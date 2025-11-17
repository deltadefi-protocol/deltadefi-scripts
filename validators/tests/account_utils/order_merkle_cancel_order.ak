// TODO: Update merkle test case

use aiken/merkle_patricia_forestry.{Branch}
use cardano/assets.{from_lovelace}
use hydra_dex/account_utils.{order_merkle_cancel_order}
use hydra_dex/types.{MPFDelete, MerklizedOrderDatum, UserSpotAccount}
use tests/utils.{mock_account, to_mvalue}

test au_omco() {
  let order_id = #"032f3cc8274143358eb2bbf7b58acaf8"
  let order =
    MerklizedOrderDatum {
      order_id,
      long_token: ("", ""),
      short_token: (
        #"5066154a102ee037390c5236f78db23239b49c5748d3d349f3ccf04b",
        #"55534458",
      ),
      is_long: False,
      list_price_times_1bil: 1_350_000_000,
      order_size: 250_000_000,
      fee_amount_bp: 10,
      account: UserSpotAccount { account: mock_account },
      value: from_lovelace(250_000_000) |> to_mvalue(),
    }
  let old_root =
    #"4005bf6b8dcfba8d297cdddb5f4b1cfabe006a85315b0f870a668c29c163e46e"
  let new_root =
    #"e112f4fad96829c544fbed2ce83b4d93db3402ac3a3d1c6d755e376d8d58d1fe"

  let proof =
    MPFDelete {
      proof: [
        Branch {
          skip: 0,
          neighbors: #"61bc86c7587b7bf73d02ca47c08c4e78dbbc4e546040bf8349e84dde61ddb317706c5b827e05abe8f554f9b75201f2949c7f7504cc9bf6aa9a4abf25da4cc21c0eb923b0cbd24df54401d998531feead35a47a99f4deed205de4af81120f97610000000000000000000000000000000000000000000000000000000000000000",
        },
      ],
    }

  order_merkle_cancel_order(old_root, new_root, order, proof)
}
