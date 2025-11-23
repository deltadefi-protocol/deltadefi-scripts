use cardano/address.{Script}
use cardano/assets.{from_asset, merge, negate}
use cardano/transaction.{Transaction}
use hydra_account/core as ha
use hydra_dex/types.{ProcessTransferal, TransferIntent, UserSpotAccount}
use hydra_dex/utils.{to_mvalue}
use mocktail.{
  complete, mint, mock_tx_hash, mocktail_tx, ref_tx_in, ref_tx_in_inline_datum,
  required_signer_hash, script_withdrawal, tx_in, tx_in_inline_datum, tx_out,
  tx_out_inline_datum,
}
use tests/utils.{
  mock_account, mock_account_2, mock_dex_order_book_address,
  mock_dex_order_book_datum, mock_dex_order_book_token,
  mock_hydra_account_address, mock_hydra_internal_transfer, mock_hydra_lovelace,
  mock_hydra_user_intent_address, mock_hydra_user_intent_token,
  mock_operation_key,
} as test_utils

type HydraInternalTransferTestCase {
  is_operation_key_signed: Bool,
  is_from_account_balance_deducted: Bool,
  is_to_account_balance_added: Bool,
  is_intent_token_burnt: Bool,
}

fn mock_hydra_internal_transfer_tx(
  test_case: HydraInternalTransferTestCase,
) -> Transaction {
  let HydraInternalTransferTestCase {
    is_operation_key_signed,
    is_from_account_balance_deducted,
    is_to_account_balance_added,
    is_intent_token_burnt,
  } = test_case

  let transferal_amount = mock_hydra_lovelace(100_000_000)
  let from_balance_start = mock_hydra_lovelace(1_000_000_000)
  let to_balance_start = mock_hydra_lovelace(1_000_000_000)
  let from_balance_end =
    if is_from_account_balance_deducted {
      transferal_amount |> negate() |> merge(from_balance_start)
    } else {
      from_balance_start
    }
  let to_balance_end =
    if is_to_account_balance_added {
      transferal_amount |> merge(to_balance_start)
    } else {
      to_balance_start
    }

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
        mock_tx_hash(0),
        0,
        from_asset(mock_hydra_user_intent_token, "", 1),
        mock_hydra_user_intent_address,
      )
    |> tx_in_inline_datum(
        True,
        TransferIntent {
          from: UserSpotAccount { account: mock_account },
          to: UserSpotAccount { account: mock_account_2 },
          amount: transferal_amount |> to_mvalue(),
        },
      )
    |> tx_in(
        True,
        mock_tx_hash(0),
        1,
        from_balance_start,
        mock_hydra_account_address,
      )
    |> tx_in_inline_datum(True, UserSpotAccount { account: mock_account })
    |> tx_out(True, mock_hydra_account_address, from_balance_end)
    |> tx_out_inline_datum(True, UserSpotAccount { account: mock_account })
    |> tx_in(
        True,
        mock_tx_hash(0),
        2,
        to_balance_start,
        mock_hydra_account_address,
      )
    |> tx_in_inline_datum(True, UserSpotAccount { account: mock_account_2 })
    |> tx_out(True, mock_hydra_account_address, to_balance_end)
    |> tx_out_inline_datum(True, UserSpotAccount { account: mock_account_2 })
    |> mint(is_intent_token_burnt, -1, mock_hydra_user_intent_token, "")
    |> script_withdrawal(True, mock_hydra_internal_transfer, 0)
    |> required_signer_hash(is_operation_key_signed, mock_operation_key)
    |> complete()
}

test s8_whit_success() {
  let test_case =
    HydraInternalTransferTestCase {
      is_operation_key_signed: True,
      is_from_account_balance_deducted: True,
      is_to_account_balance_added: True,
      is_intent_token_burnt: True,
    }

  let tx = mock_hydra_internal_transfer_tx(test_case)

  ha.hydra_account.withdraw(
    mock_dex_order_book_token,
    ProcessTransferal,
    Script(""),
    tx,
  )
}

test s8_whit_failed_without_operation_key_signed() {
  let test_case =
    HydraInternalTransferTestCase {
      is_operation_key_signed: False,
      is_from_account_balance_deducted: True,
      is_to_account_balance_added: True,
      is_intent_token_burnt: True,
    }

  let tx = mock_hydra_internal_transfer_tx(test_case)

  !ha.hydra_account.withdraw(
    mock_dex_order_book_token,
    ProcessTransferal,
    Script(""),
    tx,
  )
}

test s8_whit_failed_without_from_account_balance_deducted() {
  let test_case =
    HydraInternalTransferTestCase {
      is_operation_key_signed: True,
      is_from_account_balance_deducted: False,
      is_to_account_balance_added: True,
      is_intent_token_burnt: True,
    }

  let tx = mock_hydra_internal_transfer_tx(test_case)

  !ha.hydra_account.withdraw(
    mock_dex_order_book_token,
    ProcessTransferal,
    Script(""),
    tx,
  )
}

test s8_whit_failed_without_to_account_balance_added() {
  let test_case =
    HydraInternalTransferTestCase {
      is_operation_key_signed: True,
      is_from_account_balance_deducted: True,
      is_to_account_balance_added: False,
      is_intent_token_burnt: True,
    }

  let tx = mock_hydra_internal_transfer_tx(test_case)

  !ha.hydra_account.withdraw(
    mock_dex_order_book_token,
    ProcessTransferal,
    Script(""),
    tx,
  )
}

test s8_whit_failed_without_intent_token_burnt() {
  let test_case =
    HydraInternalTransferTestCase {
      is_operation_key_signed: True,
      is_from_account_balance_deducted: True,
      is_to_account_balance_added: True,
      is_intent_token_burnt: False,
    }

  let tx = mock_hydra_internal_transfer_tx(test_case)

  !ha.hydra_account.withdraw(
    mock_dex_order_book_token,
    ProcessTransferal,
    Script(""),
    tx,
  )
}
