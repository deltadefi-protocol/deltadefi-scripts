use aiken/builtin.{blake2b_256}
use aiken/cbor
use aiken/collection/dict
use aiken/collection/list
use aiken/merkle_patricia_forestry/merkling.{null_hash}
use aiken/primitive/bytearray
use cardano/address.{Credential}
use cardano/assets.{PolicyId, quantity_of, tokens}
use cardano/certificate.{Certificate}
use cardano/transaction.{InlineDatum, Input, Output, Transaction}
use cocktail.{outputs_with_policy}
use hydra_dex/hydra_tree_utils.{Tree, compute_tree_hash, extract_key_values}
use hydra_dex/types.{DexOrderBookDatum, HydraOrderBookDatum}
use hydra_dex/utils.{get_dex_order_book_datum}

validator combine_order_merkle(oracle_nft: PolicyId) {
  withdraw(redeemer: Tree, _credential: Credential, tx: Transaction) {
    let Transaction { inputs, outputs, .. } = tx
    let input_dex_order_book_datum: DexOrderBookDatum =
      inputs |> get_dex_order_book_datum(oracle_nft)
    let DexOrderBookDatum {
      hydra_order_book_address,
      hydra_order_book_token,
      dex_order_book_token,
      dex_order_book_address,
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
      inputs
        |> list.filter(
            fn(input: Input) {
              input.output.address == hydra_order_book_address && dict.size(
                tokens(input.output.value, hydra_order_book_token),
              ) == 1
            },
          )

    let hydra_account_balance_burnt_check =
      outputs_with_policy(outputs, hydra_order_book_token) == []

    let serialised_inputs: List<Pair<ByteArray, ByteArray>> =
      hydra_order_book_inputs
        |> list.map(
            fn(input: Input) {
              expect InlineDatum(input_datum) = input.output.datum
              expect order_book_datum: HydraOrderBookDatum = input_datum
              Pair(order_book_datum.order_id, cbor.serialise(order_book_datum))
            },
          )
    let sorted_serialised_inputs: List<Pair<ByteArray, ByteArray>> =
      serialised_inputs
        |> list.sort(
            fn(a: Pair<ByteArray, ByteArray>, b: Pair<ByteArray, ByteArray>) {
              bytearray.compare(blake2b_256(a.1st), blake2b_256(b.1st))
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
    and {
      (input_dex_order_book_datum.limit_orders_merkle_root == null_hash)?,
      (compute_tree_hash(redeemer) == output_dex_order_book_datum.limit_orders_merkle_root)?,
      (extract_key_values(redeemer) == sorted_serialised_inputs)?,
      hydra_account_balance_burnt_check?,
    }
  }

  publish(_redeemer: Data, _credential: Certificate, _tx: Transaction) {
    True
  }

  else(_) {
    fail @"unsupported purpose"
  }
}
