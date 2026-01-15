use aiken/collection/list
use cardano/address.{from_script}
use cardano/assets.{PolicyId, from_asset_list, merge, negate, without_lovelace}
use cardano/transaction.{Transaction}
use cocktail.{
  group_outputs_2, input_inline_datum, inputs_at_with_policy, key_signed,
  o_at_with_policy,
}
use cocktail/vodka_inputs.{group_inputs_2, i_at_with_policy}
use cocktail/vodka_value.{inputs_value, outputs_value}
use hydra_dex/account_utils.{
  create_account_inputs_filter, create_account_outputs_filter,
  dex_account_balance_balance_decrease, from_value_to_hydra_balance,
}
use hydra_dex/types.{
  CancelWithdrawalIntent, DexOrderBookDatum, HydraAccountIntent,
  HydraUserIntentDatum, MPFProof, MasterIntent,
}
use hydra_dex/utils.{get_dex_order_book_datum}

pub fn cancel_withdrawal(
  oracle_nft: PolicyId,
  mpf_action: MPFProof,
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

  // - Ref input with `oracle_nft`
  let DexOrderBookDatum {
    operation_key,
    dex_account_balance_token,
    dex_account_balance_address,
    hydra_user_intent_script_hash,
    hydra_account_script_hash,
    hydra_token_policy_id,
    ..
  }: DexOrderBookDatum =
    reference_inputs |> get_dex_order_book_datum(oracle_nft)
  let hydra_user_intent_address = from_script(hydra_user_intent_script_hash)

  // - Get `II` - Intent Input
  expect [intent_input] =
    inputs_at_with_policy(
      inputs,
      hydra_user_intent_address,
      hydra_user_intent_script_hash,
    )

  // - `II` with `CancelWithdrawalIntent` datum
  expect MasterIntent { account, intent }: HydraUserIntentDatum =
    input_inline_datum(intent_input)
  expect CancelWithdrawalIntent { amount_l1: withdrawal_amount }: HydraAccountIntent =
    intent

  // - Categorize inputs into
  //   - `AI` - Account Inputs with `from` account at intent
  //   - `DI` - Dex Account Balance Input
  //   - Other inputs
  let ai_filter =
    create_account_inputs_filter(account, hydra_account_script_hash)
  let di_filter =
    i_at_with_policy(dex_account_balance_address, dex_account_balance_token)
  let (account_inputs, dex_account_balance_inputs, other_inputs) =
    group_inputs_2(inputs, ai_filter, di_filter)

  // - Categorize outputs into
  //   - `AO` - Account Outputs with `from` account at intent
  //   - `DO` - Dex Account Balance Output
  //   - Other outputs
  let ao_filter =
    create_account_outputs_filter(account, hydra_account_script_hash)
  let do_filter =
    o_at_with_policy(dex_account_balance_address, dex_account_balance_token)
  let (account_outputs, dex_account_balance_outputs, other_outputs) =
    group_outputs_2(outputs, ao_filter, do_filter)

  // - Other inputs length == 1 (the intent input)
  // - No other outputs
  let no_other_inputs = list.length(other_inputs) == 1
  let no_other_outputs = list.length(other_outputs) == 0

  // - `DO` with updated merkle root (with translated L1 value)
  expect [dex_account_balance_input] = dex_account_balance_inputs
  expect [dex_account_balance_output] = dex_account_balance_outputs
  let is_dex_account_balance_updated =
    dex_account_balance_balance_decrease(
      dex_account_balance_input,
      dex_account_balance_output,
      account,
      from_asset_list(withdrawal_amount),
      mpf_action,
    )

  // - The `HydraToken` added is minted
  // - Intent value is burnt
  let cancel_withdrawal_hydra_value =
    from_asset_list(withdrawal_amount)
      |> from_value_to_hydra_balance(hydra_token_policy_id)
  let to_mint_or_burn_value =
    without_lovelace(intent_input.output.value)
      |> negate()
      |> merge(cancel_withdrawal_hydra_value)
  let is_mint_value_correct = assets.match(mint, to_mint_or_burn_value, ==)

  // - The 3 value are equal:
  //   1. Increase in value for `account` (`AO` - `AI`)
  //   2. Deduct in value for in root (change in root in `DO`) -> translate into hydra balance
  //   3. Value in cancel withdrawal intent -> translate into hydra balance
  let deducted_amount =
    outputs_value(account_outputs)
      |> merge(negate(inputs_value(account_inputs)))
      |> without_lovelace()
  let is_cancel_withdrawal_amount_matching =
    deducted_amount == cancel_withdrawal_hydra_value

  // - Signed by `operating_key`
  let is_hydra_cancel_withdrawal_authorized =
    key_signed(extra_signatories, operation_key)

  and {
    no_other_inputs?,
    no_other_outputs?,
    is_dex_account_balance_updated?,
    is_cancel_withdrawal_amount_matching?,
    is_mint_value_correct?,
    is_hydra_cancel_withdrawal_authorized?,
  }
}
