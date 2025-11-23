use cardano/assets.{from_asset, zero}
use cardano/transaction.{Transaction}
use hydra_account/core as ha
use hydra_dex/types.{
  CancelOrder, FillOrder, MPFInsert, PlaceOrder, ProcessCancelWithdrawal,
  ProcessCombineUtxosAtClose, ProcessWithdrawal, Proofs,
  TreeOrProofsWithTokenMap, UpdateBalanceWithCancelOrder,
  UpdateBalanceWithFillOrder, UpdateBalanceWithPlaceOrder,
}
use mocktail.{
  complete, mock_tx_hash, mock_utxo_ref, mocktail_tx, ref_tx_in,
  ref_tx_in_inline_datum, script_withdrawal, tx_in, withdrawal_redeemer_value,
}
use tests/utils.{
  mock_account, mock_dex_order_book_address, mock_dex_order_book_datum,
  mock_dex_order_book_token, mock_hydra_account, mock_hydra_account_address,
  mock_hydra_order_book, mock_user_account,
}

type TestCase {
  is_dex_order_book_inputed: Bool,
  is_place_order_script_attached: Bool,
  is_fill_order_script_attached: Bool,
  is_cancel_order_script_attached: Bool,
  is_withdrawal_script_attached: Bool,
  is_cancel_withdrawal_script_attached: Bool,
  is_hydra_close_script_attached: Bool,
}

fn mock_tx(test_case: TestCase) -> Transaction {
  let TestCase {
    is_dex_order_book_inputed,
    is_place_order_script_attached,
    is_fill_order_script_attached,
    is_cancel_order_script_attached,
    is_withdrawal_script_attached,
    is_cancel_withdrawal_script_attached,
    is_hydra_close_script_attached,
  } = test_case

  mocktail_tx()
    |> ref_tx_in(
        is_dex_order_book_inputed,
        mock_tx_hash(0),
        1,
        from_asset(mock_dex_order_book_token, "", 1),
        mock_dex_order_book_address,
      )
    |> ref_tx_in_inline_datum(
        is_dex_order_book_inputed,
        mock_dex_order_book_datum,
      )
    |> tx_in(True, mock_tx_hash(0), 0, zero, mock_hydra_account_address)
    |> script_withdrawal(
        is_place_order_script_attached || is_fill_order_script_attached || is_cancel_order_script_attached,
        mock_hydra_order_book,
        0,
      )
    |> withdrawal_redeemer_value(
        is_place_order_script_attached,
        PlaceOrder { account: mock_user_account(mock_account) },
      )
    |> withdrawal_redeemer_value(
        is_fill_order_script_attached,
        FillOrder { filler_order_id: "" },
      )
    |> withdrawal_redeemer_value(is_cancel_order_script_attached, CancelOrder)
    |> script_withdrawal(
        is_withdrawal_script_attached || is_cancel_withdrawal_script_attached || is_hydra_close_script_attached,
        mock_hydra_account,
        0,
      )
    |> withdrawal_redeemer_value(
        is_withdrawal_script_attached,
        ProcessWithdrawal { mpf_action: MPFInsert { proof: [] } },
      )
    |> withdrawal_redeemer_value(
        is_cancel_withdrawal_script_attached,
        ProcessCancelWithdrawal { mpf_action: MPFInsert { proof: [] } },
      )
    |> withdrawal_redeemer_value(
        is_hydra_close_script_attached,
        ProcessCombineUtxosAtClose {
          tree_or_proofs_with_token_map: TreeOrProofsWithTokenMap {
            proof: Proofs { proofs: [] },
            token_map: [],
          },
        },
      )
    |> complete()
}

