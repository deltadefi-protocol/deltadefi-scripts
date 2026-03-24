use aiken/cbor
use aiken/collection/dict
use cardano/assets.{Value}
use hydra_dex/types.{MValue}

pub fn to_mvalue(value: Value) -> MValue {
  let data = cbor.serialise(value)
  expect Some(mvalue_raw): Option<Data> = cbor.deserialise(data)
  expect mvalue: MValue = mvalue_raw
  mvalue
}

pub fn combine_m_value(left_m_value: MValue, right_m_value: MValue) -> MValue {
  let left_dict = dict.from_pairs(left_m_value)
  let right_dict = dict.from_pairs(right_m_value)

  dict.union_with(
    left_dict,
    right_dict,
    fn(_k, v1, v2) {
      let v1_dict = dict.from_pairs(v1)
      let v2_dict = dict.from_pairs(v2)
      let all =
        dict.union_with(
          v1_dict,
          v2_dict,
          fn(_k, v_v_1, v_v_2) { Some(v_v_1 + v_v_2) },
        )
          |> dict.to_pairs()
      Some(all)
    },
  )
    |> dict.to_pairs()
}

// Calculate shares to mint for a deposit
// Initial deposit (total_shares == 0): share price = 1.0, so shares = usd_value
// Subsequent deposits: shares = (usd_value * total_shares) / vault_equity (round DOWN)
pub fn cal_shares_amount(
  usd_value: Int,
  vault_equity: Int,
  total_shares: Int,
) -> Int {
  if total_shares == 0 {
    usd_value
  } else {
    usd_value * total_shares / vault_equity
  }
}
