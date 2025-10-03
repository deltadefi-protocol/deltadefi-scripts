use aiken/collection/dict
use aiken/interval.{is_entirely_after}
use cardano/assets.{PolicyId}
use cardano/transaction.{Transaction}
use cocktail/vodka_outputs.{output_inline_datum, outputs_at_with_policy}
use hydra_dex/types.{
  AppOracleDatum, EmergencyCancelRequestDatum, MintPolarity, RBurn, RMint,
}
use hydra_dex/utils.{get_app_oracle_datum}

validator emergency_cancel_order_request(oracle_nft: PolicyId) {
  mint(redeemer: MintPolarity, policy_id: PolicyId, self: Transaction) {
    // It checks that only one minted asset exists and will fail otherwise
    expect [Pair(_asset_name, quantity)] =
      self.mint
        |> assets.tokens(policy_id)
        |> dict.to_pairs()
    let Transaction { outputs, reference_inputs, validity_range, .. } = self
    when redeemer is {
      RMint -> {
        let oracle_input_datum: AppOracleDatum =
          reference_inputs |> get_app_oracle_datum(oracle_nft)
        expect [cancel_request_output] =
          outputs_at_with_policy(
            outputs,
            oracle_input_datum.emergency_cancel_order_request_address,
            policy_id,
          )
        expect output_datum: EmergencyCancelRequestDatum =
          output_inline_datum(cancel_request_output)

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
