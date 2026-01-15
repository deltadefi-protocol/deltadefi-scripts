use app_vault/app_vault_stake_rotation as avsr
use cardano/address.{Script}
use cardano/assets.{from_asset, from_lovelace}
use cardano/transaction.{Transaction}
use mocktail.{
  complete, mock_tx_hash, mocktail_tx, ref_tx_in, ref_tx_in_inline_datum,
  required_signer_hash, script_withdrawal, tx_in, tx_out,
}
use tests/utils.{
  mock_app_vault_address, mock_app_vault_stake_rotation, mock_input_oracle_datum,
  mock_operation_key, mock_oracle_address, mock_oracle_nft,
} as test_utils

type TestCase {
  is_operation_key_signed: Bool,
  is_value_unlocked_correct: Bool,
}

fn mock_tx(test_case: TestCase) -> Transaction {
  let TestCase { is_operation_key_signed, is_value_unlocked_correct } =
    test_case

  mocktail_tx()
    |> ref_tx_in(
        True,
        mock_tx_hash(0),
        0,
        from_asset(mock_oracle_nft, "", 1),
        mock_oracle_address,
      )
    |> ref_tx_in_inline_datum(True, mock_input_oracle_datum)
    |> script_withdrawal(True, mock_app_vault_stake_rotation, 0)
    |> tx_in(
        True,
        mock_tx_hash(0),
        0,
        from_lovelace(10_000_000),
        mock_app_vault_address,
      )
    |> tx_in(
        True,
        mock_tx_hash(0),
        0,
        from_lovelace(10_000_000),
        mock_app_vault_address,
      )
    |> tx_in(
        True,
        mock_tx_hash(0),
        0,
        from_lovelace(10_000_000),
        mock_app_vault_address,
      )
    |> tx_out(True, mock_app_vault_address, from_lovelace(10_000_000))
    |> tx_out(True, mock_app_vault_address, from_lovelace(10_000_000))
    |> tx_out(
        is_value_unlocked_correct,
        mock_app_vault_address,
        from_lovelace(10_000_000),
      )
    |> required_signer_hash(is_operation_key_signed, mock_operation_key)
    |> complete()
}

test s2_wavsr_success_stake_key_rotation() {
  let tx =
    mock_tx(
      TestCase {
        is_operation_key_signed: True,
        is_value_unlocked_correct: True,
      },
    )

  avsr.app_vault_stake_rotation.withdraw(
    mock_oracle_nft,
    Void,
    Script(mock_app_vault_stake_rotation),
    tx,
  )
}

test s2_wavsr_fail_unauthorized_stake_key_rotation() {
  let tx =
    mock_tx(
      TestCase {
        is_operation_key_signed: False,
        is_value_unlocked_correct: True,
      },
    )

  !avsr.app_vault_stake_rotation.withdraw(
    mock_oracle_nft,
    Void,
    Script(mock_app_vault_stake_rotation),
    tx,
  )
}

test s2_wavsr_fail_incorrect_value_after_stake_key_rotation() {
  let tx =
    mock_tx(
      TestCase {
        is_operation_key_signed: True,
        is_value_unlocked_correct: False,
      },
    )

  !avsr.app_vault_stake_rotation.withdraw(
    mock_oracle_nft,
    Void,
    Script(mock_app_vault_stake_rotation),
    tx,
  )
}
