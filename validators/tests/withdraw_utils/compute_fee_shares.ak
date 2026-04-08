use hydra_dex/withdraw_utils.{compute_fee_shares}

// ========== compute_fee_shares tests ==========
// Formula: fee_shares = ceil(fee * total_shares / vault_equity)

// Basic case: fee=100, total_shares=1000, vault_equity=1000 → 100 shares
test wu_compute_fee_shares_basic() {
  compute_fee_shares(100, 1000, 1000) == 100
}

// Round up: fee=100, total_shares=1000, vault_equity=300 → ceil(333.33) = 334
test wu_compute_fee_shares_round_up() {
  compute_fee_shares(100, 1000, 300) == 334
}

// Exact division: fee=300, total_shares=1000, vault_equity=1000 → 300
test wu_compute_fee_shares_exact() {
  compute_fee_shares(300, 1000, 1000) == 300
}

// Zero fee: fee=0 → 0 shares
test wu_compute_fee_shares_zero_fee() {
  compute_fee_shares(0, 1000, 1000) == 0
}

// Large total_shares: fee=100, total_shares=1000000, vault_equity=1000 → 100000
test wu_compute_fee_shares_large_total() {
  compute_fee_shares(100, 1000000, 1000) == 100000
}

// Small vault equity: fee=10, total_shares=1000, vault_equity=100 → 100
test wu_compute_fee_shares_small_equity() {
  compute_fee_shares(10, 1000, 100) == 100
}

// Real-world example:
// fee = 20000 (0.02 USD with 6 decimals)
// total_shares = 3000000000000000
// vault_equity = 2400000000
// fee_shares = ceil(20000 * 3000000000000000 / 2400000000) = ceil(25000000000) = 25000000000
test wu_compute_fee_shares_real_world() {
  compute_fee_shares(20000, 3000000000000000, 2400000000) == 25000000000
}

// Small fee with rounding:
// fee = 1, total_shares = 1000, vault_equity = 3
// fee_shares = ceil(1 * 1000 / 3) = ceil(333.33) = 334
test wu_compute_fee_shares_small_round_up() {
  compute_fee_shares(1, 1000, 3) == 334
}
