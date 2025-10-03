use cardano/assets.{from_lovelace}
use hydra_dex/order_utils.{get_fee, get_order_settlement_info, get_short_qty}
use tests/utils.{mock_account, mock_order, mock_order_id, mock_usd}

test ou_gosi_1() {
  let is_long = False
  let order_size = 250_000_000
  let list_price_times_1bil = 1_350_000_000
  let fee_amount_bp = 10
  let extra_value = 0

  let short_qty = get_short_qty(order_size, list_price_times_1bil)

  let order =
    mock_order(
      mock_order_id,
      is_long,
      order_size,
      list_price_times_1bil,
      fee_amount_bp,
      extra_value,
      mock_account,
    )

  let (order_value, order_payoff, _, fee_amount) =
    get_order_settlement_info(order, None)
  let is_order_value_correct = order_value == from_lovelace(order_size)
  let is_order_payoff_correct = order_payoff == mock_usd(short_qty)
  let is_fee_amount_correct =
    fee_amount == mock_usd(get_fee(short_qty, fee_amount_bp))
  is_order_value_correct? && is_order_payoff_correct? && is_fee_amount_correct?
}

test ou_gosi_2() {
  let is_long = True
  let order_size = 250_000_000
  let list_price_times_1bil = 1_350_000_000
  let fee_amount_bp = 10
  let extra_value = 0

  let short_qty = get_short_qty(order_size, list_price_times_1bil)

  let order =
    mock_order(
      mock_order_id,
      is_long,
      order_size,
      list_price_times_1bil,
      fee_amount_bp,
      extra_value,
      mock_account,
    )

  let (order_value, order_payoff, _, fee_amount) =
    get_order_settlement_info(order, None)
  let is_order_value_correct = order_value == mock_usd(short_qty)
  let is_order_payoff_correct = order_payoff == from_lovelace(order_size)
  let is_fee_amount_correct =
    fee_amount == from_lovelace(get_fee(order_size, fee_amount_bp))
  is_order_value_correct? && is_order_payoff_correct? && is_fee_amount_correct?
}

test ou_gosi_3() {
  let is_long = True
  let order_size = 250_000_000
  let list_price_times_1bil = 1_350_000_000
  let fee_amount_bp = 10
  let extra_value = 100_000_000

  let short_qty = get_short_qty(order_size, list_price_times_1bil)

  let order =
    mock_order(
      mock_order_id,
      is_long,
      order_size,
      list_price_times_1bil,
      fee_amount_bp,
      extra_value,
      mock_account,
    )

  let (order_value, order_payoff, extra_value_value, fee_amount) =
    get_order_settlement_info(order, None)
  let is_order_value_correct = order_value == mock_usd(short_qty)
  let is_extra_value_correct = extra_value_value == mock_usd(extra_value)
  let is_order_payoff_correct = order_payoff == from_lovelace(order_size)
  let is_fee_amount_correct =
    fee_amount == from_lovelace(get_fee(order_size, fee_amount_bp))
  is_order_value_correct? && is_order_payoff_correct? && is_extra_value_correct? && is_fee_amount_correct?
}
