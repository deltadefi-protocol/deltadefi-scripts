use cardano/assets.{PolicyId}
use cardano/script_context.{ScriptContext}
use cardano/transaction.{Transaction}
use hydra_dex/types.{
  CancelOrder, CombineOrderMerkle, DexOrderBookDatum,
  DexOrderBookWithdrawalScripts, FillOrder, HydraOrderBookRedeemer, PlaceOrder,
  SplitOrderMerkle,
}
use hydra_dex/utils.{get_dex_order_book_datum, withdrawal_script_validated}

validator hydra_order_book(oracle_nft: PolicyId) {
  mint(redeemer: HydraOrderBookRedeemer, _policy_id: PolicyId, tx: Transaction) {
    let Transaction { withdrawals, reference_inputs, inputs, .. } = tx
    let DexOrderBookDatum {
      withdrawal_script_hashes: DexOrderBookWithdrawalScripts {
        hydra_place_order,
        hydra_fill_order,
        hydra_cancel_order,
        combine_order_merkle,
        split_order_merkle,
        ..
      },
      ..
    }: DexOrderBookDatum =
      if redeemer == CombineOrderMerkle || redeemer == SplitOrderMerkle {
        inputs |> get_dex_order_book_datum(oracle_nft)
      } else {
        reference_inputs |> get_dex_order_book_datum(oracle_nft)
      }
    when redeemer is {
      PlaceOrder -> withdrawal_script_validated(withdrawals, hydra_place_order)
      CancelOrder ->
        withdrawal_script_validated(withdrawals, hydra_cancel_order)
      FillOrder -> withdrawal_script_validated(withdrawals, hydra_fill_order)
      CombineOrderMerkle ->
        withdrawal_script_validated(withdrawals, combine_order_merkle)
      SplitOrderMerkle ->
        withdrawal_script_validated(withdrawals, split_order_merkle)
      _ -> False
    }
  }

  else(_ctx: ScriptContext) {
    fail
  }
}
