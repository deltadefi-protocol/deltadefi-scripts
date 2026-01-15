use cardano/assets.{PolicyId}
use cardano/script_context.{ScriptContext}
use cardano/transaction.{Transaction}
use cocktail.{inputs_with_policy, withdrawal_redeemer}
use hydra_dex/types.{
  BurnAtCombineOrderBook, BurnAtHydraClose, BurnAtWithdrawal, CombineOrderMerkle,
  DexOrderBookDatum, HydraAccountOperation, HydraOrderBookRedeemer,
  HydraTokensRedeemer, MintAtCancelWithdrawal, MintAtHydraOpen,
  MintAtInitOrderBook, ProcessCancelWithdrawal, ProcessCombineUtxosAtClose,
  ProcessSplitUtxosAtOpen, ProcessWithdrawal, SplitOrderMerkle,
}
use hydra_dex/utils.{get_dex_order_book_datum}

validator hydra_tokens(oracle_nft: PolicyId) {
  mint(redeemer: HydraTokensRedeemer, _policy_id: PolicyId, tx: Transaction) {
    let Transaction { redeemers, reference_inputs, inputs, .. } = tx
    let DexOrderBookDatum {
      hydra_account_script_hash,
      hydra_order_book_script_hash,
      ..
    }: DexOrderBookDatum =
      if inputs_with_policy(inputs, oracle_nft) == [] {
        reference_inputs |> get_dex_order_book_datum(oracle_nft)
      } else {
        inputs |> get_dex_order_book_datum(oracle_nft)
      }

    when redeemer is {
      MintAtHydraOpen -> {
        expect Some(w_redeemer) =
          withdrawal_redeemer(redeemers, hydra_account_script_hash)
        expect w_redeemer: HydraAccountOperation = w_redeemer
        when w_redeemer is {
          ProcessSplitUtxosAtOpen { .. } -> True
          _ -> False
        }
      }
      BurnAtHydraClose -> {
        expect Some(w_redeemer) =
          withdrawal_redeemer(redeemers, hydra_account_script_hash)
        expect w_redeemer: HydraAccountOperation = w_redeemer
        when w_redeemer is {
          ProcessCombineUtxosAtClose { .. } -> True
          _ -> False
        }
      }
      MintAtCancelWithdrawal -> {
        expect Some(w_redeemer) =
          withdrawal_redeemer(redeemers, hydra_account_script_hash)
        expect w_redeemer: HydraAccountOperation = w_redeemer
        when w_redeemer is {
          ProcessCancelWithdrawal { .. } -> True
          _ -> False
        }
      }
      BurnAtWithdrawal -> {
        expect Some(w_redeemer) =
          withdrawal_redeemer(redeemers, hydra_account_script_hash)
        expect w_redeemer: HydraAccountOperation = w_redeemer
        when w_redeemer is {
          ProcessWithdrawal { .. } -> True
          _ -> False
        }
      }
      MintAtInitOrderBook -> {
        expect Some(w_redeemer) =
          withdrawal_redeemer(redeemers, hydra_order_book_script_hash)
        expect w_redeemer: HydraOrderBookRedeemer = w_redeemer
        when w_redeemer is {
          SplitOrderMerkle { .. } -> True
          _ -> False
        }
      }
      BurnAtCombineOrderBook -> {
        expect Some(w_redeemer) =
          withdrawal_redeemer(redeemers, hydra_order_book_script_hash)
        expect w_redeemer: HydraOrderBookRedeemer = w_redeemer
        when w_redeemer is {
          CombineOrderMerkle { .. } -> True
          _ -> False
        }
      }
    }
  }

  else(_ctx: ScriptContext) {
    fail
  }
}
