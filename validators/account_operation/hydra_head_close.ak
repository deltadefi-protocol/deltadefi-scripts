use aiken/builtin.{blake2b_256}
use aiken/cbor
use aiken/collection/list
use aiken/merkle_patricia_forestry as mpf
use aiken/merkle_patricia_forestry/merkling.{null_hash}
use aiken/primitive/bytearray
use cardano/address.{Credential}
use cardano/assets.{PolicyId, Value, merge, negate, restricted_to, zero}
use cardano/certificate.{Certificate}
use cardano/transaction.{InlineDatum, Input, Output, Transaction}
use cocktail.{inputs_at, inputs_at_with, key_signed, outputs_at_with}
use hydra_dex/account_utils.{from_hydra_balance_to_value}
use hydra_dex/hydra_tree_utils.{
  compute_tree_hash, extract_key_values, recursive_insert,
}
use hydra_dex/types.{
  DexAccountBalanceDatum, DexOrderBookDatum, FullTree, Proofs,
  TreeOrProofsWithTokenMap, UserAccount,
}
use hydra_dex/utils.{get_dex_order_book_datum}

validator hydra_head_close(oracle_nft: PolicyId) {
  withdraw(
    redeemer: TreeOrProofsWithTokenMap,
    _credential: Credential,
    tx: Transaction,
  ) {
    let TreeOrProofsWithTokenMap { proof: redeemer_proof, token_map } = redeemer
    let Transaction {
      inputs,
      reference_inputs,
      outputs,
      mint,
      extra_signatories,
      ..
    } = tx
    let DexOrderBookDatum {
      dex_account_balance_token,
      dex_account_balance_address,
      hydra_account_balance_address,
      hydra_token_policy_id,
      operation_key,
      ..
    }: DexOrderBookDatum =
      reference_inputs |> get_dex_order_book_datum(oracle_nft)
    let account_balance_inputs: List<Input> =
      inputs_at(inputs, hydra_account_balance_address)

    let (input_merkle_record_list, to_burn_assets): (
      List<Pair<ByteArray, ByteArray>>,
      Value,
    ) =
      account_balance_inputs
        |> list.foldr(
            ([], zero),
            fn(input: Input, acc) {
              expect InlineDatum(input_datum) = input.output.datum
              let balance =
                from_hydra_balance_to_value(
                  input.output.value,
                  hydra_token_policy_id,
                  token_map,
                )
              expect account: UserAccount = input_datum
              (
                acc.1st
                  |> list.push(
                      Pair(cbor.serialise(account), cbor.serialise(balance)),
                    ),
                acc.2nd
                  |> merge(
                      negate(
                        restricted_to(
                          input.output.value,
                          [hydra_token_policy_id],
                        ),
                      ),
                    ),
              )
            },
          )

    expect [dex_account_balance_input] =
      inputs_at_with(
        inputs,
        dex_account_balance_address,
        dex_account_balance_token,
        "",
      )
    expect InlineDatum(input_datum) = dex_account_balance_input.output.datum
    expect input_dex_account_balance_datum: DexAccountBalanceDatum = input_datum

    expect [dex_account_balance_output] =
      outputs_at_with(
        outputs,
        dex_account_balance_address,
        dex_account_balance_token,
        "",
      )
    expect InlineDatum(output_datum) = dex_account_balance_output.datum
    expect output_dex_account_balance_datum: DexAccountBalanceDatum =
      output_datum

    let is_tree_updated =
      when redeemer_proof is {
        FullTree { tree } -> {
          let sorted_serialised_inputs: List<Pair<ByteArray, ByteArray>> =
            input_merkle_record_list
              |> list.sort(
                  fn(
                    a: Pair<ByteArray, ByteArray>,
                    b: Pair<ByteArray, ByteArray>,
                  ) {
                    bytearray.compare(blake2b_256(a.1st), blake2b_256(b.1st))
                  },
                )
          and {
            (input_dex_account_balance_datum.account_balance_merkle_root == null_hash)?,
            (compute_tree_hash(tree) == output_dex_account_balance_datum.account_balance_merkle_root)?,
            (extract_key_values(tree) == sorted_serialised_inputs)?,
          }
        }
        Proofs { proofs } -> {
          let old_root: mpf.MerklePatriciaForestry =
            mpf.from_root(
              input_dex_account_balance_datum.account_balance_merkle_root,
            )
          let new_root: mpf.MerklePatriciaForestry =
            mpf.from_root(
              output_dex_account_balance_datum.account_balance_merkle_root,
            )
          let computed_new_root: mpf.MerklePatriciaForestry =
            recursive_insert(old_root, input_merkle_record_list, proofs)

          mpf.root(new_root) == mpf.root(computed_new_root)
        }
      }

    let is_value_burnt = mint == to_burn_assets

    let is_operation_key_signed = key_signed(extra_signatories, operation_key)

    and {
      is_value_burnt?,
      is_operation_key_signed?,
      is_tree_updated?,
    }
  }

  publish(_redeemer: Data, _credential: Certificate, _tx: Transaction) {
    True
  }

  else(_) {
    fail @"unsupported purpose"
  }
}
