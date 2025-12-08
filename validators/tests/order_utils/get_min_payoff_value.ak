use hydra_dex/order_utils.{
  base_to_quote_qty, get_min_payoff_value, get_payoff_qty, quote_to_base_qty,
}
use tests/utils.{
  mock_account, mock_hydra_lovelace, mock_hydra_token_policy_id, mock_hydra_usd,
  mock_order, mock_order_id,
}

test ou_gmpv_1() {
  let is_buy = False
  let size = 250_000_000
  let list_price_times_1bil = 1_350_000_000
  let fee_amount_bp = 10

  let short_qty = get_payoff_qty(size, list_price_times_1bil, is_buy)

  let order =
    mock_order(
      mock_order_id,
      is_buy,
      size,
      list_price_times_1bil,
      fee_amount_bp,
      mock_account,
    )

  let order_payoff = get_min_payoff_value(order, mock_hydra_token_policy_id)
  order_payoff == mock_hydra_usd(short_qty)
}

test ou_gmpv_2() {
  let is_buy = True
  let size = 250_000_000
  let list_price_times_1bil = 1_350_000_000
  let fee_amount_bp = 10

  let long_qty = get_payoff_qty(size, list_price_times_1bil, is_buy)

  let order =
    mock_order(
      mock_order_id,
      is_buy,
      size,
      list_price_times_1bil,
      fee_amount_bp,
      mock_account,
    )

  let order_payoff = get_min_payoff_value(order, mock_hydra_token_policy_id)
  order_payoff == mock_hydra_lovelace(long_qty)
}

test ou_gmpv_3() {
  let is_buy = True
  let size = 250_000_000
  let list_price_times_1bil = 1_350_000_000
  let fee_amount_bp = 10

  let long_qty = get_payoff_qty(size, list_price_times_1bil, is_buy)

  let order =
    mock_order(
      mock_order_id,
      is_buy,
      size,
      list_price_times_1bil,
      fee_amount_bp,
      mock_account,
    )

  let order_payoff = get_min_payoff_value(order, mock_hydra_token_policy_id)
  order_payoff == mock_hydra_lovelace(long_qty)
}

// Buy Market - base qty specified (price 1.2121)
// In Aiken: is_buy = True, size = baseQty (891250911)
test ou_gmpv_4() {
  let is_buy = True
  let base_qty = 891_250_911
  let list_price_times_1bil = 1_212_100_000
  let fee_amount_bp = 10

  let quote_qty = base_to_quote_qty(base_qty, list_price_times_1bil)

  let order =
    mock_order(
      mock_order_id,
      is_buy,
      quote_qty,
      list_price_times_1bil,
      fee_amount_bp,
      mock_account,
    )

  let order_payoff = get_min_payoff_value(order, mock_hydra_token_policy_id)
  // expectedBaseQty: 891250910, expectedQuoteQty: 0
  // Since is_buy=True, we expect base (lovelace), and the payoff should equal size-1
  order_payoff == mock_hydra_lovelace(891_250_910)
}

// Buy Market - base qty specified (price 0.5211)
test ou_gmpv_5() {
  let is_buy = True
  let base_qty = 1_036_981_165
  let list_price_times_1bil = 521_100_000
  let fee_amount_bp = 10

  let quote_qty = base_to_quote_qty(base_qty, list_price_times_1bil)

  let order =
    mock_order(
      mock_order_id,
      is_buy,
      quote_qty,
      list_price_times_1bil,
      fee_amount_bp,
      mock_account,
    )

  let order_payoff = get_min_payoff_value(order, mock_hydra_token_policy_id)
  // expectedBaseQty: 1036981164, expectedQuoteQty: 0
  order_payoff == mock_hydra_lovelace(1_036_981_164)
}

// Sell Market - quote qty specified (price 0.5123)
test ou_gmpv_6() {
  let is_buy = False
  let quote_qty = 518_501_215
  let list_price_times_1bil = 512_300_000
  let fee_amount_bp = 10

  let base_qty = quote_to_base_qty(quote_qty, list_price_times_1bil)

  let order =
    mock_order(
      mock_order_id,
      is_buy,
      base_qty,
      list_price_times_1bil,
      fee_amount_bp,
      mock_account,
    )

  let order_payoff = get_min_payoff_value(order, mock_hydra_token_policy_id)
  // expectedBaseQty: 0, expectedQuoteQty: 518501214
  order_payoff == mock_hydra_usd(518_501_214)
}

