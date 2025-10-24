use account_operation/hydra_head_open
use aiken/cbor
use aiken/merkle_patricia_forestry/merkling.{null_hash}
use cardano/address.{Script}
use cardano/assets.{from_asset, from_lovelace}
use cardano/transaction.{Transaction}
use hydra_dex/hydra_tree_utils.{compute_tree_hash}
use hydra_dex/types.{
  Account, DexAccountBalanceDatum, FullTree, HydraAccountBalanceDatum, Tree,
  TreeBranch, TreeLeaf, UserSpotAccount,
}
use mocktail.{
  complete, mock_tx_hash, mocktail_tx, ref_tx_in, ref_tx_in_inline_datum, tx_in,
  tx_in_inline_datum, tx_out, tx_out_inline_datum,
}
use tests/utils.{
  mock_account, mock_account_2, mock_account_3, mock_dex_account_balance_address,
  mock_dex_account_balance_token, mock_dex_order_book_address,
  mock_dex_order_book_datum, mock_dex_order_book_token,
  mock_hydra_account_balance_address, mock_hydra_account_balance_token, mock_usd,
  to_mvalue,
}

type HydraOpenTestCase {
  is_tree_valid: Bool,
  is_outputs_correct: Bool,
  is_output_root_hash_correct: Bool,
}

type AccountWrapper {
  wrapped_account: Account,
}

const tree: Tree =
  TreeBranch {
    nibble: #"",
    nodes: [
      Pair(
        4,
        TreeLeaf {
          path: #"4edd63a178c1f0a5cf5d3ff33c80d172a52d94d49294f7c565e2308d8183f0c3",
          key: cbor.serialise(
            AccountWrapper { wrapped_account: mock_account_2 },
          ),
          value: cbor.serialise(mock_usd(10000)),
        },
      ),
      Pair(
        5,
        TreeLeaf {
          path: #"597dd2983e37fd66ba32d94184c5d25a891f566eedb18b5c9f0ec45cb770e59e",
          key: cbor.serialise(
            AccountWrapper { wrapped_account: mock_account_3 },
          ),
          value: cbor.serialise(from_lovelace(100)),
        },
      ),
      Pair(
        15,
        TreeLeaf {
          path: #"f742c7d87d703d499d4d98c2f49a9a59356bce5ac3b9b730a3b26fd6bd7a98b9",
          key: cbor.serialise(AccountWrapper { wrapped_account: mock_account }),
          value: cbor.serialise(from_lovelace(0)),
        },
      ),
    ],
  }

const invalid_tree: Tree =
  TreeBranch {
    nibble: #"",
    nodes: [
      Pair(
        4,
        TreeLeaf {
          path: #"4edd63a178c1f0a5cf5d3ff33c80d172a52d94d49294f7c565e2308d8183f0c3",
          key: cbor.serialise(
            AccountWrapper { wrapped_account: mock_account_2 },
          ),
          value: cbor.serialise(mock_usd(10000)),
        },
      ),
      Pair(
        5,
        TreeLeaf {
          path: #"597dd2983e37fd66ba32d94184c5d25a891f566eedb18b5c9f0ec45cb770e59e",
          key: cbor.serialise(
            AccountWrapper { wrapped_account: mock_account_3 },
          ),
          value: cbor.serialise(from_lovelace(101)),
        },
      ),
      Pair(
        15,
        TreeLeaf {
          path: #"f742c7d87d703d499d4d98c2f49a9a59356bce5ac3b9b730a3b26fd6bd7a98b9",
          key: cbor.serialise(AccountWrapper { wrapped_account: mock_account }),
          value: cbor.serialise(from_lovelace(0)),
        },
      ),
    ],
  }

