use aiken/merkle_patricia_forestry.{Branch}
use cardano/assets.{add, from_asset}
use hydra_dex/account_utils.{account_merkle_balance_increase}
use hydra_dex/types.{MPFInsert, MPFUpdate}
use tests/utils.{mock_account, mock_user_account}

test au_hmbi_insert() {
  let account = mock_user_account(mock_account)
  let old_root =
    #"0000000000000000000000000000000000000000000000000000000000000000"
  let new_root =
    #"d77bbe4dd2ef95da2112cb54177b8132b4166f05493405b5fdc6c4f7e9ec8df8"
  let value = from_asset("", "", 100_000_000)
  let proof = MPFInsert { proof: [] }

  account_merkle_balance_increase(old_root, new_root, account, value, proof)
}

test au_hmbi_update() {
  let account = mock_user_account(mock_account)
  let old_root =
    #"d77bbe4dd2ef95da2112cb54177b8132b4166f05493405b5fdc6c4f7e9ec8df8"
  let new_root =
    #"fc765255aa7da1b705a7703f161f9e954e53964026d4aecda93fc3d986c899b8"
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
  let old_root =
    #"c30c594b7188370e1995e5cf31d319f386d386d967f2987aa56a0c542f2ef076"
  let new_root =
    #"02817b279adf04e7af6c8dffbc752bb2583126814b9613fb6c9a8bbaf93931b5"
  let value = from_asset("", "", 10_000_000)
  let proof =
    MPFUpdate {
      from: #"a240a1401a3b9aca00581c5066154a102ee037390c5236f78db23239b49c5748d3d349f3ccf04ba144555344581a3b9aca00",
      to: #"a240a1401a3c336080581c5066154a102ee037390c5236f78db23239b49c5748d3d349f3ccf04ba144555344581a3b9aca00",
      to_proof: [
        Branch {
          skip: 0,
          neighbors: #"9543c86b0bb9781a8d503bc087408469b50a3d3e1f7f4b0554dc813ae14c086185c09af929492a871e4fae32d9d5c36e352471cd659bcdb61de08f1722acc3b10eb923b0cbd24df54401d998531feead35a47a99f4deed205de4af81120f97610000000000000000000000000000000000000000000000000000000000000000",
        },
      ],
    }

  account_merkle_balance_increase(old_root, new_root, account, value, proof)
}
