use aiken/builtin.{blake2b_256}
use aiken/cbor
use aiken/collection/list
use aiken/merkle_patricia_forestry as mpf
use aiken/merkle_patricia_forestry/merkling.{null_hash}
use aiken/primitive/bytearray
use cardano/address.{Credential}
use cardano/assets.{PolicyId, quantity_of, without_lovelace}
use cardano/certificate.{Certificate}
use cardano/transaction.{InlineDatum, Input, Output, Transaction}
use hydra_dex/account_utils.{from_hydra_balance_to_value}
use hydra_dex/hydra_tree_utils.{
  compute_tree_hash, extract_key_values, recursive_insert,
}
use hydra_dex/types.{
  DexOrderBookDatum, FullTree, HydraOrderBookDatum, MerklizedOrderDatum, Proofs,
  TreeOrProofsWithTokenMap,
}
use hydra_dex/utils.{get_dex_order_book_datum, to_mvalue}
use hydra_dex/vodka.{inputs_at}

validator combine_order_merkle(oracle_nft: PolicyId) {
  withdraw(
    redeemer: TreeOrProofsWithTokenMap,
    _credential: Credential,
    tx: Transaction,
  ) {
    let TreeOrProofsWithTokenMap { proof: redeemer_proof, token_map } = redeemer
    let Transaction { inputs, outputs, .. } = tx
    let input_dex_order_book_datum: DexOrderBookDatum =
      inputs |> get_dex_order_book_datum(oracle_nft)
    let DexOrderBookDatum {
      hydra_order_book_address,
      dex_order_book_token,
      dex_order_book_address,
      hydra_tokens_policy_id,
      ..
    } = input_dex_order_book_datum
    expect [dex_order_book_input] =
      inputs
        |> list.filter(
            fn(input: Input) {
              input.output.address == dex_order_book_address && quantity_of(
                input.output.value,
                dex_order_book_token,
                "",
              ) == 1
            },
          )
    expect InlineDatum(input_datum) = dex_order_book_input.output.datum
    expect input_dex_order_book_datum: DexOrderBookDatum = input_datum
    let hydra_order_book_inputs: List<Input> =
      inputs_at(inputs, hydra_order_book_address)

    let serialised_inputs: List<Pair<ByteArray, ByteArray>> =
      hydra_order_book_inputs
        |> list.map(
            fn(input: Input) {
              expect InlineDatum(input_datum) = input.output.datum
              expect order_book_datum: HydraOrderBookDatum = input_datum
              let merkle_datum =
                MerklizedOrderDatum {
                  datum: order_book_datum,
                  value: input.output.value
                    |> without_lovelace
                    |> from_hydra_balance_to_value(
                        hydra_tokens_policy_id,
                        token_map,
                      )
                    |> to_mvalue,
                }
              Pair(order_book_datum.order_id, cbor.serialise(merkle_datum))
            },
          )

    expect [dex_order_book_output] =
      outputs
        |> list.filter(
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
        let sorted_serialised_inputs: List<Pair<ByteArray, ByteArray>> =
          serialised_inputs
            |> list.sort(
                fn(a: Pair<ByteArray, ByteArray>, b: Pair<ByteArray, ByteArray>) {
                  bytearray.compare(blake2b_256(a.1st), blake2b_256(b.1st))
                },
              )
        and {
          (input_dex_order_book_datum.limit_orders_merkle_root == null_hash)?,
          (compute_tree_hash(tree) == output_dex_order_book_datum.limit_orders_merkle_root)?,
          (extract_key_values(tree) == sorted_serialised_inputs)?,
        }
      }
      Proofs { proofs } -> {
        let old_root: mpf.MerklePatriciaForestry =
          mpf.from_root(input_dex_order_book_datum.limit_orders_merkle_root)
        let new_root: mpf.MerklePatriciaForestry =
          mpf.from_root(output_dex_order_book_datum.limit_orders_merkle_root)
        let computed_new_root: mpf.MerklePatriciaForestry =
          recursive_insert(old_root, serialised_inputs, proofs)

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
