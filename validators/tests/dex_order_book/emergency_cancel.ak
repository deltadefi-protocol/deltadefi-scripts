// TODO: Update merkle test case

use aiken/merkle_patricia_forestry.{Branch}
use cardano/address.{Address, Script}
use cardano/assets.{add, from_asset, from_lovelace}
use cardano/transaction.{Transaction}
use dex_order_book/emergency_cancel
use hydra_dex/types.{
  DexOrderBookDatum, EmergencyCancelRedeemer, EmergencyCancelRequestDatum,
  LimitOrder, MPFDelete, MerklizedOrderDatum, Order,
}
use hydra_dex/utils.{to_mvalue}
use mocktail.{
  complete, invalid_before, mint, mock_tx_hash, mocktail_tx, ref_tx_in,
  ref_tx_in_inline_datum, required_signer_hash, script_withdrawal, tx_in,
  tx_in_inline_datum, tx_out, tx_out_inline_datum,
}
use tests/utils.{
  mock_account, mock_account_master_key_hash, mock_app_vault_address,
  mock_app_withdrawal, mock_dex_order_book_address, mock_dex_order_book_datum,
  mock_dex_order_book_token, mock_emergency_cancel_order_request_address,
  mock_emergency_cancel_order_request_token, mock_input_oracle_datum,
  mock_operation_key, mock_oracle_address, mock_oracle_nft, mock_user_account,
} as test_utils

type AppWithdrawalTestCase {
  is_operation_key_signed: Bool,
  is_single_dex_order_book_input: Bool,
  is_single_dex_order_book_output: Bool,
  is_merkle_tree_udpated: Bool,
  is_value_unlocked_correct: Bool,
  is_withdrawal_amount_sent_to_user: Bool,
  is_emergency_token_burnt: Bool,
  is_emergency_withdraw: Bool,
  is_emergency_time_passed: Bool,
  is_user_signed: Bool,
}

fn mock_process_withdrawal_tx(
  test_case: AppWithdrawalTestCase,
) -> (Transaction, EmergencyCancelRedeemer) {
  let AppWithdrawalTestCase {
    is_operation_key_signed,
    is_single_dex_order_book_input,
    is_single_dex_order_book_output,
    is_merkle_tree_udpated,
    is_value_unlocked_correct,
    is_withdrawal_amount_sent_to_user,
    is_emergency_token_burnt,
    is_emergency_withdraw,
    is_emergency_time_passed,
    is_user_signed,
  } = test_case

  // MPF
  let old_root =
    #"4005bf6b8dcfba8d297cdddb5f4b1cfabe006a85315b0f870a668c29c163e46e"
  let new_root =
    if is_merkle_tree_udpated {
      #"e112f4fad96829c544fbed2ce83b4d93db3402ac3a3d1c6d755e376d8d58d1fe"
    } else {
      old_root
    }
  let withdrawal_amount = from_asset("", "", 250_000_000)

  let proof =
    MPFDelete {
      proof: [
        Branch {
          skip: 0,
          neighbors: #"61bc86c7587b7bf73d02ca47c08c4e78dbbc4e546040bf8349e84dde61ddb317706c5b827e05abe8f554f9b75201f2949c7f7504cc9bf6aa9a4abf25da4cc21c0eb923b0cbd24df54401d998531feead35a47a99f4deed205de4af81120f97610000000000000000000000000000000000000000000000000000000000000000",
        },
      ],
    }

  let order_id = #"032f3cc8274143358eb2bbf7b58acaf8"

  let dex_order_book_value =
    from_lovelace(2_000_000) |> add(mock_dex_order_book_token, "", 1)

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
          dex_order_book_value,
          mock_dex_order_book_address,
        )
      |> tx_in_inline_datum(
          True,
          DexOrderBookDatum {
            ..mock_dex_order_book_datum,
            limit_orders_merkle_root: old_root,
          },
        )
      |> tx_out(True, mock_dex_order_book_address, dex_order_book_value)
      |> tx_out_inline_datum(
          True,
          DexOrderBookDatum {
            ..mock_dex_order_book_datum,
            limit_orders_merkle_root: new_root,
          },
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
          withdrawal_amount,
        )
      |> script_withdrawal(True, mock_app_withdrawal, 0)
      |> required_signer_hash(is_operation_key_signed, mock_operation_key)
      // Emergency withdraw
      |> mint(
          is_emergency_token_burnt,
          -1,
          mock_emergency_cancel_order_request_token,
          "",
        )
      |> tx_in(
          is_emergency_withdraw,
          mock_tx_hash(1),
          0,
          from_asset(mock_emergency_cancel_order_request_token, "", 1),
          mock_emergency_cancel_order_request_address,
        )
      |> tx_in_inline_datum(
          is_emergency_withdraw,
          EmergencyCancelRequestDatum {
            account: mock_user_account(mock_account),
            order_id,
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
          !is_single_dex_order_book_input,
          mock_tx_hash(0),
          2,
          dex_order_book_value,
          mock_dex_order_book_address,
        )
      |> tx_in_inline_datum(
          !is_single_dex_order_book_input,
          DexOrderBookDatum {
            ..mock_dex_order_book_datum,
            limit_orders_merkle_root: old_root,
          },
        )
      |> tx_out(
          !is_single_dex_order_book_output,
          mock_dex_order_book_address,
          dex_order_book_value,
        )
      |> tx_out_inline_datum(
          !is_single_dex_order_book_output,
          DexOrderBookDatum {
            ..mock_dex_order_book_datum,
            limit_orders_merkle_root: new_root,
          },
        )
      |> complete()

  (
    mock_tx,
    EmergencyCancelRedeemer {
      account: mock_user_account(mock_account),
      order: MerklizedOrderDatum {
        datum: Order {
          order_id,
          base_token: ("", ""),
          quote_token: (
            #"5066154a102ee037390c5236f78db23239b49c5748d3d349f3ccf04b",
            #"55534458",
          ),
          is_buy: False,
          list_price_times_1bil: 1_350_000_000,
          size: 250_000_000,
          fee_amount_bp: 10,
          account: mock_user_account(mock_account),
          order_type: LimitOrder,
        },
        value: from_lovelace(250_000_000) |> to_mvalue(),
      },
      mpf_action: proof,
    },
  )
}

