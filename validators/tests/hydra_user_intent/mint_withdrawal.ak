use cardano/assets.{from_asset}
use cardano/transaction.{Transaction}
use hydra_dex/types.{
  HydraUserCancelOrder, HydraUserCancelWithdrawal, HydraUserPlaceOrder,
  HydraUserTransfer, HydraUserWithdrawal,
}
use hydra_user_intent/mint as hydra_user_intent_mint
use mocktail.{
  complete, mock_tx_hash, mocktail_tx, ref_tx_in, ref_tx_in_inline_datum,
  script_withdrawal,
}
use tests/utils.{
  mock_dex_order_book_datum, mock_dex_order_book_token, mock_hydra_cancel_order,
  mock_hydra_cancel_withdrawal, mock_hydra_internal_transfer,
  mock_hydra_order_book_address, mock_hydra_place_order,
  mock_hydra_user_intent_token, mock_hydra_withdrawal,
}

type ProcessIntentTestCase {
  is_dex_order_book_inputed: Bool,
  is_process_order_script_attached: Bool,
  is_cancel_order_script_attached: Bool,
  is_withdrawal_script_attached: Bool,
  is_cancel_withdrawal_script_attached: Bool,
  is_internal_transfer_script_attached: Bool,
}

fn mock_process_intent_tx(test_case: ProcessIntentTestCase) -> Transaction {
  let ProcessIntentTestCase {
    is_dex_order_book_inputed,
    is_process_order_script_attached,
    is_cancel_order_script_attached,
    is_withdrawal_script_attached,
    is_cancel_withdrawal_script_attached,
    is_internal_transfer_script_attached,
  } = test_case

  mocktail_tx()
    |> ref_tx_in(
        is_dex_order_book_inputed,
        mock_tx_hash(0),
        0,
        from_asset(mock_dex_order_book_token, "", 1),
        mock_hydra_order_book_address,
      )
    |> ref_tx_in_inline_datum(
        is_dex_order_book_inputed,
        mock_dex_order_book_datum,
      )
    |> script_withdrawal(
        is_process_order_script_attached,
        mock_hydra_place_order,
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
        is_internal_transfer_script_attached,
        mock_hydra_internal_transfer,
        0,
      )
    |> complete()
}

test s7_mint_w_success_process_place_order() {
  let redeemer = HydraUserPlaceOrder
  let tx =
    mock_process_intent_tx(
      ProcessIntentTestCase {
        is_dex_order_book_inputed: True,
        is_process_order_script_attached: True,
        is_cancel_order_script_attached: False,
        is_withdrawal_script_attached: False,
        is_cancel_withdrawal_script_attached: False,
        is_internal_transfer_script_attached: False,
      },
    )

  hydra_user_intent_mint.hydra_user_intent.mint(
    mock_dex_order_book_token,
    redeemer,
    mock_hydra_user_intent_token,
    tx,
  )
}

test s7_mint_w_fail_process_place_order_without_dex_order_book_inputed() fail {
  let redeemer = HydraUserPlaceOrder
  let tx =
    mock_process_intent_tx(
      ProcessIntentTestCase {
        is_dex_order_book_inputed: False,
        is_process_order_script_attached: True,
        is_cancel_order_script_attached: False,
        is_withdrawal_script_attached: False,
        is_cancel_withdrawal_script_attached: False,
        is_internal_transfer_script_attached: False,
      },
    )

  hydra_user_intent_mint.hydra_user_intent.mint(
    mock_dex_order_book_token,
    redeemer,
    mock_hydra_user_intent_token,
    tx,
  )
}

test s7_mint_w_fail_process_place_order_without_withdrawal_script() {
  let redeemer = HydraUserPlaceOrder
  let tx =
    mock_process_intent_tx(
      ProcessIntentTestCase {
        is_dex_order_book_inputed: True,
        is_process_order_script_attached: False,
        is_cancel_order_script_attached: False,
        is_withdrawal_script_attached: False,
        is_cancel_withdrawal_script_attached: False,
        is_internal_transfer_script_attached: False,
      },
    )

  !hydra_user_intent_mint.hydra_user_intent.mint(
    mock_dex_order_book_token,
    redeemer,
    mock_hydra_user_intent_token,
    tx,
  )
}

