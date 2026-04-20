use aiken/cbor
use aiken/collection/pairs
use aiken/math
use aiken/merkle_patricia_forestry as mpf
use cardano/assets.{AssetName, PolicyId, Value}
use hydra_dex/types.{
  SharesInsert, SharesMPFAction, SharesRecordEntry, SharesUpdate, UserAccount,
}

// Power of 10: returns 10^n
fn pow10(n: Int) -> Int {
  math.pow(10, n)
}

pub fn convert_shares_to_usd(
  shares_amount: Int,
  total_shares: Int,
  vault_equity: Int,
) -> Int {
  shares_amount * vault_equity / total_shares
}

pub fn cal_per_user_operator_fee(
  withdrawal_value: Int,
  cost_basis: Int,
  operator_fee_rate_bp: Int,
) -> Int {
  let profit = withdrawal_value - cost_basis
  if profit <= 0 {
    0
  } else {
    // Round DOWN — fee never overpaid
    profit * operator_fee_rate_bp / 10000
  }
}

pub fn compute_fee_shares(fee: Int, total_shares: Int, vault_equity: Int) -> Int {
  // Round DOWN
  fee * total_shares / vault_equity
}

// USD calculation: usd_value = Σ(amount * price / 10^scale) for each asset
pub fn check_output_value_equal_to_shares_usd_value(
  output_value: Value,
  shares_usd_value: Int,
  prices: Pairs<(PolicyId, AssetName), (Int, Int)>,
) -> Bool {
  assets.reduce(
    output_value,
    0,
    fn(policy_id, asset_name, amount, acc) {
      expect Some((price, scale)) =
        prices |> pairs.get_first((policy_id, asset_name))

      acc + amount * price / pow10(scale)
    },
  ) == shares_usd_value
}

// Apply operator fee share MPF action after all user withdrawals
pub fn apply_operator_fee_share(
  current_root: ByteArray,
  total_fee_shares: Int,
  operator_account: UserAccount,
  operator_action: SharesMPFAction,
) -> ByteArray {
  if total_fee_shares <= 0 {
    current_root
  } else {
    // Use Account directly as MPF key
    let mpf_key = cbor.serialise(operator_account)
    when operator_action is {
      SharesInsert { proof } -> {
        // Operator has no existing entry - compute new_value
        let new_entry =
          SharesRecordEntry { shares: total_fee_shares, total_deposited: 0 }
        let new_value = cbor.serialise(new_entry)
        let trie = mpf.from_root(current_root)
        let new_trie = mpf.insert(trie, mpf_key, new_value, proof)
        mpf.root(new_trie)
      }
      SharesUpdate { from, to_proof } -> {
        // Operator has existing entry — add fee shares, total_deposited unchanged
        expect Some(from_data) = cbor.deserialise(from)
        expect old_entry: SharesRecordEntry = from_data
        let new_entry =
          SharesRecordEntry {
            shares: old_entry.shares + total_fee_shares,
            total_deposited: old_entry.total_deposited,
          }
        let to = cbor.serialise(new_entry)
        let trie = mpf.from_root(current_root)
        let new_trie = mpf.update(trie, mpf_key, to_proof, from, to)
        mpf.root(new_trie)
      }
      _ -> fail @"Invalid MPF action for operator fee share"
    }
  }
}
