use aiken/cbor
use aiken/collection/list
use aiken/collection/pairs
use aiken/crypto.{VerificationKey}
use cardano/assets.{AssetName, PolicyId, Value}
use cardano/transaction.{Input}
use cocktail.{verify_pub_keys, verify_signatures}
use hydra_dex/types.{MValue, Message}

pub fn verify_prices_oracle_messages(
  prices_message: ByteArray,
  inputs: List<Input>,
  hydra_signers: List<VerificationKey>,
  hydra_node_pub_keys: List<VerificationKey>,
  signatures: List<ByteArray>,
) -> (Int, Pairs<(PolicyId, AssetName), Int>, Bool) {
  expect Some(signed_data) = cbor.deserialise(prices_message)
  expect Message { vault_equity, prices, utxo_ref }: Message = signed_data

  let is_utxo_consumed =
    list.any(inputs, fn(input) { input.output_reference == utxo_ref })

  // Convert VerificationKey to ByteArray for cocktail functions
  let pub_keys_bytes = list.map(hydra_node_pub_keys, fn(vk) { vk })
  let signers_bytes = list.map(hydra_signers, fn(vk) { vk })

  let keys_check = verify_pub_keys(pub_keys_bytes, signers_bytes)
  let signatures_check =
    verify_signatures(pub_keys_bytes, prices_message, signatures)

  let message_verified = is_utxo_consumed? && keys_check? && signatures_check?

  (vault_equity, prices, message_verified)
}

pub fn convert_value_to_usd(
  value: Value,
  prices: Pairs<(PolicyId, AssetName), Int>,
) -> Int {
  assets.reduce(
    value,
    0,
    fn(policy_id, asset_name, amount, acc) {
      expect Some(price) = prices |> pairs.get_first((policy_id, asset_name))

      acc + amount * price
    },
  )
}

pub fn convert_m_value_to_usd(
  m_value: MValue,
  prices: Pairs<(PolicyId, AssetName), Int>,
) -> Int {
  list.foldl(
    m_value,
    0,
    fn(policy_pair: Pair<PolicyId, Pairs<AssetName, Int>>, acc: Int) {
      list.foldl(
        policy_pair.2nd,
        acc,
        fn(asset_pair: Pair<AssetName, Int>, nested_acc: Int) {
          expect Some(price) =
            prices
              |> pairs.get_first((policy_pair.1st, asset_pair.1st))
          nested_acc + price * asset_pair.2nd
        },
      )
    },
  )
}
