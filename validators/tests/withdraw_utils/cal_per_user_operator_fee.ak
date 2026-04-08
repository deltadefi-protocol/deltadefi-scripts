use hydra_dex/withdraw_utils.{cal_per_user_operator_fee}

// ========== cal_per_user_operator_fee tests ==========
// Formula: if profit > 0, fee = ceil(profit * operator_charge_percentage / 100)
// profit = withdrawal_value - cost_basis

// Basic profit case: withdrawal=1000, cost=800, charge=10% → profit=200, fee=20
test wu_cal_per_user_operator_fee_basic_profit() {
  cal_per_user_operator_fee(1000, 800, 10) == 20
}

// No profit (break even): withdrawal=1000, cost=1000 → profit=0, fee=0
test wu_cal_per_user_operator_fee_no_profit() {
  cal_per_user_operator_fee(1000, 1000, 10) == 0
}

// Loss case: withdrawal=800, cost=1000 → profit=-200, fee=0
test wu_cal_per_user_operator_fee_loss() {
  cal_per_user_operator_fee(800, 1000, 10) == 0
}

// Round up: withdrawal=1003, cost=1000, charge=10% → profit=3, fee=ceil(0.3)=1
test wu_cal_per_user_operator_fee_round_up() {
  cal_per_user_operator_fee(1003, 1000, 10) == 1
}

// Exact division: withdrawal=1100, cost=1000, charge=10% → profit=100, fee=10
test wu_cal_per_user_operator_fee_exact() {
  cal_per_user_operator_fee(1100, 1000, 10) == 10
}

// Higher charge percentage: 20%
test wu_cal_per_user_operator_fee_higher_percentage() {
  cal_per_user_operator_fee(1000, 800, 20) == 40
}

// Zero charge percentage: fee always 0
test wu_cal_per_user_operator_fee_zero_percentage() {
  cal_per_user_operator_fee(1000, 500, 0) == 0
}

// 100% charge: all profit goes to operator
test wu_cal_per_user_operator_fee_full_charge() {
  cal_per_user_operator_fee(1000, 800, 100) == 200
}

// Real-world example:
// withdrawal_value = 1000000 (1 USD with 6 decimals)
// cost_basis = 800000 (0.8 USD)
// charge = 10%
// profit = 200000, fee = ceil(200000 * 10 / 100) = 20000
test wu_cal_per_user_operator_fee_real_world() {
  cal_per_user_operator_fee(1000000, 800000, 10) == 20000
}

// Large profit with rounding:
// withdrawal = 1234567, cost = 1000000, charge = 15%
// profit = 234567, fee = ceil(234567 * 15 / 100) = ceil(35185.05) = 35186
test wu_cal_per_user_operator_fee_large_profit_round_up() {
  cal_per_user_operator_fee(1234567, 1000000, 15) == 35186
}
