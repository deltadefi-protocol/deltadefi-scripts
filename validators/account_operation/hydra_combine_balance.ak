use aiken/collection/list
use cardano/address.{Credential}
use cardano/assets.{PolicyId, merge, restricted_to, without_lovelace, zero}
use cardano/certificate.{Certificate}
use cardano/transaction.{Transaction}
use cocktail.{
  input_inline_datum, inputs_at, key_signed, output_inline_datum, outputs_at,
}
use hydra_dex/types.{DexOrderBookDatum, UserAccount}
use hydra_dex/utils.{get_dex_order_book_datum}

validator hydra_combine_balance(oracle_nft: PolicyId) {
  withdraw(_redeemer: Data, _credential: Credential, tx: Transaction) {
    let Transaction { inputs, outputs, reference_inputs, extra_signatories, .. } =
      tx

    let DexOrderBookDatum {
      operation_key,
      hydra_account_balance_address,
      hydra_tokens_policy_id,
      ..
    }: DexOrderBookDatum =
      reference_inputs |> get_dex_order_book_datum(oracle_nft)

    let account_inputs = inputs_at(inputs, hydra_account_balance_address)
    expect [account_output] = outputs_at(outputs, hydra_account_balance_address)
    expect output_account: UserAccount = output_inline_datum(account_output)

    //  - Combine the account balance
    let (is_same_account, combined_balance) =
      list.foldl(
        account_inputs,
        (True, zero),
        fn(input, (is_same_account_acc, balance_acc)) {
          expect input_account: UserAccount = input_inline_datum(input)
          let is_same_account =
            input_account == output_account && is_same_account_acc
          let input_balance =
            input.output.value |> restricted_to([hydra_tokens_policy_id])
          let combined_balance_new = merge(balance_acc, input_balance)
          (is_same_account, combined_balance_new)
        },
      )

    let is_balance_updated =
      without_lovelace(account_output.value) == combined_balance

    //  - Signed by `operating_key`
    let is_hydra_internal_transfer_authorized =
      key_signed(extra_signatories, operation_key)

    and {
      is_same_account?,
      is_balance_updated?,
      is_hydra_internal_transfer_authorized?,
    }
  }

  publish(_redeemer: Data, _credential: Certificate, _tx: Transaction) {
    True
  }

  else(_) {
    fail @"unsupported purpose"
  }
}
// test test_hydra_internal_transfer_withdrawal_policy() {
//   let redeemer = ProcessHydraWithdrawal(MPFInsert([]))
//   hydra_internal_transfer.withdraw("", redeemer, Script(#""), placeholder)
// }
