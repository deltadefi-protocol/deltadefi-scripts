use cardano/assets.{add, from_asset}
use cardano/transaction.{Transaction}
use dex_account_balance/spend as dex_account_balance
use hydra_dex/types.{
  AppDeposit, AppWithdrawal, DABCombineMerkleTree, DABSplitMerkleTree,
  HydraCancelWithdrawal, HydraWithdrawal, MPFDelete, MPFInsert,
  ProcessCancelWithdrawal, ProcessCombineUtxosAtClose, ProcessSplitUtxosAtOpen,
  ProcessWithdrawal, Proofs, TreeOrProofsWithTokenMap,
}
use mocktail.{
  complete, mock_policy_id, mock_script_address, mock_tx_hash, mock_utxo_ref,
  mocktail_tx, ref_tx_in, ref_tx_in_inline_datum, script_withdrawal, tx_in,
  tx_out, withdrawal_redeemer_value,
}
use tests/utils.{
  mock_app_deposit, mock_app_withdrawal, mock_dex_order_book_address,
  mock_dex_order_book_datum, mock_dex_order_book_token, mock_hydra_account,
  mock_input_oracle_datum, mock_oracle_address, mock_oracle_nft,
}

type TestCase {
  is_app_oracle_inputed: Bool,
  is_dex_order_book_inputed: Bool,
  is_app_deposit_script_attached: Bool,
  is_app_withdrawal_script_attached: Bool,
  is_hydra_withdrawal_script_attached: Bool,
  is_hydra_cancel_withdrawal_script_attached: Bool,
  is_hydra_head_open_script_attached: Bool,
  is_hydra_head_close_script_attached: Bool,
}

