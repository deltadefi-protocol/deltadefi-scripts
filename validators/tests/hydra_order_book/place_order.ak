use cardano/address.{Script}
use cardano/assets.{from_asset, zero}
use cardano/transaction.{Transaction}
use hydra_dex/types.{PlaceOrder}
use hydra_order_book/core as ob
use mocktail.{
  complete, mint, mock_pub_key_address, mock_tx_hash, mocktail_tx, ref_tx_in,
  ref_tx_in_inline_datum, required_signer_hash, tx_in, tx_in_inline_datum,
  tx_out, tx_out_inline_datum,
}
use tests/utils.{
  mock_account, mock_dex_order_book_address, mock_dex_order_book_datum,
  mock_dex_order_book_token, mock_hydra_account_address, mock_hydra_lovelace,
  mock_hydra_order_book, mock_hydra_order_book_address,
  mock_hydra_user_intent_address, mock_hydra_user_intent_token, mock_limit_order,
  mock_operation_key, mock_order_id, mock_order_intent, mock_user_account,
} as test_utils

type TestCase {
  is_single_intent_input: Bool,
  is_single_order_output: Bool,
  without_random_input: Bool,
  without_random_output: Bool,
  is_intent_token_burnt: Bool,
  is_datum_correct: Bool,
  is_account_balance_updated: Bool,
  is_operation_key_signed: Bool,
  no_account_output_case: Bool,
}

fn mock_tx(test_case: TestCase) -> Transaction {
  let TestCase {
    is_single_intent_input,
    is_single_order_output,
    without_random_input,
    without_random_output,
    is_intent_token_burnt,
    is_datum_correct,
    is_account_balance_updated,
    is_operation_key_signed,
    no_account_output_case,
  } = test_case

  let account = mock_user_account(mock_account)

  let is_buy = False
  let size =
    if no_account_output_case {
      500_000_000
    } else {
      250_000_000
    }
  let list_price_times_1tri = 1_350_000_000_000
  let fee_amount_bp = 10

  let intent_datum =
    mock_order_intent(
      is_buy,
      size,
      list_price_times_1tri,
      fee_amount_bp,
      mock_hydra_lovelace(size),
    )
  let order_datum =
    if is_datum_correct {
      mock_limit_order(
        mock_order_id,
        is_buy,
        size,
        list_price_times_1tri,
        fee_amount_bp,
        mock_account,
      )
    } else {
      mock_limit_order(
        mock_order_id,
        is_buy,
        123_456_789,
        list_price_times_1tri,
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
        mock_tx_hash(1),
        0,
        mock_hydra_lovelace(200_000_000),
        mock_hydra_account_address,
      )
    |> tx_in_inline_datum(True, account)
    |> tx_in(
        True,
        mock_tx_hash(1),
        1,
        mock_hydra_lovelace(200_000_000),
        mock_hydra_account_address,
      )
    |> tx_in_inline_datum(True, account)
    |> tx_in(
        True,
        mock_tx_hash(1),
        2,
        mock_hydra_lovelace(100_000_000),
        mock_hydra_account_address,
      )
    |> tx_in_inline_datum(True, account)
    //  - Categorize outputs into
    //    - `AO` - Account Output with `account` at intent
    //    - `OO` - Order Output with `account` at intent
    //    - Other outputs
    |> tx_out(
        !no_account_output_case,
        mock_hydra_account_address,
        output_balance,
      )
    |> tx_out_inline_datum(!no_account_output_case, account)
    |> tx_out(True, mock_hydra_order_book_address, mock_hydra_lovelace(size))
    |> tx_out_inline_datum(True, order_datum)
    // - The input token is burnt
    |> mint(is_intent_token_burnt, -1, mock_hydra_user_intent_token, "")
    // - Signed by `operating_key` 
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
        mock_hydra_lovelace(250_000_000),
      )
    |> tx_out_inline_datum(!is_single_order_output, order_datum)
    |> tx_in(
        !without_random_input,
        mock_tx_hash(2),
        0,
        zero,
        mock_pub_key_address(10, None),
      )
    |> tx_out(!without_random_output, mock_pub_key_address(10, None), zero)
    |> complete()
}

test s9_wpo_success() {
  let tx =
    mock_tx(
      TestCase {
        is_single_intent_input: True,
        is_single_order_output: True,
        without_random_input: True,
        without_random_output: True,
        is_intent_token_burnt: True,
        is_datum_correct: True,
        is_account_balance_updated: True,
        is_operation_key_signed: True,
        no_account_output_case: False,
      },
    )
  ob.hydra_order_book.withdraw(
    mock_dex_order_book_token,
    PlaceOrder { account: mock_user_account(mock_account) },
    Script(mock_hydra_order_book),
    tx,
  )
}

test s9_wpo_success_no_account_output_case() {
  let tx =
    mock_tx(
      TestCase {
        is_single_intent_input: True,
        is_single_order_output: True,
        without_random_input: True,
        without_random_output: True,
        is_intent_token_burnt: True,
        is_datum_correct: True,
        is_account_balance_updated: True,
        is_operation_key_signed: True,
        no_account_output_case: True,
      },
    )
  ob.hydra_order_book.withdraw(
    mock_dex_order_book_token,
    PlaceOrder { account: mock_user_account(mock_account) },
    Script(mock_hydra_order_book),
    tx,
  )
}

