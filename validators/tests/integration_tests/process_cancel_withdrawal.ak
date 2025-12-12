// use aiken/merkle_patricia_forestry.{Branch}
// use cardano/address.{Script}
// use cardano/assets.{add, from_asset, from_lovelace, merge}
// use cardano/transaction.{Transaction}
// use dex_account_balance/spend as dex_account_balance
// use hydra_account/core as ha
// use hydra_dex/account_utils.{from_value_to_hydra_balance}
// use hydra_dex/types.{
//   BurnIntent, CancelWithdrawalIntent, DexAccountBalanceDatum,
//   HydraAccountOperate, HydraCancelWithdrawal, HydraUserIntentDatum, MPFUpdate,
//   MasterIntent, ProcessCancelWithdrawal,
// }
// use hydra_dex/utils.{to_mvalue}
// use hydra_user_intent as hui
// use mocktail.{
//   complete, mint, mock_tx_hash, mock_utxo_ref, mocktail_tx, ref_tx_in,
//   ref_tx_in_inline_datum, required_signer_hash, script_withdrawal, tx_in,
//   tx_in_inline_datum, tx_out, tx_out_inline_datum,
// }
// use tests/utils.{
//   mock_account, mock_dex_account_balance_address, mock_dex_account_balance_token,
//   mock_dex_order_book_address, mock_dex_order_book_datum,
//   mock_dex_order_book_token, mock_hydra_account, mock_hydra_account_address,
//   mock_hydra_lovelace, mock_hydra_token_policy_id,
//   mock_hydra_user_intent_address, mock_hydra_user_intent_token,
//   mock_operation_key, mock_oracle_nft, mock_user_account,
// } as test_utils

// type TestCase {
//   is_operation_key_signed: Bool,
//   is_single_dex_account_balance_input: Bool,
//   is_single_dex_account_balance_output: Bool,
//   is_merkle_tree_udpated: Bool,
//   is_account_balance_updated: Bool,
//   is_intent_token_burnt: Bool,
//   is_withdrawal_script_validated: Bool,
//   is_cancel_withdrawal_amount_minted: Bool,
// }

// const proof =
//   MPFUpdate {
//     from: #"a240a1401a3b9aca00581c5066154a102ee037390c5236f78db23239b49c5748d3d349f3ccf04ba144555344581a3b9aca00",
//     to: #"a240a1401a1dcd6500581c5066154a102ee037390c5236f78db23239b49c5748d3d349f3ccf04ba144555344581a3b9aca00",
//     to_proof: [
//       Branch {
//         skip: 0,
//         neighbors: #"9543c86b0bb9781a8d503bc087408469b50a3d3e1f7f4b0554dc813ae14c086185c09af929492a871e4fae32d9d5c36e352471cd659bcdb61de08f1722acc3b10eb923b0cbd24df54401d998531feead35a47a99f4deed205de4af81120f97610000000000000000000000000000000000000000000000000000000000000000",
//       },
//     ],
//   }

// fn mock_tx(
//   test_case: TestCase,
// ) -> (Transaction, HydraUserIntentDatum, DexAccountBalanceDatum) {
//   let TestCase {
//     is_operation_key_signed,
//     is_single_dex_account_balance_input,
//     is_single_dex_account_balance_output,
//     is_merkle_tree_udpated,
//     is_account_balance_updated,
//     is_intent_token_burnt,
//     is_withdrawal_script_validated,
//     is_cancel_withdrawal_amount_minted,
//   } = test_case

//   let account = mock_user_account(mock_account)

//   // MPF
//   let old_root =
//     #"c30c594b7188370e1995e5cf31d319f386d386d967f2987aa56a0c542f2ef076"
//   let new_root =
//     if is_merkle_tree_udpated {
//       #"d13dbd6ff7b335876e3d6812f26649dc13592b3cd91b38623f95da458a835030"
//     } else {
//       old_root
//     }
//   let withdrawal_amount = from_lovelace(500_000_000)

//   let hydra_account_start = mock_hydra_lovelace(10_000_000)
//   let hydra_account_end =
//     if is_account_balance_updated {
//       withdrawal_amount
//         |> from_value_to_hydra_balance(mock_hydra_token_policy_id)
//         |> merge(hydra_account_start)
//     } else {
//       hydra_account_start
//     }
//   let dex_account_balance_value =
//     from_lovelace(2_000_000) |> add(mock_dex_account_balance_token, "", 1)

//   let input_dex_balance =
//     DexAccountBalanceDatum { account_balance_merkle_root: old_root }

