use cardano/assets.{add, from_asset}
use cardano/transaction.{Transaction}
use dex_order_book/spend as dex_order_book_spend
use hydra_dex/types.{
  CombineOrderMerkle, DexOrderBookCombineMerkleTree,
  DexOrderBookEmergencyCancelOrder, DexOrderBookSplitMerkleTree, FullTree,
  SplitOrderMerkle, Tree, TreeBranch, TreeOrProofsWithTokenMap,
}
use mocktail.{
  complete, mock_policy_id, mock_script_address, mock_tx_hash, mock_utxo_ref,
  mocktail_tx, ref_tx_in, ref_tx_in_inline_datum, script_withdrawal, tx_in,
  tx_out, withdrawal_redeemer_value,
}
use tests/utils.{
  mock_dex_order_book_datum, mock_dex_order_book_token,
  mock_emergency_cancel_order, mock_hydra_order_book, mock_input_oracle_datum,
  mock_oracle_address, mock_oracle_nft, mock_token_map,
}

const tree: Tree = TreeBranch { nibble: #"", nodes: [] }

type TestCase {
  is_app_oracle_inputed: Bool,
  is_split_order_merkle_script_attached: Bool,
  is_combine_order_merkle_script_attached: Bool,
  is_emergency_cancel_order_script_attached: Bool,
}

fn mock_tx(test_case: TestCase) -> Transaction {
  let TestCase {
    is_app_oracle_inputed,
    is_split_order_merkle_script_attached,
    is_combine_order_merkle_script_attached,
    is_emergency_cancel_order_script_attached,
  } = test_case

  let input_value =
    from_asset(mock_policy_id(999), "", 1) |> add("", "", 2_000_000)

  mocktail_tx()
    |> ref_tx_in(
        is_app_oracle_inputed,
        mock_tx_hash(0),
        0,
        from_asset(mock_oracle_nft, "", 1),
        mock_oracle_address,
      )
    |> ref_tx_in_inline_datum(is_app_oracle_inputed, mock_input_oracle_datum)
    |> tx_in(
        True,
        mock_tx_hash(0),
        0,
        input_value,
        mock_script_address(999, None),
      )
    |> tx_out(True, mock_script_address(999, None), input_value)
    |> script_withdrawal(
        is_split_order_merkle_script_attached || is_combine_order_merkle_script_attached,
        mock_hydra_order_book,
        0,
      )
    |> withdrawal_redeemer_value(
        is_split_order_merkle_script_attached,
        SplitOrderMerkle {
          tree_or_proofs_with_token_map: TreeOrProofsWithTokenMap {
            proof: FullTree { tree },
            token_map: mock_token_map,
          },
        },
      )
    |> withdrawal_redeemer_value(
        is_combine_order_merkle_script_attached,
        CombineOrderMerkle {
          tree_or_proofs_with_token_map: TreeOrProofsWithTokenMap {
            proof: FullTree { tree },
            token_map: mock_token_map,
          },
        },
      )
    |> script_withdrawal(
        is_emergency_cancel_order_script_attached,
        mock_emergency_cancel_order,
        0,
      )
    |> complete()
}

// TODO: Fix
// │ · with traces
// │ | the validator crashed / exited prematurely
// │ | expect w_redeemer: HydraOrderBookRedeemer = w_redeemer
test s6_spend_w_success_split_merkle_tree() {
  let redeemer = DexOrderBookSplitMerkleTree
  let tx =
    mock_tx(
      TestCase {
        is_app_oracle_inputed: False,
        is_split_order_merkle_script_attached: True,
        is_combine_order_merkle_script_attached: False,
        is_emergency_cancel_order_script_attached: False,
      },
    )

  dex_order_book_spend.dex_order_book.spend(
    mock_oracle_nft,
    mock_dex_order_book_token,
    Some(mock_dex_order_book_datum),
    redeemer,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s6_spend_w_fail_split_merkle_tree_with_no_attached() fail {
  let redeemer = DexOrderBookSplitMerkleTree

  let tx =
    mock_tx(
      TestCase {
        is_app_oracle_inputed: False,
        is_split_order_merkle_script_attached: False,
        is_combine_order_merkle_script_attached: False,
        is_emergency_cancel_order_script_attached: False,
      },
    )

  !dex_order_book_spend.dex_order_book.spend(
    mock_oracle_nft,
    mock_dex_order_book_token,
    Some(mock_dex_order_book_datum),
    redeemer,
    mock_utxo_ref(0, 0),
    tx,
  )
}

// TODO: Fix
// │ · with traces
// │ | the validator crashed / exited prematurely
// │ | expect w_redeemer: HydraOrderBookRedeemer = w_redeemer
test s6_spend_w_success_combine_merkle_tree() {
  let redeemer = DexOrderBookCombineMerkleTree
  let tx =
    mock_tx(
      TestCase {
        is_app_oracle_inputed: False,
        is_split_order_merkle_script_attached: False,
        is_combine_order_merkle_script_attached: True,
        is_emergency_cancel_order_script_attached: False,
      },
    )

  dex_order_book_spend.dex_order_book.spend(
    mock_oracle_nft,
    mock_dex_order_book_token,
    Some(mock_dex_order_book_datum),
    redeemer,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s6_spend_w_fail_combine_merkle_tree_with_no_attached() fail {
  let redeemer = DexOrderBookCombineMerkleTree

  let tx =
    mock_tx(
      TestCase {
        is_app_oracle_inputed: False,
        is_split_order_merkle_script_attached: False,
        is_combine_order_merkle_script_attached: False,
        is_emergency_cancel_order_script_attached: False,
      },
    )

  !dex_order_book_spend.dex_order_book.spend(
    mock_oracle_nft,
    mock_dex_order_book_token,
    Some(mock_dex_order_book_datum),
    redeemer,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s6_spend_w_success_emergency_cancel_order() {
  let redeemer = DexOrderBookEmergencyCancelOrder
  let tx =
    mock_tx(
      TestCase {
        is_app_oracle_inputed: True,
        is_split_order_merkle_script_attached: False,
        is_combine_order_merkle_script_attached: False,
        is_emergency_cancel_order_script_attached: True,
      },
    )

  dex_order_book_spend.dex_order_book.spend(
    mock_oracle_nft,
    mock_dex_order_book_token,
    Some(mock_dex_order_book_datum),
    redeemer,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s6_spend_w_fail_emergency_cancel_order_with_no_app_oracle_inputed() fail {
  let redeemer = DexOrderBookEmergencyCancelOrder

  let tx =
    mock_tx(
      TestCase {
        is_app_oracle_inputed: False,
        is_split_order_merkle_script_attached: False,
        is_combine_order_merkle_script_attached: False,
        is_emergency_cancel_order_script_attached: True,
      },
    )

  dex_order_book_spend.dex_order_book.spend(
    mock_oracle_nft,
    mock_dex_order_book_token,
    Some(mock_dex_order_book_datum),
    redeemer,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s6_spend_w_fail_emergency_cancel_order_with_no_attached() {
  let redeemer = DexOrderBookEmergencyCancelOrder

  let tx =
    mock_tx(
      TestCase {
        is_app_oracle_inputed: True,
        is_split_order_merkle_script_attached: False,
        is_combine_order_merkle_script_attached: False,
        is_emergency_cancel_order_script_attached: False,
      },
    )

  !dex_order_book_spend.dex_order_book.spend(
    mock_oracle_nft,
    mock_dex_order_book_token,
    Some(mock_dex_order_book_datum),
    redeemer,
    mock_utxo_ref(0, 0),
    tx,
  )
}
