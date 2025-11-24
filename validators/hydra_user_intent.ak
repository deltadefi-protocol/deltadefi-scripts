use cardano/address.{from_script}
use cardano/assets.{PolicyId, negate, restricted_to}
use cardano/transaction.{OutputReference, Transaction, find_input}
use cocktail.{
  key_signed, only_minted_token, output_inline_datum, outputs_at_with_policy,
}
use hydra_dex/account_utils.{master_auth_by_account, trade_auth_by_account}
use hydra_dex/types.{
  BurnIntent, DexOrderBookDatum, HydraUserIntentDatum, HydraUserIntentRedeemer,
  MasterIntent, MintMasterIntent, MintTradeIntent, TradeIntent,
}
use hydra_dex/utils.{get_dex_order_book_datum}

validator hydra_user_intent(dex_oracle_nft: PolicyId) {
  spend(
    _datum: Option<HydraUserIntentDatum>,
    _redeemer: Data,
    utxo: OutputReference,
    self: Transaction,
  ) {
    let Transaction { reference_inputs, mint, inputs, .. } = self
    let DexOrderBookDatum { hydra_user_intent_script_hash, .. }: DexOrderBookDatum =
      reference_inputs
        |> get_dex_order_book_datum(dex_oracle_nft)

    expect Some(own_input) = find_input(inputs, utxo)
    let is_intent_burnt =
      restricted_to(mint, [hydra_user_intent_script_hash]) == negate(
        restricted_to(own_input.output.value, [hydra_user_intent_script_hash]),
      )

    is_intent_burnt?
  }

  mint(
    redeemer: HydraUserIntentRedeemer,
    policy_id: PolicyId,
    self: Transaction,
  ) {
    let Transaction {
      mint,
      reference_inputs,
      withdrawals,
      extra_signatories,
      outputs,
      ..
    } = self

    let oracle: DexOrderBookDatum =
      reference_inputs
        |> get_dex_order_book_datum(dex_oracle_nft)

    let hydra_user_intent_address =
      from_script(oracle.hydra_user_intent_script_hash)
    when redeemer is {
      MintTradeIntent { account, intent } -> {
        let token_check = only_minted_token(mint, policy_id, "", 1)
        let only_output_check =
          when
            outputs_at_with_policy(
              outputs,
              hydra_user_intent_address,
              oracle.hydra_user_intent_script_hash,
            )
          is {
            [only_output] -> {
              expect TradeIntent {
                account: output_account,
                intent: output_intent,
              }: HydraUserIntentDatum = output_inline_datum(only_output)
              output_account == account && output_intent == intent
            }
            _ -> False
          }

        let is_account_auth =
          trade_auth_by_account(account, withdrawals, extra_signatories)
        token_check? && only_output_check? && is_account_auth?
      }
      MintMasterIntent { account, intent } -> {
        let token_check = only_minted_token(mint, policy_id, "", 1)
        let only_output_check =
          when
            outputs_at_with_policy(
              outputs,
              hydra_user_intent_address,
              oracle.hydra_user_intent_script_hash,
            )
          is {
            [only_output] -> {
              expect MasterIntent {
                account: output_account,
                intent: output_intent,
              }: HydraUserIntentDatum = output_inline_datum(only_output)
              output_account == account && output_intent == intent
            }
            _ -> False
          }

        let is_account_auth =
          master_auth_by_account(account, withdrawals, extra_signatories)
        token_check? && only_output_check? && is_account_auth?
      }
      BurnIntent -> key_signed(extra_signatories, oracle.operation_key)
    }
  }

  else(_) {
    fail
  }
}
