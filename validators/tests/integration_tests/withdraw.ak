use aiken/merkle_patricia_forestry.{Branch}
use app_vault/app_withdrawal
use app_vault/spend as app_vault_spend
use cardano/address.{Address, Script}
use cardano/assets.{add, from_asset, from_lovelace, merge, negate}
use cardano/transaction.{Transaction}
use hydra_dex/types.{
  DexAccountBalanceDatum, EmergencyWithdrawalRequestDatum, MPFUpdate,
  ProcessAppWithdrawal, UserSpotAccount,
}
use hydra_dex/utils.{to_mvalue}
use mocktail.{
  complete, invalid_before, mint, mock_tx_hash, mock_utxo_ref, mocktail_tx,
  ref_tx_in, ref_tx_in_inline_datum, required_signer_hash, script_withdrawal,
  tx_in, tx_in_inline_datum, tx_out, tx_out_inline_datum,
}
use mocktail/virgin_address
use tests/utils.{
  mock_account, mock_account_master_key_hash, mock_app_vault_address,
  mock_app_withdrawal, mock_dex_account_balance_address,
  mock_dex_account_balance_token, mock_emergency_withdrawal_request_address,
  mock_emergency_withdrawal_request_token, mock_input_oracle_datum,
  mock_operation_key, mock_oracle_address, mock_oracle_nft,
} as test_utils

type AppWithdrawalTestCase {
  is_operation_key_signed: Bool,
  is_single_dex_account_balance_input: Bool,
  is_single_dex_account_balance_output: Bool,
  is_merkle_tree_udpated: Bool,
  is_value_unlocked_correct: Bool,
  is_withdrawal_amount_sent_to_user: Bool,
  is_emergency_token_burnt: Bool,
  is_emergency_withdraw: Bool,
  is_emergency_time_passed: Bool,
  is_user_signed: Bool,
  is_app_withdrawal_auth_credential_attached: Bool,
}

