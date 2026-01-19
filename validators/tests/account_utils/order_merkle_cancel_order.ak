use aiken/merkle_patricia_forestry/merkling.{null_hash}
use cardano/assets.{from_lovelace}
use hydra_dex/account_utils.{order_merkle_cancel_order}
use hydra_dex/types.{LimitOrder, MPFDelete, MerklizedOrderDatum, Order}
use hydra_dex/utils.{to_mvalue}
use tests/utils.{mock_account, mock_user_account} as test_utils

test au_omco() {
  let order_id = #"032f3cc8274143358eb2bbf7b58acaf8"
  let order =
    MerklizedOrderDatum {
      datum: Order {
        order_id,
        base_token: ("", ""),
        quote_token: (
          #"5066154a102ee037390c5236f78db23239b49c5748d3d349f3ccf04b",
          #"55534458",
        ),
        is_buy: False,
        list_price_times_1tri: 1_350_000_000_000,
        size: 250_000_000,
        fee_amount_bp: 10,
        account: mock_user_account(mock_account),
        order_type: LimitOrder,
      },
      value: from_lovelace(250_000_000) |> to_mvalue(),
    }

  // Single order trie: delete results in empty trie (null_hash)
  let old_root =
    #"18aea1856d599e589ad928f8a773e1cde81d2cb4a481cb3a3518665dff7c8b7c"
  let new_root = null_hash

  // Empty proof for single-key trie deletion
  let proof = MPFDelete { proof: [] }

  order_merkle_cancel_order(old_root, new_root, order, proof)
}
