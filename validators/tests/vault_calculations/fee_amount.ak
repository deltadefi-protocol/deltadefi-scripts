use hydra_dex/withdraw_utils.{cal_per_user_operator_fee}

// ========== 3.3 Fee Amount (Withdrawal) ==========
// Formula: profit = max(0, grossValue - costBasis)
//          fee = floor(profit * feeBp / 10000)

// --- 6.1 Standard profit, 10% fee ---

test fa_3_3_1_standard_profit_clean() {
  // profit = 60M - 50M = 10M, fee = 10M * 1000 / 10000 = 1M
  cal_per_user_operator_fee(60_000_000, 50_000_000, 1000) == 1_000_000
}

test fa_3_3_1_standard_profit_ugly() {
  // profit = 57_777_777 - 43_333_333 = 14_444_444
  // fee = floor(14_444_444 * 1000 / 10000) = 1_444_444 (rem 4000)
  cal_per_user_operator_fee(57_777_777, 43_333_333, 1000) == 1_444_444
}

// --- 6.2 No profit (break even) ---

test fa_3_3_2_break_even_clean() {
  cal_per_user_operator_fee(50_000_000, 50_000_000, 1000) == 0
}

test fa_3_3_2_break_even_ugly() {
  cal_per_user_operator_fee(33_333_333, 33_333_333, 1500) == 0
}

// --- 6.3 Loss (no fee) ---

test fa_3_3_3_loss_clean() {
  cal_per_user_operator_fee(40_000_000, 50_000_000, 1000) == 0
}

test fa_3_3_3_loss_ugly() {
  cal_per_user_operator_fee(29_999_999, 33_333_333, 2000) == 0
}

// --- 6.4 Owner withdrawal (fee skipped) ---
// Note: owner fee bypass is handled at the validator level, not in cal_per_user_operator_fee.
// These tests verify the fee WOULD be charged if not bypassed.
// The validator skips calling this function for owner withdrawals.

test fa_3_3_4_owner_fee_would_apply_clean() {
  // If owner were charged: profit=10M, fee=1M
  cal_per_user_operator_fee(60_000_000, 50_000_000, 1000) == 1_000_000
}

test fa_3_3_4_owner_fee_would_apply_ugly() {
  cal_per_user_operator_fee(57_777_777, 43_333_333, 1000) == 1_444_444
}

// --- 6.5 Small profit, fee rounds to 0 ---

test fa_3_3_5_small_profit_clean() {
  // profit = 9, fee = floor(9 * 1000 / 10000) = floor(0.9) = 0
  cal_per_user_operator_fee(50_000_009, 50_000_000, 1000) == 0
}

test fa_3_3_5_small_profit_ugly() {
  // profit = 3, fee = floor(3 * 1 / 10000) = 0
  cal_per_user_operator_fee(100_000_003, 100_000_000, 1) == 0
}

// --- 6.6 20% fee rate ---

test fa_3_3_6_twenty_pct_clean() {
  // profit = 10M, fee = 10M * 2000 / 10000 = 2M
  cal_per_user_operator_fee(60_000_000, 50_000_000, 2000) == 2_000_000
}

test fa_3_3_6_twenty_pct_ugly() {
  // profit = 54_321_098 - 43_210_987 = 11_110_111
  // fee = floor(11_110_111 * 2000 / 10000) = 2_222_022 (rem 2000)
  cal_per_user_operator_fee(54_321_098, 43_210_987, 2000) == 2_222_022
}

// --- 6.7 99.99% fee rate (edge) ---

test fa_3_3_7_max_fee_clean() {
  // profit = 10M, fee = 10M * 10000 / 10000 = 10M
  cal_per_user_operator_fee(60_000_000, 50_000_000, 10000) == 10_000_000
}

test fa_3_3_7_max_fee_ugly() {
  // profit = 14_444_444, fee = floor(14_444_444 * 9999 / 10000) = 14_442_999 (rem 5556)
  cal_per_user_operator_fee(57_777_777, 43_333_333, 9999) == 14_442_999
}

// --- 6.8 Near-zero fee rate (0.03%) ---

test fa_3_3_8_near_zero_pct_clean() {
  cal_per_user_operator_fee(60_000_000, 50_000_000, 0) == 0
}

test fa_3_3_8_near_zero_pct_ugly() {
  // profit = 14_444_444, fee = floor(14_444_444 * 3 / 10000) = 4_333 (rem 3332)
  cal_per_user_operator_fee(57_777_777, 43_333_333, 3) == 4_333
}

// --- 6.9 Minimum fee rate (1 bp = 0.01%) ---

test fa_3_3_9_min_fee_rate_clean() {
  // profit = 10M, fee = floor(10M * 1 / 10000) = 1_000
  cal_per_user_operator_fee(60_000_000, 50_000_000, 1) == 1_000
}

test fa_3_3_9_min_fee_rate_ugly() {
  // profit = 99_999, fee = floor(99_999 * 1 / 10000) = 9 (rem 9999)
  cal_per_user_operator_fee(50_099_999, 50_000_000, 1) == 9
}
