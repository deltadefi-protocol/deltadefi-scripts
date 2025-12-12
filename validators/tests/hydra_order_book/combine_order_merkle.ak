// TODO: update merkle root

use aiken/builtin.{blake2b_256}
use aiken/cbor
use aiken/merkle_patricia_forestry/merkling.{null_hash}
use cardano/address.{Script}
use cardano/assets.{from_asset, merge, negate}
use cardano/transaction.{Transaction}
use hydra_dex/hydra_tree_utils.{compute_tree_hash}
use hydra_dex/types.{
  CombineOrderMerkle, DexOrderBookDatum, FullTree, Tree, TreeBranch, TreeLeaf,
  TreeOrProofsWithTokenMap,
}
use hydra_order_book/core as ob
use mocktail.{
  add_mint, complete, mock_tx_hash, mocktail_tx, tx_in, tx_in_inline_datum,
  tx_out, tx_out_inline_datum,
}
use tests/utils.{
  mock_account, mock_account_2, mock_account_3, mock_dex_order_book_address,
  mock_dex_order_book_datum, mock_dex_order_book_token, mock_hydra_lovelace,
  mock_hydra_order_book_address, mock_hydra_usd, mock_order, mock_token_map,
}

type DexOrderBookCombineMerkleTestCase {
  is_tree_valid: Bool,
  is_inputs_correct: Bool,
  is_input_root_hash_correct: Bool,
  is_all_hydra_tokens_burnt: Bool,
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

fn mock_combine_order_merkle_tx(
  test_case: DexOrderBookCombineMerkleTestCase,
) -> Transaction {
  let DexOrderBookCombineMerkleTestCase {
    is_tree_valid,
    is_inputs_correct,
    is_input_root_hash_correct,
    is_all_hydra_tokens_burnt,
  } = test_case

  let order_1_value = mock_hydra_lovelace(250_000_000)
  let order_2_value = mock_hydra_usd(250_000_000)

  mocktail_tx()
    |> tx_in(
        True,
        mock_tx_hash(0),
        0,
        from_asset(mock_dex_order_book_token, "", 1),
        mock_dex_order_book_address,
      )
    |> tx_in_inline_datum(
        is_input_root_hash_correct,
        DexOrderBookDatum {
          ..mock_dex_order_book_datum,
          limit_orders_merkle_root: null_hash,
        },
      )
    |> tx_in_inline_datum(
        !is_input_root_hash_correct,
        DexOrderBookDatum {
          ..mock_dex_order_book_datum,
          limit_orders_merkle_root: invalid_tree |> compute_tree_hash(),
        },
      )
    |> tx_in(
        True,
        mock_tx_hash(1),
        0,
        order_1_value,
        mock_hydra_order_book_address,
      )
    |> tx_in_inline_datum(True, order_1)
    |> tx_in(
        is_inputs_correct,
        mock_tx_hash(1),
        1,
        order_2_value,
        mock_hydra_order_book_address,
      )
    |> tx_in_inline_datum(True, order_2)
    |> tx_out(
        True,
        mock_dex_order_book_address,
        from_asset(mock_dex_order_book_token, "", 1),
      )
    |> tx_out_inline_datum(
        is_tree_valid,
        DexOrderBookDatum {
          ..mock_dex_order_book_datum,
          limit_orders_merkle_root: tree |> compute_tree_hash(),
        },
      )
    |> tx_out_inline_datum(
        !is_tree_valid,
        DexOrderBookDatum {
          ..mock_dex_order_book_datum,
          limit_orders_merkle_root: invalid_tree |> compute_tree_hash(),
        },
      )
    |> complete()
    |> add_mint(
        is_all_hydra_tokens_burnt,
        negate(merge(order_1_value, order_2_value)),
      )
}

// TODO: Fix
// │ · with traces
// │ | extract_key_values(tree) == sorted_serialised_inputs ? False
test s9_wcom_success_combine_order_merkle() {
  let test_case =
    DexOrderBookCombineMerkleTestCase {
      is_tree_valid: True,
      is_inputs_correct: True,
      is_input_root_hash_correct: True,
      is_all_hydra_tokens_burnt: True,
    }

  let tx = mock_combine_order_merkle_tx(test_case)
  ob.hydra_order_book.withdraw(
    mock_dex_order_book_token,
    CombineOrderMerkle {
      tree_or_proofs_with_token_map: TreeOrProofsWithTokenMap {
        proof: FullTree { tree },
        token_map: mock_token_map,
      },
    },
    Script(""),
    tx,
  )
}

test s9_wcom_fail_combine_order_merkle_invalid_tree() fail {
  let test_case =
    DexOrderBookCombineMerkleTestCase {
      is_tree_valid: False,
      is_inputs_correct: True,
      is_input_root_hash_correct: True,
      is_all_hydra_tokens_burnt: True,
    }

  let tx = mock_combine_order_merkle_tx(test_case)
  ob.hydra_order_book.withdraw(
    mock_dex_order_book_token,
    CombineOrderMerkle {
      tree_or_proofs_with_token_map: TreeOrProofsWithTokenMap {
        proof: FullTree { tree },
        token_map: mock_token_map,
      },
    },
    Script(""),
    tx,
  )
}

test s9_wcom_fail_combine_order_merkle_invalid_inputs() {
  let test_case =
    DexOrderBookCombineMerkleTestCase {
      is_tree_valid: True,
      is_inputs_correct: False,
      is_input_root_hash_correct: True,
      is_all_hydra_tokens_burnt: True,
    }

  let tx = mock_combine_order_merkle_tx(test_case)
  !ob.hydra_order_book.withdraw(
    mock_dex_order_book_token,
    CombineOrderMerkle {
      tree_or_proofs_with_token_map: TreeOrProofsWithTokenMap {
        proof: FullTree { tree },
        token_map: mock_token_map,
      },
    },
    Script(""),
    tx,
  )
}

test s9_wcom_fail_combine_order_merkle_invalid_input_root_hash() {
  let test_case =
    DexOrderBookCombineMerkleTestCase {
      is_tree_valid: True,
      is_inputs_correct: True,
      is_input_root_hash_correct: False,
      is_all_hydra_tokens_burnt: True,
    }

  let tx = mock_combine_order_merkle_tx(test_case)
  !ob.hydra_order_book.withdraw(
    mock_dex_order_book_token,
    CombineOrderMerkle {
      tree_or_proofs_with_token_map: TreeOrProofsWithTokenMap {
        proof: FullTree { tree },
        token_map: mock_token_map,
      },
    },
    Script(""),
    tx,
  )
}

test s9_wcom_fail_combine_order_merkle_without_burning_hydra_tokens() {
  let test_case =
    DexOrderBookCombineMerkleTestCase {
      is_tree_valid: True,
      is_inputs_correct: True,
      is_input_root_hash_correct: True,
      is_all_hydra_tokens_burnt: False,
    }

  let tx = mock_combine_order_merkle_tx(test_case)
  !ob.hydra_order_book.withdraw(
    mock_dex_order_book_token,
    CombineOrderMerkle {
      tree_or_proofs_with_token_map: TreeOrProofsWithTokenMap {
        proof: FullTree { tree },
        token_map: mock_token_map,
      },
    },
    Script(""),
    tx,
  )
}
