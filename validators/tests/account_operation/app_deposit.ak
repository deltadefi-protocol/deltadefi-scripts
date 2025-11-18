use account_operation/app_deposit
use cardano/address.{Script}
use cardano/assets.{add, from_asset, from_lovelace}
use cardano/transaction.{Transaction}
use hydra_dex/types.{
  AppDepositRequestDatum, DexAccountBalanceDatum, MPFUpdate, ProcessAppDeposit,
  UserSpotAccount,
}
use hydra_dex/utils.{to_mvalue}
use mocktail.{
  complete, mint, mock_tx_hash, mocktail_tx, ref_tx_in, ref_tx_in_inline_datum,
  required_signer_hash, script_withdrawal, tx_in, tx_in_inline_datum, tx_out,
  tx_out_inline_datum,
}
use tests/utils.{
  mock_account, mock_app_deposit, mock_app_deposit_request_address,
  mock_app_deposit_request_token, mock_app_vault_address,
  mock_dex_account_balance_address, mock_dex_account_balance_token,
  mock_input_oracle_datum, mock_operation_key, mock_oracle_address,
  mock_oracle_nft,
} as test_utils

type ProcessDepositTestCase {
  is_operation_key_signed: Bool,
  is_single_app_deposit_request_input: Bool,
  is_single_dex_account_balance_input: Bool,
  is_single_dex_account_balance_output: Bool,
  is_merkle_tree_udpated: Bool,
  is_intent_token_burnt: Bool,
  is_value_sent_to_vault: Bool,
}

fn mock_process_deposit_tx(
  test_case: ProcessDepositTestCase,
) -> (Transaction, ProcessAppDeposit) {
  let ProcessDepositTestCase {
    is_operation_key_signed,
    is_single_app_deposit_request_input,
    is_single_dex_account_balance_input,
    is_single_dex_account_balance_output,
    is_merkle_tree_udpated,
    is_intent_token_burnt,
    is_value_sent_to_vault,
  } = test_case

  // MPF
  let old_root =
    #"d77bbe4dd2ef95da2112cb54177b8132b4166f05493405b5fdc6c4f7e9ec8df8"
  let new_root =
    if is_merkle_tree_udpated {
      #"fc765255aa7da1b705a7703f161f9e954e53964026d4aecda93fc3d986c899b8"
    } else {
      old_root
    }
  let deposit_amount =
    from_asset("", "", 900_000_000)
      |> add(
          #"5066154a102ee037390c5236f78db23239b49c5748d3d349f3ccf04b",
          #"55534458",
          1_000_000_000,
        )
  let proof =
    MPFUpdate {
      from: #"a140a1401a05f5e100",
      to: #"a240a1401a3b9aca00581c5066154a102ee037390c5236f78db23239b49c5748d3d349f3ccf04ba144555344581a3b9aca00",
      to_proof: [],
    }

  let deposit_datum =
    AppDepositRequestDatum {
      account: UserSpotAccount { account: mock_account },
      amount: deposit_amount |> to_mvalue(),
    }

  let app_deposit_request_value =
    deposit_amount |> add(mock_app_deposit_request_token, "", 1)
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
          1,
          app_deposit_request_value,
          mock_app_deposit_request_address,
        )
      |> tx_in_inline_datum(True, deposit_datum)
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
      |> tx_out(
          True,
          mock_app_vault_address,
          if is_value_sent_to_vault {
            deposit_amount
          } else {
            from_lovelace(2_000_000)
          },
        )
      |> script_withdrawal(True, mock_app_deposit, 0)
      |> mint(is_intent_token_burnt, -1, mock_app_deposit_request_token, "")
      |> required_signer_hash(is_operation_key_signed, mock_operation_key)
      // Failing cases
      |> tx_in(
          !is_single_app_deposit_request_input,
          mock_tx_hash(0),
          1,
          app_deposit_request_value,
          mock_app_deposit_request_address,
        )
      |> tx_in_inline_datum(!is_single_app_deposit_request_input, deposit_datum)
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

  (mock_tx, ProcessAppDeposit { mpf_action: proof })
}

test s1_wad_success() {
  let test_case =
    ProcessDepositTestCase {
      is_operation_key_signed: True,
      is_single_app_deposit_request_input: True,
      is_single_dex_account_balance_input: True,
      is_single_dex_account_balance_output: True,
      is_merkle_tree_udpated: True,
      is_intent_token_burnt: True,
      is_value_sent_to_vault: True,
    }

  let (tx, redeemer) = mock_process_deposit_tx(test_case)

  app_deposit.app_deposit.withdraw(mock_oracle_nft, redeemer, Script(""), tx)
}

