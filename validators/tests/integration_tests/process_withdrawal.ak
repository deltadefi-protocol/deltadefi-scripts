// use cardano/address.{Script}
// use cardano/assets.{add, from_asset, from_lovelace, merge, negate}
// use cardano/transaction.{Transaction}
// use dex_account_balance/spend as dex_account_balance
// use hydra_account/core as hab
// use hydra_dex/account_utils.{from_value_to_hydra_balance}
// use hydra_dex/types.{
//   BurnIntent, DexAccountBalanceDatum, HydraUserIntentDatum, HydraWithdrawal,
//   MPFUpdate, ProcessHydraWithdrawal, UpdateBalanceWithWithdrawal,
//   UserTradeAccount, WithdrawalIntent,
// }
// use hydra_dex/utils.{to_mvalue}
// use hydra_user_intent/mint as intent_mint
// use hydra_user_intent/spend as intent_spend
// use mocktail.{
//   complete, mint, mock_tx_hash, mock_utxo_ref, mocktail_tx, ref_tx_in,
//   ref_tx_in_inline_datum, required_signer_hash, script_withdrawal, tx_in,
//   tx_in_inline_datum, tx_out, tx_out_inline_datum,
// }
// use tests/utils.{
//   mock_account, mock_dex_account_balance_address, mock_dex_account_balance_token,
//   mock_dex_order_book_address, mock_dex_order_book_datum,
//   mock_dex_order_book_token, mock_hydra_account_address, mock_hydra_lovelace,
//   mock_hydra_token_policy_id, mock_hydra_usd, mock_hydra_usd_token_name,
//   mock_hydra_user_intent_address, mock_hydra_user_intent_token,
//   mock_hydra_withdrawal, mock_operation_key, mock_oracle_nft,
// } as test_utils

// type TestCase {
//   is_operation_key_signed: Bool,
//   is_single_dex_account_balance_input: Bool,
//   is_single_dex_account_balance_output: Bool,
//   is_merkle_tree_udpated: Bool,
//   is_account_balance_updated: Bool,
//   is_intent_token_burnt: Bool,
//   is_withdrawal_script_validated: Bool,
//   is_withdraw_value_burnt: Bool,
// }

// fn mock_tx(
//   test_case: TestCase,
// ) -> (
//   Transaction,
//   ProcessHydraWithdrawal,
//   HydraUserIntentDatum,
//   DexAccountBalanceDatum,
// ) {
//   let TestCase {
//     is_operation_key_signed,
//     is_single_dex_account_balance_input,
//     is_single_dex_account_balance_output,
//     is_merkle_tree_udpated,
//     is_account_balance_updated,
//     is_intent_token_burnt,
//     is_withdrawal_script_validated,
//     is_withdraw_value_burnt,
//   } = test_case

//   let account = mock_user_account(mock_account)

//   // MPF
//   let old_root =
//     #"d77bbe4dd2ef95da2112cb54177b8132b4166f05493405b5fdc6c4f7e9ec8df8"
//   let new_root =
//     if is_merkle_tree_udpated {
//       #"fc765255aa7da1b705a7703f161f9e954e53964026d4aecda93fc3d986c899b8"
//     } else {
//       old_root
//     }
//   let withdrawal_amount =
//     from_asset("", "", 900_000_000)
//       |> add(
//           #"5066154a102ee037390c5236f78db23239b49c5748d3d349f3ccf04b",
//           #"55534458",
//           1_000_000_000,
//         )
//   let proof =
//     MPFUpdate {
//       from: #"a140a1401a05f5e100",
//       to: #"a240a1401a3b9aca00581c5066154a102ee037390c5236f78db23239b49c5748d3d349f3ccf04ba144555344581a3b9aca00",
//       to_proof: [],
//     }

