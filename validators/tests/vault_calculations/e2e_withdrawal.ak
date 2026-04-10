use hydra_dex/withdraw_utils.{
  cal_per_user_operator_fee, compute_fee_shares, convert_shares_to_usd,
}

// ========== 11. End-to-End Withdrawal Scenarios ==========
// Full pipeline: grossValue → costBasis → profit → fee → feeShares → net → newTotal

fn cost_basis(total_deposited: Int, redeem: Int, user_shares: Int) -> Int {
  total_deposited * redeem / user_shares
}

// --- 11.1 User full withdrawal at profit ---

test e2e_w_11_1_user_profit_clean() {
  let equity = 120_000_000
  let total = 100_000_000
  let redeem = 50_000_000
  let gross = convert_shares_to_usd(redeem, total, equity)
  let cb = cost_basis(50_000_000, redeem, 50_000_000)
  let fee = cal_per_user_operator_fee(gross, cb, 1000)
  let fee_sh = compute_fee_shares(fee, total, equity)
  let net = gross - fee
  let new_total = total - redeem + fee_sh
  gross == 60_000_000 && cb == 50_000_000 && fee == 1_000_000 && fee_sh == 833_333 && net == 59_000_000 && new_total == 50_833_333
}

test e2e_w_11_1_user_profit_ugly() {
  let equity = 113_456_789
  let total = 98_765_432
  let redeem = 33_333_333
  let gross = convert_shares_to_usd(redeem, total, equity)
  let cb = cost_basis(33_333_333, redeem, 33_333_333)
  let fee = cal_per_user_operator_fee(gross, cb, 1000)
  let fee_sh = compute_fee_shares(fee, total, equity)
  let net = gross - fee
  let new_total = total - redeem + fee_sh
  // gross=38_291_665 (rem 93M), fee=495_833 (rem 2K), feeShares=431_628 (rem 33M)
  gross == 38_291_665 && cb == 33_333_333 && fee == 495_833 && fee_sh == 431_628 && net == 37_795_832 && new_total == 65_863_727
}

// --- 11.2 User full withdrawal at loss ---

test e2e_w_11_2_user_loss_clean() {
  let equity = 80_000_000
  let total = 100_000_000
  let redeem = 50_000_000
  let gross = convert_shares_to_usd(redeem, total, equity)
  let cb = cost_basis(50_000_000, redeem, 50_000_000)
  let fee = cal_per_user_operator_fee(gross, cb, 1000)
  let new_total = total - redeem
  gross == 40_000_000 && cb == 50_000_000 && fee == 0 && new_total == 50_000_000
}

test e2e_w_11_2_user_loss_ugly() {
  let equity = 66_666_666
  let total = 100_000_000
  let redeem = 44_444_444
  let gross = convert_shares_to_usd(redeem, total, equity)
  let cb = cost_basis(44_444_444, redeem, 44_444_444)
  let fee = cal_per_user_operator_fee(gross, cb, 1500)
  let new_total = total - redeem
  // gross=29_629_629 (rem 3.7M), loss → fee=0
  gross == 29_629_629 && cb == 44_444_444 && fee == 0 && new_total == 55_555_556
}

// --- 11.3 User partial withdrawal at profit ---

test e2e_w_11_3_user_partial_profit_clean() {
  let equity = 120_000_000
  let total = 100_000_000
  let redeem = 25_000_000
  let gross = convert_shares_to_usd(redeem, total, equity)
  let cb = cost_basis(100_000_000, redeem, 100_000_000)
  let fee = cal_per_user_operator_fee(gross, cb, 1000)
  let fee_sh = compute_fee_shares(fee, total, equity)
  let net = gross - fee
  let new_total = total - redeem + fee_sh
  gross == 30_000_000 && cb == 25_000_000 && fee == 500_000 && fee_sh == 416_666 && net == 29_500_000 && new_total == 75_416_666
}