test s7_mint_w_success_process_cancel_order() {
  let redeemer = HydraUserCancelOrder
  let tx =
    mock_process_intent_tx(
      ProcessIntentTestCase {
        is_dex_order_book_inputed: True,
        is_process_order_script_attached: False,
        is_cancel_order_script_attached: True,
        is_withdrawal_script_attached: False,
        is_cancel_withdrawal_script_attached: False,
        is_internal_transfer_script_attached: False,
      },
    )

  hydra_user_intent_mint.hydra_user_intent.mint(
    mock_dex_order_book_token,
    redeemer,
    mock_hydra_user_intent_token,
    tx,
  )
}

test s7_mint_w_fail_process_cancel_order_without_dex_order_book_inputed() fail {
  let redeemer = HydraUserCancelOrder
  let tx =
    mock_process_intent_tx(
      ProcessIntentTestCase {
        is_dex_order_book_inputed: False,
        is_process_order_script_attached: False,
        is_cancel_order_script_attached: True,
        is_withdrawal_script_attached: False,
        is_cancel_withdrawal_script_attached: False,
        is_internal_transfer_script_attached: False,
      },
    )

  hydra_user_intent_mint.hydra_user_intent.mint(
    mock_dex_order_book_token,
    redeemer,
    mock_hydra_user_intent_token,
    tx,
  )
}

test s7_mint_w_fail_process_cancel_order_without_withdrawal_script() {
  let redeemer = HydraUserCancelOrder
  let tx =
    mock_process_intent_tx(
      ProcessIntentTestCase {
        is_dex_order_book_inputed: True,
        is_process_order_script_attached: False,
        is_cancel_order_script_attached: False,
        is_withdrawal_script_attached: False,
        is_cancel_withdrawal_script_attached: False,
        is_internal_transfer_script_attached: False,
      },
    )

  !hydra_user_intent_mint.hydra_user_intent.mint(
    mock_dex_order_book_token,
    redeemer,
    mock_hydra_user_intent_token,
    tx,
  )
}

test s7_mint_w_success_process_withdrawal_order() {
  let redeemer = HydraUserWithdrawal
  let tx =
    mock_process_intent_tx(
      ProcessIntentTestCase {
        is_dex_order_book_inputed: True,
        is_process_order_script_attached: False,
        is_cancel_order_script_attached: False,
        is_withdrawal_script_attached: True,
        is_cancel_withdrawal_script_attached: False,
        is_internal_transfer_script_attached: False,
      },
    )

  hydra_user_intent_mint.hydra_user_intent.mint(
    mock_dex_order_book_token,
    redeemer,
    mock_hydra_user_intent_token,
    tx,
  )
}

test s7_mint_w_fail_process_withdrawal_order_without_dex_order_book_inputed() fail {
  let redeemer = HydraUserWithdrawal
  let tx =
    mock_process_intent_tx(
      ProcessIntentTestCase {
        is_dex_order_book_inputed: False,
        is_process_order_script_attached: False,
        is_cancel_order_script_attached: False,
        is_withdrawal_script_attached: True,
        is_cancel_withdrawal_script_attached: False,
        is_internal_transfer_script_attached: False,
      },
    )

  hydra_user_intent_mint.hydra_user_intent.mint(
    mock_dex_order_book_token,
    redeemer,
    mock_hydra_user_intent_token,
    tx,
  )
}

test s7_mint_w_fail_process_withdrawal_order_without_withdrawal_script() {
  let redeemer = HydraUserWithdrawal
  let tx =
    mock_process_intent_tx(
      ProcessIntentTestCase {
        is_dex_order_book_inputed: True,
        is_process_order_script_attached: False,
        is_cancel_order_script_attached: False,
        is_withdrawal_script_attached: False,
        is_cancel_withdrawal_script_attached: False,
        is_internal_transfer_script_attached: False,
      },
    )

  !hydra_user_intent_mint.hydra_user_intent.mint(
    mock_dex_order_book_token,
    redeemer,
    mock_hydra_user_intent_token,
    tx,
  )
}

