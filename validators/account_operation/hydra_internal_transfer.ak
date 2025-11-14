use cardano/address.{Credential}
use cardano/assets.{PolicyId, from_asset_list, negate, without_lovelace}
use cardano/certificate.{Certificate}
use cardano/transaction.{Transaction}
use cocktail.{
  input_inline_datum, inputs_at, inputs_at_with_policy, key_signed, outputs_at,
}
use hydra_dex/account_utils.{
  get_account_input, get_account_output, hydra_balance_decrease,
  hydra_balance_increase,
}
use hydra_dex/types.{DexOrderBookDatum, HydraUserIntentDatum, TransferIntent}
use hydra_dex/utils.{get_dex_order_book_datum}

validator hydra_internal_transfer(oracle_nft: PolicyId) {
  withdraw(_redeemer: Data, _credential: Credential, tx: Transaction) {
    let Transaction {
      inputs,
      outputs,
      reference_inputs,
      extra_signatories,
      mint,
      ..
    } = tx

    let DexOrderBookDatum {
      operation_key,
      hydra_user_intent_token,
      hydra_user_intent_address,
      hydra_account_balance_address,
      ..
    }: DexOrderBookDatum =
      reference_inputs |> get_dex_order_book_datum(oracle_nft)

    //  - Input from `HydraUserIntent` with `TransferIntent` datum
    expect [intent_input] =
      inputs_at_with_policy(
        inputs,
        hydra_user_intent_address,
        hydra_user_intent_token,
      )
    expect TransferIntent { from, to, amount: transferal_amount }: HydraUserIntentDatum =
      input_inline_datum(intent_input)

    //  - The intent token is burnt
    let is_intent_token_burnt =
      assets.match(
        mint,
        negate(without_lovelace(intent_input.output.value)),
        ==,
      )

    let account_inputs = inputs_at(inputs, hydra_account_balance_address)
    let account_outputs = outputs_at(outputs, hydra_account_balance_address)

    //  - Deduct the account balance from `HydraAccountBalance` with for the `from` account.
    let is_from_account_balance_deducted =
      when
        (
          get_account_input(account_inputs, from),
          get_account_output(account_outputs, from),
        )
      is {
        (Some(input), Some(output)) ->
          hydra_balance_decrease(
            input,
            output,
            from_asset_list(transferal_amount),
          )
        _ -> False
      }

    //  - Add the account balance from `HydraAccountBalance` with for the `to` account.
    let is_to_account_balance_added =
      when
        (
          get_account_input(account_inputs, to),
          get_account_output(account_outputs, to),
        )
      is {
        (Some(input), Some(output)) ->
          hydra_balance_increase(
            input,
            output,
            from_asset_list(transferal_amount),
          )
        _ -> False
      }

    //  - Signed by `operating_key`
    let is_hydra_internal_transfer_authorized =
      key_signed(extra_signatories, operation_key)
    and {
      is_from_account_balance_deducted?,
      is_to_account_balance_added?,
      is_hydra_internal_transfer_authorized?,
      is_intent_token_burnt?,
    }
  }

  publish(_redeemer: Data, _credential: Certificate, _tx: Transaction) {
    True
  }

  else(_) {
    fail @"unsupported purpose"
  }
}
