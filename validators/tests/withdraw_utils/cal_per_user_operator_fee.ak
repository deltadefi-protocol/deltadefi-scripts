use hydra_dex/withdraw_utils.{cal_per_user_operator_fee}

// ========== cal_per_user_operator_fee tests ==========
// Formula: if profit > 0, fee = floor(profit * operator_fee_rate_bp / 10000)
// profit = withdrawal_value - cost_basis
// operator_fee_rate_bp uses basis points: 10000 = 100%, 1000 = 10%, 1 = 0.01%

// Basic profit case: withdrawal=1000, cost=800, charge=10% → profit=200, fee=20
test wu_cal_per_user_operator_fee_basic_profit() {
  cal_per_user_operator_fee(1000, 800, 1000) == 20
}

// No profit (break even): withdrawal=1000, cost=1000 → profit=0, fee=0
test wu_cal_per_user_operator_fee_no_profit() {
  cal_per_user_operator_fee(1000, 1000, 1000) == 0
}

// Loss case: withdrawal=800, cost=1000 → profit=-200, fee=0
test wu_cal_per_user_operator_fee_loss() {
  cal_per_user_operator_fee(800, 1000, 1000) == 0
}

// Round down: withdrawal=1003, cost=1000, charge=10% → profit=3, fee=floor(0.3)=0
test wu_cal_per_user_operator_fee_round_down() {
  cal_per_user_operator_fee(1003, 1000, 1000) == 0
}

// Exact division: withdrawal=1100, cost=1000, charge=10% → profit=100, fee=10
test wu_cal_per_user_operator_fee_exact() {
  cal_per_user_operator_fee(1100, 1000, 1000) == 10
}

// Higher charge percentage: 20%
test wu_cal_per_user_operator_fee_higher_percentage() {
  cal_per_user_operator_fee(1000, 800, 2000) == 40
}

// Zero charge percentage: fee always 0
test wu_cal_per_user_operator_fee_zero_percentage() {
  cal_per_user_operator_fee(1000, 500, 0) == 0
}

// 100% charge: all profit goes to operator
test wu_cal_per_user_operator_fee_full_charge() {
  cal_per_user_operator_fee(1000, 800, 10000) == 200
}

// Real-world example:
// withdrawal_value = 1000000 (1 USD with 6 decimals)
// cost_basis = 800000 (0.8 USD)
// charge = 10% (1000 bp)
// profit = 200000, fee = floor(200000 * 1000 / 10000) = 20000
test wu_cal_per_user_operator_fee_real_world() {
  cal_per_user_operator_fee(1000000, 800000, 1000) == 20000
}

// Large profit with rounding:
// withdrawal = 1234567, cost = 1000000, charge = 15% (1500 bp)
// profit = 234567, fee = floor(234567 * 1500 / 10000) = floor(35185.05) = 35185
test wu_cal_per_user_operator_fee_large_profit_round_down() {
  cal_per_user_operator_fee(1234567, 1000000, 1500) == 35185
}
