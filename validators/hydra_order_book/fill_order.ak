use aiken/collection/list
use aiken/collection/pairs
use cardano/address.{Credential}
use cardano/assets.{
  PolicyId, Value, flatten, from_asset, from_asset_list, merge, negate,
  without_lovelace, zero,
}
use cardano/certificate.{Certificate}
use cardano/transaction.{Output, Transaction}
use cocktail.{
  input_inline_datum, inputs_at_with_policy, key_signed, output_inline_datum,
  outputs_at_with_policy,
}
use cocktail/vodka_value.{value_geq}
use hydra_dex/account_utils.{compare_user_account}
use hydra_dex/order_utils.{get_fee, get_order_settlement_info}
use hydra_dex/types.{
  DexOrderBookDatum, FillOrderRedeemer, HydraAccountBalanceDatum,
  HydraOrderBookDatum, UserAccount,
}
use hydra_dex/utils.{get_dex_order_book_datum}

fn find_remaining_order(
  order_id: ByteArray,
  order_outputs: List<Output>,
) -> (Option<HydraOrderBookDatum>, List<Output>) {
  let remaining_order =
    list.find(
      order_outputs,
      fn(order_output) {
        expect order_output_datum: HydraOrderBookDatum =
          output_inline_datum(order_output)
        order_output_datum.order_id == order_id
      },
    )
  when remaining_order is {
    Some(order_output) -> {
      expect order_output_datum: HydraOrderBookDatum =
        output_inline_datum(order_output)
      // In our product design, there should be at max one remaining order
      // Either one of the limit orders / or the filler order
      (Some(order_output_datum), [])
    }
    None -> (None, order_outputs)
  }
}

fn add_to_payoff(
  payoff: Pairs<UserAccount, Value>,
  user_account: UserAccount,
  value: Value,
) -> Pairs<UserAccount, Value> {
  when payoff |> pairs.get_first(user_account) is {
    Some(current_payoff) ->
      payoff
        |> pairs.repsert_by_ascending_key(
            user_account,
            current_payoff |> merge(value),
            compare_user_account,
          )
    None ->
      payoff
        |> pairs.repsert_by_ascending_key(
            user_account,
            value,
            compare_user_account,
          )
  }
}

fn deduct_from_payoff(
  payoff: Pairs<UserAccount, Value>,
  user_account: UserAccount,
  value: Value,
) -> Pairs<UserAccount, Value> {
  let negate_value = negate(value)
  when payoff |> pairs.get_first(user_account) is {
    Some(current_payoff) ->
      payoff
        |> pairs.repsert_by_ascending_key(
            user_account,
            current_payoff |> merge(negate_value),
            compare_user_account,
          )
    None ->
      payoff
        |> pairs.repsert_by_ascending_key(
            user_account,
            negate_value,
            compare_user_account,
          )
  }
}

