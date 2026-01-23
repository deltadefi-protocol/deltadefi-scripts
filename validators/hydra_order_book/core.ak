use cardano/address.{Credential}
use cardano/assets.{PolicyId}
use cardano/certificate.{Certificate}
use cardano/script_context.{ScriptContext}
use cardano/transaction.{OutputReference, Transaction}
use cocktail.{withdrawal_script_validated}
use hydra_dex/types.{
  CancelOrder, CombineOrderMerkle, DexOrderBookDatum, FillOrder,
  HydraOrderBookRedeemer, ModifyOrder, Order, PlaceOrder, SplitOrderMerkle,
  TreeOrProofsWithTokenMap,
}
use hydra_dex/utils.{get_dex_order_book_datum}
use hydra_order_book/cancel_order.{cancel_order}
use hydra_order_book/combine_order_merkle.{combine_order_merkle}
use hydra_order_book/fill_order.{fill_order}
use hydra_order_book/modify_order.{modify_order}
use hydra_order_book/place_order.{place_order}
use hydra_order_book/split_order_merkle.{split_order_merkle}

validator hydra_order_book(oracle_nft: PolicyId) {
  // todo: spam prevention
  spend(
    _datum_opt: Option<Order>,
    _redeemer: Data,
    _input: OutputReference,
    tx: Transaction,
  ) {
    let Transaction { reference_inputs, withdrawals, .. } = tx
    let DexOrderBookDatum { hydra_order_book_script_hash, .. }: DexOrderBookDatum =
      reference_inputs
        |> get_dex_order_book_datum(oracle_nft)

    withdrawal_script_validated(withdrawals, hydra_order_book_script_hash)?
  }

  withdraw(
    redeemer: HydraOrderBookRedeemer,
    _credential: Credential,
    tx: Transaction,
  ) {
    when redeemer is {
      PlaceOrder { account } -> place_order(oracle_nft, account, tx)
      FillOrder { filler_order_id } ->
        fill_order(oracle_nft, filler_order_id, tx)
      CancelOrder -> cancel_order(oracle_nft, tx)
      ModifyOrder { account } -> modify_order(oracle_nft, account, tx)
      CombineOrderMerkle { tree_or_proofs_with_token_map } -> {
        let TreeOrProofsWithTokenMap { proof, token_map } =
          tree_or_proofs_with_token_map
        combine_order_merkle(oracle_nft, proof, token_map, tx)
      }
      SplitOrderMerkle { tree_or_proofs_with_token_map } -> {
        let TreeOrProofsWithTokenMap { proof, token_map } =
          tree_or_proofs_with_token_map
        split_order_merkle(oracle_nft, proof, token_map, tx)
      }
    }
  }

  publish(_redeemer: Data, _credential: Certificate, _tx: Transaction) {
    True
  }

  else(_ctx: ScriptContext) {
    fail
  }
}
