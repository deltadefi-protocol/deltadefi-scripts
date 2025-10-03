use aiken/collection/list
use aiken/merkle_patricia_forestry as mpf
use cardano/assets.{PolicyId}
use cardano/transaction.{Output, Transaction}
use cocktail.{inputs_with_policy, output_inline_datum, outputs_at_with_policy}
use cocktail/vodka_extra_signatories.{key_signed}
use cocktail/vodka_mints.{check_policy_only_burn}
use hydra_dex/types.{
  AppOracleDatum, DexAccountBalanceDatum, MintPolarity, RBurn, RMint,
}
use hydra_dex/utils.{get_app_oracle_datum}

validator dex_account_balance(oracle_nft: PolicyId) {
  mint(redeemer: MintPolarity, policy_id: PolicyId, self: Transaction) {
    let Transaction {
      inputs,
      outputs,
      extra_signatories,
      mint,
      reference_inputs,
      ..
    } = self
    when redeemer is {
      RMint -> {
        trace oracle_nft
        let AppOracleDatum { dex_account_balance_address, operation_key, .. } =
          reference_inputs |> get_app_oracle_datum(oracle_nft)
        let no_input_with_current_token =
          when inputs_with_policy(inputs, policy_id) is {
            [] -> True
            _ -> False
          }

        let outputs_with_policy =
          outputs_at_with_policy(
            outputs,
            dex_account_balance_address,
            policy_id,
          )
        let is_all_root_empty =
          list.all(
            outputs_with_policy,
            fn(output: Output) -> Bool {
              expect DexAccountBalanceDatum { account_balance_merkle_root }: DexAccountBalanceDatum =
                output_inline_datum(output)

              let is_empty_root =
                account_balance_merkle_root == mpf.root(mpf.empty)
              is_empty_root
            },
          )
        let is_operation_key_signed =
          key_signed(extra_signatories, operation_key)

        no_input_with_current_token? && is_all_root_empty? && is_operation_key_signed?
      }
      RBurn -> check_policy_only_burn(mint, policy_id)
    }
    // No need to check if output is consumed for burning
  }

  else(_) {
    fail
  }
}