test e2e_w_11_3_user_partial_profit_ugly() {
  let equity = 113_456_789
  let total = 98_765_432
  let redeem = 22_222_222
  let gross = convert_shares_to_usd(redeem, total, equity)
  let cb = cost_basis(77_777_777, redeem, 77_777_777)
  let fee = cal_per_user_operator_fee(gross, cb, 1000)
  let fee_sh = compute_fee_shares(fee, total, equity)
  let net = gross - fee
  let new_total = total - redeem + fee_sh
  gross == 25_527_777 && cb == 22_222_222 && fee == 330_555 && fee_sh == 287_751 && net == 25_197_222 && new_total == 76_830_961
}

// --- 11.4 User partial withdrawal at loss ---

test e2e_w_11_4_user_partial_loss_clean() {
  let equity = 90_000_000
  let total = 100_000_000
  let redeem = 20_000_000
  let gross = convert_shares_to_usd(redeem, total, equity)
  let cb = cost_basis(100_000_000, redeem, 100_000_000)
  let fee = cal_per_user_operator_fee(gross, cb, 1000)
  let new_total = total - redeem
  gross == 18_000_000 && cb == 20_000_000 && fee == 0 && new_total == 80_000_000
}

test e2e_w_11_4_user_partial_loss_ugly() {
  let equity = 66_666_666
  let total = 98_765_432
  let redeem = 22_222_222
  let gross = convert_shares_to_usd(redeem, total, equity)
  let cb = cost_basis(77_777_777, redeem, 77_777_777)
  let fee = cal_per_user_operator_fee(gross, cb, 1000)
  let new_total = total - redeem
  // gross=14_999_999 (rem 70M), loss → fee=0
  gross == 14_999_999 && cb == 22_222_222 && fee == 0 && new_total == 76_543_210
}

// --- 11.5 User partial withdrawal near par ---

test e2e_w_11_5_user_partial_par_clean() {
  let equity = 100_000_000
  let total = 100_000_000
  let redeem = 25_000_000
  let gross = convert_shares_to_usd(redeem, total, equity)
  let cb = cost_basis(100_000_000, redeem, 100_000_000)
  let fee = cal_per_user_operator_fee(gross, cb, 1000)
  let new_total = total - redeem
  gross == 25_000_000 && cb == 25_000_000 && fee == 0 && new_total == 75_000_000
}

test e2e_w_11_5_user_partial_par_ugly() {
  let equity = 99_999_997
  let total = 98_765_432
  let redeem = 22_222_222
  let gross = convert_shares_to_usd(redeem, total, equity)
  let cb = cost_basis(77_777_777, redeem, 77_777_777)
  let fee = cal_per_user_operator_fee(gross, cb, 1000)
  let fee_sh = compute_fee_shares(fee, total, equity)
  let net = gross - fee
  let new_total = total - redeem + fee_sh
  // near par: small profit=277_777, fee=27_777, feeShares=27_434
  gross == 22_499_999 && cb == 22_222_222 && fee == 27_777 && fee_sh == 27_434 && net == 22_472_222 && new_total == 76_570_644
}

// --- 11.6 Owner partial at profit (no fee) ---

test e2e_w_11_6_owner_profit_clean() {
  let equity = 120_000_000
  let total = 100_000_000
  let redeem = 10_000_000
  let gross = convert_shares_to_usd(redeem, total, equity)
  let cb = cost_basis(50_000_000, redeem, 50_000_000)
  // Owner: fee skipped
  let new_total = total - redeem
  gross == 12_000_000 && cb == 10_000_000 && new_total == 90_000_000
}

test e2e_w_11_6_owner_profit_ugly() {
  let equity = 113_456_789
  let total = 98_765_432
  let redeem = 11_111_111
  let gross = convert_shares_to_usd(redeem, total, equity)
  let cb = cost_basis(44_444_444, redeem, 44_444_444)
  // Owner: fee skipped. gross=12_763_888 (rem 63M)
  let new_total = total - redeem
  gross == 12_763_888 && cb == 11_111_111 && new_total == 87_654_321
}

// --- 11.7 Owner partial at loss ---

test e2e_w_11_7_owner_loss_clean() {
  let equity = 80_000_000
  let total = 100_000_000
  let redeem = 10_000_000
  let gross = convert_shares_to_usd(redeem, total, equity)
  let cb = cost_basis(50_000_000, redeem, 50_000_000)
  let new_total = total - redeem
  gross == 8_000_000 && cb == 10_000_000 && new_total == 90_000_000
}

