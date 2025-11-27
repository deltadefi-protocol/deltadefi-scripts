use aiken/collection/list
use cardano/address.{from_script}
use cardano/assets.{
  PolicyId, Value, from_asset, match, merge, negate, without_lovelace, zero,
}
use cardano/transaction.{Output, Transaction}
use cocktail.{
  group_inputs, i_at, input_inline_datum, key_signed, o_at, output_inline_datum,
  value_geq,
}
use cocktail/vodka_value.{inputs_value, outputs_value}
use hydra_dex/account_utils.{
  AccountPayoff, add_to_payoff, payoff_output_settlement,
}
use hydra_dex/order_utils.{get_fee, get_min_order_value, get_min_payoff_value}
use hydra_dex/types.{DexOrderBookDatum, Order, UserAccount}
use hydra_dex/utils.{get_dex_order_book_datum}

pub fn fill_order(
  oracle_nft: PolicyId,
  filler_order_id: ByteArray,
  tx: Transaction,
) {
  let Transaction { inputs, outputs, reference_inputs, extra_signatories, .. } =
    tx
  let DexOrderBookDatum {
    operation_key,
    fee_account,
    hydra_order_book_script_hash,
    hydra_account_script_hash,
    hydra_token_policy_id,
    ..
  }: DexOrderBookDatum =
    reference_inputs |> get_dex_order_book_datum(oracle_nft)
  let hydra_order_book_address = from_script(hydra_order_book_script_hash)
  let hydra_account_address = from_script(hydra_account_script_hash)

  // - Ref input with `dex_oracle_nft`
  // - Categorize inputs into
  //   - `OI` - Order Inputs
  //   - Other inputs
  let oi_filter = i_at(hydra_order_book_address)
  let (order_inputs, other_inputs) = group_inputs(inputs, oi_filter)

  // - Categorize outputs into
  //   - `AO` - Account Outputs
  //   - `OO` - Order Output
  //   - Other outputs
  let ao_filter = o_at(hydra_account_address)
  let oo_filter = o_at(hydra_order_book_address)
  let (account_outputs, order_outputs, other_outputs) =
    cocktail.group_outputs_2(outputs, ao_filter, oo_filter)

  // ### Backend Logics
  // - Handle remaining order
  // - deduct from payoff of that user
  // - This to replace the `end qty (EQ)` of order calculation:
  //   - `filled qty (FQ)` = `start qty (SQ)` - `end qty (EQ)`
  let new_order_opt =
    when order_outputs is {
      [remaining_order_output] -> {
        expect remaining_order_datum: Order =
          output_inline_datum(remaining_order_output)
        Some((remaining_order_datum, remaining_order_output.value))
      }
      _ -> None
    }

  // - Loop through `OI` 
  //   - Return `total_order_value`, `total_min_order_value`, `total_payoff_value`, `account_payoff`, `filler_order_opt`
  let (
    total_order_value,
    total_min_order_value,
    total_payoff_value,
    account_payoff,
    filler_order_input_opt,
  ) =
    order_inputs
      |> list.foldr(
          (zero, zero, zero, [], None),
          fn(
            order_input,
            (
              total_order_value_acc,
              total_min_order_value_acc,
              total_payoff_value_acc,
              account_payoff_acc,
              filler_order_acc,
            ),
          ) {
            expect order: Order = input_inline_datum(order_input)
            //   - Skip the filler order for later process
            if order.order_id == filler_order_id {
              (
                total_order_value_acc,
                total_min_order_value_acc,
                total_payoff_value_acc,
                account_payoff_acc,
                Some(order_input),
              )
            } else {
              //   - Get `order_value (OV)`, `min_order_value (MOV)`, `min_payoff_value (MPV)`
              let order_value = order_input.output.value
              let min_order_value =
                get_min_order_value(order, hydra_token_policy_id)
              let min_payoff_value =
                get_min_payoff_value(order, hydra_token_policy_id)
              //   - Calculate the `excess_order_value (EOV)` (`OV` - `MOV`)
              // - If the order is partially filled, with `filled_qty` = `start_qty` - `end_qty`, calculate:
              //   - `Final OV` = `OV` - output `OV`
              //   - `Final MOV` = `filled_qty`'s value
              //   - `Final EOV` = `FOV` - `FMOV`
              //   - `Final MPV` = convert `filled_qty` into pay off Int’s value
              //   - Return `Final OV`, `Final EOV`, `Final MPV`
              let (final_order_value, final_min_order_value, final_payoff_value) =
                get_unfilled_order(order, new_order_opt)
                  |> get_partial_filled_order_info(
                      order,
                      hydra_token_policy_id,
                      order_value,
                      min_order_value,
                      min_payoff_value,
                    )
              let final_excess_value =
                final_order_value |> merge(negate(final_min_order_value))

              //   - Process the maker order
              let fee_value =
                get_fee_value(final_payoff_value, order.fee_amount_bp)
              (
                // - Cummulate the order value
                total_order_value_acc |> merge(final_order_value),
                total_min_order_value_acc |> merge(final_min_order_value),
                total_payoff_value_acc |> merge(final_payoff_value),
                account_payoff_acc
                  //     - Calculate settlement to maker
                  //       - payoff (i.e. `filled qty`)
                  //       - Excessive value `EOV`
                  |> add_to_payoff(
                      order.account,
                      merge(final_payoff_value, final_excess_value)
                        |> merge(negate(fee_value)),
                    )
                  //     - Calculate fee (`filled qty` \* 10bp round down)
                  |> add_to_payoff(fee_account, fee_value),
                filler_order_acc,
              )
            }
          },
        )

  // - Handle filler order
  let final_account_payoff =
    when filler_order_input_opt is {
      Some(filler_order_input) -> {
        expect order: Order = input_inline_datum(filler_order_input)

        //   - Use exactly the makers’ `Final MOV` as payoff
        let order_value = filler_order_input.output.value
        let min_order_value = get_min_order_value(order, hydra_token_policy_id)
        let filler_payoff_value = total_min_order_value

        //   - Handle unfilled order value
        //     - Deduct `new order qty` from `order remaining value`
        let (final_order_value, _, final_payoff_value) =
          get_unfilled_order(order, new_order_opt)
            |> get_partial_filled_order_info(
                order,
                hydra_token_policy_id,
                order_value,
                min_order_value,
                filler_payoff_value,
              )

        //   - Calculate fee (`FQ` \* 10bp round down)
        let fee_value = get_fee_value(filler_payoff_value, order.fee_amount_bp)

        // - Pay the `order remaining value` to taker
        //   - If there is negative `order remaining value` → deduct from fee instead
        let total_order_value = total_order_value |> merge(final_order_value)
        let total_payoff_value = total_payoff_value |> merge(final_payoff_value)
        let order_remaining_value =
          total_order_value |> merge(negate(total_payoff_value))

        let final_account_payoff =
          account_payoff
            |> handle_remaining_value(
                order.account,
                fee_account,
                order_remaining_value,
              )
            |> add_to_payoff(fee_account, fee_value)
            |> add_to_payoff(
                order.account,
                final_payoff_value
                  |> merge(negate(fee_value)),
              )

        final_account_payoff
      }
      None -> {
        let excess_value =
          total_order_value |> merge(negate(total_payoff_value))
        account_payoff |> add_to_payoff(fee_account, excess_value)
      }
    }
  // ### Contract Guards
  // - There is no other inputs
  // - There is no other outputs
  let no_other_inputs = other_inputs == []
  let no_other_outputs = other_outputs == []

  // - Loop through `AO`
  //   - Each has at least received the payoff value calculated above
  let payoff_after_settlement =
    final_account_payoff |> payoff_output_settlement(account_outputs)

  // - There is no negative payoff
  let is_no_negative_payoff = payoff_after_settlement == []

  // - `OO` has at least value
  //   - `is_long` == True -> at least short qty of short token
  //   - `is_long` == False -> at least `size` of long token
  let (is_order_value_sufficient, order_output_value) =
    when new_order_opt is {
      Some((new_order, new_order_value)) ->
        (
          value_geq(
            new_order_value,
            get_min_order_value(new_order, hydra_token_policy_id),
          ),
          new_order_value,
        )
      _ -> (True, zero)
    }

  // - Value parity: `OI` == `AO` + `OO` (to clear: is the check needed?)
  let input_value = order_inputs |> inputs_value |> without_lovelace
  let output_value =
    outputs_value(account_outputs)
      |> merge(order_output_value)
      |> without_lovelace
  let is_value_parity_holds = match(input_value, output_value, ==)

  // - Signed by `operating_key`
  let is_fill_order_authorized = key_signed(extra_signatories, operation_key)

  and {
    no_other_inputs?,
    no_other_outputs?,
    is_no_negative_payoff?,
    is_order_value_sufficient?,
    is_value_parity_holds?,
    is_fill_order_authorized?,
  }
}

