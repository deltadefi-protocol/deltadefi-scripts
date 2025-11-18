use aiken/cbor
use aiken/collection/list
use aiken/merkle_patricia_forestry as mpf
use aiken/merkle_patricia_forestry/merkling.{null_hash}
use cardano/address.{Credential}
use cardano/assets.{PolicyId, Value, merge, restricted_to}
use cardano/transaction.{InlineDatum, Input, Output, Transaction}
use cocktail.{inputs_at_with, key_signed, outputs_at, outputs_at_with}
use hydra_dex/account_utils.{from_hydra_balance_to_value}
use hydra_dex/hydra_tree_utils.{
  compute_tree_hash, extract_key_values, recursive_delete,
}
use hydra_dex/types.{
  DexAccountBalanceDatum, DexOrderBookDatum, FullTree, Proofs,
  TreeOrProofsWithTokenMap, UserAccount,
}
use hydra_dex/utils.{get_dex_order_book_datum}

validator hydra_head_open(oracle_nft: PolicyId) {
  withdraw(
    redeemer: TreeOrProofsWithTokenMap,
    _credential: Credential,
    tx: Transaction,
  ) {
    let TreeOrProofsWithTokenMap { proof: redeemer_proof, token_map } = redeemer
    let Transaction { inputs, reference_inputs, outputs, .. } = tx
    let DexOrderBookDatum {
      dex_account_balance_token,
      dex_account_balance_address,
      hydra_account_balance_address,
      hydra_tokens_policy_id,
      operation_key,
      ..
    }: DexOrderBookDatum =
      reference_inputs |> get_dex_order_book_datum(oracle_nft)

    // Find the `DexAccountBalance` input and output, locate the merkle root
    expect [dex_account_balance_input] =
      inputs_at_with(
        inputs,
        dex_account_balance_address,
        dex_account_balance_token,
        "",
      )

    expect InlineDatum(tree_root) = dex_account_balance_input.output.datum
    expect DexAccountBalanceDatum {
      account_balance_merkle_root: input_merkle_root,
    }: DexAccountBalanceDatum = tree_root
    expect [dex_account_balance_output] =
      outputs_at_with(
        outputs,
        dex_account_balance_address,
        dex_account_balance_token,
        "",
      )

    expect InlineDatum(output_datum) = dex_account_balance_output.datum
    expect output_account_balance_datum: DexAccountBalanceDatum = output_datum

    // Obtain the `HydraAccountBalance` outputs with auth token and value
    let hydra_account_outputs =
      outputs_at(outputs, hydra_account_balance_address)
    // The way account balances are serialised into the tree is to have
    // the key as the serialised account, and the value is the serialised balance.
    let (output_merkle_record_list, to_mint_value): (
      List<Pair<ByteArray, ByteArray>>,
      Value,
    ) =
      hydra_account_outputs
        |> list.foldr(
            ([], assets.zero),
            fn(output: Output, acc) {
              expect InlineDatum(output_datum) = output.datum
              let balance =
                from_hydra_balance_to_value(
                  output.value,
                  hydra_tokens_policy_id,
                  token_map,
                )
              expect account: UserAccount = output_datum
              (
                acc.1st
                  |> list.push(
                      Pair(cbor.serialise(account), cbor.serialise(balance)),
                    ),
                acc.2nd
                  |> merge(
                      restricted_to(output.value, [hydra_tokens_policy_id]),
                    ),
              )
            },
          )

    let is_tree_updated =
      when redeemer_proof is {
        FullTree { tree } -> {
          let key_values = extract_key_values(tree)
          and {
            (compute_tree_hash(tree) == input_merkle_root)?,
            (key_values == output_merkle_record_list)?,
            (output_account_balance_datum.account_balance_merkle_root == null_hash)?,
          }
        }
        Proofs { proofs } -> {
          let old_root: mpf.MerklePatriciaForestry =
            mpf.from_root(input_merkle_root)
          let new_root: mpf.MerklePatriciaForestry =
            mpf.from_root(
              output_account_balance_datum.account_balance_merkle_root,
            )
          let computed_new_root: mpf.MerklePatriciaForestry =
            recursive_delete(old_root, output_merkle_record_list, proofs)

          mpf.root(new_root) == mpf.root(computed_new_root)
        }
      }

    let is_value_minted =
      restricted_to(tx.mint, [hydra_tokens_policy_id]) == to_mint_value

    let is_operation_key_signed =
      key_signed(tx.extra_signatories, operation_key)

    and {
      is_value_minted?,
      is_operation_key_signed?,
      is_tree_updated?,
    }
  }

  else(_) {
    fail
  }
}
