use aiken/option.{is_none}
use cardano/assets.{PolicyId, without_lovelace, zero}
use cardano/transaction.{OutputReference, Transaction, find_input}
use cocktail.{key_signed}
use hydra_dex/types.{
  DexOrderBookDatum, HydraAccountBalanceRedeemer,
  HydraAccountBalanceSpamPreventionWithdraw, HydraCombineUtxosAtClose,
  HydraCombineUtxosAtOpen, UpdateBalanceWithCancelOrder,
  UpdateBalanceWithCancelWithdrawal, UpdateBalanceWithFillOrder,
  UpdateBalanceWithPlaceOrder, UpdateBalanceWithReleaseExtraValue,
  UpdateBalanceWithTransfer, UpdateBalanceWithWithdrawal, UserAccount,
}
use hydra_dex/utils.{get_dex_order_book_datum, withdrawal_script_validated}

validator hydra_account_balance(dex_oracle_nft: PolicyId) {
  spend(
    datum_opt: Option<UserAccount>,
    redeemer: HydraAccountBalanceRedeemer,
    utxo: OutputReference,
    self: Transaction,
  ) {
    let Transaction {
      reference_inputs,
      withdrawals,
      inputs,
      extra_signatories,
      ..
    } = self

    let DexOrderBookDatum { operation_key, withdrawal_script_hashes, .. }: DexOrderBookDatum =
      reference_inputs
        |> get_dex_order_book_datum(dex_oracle_nft)
    when redeemer is {
      UpdateBalanceWithPlaceOrder ->
        withdrawal_script_validated(
          withdrawals,
          withdrawal_script_hashes.hydra_place_order,
        )
      UpdateBalanceWithFillOrder ->
        withdrawal_script_validated(
          withdrawals,
          withdrawal_script_hashes.hydra_fill_order,
        )
      UpdateBalanceWithCancelOrder ->
        withdrawal_script_validated(
          withdrawals,
          withdrawal_script_hashes.hydra_cancel_order,
        )
      UpdateBalanceWithReleaseExtraValue ->
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
      HydraAccountBalanceSpamPreventionWithdraw -> {
        expect Some(own_input) = inputs |> find_input(utxo)
        let is_no_value =
          own_input.output.value
            |> without_lovelace()
            |> assets.match(zero, ==)

        let is_no_datum = is_none(datum_opt)
        let is_operation_key_signed =
          key_signed(extra_signatories, operation_key)

        trace @"gm"
        trace True == or {
          is_no_value?,
          is_no_datum?,
        }
        trace True

        and {
          or {
            is_no_value?,
            is_no_datum?,
          },
          is_operation_key_signed?,
        }
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
