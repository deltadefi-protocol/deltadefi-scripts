use app_deposit_request/spend as app_deposit_request_spend
use cardano/assets.{add, from_asset, from_lovelace, zero}
use cardano/transaction.{Transaction}
use hydra_dex/types.{
  AppDepositRequestDatum, AppDepositRequestEmergencyWithdrawal,
  AppDepositRequestSpamPreventionWithdraw,
  AppDepositRequestTransferAccountBalance, EmergencyWithdrawalRequestDatum,
  UserSpotAccount,
}
use hydra_dex/utils.{to_mvalue}
use mocktail.{
  complete, invalid_before, mint, mock_policy_id, mock_script_address,
  mock_tx_hash, mock_utxo_ref, mocktail_tx, ref_tx_in, ref_tx_in_inline_datum,
  required_signer_hash, script_withdrawal, tx_in, tx_in_inline_datum, tx_out,
}
use tests/utils.{
  mock_account, mock_account_2, mock_account_master_key_hash, mock_app_deposit,
  mock_app_deposit_request_address, mock_app_deposit_request_token,
  mock_emergency_withdrawal_request_address,
  mock_emergency_withdrawal_request_token, mock_input_oracle_datum,
  mock_operation_key, mock_oracle_address, mock_oracle_nft,
  mock_withdrawal_script_hashes,
} as test_utils

type TransferalTestCase {
  is_app_oracle_inputed: Bool,
  is_app_oracle_format_correct: Bool,
  is_app_deposit_auth_credential_attached: Bool,
}