test s8_w_spend_success_update_balance_with_place_order_intent() {
  let redeemer = UpdateBalanceWithPlaceOrder
  let tx =
    mock_tx(
      TestCase {
        is_dex_order_book_inputed: True,
        is_place_order_script_attached: True,
        is_fill_order_script_attached: False,
        is_cancel_order_script_attached: False,
        is_withdrawal_script_attached: False,
        is_cancel_withdrawal_script_attached: False,
        is_hydra_close_script_attached: False,
      },
    )

  ha.hydra_account.spend(
    mock_dex_order_book_token,
    None,
    redeemer,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s8_w_spend_fail_update_balance_with_place_order_intent_with_no_dex_oracle_inputed() fail {
  let redeemer = UpdateBalanceWithPlaceOrder
  let tx =
    mock_tx(
      TestCase {
        is_dex_order_book_inputed: False,
        is_place_order_script_attached: True,
        is_fill_order_script_attached: False,
        is_cancel_order_script_attached: False,
        is_withdrawal_script_attached: False,
        is_cancel_withdrawal_script_attached: False,
        is_hydra_close_script_attached: False,
      },
    )

  ha.hydra_account.spend(
    mock_dex_order_book_token,
    None,
    redeemer,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s8_w_spend_fail_update_balance_with_place_order_intent_with_no_auth_attached() fail {
  let redeemer = UpdateBalanceWithPlaceOrder
  let tx =
    mock_tx(
      TestCase {
        is_dex_order_book_inputed: True,
        is_place_order_script_attached: False,
        is_fill_order_script_attached: False,
        is_cancel_order_script_attached: False,
        is_withdrawal_script_attached: False,
        is_cancel_withdrawal_script_attached: False,
        is_hydra_close_script_attached: False,
      },
    )

  ha.hydra_account.spend(
    mock_dex_order_book_token,
    None,
    redeemer,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s8_w_spend_success_update_balance_with_fill_order() {
  let redeemer = UpdateBalanceWithFillOrder
  let tx =
    mock_tx(
      TestCase {
        is_dex_order_book_inputed: True,
        is_place_order_script_attached: False,
        is_fill_order_script_attached: True,
        is_cancel_order_script_attached: False,
        is_withdrawal_script_attached: False,
        is_cancel_withdrawal_script_attached: False,
        is_hydra_close_script_attached: False,
      },
    )

  ha.hydra_account.spend(
    mock_dex_order_book_token,
    None,
    redeemer,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s8_w_spend_fail_update_balance_with_fill_order_with_no_dex_oracle_inputed() fail {
  let redeemer = UpdateBalanceWithFillOrder
  let tx =
    mock_tx(
      TestCase {
        is_dex_order_book_inputed: False,
        is_place_order_script_attached: False,
        is_fill_order_script_attached: True,
        is_cancel_order_script_attached: False,
        is_withdrawal_script_attached: False,
        is_cancel_withdrawal_script_attached: False,
        is_hydra_close_script_attached: False,
      },
    )

  ha.hydra_account.spend(
    mock_dex_order_book_token,
    None,
    redeemer,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s8_w_spend_fail_update_balance_with_fill_order_with_no_auth_attached() fail {
  let redeemer = UpdateBalanceWithFillOrder
  let tx =
    mock_tx(
      TestCase {
        is_dex_order_book_inputed: True,
        is_place_order_script_attached: False,
        is_fill_order_script_attached: False,
        is_cancel_order_script_attached: False,
        is_withdrawal_script_attached: False,
        is_cancel_withdrawal_script_attached: False,
        is_hydra_close_script_attached: False,
      },
    )

  ha.hydra_account.spend(
    mock_dex_order_book_token,
    None,
    redeemer,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s8_w_spend_success_update_balance_with_cancel_order() {
  let redeemer = UpdateBalanceWithCancelOrder
  let tx =
    mock_tx(
      TestCase {
        is_dex_order_book_inputed: True,
        is_place_order_script_attached: False,
        is_fill_order_script_attached: False,
        is_cancel_order_script_attached: True,
        is_withdrawal_script_attached: False,
        is_cancel_withdrawal_script_attached: False,
        is_hydra_close_script_attached: False,
      },
    )

  ha.hydra_account.spend(
    mock_dex_order_book_token,
    None,
    redeemer,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s8_w_spend_fail_update_balance_with_cancel_order_with_no_dex_oracle_inputed() fail {
  let redeemer = UpdateBalanceWithCancelOrder
  let tx =
    mock_tx(
      TestCase {
        is_dex_order_book_inputed: False,
        is_place_order_script_attached: False,
        is_fill_order_script_attached: False,
        is_cancel_order_script_attached: True,
        is_withdrawal_script_attached: False,
        is_cancel_withdrawal_script_attached: False,
        is_hydra_close_script_attached: False,
      },
    )

  ha.hydra_account.spend(
    mock_dex_order_book_token,
    None,
    redeemer,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s8_w_spend_fail_update_balance_with_cancel_order_with_no_auth_attached() fail {
  let redeemer = UpdateBalanceWithCancelOrder
  let tx =
    mock_tx(
      TestCase {
        is_dex_order_book_inputed: True,
        is_place_order_script_attached: False,
        is_fill_order_script_attached: False,
        is_cancel_order_script_attached: False,
        is_withdrawal_script_attached: False,
        is_cancel_withdrawal_script_attached: False,
        is_hydra_close_script_attached: False,
      },
    )

  ha.hydra_account.spend(
    mock_dex_order_book_token,
    None,
    redeemer,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s8_w_spend_success_update_balance_with_withdrawal_intent() {
  let redeemer = ProcessWithdrawal { mpf_action: MPFInsert { proof: [] } }
  let tx =
    mock_tx(
      TestCase {
        is_dex_order_book_inputed: True,
        is_place_order_script_attached: False,
        is_fill_order_script_attached: False,
        is_cancel_order_script_attached: False,
        is_withdrawal_script_attached: True,
        is_cancel_withdrawal_script_attached: False,
        is_hydra_close_script_attached: False,
      },
    )

  ha.hydra_account.spend(
    mock_dex_order_book_token,
    None,
    redeemer,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s8_w_spend_fail_update_balance_with_withdrawal_intent_with_no_dex_oracle_inputed() fail {
  let redeemer = ProcessWithdrawal { mpf_action: MPFInsert { proof: [] } }
  let tx =
    mock_tx(
      TestCase {
        is_dex_order_book_inputed: False,
        is_place_order_script_attached: False,
        is_fill_order_script_attached: False,
        is_cancel_order_script_attached: False,
        is_withdrawal_script_attached: True,
        is_cancel_withdrawal_script_attached: False,
        is_hydra_close_script_attached: False,
      },
    )

  ha.hydra_account.spend(
    mock_dex_order_book_token,
    None,
    redeemer,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s8_w_spend_fail_update_balance_with_withdrawal_intent_with_no_auth_attached() fail {
  let redeemer = ProcessWithdrawal { mpf_action: MPFInsert { proof: [] } }
  let tx =
    mock_tx(
      TestCase {
        is_dex_order_book_inputed: True,
        is_place_order_script_attached: False,
        is_fill_order_script_attached: False,
        is_cancel_order_script_attached: False,
        is_withdrawal_script_attached: False,
        is_cancel_withdrawal_script_attached: False,
        is_hydra_close_script_attached: False,
      },
    )

  !ha.hydra_account.spend(
    mock_dex_order_book_token,
    None,
    redeemer,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s8_w_spend_success_update_balance_with_cancel_withdrawal_intent() {
  let redeemer = ProcessCancelWithdrawal { mpf_action: MPFInsert { proof: [] } }
  let tx =
    mock_tx(
      TestCase {
        is_dex_order_book_inputed: True,
        is_place_order_script_attached: False,
        is_fill_order_script_attached: False,
        is_cancel_order_script_attached: False,
        is_withdrawal_script_attached: False,
        is_cancel_withdrawal_script_attached: True,
        is_hydra_close_script_attached: False,
      },
    )

  ha.hydra_account.spend(
    mock_dex_order_book_token,
    None,
    redeemer,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s8_w_spend_fail_update_balance_with_cancel_withdrawal_intent_with_no_dex_oracle_inputed() fail {
  let redeemer = ProcessCancelWithdrawal { mpf_action: MPFInsert { proof: [] } }
  let tx =
    mock_tx(
      TestCase {
        is_dex_order_book_inputed: False,
        is_place_order_script_attached: False,
        is_fill_order_script_attached: False,
        is_cancel_order_script_attached: False,
        is_withdrawal_script_attached: False,
        is_cancel_withdrawal_script_attached: True,
        is_hydra_close_script_attached: False,
      },
    )

  ha.hydra_account.spend(
    mock_dex_order_book_token,
    None,
    redeemer,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s8_w_spend_fail_update_balance_with_cancel_withdrawal_intent_with_no_auth_attached() fail {
  let redeemer = ProcessCancelWithdrawal { mpf_action: MPFInsert { proof: [] } }
  let tx =
    mock_tx(
      TestCase {
        is_dex_order_book_inputed: True,
        is_place_order_script_attached: False,
        is_fill_order_script_attached: False,
        is_cancel_order_script_attached: False,
        is_withdrawal_script_attached: False,
        is_cancel_withdrawal_script_attached: False,
        is_hydra_close_script_attached: False,
      },
    )

  !ha.hydra_account.spend(
    mock_dex_order_book_token,
    None,
    redeemer,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s8_w_spend_success_combine_utxos_at_close() {
  let redeemer =
    ProcessCombineUtxosAtClose {
      tree_or_proofs_with_token_map: TreeOrProofsWithTokenMap {
        proof: Proofs { proofs: [] },
        token_map: [],
      },
    }
  let tx =
    mock_tx(
      TestCase {
        is_dex_order_book_inputed: True,
        is_place_order_script_attached: False,
        is_fill_order_script_attached: False,
        is_cancel_order_script_attached: False,
        is_withdrawal_script_attached: False,
        is_cancel_withdrawal_script_attached: False,
        is_hydra_close_script_attached: True,
      },
    )

  ha.hydra_account.spend(
    mock_dex_order_book_token,
    None,
    redeemer,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s8_w_spend_fail_combine_utxos_at_close_with_no_dex_oracle_inputed() fail {
  let redeemer =
    ProcessCombineUtxosAtClose {
      tree_or_proofs_with_token_map: TreeOrProofsWithTokenMap {
        proof: Proofs { proofs: [] },
        token_map: [],
      },
    }
  let tx =
    mock_tx(
      TestCase {
        is_dex_order_book_inputed: False,
        is_place_order_script_attached: False,
        is_fill_order_script_attached: False,
        is_cancel_order_script_attached: False,
        is_withdrawal_script_attached: False,
        is_cancel_withdrawal_script_attached: False,
        is_hydra_close_script_attached: True,
      },
    )

  ha.hydra_account.spend(
    mock_dex_order_book_token,
    None,
    redeemer,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s8_w_spend_fail_combine_utxos_at_close_with_no_auth_attached() fail {
  let redeemer =
    ProcessCombineUtxosAtClose {
      tree_or_proofs_with_token_map: TreeOrProofsWithTokenMap {
        proof: Proofs { proofs: [] },
        token_map: [],
      },
    }
  let tx =
    mock_tx(
      TestCase {
        is_dex_order_book_inputed: True,
        is_place_order_script_attached: False,
        is_fill_order_script_attached: False,
        is_cancel_order_script_attached: False,
        is_withdrawal_script_attached: False,
        is_cancel_withdrawal_script_attached: False,
        is_hydra_close_script_attached: False,
      },
    )

  !ha.hydra_account.spend(
    mock_dex_order_book_token,
    None,
    redeemer,
    mock_utxo_ref(0, 0),
    tx,
  )
}
