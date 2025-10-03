use aiken/merkle_patricia_forestry as mpf
use cardano/assets.{add, from_asset}
use cardano/transaction.{Transaction}
use dex_account_balance/spend as dex_account_balance
use hydra_dex/types.{
  DexAccountBalanceDatum, DexAccountBalanceRemoveRegistry,
  DexAccountBalanceSpamPreventionWithdraw,
}
use mocktail.{
  complete, mint, mock_policy_id, mock_script_address, mock_tx_hash,
  mock_utxo_ref, mocktail_tx, ref_tx_in, ref_tx_in_inline_datum,
  required_signer_hash, tx_in, tx_in_inline_datum, tx_out,
}
use tests/utils.{
  mock_dex_account_balance_address, mock_dex_account_balance_token,
  mock_dex_order_book_token, mock_input_oracle_datum, mock_operation_key,
  mock_oracle_address, mock_oracle_nft, mock_withdrawal_script_hashes,
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
    from_asset(mock_dex_account_balance_token, "", 1) |> add("", "", 2_000_000)

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
        mock_dex_account_balance_address,
      )
    |> tx_out(
        !is_no_auth_token_inputed,
        mock_dex_account_balance_address,
        auth_value,
      )
    |> required_signer_hash(is_operation_key_signed, mock_operation_key)
    |> complete()
}