// Sell Market - quote qty specified (price 0.4921)
test ou_gmpv_7() {
  let is_buy = False
  let quote_qty = 16_123_743_813
  let list_price_times_1bil = 492_100_000
  let fee_amount_bp = 10

  let base_qty = quote_to_base_qty(quote_qty, list_price_times_1bil)

  let order =
    mock_order(
      mock_order_id,
      is_buy,
      base_qty,
      list_price_times_1bil,
      fee_amount_bp,
      mock_account,
    )

  let order_payoff = get_min_payoff_value(order, mock_hydra_token_policy_id)
  // expectedBaseQty: 0, expectedQuoteQty: 16123743812
  order_payoff == mock_hydra_usd(16_123_743_812)
}

// Sell Market - quote qty specified (price 1.3533)
test ou_gmpv_8() {
  let is_buy = False
  let quote_qty = 4_251_261_361
  let list_price_times_1bil = 1_353_300_000
  let fee_amount_bp = 10

  let base_qty = quote_to_base_qty(quote_qty, list_price_times_1bil)

  let order =
    mock_order(
      mock_order_id,
      is_buy,
      base_qty,
      list_price_times_1bil,
      fee_amount_bp,
      mock_account,
    )

  let order_payoff = get_min_payoff_value(order, mock_hydra_token_policy_id)
  // expectedBaseQty: 0, expectedQuoteQty: 4251261360
  order_payoff == mock_hydra_usd(4_251_261_360)
}

// Buy Market - quote qty specified (price 1.2121)
test ou_gmpv_9() {
  let is_buy = True
  let quote_qty = 891_250_911
  let list_price_times_1bil = 1_212_100_000
  let fee_amount_bp = 10

  let order =
    mock_order(
      mock_order_id,
      is_buy,
      quote_qty,
      list_price_times_1bil,
      fee_amount_bp,
      mock_account,
    )

  let order_payoff = get_min_payoff_value(order, mock_hydra_token_policy_id)
  // expectedBaseQty: 735294869, expectedQuoteQty: 0
  order_payoff == mock_hydra_lovelace(735_294_869)
}

// Buy Market - quote qty specified (price 0.5211)
test ou_gmpv_10() {
  let is_buy = True
  let quote_qty = 1_036_981_165
  let list_price_times_1bil = 521_100_000
  let fee_amount_bp = 10

  let order =
    mock_order(
      mock_order_id,
      is_buy,
      quote_qty,
      list_price_times_1bil,
      fee_amount_bp,
      mock_account,
    )

  let order_payoff = get_min_payoff_value(order, mock_hydra_token_policy_id)
  // expectedBaseQty: 1989984964, expectedQuoteQty: 0
  order_payoff == mock_hydra_lovelace(1_989_984_964)
}

// Sell Market - base qty specified (price 0.5123)
test ou_gmpv_11() {
  let is_buy = False
  let base_qty = 518_501_215
  let list_price_times_1bil = 512_300_000
  let fee_amount_bp = 10

  let order =
    mock_order(
      mock_order_id,
      is_buy,
      base_qty,
      list_price_times_1bil,
      fee_amount_bp,
      mock_account,
    )

  let order_payoff = get_min_payoff_value(order, mock_hydra_token_policy_id)
  // expectedBaseQty: 0, expectedQuoteQty: 265628172
  order_payoff == mock_hydra_usd(265_628_172)
}

// Sell Market - base qty specified (price 0.4921)
test ou_gmpv_12() {
  let is_buy = False
  let base_qty = 16_123_743_813
  let list_price_times_1bil = 492_100_000
  let fee_amount_bp = 10

  let order =
    mock_order(
      mock_order_id,
      is_buy,
      base_qty,
      list_price_times_1bil,
      fee_amount_bp,
      mock_account,
    )

  let order_payoff = get_min_payoff_value(order, mock_hydra_token_policy_id)
  // expectedBaseQty: 0, expectedQuoteQty: 7934494330
  order_payoff == mock_hydra_usd(7_934_494_330)
}

// Sell Market - base qty specified (price 1.3533)
test ou_gmpv_13() {
  let is_buy = False
  let base_qty = 4_251_261_361
  let list_price_times_1bil = 1_353_300_000
  let fee_amount_bp = 10

  let order =
    mock_order(
      mock_order_id,
      is_buy,
      base_qty,
      list_price_times_1bil,
      fee_amount_bp,
      mock_account,
    )

  let order_payoff = get_min_payoff_value(order, mock_hydra_token_policy_id)
  // expectedBaseQty: 0, expectedQuoteQty: 5753231999
  order_payoff == mock_hydra_usd(5_753_231_999)
}
