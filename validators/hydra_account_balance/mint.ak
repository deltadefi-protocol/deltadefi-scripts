use aiken/collection/dict
use cardano/assets.{PolicyId, from_asset_list, zero}
use cardano/transaction.{Transaction}
use cocktail.{output_inline_datum, outputs_at_with_policy}
use cocktail/vodka_extra_signatories.{key_signed}
use cocktail/vodka_inputs.{inputs_with_policy}
use cocktail/vodka_mints.{check_policy_only_burn}
use hydra_dex/types.{
  DexOrderBookDatum, HydraAccountBalanceDatum, MintPolarity, RBurn, RMint,
}
use hydra_dex/utils.{get_dex_order_book_datum, withdrawal_script_validated}

validator hydra_account_balance(dex_oracle_nft: PolicyId) {
  mint(redeemer: MintPolarity, policy_id: PolicyId, self: Transaction) {
    // It checks that only one minted asset exists and will fail otherwise

    let Transaction {
      mint,
      inputs,
      extra_signatories,
      outputs,
      reference_inputs,
      withdrawals,
      ..
    } = self

    when redeemer is {
      RMint -> {
        let DexOrderBookDatum {
          hydra_account_balance_address,
          operation_key,
          withdrawal_script_hashes,
          ..
        }: DexOrderBookDatum =
          reference_inputs
            |> get_dex_order_book_datum(dex_oracle_nft)
        when
          withdrawal_script_validated(
            withdrawals,
            withdrawal_script_hashes.hydra_head_open,
          )
        is {
          True -> True
          _ -> {
            let no_input_with_current_token =
              when inputs_with_policy(inputs, policy_id) is {
                [] -> True
                _ -> False
              }

            expect [hydra_account_balance_output] =
              outputs_at_with_policy(
                outputs,
                hydra_account_balance_address,
                policy_id,
              )
            expect HydraAccountBalanceDatum { balance, .. }: HydraAccountBalanceDatum =
              output_inline_datum(hydra_account_balance_output)

            let is_empty_balance = from_asset_list(balance) == zero

            expect [Pair(_asset_name, quantity)] =
              mint |> assets.tokens(policy_id) |> dict.to_pairs()
            let is_single_token_minted = quantity == 1
            let is_operation_key_signed =
              key_signed(extra_signatories, operation_key)

            no_input_with_current_token? && is_empty_balance? && is_single_token_minted? && is_operation_key_signed?
          }
        }
      }

      RBurn -> check_policy_only_burn(mint, policy_id)
    }
  }

  else(_) {
    fail
  }
}
