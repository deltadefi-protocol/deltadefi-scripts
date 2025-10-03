use cardano/assets.{add, from_asset}
use cardano/transaction.{Transaction}
use dex_order_book/spend as dex_order_book_spend
use hydra_dex/types.{DexOrderBookSpamPreventionWithdraw}
use mocktail.{
  complete, mock_policy_id, mock_tx_hash, mock_utxo_ref, mocktail_tx, ref_tx_in,
  ref_tx_in_inline_datum, required_signer_hash, tx_in, tx_out,
}
use tests/utils.{
  mock_dex_order_book_address, mock_dex_order_book_token,
  mock_input_oracle_datum, mock_operation_key, mock_oracle_address,
  mock_oracle_nft,
}

type SpamPreventionWithdrawTestCase {
  is_oracle_ref_utxo_attached: Bool,
  is_no_auth_token_inputed: Bool,
  is_operation_key_signed: Bool,
}

fn mock_spam_prevention_withdrawal_tx(
  test_case: SpamPreventionWithdrawTestCase,
) -> Transaction {
  let SpamPreventionWithdrawTestCase {
    is_oracle_ref_utxo_attached,
    is_no_auth_token_inputed,
    is_operation_key_signed,
  } = test_case

  let input_value =
    if is_no_auth_token_inputed {
      from_asset(mock_policy_id(999), "", 1) |> add("", "", 2_000_000)
    } else {
      from_asset(mock_dex_order_book_token, "", 1) |> add("", "", 2_000_000)
    }

  mocktail_tx()
    |> ref_tx_in(
        is_oracle_ref_utxo_attached,
        mock_tx_hash(0),
        0,
        from_asset(mock_oracle_nft, "", 1),
        mock_oracle_address,
      )
    |> ref_tx_in_inline_datum(
        is_oracle_ref_utxo_attached,
        mock_input_oracle_datum,
      )
    |> tx_in(True, mock_tx_hash(0), 0, input_value, mock_dex_order_book_address)
    |> tx_out(True, mock_dex_order_book_address, input_value)
    |> required_signer_hash(is_operation_key_signed, mock_operation_key)
    |> complete()
}

test s6_spend_success_spam_prevention_withdraw() {
  let tx =
    mock_spam_prevention_withdrawal_tx(
      SpamPreventionWithdrawTestCase {
        is_oracle_ref_utxo_attached: True,
        is_no_auth_token_inputed: True,
        is_operation_key_signed: True,
      },
    )

  dex_order_book_spend.dex_order_book.spend(
    mock_oracle_nft,
    mock_dex_order_book_token,
    None,
    DexOrderBookSpamPreventionWithdraw,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s6_spend_fail_spam_prevention_withdraw_with_no_dex_oracle_inputed() fail {
  let tx =
    mock_spam_prevention_withdrawal_tx(
      SpamPreventionWithdrawTestCase {
        is_oracle_ref_utxo_attached: False,
        is_no_auth_token_inputed: True,
        is_operation_key_signed: True,
      },
    )

  dex_order_book_spend.dex_order_book.spend(
    mock_oracle_nft,
    mock_dex_order_book_token,
    None,
    DexOrderBookSpamPreventionWithdraw,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s6_spend_fail_spam_prevention_withdraw_with_auth_input() {
  let tx =
    mock_spam_prevention_withdrawal_tx(
      SpamPreventionWithdrawTestCase {
        is_oracle_ref_utxo_attached: True,
        is_no_auth_token_inputed: False,
        is_operation_key_signed: True,
      },
    )

  !dex_order_book_spend.dex_order_book.spend(
    mock_oracle_nft,
    mock_dex_order_book_token,
    None,
    DexOrderBookSpamPreventionWithdraw,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s6_spend_fail_spam_prevention_withdraw_with_no_op_key_sign() fail {
  let tx =
    mock_spam_prevention_withdrawal_tx(
      SpamPreventionWithdrawTestCase {
        is_oracle_ref_utxo_attached: True,
        is_no_auth_token_inputed: True,
        is_operation_key_signed: False,
      },
    )

  dex_order_book_spend.dex_order_book.spend(
    mock_oracle_nft,
    mock_dex_order_book_token,
    None,
    DexOrderBookSpamPreventionWithdraw,
    mock_utxo_ref(0, 0),
    tx,
  )
}
