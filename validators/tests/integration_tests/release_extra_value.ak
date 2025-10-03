use cardano/address.{Script}
use cardano/assets.{from_asset, from_lovelace, merge}
use cardano/transaction.{Transaction}
use hydra_account_balance/spend as hydra_account_balance
use hydra_dex/types.{
  HydraAccountBalanceDatum, HydraOrderBookDatum, ReleaseExtraValue,
  UpdataBalanceWithReleaseExtraValue, UserSpotAccount,
}
use hydra_order_book/release_extra_value
use hydra_order_book/spend as ob_spend
use mocktail.{
  complete, mock_tx_hash, mock_utxo_ref, mocktail_tx, ref_tx_in,
  ref_tx_in_inline_datum, required_signer_hash, script_withdrawal, tx_in,
  tx_in_inline_datum, tx_out, tx_out_inline_datum,
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
  is_withdrawal_script_validated: Bool,
}

fn mock_tx(
  test_case: TestCase,
) -> (Transaction, HydraOrderBookDatum, HydraAccountBalanceDatum) {
  let TestCase {
    is_single_order_input,
    is_single_order_output,
    is_datum_correct,
    is_account_balance_updated,
    is_operation_key_signed,
    is_withdrawal_script_validated,
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

  let tx =
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
      |> script_withdrawal(
          is_withdrawal_script_validated,
          mock_hydra_release_extra_value,
          0,
        )
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
  (tx, old_order_datum, input_balance)
}

fn check_all_scripts(test_case: TestCase) {
  let (tx, order_datum, input_balance) = mock_tx(test_case)
  // withdrawal
  let withdraw =
    release_extra_value.release_extra_value.withdraw(
      mock_dex_order_book_token,
      Void,
      Script(mock_hydra_release_extra_value),
      tx,
    )
  // hydra_order_book.spend
  let check_ob_spend =
    ob_spend.hydra_order_book.spend(
      mock_dex_order_book_token,
      Some(order_datum),
      ReleaseExtraValue,
      mock_utxo_ref(0, 1),
      tx,
    )
  // hydra_account_balance.spend
  let check_hydra_balance =
    hydra_account_balance.hydra_account_balance.spend(
      mock_dex_order_book_token,
      Some(input_balance),
      UpdataBalanceWithReleaseExtraValue,
      mock_utxo_ref(0, 2),
      tx,
    )

  withdraw? && check_ob_spend? && check_hydra_balance?
}

test it_hrev_success() {
  let test_case =
    TestCase {
      is_single_order_input: True,
      is_single_order_output: True,
      is_datum_correct: True,
      is_account_balance_updated: True,
      is_operation_key_signed: True,
      is_withdrawal_script_validated: True,
    }
  check_all_scripts(test_case)
}

test it_hrev_fail_with_multiple_order_input() {
  let test_case =
    TestCase {
      is_single_order_input: False,
      is_single_order_output: True,
      is_datum_correct: True,
      is_account_balance_updated: True,
      is_operation_key_signed: True,
      is_withdrawal_script_validated: True,
    }
  !check_all_scripts(test_case)
}

test it_hrev_fail_with_multiple_order_output() {
  let test_case =
    TestCase {
      is_single_order_input: True,
      is_single_order_output: False,
      is_datum_correct: True,
      is_account_balance_updated: True,
      is_operation_key_signed: True,
      is_withdrawal_script_validated: True,
    }
  !check_all_scripts(test_case)
}

test it_hrev_fail_with_incorrect_datum() {
  let test_case =
    TestCase {
      is_single_order_input: True,
      is_single_order_output: True,
      is_datum_correct: False,
      is_account_balance_updated: True,
      is_operation_key_signed: True,
      is_withdrawal_script_validated: True,
    }
  !check_all_scripts(test_case)
}

test it_hrev_fail_without_balance_updated() {
  let test_case =
    TestCase {
      is_single_order_input: True,
      is_single_order_output: True,
      is_datum_correct: True,
      is_account_balance_updated: False,
      is_operation_key_signed: True,
      is_withdrawal_script_validated: True,
    }
  !check_all_scripts(test_case)
}

test it_hrev_fail_without_operation_key_signed() {
  let test_case =
    TestCase {
      is_single_order_input: True,
      is_single_order_output: True,
      is_datum_correct: True,
      is_account_balance_updated: True,
      is_operation_key_signed: False,
      is_withdrawal_script_validated: True,
    }
  !check_all_scripts(test_case)
}

test it_hrev_fail_without_withdrawal_script() {
  let test_case =
    TestCase {
      is_single_order_input: True,
      is_single_order_output: True,
      is_datum_correct: True,
      is_account_balance_updated: True,
      is_operation_key_signed: True,
      is_withdrawal_script_validated: False,
    }
  !check_all_scripts(test_case)
}
