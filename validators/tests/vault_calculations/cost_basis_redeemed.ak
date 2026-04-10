// ========== 3.2 Cost Basis Redeemed (Withdrawal) ==========
// Formula: costBasisRedeemed = floor(total_deposited * shares_to_redeem / user_shares)
// On-chain: old_entry.total_deposited * shares_to_redeem / old_entry.shares

fn calculate_cost_basis(
  total_deposited: Int,
  shares_to_redeem: Int,
  user_shares: Int,
) -> Int {
  total_deposited * shares_to_redeem / user_shares
}

// --- 5.1 Full withdrawal (all shares) ---

test cb_3_2_1_full_withdrawal_clean() {
  // 100M * 100M / 100M = 100M
  calculate_cost_basis(100_000_000, 100_000_000, 100_000_000) == 100_000_000
}

test cb_3_2_1_full_withdrawal_ugly() {
  // Near-full: floor(83_456_789 * 77_777_776 / 77_777_777) = 83_456_787 (rem 72_098_765)
  calculate_cost_basis(83_456_789, 77_777_776, 77_777_777) == 83_456_787
}

// --- 5.2 Partial withdrawal (half) ---

test cb_3_2_2_partial_half_clean() {
  // 100M * 50M / 100M = 50M
  calculate_cost_basis(100_000_000, 50_000_000, 100_000_000) == 50_000_000
}

test cb_3_2_2_partial_half_ugly() {
  // floor(123_456_789 * 33_333_333 / 77_777_777) = 52_910_052 (rem 33_333_333)
  calculate_cost_basis(123_456_789, 33_333_333, 77_777_777) == 52_910_052
}

// --- 5.3 Partial withdrawal (1/3) ---

test cb_3_2_3_partial_third_clean() {
  // 90M * 30M / 90M = 30M
  calculate_cost_basis(90_000_000, 30_000_000, 90_000_000) == 30_000_000
}

test cb_3_2_3_partial_third_ugly() {
  // floor(109_876_543 * 33_333_333 / 98_765_432) = 37_083_332 (rem 91_728_395)
  calculate_cost_basis(109_876_543, 33_333_333, 98_765_432) == 37_083_332
}

// --- 5.4 After blended cost (multiple deposits) ---

test cb_3_2_4_blended_cost_clean() {
  // floor(150M * 50M / 141_666_666) = 52_941_176 (rem 101_960_784)
  calculate_cost_basis(150_000_000, 50_000_000, 141_666_666) == 52_941_176
}

test cb_3_2_4_blended_cost_ugly() {
  // floor(137_123_456 * 22_222_222 / 131_765_432) = 23_125_852 (rem 1_491_168)
  calculate_cost_basis(137_123_456, 22_222_222, 131_765_432) == 23_125_852
}
