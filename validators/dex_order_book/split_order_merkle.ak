use aiken/cbor
use aiken/collection/list
use aiken/merkle_patricia_forestry as mpf
use aiken/merkle_patricia_forestry/merkling.{null_hash}
use cardano/address.{Credential}
use cardano/assets.{PolicyId, quantity_of, without_lovelace}
use cardano/certificate.{Certificate}
use cardano/transaction.{InlineDatum, Output, Transaction}
use cocktail.{outputs_at}
use hydra_dex/account_utils.{from_hydra_balance_to_value}
use hydra_dex/hydra_tree_utils.{
  compute_tree_hash, extract_key_values, recursive_delete,
}
use hydra_dex/types.{
  DexOrderBookDatum, FullTree, HydraOrderBookDatum, MerklizedOrderDatum, Proofs,
  TreeOrProofsWithTokenMap,
}
use hydra_dex/utils.{get_dex_order_book_datum, to_mvalue}

validator split_order_merkle(oracle_nft: PolicyId) {
  withdraw(
    redeemer: TreeOrProofsWithTokenMap,
    _credential: Credential,
    tx: Transaction,
  ) {
    let TreeOrProofsWithTokenMap { proof: redeemer_proof, token_map } = redeemer
    let Transaction { inputs, outputs, .. } = tx
    // THe dex order book datum is taken from inputs rather than
    // reference inputs, as the datum is changed in this transaction.
    let input_order_book_datum: DexOrderBookDatum =
      inputs |> get_dex_order_book_datum(oracle_nft)
    let DexOrderBookDatum {
      hydra_order_book_address,
      dex_order_book_token,
      dex_order_book_address,
      limit_orders_merkle_root,
      hydra_tokens_policy_id,
      ..
    } = input_order_book_datum
    let filtered_outputs = outputs_at(outputs, hydra_order_book_address)

    // The way orders are placed into the tree is a little bit different to
    // how they are done in account balance merkle tree. The key is `order_id`
    // and the value is the entire `HydraOrderBookDatum` datum serialised.
    let output_serialised_datum_list: List<Pair<ByteArray, ByteArray>> =
      filtered_outputs
        |> list.map(
            fn(output: Output) {
              expect InlineDatum(output_datum) = output.datum
              expect hydra_order_book_datum: HydraOrderBookDatum = output_datum
              let merkle_datum =
                MerklizedOrderDatum {
                  datum: hydra_order_book_datum,
                  value: output.value
                    |> without_lovelace
                    |> from_hydra_balance_to_value(
                        hydra_tokens_policy_id,
                        token_map,
                      )
                    |> to_mvalue,
                }
              Pair(
                hydra_order_book_datum.order_id,
                cbor.serialise(merkle_datum),
              )
            },
          )
    expect [dex_order_book_output] =
      list.filter(
        outputs,
        fn(output: Output) {
          output.address == dex_order_book_address && quantity_of(
            output.value,
            dex_order_book_token,
            "",
          ) == 1
        },
      )
    expect InlineDatum(output_datum) = dex_order_book_output.datum
    expect output_dex_order_book_datum: DexOrderBookDatum = output_datum
    when redeemer_proof is {
      FullTree { tree } -> {
        let key_values = extract_key_values(tree)
        and {
          (compute_tree_hash(tree) == limit_orders_merkle_root)?,
          (key_values == output_serialised_datum_list)?,
          (output_dex_order_book_datum == DexOrderBookDatum {
            ..input_order_book_datum,
            limit_orders_merkle_root: null_hash,
          })?,
        }
      }
      Proofs { proofs } -> {
        let old_root: mpf.MerklePatriciaForestry =
          mpf.from_root(limit_orders_merkle_root)
        let new_root: mpf.MerklePatriciaForestry =
          mpf.from_root(output_dex_order_book_datum.limit_orders_merkle_root)
        let computed_new_root: mpf.MerklePatriciaForestry =
          recursive_delete(old_root, output_serialised_datum_list, proofs)

        mpf.root(new_root) == mpf.root(computed_new_root)
      }
    }
  }

  publish(_redeemer: Data, _credential: Certificate, _tx: Transaction) {
    True
  }

  else(_) {
    fail @"unsupported purpose"
  }
}
