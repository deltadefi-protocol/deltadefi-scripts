use aiken/option.{is_none}
use cardano/address.{Credential}
use cardano/assets.{PolicyId, without_lovelace, zero}
use cardano/transaction.{OutputReference, Redeemer, Transaction, find_input}
use cocktail.{address_script_hash, key_signed, withdrawal_redeemer}
use hydra_account/cancel_withdrawal.{cancel_withdrawal}
use hydra_account/combine_utxos_at_close.{combine_utxos_at_close}
use hydra_account/same_account_transferal.{same_account_transferal}
use hydra_account/split_utxos_at_open.{split_utxos_at_open}
use hydra_account/transferal.{transferal}
use hydra_account/withdrawal.{withdrawal}
use hydra_dex/types.{
  CancelOrder, DexOrderBookDatum, FillOrder, HydraAccountRedeemer,
  HydraAccountSpamPreventionWithdraw, HydraOrderBookRedeemer, PlaceOrder,
  ProcessCancelWithdrawal, ProcessCombineUtxosAtClose,
  ProcessSameAccountTransferal, ProcessSplitUtxosAtOpen, ProcessTransferal,
  ProcessWithdrawal, TreeOrProofsWithTokenMap, UpdateBalanceWithCancelOrder,
  UpdateBalanceWithFillOrder, UpdateBalanceWithPlaceOrder, UserAccount,
}
use hydra_dex/utils.{get_dex_order_book_datum}

validator hydra_account(dex_oracle_nft: PolicyId) {
  spend(
    datum_opt: Option<UserAccount>,
    redeemer: HydraAccountRedeemer,
    input: OutputReference,
    tx: Transaction,
  ) {
    let Transaction {
      reference_inputs,
      redeemers,
      inputs,
      extra_signatories,
      ..
    } = tx

    let DexOrderBookDatum { operation_key, hydra_order_book_script_hash, .. }: DexOrderBookDatum =
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
      HydraAccountSpamPreventionWithdraw -> {
        expect Some(own_input) = inputs |> find_input(input)
        let is_no_value =
          own_input.output.value
            |> without_lovelace()
            |> assets.match(zero, ==)

        let is_no_datum = is_none(datum_opt)
        let is_operation_key_signed =
          key_signed(extra_signatories, operation_key)

        and {
          or {
            is_no_value?,
            is_no_datum?,
          },
          is_operation_key_signed?,
        }
      }
      _ -> {
        expect Some(own_input) = find_input(inputs, input)
        expect Some(script_hash) = address_script_hash(own_input.output.address)
        expect Some(w_redeemer) = withdrawal_redeemer(redeemers, script_hash)
        let raw_redeemer: Redeemer = redeemer
        raw_redeemer == w_redeemer
      }
    }
  }

  withdraw(
    redeemer: HydraAccountRedeemer,
    _credential: Credential,
    tx: Transaction,
  ) {
    when redeemer is {
      ProcessWithdrawal { mpf_action } ->
        withdrawal(dex_oracle_nft, mpf_action, tx)
      ProcessCancelWithdrawal { mpf_action } ->
        cancel_withdrawal(dex_oracle_nft, mpf_action, tx)
      ProcessSameAccountTransferal { account } ->
        same_account_transferal(dex_oracle_nft, account, tx)
      ProcessTransferal -> transferal(dex_oracle_nft, tx)
      ProcessSplitUtxosAtOpen { tree_or_proofs_with_token_map } -> {
        let TreeOrProofsWithTokenMap { proof, token_map } =
          tree_or_proofs_with_token_map
        split_utxos_at_open(dex_oracle_nft, proof, token_map, tx)
      }
      ProcessCombineUtxosAtClose { tree_or_proofs_with_token_map } -> {
        let TreeOrProofsWithTokenMap { proof, token_map } =
          tree_or_proofs_with_token_map
        combine_utxos_at_close(dex_oracle_nft, proof, token_map, tx)
      }
      _ -> False
    }
  }

  else(_) {
    fail
  }
}
