use cardano/assets.{from_asset, merge, zero}
use cardano/transaction.{Transaction}
use hydra_account_balance/spend as hydra_account_balance_spend
use hydra_dex/types.{HydraAccountBalanceRemoveEmptyBalance, UserSpotAccount}
use mocktail.{
  complete, mint, mock_tx_hash, mock_utxo_ref, mocktail_tx, ref_tx_in,
  ref_tx_in_inline_datum, required_signer_hash, tx_in, tx_in_inline_datum,
}
use tests/utils.{
  mock_account, mock_dex_order_book_address, mock_dex_order_book_datum,
  mock_dex_order_book_token, mock_hydra_account_balance_address,
  mock_hydra_account_balance_token, mock_hydra_lovelace, mock_operation_key,
}

// type SpamPreventionWithdrawTestCase {
//   is_dex_oracle_inputed: Bool,
//   is_no_auth_token_inputed: Bool,
//   is_operation_key_signed: Bool,
// }

// fn mock_spam_prevention_withdrawal_tx(
//   test_case: SpamPreventionWithdrawTestCase,
// ) -> Transaction {
//   let SpamPreventionWithdrawTestCase {
//     is_dex_oracle_inputed,
//     is_no_auth_token_inputed,
//     is_operation_key_signed,
//   } = test_case

//   let input_value =
//     if is_no_auth_token_inputed {
//       from_asset(mock_policy_id(999), "", 1)
//     } else {
//       from_asset(mock_hydra_account_balance_token, "", 1)
//     }

//   mocktail_tx()
//     |> ref_tx_in(
//         is_dex_oracle_inputed,
//         mock_tx_hash(0),
//         0,
//         from_asset(mock_dex_order_book_token, "", 1),
//         mock_dex_order_book_address,
//       )
//     |> ref_tx_in_inline_datum(is_dex_oracle_inputed, mock_dex_order_book_datum)
//     |> tx_in(
//         True,
//         mock_tx_hash(0),
//         0,
//         input_value,
//         mock_script_address(999, None),
//       )
//     |> tx_out(True, mock_script_address(999, None), input_value)
//     |> required_signer_hash(is_operation_key_signed, mock_operation_key)
//     |> complete()
// }

// test s8_spend_success_spam_prevention_withdraw() {
//   let tx =
//     mock_spam_prevention_withdrawal_tx(
//       SpamPreventionWithdrawTestCase {
//         is_dex_oracle_inputed: True,
//         is_no_auth_token_inputed: True,
//         is_operation_key_signed: True,
//       },
//     )

//   hydra_account_balance_spend.hydra_account_balance.spend(
//     mock_dex_order_book_token,
//     None,
//     HydraAccountBalanceSpamPreventionWithdraw,
//     mock_utxo_ref(0, 0),
//     tx,
//   )
// }

// test s8_spend_fail_spam_prevention_withdraw_with_no_app_oracle_inputed() fail {
//   let tx =
//     mock_spam_prevention_withdrawal_tx(
//       SpamPreventionWithdrawTestCase {
//         is_dex_oracle_inputed: False,
//         is_no_auth_token_inputed: True,
//         is_operation_key_signed: True,
//       },
//     )

//   !hydra_account_balance_spend.hydra_account_balance.spend(
//     mock_dex_order_book_token,
//     None,
//     HydraAccountBalanceSpamPreventionWithdraw,
//     mock_utxo_ref(0, 0),
//     tx,
//   )
// }

// test s8_spend_fail_spam_prevention_withdraw_with_auth_input() {
//   let tx =
//     mock_spam_prevention_withdrawal_tx(
//       SpamPreventionWithdrawTestCase {
//         is_dex_oracle_inputed: True,
//         is_no_auth_token_inputed: False,
//         is_operation_key_signed: True,
//       },
//     )

//   !hydra_account_balance_spend.hydra_account_balance.spend(
//     mock_dex_order_book_token,
//     None,
//     HydraAccountBalanceSpamPreventionWithdraw,
//     mock_utxo_ref(0, 0),
//     tx,
//   )
// }

// test s8_spend_fail_spam_prevention_withdraw_with_no_op_key_sign() {
//   let tx =
//     mock_spam_prevention_withdrawal_tx(
//       SpamPreventionWithdrawTestCase {
//         is_dex_oracle_inputed: True,
//         is_no_auth_token_inputed: True,
//         is_operation_key_signed: False,
//       },
//     )