// TODO: Fix
// │ · with traces
// │ | the validator crashed / exited prematurely
// │ | expect including(key, value, proof) == self.root
test s6_wec_success() {
  let test_case =
    AppWithdrawalTestCase {
      is_operation_key_signed: True,
      is_single_dex_order_book_input: True,
      is_single_dex_order_book_output: True,
      is_merkle_tree_udpated: True,
      is_value_unlocked_correct: True,
      is_withdrawal_amount_sent_to_user: True,
      is_emergency_token_burnt: False,
      is_emergency_withdraw: False,
      is_emergency_time_passed: False,
      is_user_signed: False,
    }

  let (tx, redeemer) = mock_process_withdrawal_tx(test_case)

  emergency_cancel.emergency_order_cancel.withdraw(
    mock_oracle_nft,
    redeemer,
    Script(""),
    tx,
  )
}

test s6_wec_failed_without_operation_key_signed() fail {
  let test_case =
    AppWithdrawalTestCase {
      is_operation_key_signed: False,
      is_single_dex_order_book_input: True,
      is_single_dex_order_book_output: True,
      is_merkle_tree_udpated: True,
      is_value_unlocked_correct: True,
      is_withdrawal_amount_sent_to_user: True,
      is_emergency_token_burnt: False,
      is_emergency_withdraw: False,
      is_emergency_time_passed: False,
      is_user_signed: False,
    }

  let (tx, redeemer) = mock_process_withdrawal_tx(test_case)

  !emergency_cancel.emergency_order_cancel.withdraw(
    mock_oracle_nft,
    redeemer,
    Script(""),
    tx,
  )
}

test s6_wec_failed_with_multiple_dex_order_book_input() {
  let test_case =
    AppWithdrawalTestCase {
      is_operation_key_signed: True,
      is_single_dex_order_book_input: False,
      is_single_dex_order_book_output: True,
      is_merkle_tree_udpated: True,
      is_value_unlocked_correct: True,
      is_withdrawal_amount_sent_to_user: True,
      is_emergency_token_burnt: False,
      is_emergency_withdraw: False,
      is_emergency_time_passed: False,
      is_user_signed: False,
    }

  let (tx, redeemer) = mock_process_withdrawal_tx(test_case)

  !emergency_cancel.emergency_order_cancel.withdraw(
    mock_oracle_nft,
    redeemer,
    Script(""),
    tx,
  )
}

test s6_wec_failed_with_multiple_dex_order_book_output() {
  let test_case =
    AppWithdrawalTestCase {
      is_operation_key_signed: True,
      is_single_dex_order_book_input: True,
      is_single_dex_order_book_output: False,
      is_merkle_tree_udpated: True,
      is_value_unlocked_correct: True,
      is_withdrawal_amount_sent_to_user: True,
      is_emergency_token_burnt: False,
      is_emergency_withdraw: False,
      is_emergency_time_passed: False,
      is_user_signed: False,
    }

  let (tx, redeemer) = mock_process_withdrawal_tx(test_case)

  !emergency_cancel.emergency_order_cancel.withdraw(
    mock_oracle_nft,
    redeemer,
    Script(""),
    tx,
  )
}

// TODO: Fix
// │ · with traces
// │ | the validator crashed / exited prematurely
// │ | expect including(key, value, proof) == self.root
test s6_wec_failed_without_merkle_updated() {
  let test_case =
    AppWithdrawalTestCase {
      is_operation_key_signed: True,
      is_single_dex_order_book_input: True,
      is_single_dex_order_book_output: True,
      is_merkle_tree_udpated: False,
      is_value_unlocked_correct: True,
      is_withdrawal_amount_sent_to_user: True,
      is_emergency_token_burnt: False,
      is_emergency_withdraw: False,
      is_emergency_time_passed: False,
      is_user_signed: False,
    }

  let (tx, redeemer) = mock_process_withdrawal_tx(test_case)

  !emergency_cancel.emergency_order_cancel.withdraw(
    mock_oracle_nft,
    redeemer,
    Script(""),
    tx,
  )
}

