use aiken/cbor
use hydra_dex/account_utils.{account_merkle_balance_decrease, deser_value}
use hydra_dex/types.{MPFDelete, MPFUpdate}
use tests/utils.{mock_account, mock_user_account}
use cardano/assets.{Value, add, from_asset}

test au_hmbd_delete() {
  let account = mock_user_account(mock_account)
  // Delete entry with 1_000_000_000 lovelace + 1_000_000_000 USDX
  // Results in empty trie
  let old_root =
    #"79a1f8ed21bade02612f0f83f41453ee61cee7d7b797ffc84ce787717279ed0e"
  let new_root =
    #"0000000000000000000000000000000000000000000000000000000000000000"
  let value =
    from_asset("", "", 1_000_000_000)
      |> add(
          #"5066154a102ee037390c5236f78db23239b49c5748d3d349f3ccf04b",
          #"55534458",
          1_000_000_000,
        )
  let proof = MPFDelete { proof: [] }

  account_merkle_balance_decrease(old_root, new_root, account, value, proof)
}

test au_hmbd_update() {
  let account = mock_user_account(mock_account)
  // Decrease from 1_000_000_000 lovelace + 1_000_000_000 USDX
  // to 500_000_000 lovelace + 1_000_000_000 USDX
  // Decreasing: 500_000_000 lovelace
  let old_root =
    #"79a1f8ed21bade02612f0f83f41453ee61cee7d7b797ffc84ce787717279ed0e"
  let new_root =
    #"13a67d5c7d4b6c68217d01cb569646ab08595ed9711224c6451ba834ff30de09"
  let value = from_asset("", "", 500_000_000)

  let proof =
    MPFUpdate {
      from: #"a240a1401a3b9aca00581c5066154a102ee037390c5236f78db23239b49c5748d3d349f3ccf04ba144555344581a3b9aca00",
      to: #"a240a1401a1dcd6500581c5066154a102ee037390c5236f78db23239b49c5748d3d349f3ccf04ba144555344581a3b9aca00",
      to_proof: [],
    }

  account_merkle_balance_decrease(old_root, new_root, account, value, proof)
}

test au_deser_value() {
  let test_value: Value =
    deser_value(
      #"a640a1401a0bebc200581c3363b99384d6ee4c4b009068af396c8fdf92dafd111e58a857af0429a1454e494748541a05f5e100581c378f9732c755ed6f4fc8d406f1461d0cca95d7d2e69416784684df39a144534e454b1a05f5e100581c82e46eb16633bf8bfa820c83ffeb63192c6e21757d2bf91290b2f41da1434941471a05f5e100581ca2818ba06a88bb6c08d10f4f9b897c09768f28d274093628ad7086fca145484f534b591a05f5e100581cc69b981db7a65e339a6d783755f85a2e03afa1cece9714c55fe4c913a1445553444d1a0bebc200",
    )
  cbor.serialise(test_value) == #"a640a1401a0bebc200581c3363b99384d6ee4c4b009068af396c8fdf92dafd111e58a857af0429a1454e494748541a05f5e100581c378f9732c755ed6f4fc8d406f1461d0cca95d7d2e69416784684df39a144534e454b1a05f5e100581c82e46eb16633bf8bfa820c83ffeb63192c6e21757d2bf91290b2f41da1434941471a05f5e100581ca2818ba06a88bb6c08d10f4f9b897c09768f28d274093628ad7086fca145484f534b591a05f5e100581cc69b981db7a65e339a6d783755f85a2e03afa1cece9714c55fe4c913a1445553444d1a0bebc200"
}

test au_deser_value_fail() fail {
  let test_value: Value =
    deser_value(
      #"a640a1401a0bebc200581cc69b981db7a65e339a6d783755f85a2e03afa1cece9714c55fe4c913a1445553444d1a0bebc200581c3363b99384d6ee4c4b009068af396c8fdf92dafd111e58a857af0429a1454e494748541a05f5e100581c378f9732c755ed6f4fc8d406f1461d0cca95d7d2e69416784684df39a144534e454b1a05f5e100581c82e46eb16633bf8bfa820c83ffeb63192c6e21757d2bf91290b2f41da1434941471a05f5e100581ca2818ba06a88bb6c08d10f4f9b897c09768f28d274093628ad7086fca145484f534b591a05f5e100",
    )
  cbor.serialise(test_value) == #"a640a1401a0bebc200581c3363b99384d6ee4c4b009068af396c8fdf92dafd111e58a857af0429a1454e494748541a05f5e100581c378f9732c755ed6f4fc8d406f1461d0cca95d7d2e69416784684df39a144534e454b1a05f5e100581c82e46eb16633bf8bfa820c83ffeb63192c6e21757d2bf91290b2f41da1434941471a05f5e100581ca2818ba06a88bb6c08d10f4f9b897c09768f28d274093628ad7086fca145484f534b591a05f5e100581cc69b981db7a65e339a6d783755f85a2e03afa1cece9714c55fe4c913a1445553444d1a0bebc200"
}