test s7_mint_w_success_process_cancel_withdrawal_order() {
  let redeemer = HydraUserCancelWithdrawal
  let tx =
    mock_process_intent_tx(
      ProcessIntentTestCase {
        is_dex_order_book_inputed: True,
        is_process_order_script_attached: False,
        is_cancel_order_script_attached: False,
        is_withdrawal_script_attached: False,
        is_cancel_withdrawal_script_attached: True,
        is_internal_transfer_script_attached: False,
      },
    )

  hydra_user_intent_mint.hydra_user_intent.mint(
    mock_dex_order_book_token,
    redeemer,
    mock_hydra_user_intent_token,
    tx,
  )
}

test s7_mint_w_fail_process_cancel_withdrawal_order_without_dex_order_book_inputed() fail {
  let redeemer = HydraUserCancelWithdrawal
  let tx =
    mock_process_intent_tx(
      ProcessIntentTestCase {
        is_dex_order_book_inputed: False,
        is_process_order_script_attached: False,
        is_cancel_order_script_attached: False,
        is_withdrawal_script_attached: False,
        is_cancel_withdrawal_script_attached: True,
        is_internal_transfer_script_attached: False,
      },
    )

  hydra_user_intent_mint.hydra_user_intent.mint(
    mock_dex_order_book_token,
    redeemer,
    mock_hydra_user_intent_token,
    tx,
  )
}

test s7_mint_w_fail_process_cancel_withdrawal_order_without_withdrawal_script() {
  let redeemer = HydraUserCancelWithdrawal
  let tx =
    mock_process_intent_tx(
      ProcessIntentTestCase {
        is_dex_order_book_inputed: True,
        is_process_order_script_attached: False,
        is_cancel_order_script_attached: False,
        is_withdrawal_script_attached: False,
        is_cancel_withdrawal_script_attached: False,
        is_internal_transfer_script_attached: False,
      },
    )

  !hydra_user_intent_mint.hydra_user_intent.mint(
    mock_dex_order_book_token,
    redeemer,
    mock_hydra_user_intent_token,
    tx,
  )
}

test s7_mint_w_success_process_internal_transfer_order() {
  let redeemer = HydraUserTransfer
  let tx =
    mock_process_intent_tx(
      ProcessIntentTestCase {
        is_dex_order_book_inputed: True,
        is_process_order_script_attached: False,
        is_cancel_order_script_attached: False,
        is_withdrawal_script_attached: False,
        is_cancel_withdrawal_script_attached: False,
        is_internal_transfer_script_attached: True,
      },
    )

  hydra_user_intent_mint.hydra_user_intent.mint(
    mock_dex_order_book_token,
    redeemer,
    mock_hydra_user_intent_token,
    tx,
  )
}

test s7_mint_w_fail_process_internal_transfer_order_without_dex_order_book_inputed() fail {
  let redeemer = HydraUserTransfer
  let tx =
    mock_process_intent_tx(
      ProcessIntentTestCase {
        is_dex_order_book_inputed: False,
        is_process_order_script_attached: False,
        is_cancel_order_script_attached: False,
        is_withdrawal_script_attached: False,
        is_cancel_withdrawal_script_attached: False,
        is_internal_transfer_script_attached: True,
      },
    )

  hydra_user_intent_mint.hydra_user_intent.mint(
    mock_dex_order_book_token,
    redeemer,
    mock_hydra_user_intent_token,
    tx,
  )
}

test s7_mint_w_fail_process_internal_transfer_order_without_withdrawal_script() {
  let redeemer = HydraUserTransfer
  let tx =
    mock_process_intent_tx(
      ProcessIntentTestCase {
        is_dex_order_book_inputed: True,
        is_process_order_script_attached: False,
        is_cancel_order_script_attached: False,
        is_withdrawal_script_attached: False,
        is_cancel_withdrawal_script_attached: False,
        is_internal_transfer_script_attached: False,
      },
    )

  !hydra_user_intent_mint.hydra_user_intent.mint(
    mock_dex_order_book_token,
    redeemer,
    mock_hydra_user_intent_token,
    tx,
  )
}
