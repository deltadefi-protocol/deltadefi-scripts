use aiken/collection/list
use aiken/math

// ========== 1.1 Vault Equity (NAV) ==========
// Formula: vaultEquity = usdcBalance + SUM(FLOOR(amount * price / 10^scale))
// Prices are sub-dollar (e.g. ADA ~0.35), stored as scaled ints: price=350_000, scale=6

type Holding {
  amount: Int,
  price: Int,
  scale: Int,
}

fn calculate_vault_equity(
  usdc_balance: Int,
  holdings: List<Holding>,
) -> Int {
  usdc_balance + list.foldl(
    holdings,
    0,
    fn(h: Holding, acc) { acc + h.amount * h.price / math.pow(10, h.scale) },
  )
}

// --- 1.1 USDC only, no holdings ---

test ve_1_1_1_usdc_only_clean() {
  calculate_vault_equity(100_000_000, []) == 100_000_000
}

test ve_1_1_1_usdc_only_ugly() {
  calculate_vault_equity(123_456_789, []) == 123_456_789
}

// --- 1.2 USDC + single holding ---

test ve_1_1_2_usdc_single_holding_clean() {
  // 100_000_000 ADA @ price=500_000 scale=6 → 100M * 500K / 1M = 50M
  let holdings = [Holding { amount: 100_000_000, price: 500_000, scale: 6 }]
  calculate_vault_equity(50_000_000, holdings) == 100_000_000
}

test ve_1_1_2_usdc_single_holding_ugly() {
  // 77_777_777 ADA @ price=412_345 scale=6
  // floor(77_777_777 * 412_345 / 1_000_000) = 32_071_277 (remainder 457_065)
  let holdings = [Holding { amount: 77_777_777, price: 412_345, scale: 6 }]
  calculate_vault_equity(33_333_333, holdings) == 65_404_610
}

// --- 1.3 USDC + multiple holdings ---

test ve_1_1_3_usdc_multi_holdings_clean() {
  let holdings =
    [
      Holding { amount: 50_000_000, price: 500_000, scale: 6 },
      Holding { amount: 20_000_000, price: 2_000_000, scale: 6 },
    ]
  // 10M + 25M + 40M = 75M
  calculate_vault_equity(10_000_000, holdings) == 75_000_000
}

test ve_1_1_3_usdc_multi_holdings_ugly() {
  let holdings =
    [
      Holding { amount: 33_333_333, price: 999_999, scale: 6 },
      Holding { amount: 17_777_777, price: 1_234_567, scale: 6 },
    ]
  // floor(33_333_333 * 999_999 / 1M) = 33_333_299 (rem 666_667)
  // floor(17_777_777 * 1_234_567 / 1M) = 21_947_856 (rem 817_559)
  // 7_777_777 + 33_333_299 + 21_947_856 = 63_058_932
  calculate_vault_equity(7_777_777, holdings) == 63_058_932
}

// --- 1.4 Zero USDC, only holdings ---

test ve_1_1_4_zero_usdc_clean() {
  let holdings = [Holding { amount: 100_000_000, price: 1_000_000, scale: 6 }]
  calculate_vault_equity(0, holdings) == 100_000_000
}

test ve_1_1_4_zero_usdc_ugly() {
  // floor(137_777_777 * 729_927 / 1_000_000) = 100_567_719 (rem 432_279)
  let holdings = [Holding { amount: 137_777_777, price: 729_927, scale: 6 }]
  calculate_vault_equity(0, holdings) == 100_567_719
}

// --- 1.5 Zero equity (empty vault) ---

test ve_1_1_5_zero_equity_clean() {
  calculate_vault_equity(0, []) == 0
}

// --- 1.6 Floor rounding on holding valuation ---
// These specifically test that integer division truncates (floors) correctly.

test ve_1_1_6_floor_rounding_clean() {
  // 3_000_000 * 333_333 / 1_000_000 = 999_999 (remainder 0, no truncation)
  let holdings = [Holding { amount: 3_000_000, price: 333_333, scale: 6 }]
  calculate_vault_equity(0, holdings) == 999_999
}

test ve_1_1_6_floor_rounding_ugly() {
  // 7_654_321 * 142_857 / 1_000_000 = 1_093_473 (remainder 335_097, truncated)
  let holdings = [Holding { amount: 7_654_321, price: 142_857, scale: 6 }]
  calculate_vault_equity(0, holdings) == 1_093_473
}
