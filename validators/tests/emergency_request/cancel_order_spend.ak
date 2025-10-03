use cardano/assets.{add, from_asset, from_lovelace}
use cardano/transaction.{Transaction}
use emergency_request/cancel_order_spend
use hydra_dex/types.{
  EmergencyCancelRequestDatum, EmergencyRequestExpiredCancel,
  EmergencyRequestProcessCancel, EmergencyRequestSpamPreventionCancel,
  UserSpotAccount,
}
use mocktail.{
  complete, invalid_before, mint, mock_tx_hash, mock_utxo_ref, mocktail_tx,
  ref_tx_in, ref_tx_in_inline_datum, required_signer_hash, script_withdrawal,
  tx_in, tx_in_inline_datum,
}
use tests/utils.{
  mock_account, mock_account_master_key_hash, mock_emergency_cancel_order,
  mock_emergency_cancel_order_request_address,
  mock_emergency_cancel_order_request_token, mock_input_oracle_datum,
  mock_operation_key, mock_oracle_address, mock_oracle_nft,
}

fn mock_emergency_cancel_tx(is_withdrawal_script_presented: Bool) -> Transaction {
  mocktail_tx()
    |> ref_tx_in(
        True,
        mock_tx_hash(0),
        0,
        from_asset(mock_oracle_nft, "", 1),
        mock_oracle_address,
      )
    |> ref_tx_in_inline_datum(True, mock_input_oracle_datum)
    |> script_withdrawal(
        is_withdrawal_script_presented,
        mock_emergency_cancel_order,
        0,
      )
    |> complete()
}

