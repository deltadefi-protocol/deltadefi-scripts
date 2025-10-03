use aiken/collection/dict
use aiken/interval.{is_entirely_after}
use cardano/assets.{PolicyId}
use cardano/transaction.{Transaction}
use cocktail/vodka_outputs.{output_inline_datum, outputs_at_with_policy}
use hydra_dex/types.{
  AppOracleDatum, EmergencyWithdrawalRequestDatum, MintPolarity, RBurn, RMint,
}
use hydra_dex/utils.{get_app_oracle_datum}

validator emergency_withdrawal_request(oracle_nft: PolicyId) {
  mint(redeemer: MintPolarity, policy_id: PolicyId, self: Transaction) {
    let Transaction { mint, outputs, reference_inputs, validity_range, .. } =
      self
    expect [Pair(_asset_name, quantity)] =
      mint
        |> assets.tokens(policy_id)
        |> dict.to_pairs()
    when redeemer is {
      RMint -> {
        let oracle_input_datum: AppOracleDatum =
          reference_inputs |> get_app_oracle_datum(oracle_nft)
        expect [withdrawal_request_output] =
          outputs_at_with_policy(
            outputs,
            oracle_input_datum.emergency_withdrawal_request_address,
            policy_id,
          )
        expect output_datum: EmergencyWithdrawalRequestDatum =
          output_inline_datum(withdrawal_request_output)

        let timestamp_check =
          validity_range |> is_entirely_after(output_datum.timestamp)
        timestamp_check? && (quantity == 1)?
      }
      RBurn -> quantity == -1
    }
  }

  else(_) {
    fail
  }
}