fn mock_process_withdrawal_tx(
  test_case: AppWithdrawalTestCase,
) -> (Transaction, ProcessAppWithdrawal) {
  let AppWithdrawalTestCase {
    is_operation_key_signed,
    is_single_dex_account_balance_input,
    is_single_dex_account_balance_output,
    is_merkle_tree_udpated,
    is_value_unlocked_correct,
    is_withdrawal_amount_sent_to_user,
    is_emergency_token_burnt,
    is_emergency_withdraw,
    is_emergency_time_passed,
    is_user_signed,
    is_app_withdrawal_auth_credential_attached,
  } = test_case

  // MPF
  let old_root =
    #"c30c594b7188370e1995e5cf31d319f386d386d967f2987aa56a0c542f2ef076"
  let new_root =
    if is_merkle_tree_udpated {
      #"d13dbd6ff7b335876e3d6812f26649dc13592b3cd91b38623f95da458a835030"
    } else {
      old_root
    }
  let withdrawal_amount = from_asset("", "", 500_000_000)

  let proof =
    MPFUpdate {
      from: #"a240a1401a3b9aca00581c5066154a102ee037390c5236f78db23239b49c5748d3d349f3ccf04ba144555344581a3b9aca00",
      to: #"a240a1401a1dcd6500581c5066154a102ee037390c5236f78db23239b49c5748d3d349f3ccf04ba144555344581a3b9aca00",
      to_proof: [
        Branch {
          skip: 0,
          neighbors: #"9543c86b0bb9781a8d503bc087408469b50a3d3e1f7f4b0554dc813ae14c086185c09af929492a871e4fae32d9d5c36e352471cd659bcdb61de08f1722acc3b10eb923b0cbd24df54401d998531feead35a47a99f4deed205de4af81120f97610000000000000000000000000000000000000000000000000000000000000000",
        },
      ],
    }

  let dex_account_balance_value =
    from_lovelace(2_000_000) |> add(mock_dex_account_balance_token, "", 1)

  let mock_tx =
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
          2,
          dex_account_balance_value,
          mock_dex_account_balance_address,
        )
      |> tx_in_inline_datum(
          True,
          DexAccountBalanceDatum { account_balance_merkle_root: old_root },
        )
      |> tx_out(
          True,
          mock_dex_account_balance_address,
          dex_account_balance_value,
        )
      |> tx_out_inline_datum(
          True,
          DexAccountBalanceDatum { account_balance_merkle_root: new_root },
        )
      |> tx_in(
          True,
          mock_tx_hash(0),
          3,
          withdrawal_amount |> add("", "", 1_000_000),
          mock_app_vault_address,
        )
      |> tx_in(
          True,
          mock_tx_hash(0),
          3,
          from_lovelace(3_000_000),
          mock_app_vault_address,
        )
      |> tx_out(True, mock_app_vault_address, from_lovelace(4_000_000))
      |> tx_out(
          is_withdrawal_amount_sent_to_user,
          Address {
            payment_credential: mock_account.master_key,
            stake_credential: None,
          },
          from_lovelace(1_000_000) |> negate() |> merge(withdrawal_amount),
        )
      |> tx_out(
          True,
          Address {
            payment_credential: virgin_address.mock_verfication_key_credential(
              999,
            ),
            stake_credential: None,
          },
          from_lovelace(1_000_000),
        )
      |> script_withdrawal(
          is_app_withdrawal_auth_credential_attached,
          mock_app_withdrawal,
          0,
        )
      |> required_signer_hash(is_operation_key_signed, mock_operation_key)
      // Emergency withdraw
      |> mint(
          is_emergency_token_burnt,
          -1,
          mock_emergency_withdrawal_request_token,
          "",
        )
      |> tx_in(
          is_emergency_withdraw,
          mock_tx_hash(1),
          0,
          from_asset(mock_emergency_withdrawal_request_token, "", 1),
          mock_emergency_withdrawal_request_address,
        )
      |> tx_in_inline_datum(
          is_emergency_withdraw,
          EmergencyWithdrawalRequestDatum {
            account: UserSpotAccount { account: mock_account },
            amount: withdrawal_amount |> to_mvalue(),
            timestamp: 100,
          },
        )
      |> invalid_before(
          is_emergency_withdraw && is_emergency_time_passed,
          100 + 86401,
        )
      |> required_signer_hash(
          is_emergency_withdraw && is_user_signed,
          mock_account_master_key_hash,
        )
      // Failing cases
      |> tx_in(
          !is_value_unlocked_correct,
          mock_tx_hash(0),
          3,
          from_lovelace(5_000_000),
          mock_app_vault_address,
        )
      |> tx_out(
          !is_value_unlocked_correct,
          mock_app_vault_address,
          from_lovelace(4_000_000),
        )
      |> tx_in(
          !is_single_dex_account_balance_input,
          mock_tx_hash(0),
          2,
          dex_account_balance_value,
          mock_dex_account_balance_address,
        )
      |> tx_in_inline_datum(
          !is_single_dex_account_balance_input,
          DexAccountBalanceDatum { account_balance_merkle_root: old_root },
        )
      |> tx_out(
          !is_single_dex_account_balance_output,
          mock_dex_account_balance_address,
          dex_account_balance_value,
        )
      |> tx_out_inline_datum(
          !is_single_dex_account_balance_output,
          DexAccountBalanceDatum { account_balance_merkle_root: new_root },
        )
      |> complete()

  (
    mock_tx,
    ProcessAppWithdrawal {
      account: UserSpotAccount { account: mock_account },
      amount: withdrawal_amount |> to_mvalue(),
      mpf_action: proof,
    },
  )
}

fn check_all_scripts(test_case: AppWithdrawalTestCase) {
  let (tx, redeemer) = mock_process_withdrawal_tx(test_case)

  let withdraw =
    app_withdrawal.app_withdrawal.withdraw(
      mock_oracle_nft,
      redeemer,
      Script(""),
      tx,
    )
  let vault =
    app_vault_spend.app_vault.spend(
      mock_oracle_nft,
      None,
      Void,
      mock_utxo_ref(0, 0),
      tx,
    )
  withdraw? && vault?
}

