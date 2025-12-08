use aiken/collection/list
use cardano/assets.{PolicyId, Value, flatten, from_asset, merge, zero}
use hydra_dex/account_utils.{from_value_to_hydra_balance}
use hydra_dex/types.{Order}

pub fn base_to_quote_qty(base_qty: Int, list_price_times_1bil: Int) -> Int {
  base_qty * list_price_times_1bil / 1_000_000_000
}

pub fn quote_to_base_qty(quote_qty: Int, list_price_times_1bil: Int) -> Int {
  quote_qty * 1_000_000_000 / list_price_times_1bil
}

pub fn get_payoff_qty(
  size: Int,
  list_price_times_1bil: Int,
  is_buy: Bool,
) -> Int {
  if is_buy {
    quote_to_base_qty(size, list_price_times_1bil)
  } else {
    base_to_quote_qty(size, list_price_times_1bil)
  }
}

pub fn get_min_order_value(
  order: Order,
  hydra_token_policy_id: PolicyId,
) -> Value {
  let (policy, name) =
    if order.is_buy {
      order.quote_token
    } else {
      order.base_token
    }
  from_asset(policy, name, order.size)
    |> from_value_to_hydra_balance(hydra_token_policy_id)
}

pub fn get_min_payoff_value(
  order: Order,
  hydra_token_policy_id: PolicyId,
) -> Value {
  let (policy, name) =
    if order.is_buy {
      order.base_token
    } else {
      order.quote_token
    }
  from_asset(
    policy,
    name,
    get_payoff_qty(order.size, order.list_price_times_1bil, order.is_buy),
  )
    |> from_value_to_hydra_balance(hydra_token_policy_id)
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
