// TODO: update merkle root

use aiken/builtin.{blake2b_256}
use aiken/cbor
use aiken/merkle_patricia_forestry/merkling.{null_hash}
use cardano/address.{Script}
use cardano/assets.{from_asset}
use cardano/transaction.{Transaction}
use dex_order_book/split_order_merkle
use hydra_dex/hydra_tree_utils.{compute_tree_hash}
use hydra_dex/types.{DexOrderBookDatum, FullTree, Tree, TreeBranch, TreeLeaf}
use mocktail.{
  complete, mock_tx_hash, mocktail_tx, tx_in, tx_in_inline_datum, tx_out,
  tx_out_inline_datum,
}
use tests/utils.{
  mock_account, mock_account_2, mock_account_3, mock_dex_order_book_address,
  mock_dex_order_book_datum, mock_dex_order_book_token,
  mock_hydra_order_book_address, mock_hydra_order_book_token, mock_order,
}

type DexOrderBookSplitOrderMerkleTestCase {
  is_tree_valid: Bool,
  is_outputs_correct: Bool,
  is_output_root_hash_correct: Bool,
}

const order_1 =
  mock_order("order_1", False, 250_000_000, 1_000_000_000, 10, mock_account)

const order_2 =
  mock_order("order_2", True, 250_000_000, 1_000_000_000, 10, mock_account_2)

const order_3 =
  mock_order("order_3", True, 250_000_000, 1_000_000_000, 10, mock_account_3)

const tree: Tree =
  TreeBranch {
    nibble: #"",
    nodes: [
      Pair(
        5,
        TreeLeaf {
          path: blake2b_256("order_2"),
          key: "order_2",
          value: cbor.serialise(order_2),
        },
      ),
      Pair(
        13,
        TreeLeaf {
          path: blake2b_256("order_1"),
          key: "order_1",
          value: cbor.serialise(order_1),
        },
      ),
    ],
  }

const invalid_tree: Tree =
  TreeBranch {
    nibble: #"",
    nodes: [
      Pair(
        5,
        TreeLeaf {
          path: #"586e692e203ea6bb9604a19b15317c25b19c37c4e7e5d26732863443be295a92",
          key: "order_2",
          value: cbor.serialise(order_2),
        },
      ),
      Pair(
        11,
        TreeLeaf {
          path: #"b073a0b9785b1fbd3c7d58079cdd0b4f526083e08a6959d898e0e8813d0db29d",
          key: "order_3",
          value: cbor.serialise(order_3),
        },
      ),
      Pair(
        13,
        TreeLeaf {
          path: #"de4687e07f4ff480f9d434d9446fcbb789edfb1190025f448abe1758a7c213d4",
          key: "order_1",
          value: cbor.serialise(order_1),
        },
      ),
    ],
  }

fn mock_dex_order_book_split_order_merkle_tx(
  test_case: DexOrderBookSplitOrderMerkleTestCase,
) -> Transaction {
  let DexOrderBookSplitOrderMerkleTestCase {
    is_tree_valid,
    is_outputs_correct,
    is_output_root_hash_correct,
  } = test_case
  mocktail_tx()
    |> tx_in(
        True,
        mock_tx_hash(0),
        0,
        from_asset(mock_dex_order_book_token, "", 1),
        mock_dex_order_book_address,
      )
    |> tx_in_inline_datum(
        is_tree_valid,
        DexOrderBookDatum {
          ..mock_dex_order_book_datum,
          limit_orders_merkle_root: tree |> compute_tree_hash(),
        },
      )
    |> tx_in_inline_datum(
        !is_tree_valid,
        DexOrderBookDatum {
          ..mock_dex_order_book_datum,
          limit_orders_merkle_root: invalid_tree |> compute_tree_hash(),
        },
      )
    |> tx_out(
        True,
        mock_dex_order_book_address,
        from_asset(mock_dex_order_book_token, "", 1),
      )
    |> tx_out_inline_datum(
        is_output_root_hash_correct,
        DexOrderBookDatum {
          ..mock_dex_order_book_datum,
          limit_orders_merkle_root: null_hash,
        },
      )
    |> tx_out_inline_datum(
        !is_output_root_hash_correct,
        DexOrderBookDatum {
          ..mock_dex_order_book_datum,
          limit_orders_merkle_root: invalid_tree |> compute_tree_hash(),
        },
      )
    |> tx_out(
        True,
        mock_hydra_order_book_address,
        from_asset(mock_hydra_order_book_token, "order_2", 1),
      )
    |> tx_out_inline_datum(True, order_2)
    |> tx_out(
        is_outputs_correct,
        mock_hydra_order_book_address,
        from_asset(mock_hydra_order_book_token, "order_1", 1),
      )
    |> tx_out_inline_datum(True, order_1)
    |> complete()
}

test s6_spend_success_split_order_merkle() {
  let test_case =
    DexOrderBookSplitOrderMerkleTestCase {
      is_tree_valid: True,
      is_outputs_correct: True,
      is_output_root_hash_correct: True,
    }
  let tx = mock_dex_order_book_split_order_merkle_tx(test_case)
  split_order_merkle.split_order_merkle.withdraw(
    mock_dex_order_book_token,
    FullTree { tree },
    Script(""),
    tx,
  )
}

test s6_spend_fail_split_order_merkle_tree_invalid() fail {
  let test_case =
    DexOrderBookSplitOrderMerkleTestCase {
      is_tree_valid: False,
      is_outputs_correct: True,
      is_output_root_hash_correct: True,
    }
  let tx = mock_dex_order_book_split_order_merkle_tx(test_case)
  split_order_merkle.split_order_merkle.withdraw(
    mock_dex_order_book_token,
    FullTree { tree },
    Script(""),
    tx,
  )
}

test s6_spend_fail_split_order_merkle_outputs_invalid() fail {
  let test_case =
    DexOrderBookSplitOrderMerkleTestCase {
      is_tree_valid: True,
      is_outputs_correct: False,
      is_output_root_hash_correct: True,
    }
  let tx = mock_dex_order_book_split_order_merkle_tx(test_case)
  split_order_merkle.split_order_merkle.withdraw(
    mock_dex_order_book_token,
    FullTree { tree },
    Script(""),
    tx,
  )
}

test s6_spend_fail_split_order_merkle_output_root_hash_invalid() fail {
  let test_case =
    DexOrderBookSplitOrderMerkleTestCase {
      is_tree_valid: True,
      is_outputs_correct: True,
      is_output_root_hash_correct: False,
    }
  let tx = mock_dex_order_book_split_order_merkle_tx(test_case)
  split_order_merkle.split_order_merkle.withdraw(
    mock_dex_order_book_token,
    FullTree { tree },
    Script(""),
    tx,
  )
}