fn mock_transfer_tx(test_case: TransferalTestCase) -> Transaction {
  let TransferalTestCase {
    is_app_oracle_inputed,
    is_app_oracle_format_correct,
    is_app_deposit_auth_credential_attached,
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
    |> tx_in(
        True,
        mock_tx_hash(0),
        0,
        input_value,
        mock_script_address(999, None),
      )
    |> tx_out(True, mock_script_address(999, None), input_value)
    |> script_withdrawal(
        is_app_deposit_auth_credential_attached,
        mock_app_deposit,
        0,
      )
    |> complete()
}

type EmergencyWithdrawTestCase {
  is_auth_by_account: Bool,
  is_account_correct: Bool,
  is_emergency_token_burnt: Bool,
  is_emergency_time_passed: Bool,
}

fn mock_emergency_withdraw_tx(
  test_case: EmergencyWithdrawTestCase,
) -> (Transaction, AppDepositRequestDatum) {
  let EmergencyWithdrawTestCase {
    is_auth_by_account,
    is_account_correct,
    is_emergency_token_burnt,
    is_emergency_time_passed,
  } = test_case

  let datum =
    AppDepositRequestDatum {
      account: UserSpotAccount {
        account: if is_account_correct {
          mock_account
        } else {
          mock_account_2
        },
      },
      amount: from_lovelace(100_000_000) |> to_mvalue(),
    }

  let tx =
    mocktail_tx()
      |> ref_tx_in(
          True,
          mock_tx_hash(0),
          1,
          from_asset(mock_oracle_nft, "", 1),
          mock_oracle_address,
        )
      |> ref_tx_in_inline_datum(True, mock_input_oracle_datum)
      |> tx_in(
          True,
          mock_tx_hash(0),
          0,
          from_asset(mock_app_deposit_request_token, "", 1)
            |> add("", "", 100_000_000),
          mock_app_deposit_request_address,
        )
      |> tx_in_inline_datum(True, datum)
      |> mint(
          is_emergency_token_burnt,
          -1,
          mock_emergency_withdrawal_request_token,
          "",
        )
      |> tx_in(
          True,
          mock_tx_hash(1),
          0,
          from_asset(mock_emergency_withdrawal_request_token, "", 1),
          mock_emergency_withdrawal_request_address,
        )
      |> tx_in_inline_datum(
          True,
          EmergencyWithdrawalRequestDatum {
            account: UserSpotAccount { account: mock_account },
            amount: zero |> to_mvalue(),
            timestamp: 100,
          },
        )
      |> invalid_before(is_emergency_time_passed, 100 + 86401)
      |> required_signer_hash(is_auth_by_account, mock_account_master_key_hash)
      |> complete()

  (tx, datum)
}

test s3_spend_success_emergency_withdraw() {
  let (tx, datum) =
    mock_emergency_withdraw_tx(
      EmergencyWithdrawTestCase {
        is_auth_by_account: True,
        is_account_correct: True,
        is_emergency_token_burnt: True,
        is_emergency_time_passed: True,
      },
    )

  app_deposit_request_spend.app_deposit_request.spend(
    mock_oracle_nft,
    Some(datum),
    AppDepositRequestEmergencyWithdrawal,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s3_spend_fail_emergency_withdraw_with_no_auth() {
  let (tx, datum) =
    mock_emergency_withdraw_tx(
      EmergencyWithdrawTestCase {
        is_auth_by_account: False,
        is_account_correct: True,
        is_emergency_token_burnt: True,
        is_emergency_time_passed: True,
      },
    )

  !app_deposit_request_spend.app_deposit_request.spend(
    mock_oracle_nft,
    Some(datum),
    AppDepositRequestEmergencyWithdrawal,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s3_spend_fail_emergency_withdraw_with_incorrect_account() {
  let (tx, datum) =
    mock_emergency_withdraw_tx(
      EmergencyWithdrawTestCase {
        is_auth_by_account: True,
        is_account_correct: False,
        is_emergency_token_burnt: True,
        is_emergency_time_passed: True,
      },
    )

  !app_deposit_request_spend.app_deposit_request.spend(
    mock_oracle_nft,
    Some(datum),
    AppDepositRequestEmergencyWithdrawal,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s3_spend_fail_emergency_withdraw_with_no_emergency_token_burnt() fail {
  let (tx, datum) =
    mock_emergency_withdraw_tx(
      EmergencyWithdrawTestCase {
        is_auth_by_account: True,
        is_account_correct: True,
        is_emergency_token_burnt: False,
        is_emergency_time_passed: True,
      },
    )

  app_deposit_request_spend.app_deposit_request.spend(
    mock_oracle_nft,
    Some(datum),
    AppDepositRequestEmergencyWithdrawal,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s3_spend_fail_emergency_withdraw_with_no_time_passed() {
  let (tx, datum) =
    mock_emergency_withdraw_tx(
      EmergencyWithdrawTestCase {
        is_auth_by_account: True,
        is_account_correct: True,
        is_emergency_token_burnt: True,
        is_emergency_time_passed: False,
      },
    )

  !app_deposit_request_spend.app_deposit_request.spend(
    mock_oracle_nft,
    Some(datum),
    AppDepositRequestEmergencyWithdrawal,
    mock_utxo_ref(0, 0),
    tx,
  )
}

type SpamPreventionWithdrawTestCase {
  is_app_oracle_inputed: Bool,
  is_app_oracle_format_correct: Bool,
  is_no_auth_token_inputed: Bool,
  is_operation_key_signed: Bool,
}

fn mock_spam_prevention_withdrawal_tx(
  test_case: SpamPreventionWithdrawTestCase,
) -> Transaction {
  let SpamPreventionWithdrawTestCase {
    is_app_oracle_inputed,
    is_app_oracle_format_correct,
    is_no_auth_token_inputed,
    is_operation_key_signed,
  } = test_case

  let input_value =
    from_asset(mock_policy_id(999), "", 1) |> add("", "", 2_000_000)

  let auth_value =
    from_asset(mock_app_deposit_request_token, "", 1) |> add("", "", 2_000_000)

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
    |> tx_in(
        is_no_auth_token_inputed,
        mock_tx_hash(0),
        0,
        input_value,
        mock_script_address(999, None),
      )
    |> tx_out(
        is_no_auth_token_inputed,
        mock_script_address(999, None),
        input_value,
      )
    |> tx_in(
        !is_no_auth_token_inputed,
        mock_utxo_ref(0, 0).transaction_id,
        mock_utxo_ref(0, 0).output_index,
        auth_value,
        mock_app_deposit_request_address,
      )
    |> tx_out(
        !is_no_auth_token_inputed,
        mock_app_deposit_request_address,
        auth_value,
      )
    |> required_signer_hash(is_operation_key_signed, mock_operation_key)
    |> complete()
}

test s3_spend_success_transfer() {
  let tx =
    mock_transfer_tx(
      TransferalTestCase {
        is_app_oracle_inputed: True,
        is_app_oracle_format_correct: True,
        is_app_deposit_auth_credential_attached: True,
      },
    )

  app_deposit_request_spend.app_deposit_request.spend(
    mock_oracle_nft,
    None,
    AppDepositRequestTransferAccountBalance,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s3_spend_fail_transfer_with_no_app_oracle_inputed() fail {
  let tx =
    mock_transfer_tx(
      TransferalTestCase {
        is_app_oracle_inputed: False,
        is_app_oracle_format_correct: True,
        is_app_deposit_auth_credential_attached: True,
      },
    )

  !app_deposit_request_spend.app_deposit_request.spend(
    mock_oracle_nft,
    None,
    AppDepositRequestTransferAccountBalance,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s3_spend_fail_transfer_with_incorrect_app_oracle_inputed() fail {
  let tx =
    mock_transfer_tx(
      TransferalTestCase {
        is_app_oracle_inputed: True,
        is_app_oracle_format_correct: False,
        is_app_deposit_auth_credential_attached: True,
      },
    )

  !app_deposit_request_spend.app_deposit_request.spend(
    mock_oracle_nft,
    None,
    AppDepositRequestTransferAccountBalance,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s3_spend_fail_transfer_with_no_attached() {
  let tx =
    mock_transfer_tx(
      TransferalTestCase {
        is_app_oracle_inputed: True,
        is_app_oracle_format_correct: True,
        is_app_deposit_auth_credential_attached: False,
      },
    )

  !app_deposit_request_spend.app_deposit_request.spend(
    mock_oracle_nft,
    None,
    AppDepositRequestTransferAccountBalance,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s3_spend_success_spam_prevention_withdraw() {
  let tx =
    mock_spam_prevention_withdrawal_tx(
      SpamPreventionWithdrawTestCase {
        is_app_oracle_inputed: True,
        is_app_oracle_format_correct: True,
        is_no_auth_token_inputed: True,
        is_operation_key_signed: True,
      },
    )

  app_deposit_request_spend.app_deposit_request.spend(
    mock_oracle_nft,
    None,
    AppDepositRequestSpamPreventionWithdraw,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s3_spend_fail_spam_prevention_withdraw_with_no_app_oracle_inputed() fail {
  let tx =
    mock_spam_prevention_withdrawal_tx(
      SpamPreventionWithdrawTestCase {
        is_app_oracle_inputed: False,
        is_app_oracle_format_correct: True,
        is_no_auth_token_inputed: True,
        is_operation_key_signed: True,
      },
    )

  !app_deposit_request_spend.app_deposit_request.spend(
    mock_oracle_nft,
    None,
    AppDepositRequestSpamPreventionWithdraw,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s3_spend_fail_spam_prevention_withdraw_with_incorrect_app_oracle_inputed() fail {
  let tx =
    mock_spam_prevention_withdrawal_tx(
      SpamPreventionWithdrawTestCase {
        is_app_oracle_inputed: True,
        is_app_oracle_format_correct: False,
        is_no_auth_token_inputed: True,
        is_operation_key_signed: True,
      },
    )

  !app_deposit_request_spend.app_deposit_request.spend(
    mock_oracle_nft,
    None,
    AppDepositRequestSpamPreventionWithdraw,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s3_spend_fail_spam_prevention_withdraw_with_auth_input() {
  let tx =
    mock_spam_prevention_withdrawal_tx(
      SpamPreventionWithdrawTestCase {
        is_app_oracle_inputed: True,
        is_app_oracle_format_correct: True,
        is_no_auth_token_inputed: False,
        is_operation_key_signed: True,
      },
    )

  !app_deposit_request_spend.app_deposit_request.spend(
    mock_oracle_nft,
    None,
    AppDepositRequestSpamPreventionWithdraw,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s3_spend_fail_spam_prevention_withdraw_with_no_op_key_sign() {
  let tx =
    mock_spam_prevention_withdrawal_tx(
      SpamPreventionWithdrawTestCase {
        is_app_oracle_inputed: True,
        is_app_oracle_format_correct: True,
        is_no_auth_token_inputed: True,
        is_operation_key_signed: False,
      },
    )

  !app_deposit_request_spend.app_deposit_request.spend(
    mock_oracle_nft,
    None,
    AppDepositRequestSpamPreventionWithdraw,
    mock_utxo_ref(0, 0),
    tx,
  )
}