//   !hydra_account_balance_spend.hydra_account_balance.spend(
//     mock_dex_order_book_token,
//     None,
//     HydraAccountBalanceSpamPreventionWithdraw,
//     mock_utxo_ref(0, 0),
//     tx,
//   )
// }

type RemoveEmptyBalanceTestCase {
  is_only_account_balance_input: Bool,
  is_empty_balance: Bool,
  is_auth_token_burnt: Bool,
  is_operation_key_signed: Bool,
}

fn mock_remove_empty_balance_tx(
  test_case: RemoveEmptyBalanceTestCase,
) -> Transaction {
  let RemoveEmptyBalanceTestCase {
    is_only_account_balance_input,
    is_empty_balance,
    is_auth_token_burnt,
    is_operation_key_signed,
  } = test_case

  let account = UserSpotAccount { account: mock_account }

  let balance =
    if is_empty_balance {
      zero
    } else {
      mock_hydra_lovelace(1_000_000)
    }

  let auth_value =
    from_asset(mock_hydra_account_balance_token, "", 1) |> merge(balance)

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
        auth_value,
        mock_hydra_account_balance_address,
      )
    |> tx_in_inline_datum(True, account)
    |> tx_in(
        !is_only_account_balance_input,
        mock_tx_hash(0),
        1,
        auth_value,
        mock_hydra_account_balance_address,
      )
    |> tx_in_inline_datum(!is_only_account_balance_input, account)
    |> mint(is_auth_token_burnt, -1, mock_hydra_account_balance_token, "")
    |> required_signer_hash(is_operation_key_signed, mock_operation_key)
    |> complete()
}

test s8_spend_success_remove_empty_balance() {
  let tx =
    mock_remove_empty_balance_tx(
      RemoveEmptyBalanceTestCase {
        is_only_account_balance_input: True,
        is_empty_balance: True,
        is_auth_token_burnt: True,
        is_operation_key_signed: True,
      },
    )

  hydra_account_balance_spend.hydra_account_balance.spend(
    mock_dex_order_book_token,
    None,
    HydraAccountBalanceRemoveEmptyBalance,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s8_spend_fail_remove_empty_balance_with_multiple_account_balance_input() fail {
  let tx =
    mock_remove_empty_balance_tx(
      RemoveEmptyBalanceTestCase {
        is_only_account_balance_input: False,
        is_empty_balance: True,
        is_auth_token_burnt: True,
        is_operation_key_signed: True,
      },
    )

  hydra_account_balance_spend.hydra_account_balance.spend(
    mock_dex_order_book_token,
    None,
    HydraAccountBalanceRemoveEmptyBalance,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s8_spend_fail_remove_empty_balance_with_non_empty_balance() fail {
  let tx =
    mock_remove_empty_balance_tx(
      RemoveEmptyBalanceTestCase {
        is_only_account_balance_input: True,
        is_empty_balance: False,
        is_auth_token_burnt: True,
        is_operation_key_signed: True,
      },
    )

  hydra_account_balance_spend.hydra_account_balance.spend(
    mock_dex_order_book_token,
    None,
    HydraAccountBalanceRemoveEmptyBalance,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s8_spend_fail_remove_empty_balance_without_auth_token_burnt() fail {
  let tx =
    mock_remove_empty_balance_tx(
      RemoveEmptyBalanceTestCase {
        is_only_account_balance_input: True,
        is_empty_balance: True,
        is_auth_token_burnt: False,
        is_operation_key_signed: True,
      },
    )

  hydra_account_balance_spend.hydra_account_balance.spend(
    mock_dex_order_book_token,
    None,
    HydraAccountBalanceRemoveEmptyBalance,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s8_spend_fail_remove_empty_balance_without_operation_key_signed() {
  let tx =
    mock_remove_empty_balance_tx(
      RemoveEmptyBalanceTestCase {
        is_only_account_balance_input: True,
        is_empty_balance: True,
        is_auth_token_burnt: True,
        is_operation_key_signed: False,
      },
    )

  !hydra_account_balance_spend.hydra_account_balance.spend(
    mock_dex_order_book_token,
    None,
    HydraAccountBalanceRemoveEmptyBalance,
    mock_utxo_ref(0, 0),
    tx,
  )
}
