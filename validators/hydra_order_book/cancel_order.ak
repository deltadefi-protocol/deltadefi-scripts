use aiken/collection/list
use cardano/address.{from_script}
use cardano/assets.{PolicyId, match, without_lovelace}
use cardano/transaction.{Transaction}
use cocktail.{
  group_inputs, group_outputs, i_at, input_inline_datum, inputs_value,
  key_signed, o_at, outputs_value,
}
use hydra_dex/account_utils.{
  AccountPayoff, add_to_payoff, payoff_output_settlement,
}
use hydra_dex/types.{DexOrderBookDatum, Order}
use hydra_dex/utils.{get_dex_order_book_datum}

pub fn cancel_order(oracle_nft: PolicyId, tx: Transaction) {
  let Transaction { inputs, outputs, reference_inputs, extra_signatories, .. } =
    tx

  //  - Ref input with `dex_oracle_nft`
  let DexOrderBookDatum {
    operation_key,
    hydra_account_script_hash,
    hydra_order_book_script_hash,
    ..
  }: DexOrderBookDatum =
    reference_inputs |> get_dex_order_book_datum(oracle_nft)
  let hydra_order_book_address = from_script(hydra_order_book_script_hash)
  let hydra_account_address = from_script(hydra_account_script_hash)

  //  - Categorize inputs into
  //    - `OI` - Order Inputs
  //    - Other inputs
  let oi_filter = i_at(hydra_order_book_address)
  let (order_inputs, other_inputs) = group_inputs(inputs, oi_filter)

  //  - Categorize outputs into
  //    - `AO` - Account Outputs
  //    - Other outputs
  let ao_filter = o_at(hydra_account_address)
  let (account_outputs, other_outputs) = group_outputs(outputs, ao_filter)

  // - No other inputs and outputs
  let no_other_inputs = other_inputs == []
  let no_other_outputs = other_outputs == []

  // - For all `OI`, check
  //   - Return `account_payoff` - `AccountPayoff`
  //   - Cummulate order value to the `account_payoff`
  let account_payoff: AccountPayoff =
    list.foldr(
      order_inputs,
      [],
      fn(order_input, ap_acc) {
        let order_value = order_input.output.value
        expect order_datum: Order = input_inline_datum(order_input)
        ap_acc |> add_to_payoff(order_datum.account, order_value)
      },
    )

  // - For all `account_payoff` - `<account, value>`
  //   - Check output value to `account` equals `value`
  let payoff_after_settlement =
    account_payoff |> payoff_output_settlement(account_outputs)
  let is_payoff_settled = payoff_after_settlement == []

  //  - Value parity: `OI` == `AO` (to clear: is the check needed?)
  let input_value = order_inputs |> inputs_value |> without_lovelace
  let output_value =
    outputs_value(account_outputs)
      |> without_lovelace
  let is_value_parity_holds = match(input_value, output_value, ==)

  //  - Signed by `operating_key`
  let is_cancel_order_authorized = key_signed(extra_signatories, operation_key)

  and {
    no_other_inputs?,
    no_other_outputs?,
    is_payoff_settled?,
    is_value_parity_holds?,
    is_cancel_order_authorized?,
  }
}
