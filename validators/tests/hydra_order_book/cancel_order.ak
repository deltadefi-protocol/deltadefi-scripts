use cardano/address.{Script}
use cardano/assets.{from_asset, merge, zero}
use cardano/transaction.{Transaction}
use hydra_dex/types.{CancelOrder, CancelOrderIntent, UserTradeAccount}
use hydra_order_book/core as ob
use mocktail.{
  complete, mint, mock_pub_key_address, mock_tx_hash, mocktail_tx, ref_tx_in,
  ref_tx_in_inline_datum, required_signer_hash, tx_in, tx_in_inline_datum,
  tx_out, tx_out_inline_datum,
}
use tests/utils.{
  mock_account, mock_account_2, mock_dex_order_book_address,
  mock_dex_order_book_datum, mock_dex_order_book_token,
  mock_hydra_account_address, mock_hydra_lovelace, mock_hydra_order_book,
  mock_hydra_order_book_address, mock_hydra_usd, mock_hydra_user_intent_address,
  mock_hydra_user_intent_token, mock_operation_key, mock_order,
} as test_utils

type TestCase {
  is_single_intent_input: Bool,
  without_random_input: Bool,
  without_random_output: Bool,
  is_intent_token_burnt: Bool,
  is_all_cancels_same_account: Bool,
  is_all_cancels_approved: Bool,
  is_account_balance_updated: Bool,
  is_operation_key_signed: Bool,
}