test s5_spend_success_spam_prevention_withdraw() {
  let tx =
    mock_spam_prevention_withdrawal_tx(
      SpamPreventionWithdrawTestCase {
        is_app_oracle_inputed: True,
        is_app_oracle_format_correct: True,
        is_no_auth_token_inputed: True,
        is_operation_key_signed: True,
      },
    )

  dex_account_balance.dex_account_balance.spend(
    mock_oracle_nft,
    mock_dex_order_book_token,
    None,
    DexAccountBalanceSpamPreventionWithdraw,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s5_spend_fail_spam_prevention_withdraw_with_no_app_oracle_inputed() fail {
  let tx =
    mock_spam_prevention_withdrawal_tx(
      SpamPreventionWithdrawTestCase {
        is_app_oracle_inputed: False,
        is_app_oracle_format_correct: True,
        is_no_auth_token_inputed: True,
        is_operation_key_signed: True,
      },
    )

  !dex_account_balance.dex_account_balance.spend(
    mock_oracle_nft,
    mock_dex_order_book_token,
    None,
    DexAccountBalanceSpamPreventionWithdraw,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s5_spend_fail_spam_prevention_withdraw_with_incorrect_app_oracle_inputed() fail {
  let tx =
    mock_spam_prevention_withdrawal_tx(
      SpamPreventionWithdrawTestCase {
        is_app_oracle_inputed: True,
        is_app_oracle_format_correct: False,
        is_no_auth_token_inputed: True,
        is_operation_key_signed: True,
      },
    )

  !dex_account_balance.dex_account_balance.spend(
    mock_oracle_nft,
    mock_dex_order_book_token,
    None,
    DexAccountBalanceSpamPreventionWithdraw,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s5_spend_fail_spam_prevention_withdraw_with_auth_input() {
  let tx =
    mock_spam_prevention_withdrawal_tx(
      SpamPreventionWithdrawTestCase {
        is_app_oracle_inputed: True,
        is_app_oracle_format_correct: True,
        is_no_auth_token_inputed: False,
        is_operation_key_signed: True,
      },
    )

  !dex_account_balance.dex_account_balance.spend(
    mock_oracle_nft,
    mock_dex_order_book_token,
    None,
    DexAccountBalanceSpamPreventionWithdraw,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s5_spend_fail_spam_prevention_withdraw_with_no_op_key_sign() {
  let tx =
    mock_spam_prevention_withdrawal_tx(
      SpamPreventionWithdrawTestCase {
        is_app_oracle_inputed: True,
        is_app_oracle_format_correct: True,
        is_no_auth_token_inputed: True,
        is_operation_key_signed: False,
      },
    )

  !dex_account_balance.dex_account_balance.spend(
    mock_oracle_nft,
    mock_dex_order_book_token,
    None,
    DexAccountBalanceSpamPreventionWithdraw,
    mock_utxo_ref(0, 0),
    tx,
  )
}

type RemoveRegistryTestCase {
  is_only_account_balance_input: Bool,
  is_empty_root: Bool,
  is_auth_token_burnt: Bool,
  is_operation_key_signed: Bool,
}

fn mock_remove_registry_tx(test_case: RemoveRegistryTestCase) -> Transaction {
  let RemoveRegistryTestCase {
    is_only_account_balance_input,
    is_empty_root,
    is_auth_token_burnt,
    is_operation_key_signed,
  } = test_case

  let auth_value =
    from_asset(mock_dex_account_balance_token, "", 1) |> add("", "", 2_000_000)

  let datum =
    DexAccountBalanceDatum {
      account_balance_merkle_root: if is_empty_root {
        mpf.root(mpf.empty)
      } else {
        "0000002412421"
      },
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
        1,
        auth_value,
        mock_dex_account_balance_address,
      )
    |> tx_in_inline_datum(True, datum)
    |> tx_in(
        !is_only_account_balance_input,
        mock_tx_hash(0),
        1,
        auth_value,
        mock_dex_account_balance_address,
      )
    |> tx_in_inline_datum(!is_only_account_balance_input, datum)
    |> mint(is_auth_token_burnt, -1, mock_dex_account_balance_token, "")
    |> required_signer_hash(is_operation_key_signed, mock_operation_key)
    |> complete()
}

test s5_spend_success_remove_registry() {
  let tx =
    mock_remove_registry_tx(
      RemoveRegistryTestCase {
        is_only_account_balance_input: True,
        is_empty_root: True,
        is_auth_token_burnt: True,
        is_operation_key_signed: True,
      },
    )

  dex_account_balance.dex_account_balance.spend(
    mock_oracle_nft,
    mock_dex_order_book_token,
    None,
    DexAccountBalanceRemoveRegistry,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s5_spend_fail_remove_registry_with_multiple_account_balance_input() fail {
  let tx =
    mock_remove_registry_tx(
      RemoveRegistryTestCase {
        is_only_account_balance_input: False,
        is_empty_root: True,
        is_auth_token_burnt: True,
        is_operation_key_signed: True,
      },
    )

  dex_account_balance.dex_account_balance.spend(
    mock_oracle_nft,
    mock_dex_order_book_token,
    None,
    DexAccountBalanceRemoveRegistry,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s5_spend_fail_remove_registry_with_non_empty_root() {
  let tx =
    mock_remove_registry_tx(
      RemoveRegistryTestCase {
        is_only_account_balance_input: True,
        is_empty_root: False,
        is_auth_token_burnt: True,
        is_operation_key_signed: True,
      },
    )

  !dex_account_balance.dex_account_balance.spend(
    mock_oracle_nft,
    mock_dex_order_book_token,
    None,
    DexAccountBalanceRemoveRegistry,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s5_spend_fail_remove_registry_with_no_auth_token_burnt() fail {
  let tx =
    mock_remove_registry_tx(
      RemoveRegistryTestCase {
        is_only_account_balance_input: True,
        is_empty_root: True,
        is_auth_token_burnt: False,
        is_operation_key_signed: True,
      },
    )

  dex_account_balance.dex_account_balance.spend(
    mock_oracle_nft,
    mock_dex_order_book_token,
    None,
    DexAccountBalanceRemoveRegistry,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test s5_spend_fail_remove_registry_with_no_op_key_sign() {
  let tx =
    mock_remove_registry_tx(
      RemoveRegistryTestCase {
        is_only_account_balance_input: True,
        is_empty_root: True,
        is_auth_token_burnt: True,
        is_operation_key_signed: False,
      },
    )

  !dex_account_balance.dex_account_balance.spend(
    mock_oracle_nft,
    mock_dex_order_book_token,
    None,
    DexAccountBalanceRemoveRegistry,
    mock_utxo_ref(0, 0),
    tx,
  )
}
