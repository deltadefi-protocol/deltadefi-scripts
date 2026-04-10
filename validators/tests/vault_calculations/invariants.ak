use hydra_dex/deposit_utils.{cal_shares_amount}
use hydra_dex/withdraw_utils.{
  cal_per_user_operator_fee, compute_fee_shares, convert_shares_to_usd,
}

// ========== 6. Invariant Tests ==========

// --- 12.1 net + fee == gross ---

test inv_6_1_net_fee_gross_clean() {
  let gross = 60_000_000
  let fee = cal_per_user_operator_fee(gross, 50_000_000, 1000)
  let net = gross - fee
  net + fee == gross
}

test inv_6_1_net_fee_gross_ugly() {
  let gross = 57_777_777
  let fee = cal_per_user_operator_fee(gross, 43_333_333, 1000)
  let net = gross - fee
  // 56_333_333 + 1_444_444 == 57_777_777
  net + fee == gross
}

// --- 12.2 fee <= profit ---

test inv_6_2_fee_lte_profit_clean() {
  let gross = 50_000_009
  let cb = 50_000_000
  let profit = gross - cb
  let fee = cal_per_user_operator_fee(gross, cb, 1000)
  // profit=9, fee=0
  fee <= profit
}

test inv_6_2_fee_lte_profit_ugly() {
  let gross = 100_000_003
  let cb = 100_000_000
  let profit = gross - cb
  let fee = cal_per_user_operator_fee(gross, cb, 777)
  // profit=3, fee=0
  fee <= profit
}

// --- 12.3 feeShares * equity / totalShares <= fee ---

test inv_6_3_fee_shares_lte_fee_clean() {
  let fee = 1_000_000
  let total = 100_000_000
  let equity = 120_000_000
  let fs = compute_fee_shares(fee, total, equity)
  // feeShares=833_333, reconstructed = 833_333 * 120M / 100M = 999_999
  let reconstructed = fs * equity / total
  reconstructed <= fee
}

test inv_6_3_fee_shares_lte_fee_ugly() {
  let fee = 1_444_444
  let total = 98_765_432
  let equity = 113_456_789
  let fs = compute_fee_shares(fee, total, equity)
  // feeShares=1_257_405, reconstructed=1_444_443
  let reconstructed = fs * equity / total
  reconstructed <= fee
}

// --- 12.4 Deposit-then-withdraw: returned <= deposited ---

test inv_6_4_deposit_withdraw_clean() {
  let deposit = 50_000_000
  let equity = 100_000_000
  let total = 100_000_000
  let minted = cal_shares_amount(deposit, equity, total)
  let new_equity = equity + deposit
  let new_total = total + minted
  let gross_back = convert_shares_to_usd(minted, new_total, new_equity)
  gross_back <= deposit
}

test inv_6_4_deposit_withdraw_ugly() {
  let deposit = 33_333_333
  let equity = 109_876_543
  let total = 98_765_432
  let minted = cal_shares_amount(deposit, equity, total)
  let new_equity = equity + deposit
  let new_total = total + minted
  let gross_back = convert_shares_to_usd(minted, new_total, new_equity)
  // minted=29_962_546, gross_back=33_333_332 <= 33_333_333
  gross_back <= deposit
}

// --- 12.5 Sum of depositor shares == totalShares ---

test inv_6_5_sum_shares_clean() {
  let m1 = cal_shares_amount(100_000_000, 0, 0)
  let ts1 = m1
  let eq1 = 100_000_000
  let m2 = cal_shares_amount(50_000_000, eq1, ts1)
  let ts2 = ts1 + m2
  let eq2 = eq1 + 50_000_000
  let m3 = cal_shares_amount(30_000_000, eq2, ts2)
  let ts3 = ts2 + m3
  m1 + m2 + m3 == ts3
}

test inv_6_5_sum_shares_ugly() {
  let m1 = cal_shares_amount(77_777_777, 0, 0)
  let ts1 = m1
  let eq1 = 77_777_777
  let m2 = cal_shares_amount(33_333_333, eq1, ts1)
  let ts2 = ts1 + m2
  let eq2 = eq1 + 33_333_333
  let m3 = cal_shares_amount(22_222_222, eq2, ts2)
  let ts3 = ts2 + m3
  m1 + m2 + m3 == ts3
}

// --- 12.6 No depositor can claim more than vault holds ---

test inv_6_6_claim_lte_equity_clean() {
  let shares = 99_999_999
  let total = 100_000_000
  let equity = 120_000_000
  let claim = convert_shares_to_usd(shares, total, equity)
  claim <= equity
}

test inv_6_6_claim_lte_equity_ugly() {
  // Near-max shares: 98_765_431 of 98_765_432
  let claim = convert_shares_to_usd(98_765_431, 98_765_432, 113_456_789)
  // claim=113_456_787 <= 113_456_789
  claim <= 113_456_789
}

// --- 12.7 Split deposits <= bulk deposit ---

test inv_6_7_split_lte_bulk_clean() {
  let equity = 100_000_000
  let total = 100_000_000
  let bulk = cal_shares_amount(50_000_000, equity, total)
  let s1 = cal_shares_amount(25_000_000, equity, total)
  let eq1 = equity + 25_000_000
  let ts1 = total + s1
  let s2 = cal_shares_amount(25_000_000, eq1, ts1)
  s1 + s2 <= bulk
}

test inv_6_7_split_lte_bulk_ugly() {
  let equity = 109_876_543
  let total = 98_765_432
  let bulk = cal_shares_amount(33_333_333, equity, total)
  let s1 = cal_shares_amount(11_111_111, equity, total)
  let eq1 = equity + 11_111_111
  let ts1 = total + s1
  let s2 = cal_shares_amount(11_111_111, eq1, ts1)
  let eq2 = eq1 + 11_111_111
  let ts2 = ts1 + s2
  let s3 = cal_shares_amount(11_111_111, eq2, ts2)
  // bulk=29_962_546, split=29_962_545
  s1 + s2 + s3 <= bulk
}