test s6_wec_failed_with_excessive_value_unlocked() {
  let test_case =
    AppWithdrawalTestCase {
      is_operation_key_signed: True,
      is_single_dex_order_book_input: True,
      is_single_dex_order_book_output: True,
      is_merkle_tree_udpated: True,
      is_value_unlocked_correct: False,
      is_withdrawal_amount_sent_to_user: True,
      is_emergency_token_burnt: False,
      is_emergency_withdraw: False,
      is_emergency_time_passed: False,
      is_user_signed: False,
    }

  let (tx, redeemer) = mock_process_withdrawal_tx(test_case)

  !emergency_cancel.emergency_order_cancel.withdraw(
    mock_oracle_nft,
    redeemer,
    Script(""),
    tx,
  )
}

test s6_wec_failed_without_sufficient_amount_sent_to_users() {
  let test_case =
    AppWithdrawalTestCase {
      is_operation_key_signed: True,
      is_single_dex_order_book_input: True,
      is_single_dex_order_book_output: True,
      is_merkle_tree_udpated: True,
      is_value_unlocked_correct: True,
      is_withdrawal_amount_sent_to_user: False,
      is_emergency_token_burnt: False,
      is_emergency_withdraw: False,
      is_emergency_time_passed: False,
      is_user_signed: False,
    }

  let (tx, redeemer) = mock_process_withdrawal_tx(test_case)

  !emergency_cancel.emergency_order_cancel.withdraw(
    mock_oracle_nft,
    redeemer,
    Script(""),
    tx,
  )
}

// TODO: Fix
// │ · with traces
// │ | the validator crashed / exited prematurely
// │ | expect including(key, value, proof) == self.root
test s6_wec_success_emergency_withdrawal() {
  let test_case =
    AppWithdrawalTestCase {
      is_operation_key_signed: False,
      is_single_dex_order_book_input: True,
      is_single_dex_order_book_output: True,
      is_merkle_tree_udpated: True,
      is_value_unlocked_correct: True,
      is_withdrawal_amount_sent_to_user: True,
      is_emergency_token_burnt: True,
      is_emergency_withdraw: True,
      is_emergency_time_passed: True,
      is_user_signed: True,
    }

  let (tx, redeemer) = mock_process_withdrawal_tx(test_case)

  emergency_cancel.emergency_order_cancel.withdraw(
    mock_oracle_nft,
    redeemer,
    Script(""),
    tx,
  )
}

test s6_wec_failed_emergency_withdrawal_without_token_burnt() fail {
  let test_case =
    AppWithdrawalTestCase {
      is_operation_key_signed: False,
      is_single_dex_order_book_input: True,
      is_single_dex_order_book_output: True,
      is_merkle_tree_udpated: True,
      is_value_unlocked_correct: True,
      is_withdrawal_amount_sent_to_user: True,
      is_emergency_token_burnt: False,
      is_emergency_withdraw: True,
      is_emergency_time_passed: True,
      is_user_signed: True,
    }

  let (tx, redeemer) = mock_process_withdrawal_tx(test_case)

  emergency_cancel.emergency_order_cancel.withdraw(
    mock_oracle_nft,
    redeemer,
    Script(""),
    tx,
  )
}

// TODO: Fix
// │ · with traces
// │ | the validator crashed / exited prematurely
// │ | expect including(key, value, proof) == self.root
test s6_wec_failed_emergency_withdrawal_without_time_passed() {
  let test_case =
    AppWithdrawalTestCase {
      is_operation_key_signed: False,
      is_single_dex_order_book_input: True,
      is_single_dex_order_book_output: True,
      is_merkle_tree_udpated: True,
      is_value_unlocked_correct: True,
      is_withdrawal_amount_sent_to_user: True,
      is_emergency_token_burnt: True,
      is_emergency_withdraw: True,
      is_emergency_time_passed: False,
      is_user_signed: True,
    }

  let (tx, redeemer) = mock_process_withdrawal_tx(test_case)

  !emergency_cancel.emergency_order_cancel.withdraw(
    mock_oracle_nft,
    redeemer,
    Script(""),
    tx,
  )
}

// TODO: Fix
// │ · with traces
// │ | the validator crashed / exited prematurely
// │ | expect including(key, value, proof) == self.root
test s6_wec_failed_emergency_withdrawal_without_user_signature() {
  let test_case =
    AppWithdrawalTestCase {
      is_operation_key_signed: False,
      is_single_dex_order_book_input: True,
      is_single_dex_order_book_output: True,
      is_merkle_tree_udpated: True,
      is_value_unlocked_correct: True,
      is_withdrawal_amount_sent_to_user: True,
      is_emergency_token_burnt: True,
      is_emergency_withdraw: True,
      is_emergency_time_passed: True,
      is_user_signed: False,
    }

  let (tx, redeemer) = mock_process_withdrawal_tx(test_case)

  !emergency_cancel.emergency_order_cancel.withdraw(
    mock_oracle_nft,
    redeemer,
    Script(""),
    tx,
  )
}
