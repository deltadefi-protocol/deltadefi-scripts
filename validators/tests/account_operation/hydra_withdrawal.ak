use account_operation/hydra_withdrawal
use cardano/address.{Script}
use cardano/assets.{add, from_asset, from_lovelace, merge, negate}
use cardano/transaction.{Transaction}
use hydra_dex/types.{
  DexAccountBalanceDatum, HydraAccountBalanceDatum, MPFUpdate,
  ProcessHydraWithdrawal, UserSpotAccount, WithdrawalIntent,
}
use mocktail.{
  complete, mint, mock_tx_hash, mocktail_tx, ref_tx_in, ref_tx_in_inline_datum,
  required_signer_hash, script_withdrawal, tx_in, tx_in_inline_datum, tx_out,
  tx_out_inline_datum,
}
use tests/utils.{
  mock_account, mock_dex_account_balance_address, mock_dex_account_balance_token,
  mock_dex_order_book_address, mock_dex_order_book_datum,
  mock_dex_order_book_token, mock_hydra_account_balance_address,
  mock_hydra_account_balance_token, mock_hydra_user_intent_address,
  mock_hydra_user_intent_token, mock_hydra_withdrawal, mock_operation_key,
  to_mvalue,
}

type HydraWithdrawalTestCase {
  is_operation_key_signed: Bool,
  is_single_dex_account_balance_input: Bool,
  is_single_dex_account_balance_output: Bool,
  is_merkle_tree_udpated: Bool,
  is_account_balance_updated: Bool,
  is_intent_token_burnt: Bool,
}

fn mock_hydra_withdrawal_tx(
  test_case: HydraWithdrawalTestCase,
) -> (Transaction, ProcessHydraWithdrawal) {
  let HydraWithdrawalTestCase {
    is_operation_key_signed,
    is_single_dex_account_balance_input,
    is_single_dex_account_balance_output,
    is_merkle_tree_udpated,
    is_account_balance_updated,
    is_intent_token_burnt,
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
  let withdrawal_amount =
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

  let hydra_account_balance_start = from_lovelace(10_000_000)
  let hydra_account_balance_end =
    if is_account_balance_updated {
      withdrawal_amount |> negate() |> merge(hydra_account_balance_start)
    } else {
      hydra_account_balance_start
    }
  let dex_account_balance_value =
    from_lovelace(2_000_000) |> add(mock_dex_account_balance_token, "", 1)

  let mock_tx =
    mocktail_tx()
      |> ref_tx_in(
          True,
          mock_tx_hash(1),
          0,
          from_asset(mock_dex_order_book_token, "", 1),
          mock_dex_order_book_address,
        )
      |> ref_tx_in_inline_datum(True, mock_dex_order_book_datum)
      |> tx_in(
          True,
          mock_tx_hash(0),
          0,
          from_asset(mock_hydra_user_intent_token, "", 1),
          mock_hydra_user_intent_address,
        )
      |> tx_in_inline_datum(
          True,
          WithdrawalIntent {
            account: UserSpotAccount { account: mock_account },
            amount: withdrawal_amount |> to_mvalue(),
          },
        )
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
          1,
          from_asset(mock_hydra_account_balance_token, "", 1),
          mock_hydra_account_balance_address,
        )
      |> tx_in_inline_datum(
          True,
          HydraAccountBalanceDatum {
            account: UserSpotAccount { account: mock_account },
            balance: hydra_account_balance_start |> to_mvalue(),
          },
        )
      |> tx_out(
          True,
          mock_hydra_account_balance_address,
          from_asset(mock_hydra_account_balance_token, "", 1),
        )
      |> tx_out_inline_datum(
          True,
          HydraAccountBalanceDatum {
            account: UserSpotAccount { account: mock_account },
            balance: hydra_account_balance_end
              |> to_mvalue(),
          },
        )
      |> script_withdrawal(True, mock_hydra_withdrawal, 0)
      |> mint(is_intent_token_burnt, -1, mock_hydra_user_intent_token, "")
      |> required_signer_hash(is_operation_key_signed, mock_operation_key)
      // Failing cases
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

  (mock_tx, ProcessHydraWithdrawal { mpf_action: proof })
}

