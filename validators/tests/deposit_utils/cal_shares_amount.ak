use hydra_dex/deposit_utils.{cal_shares_amount}

// ========== cal_shares_amount tests ==========
// Formula: shares = usd_value * total_shares / vault_equity

// Basic calculation: 1000 USD with vault_equity=2000, total_shares=1000 → 500 shares
test du_cal_shares_amount_basic() {
  cal_shares_amount(1000, 2000, 1000) == 500
}

// Equal values: 1000 USD with vault_equity=1000, total_shares=1000 → 1000 shares
test du_cal_shares_amount_equal() {
  cal_shares_amount(1000, 1000, 1000) == 1000
}

// Larger vault: 1000 USD with vault_equity=10000, total_shares=1000 → 100 shares
test du_cal_shares_amount_larger_vault() {
  cal_shares_amount(1000, 10000, 1000) == 100
}

// Larger total_shares: 1000 USD with vault_equity=1000, total_shares=10000 → 10000 shares
test du_cal_shares_amount_more_shares() {
  cal_shares_amount(1000, 1000, 10000) == 10000
}

// Round down: 100 USD with vault_equity=300, total_shares=100 → 33 shares (100*100/300 = 33.33...)
test du_cal_shares_amount_round_down() {
  cal_shares_amount(100, 300, 100) == 33
}

// Zero USD value: 0 USD → 0 shares
test du_cal_shares_amount_zero_usd() {
  cal_shares_amount(0, 1000, 1000) == 0
}

// Fail when total_shares is zero
test du_cal_shares_amount_fail_zero_total_shares() fail {
  cal_shares_amount(1000, 1000, 0) == 0
}

// Real-world example using mock values:
// vault_equity = 2400000000 (2400 USD with 6 decimals)
// total_shares = 3000000000000000
// deposit_usd = 3000000 (3 USD with 6 decimals)
// expected = 3000000 * 3000000000000000 / 2400000000 = 3750000000000
test du_cal_shares_amount_real_world() {
  cal_shares_amount(3000000, 2400000000, 3000000000000000) == 3750000000000
}
