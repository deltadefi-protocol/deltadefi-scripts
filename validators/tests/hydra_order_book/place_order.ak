use cardano/address.{Script}
use cardano/assets.{from_asset, from_lovelace}
use cardano/transaction.{Transaction}
use hydra_dex/types.{HydraAccountBalanceDatum, UserSpotAccount}
use hydra_order_book/place_order
use mocktail.{
  complete, mint, mock_tx_hash, mocktail_tx, ref_tx_in, ref_tx_in_inline_datum,
  required_signer_hash, tx_in, tx_in_inline_datum, tx_out, tx_out_inline_datum,
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
}

fn mock_tx(test_case: TestCase) -> Transaction {
  let TestCase {
    is_single_intent_input,
    is_single_order_output,
    is_order_token_minted,
    is_intent_token_burnt,
    is_datum_correct,
    is_account_balance_updated,
    is_operation_key_signed,
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
}

test s9_wpo_success() {
  let tx =
    mock_tx(
      TestCase {
        is_single_intent_input: True,
        is_single_order_output: True,
        is_order_token_minted: True,
        is_intent_token_burnt: True,
        is_datum_correct: True,
        is_account_balance_updated: True,
        is_operation_key_signed: True,
      },
    )
  place_order.place_order.withdraw(
    mock_dex_order_book_token,
    Void,
    Script(mock_hydra_place_order),
    tx,
  )
}

test s9_wpo_fail_with_multiple_intent_input() {
  let tx =
    mock_tx(
      TestCase {
        is_single_intent_input: False,
        is_single_order_output: True,
        is_order_token_minted: True,
        is_intent_token_burnt: True,
        is_datum_correct: True,
        is_account_balance_updated: True,
        is_operation_key_signed: True,
      },
    )
  !place_order.place_order.withdraw(
    mock_dex_order_book_token,
    Void,
    Script(mock_hydra_place_order),
    tx,
  )
}

test s9_wpo_fail_with_multiple_order_output() {
  let tx =
    mock_tx(
      TestCase {
        is_single_intent_input: True,
        is_single_order_output: False,
        is_order_token_minted: True,
        is_intent_token_burnt: True,
        is_datum_correct: True,
        is_account_balance_updated: True,
        is_operation_key_signed: True,
      },
    )
  !place_order.place_order.withdraw(
    mock_dex_order_book_token,
    Void,
    Script(mock_hydra_place_order),
    tx,
  )
}

test s9_wpo_fail_without_order_token_minted() {
  let tx =
    mock_tx(
      TestCase {
        is_single_intent_input: True,
        is_single_order_output: True,
        is_order_token_minted: False,
        is_intent_token_burnt: True,
        is_datum_correct: True,
        is_account_balance_updated: True,
        is_operation_key_signed: True,
      },
    )
  !place_order.place_order.withdraw(
    mock_dex_order_book_token,
    Void,
    Script(mock_hydra_place_order),
    tx,
  )
}

test s9_wpo_fail_without_intent_token_burnt() {
  let tx =
    mock_tx(
      TestCase {
        is_single_intent_input: True,
        is_single_order_output: True,
        is_order_token_minted: True,
        is_intent_token_burnt: False,
        is_datum_correct: True,
        is_account_balance_updated: True,
        is_operation_key_signed: True,
      },
    )
  !place_order.place_order.withdraw(
    mock_dex_order_book_token,
    Void,
    Script(mock_hydra_place_order),
    tx,
  )
}

test s9_wpo_fail_with_incorrect_datum() {
  let tx =
    mock_tx(
      TestCase {
        is_single_intent_input: True,
        is_single_order_output: True,
        is_order_token_minted: True,
        is_intent_token_burnt: True,
        is_datum_correct: False,
        is_account_balance_updated: True,
        is_operation_key_signed: True,
      },
    )
  !place_order.place_order.withdraw(
    mock_dex_order_book_token,
    Void,
    Script(mock_hydra_place_order),
    tx,
  )
}

test s9_wpo_fail_without_balance_updated() {
  let tx =
    mock_tx(
      TestCase {
        is_single_intent_input: True,
        is_single_order_output: True,
        is_order_token_minted: True,
        is_intent_token_burnt: True,
        is_datum_correct: True,
        is_account_balance_updated: False,
        is_operation_key_signed: True,
      },
    )
  !place_order.place_order.withdraw(
    mock_dex_order_book_token,
    Void,
    Script(mock_hydra_place_order),
    tx,
  )
}

test s9_wpo_fail_without_operation_key_signed() {
  let tx =
    mock_tx(
      TestCase {
        is_single_intent_input: True,
        is_single_order_output: True,
        is_order_token_minted: True,
        is_intent_token_burnt: True,
        is_datum_correct: True,
        is_account_balance_updated: True,
        is_operation_key_signed: False,
      },
    )
  !place_order.place_order.withdraw(
    mock_dex_order_book_token,
    Void,
    Script(mock_hydra_place_order),
    tx,
  )
}
