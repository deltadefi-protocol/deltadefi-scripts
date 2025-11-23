use aiken/merkle_patricia_forestry.{Branch}
use cardano/assets.{add, from_asset}
use hydra_dex/account_utils.{account_merkle_balance_decrease}
use hydra_dex/types.{MPFDelete, MPFUpdate}
use tests/utils.{mock_account, mock_user_account}

test au_hmbd_delete() {
  let account = mock_user_account(mock_account)
  let old_root =
    #"c30c594b7188370e1995e5cf31d319f386d386d967f2987aa56a0c542f2ef076"
  let new_root =
    #"ec641c74d6aec786bbcf1b8344a7dde1b3610cbc710a93098d05276e2c6432e7"
  let value =
    from_asset("", "", 1_000_000_000)
      |> add(
          #"5066154a102ee037390c5236f78db23239b49c5748d3d349f3ccf04b",
          #"55534458",
          1_000_000_000,
        )
  let proof =
    MPFDelete {
      proof: [
        Branch {
          skip: 0,
          neighbors: #"9543c86b0bb9781a8d503bc087408469b50a3d3e1f7f4b0554dc813ae14c086185c09af929492a871e4fae32d9d5c36e352471cd659bcdb61de08f1722acc3b10eb923b0cbd24df54401d998531feead35a47a99f4deed205de4af81120f97610000000000000000000000000000000000000000000000000000000000000000",
        },
      ],
    }

  account_merkle_balance_decrease(old_root, new_root, account, value, proof)
}

test au_hmbd_update() {
  let account = mock_user_account(mock_account)
  let old_root =
    #"c30c594b7188370e1995e5cf31d319f386d386d967f2987aa56a0c542f2ef076"
  let new_root =
    #"d13dbd6ff7b335876e3d6812f26649dc13592b3cd91b38623f95da458a835030"
  let value = from_asset("", "", 500_000_000)

  let proof =
    MPFUpdate {
      from: #"a240a1401a3b9aca00581c5066154a102ee037390c5236f78db23239b49c5748d3d349f3ccf04ba144555344581a3b9aca00",
      to: #"a240a1401a1dcd6500581c5066154a102ee037390c5236f78db23239b49c5748d3d349f3ccf04ba144555344581a3b9aca00",
      to_proof: [
        Branch {
          skip: 0,
          neighbors: #"9543c86b0bb9781a8d503bc087408469b50a3d3e1f7f4b0554dc813ae14c086185c09af929492a871e4fae32d9d5c36e352471cd659bcdb61de08f1722acc3b10eb923b0cbd24df54401d998531feead35a47a99f4deed205de4af81120f97610000000000000000000000000000000000000000000000000000000000000000",
        },
      ],
    }

  account_merkle_balance_decrease(old_root, new_root, account, value, proof)
}