fn mock_hydra_open_tx(test_case: HydraOpenTestCase) -> Transaction {
  let HydraOpenTestCase {
    is_tree_valid,
    is_outputs_correct,
    is_output_root_hash_correct,
  } = test_case
  mocktail_tx()
    |> ref_tx_in(
        True,
        mock_tx_hash(1),
        0,
        from_asset(mock_dex_order_book_token, "", 1),
        mock_dex_order_book_address,
      )
    |> ref_tx_in_inline_datum(True, mock_dex_order_book_datum)
    |> tx_in(
        True,
        mock_tx_hash(2),
        0,
        from_asset(mock_dex_account_balance_token, "", 1),
        mock_dex_account_balance_address,
      )
    |> tx_in_inline_datum(
        is_tree_valid,
        DexAccountBalanceDatum {
          account_balance_merkle_root: tree |> compute_tree_hash(),
        },
      )
    |> tx_in_inline_datum(
        !is_tree_valid,
        DexAccountBalanceDatum {
          account_balance_merkle_root: invalid_tree |> compute_tree_hash(),
        },
      )
    |> tx_out(
        True,
        mock_dex_account_balance_address,
        from_asset(mock_dex_account_balance_token, "", 1),
      )
    |> tx_out_inline_datum(
        is_output_root_hash_correct,
        DexAccountBalanceDatum { account_balance_merkle_root: null_hash },
      )
    |> tx_out_inline_datum(
        !is_output_root_hash_correct,
        DexAccountBalanceDatum {
          account_balance_merkle_root: tree |> compute_tree_hash(),
        },
      )
    |> tx_out(
        True,
        mock_hydra_account_balance_address,
        from_asset(mock_hydra_account_balance_token, "", 1),
      )
    |> tx_out_inline_datum(
        True,
        HydraAccountBalanceDatum {
          account: UserSpotAccount { account: mock_account_2 },
          balance: mock_usd(10000) |> to_mvalue(),
        },
      )
    |> tx_out(
        True,
        mock_hydra_account_balance_address,
        from_asset(mock_hydra_account_balance_token, "", 1),
      )
    |> tx_out_inline_datum(
        True,
        HydraAccountBalanceDatum {
          account: UserSpotAccount { account: mock_account_3 },
          balance: from_lovelace(100) |> to_mvalue(),
        },
      )
    |> tx_out(
        is_outputs_correct,
        mock_hydra_account_balance_address,
        from_asset(mock_hydra_account_balance_token, "", 1),
      )
    |> tx_out_inline_datum(
        is_outputs_correct,
        HydraAccountBalanceDatum {
          account: UserSpotAccount { account: mock_account },
          balance: from_lovelace(0) |> to_mvalue(),
        },
      )
    |> complete()
}

test s5_spend_success_hydra_open() {
  let test_case =
    HydraOpenTestCase {
      is_tree_valid: True,
      is_outputs_correct: True,
      is_output_root_hash_correct: True,
    }
  let tx = mock_hydra_open_tx(test_case)
  hydra_head_open.hydra_head_open.withdraw(
    mock_dex_order_book_token,
    FullTree { tree },
    Script(""),
    tx,
  )
}

test s5_spend_fail_hydra_open_tree_invalid() fail {
  let test_case =
    HydraOpenTestCase {
      is_tree_valid: False,
      is_outputs_correct: True,
      is_output_root_hash_correct: True,
    }
  let tx = mock_hydra_open_tx(test_case)
  hydra_head_open.hydra_head_open.withdraw(
    mock_dex_order_book_token,
    FullTree { tree },
    Script(""),
    tx,
  )
}

test s5_spend_fail_hydra_open_output_root_hash_invalid() fail {
  let test_case =
    HydraOpenTestCase {
      is_tree_valid: True,
      is_outputs_correct: True,
      is_output_root_hash_correct: False,
    }
  let tx = mock_hydra_open_tx(test_case)
  hydra_head_open.hydra_head_open.withdraw(
    mock_dex_order_book_token,
    FullTree { tree },
    Script(""),
    tx,
  )
}
