use hydra_dex/account_utils.{account_merkle_balance_increase}
use hydra_dex/types.{MPFInsert, MPFUpdate}
use tests/utils.{mock_account, mock_user_account}
use cardano/assets.{add, from_asset}

test au_hmbi_insert() {
  let account = mock_user_account(mock_account)
  // Insert into empty trie with 100_000_000 lovelace
  let old_root =
    #"0000000000000000000000000000000000000000000000000000000000000000"
  let new_root =
    #"8f112b346bf2bef0c76d306c10f76432b1936b49a5074311ce9ed16f0c964a28"
  let value = from_asset("", "", 100_000_000)
  let proof = MPFInsert { proof: [] }

  account_merkle_balance_increase(old_root, new_root, account, value, proof)
}

test au_hmbi_update() {
  let account = mock_user_account(mock_account)
  // Update from 100_000_000 lovelace to 1_000_000_000 lovelace + 1_000_000_000 USDX
  // Adding: 900_000_000 lovelace + 1_000_000_000 USDX
  let old_root =
    #"8f112b346bf2bef0c76d306c10f76432b1936b49a5074311ce9ed16f0c964a28"
  let new_root =
    #"79a1f8ed21bade02612f0f83f41453ee61cee7d7b797ffc84ce787717279ed0e"
  let value =
    from_asset("", "", 900_000_000)
      |> add(
          #"5066154a102ee037390c5236f78db23239b49c5748d3d349f3ccf04b",
          #"55534458",
          1_000_000_000,
        )
  let proof =
    MPFUpdate {
      from: #"a140a1401a05f5e100",
      to: #"a240a1401a3b9aca00581c5066154a102ee037390c5236f78db23239b49c5748d3d349f3ccf04ba144555344581a3b9aca00",
      to_proof: [],
    }

  account_merkle_balance_increase(old_root, new_root, account, value, proof)
}

test au_hmbi_update_2() {
  let account = mock_user_account(mock_account)
  // Update from 1_000_000_000 lovelace + 1_000_000_000 USDX
  // to 1_010_000_000 lovelace + 1_000_000_000 USDX
  // Adding: 10_000_000 lovelace
  let old_root =
    #"79a1f8ed21bade02612f0f83f41453ee61cee7d7b797ffc84ce787717279ed0e"
  let new_root =
    #"cf55f97dee458d36e789efa53eaa31a6a3d3cc11e3532909696e4120618df469"
  let value = from_asset("", "", 10_000_000)
  let proof =
    MPFUpdate {
      from: #"a240a1401a3b9aca00581c5066154a102ee037390c5236f78db23239b49c5748d3d349f3ccf04ba144555344581a3b9aca00",
      to: #"a240a1401a3c336080581c5066154a102ee037390c5236f78db23239b49c5748d3d349f3ccf04ba144555344581a3b9aca00",
      to_proof: [],
    }

  account_merkle_balance_increase(old_root, new_root, account, value, proof)
}
