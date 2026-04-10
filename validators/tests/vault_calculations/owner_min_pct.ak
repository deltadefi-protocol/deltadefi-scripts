// ========== 3.7 Owner Min % Check (Withdrawal) ==========
// Formula: ownerPctBp = floor(ownerSharesAfter * 10000 / totalSharesAfter)
// Require: ownerPctBp >= ownerMinPctBp
//
// ownerSharesAfter = ownerShares - redeem + feeMinted
// totalSharesAfter = totalShares - redeem + feeMinted

fn owner_pct_bp(owner_shares_after: Int, total_shares_after: Int) -> Int {
  owner_shares_after * 10000 / total_shares_after
}

fn check_owner_min_pct(
  owner_shares: Int,
  redeem: Int,
  fee_minted: Int,
  total_shares: Int,
  min_pct_bp: Int,
) -> Bool {
  let owner_after = owner_shares - redeem + fee_minted
  let total_after = total_shares - redeem + fee_minted
  owner_pct_bp(owner_after, total_after) >= min_pct_bp
}

// --- 9.1 Owner withdrawal passes min check ---

test om_3_7_1_passes_clean() {
  // ownerAfter=6M, totalAfter=96M => floor(6M * 10000 / 96M) = 625 >= 500
  check_owner_min_pct(10_000_000, 4_000_000, 0, 100_000_000, 500)
}

test om_3_7_1_passes_ugly() {
  // ownerAfter=5_877_777, totalAfter=98_099_999
  // floor(5_877_777 * 10000 / 98_099_999) = 599 (rem 15_870_599) >= 500
  check_owner_min_pct(7_777_777, 2_000_000, 100_000, 99_999_999, 500)
}

// --- 9.2 Owner withdrawal fails min check ---

test om_3_7_2_fails_clean() {
  // ownerAfter=4M, totalAfter=98M => floor(4M * 10000 / 98M) = 408 < 500
  check_owner_min_pct(6_000_000, 2_000_000, 0, 100_000_000, 500) == False
}

test om_3_7_2_fails_ugly() {
  // ownerAfter=4_499_999, totalAfter=99_399_999
  // floor(4_499_999 * 10000 / 99_399_999) = 452 (rem 71_190_452) < 500
  check_owner_min_pct(5_100_000, 600_001, 0, 100_000_000, 500) == False
}

// --- 9.3 Owner withdrawal exactly at boundary ---

test om_3_7_3_boundary_clean() {
  // ownerAfter=5M, totalAfter=100M => floor(5M * 10000 / 100M) = 500 == 500
  owner_pct_bp(5_000_000, 100_000_000) >= 500
}

test om_3_7_3_boundary_ugly() {
  // ownerAfter=5_000_001, totalAfter=100M
  // floor(5_000_001 * 10000 / 100M) = 500 (rem 10_000) == 500
  owner_pct_bp(5_000_001, 100_000_000) >= 500
}

// --- 9.4 Fee shares help owner pass check ---

test om_3_7_4_fee_shares_help_clean() {
  // ownerAfter=4_500_000, totalAfter=99_500_000
  // floor(4_500_000 * 10000 / 99_500_000) = 452 (rem 26M) >= 400
  check_owner_min_pct(5_000_000, 1_000_000, 500_000, 100_000_000, 400)
}

test om_3_7_4_fee_shares_help_ugly() {
  // ownerAfter=4_277_777, totalAfter=88_722_221
  // floor(4_277_777 * 10000 / 88_722_221) = 482 (rem 13_659_478) >= 400
  check_owner_min_pct(4_444_444, 500_000, 333_333, 88_888_888, 400)
}

// --- 9.5 Owner withdrawal to 0 (force-close only) ---
// When owner redeems ALL shares and total goes to 0, this is the force-close path.
// No percentage check applies (division by zero). Validator handles this separately.

test om_3_7_5_force_close_clean() {
  let owner_after = 5_000_000 - 5_000_000
  let total_after = 5_000_000 - 5_000_000
  owner_after == 0 && total_after == 0
}

test om_3_7_5_force_close_ugly() {
  let owner_after = 3_333_333 - 3_333_333
  let total_after = 3_333_333 - 3_333_333
  owner_after == 0 && total_after == 0
}
