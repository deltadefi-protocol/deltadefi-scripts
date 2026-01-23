use aiken/option.{is_none}
use cardano/address.{Credential}
use cardano/assets.{PolicyId, without_lovelace, zero}
use cardano/transaction.{OutputReference, Transaction, find_input}
use cocktail.{key_signed, withdrawal_script_validated}
use hydra_account/cancel_withdrawal.{cancel_withdrawal}
use hydra_account/combine_utxos_at_close.{combine_utxos_at_close}
use hydra_account/same_account_transferal.{same_account_transferal}
use hydra_account/split_utxos_at_open.{split_utxos_at_open}
use hydra_account/transferal.{transferal}
use hydra_account/withdrawal.{withdrawal}
use hydra_dex/types.{
  DexOrderBookDatum, HydraAccountOperate, HydraAccountOperation,
  HydraAccountRedeemer, HydraAccountSpamPreventionWithdraw, HydraAccountTrade,
  ProcessCancelWithdrawal, ProcessCombineUtxosAtClose,
  ProcessSameAccountTransferal, ProcessSplitUtxosAtOpen, ProcessTransferal,
  ProcessWithdrawal, TreeOrProofsWithTokenMap, UserAccount,
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
      inputs,
      extra_signatories,
      withdrawals,
      ..
    } = tx

    let DexOrderBookDatum { operation_key, hydra_account_script_hash, .. }: DexOrderBookDatum =
      reference_inputs
        |> get_dex_order_book_datum(dex_oracle_nft)
    when redeemer is {
      HydraAccountTrade { .. } ->
        withdrawal_script_validated(withdrawals, hydra_account_script_hash)?
      HydraAccountOperate ->
        withdrawal_script_validated(withdrawals, hydra_account_script_hash)?

      HydraAccountSpamPreventionWithdraw -> {
        // TODO: review
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
    }
  }

  withdraw(
    redeemer: HydraAccountOperation,
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
    }
  }

  else(_) {
    fail
  }
}
