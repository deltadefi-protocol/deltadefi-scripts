use cardano/address.{Script}
use cardano/assets.{from_asset, from_lovelace}
use cardano/transaction.{Transaction}
use hydra_account_balance/spend as hydra_account_balance
use hydra_dex/types.{
  HydraAccountBalanceDatum, HydraUserIntentDatum, HydraUserPlaceOrder,
  PlaceOrder, UpdateBalanceWithPlaceOrder, UserSpotAccount,
}
use hydra_order_book/mint as ob_mint
use hydra_order_book/place_order
use hydra_user_intent/mint as intent_mint
use hydra_user_intent/spend as intent_spend
use mocktail.{
  complete, mint, mock_tx_hash, mock_utxo_ref, mocktail_tx, ref_tx_in,
  ref_tx_in_inline_datum, required_signer_hash, script_withdrawal, tx_in,
  tx_in_inline_datum, tx_out, tx_out_inline_datum,
}
use tests/utils.{
  mock_account, mock_dex_order_book_address, mock_dex_order_book_datum,
  mock_dex_order_book_token, mock_hydra_account_balance_address,
  mock_hydra_account_balance_token, mock_hydra_order_book_address,
  mock_hydra_order_book_token, mock_hydra_place_order,
  mock_hydra_user_intent_address, mock_hydra_user_intent_token,
  mock_operation_key, mock_order, mock_order_id, mock_order_intent, to_mvalue,
}

type TestCase {
  is_single_intent_input: Bool,
  is_single_order_output: Bool,
  is_order_token_minted: Bool,
  is_intent_token_burnt: Bool,
  is_datum_correct: Bool,
  is_account_balance_updated: Bool,
  is_operation_key_signed: Bool,
  is_withdrawal_script_attached: Bool,
}

fn mock_tx(
  test_case: TestCase,
) -> (Transaction, HydraUserIntentDatum, HydraAccountBalanceDatum) {
  let TestCase {
    is_single_intent_input,
    is_single_order_output,
    is_order_token_minted,
    is_intent_token_burnt,
    is_datum_correct,
    is_account_balance_updated,
    is_operation_key_signed,
    is_withdrawal_script_attached,
  } = test_case

  let is_long = False
  let order_size = 250_000_000
  let list_price_times_1bil = 1_350_000_000
  let fee_amount_bp = 10
  let extra_value = 0

  let intent_datum =
    mock_order_intent(
      is_long,
      order_size,
      list_price_times_1bil,
      fee_amount_bp,
      extra_value,
    )
  let order_datum =
    if is_datum_correct {
      mock_order(
        mock_order_id,
        is_long,
        order_size,
        list_price_times_1bil,
        fee_amount_bp,
        extra_value,
        mock_account,
      )
    } else {
      mock_order(
        mock_order_id,
        is_long,
        123_456_789,
        list_price_times_1bil,
        fee_amount_bp,
        extra_value,
        mock_account,
      )
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
        balance: from_lovelace(250_000_000) |> to_mvalue(),
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
          from_asset(mock_hydra_user_intent_token, "", 1),
          mock_hydra_user_intent_address,
        )
      |> tx_in_inline_datum(True, intent_datum)
      |> tx_out(
          True,
          mock_hydra_order_book_address,
          from_asset(mock_hydra_order_book_token, mock_order_id, 1),
        )
      |> tx_out_inline_datum(True, order_datum)
      |> mint(
          is_order_token_minted,
          1,
          mock_hydra_order_book_token,
          mock_order_id,
        )
      |> mint(is_intent_token_burnt, -1, mock_hydra_user_intent_token, "")
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
          is_withdrawal_script_attached,
          mock_hydra_place_order,
          0,
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
          from_asset(mock_hydra_order_book_token, mock_order_id, 1),
        )
      |> tx_out_inline_datum(!is_single_order_output, order_datum)
      |> complete()
  (tx, intent_datum, input_balance)
}

