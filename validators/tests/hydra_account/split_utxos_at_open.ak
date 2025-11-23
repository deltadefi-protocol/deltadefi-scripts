use aiken/cbor
use aiken/merkle_patricia_forestry/merkling.{null_hash}
use cardano/address.{Script}
use cardano/assets.{from_asset, from_lovelace, zero}
use cardano/transaction.{Transaction}
use hydra_account/core as ha
use hydra_dex/hydra_tree_utils.{compute_tree_hash}
use hydra_dex/types.{
  Account, DexAccountBalanceDatum, FullTree, ProcessSplitUtxosAtOpen, Tree,
  TreeBranch, TreeLeaf, TreeOrProofsWithTokenMap, UserSpotAccount,
}
use mocktail.{
  complete, mint, mock_tx_hash, mocktail_tx, ref_tx_in, ref_tx_in_inline_datum,
  required_signer_hash, tx_in, tx_in_inline_datum, tx_out, tx_out_inline_datum,
}
use tests/utils.{
  mock_account, mock_account_2, mock_account_3, mock_dex_account_balance_address,
  mock_dex_account_balance_token, mock_dex_order_book_address,
  mock_dex_order_book_datum, mock_dex_order_book_token,
  mock_hydra_account_address, mock_hydra_lovelace, mock_hydra_token_policy_id,
  mock_hydra_usd, mock_hydra_usd_token_name, mock_operation_key, mock_token_map,
  mock_usd,
}

type HydraOpenTestCase {
  is_tree_valid: Bool,
  is_outputs_correct: Bool,
  is_output_root_hash_correct: Bool,
  is_value_minted: Bool,
  is_operation_key_signed: Bool,
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
    is_value_minted,
    is_operation_key_signed,
  } = test_case

  mocktail_tx()
    |> mint(is_value_minted, 100, mock_hydra_token_policy_id, "")
    |> mint(
        is_value_minted,
        10000,
        mock_hydra_token_policy_id,
        mock_hydra_usd_token_name,
      )
    |> required_signer_hash(is_operation_key_signed, mock_operation_key)
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
    |> tx_out(True, mock_hydra_account_address, mock_hydra_usd(10000))
    |> tx_out_inline_datum(True, UserSpotAccount { account: mock_account_2 })
    |> tx_out(True, mock_hydra_account_address, mock_hydra_lovelace(100))
    |> tx_out_inline_datum(True, UserSpotAccount { account: mock_account_3 })
    |> tx_out(is_outputs_correct, mock_hydra_account_address, zero)
    |> tx_out_inline_datum(
        is_outputs_correct,
        UserSpotAccount { account: mock_account },
      )
    |> complete()
}

test s8_w_suao_spend_success_hydra_open() {
  let test_case =
    HydraOpenTestCase {
      is_tree_valid: True,
      is_outputs_correct: True,
      is_output_root_hash_correct: True,
      is_value_minted: True,
      is_operation_key_signed: True,
    }
  let tx = mock_hydra_open_tx(test_case)
  ha.hydra_account.withdraw(
    mock_dex_order_book_token,
    ProcessSplitUtxosAtOpen {
      tree_or_proofs_with_token_map: TreeOrProofsWithTokenMap {
        proof: FullTree { tree },
        token_map: mock_token_map,
      },
    },
    Script(""),
    tx,
  )
}

test s8_w_suao_spend_fail_hydra_open_tree_invalid() {
  let test_case =
    HydraOpenTestCase {
      is_tree_valid: False,
      is_outputs_correct: True,
      is_output_root_hash_correct: True,
      is_value_minted: True,
      is_operation_key_signed: True,
    }
  let tx = mock_hydra_open_tx(test_case)
  !ha.hydra_account.withdraw(
    mock_dex_order_book_token,
    ProcessSplitUtxosAtOpen {
      tree_or_proofs_with_token_map: TreeOrProofsWithTokenMap {
        proof: FullTree { tree },
        token_map: mock_token_map,
      },
    },
    Script(""),
    tx,
  )
}

test s8_w_suao_spend_fail_hydra_open_output_root_hash_invalid() {
  let test_case =
    HydraOpenTestCase {
      is_tree_valid: True,
      is_outputs_correct: True,
      is_output_root_hash_correct: False,
      is_value_minted: True,
      is_operation_key_signed: True,
    }
  let tx = mock_hydra_open_tx(test_case)
  !ha.hydra_account.withdraw(
    mock_dex_order_book_token,
    ProcessSplitUtxosAtOpen {
      tree_or_proofs_with_token_map: TreeOrProofsWithTokenMap {
        proof: FullTree { tree },
        token_map: mock_token_map,
      },
    },
    Script(""),
    tx,
  )
}

test s8_w_suao_spend_fail_without_hydra_value_minted() {
  let test_case =
    HydraOpenTestCase {
      is_tree_valid: True,
      is_outputs_correct: True,
      is_output_root_hash_correct: True,
      is_value_minted: False,
      is_operation_key_signed: True,
    }
  let tx = mock_hydra_open_tx(test_case)
  !ha.hydra_account.withdraw(
    mock_dex_order_book_token,
    ProcessSplitUtxosAtOpen {
      tree_or_proofs_with_token_map: TreeOrProofsWithTokenMap {
        proof: FullTree { tree },
        token_map: mock_token_map,
      },
    },
    Script(""),
    tx,
  )
}

test s8_w_suao_spend_fail_without_operation_key_signed() {
  let test_case =
    HydraOpenTestCase {
      is_tree_valid: True,
      is_outputs_correct: True,
      is_output_root_hash_correct: True,
      is_value_minted: True,
      is_operation_key_signed: False,
    }
  let tx = mock_hydra_open_tx(test_case)
  !ha.hydra_account.withdraw(
    mock_dex_order_book_token,
    ProcessSplitUtxosAtOpen {
      tree_or_proofs_with_token_map: TreeOrProofsWithTokenMap {
        proof: FullTree { tree },
        token_map: mock_token_map,
      },
    },
    Script(""),
    tx,
  )
}
