use cardano/address.{Script}
use cardano/assets.{from_asset}
use cardano/transaction.{Transaction}
use hydra_account/core as ha
use hydra_dex/types.{ProcessMigration}
use mocktail.{
  complete, mock_tx_hash, mocktail_tx, ref_tx_in, ref_tx_in_inline_datum,
  required_signer_hash, tx_in, tx_in_inline_datum, tx_out, tx_out_inline_datum,
}
use tests/utils.{
  mock_account, mock_account_2, mock_dex_order_book_address,
  mock_dex_order_book_token, mock_hydra_account, mock_hydra_account_address,
  mock_hydra_lovelace, mock_migrated_user_account,
  mock_migration_dex_order_book_datum, mock_new_hydra_account_address,
  mock_operation_key, mock_user_account,
}

type MigrationTestCase {
  is_operation_key_signed: Bool,
  is_datum_migrated: Bool,
  is_value_preserved: Bool,
  is_no_other_old_script_inputs: Bool,
  is_no_new_script_inputs: Bool,
}

fn mock_migration_tx(test_case: MigrationTestCase) -> Transaction {
  let MigrationTestCase {
    is_operation_key_signed,
    is_datum_migrated,
    is_value_preserved,
    is_no_other_old_script_inputs,
    is_no_new_script_inputs,
  } = test_case

  let input_value = mock_hydra_lovelace(1_000_000_000)
  let output_value =
    if is_value_preserved {
      mock_hydra_lovelace(1_000_000_000)
    } else {
      mock_hydra_lovelace(500_000_000)
    }

  let output_datum =
    if is_datum_migrated {
      mock_migrated_user_account(mock_account)
    } else {
      mock_user_account(mock_account)
    }

  mocktail_tx()
    |> ref_tx_in(
        True,
        mock_tx_hash(1),
        0,
        from_asset(mock_dex_order_book_token, "", 1),
        mock_dex_order_book_address,
      )
    |> ref_tx_in_inline_datum(True, mock_migration_dex_order_book_datum)
    |> tx_in(True, mock_tx_hash(0), 0, input_value, mock_hydra_account_address)
    |> tx_in_inline_datum(True, mock_user_account(mock_account))
    |> tx_in(
        !is_no_other_old_script_inputs,
        mock_tx_hash(0),
        1,
        mock_hydra_lovelace(500_000_000),
        mock_hydra_account_address,
      )
    |> tx_in_inline_datum(
        !is_no_other_old_script_inputs,
        mock_user_account(mock_account_2),
      )
    |> tx_in(
        !is_no_new_script_inputs,
        mock_tx_hash(0),
        2,
        mock_hydra_lovelace(500_000_000),
        mock_new_hydra_account_address,
      )
    |> tx_in_inline_datum(
        !is_no_new_script_inputs,
        mock_migrated_user_account(mock_account_2),
      )
    |> tx_out(True, mock_new_hydra_account_address, output_value)
    |> tx_out_inline_datum(True, output_datum)
    |> required_signer_hash(is_operation_key_signed, mock_operation_key)
    |> complete()
}

fn default_test_case() -> MigrationTestCase {
  MigrationTestCase {
    is_operation_key_signed: True,
    is_datum_migrated: True,
    is_value_preserved: True,
    is_no_other_old_script_inputs: True,
    is_no_new_script_inputs: True,
  }
}

test s8_wm_success() {
  let tx = mock_migration_tx(default_test_case())

  ha.hydra_account.withdraw(
    mock_dex_order_book_token,
    ProcessMigration { account: mock_user_account(mock_account) },
    Script(mock_hydra_account),
    tx,
  )
}

test s8_wm_failed_without_operation_key_signed() {
  let tx =
    mock_migration_tx(
      MigrationTestCase {
        ..default_test_case(),
        is_operation_key_signed: False,
      },
    )

  !ha.hydra_account.withdraw(
    mock_dex_order_book_token,
    ProcessMigration { account: mock_user_account(mock_account) },
    Script(mock_hydra_account),
    tx,
  )
}

test s8_wm_failed_without_datum_migrated() {
  let tx =
    mock_migration_tx(
      MigrationTestCase { ..default_test_case(), is_datum_migrated: False },
    )

  !ha.hydra_account.withdraw(
    mock_dex_order_book_token,
    ProcessMigration { account: mock_user_account(mock_account) },
    Script(mock_hydra_account),
    tx,
  )
}

test s8_wm_failed_without_value_preserved() {
  let tx =
    mock_migration_tx(
      MigrationTestCase { ..default_test_case(), is_value_preserved: False },
    )

  !ha.hydra_account.withdraw(
    mock_dex_order_book_token,
    ProcessMigration { account: mock_user_account(mock_account) },
    Script(mock_hydra_account),
    tx,
  )
}

test s8_wm_failed_with_other_old_script_inputs() {
  let tx =
    mock_migration_tx(
      MigrationTestCase {
        ..default_test_case(),
        is_no_other_old_script_inputs: False,
      },
    )

  !ha.hydra_account.withdraw(
    mock_dex_order_book_token,
    ProcessMigration { account: mock_user_account(mock_account) },
    Script(mock_hydra_account),
    tx,
  )
}

test s8_wm_failed_with_new_script_inputs() {
  let tx =
    mock_migration_tx(
      MigrationTestCase {
        ..default_test_case(),
        is_no_new_script_inputs: False,
      },
    )

  !ha.hydra_account.withdraw(
    mock_dex_order_book_token,
    ProcessMigration { account: mock_user_account(mock_account) },
    Script(mock_hydra_account),
    tx,
  )
}
