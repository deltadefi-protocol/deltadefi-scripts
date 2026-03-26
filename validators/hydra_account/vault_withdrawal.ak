use aiken/cbor
use aiken/merkle_patricia_forestry as mpf
use cardano/address.{Script, VerificationKey, from_script}
use cardano/assets.{PolicyId, flatten, merge, negate}
use cardano/transaction.{Transaction}
use cocktail.{
  group_inputs_2, group_outputs_2, input_inline_datum, inputs_at,
  inputs_at_with_policy, inputs_value, inputs_with_policy, key_signed,
  output_inline_datum, outputs_at, outputs_value, outputs_with_policy,
}
use hydra_dex/account_utils.{
  create_account_inputs_filter, create_account_outputs_filter,
  create_master_key_inputs_filter, create_master_key_outputs_filter,
  from_hydra_balance_to_value, get_master_key,
}
use hydra_dex/price_oracle_utils.{
  convert_value_to_usd, verify_prices_oracle_messages,
}
use hydra_dex/types.{
  DexOrderBookDatum, SharesDelete, SharesMPFAction, SharesRecordEntry,
  SharesUpdate, TokenMap, VaultOracleDatum, VaultWithdrawalIntentDatumL2,
}
use hydra_dex/utils.{get_burning_intent_policy, get_dex_order_book_datum}
use hydra_dex/withdraw_utils.{
  apply_operator_fee_share, cal_per_user_operator_fee, compute_fee_shares,
  convert_shares_to_usd,
}

