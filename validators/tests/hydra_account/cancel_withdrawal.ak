use cardano/address.{Script}
use cardano/assets.{add, from_asset, from_lovelace, merge}
use cardano/transaction.{Transaction}
use hydra_account/core as ha
use hydra_dex/account_utils.{from_value_to_hydra_balance}
use hydra_dex/types.{
  CancelWithdrawalIntent, DexAccountBalanceDatum, HydraAccountOperation,
  MPFUpdate, MasterIntent, ProcessCancelWithdrawal,
}
use hydra_dex/utils.{to_mvalue}
use mocktail.{
  complete, mint, mock_tx_hash, mocktail_tx, ref_tx_in, ref_tx_in_inline_datum,
  required_signer_hash, tx_in, tx_in_inline_datum, tx_out, tx_out_inline_datum,
}
use tests/utils.{
  mock_account, mock_dex_account_balance_address, mock_dex_account_balance_token,
  mock_dex_order_book_address, mock_dex_order_book_datum,
  mock_dex_order_book_token, mock_hydra_account_address, mock_hydra_lovelace,
  mock_hydra_token_policy_id, mock_hydra_user_intent_address,
  mock_hydra_user_intent_token, mock_operation_key, mock_user_account,
} as test_utils

type TestCase {
  is_operation_key_signed: Bool,
  is_single_dex_account_balance_input: Bool,
  is_single_dex_account_balance_output: Bool,
  is_merkle_tree_udpated: Bool,
  is_account_balance_updated: Bool,
  is_intent_token_burnt: Bool,
  is_cancel_withdrawal_amount_minted: Bool,
}