test s1_wad_failed_without_operation_key_signed() {
  let test_case =
    ProcessDepositTestCase {
      is_operation_key_signed: False,
      is_single_app_deposit_request_input: True,
      is_single_dex_account_balance_input: True,
      is_single_dex_account_balance_output: True,
      is_merkle_tree_udpated: True,
      is_intent_token_burnt: True,
      is_value_sent_to_vault: True,
    }

  let (tx, redeemer) = mock_process_deposit_tx(test_case)

  !app_deposit.app_deposit.withdraw(mock_oracle_nft, redeemer, Script(""), tx)
}

test s1_wad_failed_with_multiple_app_deposit_requests() fail {
  let test_case =
    ProcessDepositTestCase {
      is_operation_key_signed: True,
      is_single_app_deposit_request_input: False,
      is_single_dex_account_balance_input: True,
      is_single_dex_account_balance_output: True,
      is_merkle_tree_udpated: True,
      is_intent_token_burnt: True,
      is_value_sent_to_vault: True,
    }

  let (tx, redeemer) = mock_process_deposit_tx(test_case)

  !app_deposit.app_deposit.withdraw(mock_oracle_nft, redeemer, Script(""), tx)
}

test s1_wad_failed_with_multiple_dex_account_balance_input() {
  let test_case =
    ProcessDepositTestCase {
      is_operation_key_signed: True,
      is_single_app_deposit_request_input: True,
      is_single_dex_account_balance_input: False,
      is_single_dex_account_balance_output: True,
      is_merkle_tree_udpated: True,
      is_intent_token_burnt: True,
      is_value_sent_to_vault: True,
    }

  let (tx, redeemer) = mock_process_deposit_tx(test_case)

  !app_deposit.app_deposit.withdraw(mock_oracle_nft, redeemer, Script(""), tx)
}

test s1_wad_failed_with_multiple_dex_account_balance_output() {
  let test_case =
    ProcessDepositTestCase {
      is_operation_key_signed: True,
      is_single_app_deposit_request_input: True,
      is_single_dex_account_balance_input: True,
      is_single_dex_account_balance_output: False,
      is_merkle_tree_udpated: True,
      is_intent_token_burnt: True,
      is_value_sent_to_vault: True,
    }

  let (tx, redeemer) = mock_process_deposit_tx(test_case)

  !app_deposit.app_deposit.withdraw(mock_oracle_nft, redeemer, Script(""), tx)
}

test s1_wad_failed_without_updating_merkle() {
  let test_case =
    ProcessDepositTestCase {
      is_operation_key_signed: True,
      is_single_app_deposit_request_input: True,
      is_single_dex_account_balance_input: True,
      is_single_dex_account_balance_output: True,
      is_merkle_tree_udpated: False,
      is_intent_token_burnt: True,
      is_value_sent_to_vault: True,
    }

  let (tx, redeemer) = mock_process_deposit_tx(test_case)

  !app_deposit.app_deposit.withdraw(mock_oracle_nft, redeemer, Script(""), tx)
}

test s1_wad_failed_without_intent_token_burnt() {
  let test_case =
    ProcessDepositTestCase {
      is_operation_key_signed: True,
      is_single_app_deposit_request_input: True,
      is_single_dex_account_balance_input: True,
      is_single_dex_account_balance_output: True,
      is_merkle_tree_udpated: True,
      is_intent_token_burnt: False,
      is_value_sent_to_vault: True,
    }

  let (tx, redeemer) = mock_process_deposit_tx(test_case)

  !app_deposit.app_deposit.withdraw(mock_oracle_nft, redeemer, Script(""), tx)
}

test s1_wad_failed_without_sending_value_to_vault() {
  let test_case =
    ProcessDepositTestCase {
      is_operation_key_signed: True,
      is_single_app_deposit_request_input: True,
      is_single_dex_account_balance_input: True,
      is_single_dex_account_balance_output: True,
      is_merkle_tree_udpated: True,
      is_intent_token_burnt: True,
      is_value_sent_to_vault: False,
    }

  let (tx, redeemer) = mock_process_deposit_tx(test_case)

  !app_deposit.app_deposit.withdraw(mock_oracle_nft, redeemer, Script(""), tx)
}
