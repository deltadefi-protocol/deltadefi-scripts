use app_vault/spend as app_vault_spend
use cardano/assets.{add, from_asset}
use cardano/transaction.{Transaction}
use mocktail.{
  complete, mock_policy_id, mock_script_address, mock_tx_hash, mock_utxo_ref,
  mocktail_tx, ref_tx_in, ref_tx_in_inline_datum, script_withdrawal, tx_in,
  tx_out,
}
use tests/utils.{
  mock_app_withdrawal, mock_input_oracle_datum, mock_oracle_address,
  mock_oracle_nft, mock_withdrawal_script_hashes,
}

type VaultWithdrawalTestCase {
  is_app_oracle_inputed: Bool,
  is_app_oracle_format_correct: Bool,
  is_app_withdrawal_auth_credential_attached: Bool,
}

fn mock_withdraw_tx(test_case: VaultWithdrawalTestCase) -> Transaction {
  let VaultWithdrawalTestCase {
    is_app_oracle_inputed,
    is_app_oracle_format_correct,
    is_app_withdrawal_auth_credential_attached,
  } = test_case

  let input_value =
    from_asset(mock_policy_id(999), "", 1) |> add("", "", 2_000_000)

  mocktail_tx()
    |> ref_tx_in(
        is_app_oracle_inputed,
        mock_tx_hash(0),
        0,
        from_asset(mock_oracle_nft, "", 1),
        mock_oracle_address,
      )
    |> ref_tx_in_inline_datum(
        is_app_oracle_inputed && is_app_oracle_format_correct,
        mock_input_oracle_datum,
      )
    |> ref_tx_in_inline_datum(
        is_app_oracle_inputed && !is_app_oracle_format_correct,
        mock_withdrawal_script_hashes,
      )
    |> script_withdrawal(
        is_app_withdrawal_auth_credential_attached,
        mock_app_withdrawal,
        0,
      )
    |> tx_in(
        True,
        mock_tx_hash(0),
        0,
        input_value,
        mock_script_address(999, None),
      )
    |> tx_out(True, mock_script_address(0, None), input_value)
    |> complete()
}

test s2_spend_success_withdraw() {
  let tx =
    mock_withdraw_tx(
      VaultWithdrawalTestCase {
        is_app_oracle_inputed: True,
        is_app_oracle_format_correct: True,
        is_app_withdrawal_auth_credential_attached: True,
      },
    )

  app_vault_spend.app_vault.spend(
    mock_oracle_nft,
    None,
    Void,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s2_spend_fail_withdraw_with_no_app_oracle_inputed() fail {
  let tx =
    mock_withdraw_tx(
      VaultWithdrawalTestCase {
        is_app_oracle_inputed: False,
        is_app_oracle_format_correct: True,
        is_app_withdrawal_auth_credential_attached: True,
      },
    )

  !app_vault_spend.app_vault.spend(
    mock_oracle_nft,
    None,
    Void,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s2_spend_fail_withdraw_with_incorrect_app_oracle_inputed() fail {
  let tx =
    mock_withdraw_tx(
      VaultWithdrawalTestCase {
        is_app_oracle_inputed: True,
        is_app_oracle_format_correct: False,
        is_app_withdrawal_auth_credential_attached: True,
      },
    )

  !app_vault_spend.app_vault.spend(
    mock_oracle_nft,
    None,
    Void,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s2_spend_fail_withdraw_with_no_withdrawal_auth_credential() {
  let tx =
    mock_withdraw_tx(
      VaultWithdrawalTestCase {
        is_app_oracle_inputed: True,
        is_app_oracle_format_correct: True,
        is_app_withdrawal_auth_credential_attached: False,
      },
    )

  !app_vault_spend.app_vault.spend(
    mock_oracle_nft,
    None,
    Void,
    mock_utxo_ref(0, 0),
    tx,
  )
}
