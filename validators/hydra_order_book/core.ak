use cardano/address.{Credential}
use cardano/assets.{PolicyId}
use cardano/certificate.{Certificate}
use cardano/script_context.{ScriptContext}
use cardano/transaction.{OutputReference, Transaction, find_input}
use cocktail.{address_script_hash}
use cocktail/vodka_redeemers.{withdrawal_redeemer}
use hydra_dex/types.{
  CancelOrder, CombineOrderMerkle, FillOrder, HydraOrderBookDatum,
  HydraOrderBookRedeemer, ModifyOrder, PlaceOrder, SplitOrderMerkle,
  TreeOrProofsWithTokenMap,
}
use hydra_order_book/combine_order_merkle.{combine_order_merkle}
use hydra_order_book/modify_order.{modify_order}
use hydra_order_book/place_order.{place_order}
use hydra_order_book/split_order_merkle.{split_order_merkle}

validator hydra_order_book(oracle_nft: PolicyId) {
  spend(
    _datum_opt: Option<HydraOrderBookDatum>,
    redeemer: Data,
    input: OutputReference,
    tx: Transaction,
  ) {
    let Transaction { redeemers, inputs, .. } = tx
    expect Some(own_input) = find_input(inputs, input)
    expect Some(script_hash) = address_script_hash(own_input.output.address)
    expect Some(w_redeemer) = withdrawal_redeemer(redeemers, script_hash)
    redeemer == w_redeemer
  }

  withdraw(
    redeemer: HydraOrderBookRedeemer,
    _credential: Credential,
    tx: Transaction,
  ) {
    when redeemer is {
      PlaceOrder { red_account } -> place_order(oracle_nft, red_account, tx)
      FillOrder { .. } -> True
      CancelOrder { .. } -> True
      ModifyOrder { red_account } -> modify_order(oracle_nft, red_account, tx)
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
