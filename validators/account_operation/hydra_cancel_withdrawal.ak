use cardano/address.{Credential}
use cardano/assets.{PolicyId, from_asset_list, merge, negate, without_lovelace}
use cardano/certificate.{Certificate}
use cardano/transaction.{Transaction}
use cocktail.{
  input_inline_datum, inputs_at, inputs_at_with_policy, key_signed, outputs_at,
  outputs_at_with_policy,
}
use hydra_dex/account_utils.{
  dex_account_balance_balance_decrease, from_value_to_hydra_balance,
  hydra_balance_increase,
}
use hydra_dex/types.{
  CancelWithdrawalIntent, DexOrderBookDatum, HydraUserIntentDatum,
  ProcessHydraCancelWithdrawal,
}
use hydra_dex/utils.{get_dex_order_book_datum}

validator hydra_cancel_withdrawal(oracle_nft: PolicyId) {
  withdraw(
    redeemer: ProcessHydraCancelWithdrawal,
    _credential: Credential,
    tx: Transaction,
  ) {
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
      dex_account_balance_token,
      dex_account_balance_address,
      hydra_user_intent_token,
      hydra_user_intent_address,
      hydra_account_balance_address,
      hydra_token_policy_id,
      ..
    }: DexOrderBookDatum =
      reference_inputs |> get_dex_order_book_datum(oracle_nft)

    //  - Input datum with current policy is `WithdrawalIntent`
    expect [intent_input] =
      inputs_at_with_policy(
        inputs,
        hydra_user_intent_address,
        hydra_user_intent_token,
      )
    expect CancelWithdrawalIntent { account, amount: withdrawal_amount }: HydraUserIntentDatum =
      input_inline_datum(intent_input)

    //  - The input token is burnt
    let cancel_withdrawal_hydra_value =
      from_asset_list(withdrawal_amount)
        |> from_value_to_hydra_balance(hydra_token_policy_id)
    let to_mint_or_burn_value =
      without_lovelace(intent_input.output.value)
        |> negate()
        |> merge(cancel_withdrawal_hydra_value)

    //  - Exactly 1 input from `DexAccountBalance` with auth token
    //  - Exactly 1 output to `DexAccountBalance` with auth token minted with account balance merkle root updated
    let is_dex_account_balance_updated =
      when
        (
          inputs_at_with_policy(
            inputs,
            dex_account_balance_address,
            dex_account_balance_token,
          ),
          outputs_at_with_policy(
            outputs,
            dex_account_balance_address,
            dex_account_balance_token,
          ),
        )
      is {
        ([dex_account_balance_input], [dex_account_balance_output]) ->
          dex_account_balance_balance_decrease(
            dex_account_balance_input,
            dex_account_balance_output,
            account,
            from_asset_list(withdrawal_amount),
            redeemer.mpf_action,
          )

        _ -> False
      }
    //  - Deduct the account balance from `HydraAccountBalance` with corresponding auth token
    let is_account_balance_updated =
      when
        (
          inputs_at(inputs, hydra_account_balance_address),
          outputs_at(outputs, hydra_account_balance_address),
        )
      is {
        ([balance_input], [balance_output]) ->
          hydra_balance_increase(
            balance_input,
            balance_output,
            cancel_withdrawal_hydra_value,
          )
        _ -> False
      }
    let is_hydra_cancel_withdrawal_authorized =
      key_signed(extra_signatories, operation_key)
    let is_mint_value_correct = assets.match(mint, to_mint_or_burn_value, ==)
    and {
      is_dex_account_balance_updated?,
      is_account_balance_updated?,
      is_hydra_cancel_withdrawal_authorized?,
      is_mint_value_correct?,
    }
  }

  publish(_redeemer: Data, _credential: Certificate, _tx: Transaction) {
    True
  }

  else(_) {
    fail @"unsupported purpose"
  }
}