//   let hydra_account_start =
//     mock_hydra_lovelace(1_000_000_000) |> merge(mock_hydra_usd(2_000_000_000))
//   let hydra_account_end =
//     if is_account_balance_updated {
//       withdrawal_amount
//         |> from_value_to_hydra_balance(mock_hydra_token_policy_id)
//         |> negate()
//         |> merge(hydra_account_start)
//     } else {
//       hydra_account_start
//     }
//   let dex_account_balance_value =
//     from_lovelace(2_000_000) |> add(mock_dex_account_balance_token, "", 1)

//   let input_dex_balance =
//     DexAccountBalanceDatum { account_balance_merkle_root: old_root }

//   let intent_datum =
//     WithdrawalIntent {
//       account: mock_user_account(mock_account),
//       amount: withdrawal_amount |> to_mvalue(),
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
//           1,
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
//           3,
//           hydra_account_start,
//           mock_hydra_account_address,
//         )
//       |> tx_in_inline_datum(True, account)
//       |> tx_out(True, mock_hydra_account_address, hydra_account_end)
//       |> tx_out_inline_datum(True, account)
//       |> script_withdrawal(
//           is_withdrawal_script_validated,
//           mock_hydra_withdrawal,
//           0,
//         )
//       |> mint(is_intent_token_burnt, -1, mock_hydra_user_intent_token, "")
//       |> mint(
//           is_withdraw_value_burnt,
//           -900_000_000,
//           mock_hydra_token_policy_id,
//           "",
//         )
//       |> mint(
//           is_withdraw_value_burnt,
//           -1_000_000_000,
//           mock_hydra_token_policy_id,
//           mock_hydra_usd_token_name,
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

//   (
//     mock_tx,
//     ProcessHydraWithdrawal { mpf_action: proof },
//     intent_datum,
//     input_dex_balance,
//   )
// }

// fn check_all_scripts(test_case: TestCase) {
//   let (tx, redeemer, intent_datum, input_dex_balance) = mock_tx(test_case)

//   let withdraw =
//     hab.hydra_account.withdraw(
//       mock_dex_order_book_token,
//       redeemer,
//       Script(mock_hydra_withdrawal),
//       tx,
//     )

//   let check_intent_spend =
//     intent_spend.hydra_user_intent.spend(
//       mock_dex_order_book_token,
//       Some(intent_datum),
//       Void,
//       mock_utxo_ref(0, 1),
//       tx,
//     )
//   let check_intent_mint =
//     intent_mint.hydra_user_intent.mint(
//       mock_dex_order_book_token,
//       BurnIntent,
//       mock_hydra_user_intent_token,
//       tx,
//     )
//   let check_hydra_balance =
//     hab.hydra_account.spend(
//       mock_dex_order_book_token,
//       Some(mock_user_account(mock_account)),
//       UpdateBalanceWithWithdrawal,
//       mock_utxo_ref(0, 3),
//       tx,
//     )
//   let check_dex_balance =
//     dex_account_balance.dex_account_balance.spend(
//       mock_oracle_nft,
//       mock_dex_order_book_token,
//       Some(input_dex_balance),
//       HydraWithdrawal,
//       mock_utxo_ref(0, 2),
//       tx,
//     )

//   withdraw? && check_intent_spend? && check_intent_mint? && check_hydra_balance? && check_dex_balance
// }

// test it_hpw_success() {
//   let test_case =
//     TestCase {
//       is_operation_key_signed: True,
//       is_single_dex_account_balance_input: True,
//       is_single_dex_account_balance_output: True,
//       is_merkle_tree_udpated: True,
//       is_account_balance_updated: True,
//       is_intent_token_burnt: True,
//       is_withdrawal_script_validated: True,
//       is_withdraw_value_burnt: True,
//     }

//   check_all_scripts(test_case)
// }

