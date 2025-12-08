use cardano/address.{from_script}
use cardano/assets.{
  PolicyId, from_asset_list, match, merge, negate, without_lovelace,
}
use cardano/transaction.{Transaction}
use cocktail.{
  group_inputs_2, group_outputs_2, i_at_with_policy, input_inline_datum,
  inputs_value, key_signed, o_at, output_inline_datum, outputs_value,
  policy_only_minted_token, value_geq,
}
use hydra_dex/account_utils.{
  create_account_inputs_filter, create_account_outputs_filter,
  from_value_to_hydra_balance,
}
use hydra_dex/order_utils.{get_min_order_value}
use hydra_dex/types.{
  DexOrderBookDatum, HydraOrderBookIntent, HydraUserIntentDatum,
  ModifyOrderIntent, Order, TradeIntent, UserAccount,
}
use hydra_dex/utils.{get_dex_order_book_datum}

pub fn modify_order(oracle_nft: PolicyId, account: UserAccount, tx: Transaction) {
  let Transaction {
    inputs,
    outputs,
    mint,
    extra_signatories,
    reference_inputs,
    ..
  } = tx

  let DexOrderBookDatum {
    operation_key,
    hydra_user_intent_script_hash,
    hydra_account_script_hash,
    hydra_order_book_script_hash,
    hydra_token_policy_id,
    ..
  } = reference_inputs |> get_dex_order_book_datum(oracle_nft)
  let hydra_user_intent_address = from_script(hydra_user_intent_script_hash)
  let hydra_order_book_address = from_script(hydra_order_book_script_hash)
  //  - Categorize inputs into
  //    - `II` - Intent Input
  //    - `AI` - Account Inputs
  //    - `OI` - Order Input
  //    - Other inputs
  let ai_filter =
    create_account_inputs_filter(account, hydra_account_script_hash)
  let ii_filter =
    i_at_with_policy(hydra_user_intent_address, hydra_user_intent_script_hash)
  let (account_inputs, intent_inputs, other_inputs) =
    group_inputs_2(inputs, ai_filter, ii_filter)
  expect [intent_input] = intent_inputs

  //  - Categorize outputs into
  //    - `AO` - Account Output with `account` at intent
  //    - `OO` - Order Output with `account` at intent
  //    - Other outputs
  let ao_filter =
    create_account_outputs_filter(account, hydra_account_script_hash)
  let oo_filter = o_at(hydra_order_book_address)
  let (account_outputs, order_outputs, other_outputs) =
    group_outputs_2(outputs, ao_filter, oo_filter)
  expect [order_output] = order_outputs

  // - No other inputs and outputs
  expect [order_input] = other_inputs
  let no_other_inputs = order_input.output.address == hydra_order_book_address
  let no_other_outputs = other_outputs == []

  // - `II` with `ModifyOrderIntent` datum
  expect TradeIntent { account, intent }: HydraUserIntentDatum =
    input_inline_datum(intent_input)

  expect ModifyOrderIntent { new_order: intent_order, authorized_account_value }: HydraOrderBookIntent =
    intent

  // - `II` with `account` as account
  let is_intent_account_correct = intent_order.account == account

  // - `OO` with exactly datum `II`
  expect new_order_datum: Order = output_inline_datum(order_output)
  let is_intent_order_correct = new_order_datum == intent_order

  // - `OI` & `OO` has same `order_id`
  expect old_order_datum: Order = input_inline_datum(order_input)
  let is_order_id_matching =
    old_order_datum.order_id == new_order_datum.order_id

  // - `OO` has at least value
  //   - `is_buy` == True -> at least short qty of short token
  //   - `is_buy` == False -> at least `size` of long token
  let is_order_value_sufficient =
    value_geq(
      order_output.value,
      get_min_order_value(new_order_datum, hydra_token_policy_id),
    )

  // - The input intent token is burnt
  let is_intent_token_burnt =
    policy_only_minted_token(mint, hydra_user_intent_script_hash, "", -1)

  // - The deduction of account value (`AI` - `AO`) does not exceed `authorized_account_value`
  let deducted_account_value =
    inputs_value(account_inputs)
      |> merge(negate(outputs_value(account_outputs)))
  let is_deduction_within_authorized_limit =
    value_geq(
      authorized_account_value
        |> from_asset_list()
        |> from_value_to_hydra_balance(hydra_token_policy_id),
      deducted_account_value,
    )

  // - Value parity: `AI` + `OI` == `AO` + `OO` (to clear: is the check needed?)
  let input_value =
    inputs_value(account_inputs)
      |> merge(order_input.output.value)
      |> without_lovelace
  let output_value =
    outputs_value(account_outputs)
      |> merge(order_output.value)
      |> without_lovelace
  let is_value_parity_holds = match(input_value, output_value, ==)

  // - Signed by `operating_key`
  let is_modify_order_authorized = key_signed(extra_signatories, operation_key)

  and {
    no_other_inputs?,
    no_other_outputs?,
    is_intent_account_correct?,
    is_intent_order_correct?,
    is_order_id_matching?,
    is_order_value_sufficient?,
    is_intent_token_burnt?,
    is_deduction_within_authorized_limit?,
    is_value_parity_holds?,
    is_modify_order_authorized?,
  }
}
