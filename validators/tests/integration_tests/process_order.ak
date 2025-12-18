use cardano/address.{Script}
use cardano/assets.{from_asset}
use cardano/transaction.{Transaction}
use hydra_account/core as ha
use hydra_dex/types.{
  BurnIntent, HydraAccountTrade, HydraUserIntentDatum, PlaceOrder,
}
use hydra_order_book/core as ob
use hydra_user_intent as hui
use mocktail.{
  complete, mint, mock_tx_hash, mock_utxo_ref, mocktail_tx, ref_tx_in,
  ref_tx_in_inline_datum, required_signer_hash, script_withdrawal, tx_in,
  tx_in_inline_datum, tx_out, tx_out_inline_datum, withdrawal_redeemer_value,
}
use tests/utils.{
  mock_account, mock_dex_order_book_address, mock_dex_order_book_datum,
  mock_dex_order_book_token, mock_hydra_account_address, mock_hydra_lovelace,
  mock_hydra_order_book, mock_hydra_order_book_address,
  mock_hydra_user_intent_address, mock_hydra_user_intent_token, mock_limit_order,
  mock_operation_key, mock_order_id, mock_order_intent, mock_user_account,
}

type TestCase {
  is_single_intent_input: Bool,
  is_single_order_output: Bool,
  is_intent_token_burnt: Bool,
  is_datum_correct: Bool,
  is_account_balance_updated: Bool,
  is_operation_key_signed: Bool,
  is_withdrawal_script_attached: Bool,
}

fn mock_tx(test_case: TestCase) -> (Transaction, HydraUserIntentDatum) {
  let TestCase {
    is_single_intent_input,
    is_single_order_output,
    is_intent_token_burnt,
    is_datum_correct,
    is_account_balance_updated,
    is_operation_key_signed,
    is_withdrawal_script_attached,
  } = test_case

  let account = mock_user_account(mock_account)

  let is_buy = False
  let size = 250_000_000
  let list_price_times_1bil = 1_350_000_000
  let fee_amount_bp = 10

  let intent_datum =
    mock_order_intent(
      is_buy,
      size,
      list_price_times_1bil,
      fee_amount_bp,
      mock_hydra_lovelace(size),
    )
  let order_datum =
    if is_datum_correct {
      mock_limit_order(
        mock_order_id,
        is_buy,
        size,
        list_price_times_1bil,
        fee_amount_bp,
        mock_account,
      )
    } else {
      mock_limit_order(
        mock_order_id,
        is_buy,
        123_456_789,
        list_price_times_1bil,
        fee_amount_bp,
        mock_account,
      )
    }

  let output_balance =
    if is_account_balance_updated {
      mock_hydra_lovelace(250_000_000)
    } else {
      mock_hydra_lovelace(500_000_000)
    }

  let tx =
    mocktail_tx()
      //  - Ref input with `dex_oracle_nft`
      |> ref_tx_in(
          True,
          mock_tx_hash(0),
          0,
          from_asset(mock_dex_order_book_token, "", 1),
          mock_dex_order_book_address,
        )
      |> ref_tx_in_inline_datum(True, mock_dex_order_book_datum)
      //  - Categorize inputs into
      //    - `AI` - Account Inputs with `account` at intent
      //    - `II` - Intent Input
      |> tx_in(
          True,
          mock_tx_hash(0),
          1,
          from_asset(mock_hydra_user_intent_token, "", 1),
          mock_hydra_user_intent_address,
        )
      |> tx_in_inline_datum(True, intent_datum)
      |> tx_in(
          True,
          mock_tx_hash(0),
          2,
          mock_hydra_lovelace(200_000_000),
          mock_hydra_account_address,
        )
      |> tx_in_inline_datum(True, account)
      |> tx_in(
          True,
          mock_tx_hash(0),
          2,
          mock_hydra_lovelace(200_000_000),
          mock_hydra_account_address,
        )
      |> tx_in_inline_datum(True, account)
      |> tx_in(
          True,
          mock_tx_hash(0),
          2,
          mock_hydra_lovelace(100_000_000),
          mock_hydra_account_address,
        )
      |> tx_in_inline_datum(True, account)
      //  - Categorize outputs into
      //    - `AO` - Account Output with `account` at intent
      //    - `OO` - Order Output with `account` at intent
      //    - Other outputs
      |> tx_out(True, mock_hydra_order_book_address, mock_hydra_lovelace(size))
      |> tx_out_inline_datum(True, order_datum)
      |> tx_out(True, mock_hydra_account_address, output_balance)
      |> tx_out_inline_datum(True, account)
      // - The input token is burnt
      |> mint(is_intent_token_burnt, -1, mock_hydra_user_intent_token, "")
      // - Signed by `operating_key` 
      |> required_signer_hash(is_operation_key_signed, mock_operation_key)
      |> script_withdrawal(
          is_withdrawal_script_attached,
          mock_hydra_order_book,
          0,
        )
      |> withdrawal_redeemer_value(
          is_withdrawal_script_attached,
          PlaceOrder { account },
        )
      // failing cases
      |> tx_in(
          !is_single_intent_input,
          mock_tx_hash(0),
          1,
          from_asset(mock_hydra_user_intent_token, "", 1),
          mock_hydra_user_intent_address,
        )
      |> tx_in_inline_datum(!is_single_intent_input, intent_datum)
      |> tx_out(
          !is_single_order_output,
          mock_hydra_order_book_address,
          mock_hydra_lovelace(size),
        )
      |> tx_out_inline_datum(!is_single_order_output, order_datum)
      |> complete()
  (tx, intent_datum)
}

