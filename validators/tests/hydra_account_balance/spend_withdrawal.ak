use cardano/assets.{from_asset}
use cardano/transaction.{Transaction}
use hydra_account_balance/spend as hydra_account_balance_spend
use hydra_dex/types.{
  HydraCombineUtxosAtClose, UpdataBalanceWithCancelOrder,
  UpdataBalanceWithFillOrder, UpdateBalanceWithCancelWithdrawal,
  UpdateBalanceWithPlaceOrder, UpdateBalanceWithWithdrawal,
}
use mocktail.{
  complete, mock_tx_hash, mock_utxo_ref, mocktail_tx, ref_tx_in,
  ref_tx_in_inline_datum, script_withdrawal,
}
use tests/utils.{
  mock_dex_order_book_address, mock_dex_order_book_datum,
  mock_dex_order_book_token, mock_hydra_cancel_order,
  mock_hydra_cancel_withdrawal, mock_hydra_fill_order, mock_hydra_head_close,
  mock_hydra_place_order, mock_hydra_withdrawal,
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
        0,
        from_asset(mock_dex_order_book_token, "", 1),
        mock_dex_order_book_address,
      )
    |> ref_tx_in_inline_datum(
        is_dex_order_book_inputed,
        mock_dex_order_book_datum,
      )
    |> script_withdrawal(
        is_place_order_script_attached,
        mock_hydra_place_order,
        0,
      )
    |> script_withdrawal(
        is_fill_order_script_attached,
        mock_hydra_fill_order,
        0,
      )
    |> script_withdrawal(
        is_cancel_order_script_attached,
        mock_hydra_cancel_order,
        0,
      )
    |> script_withdrawal(
        is_withdrawal_script_attached,
        mock_hydra_withdrawal,
        0,
      )
    |> script_withdrawal(
        is_cancel_withdrawal_script_attached,
        mock_hydra_cancel_withdrawal,
        0,
      )
    |> script_withdrawal(
        is_hydra_close_script_attached,
        mock_hydra_head_close,
        0,
      )
    |> complete()
}

test s8_spend_w_success_updata_balance_with_place_order_intent() {
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

  hydra_account_balance_spend.hydra_account_balance.spend(
    mock_dex_order_book_token,
    None,
    redeemer,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s8_spend_w_fail_updata_balance_with_place_order_intent_with_no_dex_oracle_inputed() fail {
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

  hydra_account_balance_spend.hydra_account_balance.spend(
    mock_dex_order_book_token,
    None,
    redeemer,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s8_spend_w_fail_updata_balance_with_place_order_intent_with_no_auth_attached() {
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

  !hydra_account_balance_spend.hydra_account_balance.spend(
    mock_dex_order_book_token,
    None,
    redeemer,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s8_spend_w_success_updata_balance_with_fill_order() {
  let redeemer = UpdataBalanceWithFillOrder
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

  hydra_account_balance_spend.hydra_account_balance.spend(
    mock_dex_order_book_token,
    None,
    redeemer,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s8_spend_w_fail_updata_balance_with_fill_order_with_no_dex_oracle_inputed() fail {
  let redeemer = UpdataBalanceWithFillOrder
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

  hydra_account_balance_spend.hydra_account_balance.spend(
    mock_dex_order_book_token,
    None,
    redeemer,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s8_spend_w_fail_updata_balance_with_fill_order_with_no_auth_attached() {
  let redeemer = UpdataBalanceWithFillOrder
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

  !hydra_account_balance_spend.hydra_account_balance.spend(
    mock_dex_order_book_token,
    None,
    redeemer,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s8_spend_w_success_updata_balance_with_cancel_order() {
  let redeemer = UpdataBalanceWithCancelOrder
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

  hydra_account_balance_spend.hydra_account_balance.spend(
    mock_dex_order_book_token,
    None,
    redeemer,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s8_spend_w_fail_updata_balance_with_cancel_order_with_no_dex_oracle_inputed() fail {
  let redeemer = UpdataBalanceWithCancelOrder
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

  hydra_account_balance_spend.hydra_account_balance.spend(
    mock_dex_order_book_token,
    None,
    redeemer,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s8_spend_w_fail_updata_balance_with_cancel_order_with_no_auth_attached() {
  let redeemer = UpdataBalanceWithCancelOrder
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

  !hydra_account_balance_spend.hydra_account_balance.spend(
    mock_dex_order_book_token,
    None,
    redeemer,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s8_spend_w_success_updata_balance_with_withdrawal_intent() {
  let redeemer = UpdateBalanceWithWithdrawal
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

  hydra_account_balance_spend.hydra_account_balance.spend(
    mock_dex_order_book_token,
    None,
    redeemer,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s8_spend_w_fail_updata_balance_with_withdrawal_intent_with_no_dex_oracle_inputed() fail {
  let redeemer = UpdateBalanceWithWithdrawal
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

  hydra_account_balance_spend.hydra_account_balance.spend(
    mock_dex_order_book_token,
    None,
    redeemer,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s8_spend_w_fail_updata_balance_with_withdrawal_intent_with_no_auth_attached() {
  let redeemer = UpdateBalanceWithWithdrawal
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

  !hydra_account_balance_spend.hydra_account_balance.spend(
    mock_dex_order_book_token,
    None,
    redeemer,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s8_spend_w_success_updata_balance_with_cancel_withdrawal_intent() {
  let redeemer = UpdateBalanceWithCancelWithdrawal
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

  hydra_account_balance_spend.hydra_account_balance.spend(
    mock_dex_order_book_token,
    None,
    redeemer,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s8_spend_w_fail_updata_balance_with_cancel_withdrawal_intent_with_no_dex_oracle_inputed() fail {
  let redeemer = UpdateBalanceWithCancelWithdrawal
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

  hydra_account_balance_spend.hydra_account_balance.spend(
    mock_dex_order_book_token,
    None,
    redeemer,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s8_spend_w_fail_updata_balance_with_cancel_withdrawal_intent_with_no_auth_attached() {
  let redeemer = UpdateBalanceWithCancelWithdrawal
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

  !hydra_account_balance_spend.hydra_account_balance.spend(
    mock_dex_order_book_token,
    None,
    redeemer,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s8_spend_w_success_combine_utxos_at_close() {
  let redeemer = HydraCombineUtxosAtClose
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

  hydra_account_balance_spend.hydra_account_balance.spend(
    mock_dex_order_book_token,
    None,
    redeemer,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s8_spend_w_fail_combine_utxos_at_close_with_no_dex_oracle_inputed() fail {
  let redeemer = HydraCombineUtxosAtClose
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

  hydra_account_balance_spend.hydra_account_balance.spend(
    mock_dex_order_book_token,
    None,
    redeemer,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s8_spend_w_fail_combine_utxos_at_close_with_no_auth_attached() {
  let redeemer = HydraCombineUtxosAtClose
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

  !hydra_account_balance_spend.hydra_account_balance.spend(
    mock_dex_order_book_token,
    None,
    redeemer,
    mock_utxo_ref(0, 0),
    tx,
  )
}
