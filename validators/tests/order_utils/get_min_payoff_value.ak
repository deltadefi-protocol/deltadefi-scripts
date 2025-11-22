use hydra_dex/order_utils.{get_min_payoff_value, get_payoff_qty}
use tests/utils.{
  mock_account, mock_hydra_lovelace, mock_hydra_token_policy_id, mock_hydra_usd,
  mock_order, mock_order_id,
}

test ou_gmpv_1() {
  let is_long = False
  let size = 250_000_000
  let list_price_times_1bil = 1_350_000_000
  let fee_amount_bp = 10

  let short_qty = get_payoff_qty(size, list_price_times_1bil, is_long)

  let order =
    mock_order(
      mock_order_id,
      is_long,
      size,
      list_price_times_1bil,
      fee_amount_bp,
      mock_account,
    )

  let order_payoff = get_min_payoff_value(order, mock_hydra_token_policy_id)
  order_payoff == mock_hydra_usd(short_qty)
}

test ou_gmpv_2() {
  let is_long = True
  let size = 250_000_000
  let list_price_times_1bil = 1_350_000_000
  let fee_amount_bp = 10

  let long_qty = get_payoff_qty(size, list_price_times_1bil, is_long)

  let order =
    mock_order(
      mock_order_id,
      is_long,
      size,
      list_price_times_1bil,
      fee_amount_bp,
      mock_account,
    )

  let order_payoff = get_min_payoff_value(order, mock_hydra_token_policy_id)
  order_payoff == mock_hydra_lovelace(long_qty)
}

test ou_gmpv_3() {
  let is_long = True
  let size = 250_000_000
  let list_price_times_1bil = 1_350_000_000
  let fee_amount_bp = 10

  let long_qty = get_payoff_qty(size, list_price_times_1bil, is_long)

  let order =
    mock_order(
      mock_order_id,
      is_long,
      size,
      list_price_times_1bil,
      fee_amount_bp,
      mock_account,
    )

  let order_payoff = get_min_payoff_value(order, mock_hydra_token_policy_id)
  order_payoff == mock_hydra_lovelace(long_qty)
}
