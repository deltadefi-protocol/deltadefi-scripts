use cardano/assets.{PolicyId}
use cardano/script_context.{ScriptContext}
use cardano/transaction.{Transaction}
use cocktail.{inputs_with_policy, withdrawal_redeemer}
use hydra_dex/types.{
  BurnAtHydraClose, BurnAtWithdrawal, DexOrderBookDatum, HydraAccountRedeemer,
  HydraTokensRedeemer, MintAtCancelWithdrawal, MintAtHydraOpen,
  ProcessCancelWithdrawal, ProcessCombineUtxosAtClose, ProcessSplitUtxosAtOpen,
  ProcessWithdrawal,
}
use hydra_dex/utils.{get_dex_order_book_datum}

validator hydra_tokens(oracle_nft: PolicyId) {
  mint(redeemer: HydraTokensRedeemer, _policy_id: PolicyId, tx: Transaction) {
    let Transaction { redeemers, reference_inputs, inputs, .. } = tx
    let DexOrderBookDatum { hydra_account_script_hash, .. }: DexOrderBookDatum =
      if inputs_with_policy(inputs, oracle_nft) == [] {
        reference_inputs |> get_dex_order_book_datum(oracle_nft)
      } else {
        inputs |> get_dex_order_book_datum(oracle_nft)
      }
    expect Some(w_redeemer) =
      withdrawal_redeemer(redeemers, hydra_account_script_hash)
    expect w_redeemer: HydraAccountRedeemer = w_redeemer

    when redeemer is {
      MintAtHydraOpen ->
        when w_redeemer is {
          ProcessSplitUtxosAtOpen { .. } -> True
          _ -> False
        }
      BurnAtHydraClose ->
        when w_redeemer is {
          ProcessCombineUtxosAtClose { .. } -> True
          _ -> False
        }
      MintAtCancelWithdrawal ->
        when w_redeemer is {
          ProcessCancelWithdrawal { .. } -> True
          _ -> False
        }
      BurnAtWithdrawal ->
        when w_redeemer is {
          ProcessWithdrawal { .. } -> True
          _ -> False
        }
    }
  }

  else(_ctx: ScriptContext) {
    fail
  }
}
