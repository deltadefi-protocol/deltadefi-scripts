use hydra_dex/withdraw_utils.{convert_shares_to_usd}

// ========== 3.1 Gross Value (Withdrawal) ==========
// Formula: grossValue = floor(sharesToRedeem * vaultEquity / totalShares)

// --- 4.1 Withdrawal at par ---

test gv_3_1_1_at_par_clean() {
  // 25M * 100M / 100M = 25M
  convert_shares_to_usd(25_000_000, 100_000_000, 100_000_000) == 25_000_000
}

test gv_3_1_1_at_par_ugly() {
  // floor(77_777_777 * 100_000_003 / 100_000_000) = 77_777_779 (rem 33_333_331)
  convert_shares_to_usd(77_777_777, 100_000_000, 100_000_003) == 77_777_779
}

// --- 4.2 Withdrawal at profit ---

test gv_3_1_2_at_profit_clean() {
  // 50M * 120M / 100M = 60M
  convert_shares_to_usd(50_000_000, 100_000_000, 120_000_000) == 60_000_000
}

test gv_3_1_2_at_profit_ugly() {
  // floor(33_333_333 * 113_456_789 / 98_765_432) = 38_291_665 (rem 93_123_457)
  convert_shares_to_usd(33_333_333, 98_765_432, 113_456_789) == 38_291_665
}

// --- 4.3 Withdrawal at loss ---

test gv_3_1_3_at_loss_clean() {
  // 50M * 80M / 100M = 40M
  convert_shares_to_usd(50_000_000, 100_000_000, 80_000_000) == 40_000_000
}

test gv_3_1_3_at_loss_ugly() {
  // floor(44_444_444 * 66_666_666 / 100_000_000) = 29_629_629 (rem 3_703_704)
  convert_shares_to_usd(44_444_444, 100_000_000, 66_666_666) == 29_629_629
}

// --- 4.4 Rounding: non-divisible numbers ---

test gv_3_1_4_rounding_clean() {
  // 33_333_333 * 100M / 100M = 33_333_333
  convert_shares_to_usd(33_333_333, 100_000_000, 100_000_000) == 33_333_333
}

test gv_3_1_4_rounding_ugly() {
  // floor(7_777_777 * 111_111_111 / 99_999_999) = 8_641_974 (rem 52_222_221)
  convert_shares_to_usd(7_777_777, 99_999_999, 111_111_111) == 8_641_974
}