test s9_wpo_fail_with_multiple_intent_input() fail {
  let tx =
    mock_tx(
      TestCase {
        is_single_intent_input: False,
        is_single_order_output: True,
        without_random_input: True,
        without_random_output: True,
        is_intent_token_burnt: True,
        is_datum_correct: True,
        is_account_balance_updated: True,
        is_operation_key_signed: True,
        no_account_output_case: False,
      },
    )
  ob.hydra_order_book.withdraw(
    mock_dex_order_book_token,
    PlaceOrder { account: mock_user_account(mock_account) },
    Script(mock_hydra_order_book),
    tx,
  )
}

test s9_wpo_fail_with_multiple_order_output() fail {
  let tx =
    mock_tx(
      TestCase {
        is_single_intent_input: True,
        is_single_order_output: False,
        without_random_input: True,
        without_random_output: True,
        is_intent_token_burnt: True,
        is_datum_correct: True,
        is_account_balance_updated: True,
        is_operation_key_signed: True,
        no_account_output_case: False,
      },
    )
  ob.hydra_order_book.withdraw(
    mock_dex_order_book_token,
    PlaceOrder { account: mock_user_account(mock_account) },
    Script(mock_hydra_order_book),
    tx,
  )
}

test s9_wpo_fail_with_random_input() {
  let tx =
    mock_tx(
      TestCase {
        is_single_intent_input: True,
        is_single_order_output: True,
        without_random_input: False,
        without_random_output: True,
        is_intent_token_burnt: True,
        is_datum_correct: True,
        is_account_balance_updated: True,
        is_operation_key_signed: True,
        no_account_output_case: False,
      },
    )
  !ob.hydra_order_book.withdraw(
    mock_dex_order_book_token,
    PlaceOrder { account: mock_user_account(mock_account) },
    Script(mock_hydra_order_book),
    tx,
  )
}

test s9_wpo_fail_with_random_output() {
  let tx =
    mock_tx(
      TestCase {
        is_single_intent_input: True,
        is_single_order_output: True,
        without_random_input: True,
        without_random_output: False,
        is_intent_token_burnt: True,
        is_datum_correct: True,
        is_account_balance_updated: True,
        is_operation_key_signed: True,
        no_account_output_case: False,
      },
    )
  !ob.hydra_order_book.withdraw(
    mock_dex_order_book_token,
    PlaceOrder { account: mock_user_account(mock_account) },
    Script(mock_hydra_order_book),
    tx,
  )
}

test s9_wpo_fail_without_intent_token_burnt() {
  let tx =
    mock_tx(
      TestCase {
        is_single_intent_input: True,
        is_single_order_output: True,
        without_random_input: True,
        without_random_output: True,
        is_intent_token_burnt: False,
        is_datum_correct: True,
        is_account_balance_updated: True,
        is_operation_key_signed: True,
        no_account_output_case: False,
      },
    )
  !ob.hydra_order_book.withdraw(
    mock_dex_order_book_token,
    PlaceOrder { account: mock_user_account(mock_account) },
    Script(mock_hydra_order_book),
    tx,
  )
}

test s9_wpo_fail_with_incorrect_datum() {
  let tx =
    mock_tx(
      TestCase {
        is_single_intent_input: True,
        is_single_order_output: True,
        without_random_input: True,
        without_random_output: True,
        is_intent_token_burnt: True,
        is_datum_correct: False,
        is_account_balance_updated: True,
        is_operation_key_signed: True,
        no_account_output_case: False,
      },
    )
  !ob.hydra_order_book.withdraw(
    mock_dex_order_book_token,
    PlaceOrder { account: mock_user_account(mock_account) },
    Script(mock_hydra_order_book),
    tx,
  )
}

test s9_wpo_fail_without_balance_updated() {
  let tx =
    mock_tx(
      TestCase {
        is_single_intent_input: True,
        is_single_order_output: True,
        without_random_input: True,
        without_random_output: True,
        is_intent_token_burnt: True,
        is_datum_correct: True,
        is_account_balance_updated: False,
        is_operation_key_signed: True,
        no_account_output_case: False,
      },
    )
  !ob.hydra_order_book.withdraw(
    mock_dex_order_book_token,
    PlaceOrder { account: mock_user_account(mock_account) },
    Script(mock_hydra_order_book),
    tx,
  )
}

test s9_wpo_fail_without_operation_key_signed() {
  let tx =
    mock_tx(
      TestCase {
        is_single_intent_input: True,
        is_single_order_output: True,
        without_random_input: True,
        without_random_output: True,
        is_intent_token_burnt: True,
        is_datum_correct: True,
        is_account_balance_updated: True,
        is_operation_key_signed: False,
        no_account_output_case: False,
      },
    )
  !ob.hydra_order_book.withdraw(
    mock_dex_order_book_token,
    PlaceOrder { account: mock_user_account(mock_account) },
    Script(mock_hydra_order_book),
    tx,
  )
}
