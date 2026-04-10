use hydra_dex/withdraw_utils.{cal_per_user_operator_fee, convert_shares_to_usd}

// ========== 4.3 Loss Crystallization ==========
// Partial withdrawal at loss resets cost basis downward.
// On recovery, the lower cost basis means more profit and more fees.
// Total fees from split path >= fees from holding through.

fn cost_basis(total_deposited: Int, redeem: Int, user_shares: Int) -> Int {
  total_deposited * redeem / user_shares
}

// --- 13.1 Partial at loss, then full at profit ---

test lc_4_3_1_partial_loss_then_profit_clean() {
  // Deposit 100M at par. Vault drops to equity=90M.
  // Step 1: withdraw 25M shares at loss
  let gross1 = convert_shares_to_usd(25_000_000, 100_000_000, 90_000_000)
  let cb1 = cost_basis(100_000_000, 25_000_000, 100_000_000)
  let fee1 = cal_per_user_operator_fee(gross1, cb1, 1000)
  // gross=22_500_000, cb=25_000_000, loss → fee=0

  // Remaining: 75M shares, deposited=75M
  // Vault recovers to equity=110M, totalShares=75M (after 25M redeemed)
  let gross2 = convert_shares_to_usd(75_000_000, 75_000_000, 110_000_000)
  let cb2 = cost_basis(75_000_000, 75_000_000, 75_000_000)
  let fee2 = cal_per_user_operator_fee(gross2, cb2, 1000)
  // gross=110M, cb=75M, profit=35M, fee=3_500_000

  let total_fee_split = fee1 + fee2

  // Hold through: withdraw all 100M at equity=110M, totalShares=100M
  let gross_hold = convert_shares_to_usd(100_000_000, 100_000_000, 110_000_000)
  let fee_hold = cal_per_user_operator_fee(gross_hold, 100_000_000, 1000)
  // gross=110M, cb=100M, profit=10M, fee=1_000_000

  // split_fee=3_500_000 >= hold_fee=1_000_000
  total_fee_split >= fee_hold
}

test lc_4_3_1_partial_loss_then_profit_ugly() {
  // Deposit 100M, shares=100M. Vault drops: equity=87_654_321, total=98_765_432
  let total_shares = 98_765_432

  // Step 1: withdraw 25_925_925 shares at loss
  let redeem1 = 25_925_925
  let gross1 =
    convert_shares_to_usd(redeem1, total_shares, 87_654_321)
  let cb1 = cost_basis(100_000_000, redeem1, 100_000_000)
  let fee1 = cal_per_user_operator_fee(gross1, cb1, 1000)
  // loss → fee=0

  let remaining_shares = 100_000_000 - redeem1
  let remaining_deposited = 100_000_000 - cb1
  let ts_after = total_shares - redeem1

  // Vault recovers: equity=106_789_012
  let gross2 =
    convert_shares_to_usd(remaining_shares, ts_after, 106_789_012)
  let cb2 =
    cost_basis(remaining_deposited, remaining_shares, remaining_shares)
  let fee2 = cal_per_user_operator_fee(gross2, cb2, 1000)

  let total_fee_split = fee1 + fee2

  // Hold through: withdraw all at equity=106_789_012, total=98_765_432
  let gross_hold =
    convert_shares_to_usd(100_000_000, total_shares, 106_789_012)
  let fee_hold =
    cal_per_user_operator_fee(gross_hold, 100_000_000, 1000)

  // split fees > hold fees due to loss crystallization
  total_fee_split >= fee_hold
}

// --- 13.2 Multiple partial withdrawals at loss ---

test lc_4_3_2_multiple_partials_clean() {
  // Deposit 100M, shares=100M.
  // Stage 1: equity drops to 95M. Withdraw 20M shares.
  let gross1 = convert_shares_to_usd(20_000_000, 100_000_000, 95_000_000)
  let cb1 = cost_basis(100_000_000, 20_000_000, 100_000_000)
  let fee1 = cal_per_user_operator_fee(gross1, cb1, 1000)
  // gross=19M, cb=20M, loss → fee=0

  let rem_shares1 = 80_000_000
  let rem_dep1 = 100_000_000 - cb1

  // Stage 2: equity drops to 85M. Withdraw 20M shares.
  let gross2 = convert_shares_to_usd(20_000_000, 80_000_000, 85_000_000)
  let cb2 = cost_basis(rem_dep1, 20_000_000, rem_shares1)
  let fee2 = cal_per_user_operator_fee(gross2, cb2, 1000)

  let rem_shares2 = 60_000_000
  let rem_dep2 = rem_dep1 - cb2

  // Stage 3: equity recovers to 115M. Withdraw remaining 60M.
  let gross3 = convert_shares_to_usd(60_000_000, 60_000_000, 115_000_000)
  let cb3 = cost_basis(rem_dep2, 60_000_000, rem_shares2)
  let fee3 = cal_per_user_operator_fee(gross3, cb3, 1000)

  let total_fee_split = fee1 + fee2 + fee3

  // Hold through: withdraw all 100M at equity=115M
  let gross_hold = convert_shares_to_usd(100_000_000, 100_000_000, 115_000_000)
  let fee_hold = cal_per_user_operator_fee(gross_hold, 100_000_000, 1000)

  // split=5_625_000 >= hold=1_500_000
  total_fee_split >= fee_hold
}

test lc_4_3_2_multiple_partials_ugly() {
  let total_shares = 98_765_432

  // Stage 1: equity=93_827_160. Withdraw 19_753_086 shares.
  let redeem1 = 19_753_086
  let gross1 =
    convert_shares_to_usd(redeem1, total_shares, 93_827_160)
  let cb1 = cost_basis(100_000_000, redeem1, 100_000_000)
  let fee1 = cal_per_user_operator_fee(gross1, cb1, 1000)

  let rem_sh1 = 100_000_000 - redeem1
  let rem_dep1 = 100_000_000 - cb1
  let ts1 = total_shares - redeem1

  // Stage 2: equity=82_716_049. Withdraw 19_753_086 shares.
  let redeem2 = 19_753_086
  let gross2 = convert_shares_to_usd(redeem2, ts1, 82_716_049)
  let cb2 = cost_basis(rem_dep1, redeem2, rem_sh1)
  let fee2 = cal_per_user_operator_fee(gross2, cb2, 1000)

  let rem_sh2 = rem_sh1 - redeem2
  let rem_dep2 = rem_dep1 - cb2
  let ts2 = ts1 - redeem2

  // Stage 3: equity recovers to 111_111_111. Withdraw remaining.
  let redeem3 = rem_sh2
  let gross3 = convert_shares_to_usd(redeem3, ts2, 111_111_111)
  let cb3 = cost_basis(rem_dep2, redeem3, rem_sh2)
  let fee3 = cal_per_user_operator_fee(gross3, cb3, 1000)

  let total_fee_split = fee1 + fee2 + fee3

  // Hold through
  let gross_hold =
    convert_shares_to_usd(100_000_000, total_shares, 111_111_111)
  let fee_hold =
    cal_per_user_operator_fee(gross_hold, 100_000_000, 1000)

  // split fees > hold fees
  total_fee_split >= fee_hold
}
