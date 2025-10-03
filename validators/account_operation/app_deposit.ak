use cardano/address.{Credential}
use cardano/assets.{PolicyId, from_asset_list, merge}
use cardano/certificate.{Certificate}
use cardano/transaction.{Transaction}
use cocktail.{
  get_all_value_from, get_all_value_to, input_inline_datum, inputs_at_with,
  inputs_at_with_policy, key_signed, only_minted_token, outputs_at_with_policy,
}
use hydra_dex/account_utils.{dex_account_balance_balance_increase}
use hydra_dex/types.{AppDepositRequestDatum, AppOracleDatum, ProcessAppDeposit}
use hydra_dex/utils.{get_app_oracle_datum}

validator app_deposit(oracle_nft: PolicyId) {
  withdraw(
    redeemer: ProcessAppDeposit,
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

    let AppOracleDatum {
      operation_key,
      app_vault_address,
      app_deposit_request_token,
      app_deposit_request_address,
      dex_account_balance_token,
      dex_account_balance_address,
      ..
    }: AppOracleDatum = reference_inputs |> get_app_oracle_datum(oracle_nft)

    //  - Obtain the only `AppDepositRequest` input and its account value
    expect [intent_input] =
      inputs_at_with(
        inputs,
        app_deposit_request_address,
        app_deposit_request_token,
        "",
      )

    expect AppDepositRequestDatum { account, amount: deposit_amount }: AppDepositRequestDatum =
      input_inline_datum(intent_input)

    //  - Check if the token with `AppDepositRequest` is burnt, and the deposit value is sent to vault
    let is_intent_token_burnt =
      only_minted_token(mint, app_deposit_request_token, "", -1)
    let value_from_vault = get_all_value_from(inputs, app_vault_address)
    let value_to_vault = get_all_value_to(outputs, app_vault_address)
    let is_value_sent_to_vault =
      value_from_vault
        |> merge(from_asset_list(deposit_amount))
        |> assets.match(value_to_vault, ==)

    //  - Obtain the only `DexAccountBalance` input and its merkle tree account value
    //  - Obtain the only `DexAccountBalance` output and its merkle tree account value
    //  - Check if the deposit is processed correctly with the merkle tree
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
          dex_account_balance_balance_increase(
            dex_account_balance_input,
            dex_account_balance_output,
            account,
            from_asset_list(deposit_amount),
            redeemer.mpf_action,
          )

        _ -> False
      }

    //  - Operation key is signed
    let is_app_deposit_authorized = key_signed(extra_signatories, operation_key)
    and {
      is_intent_token_burnt?,
      is_value_sent_to_vault?,
      is_dex_account_balance_updated?,
      is_app_deposit_authorized?,
    }
  }

  publish(_redeemer: Data, _credential: Certificate, tx: Transaction) {
    let Transaction { reference_inputs, extra_signatories, .. } = tx
    let AppOracleDatum { operation_key, .. }: AppOracleDatum =
      reference_inputs |> get_app_oracle_datum(oracle_nft)

    key_signed(extra_signatories, operation_key)?
  }

  else(_) {
    fail @"unsupported purpose"
  }
}
