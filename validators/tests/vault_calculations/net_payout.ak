// ========== 3.5 Net Payout (Withdrawal) ==========
// Formula: netPayout = grossValue - feeAmount

fn calculate_net_payout(gross_value: Int, fee_amount: Int) -> Int {
  gross_value - fee_amount
}

// --- 8.1 Standard payout with fee ---

test np_3_5_1_standard_payout_clean() {
  // 60M - 1M = 59M
  calculate_net_payout(60_000_000, 1_000_000) == 59_000_000
}

test np_3_5_1_standard_payout_ugly() {
  // 57_777_777 - 1_444_444 = 56_333_333
  calculate_net_payout(57_777_777, 1_444_444) == 56_333_333
}

// --- 8.2 No fee (loss) ---

test np_3_5_2_no_fee_loss_clean() {
  calculate_net_payout(40_000_000, 0) == 40_000_000
}

test np_3_5_2_no_fee_loss_ugly() {
  calculate_net_payout(29_999_999, 0) == 29_999_999
}

// --- 8.3 No fee (owner) ---

test np_3_5_3_no_fee_owner_clean() {
  calculate_net_payout(60_000_000, 0) == 60_000_000
}

test np_3_5_3_no_fee_owner_ugly() {
  calculate_net_payout(57_777_777, 0) == 57_777_777
}

// --- 8.4 Invariant: net + fee == gross ---

test np_3_5_4_invariant_clean() {
  let gross = 60_000_000
  let fee = 1_000_000
  let net = calculate_net_payout(gross, fee)
  net + fee == gross
}

test np_3_5_4_invariant_ugly() {
  let gross = 54_321_098
  let fee = 2_222_022
  let net = calculate_net_payout(gross, fee)
  // 52_099_076 + 2_222_022 == 54_321_098
  net + fee == gross
}
