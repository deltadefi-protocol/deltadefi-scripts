use aiken/builtin.{blake2b_256}
use aiken/cbor
use aiken/collection/list
use aiken/merkle_patricia_forestry as mpf
use aiken/merkle_patricia_forestry/merkling.{null_hash}
use aiken/primitive/bytearray
use cardano/address.{from_script}
use cardano/assets.{
  PolicyId, Value, merge, negate, quantity_of, without_lovelace, zero,
}
use cardano/transaction.{InlineDatum, Input, Output, Transaction}
use cocktail.{inputs_at}
use hydra_dex/account_utils.{from_hydra_balance_to_value}
use hydra_dex/hydra_tree_utils.{
  compute_tree_hash, extract_key_values, recursive_insert,
}
use hydra_dex/order_utils.{order_datum_to_merkle_datum}
use hydra_dex/types.{
  DexOrderBookDatum, FullTree, MerklizedOrderDatum, Order, Proofs, TokenMap,
  TreeOrProofs,
}
use hydra_dex/utils.{get_dex_order_book_datum, to_mvalue}

pub fn combine_order_merkle(
  oracle_nft: PolicyId,
  tree_or_proofs: TreeOrProofs,
  token_map: TokenMap,
  tx: Transaction,
) {
  let Transaction { inputs, outputs, mint, .. } = tx
  let oracle = inputs |> get_dex_order_book_datum(oracle_nft)
  let DexOrderBookDatum {
    dex_order_book_token,
    dex_order_book_address,
    hydra_token_policy_id,
    hydra_order_book_script_hash,
    ..
  } = oracle

  let hydra_order_book_address = from_script(hydra_order_book_script_hash)

  //  - For every single order input from `HydraOrderBook` combine it into merkle tree
  //  - All `HydraTokens` locked in orders are burnt
  let hydra_order_book_inputs: List<Input> =
    inputs_at(inputs, hydra_order_book_address)
  let (serialised_inputs, to_burn_value): (Pairs<ByteArray, ByteArray>, Value) =
    hydra_order_book_inputs
      |> list.foldr(
          ([], zero),
          fn(input: Input, acc) {
            let order_value = without_lovelace(input.output.value)
            expect InlineDatum(input_datum) = input.output.datum
            expect order_book_datum: Order = input_datum
            let merkle_datum =
              MerklizedOrderDatum {
                datum: order_book_datum
                  |> order_datum_to_merkle_datum(token_map),
                value: order_value
                  |> from_hydra_balance_to_value(
                      hydra_token_policy_id,
                      token_map,
                    )
                  |> to_mvalue,
              }
            (
              acc.1st
                |> list.push(
                    Pair(
                      order_book_datum.order_id,
                      cbor.serialise(merkle_datum),
                    ),
                  ),
              acc.2nd |> merge(order_value),
            )
          },
        )

  let is_all_hydra_tokens_burnt = negate(to_burn_value) == mint

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

  let is_merkle_root_updated =
    when tree_or_proofs is {
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

  and {
    is_all_hydra_tokens_burnt?,
    is_merkle_root_updated?,
  }
}