fn mock_tx(test_case: TestCase) -> Transaction {
  let TestCase {
    is_single_intent_input,
    without_random_input,
    without_random_output,
    is_intent_token_burnt,
    is_all_cancels_same_account,
    is_all_cancels_approved,
    is_account_balance_updated,
    is_operation_key_signed,
  } = test_case

  let size = 250_000_000
  let list_price_times_1bil = 1_000_000_000
  let fee_amount_bp = 10

  let account = UserTradeAccount { account: mock_account }

  let intent_datum =
    CancelOrderIntent { account, order_ids: ["order_1", "order_2", "order_3"] }

  let order_1 =
    mock_order(
      if is_all_cancels_approved {
        "order_1"
      } else {
        "order_abc"
      },
      False,
      size,
      list_price_times_1bil,
      fee_amount_bp,
      if is_all_cancels_same_account {
        mock_account
      } else {
        mock_account_2
      },
    )

  let order_2 =
    mock_order(
      "order_2",
      False,
      size,
      list_price_times_1bil,
      fee_amount_bp,
      mock_account,
    )
  let order_3 =
    mock_order(
      "order_3",
      True,
      size,
      list_price_times_1bil,
      fee_amount_bp,
      mock_account,
    )

  let output_balance =
    if is_account_balance_updated {
      mock_hydra_lovelace(500_000_000) |> merge(mock_hydra_usd(250_000_000))
    } else {
      mock_hydra_lovelace(150_000_000)
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
    // - Categorize inputs into
    //    - `II` - Intent Input
    //    - `OI` - Order Inputs
    //    - Other inputs
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
        mock_hydra_lovelace(size),
        mock_hydra_order_book_address,
      )
    |> tx_in_inline_datum(True, order_1)
    |> tx_in(
        True,
        mock_tx_hash(0),
        2,
        mock_hydra_lovelace(size),
        mock_hydra_order_book_address,
      )
    |> tx_in_inline_datum(True, order_2)
    |> tx_in(
        True,
        mock_tx_hash(0),
        2,
        mock_hydra_usd(size),
        mock_hydra_order_book_address,
      )
    |> tx_in_inline_datum(True, order_3)
    // - Categorize outputs into
    //    - `AO` - Account Output with `account` at intent
    //    - Other outputs
    |> tx_out(True, mock_hydra_account_address, output_balance)
    |> tx_out_inline_datum(True, account)
    //  - The input intent token is burnt
    |> mint(is_intent_token_burnt, -1, mock_hydra_user_intent_token, "")
    //  - Signed by `operating_key`
    |> required_signer_hash(is_operation_key_signed, mock_operation_key)
    // failing cases
    |> tx_in(
        !is_single_intent_input,
        mock_tx_hash(0),
        5,
        from_asset(mock_hydra_user_intent_token, "", 1),
        mock_hydra_user_intent_address,
      )
    |> tx_in_inline_datum(!is_single_intent_input, intent_datum)
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

test s9_w_co_success() {
  let tx =
    mock_tx(
      TestCase {
        is_single_intent_input: True,
        without_random_input: True,
        without_random_output: True,
        is_intent_token_burnt: True,
        is_all_cancels_same_account: True,
        is_all_cancels_approved: True,
        is_account_balance_updated: True,
        is_operation_key_signed: True,
      },
    )
  ob.hydra_order_book.withdraw(
    mock_dex_order_book_token,
    CancelOrder,
    Script(mock_hydra_order_book),
    tx,
  )
}

test s9_w_co_fail_with_multiple_intent_input() fail {
  let tx =
    mock_tx(
      TestCase {
        is_single_intent_input: False,
        without_random_input: True,
        without_random_output: True,
        is_intent_token_burnt: True,
        is_all_cancels_same_account: True,
        is_all_cancels_approved: True,
        is_account_balance_updated: True,
        is_operation_key_signed: True,
      },
    )
  !ob.hydra_order_book.withdraw(
    mock_dex_order_book_token,
    CancelOrder,
    Script(mock_hydra_order_book),
    tx,
  )
}

test s9_w_co_fail_with_random_input() {
  let tx =
    mock_tx(
      TestCase {
        is_single_intent_input: True,
        without_random_input: False,
        without_random_output: True,
        is_intent_token_burnt: True,
        is_all_cancels_same_account: True,
        is_all_cancels_approved: True,
        is_account_balance_updated: True,
        is_operation_key_signed: True,
      },
    )
  !ob.hydra_order_book.withdraw(
    mock_dex_order_book_token,
    CancelOrder,
    Script(mock_hydra_order_book),
    tx,
  )
}

test s9_w_co_fail_with_random_output() {
  let tx =
    mock_tx(
      TestCase {
        is_single_intent_input: True,
        without_random_input: True,
        without_random_output: False,
        is_intent_token_burnt: True,
        is_all_cancels_same_account: True,
        is_all_cancels_approved: True,
        is_account_balance_updated: True,
        is_operation_key_signed: True,
      },
    )
  !ob.hydra_order_book.withdraw(
    mock_dex_order_book_token,
    CancelOrder,
    Script(mock_hydra_order_book),
    tx,
  )
}

test s9_w_co_fail_without_intent_token_burnt() {
  let tx =
    mock_tx(
      TestCase {
        is_single_intent_input: True,
        without_random_input: True,
        without_random_output: True,
        is_intent_token_burnt: False,
        is_all_cancels_same_account: True,
        is_all_cancels_approved: True,
        is_account_balance_updated: True,
        is_operation_key_signed: True,
      },
    )
  !ob.hydra_order_book.withdraw(
    mock_dex_order_book_token,
    CancelOrder,
    Script(mock_hydra_order_book),
    tx,
  )
}

test s9_w_co_fail_with_mixed_accounts() {
  let tx =
    mock_tx(
      TestCase {
        is_single_intent_input: True,
        is_intent_token_burnt: True,
        without_random_input: True,
        without_random_output: True,
        is_all_cancels_same_account: False,
        is_all_cancels_approved: True,
        is_account_balance_updated: True,
        is_operation_key_signed: True,
      },
    )
  !ob.hydra_order_book.withdraw(
    mock_dex_order_book_token,
    CancelOrder,
    Script(mock_hydra_order_book),
    tx,
  )
}

test s9_w_co_fail_without_all_cancels_approved() {
  let tx =
    mock_tx(
      TestCase {
        is_single_intent_input: True,
        is_intent_token_burnt: True,
        without_random_input: True,
        without_random_output: True,
        is_all_cancels_same_account: True,
        is_all_cancels_approved: False,
        is_account_balance_updated: True,
        is_operation_key_signed: True,
      },
    )
  !ob.hydra_order_book.withdraw(
    mock_dex_order_book_token,
    CancelOrder,
    Script(mock_hydra_order_book),
    tx,
  )
}

test s9_w_co_fail_without_balance_updated() {
  let tx =
    mock_tx(
      TestCase {
        is_single_intent_input: True,
        without_random_input: True,
        without_random_output: True,
        is_intent_token_burnt: True,
        is_all_cancels_same_account: True,
        is_all_cancels_approved: True,
        is_account_balance_updated: False,
        is_operation_key_signed: True,
      },
    )
  !ob.hydra_order_book.withdraw(
    mock_dex_order_book_token,
    CancelOrder,
    Script(mock_hydra_order_book),
    tx,
  )
}

test s9_w_co_fail_without_operation_key_signed() {
  let tx =
    mock_tx(
      TestCase {
        is_single_intent_input: True,
        without_random_input: True,
        without_random_output: True,
        is_intent_token_burnt: True,
        is_all_cancels_same_account: True,
        is_all_cancels_approved: True,
        is_account_balance_updated: True,
        is_operation_key_signed: False,
      },
    )
  !ob.hydra_order_book.withdraw(
    mock_dex_order_book_token,
    CancelOrder,
    Script(mock_hydra_order_book),
    tx,
  )
}