fn check_all_scripts(test_case: TestCase) {
  let (tx, intent_datum) = mock_tx(test_case)
  let account = mock_user_account(mock_account)

  let check_withdraw =
    ob.hydra_order_book.withdraw(
      mock_dex_order_book_token,
      PlaceOrder { account },
      Script(mock_hydra_order_book),
      tx,
    )
  let check_intent_spend =
    hui.hydra_user_intent.spend(
      mock_dex_order_book_token,
      Some(intent_datum),
      Void,
      mock_utxo_ref(0, 1),
      tx,
    )
  let check_intent_mint =
    hui.hydra_user_intent.mint(
      mock_dex_order_book_token,
      BurnIntent,
      mock_hydra_user_intent_token,
      tx,
    )
  let check_hydra_balance =
    ha.hydra_account.spend(
      mock_dex_order_book_token,
      Some(account),
      HydraAccountTrade { trade_redeemer: PlaceOrder { account } },
      mock_utxo_ref(0, 2),
      tx,
    )

  check_withdraw? && check_intent_spend? && check_intent_mint? && check_hydra_balance?
}

test it_hpo_success() {
  let test_case =
    TestCase {
      is_single_intent_input: True,
      is_single_order_output: True,
      is_intent_token_burnt: True,
      is_datum_correct: True,
      is_account_balance_updated: True,
      is_operation_key_signed: True,
      is_withdrawal_script_attached: True,
    }
  check_all_scripts(test_case)
}

test it_hpo_fail_with_multiple_intent_input() fail {
  let test_case =
    TestCase {
      is_single_intent_input: False,
      is_single_order_output: True,
      is_intent_token_burnt: True,
      is_datum_correct: True,
      is_account_balance_updated: True,
      is_operation_key_signed: True,
      is_withdrawal_script_attached: True,
    }
  check_all_scripts(test_case)
}

test it_hpo_fail_with_multiple_order_output() fail {
  let test_case =
    TestCase {
      is_single_intent_input: True,
      is_single_order_output: False,
      is_intent_token_burnt: True,
      is_datum_correct: True,
      is_account_balance_updated: True,
      is_operation_key_signed: True,
      is_withdrawal_script_attached: True,
    }
  check_all_scripts(test_case)
}

test it_hpo_fail_without_intent_token_burnt() {
  let test_case =
    TestCase {
      is_single_intent_input: True,
      is_single_order_output: True,
      is_intent_token_burnt: False,
      is_datum_correct: True,
      is_account_balance_updated: True,
      is_operation_key_signed: True,
      is_withdrawal_script_attached: True,
    }
  !check_all_scripts(test_case)
}

test it_hpo_fail_with_incorrect_datum() {
  let test_case =
    TestCase {
      is_single_intent_input: True,
      is_single_order_output: True,
      is_intent_token_burnt: True,
      is_datum_correct: False,
      is_account_balance_updated: True,
      is_operation_key_signed: True,
      is_withdrawal_script_attached: True,
    }
  !check_all_scripts(test_case)
}

test it_hpo_fail_without_balance_updated() {
  let test_case =
    TestCase {
      is_single_intent_input: True,
      is_single_order_output: True,
      is_intent_token_burnt: True,
      is_datum_correct: True,
      is_account_balance_updated: False,
      is_operation_key_signed: True,
      is_withdrawal_script_attached: True,
    }
  !check_all_scripts(test_case)
}

test it_hpo_fail_without_operation_key_signed() {
  let test_case =
    TestCase {
      is_single_intent_input: True,
      is_single_order_output: True,
      is_intent_token_burnt: True,
      is_datum_correct: True,
      is_account_balance_updated: True,
      is_operation_key_signed: False,
      is_withdrawal_script_attached: True,
    }
  !check_all_scripts(test_case)
}

test it_hpo_fail_without_withdrawal_script() fail {
  let test_case =
    TestCase {
      is_single_intent_input: True,
      is_single_order_output: True,
      is_intent_token_burnt: True,
      is_datum_correct: True,
      is_account_balance_updated: True,
      is_operation_key_signed: True,
      is_withdrawal_script_attached: False,
    }
  check_all_scripts(test_case)
}
