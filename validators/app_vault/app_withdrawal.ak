use aiken/collection/dict
use aiken/interval.{is_entirely_after}
use cardano/address.{Credential}
use cardano/assets.{PolicyId, add, from_asset_list, merge}
use cardano/certificate.{Certificate}
use cardano/transaction.{Transaction}
use cocktail.{
  get_all_value_from, get_all_value_to, inputs_at_with_policy, key_signed,
  outputs_at_with_policy,
}
use cocktail/vodka_inputs.{input_inline_datum}
use hydra_dex/account_utils.{
  dex_account_balance_balance_decrease, get_master_key,
  withdrawal_auth_by_account,
}
use hydra_dex/types.{
  AppOracleDatum, EmergencyWithdrawalRequestDatum, ProcessAppWithdrawal,
}
use hydra_dex/utils.{get_all_value_to_cred, get_app_oracle_datum}

validator app_withdrawal(oracle_nft: PolicyId) {
  withdraw(
    redeemer: ProcessAppWithdrawal,
    _credential: Credential,
    tx: Transaction,
  ) {
    let Transaction {
      inputs,
      outputs,
      reference_inputs,
      extra_signatories,
      validity_range,
      withdrawals,
      mint,
      ..
    } = tx

    let AppOracleDatum {
      operation_key,
      app_vault_address,
      dex_account_balance_token,
      dex_account_balance_address,
      emergency_withdrawal_request_address,
      emergency_withdrawal_request_token,
      ..
    }: AppOracleDatum = reference_inputs |> get_app_oracle_datum(oracle_nft)

    //  - Obtain the input and output value to `AppVault`, check the value deducted equal to withdrawal amount
    //  - Check the withdrawal amounut is correct sent to an address equal
    let value_from_vault = get_all_value_from(inputs, app_vault_address)
    let value_to_vault = get_all_value_to(outputs, app_vault_address)
    let is_value_unlocked_from_vault_correct =
      value_to_vault
        |> merge(from_asset_list(redeemer.amount))
        |> assets.match(value_from_vault, ==)
    let user_master_key = get_master_key(redeemer.account)
    let is_withdrawal_amount_sent_to_user =
      get_all_value_to_cred(outputs, user_master_key)
        |> add("", "", 1_000_000)
        |> assets.match(redeemer.amount, >=)
    //  - Obtain the only `DexAccountBalance` input and its merkle tree account value
    //  - Obtain the only `DexAccountBalance` output and its merkle tree account value
    //  - Check if the withdrawal is processed correctly with the merkle tree
    let is_dex_account_balance_updated =
      when
        (
          inputs_at_with_policy(
            inputs,
            dex_account_balance_address,
            dex_account_balance_token,
          ),
          outputs_at_with_policy(
            outputs,
            dex_account_balance_address,
            dex_account_balance_token,
          ),
        )
      is {
        ([dex_account_balance_input], [dex_account_balance_output]) ->
          dex_account_balance_balance_decrease(
            dex_account_balance_input,
            dex_account_balance_output,
            redeemer.account,
            from_asset_list(redeemer.amount),
            redeemer.mpf_action,
          )

        _ -> False
      }

    //  - Operation key is signed
    let is_app_withdrawal_authorized = or {
        key_signed(extra_signatories, operation_key),
        //  - Obtain the only `AppWithdrawalRequest` input and its account value
        when
          inputs_at_with_policy(
            inputs,
            emergency_withdrawal_request_address,
            emergency_withdrawal_request_token,
          )
        is {
          [intent_input] -> {
            expect EmergencyWithdrawalRequestDatum {
              account: withdraw_account,
              amount: withdraw_amount,
              timestamp: withdraw_timestamp,
            }: EmergencyWithdrawalRequestDatum =
              input_inline_datum(intent_input)

            expect [Pair(_asset_name, quantity)] =
              mint
                |> assets.tokens(emergency_withdrawal_request_token)
                |> dict.to_pairs()

            let is_emergency_token_burnt = quantity == -1

            // Check that the redeemer matches the withdrawal request
            let is_redeemer_matches_withdrawal_request =
              redeemer.account == withdraw_account && redeemer.amount == withdraw_amount
            and {
              is_emergency_token_burnt,
              is_redeemer_matches_withdrawal_request,
              withdrawal_auth_by_account(
                redeemer.account,
                withdrawals,
                extra_signatories,
              ),
              is_entirely_after(validity_range, withdraw_timestamp + 86400),
            }
          }
          _ -> False
        },
      }

    //  - Input datum with current policy is `WithdrawalIntent`
    and {
      is_value_unlocked_from_vault_correct?,
      is_withdrawal_amount_sent_to_user?,
      is_dex_account_balance_updated?,
      is_app_withdrawal_authorized?,
    }
  }

  publish(_redeemer: Data, _credential: Certificate, tx: Transaction) {
    let Transaction { reference_inputs, extra_signatories, .. } = tx
    let AppOracleDatum { operation_key, .. }: AppOracleDatum =
      reference_inputs |> get_app_oracle_datum(oracle_nft)

    key_signed(extra_signatories, operation_key)?
  }

  else(_) {
    fail @"unsupported purpose"
  }
}
// test test_app_deposit_withdrawal_policy() {
//   let redeemer = ProcessAppWithdrawal(MPFInsert([]))
//   app_withdrawal.withdraw("", redeemer, Script(#""), placeholder)
// }
