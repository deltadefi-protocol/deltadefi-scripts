use hydra_dex/deposit_utils.{cal_shares_amount}

// ========== 10. End-to-End Deposit Scenarios ==========
// Full state transition: sharesMinted, newTotalShares, newVaultEquity

// --- 10.1 Owner genesis deposit ---

test e2e_d_10_1_genesis_clean() {
  let deposit = 100_000_000
  let minted = cal_shares_amount(deposit, 0, 0)
  let new_total = 0 + minted
  let new_equity = 0 + deposit
  minted == 100_000_000 && new_total == 100_000_000 && new_equity == 100_000_000
}

test e2e_d_10_1_genesis_ugly() {
  let deposit = 77_777_777
  let minted = cal_shares_amount(deposit, 0, 0)
  let new_total = 0 + minted
  let new_equity = 0 + deposit
  minted == 77_777_777 && new_total == 77_777_777 && new_equity == 77_777_777
}

// --- 10.2 User deposit (vault earning) ---

test e2e_d_10_2_earning_clean() {
  let deposit = 50_000_000
  let equity = 120_000_000
  let total = 100_000_000
  let minted = cal_shares_amount(deposit, equity, total)
  let new_total = total + minted
  let new_equity = equity + deposit
  // minted = floor(50M * 100M / 120M) = 41_666_666
  minted == 41_666_666 && new_total == 141_666_666 && new_equity == 170_000_000
}

test e2e_d_10_2_earning_ugly() {
  let deposit = 37_123_456
  let equity = 113_456_789
  let total = 98_765_432
  let minted = cal_shares_amount(deposit, equity, total)
  let new_total = total + minted
  let new_equity = equity + deposit
  // minted = 32_316_392 (rem 100_787_704)
  minted == 32_316_392 && new_total == 131_081_824 && new_equity == 150_580_245
}

// --- 10.3 User deposit (vault losing) ---

test e2e_d_10_3_losing_clean() {
  let deposit = 50_000_000
  let equity = 80_000_000
  let total = 100_000_000
  let minted = cal_shares_amount(deposit, equity, total)
  let new_total = total + minted
  let new_equity = equity + deposit
  minted == 62_500_000 && new_total == 162_500_000 && new_equity == 130_000_000
}

test e2e_d_10_3_losing_ugly() {
  let deposit = 41_111_111
  let equity = 73_333_333
  let total = 100_000_000
  let minted = cal_shares_amount(deposit, equity, total)
  let new_total = total + minted
  let new_equity = equity + deposit
  // minted = 56_060_606 (rem 12_020_202)
  minted == 56_060_606 && new_total == 156_060_606 && new_equity == 114_444_444
}

// --- 10.4 Second deposit ---

test e2e_d_10_4_second_deposit_clean() {
  let deposit = 30_000_000
  let equity = 120_000_000
  let total = 100_000_000
  let minted = cal_shares_amount(deposit, equity, total)
  let new_total = total + minted
  let new_equity = equity + deposit
  minted == 25_000_000 && new_total == 125_000_000 && new_equity == 150_000_000
}

test e2e_d_10_4_second_deposit_ugly() {
  let deposit = 27_654_321
  let equity = 109_876_543
  let total = 98_765_432
  let minted = cal_shares_amount(deposit, equity, total)
  let new_total = total + minted
  let new_equity = equity + deposit
  // minted = 24_857_816 (rem 71_621_584)
  minted == 24_857_816 && new_total == 123_623_248 && new_equity == 137_530_864
}

// --- 10.5 Owner deposit when earning ---

test e2e_d_10_5_owner_earning_clean() {
  let deposit = 50_000_000
  let equity = 150_000_000
  let total = 100_000_000
  let minted = cal_shares_amount(deposit, equity, total)
  let new_total = total + minted
  let new_equity = equity + deposit
  // minted = floor(50M * 100M / 150M) = 33_333_333
  minted == 33_333_333 && new_total == 133_333_333 && new_equity == 200_000_000
}