test s1_whw_success() {
  let test_case =
    HydraWithdrawalTestCase {
      is_operation_key_signed: True,
      is_single_dex_account_balance_input: True,
      is_single_dex_account_balance_output: True,
      is_merkle_tree_udpated: True,
      is_account_balance_updated: True,
      is_intent_token_burnt: True,
    }

  let (tx, redeemer) = mock_hydra_withdrawal_tx(test_case)

  hydra_withdrawal.hydra_withdrawal.withdraw(
    mock_dex_order_book_token,
    redeemer,
    Script(""),
    tx,
  )
}

test s1_whw_failed_without_operation_key_signed() {
  let test_case =
    HydraWithdrawalTestCase {
      is_operation_key_signed: False,
      is_single_dex_account_balance_input: True,
      is_single_dex_account_balance_output: True,
      is_merkle_tree_udpated: True,
      is_account_balance_updated: True,
      is_intent_token_burnt: True,
    }

  let (tx, redeemer) = mock_hydra_withdrawal_tx(test_case)

  !hydra_withdrawal.hydra_withdrawal.withdraw(
    mock_dex_order_book_token,
    redeemer,
    Script(""),
    tx,
  )
}

test s1_whw_failed_with_multiple_dex_account_balance_input() {
  let test_case =
    HydraWithdrawalTestCase {
      is_operation_key_signed: True,
      is_single_dex_account_balance_input: False,
      is_single_dex_account_balance_output: True,
      is_merkle_tree_udpated: True,
      is_account_balance_updated: True,
      is_intent_token_burnt: True,
    }

  let (tx, redeemer) = mock_hydra_withdrawal_tx(test_case)

  !hydra_withdrawal.hydra_withdrawal.withdraw(
    mock_dex_order_book_token,
    redeemer,
    Script(""),
    tx,
  )
}

test s1_whw_failed_with_multiple_dex_account_balance_output() {
  let test_case =
    HydraWithdrawalTestCase {
      is_operation_key_signed: True,
      is_single_dex_account_balance_input: True,
      is_single_dex_account_balance_output: False,
      is_merkle_tree_udpated: True,
      is_account_balance_updated: True,
      is_intent_token_burnt: True,
    }

  let (tx, redeemer) = mock_hydra_withdrawal_tx(test_case)

  !hydra_withdrawal.hydra_withdrawal.withdraw(
    mock_dex_order_book_token,
    redeemer,
    Script(""),
    tx,
  )
}

test s1_whw_failed_without_merkle_root_updated() {
  let test_case =
    HydraWithdrawalTestCase {
      is_operation_key_signed: True,
      is_single_dex_account_balance_input: True,
      is_single_dex_account_balance_output: True,
      is_merkle_tree_udpated: False,
      is_account_balance_updated: True,
      is_intent_token_burnt: True,
    }

  let (tx, redeemer) = mock_hydra_withdrawal_tx(test_case)

  !hydra_withdrawal.hydra_withdrawal.withdraw(
    mock_dex_order_book_token,
    redeemer,
    Script(""),
    tx,
  )
}

test s1_whw_failed_without_account_balance_updated() {
  let test_case =
    HydraWithdrawalTestCase {
      is_operation_key_signed: True,
      is_single_dex_account_balance_input: True,
      is_single_dex_account_balance_output: True,
      is_merkle_tree_udpated: True,
      is_account_balance_updated: False,
      is_intent_token_burnt: True,
    }

  let (tx, redeemer) = mock_hydra_withdrawal_tx(test_case)

  !hydra_withdrawal.hydra_withdrawal.withdraw(
    mock_dex_order_book_token,
    redeemer,
    Script(""),
    tx,
  )
}

test s1_whw_failed_without_intent_token_burnt() {
  let test_case =
    HydraWithdrawalTestCase {
      is_operation_key_signed: True,
      is_single_dex_account_balance_input: True,
      is_single_dex_account_balance_output: True,
      is_merkle_tree_udpated: True,
      is_account_balance_updated: True,
      is_intent_token_burnt: False,
    }

  let (tx, redeemer) = mock_hydra_withdrawal_tx(test_case)

  !hydra_withdrawal.hydra_withdrawal.withdraw(
    mock_dex_order_book_token,
    redeemer,
    Script(""),
    tx,
  )
}
