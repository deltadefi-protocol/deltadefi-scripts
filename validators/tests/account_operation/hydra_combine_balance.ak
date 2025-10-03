use account_operation/hydra_combine_balance
use cardano/address.{Script}
use cardano/assets.{from_asset, from_lovelace, merge}
use cardano/transaction.{Transaction}
use hydra_dex/types.{HydraAccountBalanceDatum, UserSpotAccount}
use mocktail.{
  complete, mint, mock_tx_hash, mocktail_tx, ref_tx_in, ref_tx_in_inline_datum,
  required_signer_hash, script_withdrawal, tx_in, tx_in_inline_datum, tx_out,
  tx_out_inline_datum,
}
use tests/utils.{
  mock_account, mock_account_2, mock_dex_order_book_address,
  mock_dex_order_book_datum, mock_dex_order_book_token,
  mock_hydra_account_balance_address, mock_hydra_account_balance_token,
  mock_hydra_combine_balance, mock_operation_key, to_mvalue,
}

type HydraCombineBalanceTestCase {
  is_operation_key_signed: Bool,
  is_same_account: Bool,
  is_balance_updated: Bool,
  is_account_burnt: Bool,
}

fn mock_hydra_combine_balance_tx(
  test_case: HydraCombineBalanceTestCase,
) -> Transaction {
  let HydraCombineBalanceTestCase {
    is_operation_key_signed,
    is_same_account,
    is_balance_updated,
    is_account_burnt,
  } = test_case

  let balance_a = from_lovelace(1_000_000_000)
  let balance_b = from_lovelace(1_000_000_000)
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
    |> tx_in(
        True,
        mock_tx_hash(0),
        0,
        from_asset(mock_hydra_account_balance_token, "", 1),
        mock_hydra_account_balance_address,
      )
    |> tx_in_inline_datum(
        True,
        HydraAccountBalanceDatum {
          account: UserSpotAccount { account: mock_account },
          balance: balance_a |> to_mvalue(),
        },
      )
    |> tx_in(
        True,
        mock_tx_hash(0),
        1,
        from_asset(mock_hydra_account_balance_token, "", 1),
        mock_hydra_account_balance_address,
      )
    |> tx_in_inline_datum(
        True,
        HydraAccountBalanceDatum {
          account: UserSpotAccount { account: mock_account },
          balance: balance_b |> to_mvalue(),
        },
      )
    |> tx_out(
        True,
        mock_hydra_account_balance_address,
        from_asset(mock_hydra_account_balance_token, "", 1),
      )
    |> tx_out_inline_datum(
        True,
        HydraAccountBalanceDatum {
          account: UserSpotAccount { account },
          balance: combined_balance |> to_mvalue(),
        },
      )
    |> mint(is_account_burnt, -1, mock_hydra_account_balance_token, "")
    |> script_withdrawal(True, mock_hydra_combine_balance, 0)
    |> required_signer_hash(is_operation_key_signed, mock_operation_key)
    |> complete()
}

test s1_whit_success() {
  let test_case =
    HydraCombineBalanceTestCase {
      is_operation_key_signed: True,
      is_same_account: True,
      is_balance_updated: True,
      is_account_burnt: True,
    }

  let tx = mock_hydra_combine_balance_tx(test_case)

  hydra_combine_balance.hydra_combine_balance.withdraw(
    mock_dex_order_book_token,
    Void,
    Script(""),
    tx,
  )
}

test s1_whit_failed_without_operation_key_signed() {
  let test_case =
    HydraCombineBalanceTestCase {
      is_operation_key_signed: False,
      is_same_account: True,
      is_balance_updated: True,
      is_account_burnt: True,
    }

  let tx = mock_hydra_combine_balance_tx(test_case)

  !hydra_combine_balance.hydra_combine_balance.withdraw(
    mock_dex_order_book_token,
    Void,
    Script(""),
    tx,
  )
}

test s1_whit_failed_with_different_account() {
  let test_case =
    HydraCombineBalanceTestCase {
      is_operation_key_signed: True,
      is_same_account: False,
      is_balance_updated: True,
      is_account_burnt: True,
    }

  let tx = mock_hydra_combine_balance_tx(test_case)

  !hydra_combine_balance.hydra_combine_balance.withdraw(
    mock_dex_order_book_token,
    Void,
    Script(""),
    tx,
  )
}

test s1_whit_failed_with_balance_not_combined() {
  let test_case =
    HydraCombineBalanceTestCase {
      is_operation_key_signed: True,
      is_same_account: True,
      is_balance_updated: False,
      is_account_burnt: True,
    }

  let tx = mock_hydra_combine_balance_tx(test_case)

  !hydra_combine_balance.hydra_combine_balance.withdraw(
    mock_dex_order_book_token,
    Void,
    Script(""),
    tx,
  )
}

test s1_whit_failed_with_account_not_burnt() {
  let test_case =
    HydraCombineBalanceTestCase {
      is_operation_key_signed: True,
      is_same_account: True,
      is_balance_updated: True,
      is_account_burnt: False,
    }

  let tx = mock_hydra_combine_balance_tx(test_case)

  !hydra_combine_balance.hydra_combine_balance.withdraw(
    mock_dex_order_book_token,
    Void,
    Script(""),
    tx,
  )
}