test s4_c_spend_success_emergency_cancel() {
  let tx = mock_emergency_cancel_tx(True)
  cancel_order_spend.emergency_cancel_order_request.spend(
    mock_oracle_nft,
    None,
    EmergencyRequestProcessCancel,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s4_c_spend_fail_emergency_cancel() {
  let tx = mock_emergency_cancel_tx(False)
  !cancel_order_spend.emergency_cancel_order_request.spend(
    mock_oracle_nft,
    None,
    EmergencyRequestProcessCancel,
    mock_utxo_ref(0, 0),
    tx,
  )
}

type SpamPreventionTestCase {
  is_operation_key_signed: Bool,
  is_without_auth_token: Bool,
}

fn mock_spam_prevention_tx(test_case: SpamPreventionTestCase) -> Transaction {
  let SpamPreventionTestCase { is_operation_key_signed, is_without_auth_token } =
    test_case

  let input_value =
    if is_without_auth_token {
      from_lovelace(2_000_000)
    } else {
      from_lovelace(2_000_000)
        |> add(mock_emergency_cancel_order_request_token, "", 1)
    }

  mocktail_tx()
    |> ref_tx_in(
        True,
        mock_tx_hash(0),
        0,
        from_asset(mock_oracle_nft, "", 1),
        mock_oracle_address,
      )
    |> ref_tx_in_inline_datum(True, mock_input_oracle_datum)
    |> tx_in(
        True,
        mock_tx_hash(0),
        0,
        input_value,
        mock_emergency_cancel_order_request_address,
      )
    |> required_signer_hash(is_operation_key_signed, mock_operation_key)
    |> complete()
}

test s4_c_spend_success_spam_prevention() {
  let test_case =
    SpamPreventionTestCase {
      is_operation_key_signed: True,
      is_without_auth_token: True,
    }
  let tx = mock_spam_prevention_tx(test_case)
  cancel_order_spend.emergency_cancel_order_request.spend(
    mock_oracle_nft,
    None,
    EmergencyRequestSpamPreventionCancel,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s4_c_spend_fail_spam_prevention_without_operation_key_signed() {
  let test_case =
    SpamPreventionTestCase {
      is_operation_key_signed: False,
      is_without_auth_token: True,
    }
  let tx = mock_spam_prevention_tx(test_case)
  !cancel_order_spend.emergency_cancel_order_request.spend(
    mock_oracle_nft,
    None,
    EmergencyRequestSpamPreventionCancel,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s4_c_spend_fail_spam_prevention_with_auth_token() {
  let test_case =
    SpamPreventionTestCase {
      is_operation_key_signed: True,
      is_without_auth_token: False,
    }
  let tx = mock_spam_prevention_tx(test_case)
  !cancel_order_spend.emergency_cancel_order_request.spend(
    mock_oracle_nft,
    None,
    EmergencyRequestSpamPreventionCancel,
    mock_utxo_ref(0, 0),
    tx,
  )
}

type ExpireTestCase {
  is_auth_token_burnt: Bool,
  is_operation_key_signed: Bool,
  is_user_authorized: Bool,
  is_request_expired: Bool,
}

fn mock_expire_tx(
  test_case: ExpireTestCase,
) -> (Transaction, EmergencyCancelRequestDatum) {
  let ExpireTestCase {
    is_auth_token_burnt,
    is_operation_key_signed,
    is_user_authorized,
    is_request_expired,
  } = test_case

  let datum =
    EmergencyCancelRequestDatum {
      account: UserSpotAccount { account: mock_account },
      order_id: "order_id",
      timestamp: 100,
    }

  let tx =
    mocktail_tx()
      |> ref_tx_in(
          True,
          mock_tx_hash(0),
          0,
          from_asset(mock_oracle_nft, "", 1),
          mock_oracle_address,
        )
      |> ref_tx_in_inline_datum(True, mock_input_oracle_datum)
      |> tx_in(
          True,
          mock_tx_hash(0),
          0,
          from_lovelace(2_000_000)
            |> add(mock_emergency_cancel_order_request_token, "", 1),
          mock_emergency_cancel_order_request_address,
        )
      |> tx_in_inline_datum(True, datum)
      |> mint(
          is_auth_token_burnt,
          -1,
          mock_emergency_cancel_order_request_token,
          "",
        )
      |> required_signer_hash(is_operation_key_signed, mock_operation_key)
      |> required_signer_hash(is_user_authorized, mock_account_master_key_hash)
      |> invalid_before(is_request_expired, 101 + 172800)
      |> complete()

  (tx, datum)
}

test s4_c_spend_success_expire_by_app() {
  let test_case =
    ExpireTestCase {
      is_auth_token_burnt: True,
      is_operation_key_signed: True,
      is_user_authorized: False,
      is_request_expired: True,
    }
  let (tx, datum) = mock_expire_tx(test_case)
  cancel_order_spend.emergency_cancel_order_request.spend(
    mock_oracle_nft,
    Some(datum),
    EmergencyRequestExpiredCancel,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s4_c_spend_success_expire_by_user() {
  let test_case =
    ExpireTestCase {
      is_auth_token_burnt: True,
      is_operation_key_signed: False,
      is_user_authorized: True,
      is_request_expired: True,
    }
  let (tx, datum) = mock_expire_tx(test_case)
  cancel_order_spend.emergency_cancel_order_request.spend(
    mock_oracle_nft,
    Some(datum),
    EmergencyRequestExpiredCancel,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s4_c_spend_fail_expire_without_auth_token_burnt() fail {
  let test_case =
    ExpireTestCase {
      is_auth_token_burnt: False,
      is_operation_key_signed: True,
      is_user_authorized: True,
      is_request_expired: True,
    }
  let (tx, datum) = mock_expire_tx(test_case)
  !cancel_order_spend.emergency_cancel_order_request.spend(
    mock_oracle_nft,
    Some(datum),
    EmergencyRequestExpiredCancel,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s4_c_spend_fail_expire_without_auth() {
  let test_case =
    ExpireTestCase {
      is_auth_token_burnt: True,
      is_operation_key_signed: False,
      is_user_authorized: False,
      is_request_expired: True,
    }
  let (tx, datum) = mock_expire_tx(test_case)
  !cancel_order_spend.emergency_cancel_order_request.spend(
    mock_oracle_nft,
    Some(datum),
    EmergencyRequestExpiredCancel,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s4_c_spend_fail_expire_when_not_expired() {
  let test_case =
    ExpireTestCase {
      is_auth_token_burnt: True,
      is_operation_key_signed: True,
      is_user_authorized: True,
      is_request_expired: False,
    }
  let (tx, datum) = mock_expire_tx(test_case)
  !cancel_order_spend.emergency_cancel_order_request.spend(
    mock_oracle_nft,
    Some(datum),
    EmergencyRequestExpiredCancel,
    mock_utxo_ref(0, 0),
    tx,
  )
}
