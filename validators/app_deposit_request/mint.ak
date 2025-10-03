use cardano/assets.{PolicyId, add, from_asset_list}
use cardano/transaction.{Transaction}
use cocktail.{
  output_inline_datum, outputs_at_with_policy, policy_only_minted_token,
}
use hydra_dex/types.{
  AppDepositRequestDatum, AppOracleDatum, MintPolarity, RBurn, RMint,
}
use hydra_dex/utils.{get_app_oracle_datum}

validator app_deposit_request(oracle_nft: PolicyId) {
  mint(redeemer: MintPolarity, policy_id: PolicyId, self: Transaction) {
    // It checks that only one minted asset exists and will fail otherwise

    let Transaction { outputs, reference_inputs, mint, .. } = self

    let oracle_input_datum: AppOracleDatum =
      reference_inputs |> get_app_oracle_datum(oracle_nft)
    when
      (
        redeemer,
        outputs_at_with_policy(
          outputs,
          oracle_input_datum.app_deposit_request_address,
          policy_id,
        ),
      )
    is {
      (RMint, [deposit_request_output]) -> {
        let is_mint_value_correct =
          policy_only_minted_token(mint, policy_id, "", 1)
        expect AppDepositRequestDatum { amount, .. }: AppDepositRequestDatum =
          output_inline_datum(deposit_request_output)

        let is_value_deposited =
          deposit_request_output.value == (
            from_asset_list(amount) |> add(policy_id, "", 1)
          )
        is_value_deposited? && is_mint_value_correct?
      }
      (RBurn, _) -> policy_only_minted_token(mint, policy_id, "", -1)
      _ -> False
    }
    // No need to check if output is consumed for burning
  }

  else(_) {
    fail
  }
}
