use hydra_dex/order_utils.{get_min_order_value}
use tests/utils.{
  mock_account, mock_hydra_lovelace, mock_hydra_usd, mock_limit_order,
  mock_order_id,
}

test ou_gmov_1() {
  let is_buy = False
  let size = 250_000_000
  let list_price_times_1bil = 1_350_000_000
  let fee_amount_bp = 10

  let order =
    mock_limit_order(
      mock_order_id,
      is_buy,
      size,
      list_price_times_1bil,
      fee_amount_bp,
      mock_account,
    )

  let min_order_value = get_min_order_value(order)
  min_order_value == mock_hydra_lovelace(size)
}

test ou_gmov_2() {
  let is_buy = True
  let size = 250_000_000
  let list_price_times_1bil = 1_350_000_000
  let fee_amount_bp = 10

  let order =
    mock_limit_order(
      mock_order_id,
      is_buy,
      size,
      list_price_times_1bil,
      fee_amount_bp,
      mock_account,
    )
  let min_order_value = get_min_order_value(order)
  min_order_value == mock_hydra_usd(size)
}

test ou_gmov_3() {
  let is_buy = True
  let size = 250_000_000
  let list_price_times_1bil = 1_350_000_000
  let fee_amount_bp = 10
  let order =
    mock_limit_order(
      mock_order_id,
      is_buy,
      size,
      list_price_times_1bil,
      fee_amount_bp,
      mock_account,
    )
  let min_order_value = get_min_order_value(order)
  min_order_value == mock_hydra_usd(size)
}
