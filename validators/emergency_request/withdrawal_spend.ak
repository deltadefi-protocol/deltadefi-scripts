use aiken/collection/dict.{is_empty}
use aiken/interval.{is_entirely_after}
use cardano/assets.{PolicyId, negate, tokens}
use cardano/transaction.{OutputReference, Transaction, find_input}
use cocktail.{key_signed, value_length}
use hydra_dex/account_utils.{master_auth_by_account}
use hydra_dex/types.{
  AppOracleDatum, EmergencyRequestExpiredWithdraw,
  EmergencyRequestProcessEmergencyAction, EmergencyRequestSpamPreventionWithdraw,
  EmergencyWithdrawalRequestDatum, EmergencyWithdrawalRequestRedeemer,
}
use hydra_dex/utils.{get_app_oracle_datum}

validator emergency_withdrawal_request(oracle_nft: PolicyId) {
  spend(
    datum_opt: Option<EmergencyWithdrawalRequestDatum>,
    redeemer: EmergencyWithdrawalRequestRedeemer,
    utxo: OutputReference,
    self: Transaction,
  ) {
    let Transaction {
      mint,
      inputs,
      reference_inputs,
      validity_range,
      withdrawals,
      extra_signatories,
      ..
    } = self

    let AppOracleDatum { emergency_withdrawal_request_token, operation_key, .. }: AppOracleDatum =
      reference_inputs |> get_app_oracle_datum(oracle_nft)

    when redeemer is {
      EmergencyRequestProcessEmergencyAction -> {
        expect Some(own_input) = find_input(inputs, utxo)
        let is_current_input_clean = value_length(own_input.output.value) == 2
        let emergency_token_mint_qty =
          mint
            |> assets.quantity_of(emergency_withdrawal_request_token, "")

        let is_current_token_burnt =
          assets.quantity_of(
            own_input.output.value |> negate(),
            emergency_withdrawal_request_token,
            "",
          ) == emergency_token_mint_qty

        expect Some(datum) = datum_opt
        let is_user_authorized =
          master_auth_by_account(datum.account, withdrawals, extra_signatories)
        is_user_authorized? && is_current_input_clean? && is_current_token_burnt?
      }

      // check burnt (current value clean)
      // check account signature
      EmergencyRequestSpamPreventionWithdraw -> {
        expect Some(own_input) = find_input(inputs, utxo)

        let token_check =
          tokens(own_input.output.value, emergency_withdrawal_request_token)
            |> is_empty()

        let is_operation_key_signed =
          key_signed(extra_signatories, operation_key)
        and {
          token_check?,
          is_operation_key_signed?,
        }
      }

      EmergencyRequestExpiredWithdraw -> {
        expect Some(input_datum) = datum_opt
        expect [Pair(_asset_name, quantity)] =
          mint
            |> assets.tokens(emergency_withdrawal_request_token)
            |> dict.to_pairs()
        let is_auth_token_burnt = quantity == -1
        let is_operation_key_signed =
          key_signed(extra_signatories, operation_key)
        let is_user_authorized =
          master_auth_by_account(
            input_datum.account,
            withdrawals,
            extra_signatories,
          )
        let is_withdrawal_authorized =
          is_operation_key_signed? || is_user_authorized?
        let is_request_expired =
          validity_range |> is_entirely_after(input_datum.timestamp + 172800)

        is_auth_token_burnt? && is_withdrawal_authorized? && is_request_expired?
      }
    }
  }

  else(_) {
    fail
  }
}
