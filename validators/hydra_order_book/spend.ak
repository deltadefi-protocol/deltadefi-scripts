use cardano/assets.{PolicyId}
use cardano/script_context.{ScriptContext}
use cardano/transaction.{OutputReference, Transaction}
use hydra_dex/types.{
  CancelOrder, CombineOrderMerkle, DexOrderBookDatum,
  DexOrderBookWithdrawalScripts, FillOrder, HydraOrderBookDatum,
  HydraOrderBookRedeemer, ReleaseExtraValue,
}
use hydra_dex/utils.{get_dex_order_book_datum, withdrawal_script_validated}

validator hydra_order_book(oracle_nft: PolicyId) {
  spend(
    _datum_opt: Option<HydraOrderBookDatum>,
    redeemer: HydraOrderBookRedeemer,
    _input: OutputReference,
    tx: Transaction,
  ) {
    let Transaction { withdrawals, reference_inputs, inputs, .. } = tx
    let DexOrderBookDatum {
      withdrawal_script_hashes: DexOrderBookWithdrawalScripts {
        hydra_fill_order,
        hydra_cancel_order,
        hydra_release_extra_value,
        combine_order_merkle,
        ..
      },
      ..
    }: DexOrderBookDatum =
      if redeemer == CombineOrderMerkle {
        inputs |> get_dex_order_book_datum(oracle_nft)
      } else {
        reference_inputs |> get_dex_order_book_datum(oracle_nft)
      }
    when redeemer is {
      FillOrder -> withdrawal_script_validated(withdrawals, hydra_fill_order)
      CancelOrder ->
        withdrawal_script_validated(withdrawals, hydra_cancel_order)
      ReleaseExtraValue ->
        withdrawal_script_validated(withdrawals, hydra_release_extra_value)
      CombineOrderMerkle ->
        withdrawal_script_validated(withdrawals, combine_order_merkle)
      _ -> False
    }
  }

  else(_ctx: ScriptContext) {
    fail
  }
}