pub fn vault_withdrawal(
  dex_oracle_nft: PolicyId,
  prices_message: ByteArray,
  signatures: List<ByteArray>,
  token_map: TokenMap,
  mpf_action: SharesMPFAction,
  operator_mpf_action: Option<SharesMPFAction>,
  tx: Transaction,
) -> Bool {
  let Transaction {
    inputs,
    outputs,
    reference_inputs,
    extra_signatories,
    mint,
    ..
  } = tx

  // 1. Get DexOrderBook datum (reference input with `dex_oracle_nft`)
  let DexOrderBookDatum {
    operation_key,
    hydra_account_script_hash,
    hydra_token_policy_id,
    ..
  }: DexOrderBookDatum =
    reference_inputs |> get_dex_order_book_datum(dex_oracle_nft)

  // 2. Get L2 Withdrawal Intent from burn event (implicitly verifies burn)
  let mint_list = mint |> flatten()
  let intent_policy_id = get_burning_intent_policy(mint_list)
  let intent_address = from_script(intent_policy_id)

  expect [intent_input] =
    inputs_at_with_policy(inputs, intent_address, intent_policy_id)
  expect VaultWithdrawalIntentDatumL2 {
    vault_oracle_nft,
    withdrawer,
    shares_to_redeem,
  }: VaultWithdrawalIntentDatumL2 = input_inline_datum(intent_input)

  // 3. Get Vault Oracle input/output (derived from intent datum)
  expect [vault_oracle_input] = inputs_with_policy(inputs, vault_oracle_nft)
  expect [vault_oracle_output] = outputs_with_policy(outputs, vault_oracle_nft)

  expect input_oracle_datum: VaultOracleDatum =
    input_inline_datum(vault_oracle_input)
  expect output_oracle_datum: VaultOracleDatum =
    output_inline_datum(vault_oracle_output)

  let VaultOracleDatum {
    l2_withdrawal_intent_script_hash,
    hydra_node_pub_keys,
    operator_account,
    vault_script_hash,
    operator_charge_percentage,
    operator_min_deposit_percentage,
    total_shares: input_total_shares,
    operator_shares: input_operator_shares,
    total_deposited: input_total_deposited,
    shares_merkle_root: input_merkle_root,
    total_fee_share_collected: input_total_fee_share_collected,
    ..
  } = input_oracle_datum

  // 4. Validate intent script matches vault config
  let is_intent_valid = intent_policy_id == l2_withdrawal_intent_script_hash

  // 5. Verify prices message
  let (vault_equity, prices, is_prices_verified) =
    verify_prices_oracle_messages(
      prices_message,
      inputs,
      hydra_node_pub_keys,
      signatures,
    )

  // 6. Check if operator is withdrawing (skip fee if so)
  let is_operator_withdrawing = withdrawer == operator_account

  // 7. Calculate withdrawal values (Division Order: multiply first!)
  // Gross value: Round DOWN (integer division) - protects vault
  let gross_value =
    convert_shares_to_usd(shares_to_redeem, input_total_shares, vault_equity)

  // Process User Merkle transition and calculate cost_basis
  let mpf_key = cbor.serialise(withdrawer)
  let (cost_basis, new_user_root) =
    when mpf_action is {
      SharesDelete { proof, old_value } -> {
        // Total withdrawal
        expect Some(old_data) = cbor.deserialise(old_value)
        expect old_entry: SharesRecordEntry = old_data
        expect shares_to_redeem == old_entry.shares
        let cost = old_entry.total_deposited
        let trie = mpf.from_root(input_merkle_root)
        let new_trie = mpf.delete(trie, mpf_key, old_value, proof)
        (cost, mpf.root(new_trie))
      }
      SharesUpdate { from, to_proof } -> {
        // Partial withdrawal
        expect Some(from_data) = cbor.deserialise(from)
        expect old_entry: SharesRecordEntry = from_data
        expect old_entry.shares >= shares_to_redeem
        // Proportional cost basis
        let cost =
          old_entry.total_deposited * shares_to_redeem / old_entry.shares
        let new_entry =
          SharesRecordEntry {
            shares: old_entry.shares - shares_to_redeem,
            total_deposited: old_entry.total_deposited - cost,
          }
        let to = cbor.serialise(new_entry)
        let trie = mpf.from_root(input_merkle_root)
        let new_trie = mpf.update(trie, mpf_key, to_proof, from, to)
        (cost, mpf.root(new_trie))
      }
      _ -> fail @"Invalid MPF action for withdrawal"
    }

  // Calculate fee based on profit - Skip fee when operator withdraws (economically neutral)
  let fee_shares =
    if is_operator_withdrawing {
      0
    } else {
      let fee =
        cal_per_user_operator_fee(
          gross_value,
          cost_basis,
          operator_charge_percentage,
        )
      // Fee shares - Round UP to protect operator
      compute_fee_shares(fee, input_total_shares, vault_equity)
    }

  // User receives: gross_value when operator, gross_value - fee otherwise
  let user_receives =
    if is_operator_withdrawing {
      gross_value
    } else {
      let fee =
        cal_per_user_operator_fee(
          gross_value,
          cost_basis,
          operator_charge_percentage,
        )
      gross_value - fee
    }

  // 7. Group Account UTxOs
  // Vault UTxOs are filtered by master_key == intent script hash
  let vault_master_key = Script(vault_script_hash)
  let withdrawer_input_filter =
    create_account_inputs_filter(withdrawer, hydra_account_script_hash)
  let vault_input_filter =
    create_master_key_inputs_filter(vault_master_key, hydra_account_script_hash)
  let withdrawer_output_filter =
    create_account_outputs_filter(withdrawer, hydra_account_script_hash)
  let vault_output_filter =
    create_master_key_outputs_filter(
      vault_master_key,
      hydra_account_script_hash,
    )

  let (vault_inputs, withdrawer_inputs, other_inputs) =
    group_inputs_2(inputs, vault_input_filter, withdrawer_input_filter)
  let (vault_outputs, withdrawer_outputs, other_outputs) =
    group_outputs_2(outputs, vault_output_filter, withdrawer_output_filter)

  // No other inputs/outputs at hydra_account_script_hash
  let hydra_account_address = from_script(hydra_account_script_hash)
  let no_other_account_inputs =
    inputs_at(other_inputs, hydra_account_address) == []
  let no_other_account_outputs =
    outputs_at(other_outputs, hydra_account_address) == []

  // 8. Validate value transfer
  // Vault loses user_receives (in USD value)
  // Convert L2 values to L1 for price lookup (prices are L1-keyed)
  let vault_deducted =
    merge(inputs_value(vault_inputs), negate(outputs_value(vault_outputs)))
  let vault_deducted_l1 =
    from_hydra_balance_to_value(
      vault_deducted,
      hydra_token_policy_id,
      token_map,
    )
  let vault_deducted_usd = convert_value_to_usd(vault_deducted_l1, prices)

  // Withdrawer gains user_receives (in USD value)
  let withdrawer_added =
    merge(
      outputs_value(withdrawer_outputs),
      negate(inputs_value(withdrawer_inputs)),
    )
  let withdrawer_added_l1 =
    from_hydra_balance_to_value(
      withdrawer_added,
      hydra_token_policy_id,
      token_map,
    )
  let withdrawer_added_usd = convert_value_to_usd(withdrawer_added_l1, prices)

  let is_value_transfer_correct =
    vault_deducted_usd == user_receives && withdrawer_added_usd == user_receives

  // 10. Apply Operator Fee Shares (only when non-operator withdraws with profit)
  // When operator withdraws, fee_shares is 0, so no operator MPF action needed
  let final_root =
    if fee_shares > 0 {
      expect Some(action) = operator_mpf_action
      apply_operator_fee_share(
        new_user_root,
        fee_shares,
        operator_account,
        action,
      )
    } else {
      new_user_root
    }

  // 11. Calculate new operator_shares
  // If withdrawer == operator: shares decrease by shares_to_redeem (no fee earned from self)
  // If withdrawer != operator: shares increase by fee_shares
  let new_operator_shares =
    if is_operator_withdrawing {
      input_operator_shares - shares_to_redeem
    } else {
      input_operator_shares + fee_shares
    }

  // Calculate new total_shares for min percentage check
  let new_total_shares = input_total_shares - shares_to_redeem + fee_shares

  // Verify operator maintains minimum share percentage when withdrawing
  // new_operator_shares / new_total_shares >= operator_min_deposit_percentage / 100
  // Rearranged to avoid division: new_operator_shares * 100 >= operator_min_deposit_percentage * new_total_shares
  let is_operator_min_percentage_maintained =
    if is_operator_withdrawing {
      new_operator_shares * 100 >= operator_min_deposit_percentage * new_total_shares
    } else {
      True
    }

  // Verify Vault Oracle output datum (field by field for debugging)
  let is_total_shares_correct =
    output_oracle_datum.total_shares == new_total_shares
  let is_operator_shares_correct =
    output_oracle_datum.operator_shares == new_operator_shares
  let is_total_deposited_correct =
    output_oracle_datum.total_deposited == input_total_deposited - cost_basis
  let is_total_fee_share_collected_correct =
    output_oracle_datum.total_fee_share_collected == input_total_fee_share_collected + fee_shares
  let is_merkle_root_correct =
    output_oracle_datum.shares_merkle_root == final_root
  let is_other_fields_unchanged =
    output_oracle_datum.app_oracle == input_oracle_datum.app_oracle && output_oracle_datum.vault_script_hash == input_oracle_datum.vault_script_hash && output_oracle_datum.l1_deposit_intent_script_hash == input_oracle_datum.l1_deposit_intent_script_hash && output_oracle_datum.l1_withdrawal_intent_script_hash == input_oracle_datum.l1_withdrawal_intent_script_hash && output_oracle_datum.l2_deposit_intent_script_hash == input_oracle_datum.l2_deposit_intent_script_hash && output_oracle_datum.l2_withdrawal_intent_script_hash == input_oracle_datum.l2_withdrawal_intent_script_hash && output_oracle_datum.pluggable_logic == input_oracle_datum.pluggable_logic && output_oracle_datum.vault_stake_rotation_script_hash == input_oracle_datum.vault_stake_rotation_script_hash && output_oracle_datum.operator_account == input_oracle_datum.operator_account && output_oracle_datum.operator_charge_percentage == input_oracle_datum.operator_charge_percentage && output_oracle_datum.operator_min_deposit_percentage == input_oracle_datum.operator_min_deposit_percentage && output_oracle_datum.hydra_node_pub_keys == input_oracle_datum.hydra_node_pub_keys && output_oracle_datum.is_active == input_oracle_datum.is_active

  let is_oracle_datum_updated = and {
      is_total_shares_correct?,
      is_operator_shares_correct?,
      is_total_deposited_correct?,
      is_total_fee_share_collected_correct?,
      is_merkle_root_correct?,
      is_other_fields_unchanged?,
    }

  // 12. Verify signature (operation_key OR operator's master_key)
  // Operator key is derived from operator_account's master_key
  let is_operator_signed =
    when get_master_key(operator_account) is {
      VerificationKey(operator_key_hash) ->
        key_signed(extra_signatories, operator_key_hash)
      _ -> False
    }
  let is_signed =
    key_signed(extra_signatories, operation_key) || is_operator_signed

  and {
    is_intent_valid?,
    is_prices_verified?,
    no_other_account_inputs?,
    no_other_account_outputs?,
    is_value_transfer_correct?,
    is_operator_min_percentage_maintained?,
    is_oracle_datum_updated?,
    is_signed?,
  }
}
