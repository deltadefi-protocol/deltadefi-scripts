use cardano/assets.{PolicyId, Value, from_asset}
use hydra_dex/account_utils.{from_value_to_hydra_balance}
use hydra_dex/types.{HydraOrderBookDatum}

pub fn get_short_qty(order_size: Int, list_price_times_1bil: Int) -> Int {
  order_size * list_price_times_1bil / 1_000_000_000
}

pub fn get_min_order_value(
  order: HydraOrderBookDatum,
  hydra_tokens_policy_id: PolicyId,
) -> Value {
  if order.is_long {
    from_asset(
      order.short_token.1st,
      order.short_token.2nd,
      get_short_qty(order.order_size, order.list_price_times_1bil),
    )
      |> from_value_to_hydra_balance(hydra_tokens_policy_id)
  } else {
    from_asset(order.long_token.1st, order.long_token.2nd, order.order_size)
      |> from_value_to_hydra_balance(hydra_tokens_policy_id)
  }
}

// pub fn get_order_settlement_info(
//   order: HydraOrderBookDatum,
//   remaining_order_opt: Option<HydraOrderBookDatum>,
// ) -> (Value, Value, Value) {
//   let long_token_size =
//     when remaining_order_opt is {
//       Some(remaining_order) -> order.order_size - remaining_order.order_size
//       None -> order.order_size
//     }
//   let short_qty = get_short_qty(long_token_size, order.list_price_times_1bil)
//   let long_token_value =
//     from_asset(order.long_token.1st, order.long_token.2nd, long_token_size)
//   let short_token_value =
//     from_asset(order.short_token.1st, order.short_token.2nd, short_qty)

//   if order.is_long {
//     let fee_amount =
//       from_asset(
//         order.long_token.1st,
//         order.long_token.2nd,
//         get_fee(long_token_size, order.fee_amount_bp),
//       )
//     (short_token_value, long_token_value, fee_amount)
//   } else {
//     let fee_amount =
//       from_asset(
//         order.short_token.1st,
//         order.short_token.2nd,
//         get_fee(short_qty, order.fee_amount_bp),
//       )
//     (long_token_value, short_token_value, fee_amount)
//   }
// }

// pub fn get_order_value(order: HydraOrderBookDatum) -> Value {
//   let (order_value, _, _) = get_order_settlement_info(order, None)
//   order_value
// }

// pub fn get_order_payoff(order: HydraOrderBookDatum) -> Value {
//   get_order_settlement_info(order, None).2nd
// }

pub fn get_fee(order_size: Int, fee_bp: Int) -> Int {
  order_size * fee_bp / 10000
}
// pub fn split_order_fee(payoff: Value, fee_bp: Int) -> (Value, Value) {
//   let flattened_payoff = flatten(payoff)
//   list.foldr(
//     flattened_payoff,
//     (zero, zero),
//     fn((policy, name, qty), (payoff_acc, fee_acc)) {
//       let fee = get_fee(qty, fee_bp)
//       (
//         from_asset(policy, name, qty - fee) |> merge(payoff_acc),
//         from_asset(policy, name, fee) |> merge(fee_acc),
//       )
//     },
//   )
// }
