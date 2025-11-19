use aiken/option.{is_none}
use cardano/assets.{PolicyId, without_lovelace, zero}
use cardano/transaction.{OutputReference, Transaction, find_input}
use cocktail.{key_signed, withdrawal_redeemer, withdrawal_script_validated}
use hydra_dex/types.{
  CancelOrder, DexOrderBookDatum, FillOrder, HydraAccountBalanceRedeemer,
  HydraAccountBalanceSpamPreventionWithdraw, HydraCombineUtxosAtClose,
  HydraCombineUtxosAtOpen, HydraOrderBookRedeemer, PlaceOrder,
  UpdateBalanceWithCancelOrder, UpdateBalanceWithCancelWithdrawal,
  UpdateBalanceWithFillOrder, UpdateBalanceWithPlaceOrder,
  UpdateBalanceWithTransfer, UpdateBalanceWithWithdrawal, UserAccount,
}
use hydra_dex/utils.{get_dex_order_book_datum}

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
      redeemers,
      inputs,
      extra_signatories,
      ..
    } = self

    let DexOrderBookDatum {
      operation_key,
      hydra_order_book_script_hash,
      withdrawal_script_hashes,
      ..
    }: DexOrderBookDatum =
      reference_inputs
        |> get_dex_order_book_datum(dex_oracle_nft)
    when redeemer is {
      UpdateBalanceWithPlaceOrder -> {
        expect Some(w_redeemer) =
          withdrawal_redeemer(redeemers, hydra_order_book_script_hash)
        expect w_redeemer: HydraOrderBookRedeemer = w_redeemer
        when w_redeemer is {
          PlaceOrder { .. } -> True
          _ -> False
        }
      }
      UpdateBalanceWithFillOrder -> {
        expect Some(w_redeemer) =
          withdrawal_redeemer(redeemers, hydra_order_book_script_hash)
        expect w_redeemer: HydraOrderBookRedeemer = w_redeemer
        when w_redeemer is {
          FillOrder { .. } -> True
          _ -> False
        }
      }
      UpdateBalanceWithCancelOrder -> {
        expect Some(w_redeemer) =
          withdrawal_redeemer(redeemers, hydra_order_book_script_hash)
        expect w_redeemer: HydraOrderBookRedeemer = w_redeemer
        when w_redeemer is {
          CancelOrder { .. } -> True
          _ -> False
        }
      }
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