//   let intent_datum =
//     MasterIntent {
//       account,
//       intent: CancelWithdrawalIntent {
//         amount: withdrawal_amount |> to_mvalue(),
//       },
//     }
//   let mock_tx =
//     mocktail_tx()
//       |> ref_tx_in(
//           True,
//           mock_tx_hash(1),
//           0,
//           from_asset(mock_dex_order_book_token, "", 1),
//           mock_dex_order_book_address,
//         )
//       |> ref_tx_in_inline_datum(True, mock_dex_order_book_datum)
//       |> tx_in(
//           True,
//           mock_tx_hash(0),
//           0,
//           from_asset(mock_hydra_user_intent_token, "", 1),
//           mock_hydra_user_intent_address,
//         )
//       |> tx_in_inline_datum(True, intent_datum)
//       |> tx_in(
//           True,
//           mock_tx_hash(0),
//           2,
//           dex_account_balance_value,
//           mock_dex_account_balance_address,
//         )
//       |> tx_in_inline_datum(True, input_dex_balance)
//       |> tx_out(
//           True,
//           mock_dex_account_balance_address,
//           dex_account_balance_value,
//         )
//       |> tx_out_inline_datum(
//           True,
//           DexAccountBalanceDatum { account_balance_merkle_root: new_root },
//         )
//       |> tx_in(
//           True,
//           mock_tx_hash(0),
//           1,
//           hydra_account_start,
//           mock_hydra_account_address,
//         )
//       |> tx_in_inline_datum(True, account)
//       |> tx_out(True, mock_hydra_account_address, hydra_account_end)
//       |> tx_out_inline_datum(True, account)
//       |> script_withdrawal(
//           is_withdrawal_script_validated,
//           mock_hydra_account,
//           0,
//         )
//       |> mint(is_intent_token_burnt, -1, mock_hydra_user_intent_token, "")
//       |> mint(
//           is_cancel_withdrawal_amount_minted,
//           500_000_000,
//           mock_hydra_token_policy_id,
//           "",
//         )
//       |> required_signer_hash(is_operation_key_signed, mock_operation_key)
//       // Failing cases
//       |> tx_in(
//           !is_single_dex_account_balance_input,
//           mock_tx_hash(0),
//           2,
//           dex_account_balance_value,
//           mock_dex_account_balance_address,
//         )
//       |> tx_in_inline_datum(
//           !is_single_dex_account_balance_input,
//           DexAccountBalanceDatum { account_balance_merkle_root: old_root },
//         )
//       |> tx_out(
//           !is_single_dex_account_balance_output,
//           mock_dex_account_balance_address,
//           dex_account_balance_value,
//         )
//       |> tx_out_inline_datum(
//           !is_single_dex_account_balance_output,
//           DexAccountBalanceDatum { account_balance_merkle_root: new_root },
//         )
//       |> complete()

//   (mock_tx, intent_datum, input_dex_balance)
// }

// fn check_all_scripts(test_case: TestCase) {
//   let (tx, intent_datum, input_dex_balance) = mock_tx(test_case)

//   let withdraw =
//     ha.hydra_account.withdraw(
//       mock_dex_order_book_token,
//       ProcessCancelWithdrawal { mpf_action: proof },
//       Script(mock_hydra_account),
//       tx,
//     )

//   let check_intent_spend =
//     hui.hydra_user_intent.spend(
//       mock_dex_order_book_token,
//       Some(intent_datum),
//       Void,
//       mock_utxo_ref(0, 0),
//       tx,
//     )
//   let check_intent_mint =
//     hui.hydra_user_intent.mint(
//       mock_dex_order_book_token,
//       BurnIntent,
//       mock_hydra_user_intent_token,
//       tx,
//     )
//   let check_hydra_balance =
//     ha.hydra_account.spend(
//       mock_dex_order_book_token,
//       Some(mock_user_account(mock_account)),
//       HydraAccountOperate,
//       mock_utxo_ref(0, 1),
//       tx,
//     )
//   let check_dex_balance =
//     dex_account_balance.dex_account_balance.spend(
//       mock_oracle_nft,
//       mock_dex_order_book_token,
//       Some(input_dex_balance),
//       HydraCancelWithdrawal,
//       mock_utxo_ref(0, 2),
//       tx,
//     )

//   withdraw? && check_intent_spend? && check_intent_mint? && check_hydra_balance? && check_dex_balance
// }

