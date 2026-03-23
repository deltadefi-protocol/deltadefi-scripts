use cardano/assets.{AssetName, PolicyId, add, from_asset}
use hydra_dex/withdraw_utils.{check_output_value_equal_to_shares_usd_value}

const usdm_policy = #"c69b981db7a65e339a6d783755f85a2e03afa1cece9714c55fe4c913"

const usdm_name = #"5553444d"

// prices: (price, scale) tuple - USD = amount * price / 10^scale
const prices: Pairs<(PolicyId, AssetName), (Int, Int)> =
  [Pair((#"", #""), (2, 0)), Pair((usdm_policy, usdm_name), (1, 0))]

// ========== check_output_value_equal_to_shares_usd_value tests ==========

// Output value: 1000000 USDM (price=1, scale=0) + 2000000 ADA (price=2, scale=0)
// USD value = 1000000 * 1 / 10^0 + 2000000 * 2 / 10^0 = 5000000
const output_value_a =
  from_asset(usdm_policy, usdm_name, 1000000)
    |> add(#"", #"", 2000000)

const shares_usd_value_a = 5000000

test wu_check_output_value_mixed_a() {
  check_output_value_equal_to_shares_usd_value(
    output_value_a,
    shares_usd_value_a,
    prices,
  )
}

// Output value: 2000000 USDM (price=1, scale=0) + 1000000 ADA (price=2, scale=0)
// USD value = 2000000 * 1 / 10^0 + 1000000 * 2 / 10^0 = 4000000
const output_value_b =
  from_asset(usdm_policy, usdm_name, 2000000)
    |> add(#"", #"", 1000000)

const shares_usd_value_b = 4000000

test wu_check_output_value_mixed_b() {
  check_output_value_equal_to_shares_usd_value(
    output_value_b,
    shares_usd_value_b,
    prices,
  )
}

// Wrong USD value should return false
test wu_check_output_value_wrong() {
  !check_output_value_equal_to_shares_usd_value(output_value_a, 4000000, prices)
}

// Output with asset that has no price should fail
const output_value_no_price =
  from_asset(
    #"c69b981db7a65e339a6d783755f85a2e03afa1cece9714c55fe4c999",
    #"",
    1000000,
  )
    |> add(usdm_policy, usdm_name, 2000000)

test wu_check_output_value_fail_no_price() fail {
  check_output_value_equal_to_shares_usd_value(
    output_value_no_price,
    4000000,
    prices,
  )
}

// Pure USDM output
const output_value_usdm_only = from_asset(usdm_policy, usdm_name, 3000000)

test wu_check_output_value_usdm_only() {
  check_output_value_equal_to_shares_usd_value(
    output_value_usdm_only,
    3000000,
    prices,
  )
}

// Pure ADA output
const output_value_ada_only = from_asset(#"", #"", 1500000)

test wu_check_output_value_ada_only() {
  check_output_value_equal_to_shares_usd_value(
    output_value_ada_only,
    3000000,
    prices,
  )
}
