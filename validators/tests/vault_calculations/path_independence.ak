use hydra_dex/withdraw_utils.{
  cal_per_user_operator_fee, compute_fee_shares, convert_shares_to_usd,
}

// ========== 4.2 Path Independence (Profit Case) ==========
// Withdrawing in parts vs all at once: total fee should be equal or differ by at most N-1
// due to floor rounding.
// Pure arithmetic: floor(total * bp / 10000) >= SUM(floor(part_i * bp / 10000))
// With state changes (fee shares, equity reduction): difference remains bounded.

fn cost_basis(total_deposited: Int, redeem: Int, user_shares: Int) -> Int {
  total_deposited * redeem / user_shares
}

// --- 4.2.1 Pure arithmetic: single fee >= split fees ---

test pi_4_2_1_arithmetic_clean() {
  // profit=20M, bp=1000. 4-split of 5M each (exact division)
  let f_single = 20_000_000 * 1000 / 10000
  let f_split =
    4 * ( 5_000_000 * 1000 / 10000 )
  // single=2M, split=2M, diff=0
  f_single >= f_split
}

test pi_4_2_1_arithmetic_ugly() {
  // profit=13_333_337, bp=1337. 3-split (non-divisible)
  let f_single = 13_333_337 * 1337 / 10000
  let f1 = 4_444_445 * 1337 / 10000
  let f2 = 4_444_446 * 1337 / 10000
  let f3 = 4_444_446 * 1337 / 10000
  // single=1_782_667, split=1_782_666, diff=1
  f_single >= f1 + f2 + f3
}

// --- 4.2.2 With state changes: single vs N-split ---

test pi_4_2_2_with_state_clean() {
  let equity = 120_000_000
  let total = 100_000_000
  let deposited = 100_000_000
  let user_shares = 100_000_000

  // Single withdrawal: all 100M shares
  let gross_single = convert_shares_to_usd(user_shares, total, equity)
  let fee_single =
    cal_per_user_operator_fee(gross_single, deposited, 1000)
  // fee = 2_000_000

  // 4-split: 25M shares each, state mutates between
  // Split 1
  let g1 = convert_shares_to_usd(25_000_000, total, equity)
  let cb1 = cost_basis(deposited, 25_000_000, user_shares)
  let f1 = cal_per_user_operator_fee(g1, cb1, 1000)
  let fs1 = compute_fee_shares(f1, total, equity)
  let eq1 = equity - ( g1 - f1 )
  let ts1 = total - 25_000_000 + fs1
  let dep1 = deposited - cb1
  let ush1 = user_shares - 25_000_000

  // Split 2
  let g2 = convert_shares_to_usd(25_000_000, ts1, eq1)
  let cb2 = cost_basis(dep1, 25_000_000, ush1)
  let f2 = cal_per_user_operator_fee(g2, cb2, 1000)
  let fs2 = compute_fee_shares(f2, ts1, eq1)
  let eq2 = eq1 - ( g2 - f2 )
  let ts2 = ts1 - 25_000_000 + fs2
  let dep2 = dep1 - cb2
  let ush2 = ush1 - 25_000_000

  // Split 3
  let g3 = convert_shares_to_usd(25_000_000, ts2, eq2)
  let cb3 = cost_basis(dep2, 25_000_000, ush2)
  let f3 = cal_per_user_operator_fee(g3, cb3, 1000)
  let fs3 = compute_fee_shares(f3, ts2, eq2)
  let eq3 = eq2 - ( g3 - f3 )
  let ts3 = ts2 - 25_000_000 + fs3
  let dep3 = dep2 - cb3
  let ush3 = ush2 - 25_000_000

  // Split 4
  let g4 = convert_shares_to_usd(ush3, ts3, eq3)
  let cb4 = cost_basis(dep3, ush3, ush3)
  let f4 = cal_per_user_operator_fee(g4, cb4, 1000)

  let fee_split = f1 + f2 + f3 + f4
  // single=2M, split=2M, diff=0
  let diff = fee_single - fee_split
  diff >= 0 && diff <= 3
}

test pi_4_2_2_with_state_ugly() {
  let equity = 113_456_789
  let total = 98_765_432
  let deposited = 77_777_777
  let user_shares = 77_777_777

  // Single withdrawal
  let gross_single = convert_shares_to_usd(user_shares, total, equity)
  let fee_single =
    cal_per_user_operator_fee(gross_single, deposited, 1337)

  // 3-split: ~25_925_925 each
  let r1 = 25_925_925
  let g1 = convert_shares_to_usd(r1, total, equity)
  let cb1 = cost_basis(deposited, r1, user_shares)
  let f1 = cal_per_user_operator_fee(g1, cb1, 1337)
  let fs1 = compute_fee_shares(f1, total, equity)
  let eq1 = equity - ( g1 - f1 )
  let ts1 = total - r1 + fs1
  let dep1 = deposited - cb1
  let ush1 = user_shares - r1

  let r2 = 25_925_925
  let g2 = convert_shares_to_usd(r2, ts1, eq1)
  let cb2 = cost_basis(dep1, r2, ush1)
  let f2 = cal_per_user_operator_fee(g2, cb2, 1337)
  let fs2 = compute_fee_shares(f2, ts1, eq1)
  let eq2 = eq1 - ( g2 - f2 )
  let ts2 = ts1 - r2 + fs2
  let dep2 = dep1 - cb2
  let ush2 = ush1 - r2

  let g3 = convert_shares_to_usd(ush2, ts2, eq2)
  let cb3 = cost_basis(dep2, ush2, ush2)
  let f3 = cal_per_user_operator_fee(g3, cb3, 1337)

  let fee_split = f1 + f2 + f3
  // diff should be 0 or 1
  let diff = fee_single - fee_split
  diff >= 0 && diff <= 2
}
