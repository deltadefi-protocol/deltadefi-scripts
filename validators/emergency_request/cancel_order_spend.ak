use aiken/collection/dict.{is_empty}
use aiken/interval.{is_entirely_after}
use cardano/assets.{PolicyId, tokens}
use cardano/transaction.{OutputReference, Transaction, find_input}
use cocktail.{key_signed, withdrawal_script_validated}
use hydra_dex/account_utils.{withdrawal_auth_by_account}
use hydra_dex/types.{
  AppOracleDatum, EmergencyCancelRequestDatum, EmergencyCancelRequestRedeemer,
  EmergencyRequestExpiredCancel, EmergencyRequestProcessCancel,
  EmergencyRequestSpamPreventionCancel,
}
use hydra_dex/utils.{get_app_oracle_datum}

validator emergency_cancel_order_request(oracle_nft: PolicyId) {
  spend(
    datum_opt: Option<EmergencyCancelRequestDatum>,
    redeemer: EmergencyCancelRequestRedeemer,
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
    let AppOracleDatum {
      all_withdrawal_script_hashes,
      emergency_cancel_order_request_token,
      operation_key,
      ..
    }: AppOracleDatum = reference_inputs |> get_app_oracle_datum(oracle_nft)

    when redeemer is {
      EmergencyRequestProcessCancel ->
        withdrawal_script_validated(
          withdrawals,
          all_withdrawal_script_hashes.emergency_cancel_order,
        )
      EmergencyRequestSpamPreventionCancel -> {
        expect Some(own_input) = find_input(inputs, utxo)
        let token_check =
          tokens(own_input.output.value, emergency_cancel_order_request_token)
            |> is_empty()

        let is_operation_key_signed =
          key_signed(extra_signatories, operation_key)
        and {
          token_check?,
          is_operation_key_signed?,
        }
      }

      EmergencyRequestExpiredCancel -> {
        expect Some(input_datum) = datum_opt
        expect [Pair(_asset_name, quantity)] =
          mint
            |> assets.tokens(emergency_cancel_order_request_token)
            |> dict.to_pairs()
        let is_auth_token_burnt = quantity == -1
        let is_operation_key_signed =
          key_signed(extra_signatories, operation_key)
        let is_user_authorized =
          withdrawal_auth_by_account(
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