test it_w_success() {
  let test_case =
    AppWithdrawalTestCase {
      is_operation_key_signed: True,
      is_single_dex_account_balance_input: True,
      is_single_dex_account_balance_output: True,
      is_merkle_tree_udpated: True,
      is_value_unlocked_correct: True,
      is_withdrawal_amount_sent_to_user: True,
      is_emergency_token_burnt: False,
      is_emergency_withdraw: False,
      is_emergency_time_passed: False,
      is_user_signed: False,
      is_app_withdrawal_auth_credential_attached: True,
    }

  check_all_scripts(test_case)
}

test it_w_failed_without_operation_key_signed() {
  let test_case =
    AppWithdrawalTestCase {
      is_operation_key_signed: False,
      is_single_dex_account_balance_input: True,
      is_single_dex_account_balance_output: True,
      is_merkle_tree_udpated: True,
      is_value_unlocked_correct: True,
      is_withdrawal_amount_sent_to_user: True,
      is_emergency_token_burnt: False,
      is_emergency_withdraw: False,
      is_emergency_time_passed: False,
      is_user_signed: False,
      is_app_withdrawal_auth_credential_attached: True,
    }

  !check_all_scripts(test_case)
}

test it_w_failed_with_multiple_dex_account_balance_input() {
  let test_case =
    AppWithdrawalTestCase {
      is_operation_key_signed: True,
      is_single_dex_account_balance_input: False,
      is_single_dex_account_balance_output: True,
      is_merkle_tree_udpated: True,
      is_value_unlocked_correct: True,
      is_withdrawal_amount_sent_to_user: True,
      is_emergency_token_burnt: False,
      is_emergency_withdraw: False,
      is_emergency_time_passed: False,
      is_user_signed: False,
      is_app_withdrawal_auth_credential_attached: True,
    }

  !check_all_scripts(test_case)
}

test it_w_failed_with_multiple_dex_account_balance_output() {
  let test_case =
    AppWithdrawalTestCase {
      is_operation_key_signed: True,
      is_single_dex_account_balance_input: True,
      is_single_dex_account_balance_output: False,
      is_merkle_tree_udpated: True,
      is_value_unlocked_correct: True,
      is_withdrawal_amount_sent_to_user: True,
      is_emergency_token_burnt: False,
      is_emergency_withdraw: False,
      is_emergency_time_passed: False,
      is_user_signed: False,
      is_app_withdrawal_auth_credential_attached: True,
    }

  !check_all_scripts(test_case)
}

test it_w_failed_without_merkle_updated() {
  let test_case =
    AppWithdrawalTestCase {
      is_operation_key_signed: True,
      is_single_dex_account_balance_input: True,
      is_single_dex_account_balance_output: True,
      is_merkle_tree_udpated: False,
      is_value_unlocked_correct: True,
      is_withdrawal_amount_sent_to_user: True,
      is_emergency_token_burnt: False,
      is_emergency_withdraw: False,
      is_emergency_time_passed: False,
      is_user_signed: False,
      is_app_withdrawal_auth_credential_attached: True,
    }

  !check_all_scripts(test_case)
}

test it_w_failed_with_excessive_value_unlocked() {
  let test_case =
    AppWithdrawalTestCase {
      is_operation_key_signed: True,
      is_single_dex_account_balance_input: True,
      is_single_dex_account_balance_output: True,
      is_merkle_tree_udpated: True,
      is_value_unlocked_correct: False,
      is_withdrawal_amount_sent_to_user: True,
      is_emergency_token_burnt: False,
      is_emergency_withdraw: False,
      is_emergency_time_passed: False,
      is_user_signed: False,
      is_app_withdrawal_auth_credential_attached: True,
    }

  !check_all_scripts(test_case)
}

test it_w_failed_without_sufficient_amount_sent_to_users() {
  let test_case =
    AppWithdrawalTestCase {
      is_operation_key_signed: True,
      is_single_dex_account_balance_input: True,
      is_single_dex_account_balance_output: True,
      is_merkle_tree_udpated: True,
      is_value_unlocked_correct: True,
      is_withdrawal_amount_sent_to_user: False,
      is_emergency_token_burnt: False,
      is_emergency_withdraw: False,
      is_emergency_time_passed: False,
      is_user_signed: False,
      is_app_withdrawal_auth_credential_attached: True,
    }

  !check_all_scripts(test_case)
}