fn check_all_scripts(test_case: TestCase) {
  let (tx, intent_datum, input_balance) = mock_tx(test_case)

  let check_withdraw =
    place_order.place_order.withdraw(
      mock_dex_order_book_token,
      Void,
      Script(mock_hydra_place_order),
      tx,
    )
  let check_ob_mint =
    ob_mint.hydra_order_book.mint(
      mock_dex_order_book_token,
      PlaceOrder,
      mock_hydra_order_book_token,
      tx,
    )
  let check_intent_spend =
    intent_spend.hydra_user_intent.spend(
      mock_dex_order_book_token,
      Some(intent_datum),
      Void,
      mock_utxo_ref(0, 1),
      tx,
    )
  let check_intent_mint =
    intent_mint.hydra_user_intent.mint(
      mock_dex_order_book_token,
      HydraUserPlaceOrder,
      mock_hydra_user_intent_token,
      tx,
    )
  let check_hydra_balance =
    hydra_account_balance.hydra_account_balance.spend(
      mock_dex_order_book_token,
      Some(input_balance),
      UpdateBalanceWithPlaceOrder,
      mock_utxo_ref(0, 2),
      tx,
    )

  check_withdraw? && check_ob_mint? && check_intent_spend? && check_intent_mint? && check_hydra_balance?
}

test it_hpro_success() {
  let test_case =
    TestCase {
      is_single_intent_input: True,
      is_single_order_output: True,
      is_order_token_minted: True,
      is_intent_token_burnt: True,
      is_datum_correct: True,
      is_account_balance_updated: True,
      is_operation_key_signed: True,
      is_withdrawal_script_attached: True,
    }
  check_all_scripts(test_case)
}

test it_hpro_fail_with_multiple_intent_input() {
  let test_case =
    TestCase {
      is_single_intent_input: False,
      is_single_order_output: True,
      is_order_token_minted: True,
      is_intent_token_burnt: True,
      is_datum_correct: True,
      is_account_balance_updated: True,
      is_operation_key_signed: True,
      is_withdrawal_script_attached: True,
    }
  !check_all_scripts(test_case)
}

test it_hpro_fail_with_multiple_order_output() {
  let test_case =
    TestCase {
      is_single_intent_input: True,
      is_single_order_output: False,
      is_order_token_minted: True,
      is_intent_token_burnt: True,
      is_datum_correct: True,
      is_account_balance_updated: True,
      is_operation_key_signed: True,
      is_withdrawal_script_attached: True,
    }
  !check_all_scripts(test_case)
}

test it_hpro_fail_without_order_token_minted() {
  let test_case =
    TestCase {
      is_single_intent_input: True,
      is_single_order_output: True,
      is_order_token_minted: False,
      is_intent_token_burnt: True,
      is_datum_correct: True,
      is_account_balance_updated: True,
      is_operation_key_signed: True,
      is_withdrawal_script_attached: True,
    }
  !check_all_scripts(test_case)
}

test it_hpro_fail_without_intent_token_burnt() {
  let test_case =
    TestCase {
      is_single_intent_input: True,
      is_single_order_output: True,
      is_order_token_minted: True,
      is_intent_token_burnt: False,
      is_datum_correct: True,
      is_account_balance_updated: True,
      is_operation_key_signed: True,
      is_withdrawal_script_attached: True,
    }
  !check_all_scripts(test_case)
}

test it_hpro_fail_with_incorrect_datum() {
  let test_case =
    TestCase {
      is_single_intent_input: True,
      is_single_order_output: True,
      is_order_token_minted: True,
      is_intent_token_burnt: True,
      is_datum_correct: False,
      is_account_balance_updated: True,
      is_operation_key_signed: True,
      is_withdrawal_script_attached: True,
    }
  !check_all_scripts(test_case)
}

test it_hpro_fail_without_balance_updated() {
  let test_case =
    TestCase {
      is_single_intent_input: True,
      is_single_order_output: True,
      is_order_token_minted: True,
      is_intent_token_burnt: True,
      is_datum_correct: True,
      is_account_balance_updated: False,
      is_operation_key_signed: True,
      is_withdrawal_script_attached: True,
    }
  !check_all_scripts(test_case)
}

test it_hpro_fail_without_operation_key_signed() {
  let test_case =
    TestCase {
      is_single_intent_input: True,
      is_single_order_output: True,
      is_order_token_minted: True,
      is_intent_token_burnt: True,
      is_datum_correct: True,
      is_account_balance_updated: True,
      is_operation_key_signed: False,
      is_withdrawal_script_attached: True,
    }
  !check_all_scripts(test_case)
}

test it_hpro_fail_without_withdrawal_script() {
  let test_case =
    TestCase {
      is_single_intent_input: True,
      is_single_order_output: True,
      is_order_token_minted: True,
      is_intent_token_burnt: True,
      is_datum_correct: True,
      is_account_balance_updated: True,
      is_operation_key_signed: True,
      is_withdrawal_script_attached: False,
    }
  !check_all_scripts(test_case)
}
