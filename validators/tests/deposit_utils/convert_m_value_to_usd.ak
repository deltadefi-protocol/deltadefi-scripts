use cardano/assets.{AssetName, PolicyId}
use hydra_dex/price_oracle_utils.{convert_m_value_to_usd}
use hydra_dex/types.{MValue}

const prices: Pairs<(PolicyId, AssetName), Int> =
  [
    Pair((#"", #""), 2),
    Pair(
      (#"c69b981db7a65e339a6d783755f85a2e03afa1cece9714c55fe4c913", #"5553444d"),
      1,
    ),
  ]

const empty_m_value: MValue = []

const m_value_a =
  [
    Pair("", [Pair("", 100)]),
    Pair(
      #"c69b981db7a65e339a6d783755f85a2e03afa1cece9714c55fe4c913",
      [Pair(#"5553444d", 100)],
    ),
  ]

const m_value_b =
  [
    Pair("", [Pair("", 200)]),
    Pair(
      #"c69b981db7a65e339a6d783755f85a2e03afa1cece9714c55fe4c913",
      [Pair(#"5553444d", 200)],
    ),
  ]

const m_value_c =
  [
    Pair("", [Pair("", 300)]),
    Pair(
      #"c69b981db7a65e339a6d783755f85a2e03afa1cece9714c55fe4c913",
      [Pair("", 300), Pair(#"5553444d", 300)],
    ),
    Pair(
      #"c69b981db7a65e339a6d783755f85a2e03afa1cece9714c55fe4c999",
      [Pair(#"5553444d", 300)],
    ),
  ]

// m_value_a: 100 * 2 (ADA) + 100 * 1 (USDM) = 300
const m_value_a_in_usd = 300

// m_value_b: 200 * 2 (ADA) + 200 * 1 (USDM) = 600
const m_value_b_in_usd = 600

test du_convert_m_value_to_usd_a() {
  convert_m_value_to_usd(m_value_a, prices) == m_value_a_in_usd
}

test du_convert_m_value_to_usd_b() {
  convert_m_value_to_usd(m_value_b, prices) == m_value_b_in_usd
}

test du_convert_m_value_to_usd_empty() {
  convert_m_value_to_usd(empty_m_value, prices) == 0
}

// m_value_c has an asset with no price - should fail
test du_convert_m_value_to_usd_fail_no_price() fail {
  convert_m_value_to_usd(m_value_c, prices) == 0
}
