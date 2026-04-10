use hydra_dex/withdraw_utils.{compute_fee_shares}

// ========== 3.4 Fee Shares Minted (Withdrawal) ==========
// Formula: feeSharesMinted = floor(feeAmount * totalShares / vaultEquity)

// --- 7.1 Standard fee shares ---

test fs_3_4_1_standard_clean() {
  // floor(1M * 100M / 120M) = 833_333
  compute_fee_shares(1_000_000, 100_000_000, 120_000_000) == 833_333
}

test fs_3_4_1_standard_ugly() {
  // floor(1_444_444 * 98_765_432 / 113_456_789) = 1_257_405 (rem 1_887_263)
  compute_fee_shares(1_444_444, 98_765_432, 113_456_789) == 1_257_405
}

// --- 7.2 Zero fee => zero shares ---

test fs_3_4_2_zero_fee_clean() {
  compute_fee_shares(0, 100_000_000, 120_000_000) == 0
}

test fs_3_4_2_zero_fee_ugly() {
  compute_fee_shares(0, 77_777_777, 99_999_999) == 0
}

// --- 7.3 Large fee shares ---

test fs_3_4_3_large_fee_clean() {
  // 10M * 1_000M / 500M = 20M
  compute_fee_shares(10_000_000, 1_000_000_000, 500_000_000) == 20_000_000
}

test fs_3_4_3_large_fee_ugly() {
  // floor(7_777_777 * 888_888_888 / 444_444_444) = 15_555_554 (rem 0)
  compute_fee_shares(7_777_777, 888_888_888, 444_444_444) == 15_555_554
}

// --- 7.4 Small fee rounds to 0 shares ---

test fs_3_4_4_small_fee_clean() {
  // floor(1 * 100M / 1_000M) = floor(0.1) = 0
  compute_fee_shares(1, 100_000_000, 1_000_000_000) == 0
}

test fs_3_4_4_small_fee_ugly() {
  // floor(99 * 100M / 999_999_999) = 9 (rem 900_000_009)
  compute_fee_shares(99, 100_000_000, 999_999_999) == 9
}
