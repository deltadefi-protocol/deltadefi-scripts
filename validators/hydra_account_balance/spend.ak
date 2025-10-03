use aiken/collection/dict
use cardano/assets.{PolicyId, from_asset_list, zero}
use cardano/transaction.{OutputReference, Transaction}
use cocktail.{key_signed}
use cocktail/vodka_inputs.{input_inline_datum, inputs_at_with_policy}
use hydra_dex/types.{
  DexOrderBookDatum, HydraAccountBalanceDatum, HydraAccountBalanceRedeemer,
  HydraAccountBalanceRemoveEmptyBalance, HydraCombineUtxosAtClose,
  HydraCombineUtxosAtOpen, UpdataBalanceWithCancelOrder,
  UpdataBalanceWithFillOrder, UpdataBalanceWithReleaseExtraValue,
  UpdateBalanceWithCancelWithdrawal, UpdateBalanceWithPlaceOrder,
  UpdateBalanceWithTransfer, UpdateBalanceWithWithdrawal,
}
use hydra_dex/utils.{get_dex_order_book_datum, withdrawal_script_validated}

validator hydra_account_balance(dex_oracle_nft: PolicyId) {
  spend(
    _datum_opt: Option<HydraAccountBalanceDatum>,
    redeemer: HydraAccountBalanceRedeemer,
    _utxo: OutputReference,
    self: Transaction,
  ) {
    let Transaction {
      mint,
      reference_inputs,
      withdrawals,
      inputs,
      extra_signatories,
      ..
    } = self

    let DexOrderBookDatum {
      operation_key,
      hydra_account_balance_address,
      hydra_account_balance_token,
      withdrawal_script_hashes,
      ..
    }: DexOrderBookDatum =
      reference_inputs
        |> get_dex_order_book_datum(dex_oracle_nft)
    when redeemer is {
      UpdateBalanceWithPlaceOrder ->
        withdrawal_script_validated(
          withdrawals,
          withdrawal_script_hashes.hydra_place_order,
        )
      UpdataBalanceWithFillOrder ->
        withdrawal_script_validated(
          withdrawals,
          withdrawal_script_hashes.hydra_fill_order,
        )
      UpdataBalanceWithCancelOrder ->
        withdrawal_script_validated(
          withdrawals,
          withdrawal_script_hashes.hydra_cancel_order,
        )
      UpdataBalanceWithReleaseExtraValue ->
        withdrawal_script_validated(
          withdrawals,
          withdrawal_script_hashes.hydra_release_extra_value,
        )
      UpdateBalanceWithWithdrawal ->
        withdrawal_script_validated(
          withdrawals,
          withdrawal_script_hashes.hydra_withdrawal,
        )
      UpdateBalanceWithCancelWithdrawal ->
        withdrawal_script_validated(
          withdrawals,
          withdrawal_script_hashes.hydra_cancel_withdrawal,
        )
      UpdateBalanceWithTransfer ->
        withdrawal_script_validated(
          withdrawals,
          withdrawal_script_hashes.hydra_internal_transfer,
        )
      HydraCombineUtxosAtClose ->
        withdrawal_script_validated(
          withdrawals,
          withdrawal_script_hashes.hydra_head_close,
        )
      // HydraAccountBalanceSpamPreventionWithdraw -> {
      //   expect Some(own_input) = find_input(inputs, utxo)
      //   let no_auth_token_check =
      //     tokens(own_input.output.value, hydra_account_balance_token)
      //       |> is_empty()
      //   let is_operation_key_signed =
      //     key_signed(extra_signatories, operation_key)
      //   no_auth_token_check? && is_operation_key_signed?
      // }
      HydraAccountBalanceRemoveEmptyBalance -> {
        expect [account_balance_input] =
          inputs_at_with_policy(
            inputs,
            hydra_account_balance_address,
            hydra_account_balance_token,
          )
        expect HydraAccountBalanceDatum { balance, .. }: HydraAccountBalanceDatum =
          input_inline_datum(account_balance_input)
        let is_empty_balance = from_asset_list(balance) == zero

        expect [Pair(_asset_name, quantity)] =
          mint |> assets.tokens(hydra_account_balance_token) |> dict.to_pairs()
        let is_auth_token_burnt = quantity == -1

        let is_operation_key_signed =
          key_signed(extra_signatories, operation_key)
        is_empty_balance? && is_auth_token_burnt? && is_operation_key_signed?
      }
      HydraCombineUtxosAtOpen ->
        withdrawal_script_validated(
          withdrawals,
          withdrawal_script_hashes.hydra_combine_balance,
        )
    }
  }

  else(_) {
    fail
  }
}