// test it_hpw_failed_without_operation_key_signed() {
//   let test_case =
//     TestCase {
//       is_operation_key_signed: False,
//       is_single_dex_account_balance_input: True,
//       is_single_dex_account_balance_output: True,
//       is_merkle_tree_udpated: True,
//       is_account_balance_updated: True,
//       is_intent_token_burnt: True,
//       is_withdrawal_script_validated: True,
//       is_withdraw_value_burnt: True,
//     }

//   !check_all_scripts(test_case)
// }

// test it_hpw_failed_with_multiple_dex_account_balance_input() {
//   let test_case =
//     TestCase {
//       is_operation_key_signed: True,
//       is_single_dex_account_balance_input: False,
//       is_single_dex_account_balance_output: True,
//       is_merkle_tree_udpated: True,
//       is_account_balance_updated: True,
//       is_intent_token_burnt: True,
//       is_withdrawal_script_validated: True,
//       is_withdraw_value_burnt: True,
//     }

//   !check_all_scripts(test_case)
// }

// test it_hpw_failed_with_multiple_dex_account_balance_output() {
//   let test_case =
//     TestCase {
//       is_operation_key_signed: True,
//       is_single_dex_account_balance_input: True,
//       is_single_dex_account_balance_output: False,
//       is_merkle_tree_udpated: True,
//       is_account_balance_updated: True,
//       is_intent_token_burnt: True,
//       is_withdrawal_script_validated: True,
//       is_withdraw_value_burnt: True,
//     }

//   !check_all_scripts(test_case)
// }

// test it_hpw_failed_without_merkle_root_updated() {
//   let test_case =
//     TestCase {
//       is_operation_key_signed: True,
//       is_single_dex_account_balance_input: True,
//       is_single_dex_account_balance_output: True,
//       is_merkle_tree_udpated: False,
//       is_account_balance_updated: True,
//       is_intent_token_burnt: True,
//       is_withdrawal_script_validated: True,
//       is_withdraw_value_burnt: True,
//     }

//   !check_all_scripts(test_case)
// }

// test it_hpw_failed_without_account_balance_updated() {
//   let test_case =
//     TestCase {
//       is_operation_key_signed: True,
//       is_single_dex_account_balance_input: True,
//       is_single_dex_account_balance_output: True,
//       is_merkle_tree_udpated: True,
//       is_account_balance_updated: False,
//       is_intent_token_burnt: True,
//       is_withdrawal_script_validated: True,
//       is_withdraw_value_burnt: True,
//     }

//   !check_all_scripts(test_case)
// }

// test it_hpw_failed_without_intent_token_burnt() {
//   let test_case =
//     TestCase {
//       is_operation_key_signed: True,
//       is_single_dex_account_balance_input: True,
//       is_single_dex_account_balance_output: True,
//       is_merkle_tree_udpated: True,
//       is_account_balance_updated: True,
//       is_intent_token_burnt: False,
//       is_withdrawal_script_validated: True,
//       is_withdraw_value_burnt: True,
//     }

//   !check_all_scripts(test_case)
// }

// test it_hpw_failed_without_withdrawal_script() {
//   let test_case =
//     TestCase {
//       is_operation_key_signed: True,
//       is_single_dex_account_balance_input: True,
//       is_single_dex_account_balance_output: True,
//       is_merkle_tree_udpated: True,
//       is_account_balance_updated: True,
//       is_intent_token_burnt: True,
//       is_withdrawal_script_validated: False,
//       is_withdraw_value_burnt: True,
//     }

//   !check_all_scripts(test_case)
// }

// test it_hpw_failed_without_withdraw_value_burnt() {
//   let test_case =
//     TestCase {
//       is_operation_key_signed: True,
//       is_single_dex_account_balance_input: True,
//       is_single_dex_account_balance_output: True,
//       is_merkle_tree_udpated: True,
//       is_account_balance_updated: True,
//       is_intent_token_burnt: True,
//       is_withdrawal_script_validated: True,
//       is_withdraw_value_burnt: False,
//     }

//   !check_all_scripts(test_case)
// }
