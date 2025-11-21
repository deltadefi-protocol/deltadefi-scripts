use aiken/collection/list
use cardano/assets.{PolicyId, Value, flatten, from_asset, merge, zero}
use hydra_dex/account_utils.{from_value_to_hydra_balance}
use hydra_dex/types.{HydraOrderBookDatum}

pub fn get_payoff_qty(
  order_size: Int,
  list_price_times_1bil: Int,
  is_long: Bool,
) -> Int {
  if is_long {
    order_size * list_price_times_1bil / 1_000_000_000
  } else {
    order_size * 1_000_000_000 / list_price_times_1bil
  }
}

pub fn get_min_order_value(
  order: HydraOrderBookDatum,
  hydra_tokens_policy_id: PolicyId,
) -> Value {
  let (policy, name) =
    if order.is_long {
      order.short_token
    } else {
      order.long_token
    }
  from_asset(policy, name, order.order_size)
    |> from_value_to_hydra_balance(hydra_tokens_policy_id)
}

pub fn get_min_payoff_value(
  order: HydraOrderBookDatum,
  hydra_tokens_policy_id: PolicyId,
) -> Value {
  let (policy, name) =
    if order.is_long {
      order.long_token
    } else {
      order.short_token
    }

  from_asset(
    policy,
    name,
    get_payoff_qty(order.order_size, order.list_price_times_1bil, order.is_long),
  )
    |> from_value_to_hydra_balance(hydra_tokens_policy_id)
}

pub fn get_fee(transacted_value: Int, fee_bp: Int) -> Int {
  transacted_value * fee_bp / 10000
}

pub fn split_order_fee(payoff: Value, fee_bp: Int) -> (Value, Value) {
  let flattened_payoff = flatten(payoff)
  list.foldr(
    flattened_payoff,
    (zero, zero),
    fn((policy, name, qty), (payoff_acc, fee_acc)) {
      let fee = get_fee(qty, fee_bp)
      (
        from_asset(policy, name, qty - fee) |> merge(payoff_acc),
        from_asset(policy, name, fee) |> merge(fee_acc),
      )
    },
  )
}
