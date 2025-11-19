use aiken/collection/dict.{is_empty}
use aiken/collection/list
use aiken/merkle_patricia_forestry as mpf
use cardano/assets.{PolicyId, tokens}
use cardano/transaction.{Output, OutputReference, Transaction, find_input}
use cocktail.{input_inline_datum, inputs_at_with_policy, key_signed}
use cocktail/vodka_withdrawals.{withdrawal_script_validated}
use hydra_dex/hydra_commit_utils.{validate_hydra_commit}
use hydra_dex/types.{
  AppDeposit, AppOracleDatum, AppWithdrawal, DexAccountBalanceCombineMerkleTree,
  DexAccountBalanceDatum, DexAccountBalanceHydraCommit,
  DexAccountBalanceRedeemer, DexAccountBalanceRemoveRegistry,
  DexAccountBalanceSpamPreventionWithdraw, DexAccountBalanceSplitMerkleTree,
  DexAccountBalanceTransferAccountBalance, DexOrderBookDatum,
  HydraCancelWithdrawal, HydraIncrementalDecommit, HydraWithdrawal,
}
use hydra_dex/utils.{get_app_oracle_datum, get_dex_order_book_datum}

validator dex_account_balance(
  oracle_nft: PolicyId,
  dex_order_book_token: PolicyId,
) {
  spend(
    _datum_opt: Option<DexAccountBalanceDatum>,
    redeemer: DexAccountBalanceRedeemer,
    utxo: OutputReference,
    self: Transaction,
  ) {
    let Transaction {
      inputs,
      outputs,
      reference_inputs,
      withdrawals,
      extra_signatories,
      mint,
      redeemers,
      ..
    } = self

    when redeemer is {
      AppDeposit -> {
        let oracle_input_datum: AppOracleDatum =
          reference_inputs |> get_app_oracle_datum(oracle_nft)
        withdrawal_script_validated(
          withdrawals,
          oracle_input_datum.all_withdrawal_script_hashes.app_deposit,
        )
      }
      AppWithdrawal -> {
        let oracle_input_datum: AppOracleDatum =
          reference_inputs |> get_app_oracle_datum(oracle_nft)
        withdrawal_script_validated(
          withdrawals,
          oracle_input_datum.all_withdrawal_script_hashes.app_withdrawal,
        )
      }
      HydraWithdrawal -> {
        let dex_order_book_input_datum: DexOrderBookDatum =
          reference_inputs
            |> get_dex_order_book_datum(dex_order_book_token)
        withdrawal_script_validated(
          withdrawals,
          dex_order_book_input_datum.withdrawal_script_hashes.hydra_withdrawal,
        )
      }
      HydraCancelWithdrawal -> {
        let dex_order_book_input_datum: DexOrderBookDatum =
          reference_inputs
            |> get_dex_order_book_datum(dex_order_book_token)
        withdrawal_script_validated(
          withdrawals,
          dex_order_book_input_datum.withdrawal_script_hashes.hydra_cancel_withdrawal,
        )
      }
      HydraIncrementalDecommit -> {
        let dex_order_book_input_datum: DexOrderBookDatum =
          reference_inputs
            |> get_dex_order_book_datum(dex_order_book_token)
        expect Some(own_input) = find_input(inputs, utxo)
        let is_input_equal_output =
          list.any(
            outputs,
            fn(output: Output) -> Bool { output == own_input.output },
          )

        let is_operation_key_signed =
          key_signed(
            extra_signatories,
            dex_order_book_input_datum.operation_key,
          )
        is_operation_key_signed? && is_input_equal_output?
      }
      DexAccountBalanceHydraCommit ->
        validate_hydra_commit(
          reference_inputs,
          oracle_nft,
          inputs,
          redeemers,
          extra_signatories,
          utxo,
        )
      DexAccountBalanceTransferAccountBalance -> {
        let dex_order_book_input_datum: DexOrderBookDatum =
          reference_inputs
            |> get_dex_order_book_datum(dex_order_book_token)
        withdrawal_script_validated(
          withdrawals,
          dex_order_book_input_datum.withdrawal_script_hashes.hydra_internal_transfer,
        )
      }
      DexAccountBalanceSplitMerkleTree -> {
        let dex_order_book_input_datum: DexOrderBookDatum =
          reference_inputs
            |> get_dex_order_book_datum(dex_order_book_token)
        withdrawal_script_validated(
          withdrawals,
          dex_order_book_input_datum.withdrawal_script_hashes.hydra_head_open,
        )
      }
      DexAccountBalanceCombineMerkleTree -> {
        let dex_order_book_input_datum: DexOrderBookDatum =
          reference_inputs
            |> get_dex_order_book_datum(dex_order_book_token)
        withdrawal_script_validated(
          withdrawals,
          dex_order_book_input_datum.withdrawal_script_hashes.hydra_head_close,
        )
      }
      DexAccountBalanceSpamPreventionWithdraw -> {
        let oracle_input_datum: AppOracleDatum =
          reference_inputs |> get_app_oracle_datum(oracle_nft)
        expect Some(own_input) = find_input(inputs, utxo)
        let no_auth_token_check =
          tokens(
            own_input.output.value,
            oracle_input_datum.dex_account_balance_token,
          )
            |> is_empty()
        let is_operation_key_signed =
          key_signed(extra_signatories, oracle_input_datum.operation_key)

        no_auth_token_check? && is_operation_key_signed?
      }
      DexAccountBalanceRemoveRegistry -> {
        let AppOracleDatum {
          operation_key,
          dex_account_balance_address,
          dex_account_balance_token,
          ..
        }: AppOracleDatum = reference_inputs |> get_app_oracle_datum(oracle_nft)
        expect [account_balance_input] =
          inputs_at_with_policy(
            inputs,
            dex_account_balance_address,
            dex_account_balance_token,
          )
        expect DexAccountBalanceDatum { account_balance_merkle_root }: DexAccountBalanceDatum =
          input_inline_datum(account_balance_input)
        let is_empty_root = account_balance_merkle_root == mpf.root(mpf.empty)

        expect [Pair(_asset_name, quantity)] =
          mint |> assets.tokens(dex_account_balance_token) |> dict.to_pairs()
        let is_auth_token_burnt = quantity == -1

        let is_operation_key_signed =
          key_signed(extra_signatories, operation_key)
        is_empty_root? && is_auth_token_burnt? && is_operation_key_signed?
      }
    }
  }

  else(_) {
    fail
  }
}
