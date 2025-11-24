use aiken/collection/dict.{is_empty}
use aiken/interval.{is_entirely_after}
use cardano/assets.{PolicyId, tokens}
use cardano/transaction.{OutputReference, Transaction, find_input}
use cocktail.{
  input_inline_datum, inputs_at_with_policy, key_signed,
  withdrawal_script_validated,
}
use hydra_dex/account_utils.{master_auth_by_account}
use hydra_dex/types.{
  AppDepositRequestDatum, AppDepositRequestEmergencyWithdrawal,
  AppDepositRequestRedeemer, AppDepositRequestSpamPreventionWithdraw,
  AppDepositRequestTransferAccountBalance, AppOracleDatum,
  EmergencyWithdrawalRequestDatum,
}
use hydra_dex/utils.{get_app_oracle_datum}

validator app_deposit_request(oracle_nft: PolicyId) {
  spend(
    datum_opt: Option<AppDepositRequestDatum>,
    redeemer: AppDepositRequestRedeemer,
    utxo: OutputReference,
    self: Transaction,
  ) {
    let Transaction {
      inputs,
      reference_inputs,
      withdrawals,
      extra_signatories,
      ..
    } = self

    let oracle_input_datum: AppOracleDatum =
      reference_inputs |> get_app_oracle_datum(oracle_nft)

    when redeemer is {
      AppDepositRequestTransferAccountBalance ->
        withdrawal_script_validated(
          withdrawals,
          oracle_input_datum.all_withdrawal_script_hashes.app_deposit,
        )
      AppDepositRequestEmergencyWithdrawal ->
        when
          inputs_at_with_policy(
            inputs,
            oracle_input_datum.emergency_withdrawal_request_address,
            oracle_input_datum.emergency_withdrawal_request_token,
          )
        is {
          [intent_input] -> {
            expect Some(datum) = datum_opt
            expect EmergencyWithdrawalRequestDatum {
              account: withdraw_account,
              timestamp: withdraw_timestamp,
              ..
            }: EmergencyWithdrawalRequestDatum =
              input_inline_datum(intent_input)
            expect [Pair(_asset_name, quantity)] =
              self.mint
                |> assets.tokens(
                    oracle_input_datum.emergency_withdrawal_request_token,
                  )
                |> dict.to_pairs()
            let is_emergency_token_burnt = quantity == -1
            let is_account_correct = withdraw_account == datum.account
            and {
              is_emergency_token_burnt?,
              is_account_correct?,
              master_auth_by_account(
                withdraw_account,
                withdrawals,
                extra_signatories,
              ),
              is_entirely_after(self.validity_range, withdraw_timestamp + 86400),
            }
          }
          _ -> False
        }

      AppDepositRequestSpamPreventionWithdraw -> {
        expect Some(own_input) = find_input(inputs, utxo)
        let no_auth_token_check =
          tokens(
            own_input.output.value,
            oracle_input_datum.app_deposit_request_token,
          )
            |> is_empty()
        let is_operation_key_signed =
          key_signed(extra_signatories, oracle_input_datum.operation_key)

        no_auth_token_check? && is_operation_key_signed?
      }
    }
  }

  else(_) {
    fail
  }
}