fn mock_tx(test_case: TestCase) -> (Transaction, HydraAccountOperation) {
  let TestCase {
    is_operation_key_signed,
    is_single_dex_account_balance_input,
    is_single_dex_account_balance_output,
    is_merkle_tree_udpated,
    is_account_balance_updated,
    is_intent_token_burnt,
    is_cancel_withdrawal_amount_minted,
  } = test_case

  // MPF - Cancel withdrawal uses decrease operation on pending withdrawal balance
  // Account has 1B lovelace + 1B USDX pending, decreasing by 500M lovelace
  // Resulting in 500M lovelace + 1B USDX
  let old_root =
    #"79a1f8ed21bade02612f0f83f41453ee61cee7d7b797ffc84ce787717279ed0e"
  let new_root =
    if is_merkle_tree_udpated {
      #"13a67d5c7d4b6c68217d01cb569646ab08595ed9711224c6451ba834ff30de09"
    } else {
      old_root
    }
  let withdrawal_amount = from_lovelace(500_000_000)

  let proof =
    MPFUpdate {
      from: #"a240a1401a3b9aca00581c5066154a102ee037390c5236f78db23239b49c5748d3d349f3ccf04ba144555344581a3b9aca00",
      to: #"a240a1401a1dcd6500581c5066154a102ee037390c5236f78db23239b49c5748d3d349f3ccf04ba144555344581a3b9aca00",
      to_proof: [],
    }

  let hydra_account_start = mock_hydra_lovelace(10_000_000)
  let hydra_account_end =
    if is_account_balance_updated {
      withdrawal_amount
        |> from_value_to_hydra_balance(mock_hydra_token_policy_id)
        |> merge(hydra_account_start)
    } else {
      hydra_account_start
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
          MasterIntent {
            account: mock_user_account(mock_account),
            intent: CancelWithdrawalIntent {
              amount_l1: withdrawal_amount |> to_mvalue(),
            },
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
          hydra_account_start,
          mock_hydra_account_address,
        )
      |> tx_in_inline_datum(True, mock_user_account(mock_account))
      |> tx_out(True, mock_hydra_account_address, hydra_account_end)
      |> tx_out_inline_datum(True, mock_user_account(mock_account))
      |> mint(is_intent_token_burnt, -1, mock_hydra_user_intent_token, "")
      |> mint(
          is_cancel_withdrawal_amount_minted,
          500_000_000,
          mock_hydra_token_policy_id,
          "",
        )
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

  (mock_tx, ProcessCancelWithdrawal { mpf_action: proof })
}

test s8_wcw_success() {
  let test_case =
    TestCase {
      is_operation_key_signed: True,
      is_single_dex_account_balance_input: True,
      is_single_dex_account_balance_output: True,
      is_merkle_tree_udpated: True,
      is_account_balance_updated: True,
      is_intent_token_burnt: True,
      is_cancel_withdrawal_amount_minted: True,
    }

  let (tx, redeemer) = mock_tx(test_case)

  ha.hydra_account.withdraw(mock_dex_order_book_token, redeemer, Script(""), tx)
}

test s8_wcw_failed_without_operation_key_signed() {
  let test_case =
    TestCase {
      is_operation_key_signed: False,
      is_single_dex_account_balance_input: True,
      is_single_dex_account_balance_output: True,
      is_merkle_tree_udpated: True,
      is_account_balance_updated: True,
      is_intent_token_burnt: True,
      is_cancel_withdrawal_amount_minted: True,
    }

  let (tx, redeemer) = mock_tx(test_case)

  !ha.hydra_account.withdraw(
    mock_dex_order_book_token,
    redeemer,
    Script(""),
    tx,
  )
}

test s8_wcw_failed_with_multiple_dex_account_balance_input() fail {
  let test_case =
    TestCase {
      is_operation_key_signed: True,
      is_single_dex_account_balance_input: False,
      is_single_dex_account_balance_output: True,
      is_merkle_tree_udpated: True,
      is_account_balance_updated: True,
      is_intent_token_burnt: True,
      is_cancel_withdrawal_amount_minted: True,
    }

  let (tx, redeemer) = mock_tx(test_case)

  !ha.hydra_account.withdraw(
    mock_dex_order_book_token,
    redeemer,
    Script(""),
    tx,
  )
}

test s8_wcw_failed_with_multiple_dex_account_balance_output() fail {
  let test_case =
    TestCase {
      is_operation_key_signed: True,
      is_single_dex_account_balance_input: True,
      is_single_dex_account_balance_output: False,
      is_merkle_tree_udpated: True,
      is_account_balance_updated: True,
      is_intent_token_burnt: True,
      is_cancel_withdrawal_amount_minted: True,
    }

  let (tx, redeemer) = mock_tx(test_case)

  !ha.hydra_account.withdraw(
    mock_dex_order_book_token,
    redeemer,
    Script(""),
    tx,
  )
}

test s8_wcw_failed_without_merkle_root_updated() {
  let test_case =
    TestCase {
      is_operation_key_signed: True,
      is_single_dex_account_balance_input: True,
      is_single_dex_account_balance_output: True,
      is_merkle_tree_udpated: False,
      is_account_balance_updated: True,
      is_intent_token_burnt: True,
      is_cancel_withdrawal_amount_minted: True,
    }

  let (tx, redeemer) = mock_tx(test_case)

  !ha.hydra_account.withdraw(
    mock_dex_order_book_token,
    redeemer,
    Script(""),
    tx,
  )
}

test s8_wcw_failed_without_account_balance_updated() {
  let test_case =
    TestCase {
      is_operation_key_signed: True,
      is_single_dex_account_balance_input: True,
      is_single_dex_account_balance_output: True,
      is_merkle_tree_udpated: True,
      is_account_balance_updated: False,
      is_intent_token_burnt: True,
      is_cancel_withdrawal_amount_minted: True,
    }

  let (tx, redeemer) = mock_tx(test_case)

  !ha.hydra_account.withdraw(
    mock_dex_order_book_token,
    redeemer,
    Script(""),
    tx,
  )
}

test s8_wcw_failed_without_intent_token_burnt() {
  let test_case =
    TestCase {
      is_operation_key_signed: True,
      is_single_dex_account_balance_input: True,
      is_single_dex_account_balance_output: True,
      is_merkle_tree_udpated: True,
      is_account_balance_updated: True,
      is_intent_token_burnt: False,
      is_cancel_withdrawal_amount_minted: True,
    }

  let (tx, redeemer) = mock_tx(test_case)

  !ha.hydra_account.withdraw(
    mock_dex_order_book_token,
    redeemer,
    Script(""),
    tx,
  )
}

test s8_wcw_failed_without_cancel_withdrawal_amount_minted() {
  let test_case =
    TestCase {
      is_operation_key_signed: True,
      is_single_dex_account_balance_input: True,
      is_single_dex_account_balance_output: True,
      is_merkle_tree_udpated: True,
      is_account_balance_updated: True,
      is_intent_token_burnt: True,
      is_cancel_withdrawal_amount_minted: False,
    }

  let (tx, redeemer) = mock_tx(test_case)

  !ha.hydra_account.withdraw(
    mock_dex_order_book_token,
    redeemer,
    Script(""),
    tx,
  )
}