// test it_hpcw_success() {
//   let test_case =
//     TestCase {
//       is_operation_key_signed: True,
//       is_single_dex_account_balance_input: True,
//       is_single_dex_account_balance_output: True,
//       is_merkle_tree_udpated: True,
//       is_account_balance_updated: True,
//       is_intent_token_burnt: True,
//       is_withdrawal_script_validated: True,
//       is_cancel_withdrawal_amount_minted: True,
//     }

//   check_all_scripts(test_case)
// }

// test it_hpcw_failed_without_operation_key_signed() {
//   let test_case =
//     TestCase {
//       is_operation_key_signed: False,
//       is_single_dex_account_balance_input: True,
//       is_single_dex_account_balance_output: True,
//       is_merkle_tree_udpated: True,
//       is_account_balance_updated: True,
//       is_intent_token_burnt: True,
//       is_withdrawal_script_validated: True,
//       is_cancel_withdrawal_amount_minted: True,
//     }

//   !check_all_scripts(test_case)
// }

// test it_hpcw_failed_with_multiple_dex_account_balance_input() {
//   let test_case =
//     TestCase {
//       is_operation_key_signed: True,
//       is_single_dex_account_balance_input: False,
//       is_single_dex_account_balance_output: True,
//       is_merkle_tree_udpated: True,
//       is_account_balance_updated: True,
//       is_intent_token_burnt: True,
//       is_withdrawal_script_validated: True,
//       is_cancel_withdrawal_amount_minted: True,
//     }

//   !check_all_scripts(test_case)
// }

// test it_hpcw_failed_with_multiple_dex_account_balance_output() {
//   let test_case =
//     TestCase {
//       is_operation_key_signed: True,
//       is_single_dex_account_balance_input: True,
//       is_single_dex_account_balance_output: False,
//       is_merkle_tree_udpated: True,
//       is_account_balance_updated: True,
//       is_intent_token_burnt: True,
//       is_withdrawal_script_validated: True,
//       is_cancel_withdrawal_amount_minted: True,
//     }

//   !check_all_scripts(test_case)
// }

// test it_hpcw_failed_without_merkle_root_updated() {
//   let test_case =
//     TestCase {
//       is_operation_key_signed: True,
//       is_single_dex_account_balance_input: True,
//       is_single_dex_account_balance_output: True,
//       is_merkle_tree_udpated: False,
//       is_account_balance_updated: True,
//       is_intent_token_burnt: True,
//       is_withdrawal_script_validated: True,
//       is_cancel_withdrawal_amount_minted: True,
//     }

//   !check_all_scripts(test_case)
// }

// test it_hpcw_failed_without_account_balance_updated() {
//   let test_case =
//     TestCase {
//       is_operation_key_signed: True,
//       is_single_dex_account_balance_input: True,
//       is_single_dex_account_balance_output: True,
//       is_merkle_tree_udpated: True,
//       is_account_balance_updated: False,
//       is_intent_token_burnt: True,
//       is_withdrawal_script_validated: True,
//       is_cancel_withdrawal_amount_minted: True,
//     }

//   !check_all_scripts(test_case)
// }

// test it_hpcw_failed_without_intent_token_burnt() {
//   let test_case =
//     TestCase {
//       is_operation_key_signed: True,
//       is_single_dex_account_balance_input: True,
//       is_single_dex_account_balance_output: True,
//       is_merkle_tree_udpated: True,
//       is_account_balance_updated: True,
//       is_intent_token_burnt: False,
//       is_withdrawal_script_validated: True,
//       is_cancel_withdrawal_amount_minted: True,
//     }

//   !check_all_scripts(test_case)
// }

// test it_hpcw_failed_without_withdrawal_script() {
//   let test_case =
//     TestCase {
//       is_operation_key_signed: True,
//       is_single_dex_account_balance_input: True,
//       is_single_dex_account_balance_output: True,
//       is_merkle_tree_udpated: True,
//       is_account_balance_updated: True,
//       is_intent_token_burnt: True,
//       is_withdrawal_script_validated: False,
//       is_cancel_withdrawal_amount_minted: True,
//     }

//   !check_all_scripts(test_case)
// }

// test it_hpcw_failed_without_cancel_withdrawal_amount_minted() {
//   let test_case =
//     TestCase {
//       is_operation_key_signed: True,
//       is_single_dex_account_balance_input: True,
//       is_single_dex_account_balance_output: True,
//       is_merkle_tree_udpated: True,
//       is_account_balance_updated: True,
//       is_intent_token_burnt: True,
//       is_withdrawal_script_validated: True,
//       is_cancel_withdrawal_amount_minted: False,
//     }

//   !check_all_scripts(test_case)
// }
