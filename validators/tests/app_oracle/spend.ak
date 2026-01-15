use app_oracle/spend as app_oracle_spend
use cardano/assets.{add, from_asset, from_lovelace}
use cardano/transaction.{Transaction}
use hydra_dex/types.{AppOracleDatum, DexRotateKey, StopDex}
use mocktail.{
  complete, mock_policy_id, mock_tx_hash, mock_utxo_ref, mocktail_tx,
  required_signer_hash, tx_in, tx_in_inline_datum, tx_out, tx_out_inline_datum,
}
use tests/utils.{
  mock_input_oracle_datum, mock_new_operation_key, mock_new_stop_key,
  mock_oracle_address, mock_oracle_nft, mock_output_oracle_datum, mock_stop_key,
}

type RotateTestCase {
  is_old_stop_key_signed: Bool,
  is_oracle_output_clean: Bool,
  is_new_stop_key_signed: Bool,
  is_output_datum_updated: Bool,
}

const mock_redeemer =
  DexRotateKey {
    new_operation_key: mock_new_operation_key,
    new_stop_key: mock_new_stop_key,
  }

fn mock_rotate_tx(test_case: RotateTestCase) -> Transaction {
  let RotateTestCase {
    is_old_stop_key_signed,
    is_oracle_output_clean,
    is_new_stop_key_signed,
    is_output_datum_updated,
  } = test_case

  let input_value = from_asset(mock_oracle_nft, "", 1) |> add("", "", 2_000_000)

  mocktail_tx()
    |> tx_in(True, mock_tx_hash(0), 0, input_value, mock_oracle_address)
    |> tx_in_inline_datum(True, mock_input_oracle_datum)
    |> tx_out(is_oracle_output_clean, mock_oracle_address, input_value)
    |> tx_out(
        !is_oracle_output_clean,
        mock_oracle_address,
        input_value |> add(mock_policy_id(999), "", 1),
      )
    |> tx_out_inline_datum(is_output_datum_updated, mock_output_oracle_datum)
    |> tx_out_inline_datum(!is_output_datum_updated, mock_input_oracle_datum)
    |> required_signer_hash(is_old_stop_key_signed, mock_stop_key)
    |> required_signer_hash(is_new_stop_key_signed, mock_new_stop_key)
    |> complete()
}

test s1_spend_success_rotate() {
  let datum = mock_input_oracle_datum
  let redeemer = mock_redeemer
  let tx =
    mock_rotate_tx(
      RotateTestCase {
        is_old_stop_key_signed: True,
        is_oracle_output_clean: True,
        is_new_stop_key_signed: True,
        is_output_datum_updated: True,
      },
    )

  app_oracle_spend.app_oracle.spend(
    Some(datum),
    redeemer,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s1_spend_fail_rotate_with_no_old_stop_key_signed() {
  let datum = mock_input_oracle_datum
  let redeemer = mock_redeemer
  let tx =
    mock_rotate_tx(
      RotateTestCase {
        is_old_stop_key_signed: False,
        is_oracle_output_clean: True,
        is_new_stop_key_signed: True,
        is_output_datum_updated: True,
      },
    )

  !app_oracle_spend.app_oracle.spend(
    Some(datum),
    redeemer,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s1_spend_fail_rotate_with_unclean_output() {
  let datum = mock_input_oracle_datum
  let redeemer = mock_redeemer
  let tx =
    mock_rotate_tx(
      RotateTestCase {
        is_old_stop_key_signed: True,
        is_oracle_output_clean: False,
        is_new_stop_key_signed: True,
        is_output_datum_updated: True,
      },
    )

  !app_oracle_spend.app_oracle.spend(
    Some(datum),
    redeemer,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s1_spend_fail_rotate_with_no_new_stop_key_signed() {
  let datum = mock_input_oracle_datum
  let redeemer = mock_redeemer
  let tx =
    mock_rotate_tx(
      RotateTestCase {
        is_old_stop_key_signed: True,
        is_oracle_output_clean: True,
        is_new_stop_key_signed: False,
        is_output_datum_updated: True,
      },
    )

  !app_oracle_spend.app_oracle.spend(
    Some(datum),
    redeemer,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s1_spend_fail_rotate_with_incorrect_new_datum() {
  let datum = mock_input_oracle_datum
  let redeemer = mock_redeemer
  let tx =
    mock_rotate_tx(
      RotateTestCase {
        is_old_stop_key_signed: True,
        is_oracle_output_clean: True,
        is_new_stop_key_signed: True,
        is_output_datum_updated: False,
      },
    )

  !app_oracle_spend.app_oracle.spend(
    Some(datum),
    redeemer,
    mock_utxo_ref(0, 0),
    tx,
  )
}

type StopOracleTestCase {
  is_stop_key_signed: Bool,
  is_oracle_output_clean: Bool,
  is_datum_correct: Bool,
}

fn mock_stop_oracle_tx(test_case: StopOracleTestCase) -> Transaction {
  let StopOracleTestCase {
    is_stop_key_signed,
    is_oracle_output_clean,
    is_datum_correct,
  } = test_case

  let input_value = from_lovelace(20000000) |> add(mock_oracle_nft, "", 1)

  mocktail_tx()
    |> tx_in(True, mock_tx_hash(0), 0, input_value, mock_oracle_address)
    |> tx_in_inline_datum(True, mock_input_oracle_datum)
    |> tx_out(is_oracle_output_clean, mock_oracle_address, input_value)
    |> tx_out(
        !is_oracle_output_clean,
        mock_oracle_address,
        input_value |> add(mock_policy_id(999), "", 1),
      )
    |> tx_out_inline_datum(
        is_datum_correct,
        AppOracleDatum {
          ..mock_output_oracle_datum,
          operation_key: #"",
          stop_key: #"",
        },
      )
    |> tx_out_inline_datum(
        !is_datum_correct,
        AppOracleDatum {
          ..mock_input_oracle_datum,
          operation_key: "a",
          stop_key: "b",
        },
      )
    |> required_signer_hash(is_stop_key_signed, mock_stop_key)
    |> complete()
}

test s1_spend_success_stop() {
  let datum = mock_input_oracle_datum
  let redeemer = StopDex
  let tx =
    mock_stop_oracle_tx(
      StopOracleTestCase {
        is_stop_key_signed: True,
        is_oracle_output_clean: True,
        is_datum_correct: True,
      },
    )

  app_oracle_spend.app_oracle.spend(
    Some(datum),
    redeemer,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s1_spend_fail_stop_with_no_stop_key_signed() fail {
  let datum = mock_input_oracle_datum
  let redeemer = StopDex

  let tx =
    mock_stop_oracle_tx(
      StopOracleTestCase {
        is_stop_key_signed: False,
        is_oracle_output_clean: True,
        is_datum_correct: True,
      },
    )

  app_oracle_spend.app_oracle.spend(
    Some(datum),
    redeemer,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s1_spend_fail_stop_with_oracle_nft_not_burnt() fail {
  let datum = mock_input_oracle_datum
  let redeemer = StopDex

  let tx =
    mock_stop_oracle_tx(
      StopOracleTestCase {
        is_stop_key_signed: True,
        is_oracle_output_clean: True,
        is_datum_correct: False,
      },
    )

  app_oracle_spend.app_oracle.spend(
    Some(datum),
    redeemer,
    mock_utxo_ref(0, 0),
    tx,
  )
}
