use cardano/assets.{from_asset, zero}
use cardano/transaction.{Transaction}
use hydra_account/core as ha
use hydra_dex/types.{HydraAccountSpamPreventionWithdraw, UserTradeAccount}
use mocktail.{
  complete, mock_tx_hash, mock_utxo_ref, mocktail_tx, ref_tx_in,
  ref_tx_in_inline_datum, required_signer_hash, tx_in,
}
use tests/utils.{
  mock_account, mock_dex_order_book_address, mock_dex_order_book_datum,
  mock_dex_order_book_token, mock_hydra_account_address, mock_hydra_lovelace,
  mock_operation_key,
}

type RemoveEmptyBalanceTestCase {
  is_empty_balance: Bool,
  is_operation_key_signed: Bool,
}

fn mock_spam_prevention_tx(test_case: RemoveEmptyBalanceTestCase) -> Transaction {
  let RemoveEmptyBalanceTestCase { is_empty_balance, is_operation_key_signed } =
    test_case

  let balance =
    if is_empty_balance {
      zero
    } else {
      mock_hydra_lovelace(1_000_000)
    }

  mocktail_tx()
    |> ref_tx_in(
        True,
        mock_tx_hash(0),
        1,
        from_asset(mock_dex_order_book_token, "", 1),
        mock_dex_order_book_address,
      )
    |> ref_tx_in_inline_datum(True, mock_dex_order_book_datum)
    |> tx_in(True, mock_tx_hash(0), 0, balance, mock_hydra_account_address)
    |> required_signer_hash(is_operation_key_signed, mock_operation_key)
    |> complete()
}

test s8_spend_success_spam_prevention() {
  let tx =
    mock_spam_prevention_tx(
      RemoveEmptyBalanceTestCase {
        is_empty_balance: True,
        is_operation_key_signed: True,
      },
    )

  ha.hydra_account.spend(
    mock_dex_order_book_token,
    None,
    HydraAccountSpamPreventionWithdraw,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s8_spend_success_spam_prevention_with_no_datum_only() {
  let tx =
    mock_spam_prevention_tx(
      RemoveEmptyBalanceTestCase {
        is_empty_balance: False,
        is_operation_key_signed: True,
      },
    )

  ha.hydra_account.spend(
    mock_dex_order_book_token,
    None,
    HydraAccountSpamPreventionWithdraw,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s8_spend_success_spam_prevention_with_empty_balance_only() {
  let tx =
    mock_spam_prevention_tx(
      RemoveEmptyBalanceTestCase {
        is_empty_balance: True,
        is_operation_key_signed: True,
      },
    )

  let account = UserTradeAccount { account: mock_account }
  ha.hydra_account.spend(
    mock_dex_order_book_token,
    Some(account),
    HydraAccountSpamPreventionWithdraw,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s8_spend_fail_spam_prevention_with_non_empty_balance_and_with_datum() {
  let tx =
    mock_spam_prevention_tx(
      RemoveEmptyBalanceTestCase {
        is_empty_balance: False,
        is_operation_key_signed: True,
      },
    )

  let account = UserTradeAccount { account: mock_account }

  !ha.hydra_account.spend(
    mock_dex_order_book_token,
    Some(account),
    HydraAccountSpamPreventionWithdraw,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s8_spend_fail_spam_prevention_without_operation_key_signed() {
  let tx =
    mock_spam_prevention_tx(
      RemoveEmptyBalanceTestCase {
        is_empty_balance: True,
        is_operation_key_signed: False,
      },
    )

  !ha.hydra_account.spend(
    mock_dex_order_book_token,
    None,
    HydraAccountSpamPreventionWithdraw,
    mock_utxo_ref(0, 0),
    tx,
  )
}