fn mock_tx(test_case: TestCase) -> Transaction {
  let TestCase {
    is_app_oracle_inputed,
    is_dex_order_book_inputed,
    is_app_deposit_script_attached,
    is_app_withdrawal_script_attached,
    is_hydra_withdrawal_script_attached,
    is_hydra_cancel_withdrawal_script_attached,
    is_hydra_head_open_script_attached,
    is_hydra_head_close_script_attached,
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
    |> ref_tx_in(
        is_dex_order_book_inputed,
        mock_tx_hash(0),
        0,
        from_asset(mock_dex_order_book_token, "", 1),
        mock_dex_order_book_address,
      )
    |> ref_tx_in_inline_datum(
        is_dex_order_book_inputed,
        mock_dex_order_book_datum,
      )
    |> tx_in(
        True,
        mock_tx_hash(0),
        0,
        input_value,
        mock_script_address(999, None),
      )
    |> tx_out(True, mock_script_address(999, None), input_value)
    |> script_withdrawal(is_app_deposit_script_attached, mock_app_deposit, 0)
    |> withdrawal_redeemer_value(is_app_deposit_script_attached, AppDeposit)
    |> script_withdrawal(
        is_app_withdrawal_script_attached,
        mock_app_withdrawal,
        0,
      )
    |> withdrawal_redeemer_value(
        is_app_withdrawal_script_attached,
        AppWithdrawal,
      )
    |> script_withdrawal(
        is_hydra_withdrawal_script_attached || is_hydra_cancel_withdrawal_script_attached || is_hydra_head_open_script_attached || is_hydra_head_close_script_attached,
        mock_hydra_account,
        0,
      )
    |> withdrawal_redeemer_value(
        is_hydra_withdrawal_script_attached,
        ProcessWithdrawal { mpf_action: MPFInsert { proof: [] } },
      )
    |> withdrawal_redeemer_value(
        is_hydra_cancel_withdrawal_script_attached,
        ProcessCancelWithdrawal { mpf_action: MPFDelete { proof: [] } },
      )
    |> withdrawal_redeemer_value(
        is_hydra_head_open_script_attached,
        ProcessSplitUtxosAtOpen {
          tree_or_proofs_with_token_map: TreeOrProofsWithTokenMap {
            proof: Proofs { proofs: [] },
            token_map: [],
          },
        },
      )
    |> withdrawal_redeemer_value(
        is_hydra_head_close_script_attached,
        ProcessCombineUtxosAtClose {
          tree_or_proofs_with_token_map: TreeOrProofsWithTokenMap {
            proof: Proofs { proofs: [] },
            token_map: [],
          },
        },
      )
    |> complete()
}

test s5_w_spend_success_app_deposit() {
  let redeemer = AppDeposit
  let tx =
    mock_tx(
      TestCase {
        is_app_oracle_inputed: True,
        is_dex_order_book_inputed: True,
        is_app_deposit_script_attached: True,
        is_app_withdrawal_script_attached: False,
        is_hydra_withdrawal_script_attached: False,
        is_hydra_cancel_withdrawal_script_attached: False,
        is_hydra_head_open_script_attached: False,
        is_hydra_head_close_script_attached: False,
      },
    )

  dex_account_balance.dex_account_balance.spend(
    mock_oracle_nft,
    mock_dex_order_book_token,
    None,
    redeemer,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s5_w_spend_fail_app_deposit_with_no_app_oracle_inputed() fail {
  let redeemer = AppDeposit

  let tx =
    mock_tx(
      TestCase {
        is_app_oracle_inputed: False,
        is_dex_order_book_inputed: True,
        is_app_deposit_script_attached: True,
        is_app_withdrawal_script_attached: False,
        is_hydra_withdrawal_script_attached: False,
        is_hydra_cancel_withdrawal_script_attached: False,
        is_hydra_head_open_script_attached: False,
        is_hydra_head_close_script_attached: False,
      },
    )

  dex_account_balance.dex_account_balance.spend(
    mock_oracle_nft,
    mock_dex_order_book_token,
    None,
    redeemer,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s5_w_spend_success_app_deposit_with_no_dex_oracle_inputed() {
  let redeemer = AppDeposit

  let tx =
    mock_tx(
      TestCase {
        is_app_oracle_inputed: True,
        is_dex_order_book_inputed: False,
        is_app_deposit_script_attached: True,
        is_app_withdrawal_script_attached: False,
        is_hydra_withdrawal_script_attached: False,
        is_hydra_cancel_withdrawal_script_attached: False,
        is_hydra_head_open_script_attached: False,
        is_hydra_head_close_script_attached: False,
      },
    )
  dex_account_balance.dex_account_balance.spend(
    mock_oracle_nft,
    mock_dex_order_book_token,
    None,
    redeemer,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s5_w_spend_fail_app_deposit_without_script() {
  let redeemer = AppDeposit

  let tx =
    mock_tx(
      TestCase {
        is_app_oracle_inputed: True,
        is_dex_order_book_inputed: True,
        is_app_deposit_script_attached: False,
        is_app_withdrawal_script_attached: False,
        is_hydra_withdrawal_script_attached: False,
        is_hydra_cancel_withdrawal_script_attached: False,
        is_hydra_head_open_script_attached: False,
        is_hydra_head_close_script_attached: False,
      },
    )

  !dex_account_balance.dex_account_balance.spend(
    mock_oracle_nft,
    mock_dex_order_book_token,
    None,
    redeemer,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s5_w_spend_success_app_withdrawal() {
  let redeemer = AppWithdrawal
  let tx =
    mock_tx(
      TestCase {
        is_app_oracle_inputed: True,
        is_dex_order_book_inputed: True,
        is_app_deposit_script_attached: False,
        is_app_withdrawal_script_attached: True,
        is_hydra_withdrawal_script_attached: False,
        is_hydra_cancel_withdrawal_script_attached: False,
        is_hydra_head_open_script_attached: False,
        is_hydra_head_close_script_attached: False,
      },
    )

  dex_account_balance.dex_account_balance.spend(
    mock_oracle_nft,
    mock_dex_order_book_token,
    None,
    redeemer,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s5_w_spend_fail_app_withdrawal_with_no_app_oracle_inputed() fail {
  let redeemer = AppWithdrawal

  let tx =
    mock_tx(
      TestCase {
        is_app_oracle_inputed: False,
        is_dex_order_book_inputed: True,
        is_app_deposit_script_attached: False,
        is_app_withdrawal_script_attached: True,
        is_hydra_withdrawal_script_attached: False,
        is_hydra_cancel_withdrawal_script_attached: False,
        is_hydra_head_open_script_attached: False,
        is_hydra_head_close_script_attached: False,
      },
    )

  dex_account_balance.dex_account_balance.spend(
    mock_oracle_nft,
    mock_dex_order_book_token,
    None,
    redeemer,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s5_w_spend_success_app_withdrawal_with_no_dex_oracle_inputed() {
  let redeemer = AppWithdrawal

  let tx =
    mock_tx(
      TestCase {
        is_app_oracle_inputed: True,
        is_dex_order_book_inputed: False,
        is_app_deposit_script_attached: False,
        is_app_withdrawal_script_attached: True,
        is_hydra_withdrawal_script_attached: False,
        is_hydra_cancel_withdrawal_script_attached: False,
        is_hydra_head_open_script_attached: False,
        is_hydra_head_close_script_attached: False,
      },
    )
  dex_account_balance.dex_account_balance.spend(
    mock_oracle_nft,
    mock_dex_order_book_token,
    None,
    redeemer,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s5_w_spend_fail_app_withdrawal_without_script() {
  let redeemer = AppWithdrawal

  let tx =
    mock_tx(
      TestCase {
        is_app_oracle_inputed: True,
        is_dex_order_book_inputed: True,
        is_app_deposit_script_attached: False,
        is_app_withdrawal_script_attached: False,
        is_hydra_withdrawal_script_attached: False,
        is_hydra_cancel_withdrawal_script_attached: False,
        is_hydra_head_open_script_attached: False,
        is_hydra_head_close_script_attached: False,
      },
    )

  !dex_account_balance.dex_account_balance.spend(
    mock_oracle_nft,
    mock_dex_order_book_token,
    None,
    redeemer,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s5_w_spend_success_hydra_withdrawal() {
  let redeemer = HydraWithdrawal
  let tx =
    mock_tx(
      TestCase {
        is_app_oracle_inputed: True,
        is_dex_order_book_inputed: True,
        is_app_deposit_script_attached: False,
        is_app_withdrawal_script_attached: False,
        is_hydra_withdrawal_script_attached: True,
        is_hydra_cancel_withdrawal_script_attached: False,
        is_hydra_head_open_script_attached: False,
        is_hydra_head_close_script_attached: False,
      },
    )

  dex_account_balance.dex_account_balance.spend(
    mock_oracle_nft,
    mock_dex_order_book_token,
    None,
    redeemer,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s5_w_spend_success_hydra_withdrawal_with_no_app_oracle_inputed() {
  let redeemer = HydraWithdrawal

  let tx =
    mock_tx(
      TestCase {
        is_app_oracle_inputed: False,
        is_dex_order_book_inputed: True,
        is_app_deposit_script_attached: False,
        is_app_withdrawal_script_attached: False,
        is_hydra_withdrawal_script_attached: True,
        is_hydra_cancel_withdrawal_script_attached: False,
        is_hydra_head_open_script_attached: False,
        is_hydra_head_close_script_attached: False,
      },
    )

  dex_account_balance.dex_account_balance.spend(
    mock_oracle_nft,
    mock_dex_order_book_token,
    None,
    redeemer,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s5_w_spend_fail_hydra_withdrawal_with_no_dex_oracle_inputed() fail {
  let redeemer = HydraWithdrawal

  let tx =
    mock_tx(
      TestCase {
        is_app_oracle_inputed: True,
        is_dex_order_book_inputed: False,
        is_app_deposit_script_attached: False,
        is_app_withdrawal_script_attached: False,
        is_hydra_withdrawal_script_attached: True,
        is_hydra_cancel_withdrawal_script_attached: False,
        is_hydra_head_open_script_attached: False,
        is_hydra_head_close_script_attached: False,
      },
    )
  dex_account_balance.dex_account_balance.spend(
    mock_oracle_nft,
    mock_dex_order_book_token,
    None,
    redeemer,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s5_w_spend_fail_hydra_withdrawal_without_script() fail {
  let redeemer = HydraWithdrawal

  let tx =
    mock_tx(
      TestCase {
        is_app_oracle_inputed: True,
        is_dex_order_book_inputed: True,
        is_app_deposit_script_attached: False,
        is_app_withdrawal_script_attached: False,
        is_hydra_withdrawal_script_attached: False,
        is_hydra_cancel_withdrawal_script_attached: False,
        is_hydra_head_open_script_attached: False,
        is_hydra_head_close_script_attached: False,
      },
    )

  !dex_account_balance.dex_account_balance.spend(
    mock_oracle_nft,
    mock_dex_order_book_token,
    None,
    redeemer,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s5_w_spend_success_hydra_cancel_withdrawal() {
  let redeemer = HydraCancelWithdrawal
  let tx =
    mock_tx(
      TestCase {
        is_app_oracle_inputed: True,
        is_dex_order_book_inputed: True,
        is_app_deposit_script_attached: False,
        is_app_withdrawal_script_attached: False,
        is_hydra_withdrawal_script_attached: False,
        is_hydra_cancel_withdrawal_script_attached: True,
        is_hydra_head_open_script_attached: False,
        is_hydra_head_close_script_attached: False,
      },
    )

  dex_account_balance.dex_account_balance.spend(
    mock_oracle_nft,
    mock_dex_order_book_token,
    None,
    redeemer,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s5_w_spend_success_hydra_cancel_withdrawal_with_no_app_oracle_inputed() {
  let redeemer = HydraCancelWithdrawal

  let tx =
    mock_tx(
      TestCase {
        is_app_oracle_inputed: False,
        is_dex_order_book_inputed: True,
        is_app_deposit_script_attached: False,
        is_app_withdrawal_script_attached: False,
        is_hydra_withdrawal_script_attached: False,
        is_hydra_cancel_withdrawal_script_attached: True,
        is_hydra_head_open_script_attached: False,
        is_hydra_head_close_script_attached: False,
      },
    )

  dex_account_balance.dex_account_balance.spend(
    mock_oracle_nft,
    mock_dex_order_book_token,
    None,
    redeemer,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s5_w_spend_fail_hydra_cancel_withdrawal_with_no_dex_oracle_inputed() fail {
  let redeemer = HydraCancelWithdrawal

  let tx =
    mock_tx(
      TestCase {
        is_app_oracle_inputed: True,
        is_dex_order_book_inputed: False,
        is_app_deposit_script_attached: False,
        is_app_withdrawal_script_attached: False,
        is_hydra_withdrawal_script_attached: False,
        is_hydra_cancel_withdrawal_script_attached: True,
        is_hydra_head_open_script_attached: False,
        is_hydra_head_close_script_attached: False,
      },
    )
  dex_account_balance.dex_account_balance.spend(
    mock_oracle_nft,
    mock_dex_order_book_token,
    None,
    redeemer,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s5_w_spend_fail_hydra_cancel_withdrawal_without_script() fail {
  let redeemer = HydraCancelWithdrawal

  let tx =
    mock_tx(
      TestCase {
        is_app_oracle_inputed: True,
        is_dex_order_book_inputed: True,
        is_app_deposit_script_attached: False,
        is_app_withdrawal_script_attached: False,
        is_hydra_withdrawal_script_attached: False,
        is_hydra_cancel_withdrawal_script_attached: False,
        is_hydra_head_open_script_attached: False,
        is_hydra_head_close_script_attached: False,
      },
    )

  !dex_account_balance.dex_account_balance.spend(
    mock_oracle_nft,
    mock_dex_order_book_token,
    None,
    redeemer,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s5_w_spend_success_split_merkle_tree() {
  let redeemer = DABSplitMerkleTree
  let tx =
    mock_tx(
      TestCase {
        is_app_oracle_inputed: True,
        is_dex_order_book_inputed: True,
        is_app_deposit_script_attached: False,
        is_app_withdrawal_script_attached: False,
        is_hydra_withdrawal_script_attached: False,
        is_hydra_cancel_withdrawal_script_attached: False,
        is_hydra_head_open_script_attached: True,
        is_hydra_head_close_script_attached: False,
      },
    )

  dex_account_balance.dex_account_balance.spend(
    mock_oracle_nft,
    mock_dex_order_book_token,
    None,
    redeemer,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s5_w_spend_success_split_merkle_tree_with_no_app_oracle_inputed() {
  let redeemer = DABSplitMerkleTree

  let tx =
    mock_tx(
      TestCase {
        is_app_oracle_inputed: False,
        is_dex_order_book_inputed: True,
        is_app_deposit_script_attached: False,
        is_app_withdrawal_script_attached: False,
        is_hydra_withdrawal_script_attached: False,
        is_hydra_cancel_withdrawal_script_attached: False,
        is_hydra_head_open_script_attached: True,
        is_hydra_head_close_script_attached: False,
      },
    )

  dex_account_balance.dex_account_balance.spend(
    mock_oracle_nft,
    mock_dex_order_book_token,
    None,
    redeemer,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s5_w_spend_fail_split_merkle_tree_with_no_dex_oracle_inputed() fail {
  let redeemer = DABSplitMerkleTree

  let tx =
    mock_tx(
      TestCase {
        is_app_oracle_inputed: True,
        is_dex_order_book_inputed: False,
        is_app_deposit_script_attached: False,
        is_app_withdrawal_script_attached: False,
        is_hydra_withdrawal_script_attached: False,
        is_hydra_cancel_withdrawal_script_attached: False,
        is_hydra_head_open_script_attached: True,
        is_hydra_head_close_script_attached: False,
      },
    )

  dex_account_balance.dex_account_balance.spend(
    mock_oracle_nft,
    mock_dex_order_book_token,
    None,
    redeemer,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s5_w_spend_fail_split_merkle_tree_with_no_script() fail {
  let redeemer = DABSplitMerkleTree

  let tx =
    mock_tx(
      TestCase {
        is_app_oracle_inputed: True,
        is_dex_order_book_inputed: True,
        is_app_deposit_script_attached: False,
        is_app_withdrawal_script_attached: False,
        is_hydra_withdrawal_script_attached: False,
        is_hydra_cancel_withdrawal_script_attached: False,
        is_hydra_head_open_script_attached: False,
        is_hydra_head_close_script_attached: False,
      },
    )

  !dex_account_balance.dex_account_balance.spend(
    mock_oracle_nft,
    mock_dex_order_book_token,
    None,
    redeemer,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s5_w_spend_success_combine_merkle_tree() {
  let redeemer = DABCombineMerkleTree
  let tx =
    mock_tx(
      TestCase {
        is_app_oracle_inputed: True,
        is_dex_order_book_inputed: True,
        is_app_deposit_script_attached: False,
        is_app_withdrawal_script_attached: False,
        is_hydra_withdrawal_script_attached: False,
        is_hydra_cancel_withdrawal_script_attached: False,
        is_hydra_head_open_script_attached: False,
        is_hydra_head_close_script_attached: True,
      },
    )

  dex_account_balance.dex_account_balance.spend(
    mock_oracle_nft,
    mock_dex_order_book_token,
    None,
    redeemer,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s5_w_spend_success_combine_merkle_tree_with_no_app_oracle_inputed() {
  let redeemer = DABCombineMerkleTree

  let tx =
    mock_tx(
      TestCase {
        is_app_oracle_inputed: False,
        is_dex_order_book_inputed: True,
        is_app_deposit_script_attached: False,
        is_app_withdrawal_script_attached: False,
        is_hydra_withdrawal_script_attached: False,
        is_hydra_cancel_withdrawal_script_attached: False,
        is_hydra_head_open_script_attached: False,
        is_hydra_head_close_script_attached: True,
      },
    )

  dex_account_balance.dex_account_balance.spend(
    mock_oracle_nft,
    mock_dex_order_book_token,
    None,
    redeemer,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s5_w_spend_fail_combine_merkle_tree_with_no_dex_oracle_inputed() fail {
  let redeemer = DABSplitMerkleTree

  let tx =
    mock_tx(
      TestCase {
        is_app_oracle_inputed: True,
        is_dex_order_book_inputed: False,
        is_app_deposit_script_attached: False,
        is_app_withdrawal_script_attached: False,
        is_hydra_withdrawal_script_attached: False,
        is_hydra_cancel_withdrawal_script_attached: False,
        is_hydra_head_open_script_attached: False,
        is_hydra_head_close_script_attached: True,
      },
    )

  dex_account_balance.dex_account_balance.spend(
    mock_oracle_nft,
    mock_dex_order_book_token,
    None,
    redeemer,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s5_w_spend_fail_combine_merkle_tree_with_no_script() fail {
  let redeemer = DABCombineMerkleTree

  let tx =
    mock_tx(
      TestCase {
        is_app_oracle_inputed: True,
        is_dex_order_book_inputed: True,
        is_app_deposit_script_attached: False,
        is_app_withdrawal_script_attached: False,
        is_hydra_withdrawal_script_attached: False,
        is_hydra_cancel_withdrawal_script_attached: False,
        is_hydra_head_open_script_attached: False,
        is_hydra_head_close_script_attached: False,
      },
    )

  !dex_account_balance.dex_account_balance.spend(
    mock_oracle_nft,
    mock_dex_order_book_token,
    None,
    redeemer,
    mock_utxo_ref(0, 0),
    tx,
  )
}
