use hydra_dex/order_utils.{base_to_quote_qty, quote_to_base_qty}

// TestGetQuoteQtyFromBaseQty - case 1: price 0.5125
test ou_bqc_1() {
  let base_qty = 869_129_851
  let list_price_times_1bil = 512_500_000

  let quote_qty = base_to_quote_qty(base_qty, list_price_times_1bil)
  quote_qty == 445_429_048
}

// TestGetQuoteQtyFromBaseQty - case 2: price 1.20
test ou_bqc_2() {
  let base_qty = 891_247_981
  let list_price_times_1bil = 1_200_000_000

  let quote_qty = base_to_quote_qty(base_qty, list_price_times_1bil)
  quote_qty == 1_069_497_577
}

// TestGetQuoteQtyFromBaseQty - case 3: price 0.4801
test ou_bqc_3() {
  let base_qty = 510_250_913
  let list_price_times_1bil = 480_100_000

  let quote_qty = base_to_quote_qty(base_qty, list_price_times_1bil)
  quote_qty == 244_971_463
}

// TestGetQuoteQtyFromBaseQty - case 4: price 0.4915
test ou_bqc_4() {
  let base_qty = 1_021_589_015
  let list_price_times_1bil = 491_500_000

  let quote_qty = base_to_quote_qty(base_qty, list_price_times_1bil)
  quote_qty == 502_111_000
}

// TestGetBaseQtyFromQuoteQty - case 1: price 0.5123
test ou_bqc_5() {
  let quote_qty = 518_501_215
  let list_price_times_1bil = 512_300_000

  let base_qty = quote_to_base_qty(quote_qty, list_price_times_1bil)
  base_qty == 1_012_104_655
}

// TestGetBaseQtyFromQuoteQty - case 2: price 0.4921
test ou_bqc_6() {
  let quote_qty = 16_123_743_813
  let list_price_times_1bil = 492_100_000

  let base_qty = quote_to_base_qty(quote_qty, list_price_times_1bil)
  base_qty == 32_765_177_429
}

// TestGetBaseQtyFromQuoteQty - case 3: price 1.3533
test ou_bqc_7() {
  let quote_qty = 4_251_261_361
  let list_price_times_1bil = 1_353_300_000

  let base_qty = quote_to_base_qty(quote_qty, list_price_times_1bil)
  base_qty == 3_141_403_503
}