test e2e_w_11_7_owner_loss_ugly() {
  let equity = 73_333_333
  let total = 98_765_432
  let redeem = 11_111_111
  let gross = convert_shares_to_usd(redeem, total, equity)
  let cb = cost_basis(44_444_444, redeem, 44_444_444)
  // gross=8_249_999 (rem 87M)
  let new_total = total - redeem
  gross == 8_249_999 && cb == 11_111_111 && new_total == 87_654_321
}

// --- 11.8 Owner partial near par ---

test e2e_w_11_8_owner_par_clean() {
  let equity = 100_000_000
  let total = 100_000_000
  let redeem = 10_000_000
  let gross = convert_shares_to_usd(redeem, total, equity)
  let cb = cost_basis(50_000_000, redeem, 50_000_000)
  let new_total = total - redeem
  gross == 10_000_000 && cb == 10_000_000 && new_total == 90_000_000
}

test e2e_w_11_8_owner_par_ugly() {
  let equity = 99_999_997
  let total = 98_765_432
  let redeem = 11_111_111
  let gross = convert_shares_to_usd(redeem, total, equity)
  let cb = cost_basis(44_444_444, redeem, 44_444_444)
  // Owner: fee skipped even though profit=138_888. gross=11_249_999 (rem 55M)
  let new_total = total - redeem
  gross == 11_249_999 && cb == 11_111_111 && new_total == 87_654_321
}

// --- 11.9 Owner withdrawal fails min % ---

test e2e_w_11_9_owner_fails_min_pct_clean() {
  let redeem = 2_000_000
  let gross = convert_shares_to_usd(redeem, 100_000_000, 100_000_000)
  let new_total = 100_000_000 - redeem
  let owner_after = 6_000_000 - redeem
  // pct = floor(4M * 10000 / 98M) = 408 < 500 → REJECT
  let pct = owner_after * 10000 / new_total
  gross == 2_000_000 && pct < 500
}

test e2e_w_11_9_owner_fails_min_pct_ugly() {
  let redeem = 1_777_777
  let gross = convert_shares_to_usd(redeem, 98_765_432, 109_876_543)
  let new_total = 98_765_432 - redeem
  let owner_after = 5_555_555 - redeem
  // gross=1_977_776 (rem 89M), pct = floor(3_777_778 * 10000 / 96_987_655) = 389 < 500
  let pct = owner_after * 10000 / new_total
  gross == 1_977_776 && pct < 500
}

// --- 11.10 User withdrawal: fee shares boost owner pct ---

test e2e_w_11_10_fee_shares_boost_owner_clean() {
  let equity = 120_000_000
  let total = 100_000_000
  let redeem = 10_000_000
  let gross = convert_shares_to_usd(redeem, total, equity)
  let cb = cost_basis(10_000_000, redeem, 10_000_000)
  let fee = cal_per_user_operator_fee(gross, cb, 1000)
  let fee_sh = compute_fee_shares(fee, total, equity)
  let new_total = total - redeem + fee_sh
  let owner_after = 6_000_000 + fee_sh
  let pct = owner_after * 10000 / new_total
  // fee=200_000, feeShares=166_666, ownerAfter=6_166_666, pct=683 >= 500
  fee == 200_000 && fee_sh == 166_666 && pct >= 500
}

test e2e_w_11_10_fee_shares_boost_owner_ugly() {
  let equity = 113_456_789
  let total = 98_765_432
  let redeem = 11_111_111
  let gross = convert_shares_to_usd(redeem, total, equity)
  let cb = cost_basis(11_111_111, redeem, 11_111_111)
  let fee = cal_per_user_operator_fee(gross, cb, 1000)
  let fee_sh = compute_fee_shares(fee, total, equity)
  let new_total = total - redeem + fee_sh
  let owner_after = 5_555_555 + fee_sh
  let pct = owner_after * 10000 / new_total
  // fee=165_277 (rem 7K), feeShares=143_875 (rem 58M), ownerAfter=5_699_430, pct=649
  fee == 165_277 && fee_sh == 143_875 && pct >= 500
}
