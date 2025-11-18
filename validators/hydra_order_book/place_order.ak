use cardano/address.{Credential}
use cardano/assets.{PolicyId, match, merge, without_lovelace}
use cardano/certificate.{Certificate}
use cardano/transaction.{Transaction}
use cocktail.{
  input_inline_datum, key_signed, output_inline_datum, policy_only_minted_token,
}
use cocktail/vodka_value.{value_geq}
use hydra_dex/account_utils.{
  create_account_inputs_filter, create_account_outputs_filter,
}
use hydra_dex/order_utils.{get_min_order_value}
use hydra_dex/types.{
  DexOrderBookDatum, HydraOrderBookDatum, HydraUserIntentDatum, PlaceOrderIntent,
  UserAccount,
}
use hydra_dex/utils.{get_dex_order_book_datum}
use hydra_dex/vodka.{
  group_inputs_2, group_outputs_2, i_at_with_policy, inputs_value, o_at,
  outputs_value,
}

validator place_order(oracle_nft: PolicyId) {
  withdraw(red_account: UserAccount, _credential: Credential, tx: Transaction) {
    let Transaction {
      inputs,
      outputs,
      reference_inputs,
      extra_signatories,
      mint,
      ..
    } = tx

    let DexOrderBookDatum {
      operation_key,
      hydra_user_intent_token,
      hydra_user_intent_address,
      hydra_account_balance_address,
      hydra_order_book_address,
      hydra_tokens_policy_id,
      ..
    }: DexOrderBookDatum =
      reference_inputs |> get_dex_order_book_datum(oracle_nft)

    //  - Categorize inputs into
    //    - `AI` - Account Input with `account` at intent
    //    - `II` - Intent Inputs
    //    - Other inputs
    let ai_filter =
      create_account_inputs_filter(red_account, hydra_account_balance_address)

    let ii_filter =
      i_at_with_policy(hydra_user_intent_address, hydra_user_intent_token)

    let (account_inputs, intent_inputs, other_inputs) =
      group_inputs_2(inputs, ai_filter, ii_filter)

    expect [intent_input] = intent_inputs
    expect PlaceOrderIntent { order: intent_order }: HydraUserIntentDatum =
      input_inline_datum(intent_input)

    //  - Categorize outputs into
    //    - `AO` - Account Output with `account` at intent
    //    - `OO` - Order Output with `account` at intent
    //    - Other outputs
    let ao_filter =
      create_account_outputs_filter(red_account, hydra_account_balance_address)

    let oo_filter = o_at(hydra_order_book_address)

    let (account_outputs, order_outputs, other_outputs) =
      group_outputs_2(outputs, ao_filter, oo_filter)

    expect [order_output] = order_outputs

    // - No other inputs and outputs
    let no_other_inputs = other_inputs == []
    let no_other_outputs = other_outputs == []

    // - `II` with `PlaceOrderIntent` datum
    expect order_datum: HydraOrderBookDatum = output_inline_datum(order_output)

    // - `II` with `red_account` as account
    let is_intent_account_correct = intent_order.account == red_account

    // - `II` with `PlaceOrderIntent` datum
    let is_order_correctly_placed = intent_order == order_datum

    //  - `OO` has at least value
    //    - `is_long` == True -> at least short qty of short token
    //    - `is_long` == False -> at least `order_size` of long token
    let is_order_value_sufficient =
      value_geq(
        order_output.value,
        get_min_order_value(order_datum, hydra_tokens_policy_id),
      )

    //  - The input token is burnt
    let is_intent_token_burnt =
      policy_only_minted_token(mint, hydra_user_intent_token, "", -1)

    //  - Value parity: `AI` == `AO` + `OO`
    let input_value = account_inputs |> inputs_value |> without_lovelace
    let output_value =
      outputs_value(account_outputs)
        |> merge(order_output.value)
        |> without_lovelace
    let is_value_parity_holds = match(input_value, output_value, ==)

    //  - Signed by `operating_key`
    let is_place_order_authorized = key_signed(extra_signatories, operation_key)

    and {
      no_other_inputs?,
      no_other_outputs?,
      is_intent_account_correct?,
      is_order_correctly_placed?,
      is_order_value_sufficient?,
      is_intent_token_burnt?,
      is_value_parity_holds?,
      is_place_order_authorized?,
    }
  }

  publish(_redeemer: Data, _credential: Certificate, _tx: Transaction) {
    True
  }

  else(_) {
    fail @"unsupported purpose"
  }
}