test it_w_failed_without_withdrawal_script() {
  let test_case =
    AppWithdrawalTestCase {
      is_operation_key_signed: True,
      is_single_dex_account_balance_input: True,
      is_single_dex_account_balance_output: True,
      is_merkle_tree_udpated: True,
      is_value_unlocked_correct: True,
      is_withdrawal_amount_sent_to_user: True,
      is_emergency_token_burnt: False,
      is_emergency_withdraw: False,
      is_emergency_time_passed: False,
      is_user_signed: False,
      is_app_withdrawal_auth_credential_attached: False,
    }

  !check_all_scripts(test_case)
}

test it_w_success_emergency_withdrawal() {
  let test_case =
    AppWithdrawalTestCase {
      is_operation_key_signed: False,
      is_single_dex_account_balance_input: True,
      is_single_dex_account_balance_output: True,
      is_merkle_tree_udpated: True,
      is_value_unlocked_correct: True,
      is_withdrawal_amount_sent_to_user: True,
      is_emergency_token_burnt: True,
      is_emergency_withdraw: True,
      is_emergency_time_passed: True,
      is_user_signed: True,
      is_app_withdrawal_auth_credential_attached: True,
    }

  check_all_scripts(test_case)
}

test it_w_failed_emergency_withdrawal_without_token_burnt() fail {
  let test_case =
    AppWithdrawalTestCase {
      is_operation_key_signed: False,
      is_single_dex_account_balance_input: True,
      is_single_dex_account_balance_output: True,
      is_merkle_tree_udpated: True,
      is_value_unlocked_correct: True,
      is_withdrawal_amount_sent_to_user: True,
      is_emergency_token_burnt: False,
      is_emergency_withdraw: True,
      is_emergency_time_passed: True,
      is_user_signed: True,
      is_app_withdrawal_auth_credential_attached: True,
    }

  check_all_scripts(test_case)
}

test it_w_failed_emergency_withdrawal_without_time_passed() {
  let test_case =
    AppWithdrawalTestCase {
      is_operation_key_signed: False,
      is_single_dex_account_balance_input: True,
      is_single_dex_account_balance_output: True,
      is_merkle_tree_udpated: True,
      is_value_unlocked_correct: True,
      is_withdrawal_amount_sent_to_user: True,
      is_emergency_token_burnt: True,
      is_emergency_withdraw: True,
      is_emergency_time_passed: False,
      is_user_signed: True,
      is_app_withdrawal_auth_credential_attached: True,
    }

  !check_all_scripts(test_case)
}

test it_w_failed_emergency_withdrawal_without_user_signature() {
  let test_case =
    AppWithdrawalTestCase {
      is_operation_key_signed: False,
      is_single_dex_account_balance_input: True,
      is_single_dex_account_balance_output: True,
      is_merkle_tree_udpated: True,
      is_value_unlocked_correct: True,
      is_withdrawal_amount_sent_to_user: True,
      is_emergency_token_burnt: True,
      is_emergency_withdraw: True,
      is_emergency_time_passed: True,
      is_user_signed: False,
      is_app_withdrawal_auth_credential_attached: True,
    }

  !check_all_scripts(test_case)
}

test it_w_failed_emergency_withdrawal_without_withdrawal_script() {
  let test_case =
    AppWithdrawalTestCase {
      is_operation_key_signed: True,
      is_single_dex_account_balance_input: True,
      is_single_dex_account_balance_output: True,
      is_merkle_tree_udpated: True,
      is_value_unlocked_correct: True,
      is_withdrawal_amount_sent_to_user: True,
      is_emergency_token_burnt: True,
      is_emergency_withdraw: True,
      is_emergency_time_passed: True,
      is_user_signed: False,
      is_app_withdrawal_auth_credential_attached: False,
    }

  !check_all_scripts(test_case)
}
