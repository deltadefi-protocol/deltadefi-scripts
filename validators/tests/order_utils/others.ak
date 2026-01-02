use hydra_dex/order_utils.{get_fee}

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
