use aiken/collection/dict
use aiken/interval.{is_entirely_after}
use cardano/address.{Credential}
use cardano/assets.{PolicyId, from_asset_list, merge}
use cardano/certificate.{Certificate}
use cardano/transaction.{Transaction}
use cocktail.{
  get_all_value_from_script, get_all_value_to_script, inputs_at_with_policy,
  key_signed, outputs_at_with_policy,
}
use cocktail/vodka_inputs.{input_inline_datum}
use hydra_dex/account_utils.{
  dex_order_book_cancel_order, get_master_key, master_auth_by_account,
}
use hydra_dex/types.{
  AppOracleDatum, EmergencyCancelRedeemer, EmergencyCancelRequestDatum,
}
use hydra_dex/utils.{get_all_value_to_cred, get_app_oracle_datum}

validator emergency_order_cancel(oracle_nft: PolicyId) {
  withdraw(
    redeemer: EmergencyCancelRedeemer,
    _credential: Credential,
    tx: Transaction,
  ) {
    let Transaction {
      inputs,
      outputs,
      reference_inputs,
      extra_signatories,
      validity_range,
      withdrawals,
      mint,
      ..
    } = tx

    let AppOracleDatum {
      operation_key,
      app_vault_script_hash,
      dex_order_book_token,
      dex_order_book_address,
      emergency_cancel_order_request_token,
      emergency_cancel_order_request_address,
      ..
    }: AppOracleDatum = reference_inputs |> get_app_oracle_datum(oracle_nft)

    //  - Obtain the input and output value to `AppVault`, check the value deducted equal to withdrawal amount
    //  - Check the withdrawal amounut is correct sent to an address equal
    let value_from_vault =
      get_all_value_from_script(inputs, app_vault_script_hash)
    let value_to_vault = get_all_value_to_script(outputs, app_vault_script_hash)
    let value_in_order = from_asset_list(redeemer.order.value)
    let is_value_unlocked_from_vault_correct =
      value_to_vault
        |> merge(value_in_order)
        |> assets.match(value_from_vault, ==)
    let user_master_key = get_master_key(redeemer.account)
    let is_withdrawal_amount_sent_to_user =
      get_all_value_to_cred(outputs, user_master_key)
        |> assets.match(value_in_order, ==)

    //  - Obtain the only `DexOrderBook` input and its merkle tree account value
    //  - Obtain the only `DexOrderBook` output and its merkle tree account value
    //  - Check if the withdrawal is processed correctly with the merkle tree
    let is_dex_order_book_updated =
      when
        (
          inputs_at_with_policy(
            inputs,
            dex_order_book_address,
            dex_order_book_token,
          ),
          outputs_at_with_policy(
            outputs,
            dex_order_book_address,
            dex_order_book_token,
          ),
        )
      is {
        ([dex_order_book_input], [dex_order_book_output]) ->
          dex_order_book_cancel_order(
            dex_order_book_input,
            dex_order_book_output,
            redeemer.order,
            redeemer.mpf_action,
          )

        _ -> False
      }

    //  - Operation key is signed
    let is_order_cancel_authorized =
      if key_signed(extra_signatories, operation_key) {
        True
      } else {
        //  - Obtain the only `DexOrderBookCancel` input and its account value
        expect [intent_input] =
          inputs_at_with_policy(
            inputs,
            emergency_cancel_order_request_address,
            emergency_cancel_order_request_token,
          )

        //  - Input datum with current policy is `WithdrawalIntent`
        expect EmergencyCancelRequestDatum {
          account: cancel_account,
          order_id: cancel_order_id,
          timestamp: cancel_timestamp,
        }: EmergencyCancelRequestDatum = input_inline_datum(intent_input)

        expect [Pair(_asset_name, quantity)] =
          mint
            |> assets.tokens(emergency_cancel_order_request_token)
            |> dict.to_pairs()

        let is_emergency_token_burnt = quantity == -1

        // Check that the redeemer matches the withdrawal request        
        let is_redeemer_matches_withdrawal_request =
          redeemer.account == cancel_account && redeemer.order.datum.order_id == cancel_order_id
        and {
          is_emergency_token_burnt,
          is_redeemer_matches_withdrawal_request,
          master_auth_by_account(
            redeemer.account,
            withdrawals,
            extra_signatories,
          ),
          is_entirely_after(validity_range, cancel_timestamp + 86400),
        }
      }
    and {
      is_value_unlocked_from_vault_correct?,
      is_withdrawal_amount_sent_to_user?,
      is_dex_order_book_updated?,
      is_order_cancel_authorized?,
    }
  }

  publish(_redeemer: Data, _credential: Certificate, _tx: Transaction) {
    True
  }

  else(_) {
    fail @"unsupported purpose"
  }
}
