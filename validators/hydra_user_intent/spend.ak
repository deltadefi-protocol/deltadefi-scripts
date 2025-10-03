use cardano/assets.{PolicyId, negate, restricted_to}
use cardano/transaction.{OutputReference, Transaction, find_input}
use hydra_dex/types.{DexOrderBookDatum, HydraUserIntentDatum}
use hydra_dex/utils.{get_dex_order_book_datum}

validator hydra_user_intent(dex_oracle_nft: PolicyId) {
  spend(
    _datum: Option<HydraUserIntentDatum>,
    _redeemer: Data,
    utxo: OutputReference,
    self: Transaction,
  ) {
    let Transaction { reference_inputs, mint, inputs, .. } = self
    let DexOrderBookDatum { hydra_user_intent_token, .. }: DexOrderBookDatum =
      reference_inputs
        |> get_dex_order_book_datum(dex_oracle_nft)

    expect Some(own_input) = find_input(inputs, utxo)
    let is_intent_burnt =
      restricted_to(mint, [hydra_user_intent_token]) == negate(
        restricted_to(own_input.output.value, [hydra_user_intent_token]),
      )

    is_intent_burnt?
  }

  else(_) {
    fail
  }
}
