use aiken/cbor
use aiken/collection/list
use aiken/merkle_patricia_forestry as mpf
use aiken/merkle_patricia_forestry/merkling.{null_hash}
use cardano/address.{from_script}
use cardano/assets.{PolicyId, Value, merge, quantity_of, without_lovelace, zero}
use cardano/transaction.{InlineDatum, Output, Transaction}
use cocktail.{outputs_at}
use hydra_dex/account_utils.{from_hydra_balance_to_value}
use hydra_dex/hydra_tree_utils.{
  compute_tree_hash, extract_key_values, recursive_delete,
}
use hydra_dex/order_utils.{order_datum_to_merkle_datum}
use hydra_dex/types.{
  DexOrderBookDatum, FullTree, MerklizedOrderDatum, Order, Proofs, TokenMap,
  TreeOrProofs,
}
use hydra_dex/utils.{get_dex_order_book_datum, to_mvalue}

pub fn split_order_merkle(
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
    limit_orders_merkle_root,
    hydra_token_policy_id,
    hydra_order_book_script_hash,
    ..
  } = oracle
  let hydra_order_book_address = from_script(hydra_order_book_script_hash)
  let filtered_outputs = outputs_at(outputs, hydra_order_book_address)

  // The way orders are placed into the tree is a little bit different to
  // how they are done in account balance merkle tree. The key is `order_id`
  // and the value is the entire `Order` datum serialised.
  let (output_serialised_datum_list, to_mint_value): (
    Pairs<ByteArray, ByteArray>,
    Value,
  ) =
    filtered_outputs
      |> list.foldr(
          ([], zero),
          fn(output: Output, acc) {
            let order_value = without_lovelace(output.value)
            expect InlineDatum(output_datum) = output.datum
            expect hydra_order_book_datum: Order = output_datum
            let merkle_datum =
              MerklizedOrderDatum {
                datum: hydra_order_book_datum
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
                      hydra_order_book_datum.order_id,
                      cbor.serialise(merkle_datum),
                    ),
                  ),
              acc.2nd |> merge(order_value),
            )
          },
        )

  let is_hydra_tokens_minted = to_mint_value == mint

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
  let is_merkle_root_updated =
    when tree_or_proofs is {
      FullTree { tree } -> {
        let key_values = extract_key_values(tree)
        and {
          (compute_tree_hash(tree) == limit_orders_merkle_root)?,
          (key_values == output_serialised_datum_list)?,
          (output_dex_order_book_datum == DexOrderBookDatum {
            ..oracle,
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

  and {
    is_merkle_root_updated?,
    is_hydra_tokens_minted?,
  }
}
