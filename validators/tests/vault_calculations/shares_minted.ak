use hydra_dex/deposit_utils.{cal_shares_amount}

// ========== 2.1 Shares Minted (Deposit) ==========
// Formula: sharesMinted = floor(depositAmount * totalShares / vaultEquity)
// Genesis: sharesMinted = depositAmount when totalShares == 0

// --- 2.1 Owner genesis deposit (first ever) ---

test sm_2_1_1_genesis_deposit_clean() {
  cal_shares_amount(100_000_000, 0, 0) == 100_000_000
}

test sm_2_1_1_genesis_deposit_ugly() {
  cal_shares_amount(77_777_777, 0, 0) == 77_777_777
}

// --- 2.2 User first deposit (vault at par) ---

test sm_2_1_2_deposit_at_par_clean() {
  cal_shares_amount(50_000_000, 100_000_000, 100_000_000) == 50_000_000
}

test sm_2_1_2_deposit_near_par_ugly() {
  // floor(33_333_333 * 100_000_000 / 99_999_997) = 33_333_334
  cal_shares_amount(33_333_333, 99_999_997, 100_000_000) == 33_333_334
}

// --- 2.3 User deposit when vault earning ---

test sm_2_1_3_deposit_vault_earning_clean() {
  // floor(50M * 100M / 120M) = 41_666_666
  cal_shares_amount(50_000_000, 120_000_000, 100_000_000) == 41_666_666
}

test sm_2_1_3_deposit_vault_earning_ugly() {
  // floor(37_123_456 * 98_765_432 / 113_456_789) = 32_316_392
  cal_shares_amount(37_123_456, 113_456_789, 98_765_432) == 32_316_392
}

// --- 2.4 User deposit when vault losing ---

test sm_2_1_4_deposit_vault_losing_clean() {
  // floor(50M * 100M / 80M) = 62_500_000
  cal_shares_amount(50_000_000, 80_000_000, 100_000_000) == 62_500_000
}

test sm_2_1_4_deposit_vault_losing_ugly() {
  // floor(41_111_111 * 100_000_000 / 73_333_333) = 56_060_606
  cal_shares_amount(41_111_111, 73_333_333, 100_000_000) == 56_060_606
}

// --- 2.5 Owner deposit when vault earning ---

test sm_2_1_5_owner_deposit_earning_clean() {
  // floor(100M * 100M / 150M) = 66_666_666
  cal_shares_amount(100_000_000, 150_000_000, 100_000_000) == 66_666_666
}

test sm_2_1_5_owner_deposit_earning_ugly() {
  // floor(88_888_888 * 100_000_000 / 133_333_333) = 66_666_666
  cal_shares_amount(88_888_888, 133_333_333, 100_000_000) == 66_666_666
}

// --- 2.6 Owner deposit when vault losing ---

test sm_2_1_6_owner_deposit_losing_clean() {
  // floor(100M * 100M / 80M) = 125_000_000
  cal_shares_amount(100_000_000, 80_000_000, 100_000_000) == 125_000_000
}

test sm_2_1_6_owner_deposit_losing_ugly() {
  // floor(55_555_555 * 100_000_000 / 66_666_666) = 83_333_333
  cal_shares_amount(55_555_555, 66_666_666, 100_000_000) == 83_333_333
}

// --- 2.7 Dilution attack ---
// Verify sharesMinted is correct, then check ownerShares * 10000 / newTotalShares < minPctBp => REJECT

fn check_owner_diluted(
  owner_shares: Int,
  new_total_shares: Int,
  min_pct_bp: Int,
) -> Bool {
  owner_shares * 10000 / new_total_shares < min_pct_bp
}

test sm_2_1_7_dilution_attack_clean() {
  // owner has 5M of 100M (5%). ownerMinPctBp=500.
  // User deposits 10_000M at par (equity=100M, shares=100M)
  let minted = cal_shares_amount(10_000_000_000, 100_000_000, 100_000_000)
  // minted = 10_000_000_000
  let new_total = 100_000_000 + minted
  // owner: 5M / 10_100_000_000 * 10000 = 4 < 500 => diluted
  check_owner_diluted(5_000_000, new_total, 500)
}

test sm_2_1_7_dilution_attack_ugly() {
  // owner=4_999_999 of 99_999_999.
  let minted = cal_shares_amount(5_000_000_000, 99_999_999, 99_999_999)
  let new_total = 99_999_999 + minted
  // owner: 4_999_999 / 5_099_999_999 * 10000 = 9 < 500 => diluted
  check_owner_diluted(4_999_999, new_total, 500)
}

// --- 2.8 Small deposit that mints 0 shares => REJECT ---

test sm_2_1_8_zero_shares_mint_clean() {
  // deposit=1, equity=1B, shares=100M => floor(1 * 100M / 1B) = 0
  cal_shares_amount(1, 1_000_000_000, 100_000_000) == 0
}

test sm_2_1_8_zero_shares_mint_ugly() {
  // deposit=999, equity=1_000_000_001, shares=1M => floor(999 * 1M / 1_000_000_001) = 0
  cal_shares_amount(999, 1_000_000_001, 1_000_000) == 0
}

// --- 2.9 Large intermediate product precision ---

test sm_2_1_9_large_intermediate_clean() {
  // deposit=1T, equity=500B, shares=500B => intermediate=10^24, result=1T
  cal_shares_amount(
    1_000_000_000_000,
    500_000_000_000,
    500_000_000_000,
  ) == 1_000_000_000_000
}

test sm_2_1_9_large_intermediate_ugly() {
  // deposit=999_999_999_999, equity=777_777_777_777, shares=888_888_888_888
  // intermediate has 36 digits
  cal_shares_amount(
    999_999_999_999,
    777_777_777_777,
    888_888_888_888,
  ) == 1_142_857_142_856
}

// --- 2.10 Deposit of 1 lovelace that still mints > 0 ---

test sm_2_1_10_tiny_deposit_mints_shares_clean() {
  // deposit=1, equity=100, shares=100M => floor(1 * 100M / 100) = 1_000_000
  cal_shares_amount(1, 100, 100_000_000) == 1_000_000
}

test sm_2_1_10_tiny_deposit_mints_shares_ugly() {
  // deposit=1, equity=3, shares=10M => floor(10M / 3) = 3_333_333
  cal_shares_amount(1, 3, 10_000_000) == 3_333_333
}
