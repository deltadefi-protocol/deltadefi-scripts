use hydra_dex/withdraw_utils.{convert_shares_to_usd}

// ========== convert_shares_to_usd tests ==========
// Formula: usd_value = shares_amount * vault_equity / total_shares

// Basic calculation: 1000 shares with vault_equity=2000, total_shares=1000 → 2000 USD
test wu_convert_shares_to_usd_basic() {
  convert_shares_to_usd(1000, 1000, 2000) == 2000
}

// Equal values: 1000 shares with vault_equity=1000, total_shares=1000 → 1000 USD
test wu_convert_shares_to_usd_equal() {
  convert_shares_to_usd(1000, 1000, 1000) == 1000
}

// Larger vault: 1000 shares with vault_equity=10000, total_shares=1000 → 10000 USD
test wu_convert_shares_to_usd_larger_vault() {
  convert_shares_to_usd(1000, 1000, 10000) == 10000
}

// More total shares: 1000 shares with vault_equity=1000, total_shares=10000 → 100 USD
test wu_convert_shares_to_usd_more_total_shares() {
  convert_shares_to_usd(1000, 10000, 1000) == 100
}

// Round down: 100 shares with total_shares=300, vault_equity=100 → 33 USD (100*100/300)
test wu_convert_shares_to_usd_round_down() {
  convert_shares_to_usd(100, 300, 100) == 33
}

// Zero shares: 0 shares → 0 USD
test wu_convert_shares_to_usd_zero() {
  convert_shares_to_usd(0, 1000, 1000) == 0
}

// Real-world example using mock values:
// vault_equity = 2400000000 (2400 USD with 6 decimals)
// total_shares = 3000000000000000
// shares_amount = 1250000000000000 (half of total)
// expected = 1250000000000000 * 2400000000 / 3000000000000000 = 1000000000
test wu_convert_shares_to_usd_real_world() {
  convert_shares_to_usd(1250000000000000, 3000000000000000, 2400000000) == 1000000000
}

// Partial withdrawal: 25% of shares
test wu_convert_shares_to_usd_partial() {
  convert_shares_to_usd(750000000000000, 3000000000000000, 2400000000) == 600000000
}
