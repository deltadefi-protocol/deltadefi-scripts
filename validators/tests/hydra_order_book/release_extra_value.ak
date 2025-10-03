use cardano/address.{Script}
use cardano/assets.{from_asset, from_lovelace, merge}
use cardano/transaction.{Transaction}
use hydra_dex/types.{HydraAccountBalanceDatum, UserSpotAccount}
use hydra_order_book/release_extra_value
use mocktail.{
  complete, mock_tx_hash, mocktail_tx, ref_tx_in, ref_tx_in_inline_datum,
  required_signer_hash, tx_in, tx_in_inline_datum, tx_out, tx_out_inline_datum,
}
use tests/utils.{
  mock_account, mock_dex_order_book_address, mock_dex_order_book_datum,
  mock_dex_order_book_token, mock_hydra_account_balance_address,
  mock_hydra_account_balance_token, mock_hydra_order_book_address,
  mock_hydra_order_book_token, mock_hydra_release_extra_value,
  mock_operation_key, mock_order, mock_order_id, mock_usd, to_mvalue,
}

type TestCase {
  is_single_order_input: Bool,
  is_single_order_output: Bool,
  is_datum_correct: Bool,
  is_account_balance_updated: Bool,
  is_operation_key_signed: Bool,
}

fn mock_tx(test_case: TestCase) -> Transaction {
  let TestCase {
    is_single_order_input,
    is_single_order_output,
    is_datum_correct,
    is_account_balance_updated,
    is_operation_key_signed,
  } = test_case

  let is_long = True
  let order_size = 250_000_000
  let list_price_times_1bil = 1_350_000_000
  let fee_amount_bp = 10
  let extra_value = 100_000_000

  let old_order_datum =
    mock_order(
      mock_order_id,
      is_long,
      order_size,
      list_price_times_1bil,
      fee_amount_bp,
      extra_value,
      mock_account,
    )
  let new_order_datum =
    if is_datum_correct {
      mock_order(
        mock_order_id,
        is_long,
        order_size,
        list_price_times_1bil,
        fee_amount_bp,
        0,
        mock_account,
      )
    } else {
      old_order_datum
    }

  let input_balance =
    HydraAccountBalanceDatum {
      account: UserSpotAccount { account: mock_account },
      balance: from_lovelace(500_000_000) |> to_mvalue(),
    }

  let output_balance =
    if is_account_balance_updated {
      HydraAccountBalanceDatum {
        account: UserSpotAccount { account: mock_account },
        balance: from_lovelace(500_000_000)
          |> merge(mock_usd(100_000_000))
          |> to_mvalue(),
      }
    } else {
      input_balance
    }

  mocktail_tx()
    |> ref_tx_in(
        True,
        mock_tx_hash(0),
        0,
        from_asset(mock_dex_order_book_token, "", 1),
        mock_dex_order_book_address,
      )
    |> ref_tx_in_inline_datum(True, mock_dex_order_book_datum)
    |> tx_in(
        True,
        mock_tx_hash(0),
        1,
        from_asset(mock_hydra_order_book_token, mock_order_id, 1),
        mock_hydra_order_book_address,
      )
    |> tx_in_inline_datum(True, old_order_datum)
    |> tx_out(
        True,
        mock_hydra_order_book_address,
        from_asset(mock_hydra_order_book_token, mock_order_id, 1),
      )
    |> tx_out_inline_datum(True, new_order_datum)
    |> tx_in(
        True,
        mock_tx_hash(0),
        2,
        from_asset(mock_hydra_account_balance_token, "", 1),
        mock_hydra_account_balance_address,
      )
    |> tx_in_inline_datum(True, input_balance)
    |> tx_out(
        True,
        mock_hydra_account_balance_address,
        from_asset(mock_hydra_account_balance_token, "", 1),
      )
    |> tx_out_inline_datum(True, output_balance)
    |> required_signer_hash(is_operation_key_signed, mock_operation_key)
    // failing cases
    |> tx_in(
        !is_single_order_input,
        mock_tx_hash(0),
        1,
        from_asset(mock_hydra_order_book_token, mock_order_id, 1),
        mock_hydra_order_book_address,
      )
    |> tx_in_inline_datum(!is_single_order_input, old_order_datum)
    |> tx_out(
        !is_single_order_output,
        mock_hydra_order_book_address,
        from_asset(mock_hydra_order_book_token, mock_order_id, 1),
      )
    |> tx_out_inline_datum(!is_single_order_output, new_order_datum)
    |> complete()
}

test s9_wrev_success() {
  let tx =
    mock_tx(
      TestCase {
        is_single_order_input: True,
        is_single_order_output: True,
        is_datum_correct: True,
        is_account_balance_updated: True,
        is_operation_key_signed: True,
      },
    )
  release_extra_value.release_extra_value.withdraw(
    mock_dex_order_book_token,
    Void,
    Script(mock_hydra_release_extra_value),
    tx,
  )
}

test s9_wrev_fail_with_multiple_order_input() {
  let tx =
    mock_tx(
      TestCase {
        is_single_order_input: False,
        is_single_order_output: True,
        is_datum_correct: True,
        is_account_balance_updated: True,
        is_operation_key_signed: True,
      },
    )
  !release_extra_value.release_extra_value.withdraw(
    mock_dex_order_book_token,
    Void,
    Script(mock_hydra_release_extra_value),
    tx,
  )
}

test s9_wrev_fail_with_multiple_order_output() {
  let tx =
    mock_tx(
      TestCase {
        is_single_order_input: True,
        is_single_order_output: False,
        is_datum_correct: True,
        is_account_balance_updated: True,
        is_operation_key_signed: True,
      },
    )
  !release_extra_value.release_extra_value.withdraw(
    mock_dex_order_book_token,
    Void,
    Script(mock_hydra_release_extra_value),
    tx,
  )
}

test s9_wrev_fail_with_incorrect_datum() {
  let tx =
    mock_tx(
      TestCase {
        is_single_order_input: True,
        is_single_order_output: True,
        is_datum_correct: False,
        is_account_balance_updated: True,
        is_operation_key_signed: True,
      },
    )
  !release_extra_value.release_extra_value.withdraw(
    mock_dex_order_book_token,
    Void,
    Script(mock_hydra_release_extra_value),
    tx,
  )
}

test s9_wrev_fail_without_balance_updated() {
  let tx =
    mock_tx(
      TestCase {
        is_single_order_input: True,
        is_single_order_output: True,
        is_datum_correct: True,
        is_account_balance_updated: False,
        is_operation_key_signed: True,
      },
    )
  !release_extra_value.release_extra_value.withdraw(
    mock_dex_order_book_token,
    Void,
    Script(mock_hydra_release_extra_value),
    tx,
  )
}

test s9_wrev_fail_without_operation_key_signed() {
  let tx =
    mock_tx(
      TestCase {
        is_single_order_input: True,
        is_single_order_output: True,
        is_datum_correct: True,
        is_account_balance_updated: True,
        is_operation_key_signed: False,
      },
    )
  !release_extra_value.release_extra_value.withdraw(
    mock_dex_order_book_token,
    Void,
    Script(mock_hydra_release_extra_value),
    tx,
  )
}
