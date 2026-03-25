use aiken/cbor
use aiken/merkle_patricia_forestry as mpf
use cardano/address.{Script, from_script}
use cardano/assets.{
  PolicyId, flatten, from_asset_list, merge, negate, without_lovelace,
}
use cardano/transaction.{Transaction}
use cocktail.{
  group_inputs_2, group_outputs_2, input_inline_datum, inputs_at,
  inputs_at_with_policy, inputs_value, inputs_with_policy, key_signed,
  output_inline_datum, outputs_at, outputs_value, outputs_with_policy,
}
use hydra_dex/account_utils.{
  create_account_inputs_filter, create_account_outputs_filter,
  create_master_key_inputs_filter, create_master_key_outputs_filter,
  from_hydra_balance_to_value,
}
use hydra_dex/deposit_utils.{cal_shares_amount}
use hydra_dex/price_oracle_utils.{
  convert_value_to_usd, verify_prices_oracle_messages,
}
use hydra_dex/types.{
  DexOrderBookDatum, SharesInsert, SharesMPFAction, SharesRecordEntry,
  SharesUpdate, TokenMap, VaultDepositIntentDatumL2, VaultOracleDatum,
}
use hydra_dex/utils.{get_burning_intent_policy, get_dex_order_book_datum}

pub fn vault_deposit(
  dex_oracle_nft: PolicyId,
  prices_message: ByteArray,
  signatures: List<ByteArray>,
  token_map: TokenMap,
  mpf_action: SharesMPFAction,
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

  // 2. Get L2 Deposit Intent from burn event (implicitly verifies burn)
  let mint_list = mint |> flatten()
  let intent_policy_id = get_burning_intent_policy(mint_list)
  let intent_address = from_script(intent_policy_id)

  expect [intent_input] =
    inputs_at_with_policy(inputs, intent_address, intent_policy_id)
  expect VaultDepositIntentDatumL2 {
    vault_oracle_nft,
    depositor,
    deposit_amount,
  }: VaultDepositIntentDatumL2 = input_inline_datum(intent_input)

  // 3. Get Vault Oracle input/output (derived from intent datum)
  expect [vault_oracle_input] = inputs_with_policy(inputs, vault_oracle_nft)
  expect [vault_oracle_output] = outputs_with_policy(outputs, vault_oracle_nft)

  expect input_oracle_datum: VaultOracleDatum =
    input_inline_datum(vault_oracle_input)
  expect output_oracle_datum: VaultOracleDatum =
    output_inline_datum(vault_oracle_output)

  let VaultOracleDatum {
    l2_deposit_intent_script_hash,
    hydra_node_pub_keys,
    vault_script_hash,
    operator_account,
    total_shares: input_total_shares,
    operator_shares: input_operator_shares,
    total_deposited: input_total_deposited,
    shares_merkle_root: input_merkle_root,
    ..
  } = input_oracle_datum

  let is_initial_deposit = input_total_shares == 0

  // 4. Validate intent script matches vault config
  let is_intent_valid = intent_policy_id == l2_deposit_intent_script_hash

  // 5. Verify prices message
  let (vault_equity, prices, is_prices_verified) =
    verify_prices_oracle_messages(
      prices_message,
      inputs,
      hydra_node_pub_keys,
      signatures,
    )

  // 6. Calculate shares and USD value (Division Order: multiply first!)
  // Convert L2 deposit amount to L1 for price lookup (prices are L1-keyed)
  let deposit_amount_l1 =
    from_asset_list(deposit_amount)
      |> from_hydra_balance_to_value(hydra_token_policy_id, token_map)
  let deposit_usd_value = convert_value_to_usd(deposit_amount_l1, prices)
  // Initial deposit: share price = 1.0, so shares = deposit_usd_value
  // Regular deposit: Round DOWN (integer division) - protects vault
  let shares_minted =
    if is_initial_deposit {
      deposit_usd_value
    } else {
      cal_shares_amount(deposit_usd_value, vault_equity, input_total_shares)
    }

  // 7. Group Account UTxOs (following transferal.ak pattern)
  // Vault UTxOs are filtered by master_key == intent script hash
  let vault_master_key = Script(vault_script_hash)
  let depositor_input_filter =
    create_account_inputs_filter(depositor, hydra_account_script_hash)
  let vault_input_filter =
    create_master_key_inputs_filter(vault_master_key, hydra_account_script_hash)
  let depositor_output_filter =
    create_account_outputs_filter(depositor, hydra_account_script_hash)
  let vault_output_filter =
    create_master_key_outputs_filter(
      vault_master_key,
      hydra_account_script_hash,
    )

  let (depositor_inputs, vault_inputs, other_inputs) =
    group_inputs_2(inputs, depositor_input_filter, vault_input_filter)
  let (depositor_outputs, vault_outputs, other_outputs) =
    group_outputs_2(outputs, depositor_output_filter, vault_output_filter)

  // No other inputs/outputs at hydra_account_script_hash
  let hydra_account_address = from_script(hydra_account_script_hash)
  let no_other_account_inputs =
    inputs_at(other_inputs, hydra_account_address) == []
  let no_other_account_outputs =
    outputs_at(other_outputs, hydra_account_address) == []

  // 8. Validate value transfer
  let deducted_amount =
    inputs_value(depositor_inputs)
      |> merge(negate(outputs_value(depositor_outputs)))
      |> without_lovelace()
  let added_amount =
    outputs_value(vault_outputs)
      |> merge(negate(inputs_value(vault_inputs)))
      |> without_lovelace()
  // deposit_amount is already in L2 format (consistent with UTxO values)
  let intent_amount =
    from_asset_list(deposit_amount)
      |> without_lovelace()

  let is_value_transfer_correct =
    deducted_amount == added_amount && added_amount == intent_amount

  // 9. Verify Merkle root transition
  let mpf_key = cbor.serialise(depositor)
  let computed_new_root =
    when mpf_action is {
      SharesInsert { proof } -> {
        // New depositor
        let new_entry =
          SharesRecordEntry {
            shares: shares_minted,
            total_deposited: deposit_usd_value,
          }
        let new_value = cbor.serialise(new_entry)
        let trie = mpf.from_root(input_merkle_root)
        let new_trie = mpf.insert(trie, mpf_key, new_value, proof)
        mpf.root(new_trie)
      }
      SharesUpdate { from, to_proof } -> {
        // Existing depositor
        expect Some(from_data) = cbor.deserialise(from)
        expect old_entry: SharesRecordEntry = from_data
        let new_entry =
          SharesRecordEntry {
            shares: old_entry.shares + shares_minted,
            total_deposited: old_entry.total_deposited + deposit_usd_value,
          }
        let to = cbor.serialise(new_entry)
        let trie = mpf.from_root(input_merkle_root)
        let new_trie = mpf.update(trie, mpf_key, to_proof, from, to)
        mpf.root(new_trie)
      }
      _ -> fail @"Invalid MPF action for deposit"
    }

  // 10. Calculate new operator_shares
  // If depositor == operator: shares increase by shares_minted
  // If depositor != operator: shares unchanged
  let is_operator_depositing = depositor == operator_account
  let new_operator_shares =
    if is_operator_depositing {
      input_operator_shares + shares_minted
    } else {
      input_operator_shares
    }

  // Verify Vault Oracle output datum (field by field for debugging)
  let is_total_shares_correct =
    output_oracle_datum.total_shares == input_total_shares + shares_minted
  let is_operator_shares_correct =
    output_oracle_datum.operator_shares == new_operator_shares
  let is_total_deposited_correct =
    output_oracle_datum.total_deposited == input_total_deposited + deposit_usd_value
  let is_merkle_root_correct =
    output_oracle_datum.shares_merkle_root == computed_new_root
  let is_other_fields_unchanged =
    output_oracle_datum.app_oracle == input_oracle_datum.app_oracle && output_oracle_datum.vault_script_hash == input_oracle_datum.vault_script_hash && output_oracle_datum.l1_deposit_intent_script_hash == input_oracle_datum.l1_deposit_intent_script_hash && output_oracle_datum.l1_withdrawal_intent_script_hash == input_oracle_datum.l1_withdrawal_intent_script_hash && output_oracle_datum.l2_deposit_intent_script_hash == input_oracle_datum.l2_deposit_intent_script_hash && output_oracle_datum.l2_withdrawal_intent_script_hash == input_oracle_datum.l2_withdrawal_intent_script_hash && output_oracle_datum.pluggable_logic == input_oracle_datum.pluggable_logic && output_oracle_datum.vault_stake_rotation_script_hash == input_oracle_datum.vault_stake_rotation_script_hash && output_oracle_datum.operator_account == input_oracle_datum.operator_account && output_oracle_datum.operator_charge_percentage == input_oracle_datum.operator_charge_percentage && output_oracle_datum.operator_min_deposit_percentage == input_oracle_datum.operator_min_deposit_percentage && output_oracle_datum.hydra_node_pub_keys == input_oracle_datum.hydra_node_pub_keys && output_oracle_datum.is_active == input_oracle_datum.is_active && output_oracle_datum.total_fee_share_collected == input_oracle_datum.total_fee_share_collected

  let is_oracle_datum_updated = and {
      is_total_shares_correct?,
      is_operator_shares_correct?,
      is_total_deposited_correct?,
      is_merkle_root_correct?,
      is_other_fields_unchanged?,
    }

  // 11. Verify signature (operation_key)
  let is_signed = key_signed(extra_signatories, operation_key)

  and {
    is_intent_valid?,
    is_prices_verified?,
    no_other_account_inputs?,
    no_other_account_outputs?,
    is_value_transfer_correct?,
    is_oracle_datum_updated?,
    is_signed?,
  }
}