validator fill_order(oracle_nft: PolicyId) {
  withdraw(
    redeemer: FillOrderRedeemer,
    _credential: Credential,
    tx: Transaction,
  ) {
    let Transaction {
      inputs,
      outputs,
      reference_inputs,
      mint,
      extra_signatories,
      ..
    } = tx

    let DexOrderBookDatum {
      operation_key,
      fee_account,
      hydra_order_book_address,
      hydra_order_book_token,
      hydra_account_balance_address,
      hydra_account_balance_token,
      ..
    }: DexOrderBookDatum =
      reference_inputs |> get_dex_order_book_datum(oracle_nft)

    let order_inputs =
      inputs_at_with_policy(
        inputs,
        hydra_order_book_address,
        hydra_order_book_token,
      )
    let order_outputs =
      outputs_at_with_policy(
        tx.outputs,
        hydra_order_book_address,
        hydra_order_book_token,
      )

    //  Obtain a map of to owe value by looking at order input
    //  Update the map by duducting the to owe value by looking at order output
    let (
      // account_payoff: In this order filling event, how much each account should get
      account_payoff,
      // order_values: The total value of all orders being involved
      limit_order_values,
      // total_payoff: Total order value - extra value
      total_payoff,
      // to_burn_tokens: Order tokens to be burnt (fully filled orders)
      to_burn_tokens,
      // filler_order_input_opt: The order input that matches the filler order id
      filler_order_input_opt,
      // To handle the case the remaining order is the filler order
      order_outputs,
    ) =
      list.foldr(
        order_inputs,
        ([], zero, zero, zero, None, order_outputs),
        fn(
          order_input,
          (
            account_payoff_acc,
            order_values_acc,
            total_payoff_acc,
            to_burn_token_acc,
            filler_order_acc,
            order_outputs_acc,
          ),
        ) {
          expect order_datum: HydraOrderBookDatum =
            input_inline_datum(order_input)

          // Possible for filler_order_id to be None if no Taker
          if order_datum.order_id == redeemer.filler_order_id {
            (
              account_payoff_acc,
              order_values_acc,
              total_payoff_acc,
              to_burn_token_acc,
              Some(order_input),
              order_outputs_acc,
            )
          } else {
            // The remaining order is one of the limit orders
            let (remaining_order_opt, order_outputs_new_acc) =
              find_remaining_order(order_datum.order_id, order_outputs_acc)
            let (order_value, order_payoff, extra_value, fee_value) =
              get_order_settlement_info(order_datum, remaining_order_opt)
            let net_payoff =
              negate(fee_value) |> merge(order_payoff) |> merge(extra_value)

            let to_burn_token_acc =
              when remaining_order_opt is {
                Some(_) -> to_burn_token_acc
                None -> to_burn_token_acc |> merge(order_input.output.value)
              }
            // Handle fee
            let account_payoff_acc =
              add_to_payoff(account_payoff_acc, fee_account, fee_value)
            // Handle user payoff
            let account_payoff_acc =
              add_to_payoff(account_payoff_acc, order_datum.account, net_payoff)

            (
              account_payoff_acc,
              order_values_acc |> merge(order_value),
              total_payoff_acc |> merge(net_payoff) |> merge(fee_value),
              to_burn_token_acc,
              filler_order_acc,
              order_outputs_new_acc,
            )
          }
        },
      )

    // At this point, we have processed all limit orders
    // We will now handle the filler order (if any)
    // Essentially we calculate fees based on the orders filled by the filler order
    // And any remaining value also goes to the filler order account
    let (account_payoff, to_burn_tokens) =
      when filler_order_input_opt is {
        Some(filler_order_input) -> {
          expect filler_order_datum: HydraOrderBookDatum =
            input_inline_datum(filler_order_input)
          // The remaining order is filler order
          let (remaining_filler_order_opt, _) =
            find_remaining_order(filler_order_datum.order_id, order_outputs)
          let (filler_order_value, _, filler_extra_value, _) =
            get_order_settlement_info(filler_order_datum, None)
          let (filler_remaining_order_value, _, filler_remaining_extra_value, _) =
            when remaining_filler_order_opt is {
              Some(remaining_filler_order) ->
                get_order_settlement_info(remaining_filler_order, None)
              None -> (zero, zero, zero, zero)
            }

          let order_fee_bp = filler_order_datum.fee_amount_bp

          // Handle filler order fees
          let fee_value =
            limit_order_values
              |> flatten()
              |> list.foldr(
                  zero,
                  fn((policy, name, qty), acc) {
                    acc
                      |> merge(
                          from_asset(policy, name, get_fee(qty, order_fee_bp)),
                        )
                  },
                )
          let filler_net_payoff =
            negate(fee_value)
              |> merge(limit_order_values)
              |> merge(filler_extra_value)

          let to_burn_tokens =
            when remaining_filler_order_opt is {
              Some(_) -> to_burn_tokens
              None -> to_burn_tokens |> merge(filler_order_input.output.value)
            }
          // Handle user payoff
          let account_payoff =
            add_to_payoff(
              account_payoff,
              filler_order_datum.account,
              filler_net_payoff,
            )
          // Handle fee
          let account_payoff =
            add_to_payoff(account_payoff, fee_account, fee_value)

          // Handle balance tx
          let total_order_values =
            limit_order_values
              |> merge(filler_order_value)
              |> merge(filler_extra_value)
          let total_payoff =
            total_payoff |> merge(filler_net_payoff) |> merge(fee_value)

          let remaining_value =
            total_order_values
              |> merge(negate(total_payoff))
              |> merge(negate(filler_remaining_order_value))
              |> merge(negate(filler_remaining_extra_value))

          if !value_geq(remaining_value, zero) {
            fail
          } else {
            (
              add_to_payoff(
                account_payoff,
                filler_order_datum.account,
                remaining_value,
              ),
              to_burn_tokens,
            )
          }
        }

        _ -> {
          let remaining_value =
            limit_order_values |> merge(negate(total_payoff))
          (
            add_to_payoff(account_payoff, fee_account, remaining_value),
            to_burn_tokens,
          )
        }
      }

    // unbalance one goes to fee account
    //  Order value equals to total account increased value
    let account_inputs =
      inputs_at_with_policy(
        inputs,
        hydra_account_balance_address,
        hydra_account_balance_token,
      )

    // Add account existing balance
    let account_payoff =
      list.foldr(
        account_inputs,
        account_payoff,
        fn(
          /// Handle balance tx
          account_input,
          payoff_acc,
        ) {
          expect HydraAccountBalanceDatum { account, balance }: HydraAccountBalanceDatum =
            input_inline_datum(account_input)
          add_to_payoff(payoff_acc, account, balance |> from_asset_list())
        },
      )

    let account_outputs =
      outputs_at_with_policy(
        outputs,
        hydra_account_balance_address,
        hydra_account_balance_token,
      )

    // Deduct account output balance
    let account_payoff =
      list.foldr(
        account_outputs,
        account_payoff,
        fn(account_output, payoff_acc) {
          expect HydraAccountBalanceDatum { account, balance }: HydraAccountBalanceDatum =
            output_inline_datum(account_output)
          if !value_geq(from_asset_list(balance), zero) {
            fail
          } else {
            // Deduct the balance from the account payoff
            deduct_from_payoff(
              payoff_acc,
              account,
              balance |> from_asset_list(),
            )
          }
        },
      )

    let is_all_account_balance_updated =
      account_payoff
        |> list.all(fn(Pair(_account, value)) { value == zero })

    // Burn all `HydraOrderBook` tokens
    let is_all_order_tokens_burnt =
      mint == negate(without_lovelace(to_burn_tokens))
    let is_fill_order_authorized = key_signed(extra_signatories, operation_key)
    is_all_account_balance_updated? && is_all_order_tokens_burnt? && is_fill_order_authorized?
  }

  publish(_redeemer: Data, _credential: Certificate, _tx: Transaction) {
    True
  }

  else(_) {
    fail @"unsupported purpose"
  }
}
