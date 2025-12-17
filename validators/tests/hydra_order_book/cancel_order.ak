use cardano/address.{Script}
use cardano/assets.{from_asset, merge, zero}
use cardano/transaction.{Transaction}
use hydra_dex/types.{CancelOrder}
use hydra_order_book/core as ob
use mocktail.{
  complete, mock_pub_key_address, mock_tx_hash, mocktail_tx, ref_tx_in,
  ref_tx_in_inline_datum, required_signer_hash, tx_in, tx_in_inline_datum,
  tx_out, tx_out_inline_datum,
}
use tests/utils.{
  mock_account, mock_account_2, mock_account_3, mock_dex_order_book_address,
  mock_dex_order_book_datum, mock_dex_order_book_token,
  mock_hydra_account_address, mock_hydra_lovelace, mock_hydra_order_book,
  mock_hydra_order_book_address, mock_hydra_usd, mock_limit_order,
  mock_operation_key, mock_user_account,
} as test_utils

type TestCase {
  without_random_input: Bool,
  without_random_output: Bool,
  is_all_cancels_same_account: Bool,
  is_account_balance_settlement_correct: Bool,
  is_operation_key_signed: Bool,
}

fn mock_tx(test_case: TestCase) -> Transaction {
  let TestCase {
    without_random_input,
    without_random_output,
    is_all_cancels_same_account,
    is_account_balance_settlement_correct,
    is_operation_key_signed,
  } = test_case

  let size = 250_000_000
  let list_price_times_1bil = 1_000_000_000
  let fee_amount_bp = 10

  let account = mock_user_account(mock_account)
  let account_3 = mock_user_account(mock_account_3)

  let order_1 =
    mock_limit_order(
      "order_1",
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
    mock_limit_order(
      "order_2",
      False,
      size,
      list_price_times_1bil,
      fee_amount_bp,
      mock_account,
    )
  let order_3 =
    mock_limit_order(
      "order_3",
      True,
      size,
      list_price_times_1bil,
      fee_amount_bp,
      mock_account_3,
    )

  let (a1_output_balance, a3_output_balance) =
    if is_account_balance_settlement_correct {
      (mock_hydra_lovelace(500_000_000), mock_hydra_usd(250_000_000))
    } else {
      (
        mock_hydra_lovelace(250_000_000),
        mock_hydra_usd(250_000_000) |> merge(mock_hydra_lovelace(250_000_000)),
      )
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
    //    - `OI` - Order Inputs
    //    - Other inputs
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
    //    - `AO` - Account Outputs
    //    - Other outputs
    |> tx_out(True, mock_hydra_account_address, a1_output_balance)
    |> tx_out_inline_datum(True, account)
    |> tx_out(True, mock_hydra_account_address, a3_output_balance)
    |> tx_out_inline_datum(True, account_3)
    //  - Signed by `operating_key`
    |> required_signer_hash(is_operation_key_signed, mock_operation_key)
    // failing cases
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

test s9_wco_success() {
  let tx =
    mock_tx(
      TestCase {
        without_random_input: True,
        without_random_output: True,
        is_all_cancels_same_account: True,
        is_account_balance_settlement_correct: True,
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

test s9_wco_fail_with_random_input() {
  let tx =
    mock_tx(
      TestCase {
        without_random_input: False,
        without_random_output: True,
        is_all_cancels_same_account: True,
        is_account_balance_settlement_correct: True,
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

test s9_wco_fail_with_random_output() {
  let tx =
    mock_tx(
      TestCase {
        without_random_input: True,
        without_random_output: False,
        is_all_cancels_same_account: True,
        is_account_balance_settlement_correct: True,
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

test s9_wco_fail_with_mixed_accounts() {
  let tx =
    mock_tx(
      TestCase {
        without_random_input: True,
        without_random_output: True,
        is_all_cancels_same_account: False,
        is_account_balance_settlement_correct: True,
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

test s9_wco_fail_without_balance_settlement_correct() {
  let tx =
    mock_tx(
      TestCase {
        without_random_input: True,
        without_random_output: True,
        is_all_cancels_same_account: True,
        is_account_balance_settlement_correct: False,
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

test s9_wco_fail_without_operation_key_signed() {
  let tx =
    mock_tx(
      TestCase {
        without_random_input: True,
        without_random_output: True,
        is_all_cancels_same_account: True,
        is_account_balance_settlement_correct: True,
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