fn get_unfilled_order(
  old_order: Order,
  new_order_opt: Option<(Order, Value)>,
) -> Option<(Order, Value)> {
  when new_order_opt is {
    Some((new_order, new_order_value)) ->
      if old_order.order_id == new_order.order_id {
        if Order { ..old_order, size: new_order.size } == new_order {
          Some((new_order, new_order_value))
        } else {
          fail @"partial filled order altered"
        }
      } else {
        None
      }
    _ -> None
  }
}

fn get_partial_filled_order_info(
  unfilled_order: Option<(Order, Value)>,
  order: Order,
  hydra_token_policy_id: ByteArray,
  order_value: Value,
  min_order_value: Value,
  min_payoff_value: Value,
) -> (Value, Value, Value) {
  when unfilled_order is {
    Some((new_order, new_order_value)) -> {
      let filled_qty = order.size - new_order.size
      let fov = order_value |> merge(negate(new_order_value))
      let fmov =
        get_min_order_value(
          Order { ..order, size: filled_qty },
          hydra_token_policy_id,
        )
      let fmpv =
        get_min_payoff_value(
          Order { ..order, size: filled_qty },
          hydra_token_policy_id,
        )
      (fov, fmov, fmpv)
    }
    _ -> (order_value, min_order_value, min_payoff_value)
  }
}

fn get_fee_value(transacted_value: Value, fee_bp: Int) -> Value {
  transacted_value
    |> assets.reduce(
        zero,
        fn(policy, name, qty, fee_acc) {
          let fee_qty = get_fee(qty, fee_bp)
          fee_acc |> merge(from_asset(policy, name, fee_qty))
        },
      )
}

fn handle_remaining_value(
  payoff: AccountPayoff,
  taker: UserAccount,
  fee_account: UserAccount,
  remaining_value: Value,
) -> AccountPayoff {
  remaining_value
    |> assets.reduce(
        payoff,
        fn(policy, name, qty, acc) {
          acc
            |> add_to_payoff(
                if qty > 0 {
                  taker
                } else {
                  fee_account
                },
                from_asset(policy, name, qty),
              )
        },
      )
}
