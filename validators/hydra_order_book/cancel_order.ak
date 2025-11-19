use aiken/collection/list
use cardano/address.{Credential}
use cardano/assets.{PolicyId, match, without_lovelace}
use cardano/certificate.{Certificate}
use cardano/transaction.{Transaction}
use cocktail.{
  group_inputs_2, group_outputs, i_at, i_at_with_policy, input_inline_datum,
  inputs_value, key_signed, outputs_value, policy_only_minted_token,
}
use hydra_dex/account_utils.{create_account_outputs_filter}
use hydra_dex/types.{
  CancelOrderIntent, DexOrderBookDatum, HydraOrderBookDatum,
  HydraUserIntentDatum,
}
use hydra_dex/utils.{get_dex_order_book_datum}

validator cancel_order(oracle_nft: PolicyId) {
  withdraw(_redeemer: Data, _credential: Credential, tx: Transaction) {
    let Transaction {
      inputs,
      outputs,
      reference_inputs,
      extra_signatories,
      mint,
      ..
    } = tx

    //  - Ref input with `dex_oracle_nft`
    let DexOrderBookDatum {
      operation_key,
      hydra_user_intent_token,
      hydra_user_intent_address,
      hydra_account_balance_address,
      hydra_order_book_address,
      ..
    }: DexOrderBookDatum =
      reference_inputs |> get_dex_order_book_datum(oracle_nft)

    //  - Categorize inputs into
    //    - `II` - Intent Input
    //    - `OI` - Order Inputs
    //    - Other inputs
    let oi_filter = i_at(hydra_order_book_address)

    let ii_filter =
      i_at_with_policy(hydra_user_intent_address, hydra_user_intent_token)

    let (order_inputs, intent_inputs, other_inputs) =
      group_inputs_2(inputs, oi_filter, ii_filter)

    expect [intent_input] = intent_inputs

    //  - `II` with `CancelOrder {account, order_ids}` datum
    expect CancelOrderIntent { account, order_ids }: HydraUserIntentDatum =
      input_inline_datum(intent_input)

    //  - Categorize outputs into
    //    - `AO` - Account Output with `account` at intent
    //    - Other outputs
    let ao_filter =
      create_account_outputs_filter(account, hydra_account_balance_address)

    let (account_outputs, other_outputs) = group_outputs(outputs, ao_filter)

    // - No other inputs and outputs
    let no_other_inputs = other_inputs == []
    let no_other_outputs = other_outputs == []

    //  - For all `OI`, check
    //    - `order_id` is included in `order_ids`
    //    - `account` == `account` at intent
    let (all_approved_by_account, not_approved_cancels) =
      list.foldr(
        order_inputs,
        (True, order_ids),
        fn(order_input, acc) {
          expect order_datum: HydraOrderBookDatum =
            input_inline_datum(order_input)
          let is_same_account = order_datum.account == account
          (
            is_same_account && acc.1st,
            list.delete(acc.2nd, order_datum.order_id),
          )
        },
      )
    let is_all_cancels_intented = not_approved_cancels == []

    //  - The input intent token is burnt
    let is_intent_token_burnt =
      policy_only_minted_token(mint, hydra_user_intent_token, "", -1)

    //  - Value parity: `OI` == `AO` (to clear: is the check needed?)
    let input_value = order_inputs |> inputs_value |> without_lovelace
    let output_value =
      outputs_value(account_outputs)
        |> without_lovelace
    let is_value_parity_holds = match(input_value, output_value, ==)

    //  - Signed by `operating_key`
    let is_cancel_order_authorized =
      key_signed(extra_signatories, operation_key)

    and {
      no_other_inputs?,
      no_other_outputs?,
      all_approved_by_account?,
      is_all_cancels_intented?,
      is_intent_token_burnt?,
      is_value_parity_holds?,
      is_cancel_order_authorized?,
    }
  }

  publish(_redeemer: Data, _credential: Certificate, _tx: Transaction) {
    True
  }

  else(_) {
    fail @"unsupported purpose"
  }
}
