use cardano/assets.{PolicyId}
use cardano/script_context.{ScriptContext}
use cardano/transaction.{Transaction}
use cocktail.{inputs_with_policy, withdrawal_script_validated}
use hydra_dex/types.{
  BurnAtHydraClose, BurnAtWithdrawal, DexOrderBookDatum,
  DexOrderBookWithdrawalScripts, HydraTokensRedeemer, MintAtHydraOpen,
}
use hydra_dex/utils.{get_dex_order_book_datum}

validator hydra_tokens(oracle_nft: PolicyId) {
  mint(redeemer: HydraTokensRedeemer, _policy_id: PolicyId, tx: Transaction) {
    let Transaction { withdrawals, reference_inputs, inputs, .. } = tx
    let DexOrderBookDatum {
      withdrawal_script_hashes: DexOrderBookWithdrawalScripts {
        hydra_head_open,
        hydra_head_close,
        hydra_withdrawal,
        ..
      },
      ..
    }: DexOrderBookDatum =
      if inputs_with_policy(inputs, oracle_nft) == [] {
        reference_inputs |> get_dex_order_book_datum(oracle_nft)
      } else {
        inputs |> get_dex_order_book_datum(oracle_nft)
      }
    when redeemer is {
      MintAtHydraOpen ->
        withdrawal_script_validated(withdrawals, hydra_head_open)
      BurnAtHydraClose ->
        withdrawal_script_validated(withdrawals, hydra_head_close)
      BurnAtWithdrawal ->
        withdrawal_script_validated(withdrawals, hydra_withdrawal)
    }
  }

  else(_ctx: ScriptContext) {
    fail
  }
}
