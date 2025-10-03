use aiken/cbor
use aiken/collection/list
use aiken/merkle_patricia_forestry/merkling.{null_hash}
use cardano/address.{Credential}
use cardano/assets.{PolicyId, quantity_of}
use cardano/transaction.{InlineDatum, Input, Output, Transaction}
use hydra_dex/hydra_tree_utils.{Tree, compute_tree_hash, extract_key_values}
use hydra_dex/types.{
  DexAccountBalanceDatum, DexOrderBookDatum, HydraAccountBalanceDatum,
}
use hydra_dex/utils.{get_dex_order_book_datum}

validator hydra_head_open(oracle_nft: PolicyId) {
  withdraw(redeemer: Tree, _credential: Credential, tx: Transaction) {
    let Transaction { inputs, reference_inputs, outputs, .. } = tx
    let DexOrderBookDatum {
      dex_account_balance_token,
      dex_account_balance_address,
      hydra_account_balance_address,
      hydra_account_balance_token,
      ..
    }: DexOrderBookDatum =
      reference_inputs |> get_dex_order_book_datum(oracle_nft)
    expect Some(dex_account_balance_input) =
      inputs
        |> list.find(
            fn(input: Input) {
              input.output.address == dex_account_balance_address && quantity_of(
                input.output.value,
                dex_account_balance_token,
                "",
              ) == 1
            },
          )
    expect InlineDatum(tree_root) = dex_account_balance_input.output.datum
    expect DexAccountBalanceDatum { account_balance_merkle_root }: DexAccountBalanceDatum =
      tree_root
    let key_values = extract_key_values(redeemer)
    let filtered_outputs =
      outputs
        |> list.filter(
            fn(output: Output) {
              output.address == hydra_account_balance_address && quantity_of(
                output.value,
                hydra_account_balance_token,
                "",
              ) == 1
            },
          )
    // The way account balances are serialised into the tree is to have
    // the key as the serialised account, and the value is the serialised balance.
    let output_serialised_datum_list: List<Pair<ByteArray, ByteArray>> =
      filtered_outputs
        |> list.map(
            fn(output: Output) {
              expect InlineDatum(output_datum) = output.datum
              expect HydraAccountBalanceDatum { account, balance }: HydraAccountBalanceDatum =
                output_datum
              Pair(cbor.serialise(account), cbor.serialise(balance))
            },
          )
    expect [dex_account_balance_output] =
      list.filter(
        outputs,
        fn(output: Output) {
          output.address == dex_account_balance_address && quantity_of(
            output.value,
            dex_account_balance_token,
            "",
          ) == 1
        },
      )
    expect InlineDatum(output_datum) = dex_account_balance_output.datum
    expect output_account_balance_datum: DexAccountBalanceDatum = output_datum
    and {
      (compute_tree_hash(redeemer) == account_balance_merkle_root)?,
      (key_values == output_serialised_datum_list)?,
      (output_account_balance_datum.account_balance_merkle_root == null_hash)?,
    }
  }

  else(_) {
    fail
  }
}
