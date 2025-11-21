use hydra_dex/order_utils.{get_fee, get_payoff_qty}

// Test cases obtained from schema test
test ou_gsq_long_1() {
  let short_qty = get_payoff_qty(100_000_000, 1_200_000_000, True)
  short_qty == 120_000_000
}

test ou_gsq_long_2() {
  let short_qty = get_payoff_qty(161_362_473, 1_411_000_000, True)
  short_qty == 227_682_449
}

test ou_gsq_long_3() {
  let short_qty = get_payoff_qty(161_362_473 - 60_245_192, 1_411_000_000, True)
  short_qty == 142_676_483
}

// test ou_gsq_short_1() {
//   let short_qty = get_payoff_qty(100_000_000, 1_200_000_000, True)
//   short_qty == 120_000_000
// }

// test ou_gsq_short_2() {
//   let short_qty = get_payoff_qty(161_362_473, 1_411_000_000, True)
//   short_qty == 227_682_449
// }

// test ou_gsq_short_3() {
//   let short_qty = get_payoff_qty(161_362_473 - 60_245_192, 1_411_000_000, True)
//   short_qty == 142_676_483
// }

test ou_gf_1() {
  let fee = get_fee(100_000_000, 20)
  fee == 200_000
}

test ou_gf_2() {
  let fee = get_fee(120_000_000, 10)
  fee == 120_000
}

test ou_gf_3() {
  let fee = get_fee(437_347_747, 10)
  fee == 437_347
}