test e2e_d_10_5_owner_earning_ugly() {
  let deposit = 88_888_888
  let equity = 133_333_333
  let total = 100_000_000
  let minted = cal_shares_amount(deposit, equity, total)
  let new_total = total + minted
  let new_equity = equity + deposit
  // minted = 66_666_666 (rem 22_222_222)
  minted == 66_666_666 && new_total == 166_666_666 && new_equity == 222_222_221
}

// --- 10.6 Owner deposit when losing ---

test e2e_d_10_6_owner_losing_clean() {
  let deposit = 50_000_000
  let equity = 80_000_000
  let total = 100_000_000
  let minted = cal_shares_amount(deposit, equity, total)
  let new_total = total + minted
  let new_equity = equity + deposit
  minted == 62_500_000 && new_total == 162_500_000 && new_equity == 130_000_000
}

test e2e_d_10_6_owner_losing_ugly() {
  let deposit = 55_555_555
  let equity = 66_666_666
  let total = 100_000_000
  let minted = cal_shares_amount(deposit, equity, total)
  let new_total = total + minted
  let new_equity = equity + deposit
  // minted = 83_333_333 (rem 22_222_222)
  minted == 83_333_333 && new_total == 183_333_333 && new_equity == 122_222_221
}

// --- 10.7 Dilution attack (rejected) ---

test e2e_d_10_7_dilution_clean() {
  let owner_shares = 5_000_000
  let total = 100_000_000
  let deposit = 10_000_000_000
  let equity = 100_000_000
  let minted = cal_shares_amount(deposit, equity, total)
  let new_total = total + minted
  // owner pct = floor(5M * 10000 / 10_100M) = 4 < 500 → REJECT
  let owner_pct = owner_shares * 10000 / new_total
  minted == 10_000_000_000 && owner_pct < 500
}

test e2e_d_10_7_dilution_ugly() {
  let owner_shares = 4_999_999
  let total = 100_000_000
  let deposit = 4_987_654_321
  let equity = 99_876_543
  let minted = cal_shares_amount(deposit, equity, total)
  let new_total = total + minted
  // minted = 4_993_819_540 (rem 78_949_780)
  // owner pct = floor(4_999_999 * 10000 / 5_093_819_540) = 9 < 500 → REJECT
  let owner_pct = owner_shares * 10000 / new_total
  minted == 4_993_819_540 && owner_pct < 500
}

// --- 10.8 Zero-share mint (rejected) ---

test e2e_d_10_8_zero_mint_clean() {
  let minted = cal_shares_amount(1, 10_000_000_000, 100_000_000)
  // floor(1 * 100M / 10B) = 0 → REJECT
  minted == 0
}

test e2e_d_10_8_zero_mint_ugly() {
  let minted = cal_shares_amount(9_999, 10_000_000_001, 1_000_000)
  // floor(9_999 * 1M / 10_000_000_001) = 0 → REJECT
  minted == 0
}

// --- 10.9 Large intermediate product precision ---

test e2e_d_10_9_large_intermediate_clean() {
  let deposit = 1_000_000_000_000
  let equity = 500_000_000_000
  let total = 500_000_000_000
  let minted = cal_shares_amount(deposit, equity, total)
  let new_total = total + minted
  let new_equity = equity + deposit
  // intermediate = 10^24
  minted == 1_000_000_000_000 && new_total == 1_500_000_000_000 && new_equity == 1_500_000_000_000
}

test e2e_d_10_9_large_intermediate_ugly() {
  let deposit = 999_999_999_999
  let equity = 777_777_777_773
  let total = 888_888_888_881
  let minted = cal_shares_amount(deposit, equity, total)
  let new_total = total + minted
  let new_equity = equity + deposit
  // 36-digit intermediate, minted = 1_142_857_142_852 (rem 682_539_682_523)
  minted == 1_142_857_142_852 && new_total == 2_031_746_031_733 && new_equity == 1_777_777_777_772
}
