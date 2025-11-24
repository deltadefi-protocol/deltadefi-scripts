use aiken/collection/list
use cardano/address.{from_script}
use cardano/assets.{PolicyId, from_asset_list, merge, negate, without_lovelace}
use cardano/transaction.{Transaction}
use cocktail.{
  group_inputs_2, group_outputs_2, input_inline_datum, inputs_at_with_policy,
  key_signed,
}
use cocktail/vodka_value.{inputs_value, outputs_value}
use hydra_dex/account_utils.{
  create_account_inputs_filter, create_account_outputs_filter,
}
use hydra_dex/types.{
  DexOrderBookDatum, HydraAccountIntent, HydraUserIntentDatum, MasterIntent,
  TransferIntent,
}
use hydra_dex/utils.{get_dex_order_book_datum}

pub fn transferal(oracle_nft: PolicyId, tx: Transaction) -> Bool {
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
    hydra_user_intent_script_hash,
    hydra_account_script_hash,
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
  // - `II` with `TransferIntent` datum
  expect MasterIntent { account: from, intent }: HydraUserIntentDatum =
    input_inline_datum(intent_input)
  expect TransferIntent { to, amount: transferal_amount }: HydraAccountIntent =
    intent

  // - Categorize inputs into
  //   - `AI_from` - Account Inputs with `from` account at intent
  //   - `AI_to` - Account Inputs with `to` account at intent
  //   - Other inputs
  let ai_from_filter =
    create_account_inputs_filter(from, hydra_account_script_hash)
  let ai_to_filter = create_account_inputs_filter(to, hydra_account_script_hash)
  let (account_inputs_from, account_inputs_to, other_inputs) =
    group_inputs_2(inputs, ai_from_filter, ai_to_filter)

  // - Categorize outputs into
  //   - `AO_from` - Account Outputs with `from` account at intent
  //   - `AO_to` - Account Outputs with `to` account at intent
  //   - Other outputs
  let ao_from_filter =
    create_account_outputs_filter(from, hydra_account_script_hash)
  let ao_to_filter =
    create_account_outputs_filter(to, hydra_account_script_hash)
  let (account_outputs_from, account_outputs_to, other_outputs) =
    group_outputs_2(outputs, ao_from_filter, ao_to_filter)

  // - Other inputs length == 1 (the intent input)
  // - No other outputs
  let no_other_inputs = list.length(other_inputs) == 1
  let no_other_outputs = other_outputs == []

  // - The 3 value are equal:
  //   1. Deduct in value for `from` (`AI_from` - `AO_from`)
  //   2. Increase in value for `to` (`AO_to` - `AI_to`)
  //   3. Value in transferal intent
  let deducted_amount =
    inputs_value(account_inputs_from)
      |> merge(negate(outputs_value(account_outputs_from)))
      |> without_lovelace()
  let added_amount =
    outputs_value(account_outputs_to)
      |> merge(negate(inputs_value(account_inputs_to)))
      |> without_lovelace()
  let intent_amount = from_asset_list(transferal_amount)
  let is_values_matching =
    deducted_amount == added_amount && added_amount == intent_amount

  // - The intent token is burnt
  let is_intent_token_burnt =
    assets.match(mint, negate(without_lovelace(intent_input.output.value)), ==)

  // - Signed by `operating_key`
  let is_hydra_internal_transfer_authorized =
    key_signed(extra_signatories, operation_key)

  and {
    no_other_inputs?,
    no_other_outputs?,
    is_values_matching?,
    is_hydra_internal_transfer_authorized?,
    is_intent_token_burnt?,
  }
}
