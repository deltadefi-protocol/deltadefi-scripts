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
  // - Return `total_order_value (TOV)`, `account_payoff (AP)`, `total_filled_order_value (TFOV)`, `total_order_payoff_value (TOPV)`, 
  let (tov, ap, tfov, topv, filler_order_input_opt) =
    order_inputs
      |> list.foldr(
          (zero, [], zero, zero, None),
          fn(
            order_input,
            (tov_acc, account_payoff_acc, tfov_acc, topv_acc, filler_order_acc),
          ) {
            expect order: Order = input_inline_datum(order_input)
            //   - Skip the filler order for later process
            if order.order_id == filler_order_id {
              (
                tov_acc,
                account_payoff_acc,
                tfov_acc,
                topv_acc,
                Some(order_input),
              )
            } else {
              //   - Get `order_value (OV)`, `min_order_value (MOV)`, `min_payoff_value (MPV)`
              let order_value = order_input.output.value
              //   - Calculate the `excess_order_value (EOV)` (`OV` - `MOV`)
              // - If the order is partially filled, with `filled_qty` = `start_qty` - `end_qty`, calculate:
              //   - If any order information other than `size` changed -> panic
              //   - `Spent OV (SOV)` = `OV` - output `order_value`
              //   - `Filled OV (FOV)` = `MOV` - output `order_size`
              //   - `Return OV (ROV)` = `SOV` - `ROV`
              //   - `Final Order Payoff (FOP)` = calculate from `FOV`
              let (sov, fov, final_order_payoff) =
                get_unfilled_order(order, new_order_opt)
                  |> get_partial_filled_order_info(
                      order,
                      hydra_token_policy_id,
                      order_value,
                    )
              let rov = sov |> merge(negate(fov))

              // - Process the maker order
              let fee_value =
                get_fee_value(final_order_payoff, order.fee_amount_bp)
              (
                // - Cummulate the order value
                tov_acc |> merge(sov),
                account_payoff_acc
                  //   - Calculate `fee` (`FOP` \* 10bp round down)
                  //   - To maker `Final Payoff (FP)` = `FOP` + `ROV` - `fee`
                  //   - To fee collector `fee`
                  |> add_to_payoff(
                      order.account,
                      merge(final_order_payoff, rov)
                        |> merge(negate(fee_value)),
                    )
                  //     - Calculate fee (`filled qty` \* 10bp round down)
                  |> add_to_payoff(fee_account, fee_value),
                tfov_acc |> merge(fov),
                topv_acc |> merge(final_order_payoff),
                filler_order_acc,
              )
            }
          },
        )

  let final_account_payoff =
    when filler_order_input_opt is {
      Some(filler_order_input) -> {
        expect order: Order = input_inline_datum(filler_order_input)
        // //   - Use exactly the makers’ `TFOV` as payoff
        let final_payoff_value = tfov
        // let min_order_value = get_min_order_value(order, hydra_token_policy_id)
        //   - Calculate `fee` (`TFOV` \* 10bp round down)
        let fee_value = get_fee_value(tfov, order.fee_amount_bp)

        //   - Get `Maker OV`
        let order_value = filler_order_input.output.value
        //   - Handle unfilled order value
        //   - `order remaining value (ORV)` = `Maker OV` - `TOPV`
        //     - `ORV` = `ORV` - new order_size
        let (final_order_value, _, _) =
          get_unfilled_order(order, new_order_opt)
            |> get_partial_filled_order_info(
                order,
                hydra_token_policy_id,
                order_value,
              )

        //   - Pay the `ORV` to taker
        //     - If there is negative `ORV` → deduct from fee instead
        let tov = tov |> merge(final_order_value)
        let topv = topv |> merge(final_payoff_value)
        let orv = tov |> merge(negate(topv))

        let final_account_payoff =
          ap
            |> handle_remaining_value(order.account, fee_account, orv)
            |> add_to_payoff(fee_account, fee_value)
            |> add_to_payoff(
                order.account,
                final_payoff_value
                  |> merge(negate(fee_value)),
              )

        final_account_payoff
      }
      None -> {
        let rov = tov |> merge(negate(topv))
        ap |> add_to_payoff(fee_account, rov)
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
) -> (Value, Value, Value) {
  let min_order_value = get_min_order_value(order, hydra_token_policy_id)
  let min_payoff_value = get_min_payoff_value(order, hydra_token_policy_id)

  when unfilled_order is {
    Some((new_order, new_order_value)) -> {
      let sov = order_value |> merge(negate(new_order_value))
      let new_mov = get_min_order_value(new_order, hydra_token_policy_id)
      let new_mpv = get_min_payoff_value(new_order, hydra_token_policy_id)

      let fov =
        min_order_value
          |> merge(negate(new_mov))
      let fop =
        min_payoff_value
          |> merge(negate(new_mpv))

      (sov, fov, fop)
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
