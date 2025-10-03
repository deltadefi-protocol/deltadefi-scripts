use aiken/builtin.{blake2b_256}
use aiken/cbor
use aiken/collection/list.{length}
use aiken/merkle_patricia_forestry/merkling.{null_hash}
use aiken/primitive/bytearray
use cardano/address.{Credential}
use cardano/assets.{PolicyId, quantity_of}
use cardano/certificate.{Certificate}
use cardano/transaction.{InlineDatum, Input, Output, Transaction}
use cocktail.{only_minted_token}
use hydra_dex/hydra_tree_utils.{Tree, compute_tree_hash, extract_key_values}
use hydra_dex/types.{
  DexAccountBalanceDatum, DexOrderBookDatum, HydraAccountBalanceDatum,
}
use hydra_dex/utils.{get_dex_order_book_datum}

validator hydra_head_close(oracle_nft: PolicyId) {
  withdraw(redeemer: Tree, _credential: Credential, tx: Transaction) {
    let Transaction { inputs, reference_inputs, outputs, mint, .. } = tx
    let DexOrderBookDatum {
      dex_account_balance_token,
      dex_account_balance_address,
      hydra_account_balance_address,
      hydra_account_balance_token,
      ..
    }: DexOrderBookDatum =
      reference_inputs |> get_dex_order_book_datum(oracle_nft)
    let account_balance_inputs: List<Input> =
      inputs
        |> list.filter(
            fn(input: Input) {
              input.output.address == hydra_account_balance_address && quantity_of(
                input.output.value,
                hydra_account_balance_token,
                "",
              ) == 1
            },
          )

    let hydra_account_balance_burnt_check =
      only_minted_token(
        mint,
        hydra_account_balance_token,
        "",
        ( account_balance_inputs |> length() ) * -1,
      )
    expect [dex_account_balance_input] =
      inputs
        |> list.filter(
            fn(input: Input) {
              input.output.address == dex_account_balance_address && quantity_of(
                input.output.value,
                dex_account_balance_token,
                "",
              ) == 1
            },
          )
    let serialised_inputs: List<Pair<ByteArray, ByteArray>> =
      account_balance_inputs
        |> list.map(
            fn(input: Input) {
              expect InlineDatum(input_datum) = input.output.datum
              expect account_datum: HydraAccountBalanceDatum = input_datum
              Pair(
                cbor.serialise(account_datum.account),
                cbor.serialise(account_datum.balance),
              )
            },
          )
    let sorted_serialised_inputs: List<Pair<ByteArray, ByteArray>> =
      serialised_inputs
        |> list.sort(
            fn(a: Pair<ByteArray, ByteArray>, b: Pair<ByteArray, ByteArray>) {
              bytearray.compare(blake2b_256(a.1st), blake2b_256(b.1st))
            },
          )
    expect [dex_account_balance_output] =
      outputs
        |> list.filter(
            fn(output: Output) {
              output.address == dex_account_balance_address && quantity_of(
                output.value,
                dex_account_balance_token,
                "",
              ) == 1
            },
          )
    expect InlineDatum(input_datum) = dex_account_balance_input.output.datum
    expect input_dex_account_balance_datum: DexAccountBalanceDatum = input_datum
    expect InlineDatum(output_datum) = dex_account_balance_output.datum
    expect output_account_balance_datum: DexAccountBalanceDatum = output_datum
    and {
      (input_dex_account_balance_datum.account_balance_merkle_root == null_hash)?,
      (compute_tree_hash(redeemer) == output_account_balance_datum.account_balance_merkle_root)?,
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
