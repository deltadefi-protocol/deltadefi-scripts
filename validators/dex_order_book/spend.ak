use aiken/collection/dict.{is_empty}
use cardano/assets.{PolicyId, tokens}
use cardano/transaction.{Input, OutputReference, Transaction, find_input}
use cocktail.{key_signed, withdrawal_redeemer, withdrawal_script_validated}
use hydra_dex/hydra_commit_utils.{validate_hydra_commit}
use hydra_dex/types.{
  AppOracleDatum, CombineOrderMerkle, DexOrderBookCombineMerkleTree,
  DexOrderBookDatum, DexOrderBookEmergencyCancelOrder, DexOrderBookHydraCommit,
  DexOrderBookRedeemer, DexOrderBookSpamPreventionWithdraw,
  DexOrderBookSplitMerkleTree, HydraOrderBookRedeemer, SplitOrderMerkle,
}
use hydra_dex/utils.{get_app_oracle_datum}

validator dex_order_book(oracle_nft: PolicyId, dex_order_book_token: PolicyId) {
  spend(
    datum_opt: Option<DexOrderBookDatum>,
    redeemer: DexOrderBookRedeemer,
    utxo: OutputReference,
    self: Transaction,
  ) {
    let Transaction {
      inputs,
      reference_inputs,
      withdrawals,
      extra_signatories,
      redeemers,
      ..
    } = self

    when redeemer is {
      DexOrderBookSplitMerkleTree -> {
        expect Some(datum) = datum_opt
        expect Some(w_redeemer) =
          withdrawal_redeemer(redeemers, datum.hydra_order_book_script_hash)
        expect w_redeemer: HydraOrderBookRedeemer = w_redeemer
        when w_redeemer is {
          SplitOrderMerkle { .. } -> True
          _ -> False
        }
      }
      DexOrderBookCombineMerkleTree -> {
        expect Some(datum) = datum_opt
        expect Some(w_redeemer) =
          withdrawal_redeemer(redeemers, datum.hydra_order_book_script_hash)
        expect w_redeemer: HydraOrderBookRedeemer = w_redeemer
        when w_redeemer is {
          CombineOrderMerkle { .. } -> True
          _ -> False
        }
      }
      DexOrderBookHydraCommit ->
        validate_hydra_commit(
          reference_inputs,
          oracle_nft,
          inputs,
          redeemers,
          extra_signatories,
          utxo,
        )
      DexOrderBookEmergencyCancelOrder -> {
        let oracle_input_datum: AppOracleDatum =
          reference_inputs |> get_app_oracle_datum(oracle_nft)
        withdrawal_script_validated(
          withdrawals,
          oracle_input_datum.all_withdrawal_script_hashes.emergency_cancel_order,
        )
      }
      DexOrderBookSpamPreventionWithdraw -> {
        let oracle_input_datum: AppOracleDatum =
          reference_inputs |> get_app_oracle_datum(oracle_nft)
        expect Some(own_input) = find_input(inputs, utxo)
        let no_auth_token_check =
          tokens(own_input.output.value, dex_order_book_token)
            |> is_empty()
        let is_operation_key_signed =
          key_signed(extra_signatories, oracle_input_datum.operation_key)

        no_auth_token_check? && is_operation_key_signed?
      }
    }
  }

  else(_) {
    fail
  }
}
