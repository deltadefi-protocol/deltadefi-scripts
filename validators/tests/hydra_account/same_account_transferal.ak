use cardano/address.{Script}
use cardano/assets.{from_asset, merge}
use cardano/transaction.{Transaction}
use hydra_account/core as ha
use hydra_dex/types.{ProcessSameAccountTransferal}
use mocktail.{
  complete, mock_tx_hash, mocktail_tx, ref_tx_in, ref_tx_in_inline_datum,
  required_signer_hash, tx_in, tx_in_inline_datum, tx_out, tx_out_inline_datum,
}
use tests/utils.{
  mock_account, mock_account_2, mock_dex_order_book_address,
  mock_dex_order_book_datum, mock_dex_order_book_token,
  mock_hydra_account_address, mock_hydra_lovelace, mock_operation_key,
  mock_user_account,
}

type HydraCombineBalanceTestCase {
  is_operation_key_signed: Bool,
  is_same_account: Bool,
  is_balance_updated: Bool,
}

fn mock_same_account_transferal_tx(
  test_case: HydraCombineBalanceTestCase,
) -> Transaction {
  let HydraCombineBalanceTestCase {
    is_operation_key_signed,
    is_same_account,
    is_balance_updated,
  } = test_case

  let balance_a = mock_hydra_lovelace(1_000_000_000)
  let balance_b = mock_hydra_lovelace(1_000_000_000)
  let combined_balance =
    if is_balance_updated {
      merge(balance_a, balance_b)
    } else {
      balance_a
    }
  let account =
    if is_same_account {
      mock_account
    } else {
      mock_account_2
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
    |> tx_in(True, mock_tx_hash(0), 0, balance_a, mock_hydra_account_address)
    |> tx_in_inline_datum(True, mock_user_account(mock_account))
    |> tx_in(True, mock_tx_hash(0), 1, balance_b, mock_hydra_account_address)
    |> tx_in_inline_datum(True, mock_user_account(mock_account))
    |> tx_out(True, mock_hydra_account_address, combined_balance)
    |> tx_out_inline_datum(True, mock_user_account(account))
    |> required_signer_hash(is_operation_key_signed, mock_operation_key)
    |> complete()
}

test s8_w_sat_success() {
  let test_case =
    HydraCombineBalanceTestCase {
      is_operation_key_signed: True,
      is_same_account: True,
      is_balance_updated: True,
    }

  let tx = mock_same_account_transferal_tx(test_case)

  ha.hydra_account.withdraw(
    mock_dex_order_book_token,
    ProcessSameAccountTransferal { account: mock_user_account(mock_account) },
    Script(""),
    tx,
  )
}

test s8_w_sat_failed_without_operation_key_signed() {
  let test_case =
    HydraCombineBalanceTestCase {
      is_operation_key_signed: False,
      is_same_account: True,
      is_balance_updated: True,
    }

  let tx = mock_same_account_transferal_tx(test_case)

  !ha.hydra_account.withdraw(
    mock_dex_order_book_token,
    ProcessSameAccountTransferal { account: mock_user_account(mock_account) },
    Script(""),
    tx,
  )
}

test s8_w_sat_failed_with_different_account() {
  let test_case =
    HydraCombineBalanceTestCase {
      is_operation_key_signed: True,
      is_same_account: False,
      is_balance_updated: True,
    }

  let tx = mock_same_account_transferal_tx(test_case)

  !ha.hydra_account.withdraw(
    mock_dex_order_book_token,
    ProcessSameAccountTransferal { account: mock_user_account(mock_account) },
    Script(""),
    tx,
  )
}

test s8_w_sat_failed_with_balance_not_combined() {
  let test_case =
    HydraCombineBalanceTestCase {
      is_operation_key_signed: True,
      is_same_account: True,
      is_balance_updated: False,
    }

  let tx = mock_same_account_transferal_tx(test_case)

  !ha.hydra_account.withdraw(
    mock_dex_order_book_token,
    ProcessSameAccountTransferal { account: mock_user_account(mock_account) },
    Script(""),
    tx,
  )
}
