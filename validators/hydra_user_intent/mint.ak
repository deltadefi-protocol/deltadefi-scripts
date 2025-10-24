use cardano/assets.{PolicyId}
use cardano/transaction.{Transaction}
use cocktail.{
  key_signed, only_minted_token, output_inline_datum, outputs_at_with_policy,
}
use hydra_dex/account_utils.{trade_auth_by_account, withdrawal_auth_by_account}
use hydra_dex/types.{
  BurnIntent, CancelOrderIntent, CancelWithdrawalIntent, DexOrderBookDatum,
  HydraUserCancelOrder, HydraUserCancelWithdrawal, HydraUserIntentDatum,
  HydraUserIntentRedeemer, HydraUserPlaceOrder, HydraUserTransfer,
  HydraUserWithdrawal, MintCancelOrderIntent, MintCancelWithdrawalIntent,
  MintPlaceOrderIntent, MintTransferIntent, MintWithdrawalIntent,
  PlaceOrderIntent, TransferIntent, WithdrawalIntent,
}
use hydra_dex/utils.{get_dex_order_book_datum, withdrawal_script_validated}

validator hydra_user_intent(dex_oracle_nft: PolicyId) {
  mint(
    redeemer: HydraUserIntentRedeemer,
    policy_id: PolicyId,
    self: Transaction,
  ) {
    let Transaction {
      mint,
      reference_inputs,
      withdrawals,
      extra_signatories,
      outputs,
      ..
    } = self

    let dex_order_book_input_datum: DexOrderBookDatum =
      reference_inputs
        |> get_dex_order_book_datum(dex_oracle_nft)
    when redeemer is {
      MintPlaceOrderIntent { order } -> {
        let token_check = only_minted_token(mint, policy_id, "", 1)
        let only_output_check =
          when
            outputs_at_with_policy(
              outputs,
              dex_order_book_input_datum.hydra_user_intent_address,
              dex_order_book_input_datum.hydra_user_intent_token,
            )
          is {
            [only_output] -> {
              expect only_output_datum: HydraUserIntentDatum =
                output_inline_datum(only_output)
              let correct_output_datum =
                PlaceOrderIntent {
                  order_id: order.order_id,
                  long_token: order.long_token,
                  short_token: order.short_token,
                  is_long: order.is_long,
                  list_price_times_1bil: order.list_price_times_1bil,
                  order_size: order.order_size,
                  fee_amount_bp: order.fee_amount_bp,
                  extra_value: order.extra_value,
                  account: order.account,
                }
              only_output_datum == correct_output_datum
            }
            _ -> False
          }

        let is_account_auth =
          trade_auth_by_account(order.account, withdrawals, extra_signatories)
        token_check? && only_output_check? && is_account_auth?
      }
      HydraUserPlaceOrder ->
        withdrawal_script_validated(
          withdrawals,
          dex_order_book_input_datum.withdrawal_script_hashes.hydra_place_order,
        )
      MintCancelOrderIntent { account, order_id } -> {
        let token_check = only_minted_token(mint, policy_id, "", 1)
        let only_output_check =
          when
            outputs_at_with_policy(
              outputs,
              dex_order_book_input_datum.hydra_user_intent_address,
              dex_order_book_input_datum.hydra_user_intent_token,
            )
          is {
            [only_output] -> {
              expect only_output_datum: HydraUserIntentDatum =
                output_inline_datum(only_output)
              let correct_output_datum = CancelOrderIntent { account, order_id }
              only_output_datum == correct_output_datum
            }
            _ -> False
          }
        let is_account_auth =
          trade_auth_by_account(account, withdrawals, extra_signatories)
        token_check? && only_output_check? && is_account_auth?
      }
      HydraUserCancelOrder ->
        withdrawal_script_validated(
          withdrawals,
          dex_order_book_input_datum.withdrawal_script_hashes.hydra_cancel_order,
        )
      MintWithdrawalIntent { account, amount } -> {
        let token_check = only_minted_token(mint, policy_id, "", 1)
        let only_output_check =
          when
            outputs_at_with_policy(
              outputs,
              dex_order_book_input_datum.hydra_user_intent_address,
              dex_order_book_input_datum.hydra_user_intent_token,
            )
          is {
            [only_output] -> {
              expect only_output_datum: HydraUserIntentDatum =
                output_inline_datum(only_output)
              let correct_output_datum = WithdrawalIntent { account, amount }
              only_output_datum == correct_output_datum
            }
            _ -> False
          }
        let is_account_auth =
          withdrawal_auth_by_account(account, withdrawals, extra_signatories)
        token_check? && only_output_check? && is_account_auth?
      }

      HydraUserWithdrawal ->
        withdrawal_script_validated(
          withdrawals,
          dex_order_book_input_datum.withdrawal_script_hashes.hydra_withdrawal,
        )
      MintCancelWithdrawalIntent { account, amount } -> {
        let token_check = only_minted_token(mint, policy_id, "", 1)
        let only_output_check =
          when
            outputs_at_with_policy(
              outputs,
              dex_order_book_input_datum.hydra_user_intent_address,
              dex_order_book_input_datum.hydra_user_intent_token,
            )
          is {
            [only_output] -> {
              expect only_output_datum: HydraUserIntentDatum =
                output_inline_datum(only_output)
              let correct_output_datum =
                CancelWithdrawalIntent { account, amount }
              only_output_datum == correct_output_datum
            }
            _ -> False
          }
        let is_account_auth =
          withdrawal_auth_by_account(account, withdrawals, extra_signatories)
        token_check? && only_output_check? && is_account_auth?
      }

      HydraUserCancelWithdrawal ->
        withdrawal_script_validated(
          withdrawals,
          dex_order_book_input_datum.withdrawal_script_hashes.hydra_cancel_withdrawal,
        )
      MintTransferIntent { from, to, amount } -> {
        let token_check = only_minted_token(mint, policy_id, "", 1)

        let only_output_check =
          when
            outputs_at_with_policy(
              outputs,
              dex_order_book_input_datum.hydra_user_intent_address,
              dex_order_book_input_datum.hydra_user_intent_token,
            )
          is {
            [only_output] -> {
              expect only_output_datum: HydraUserIntentDatum =
                output_inline_datum(only_output)
              let correct_output_datum = TransferIntent { from, to, amount }
              only_output_datum == correct_output_datum
            }
            _ -> False
          }
        let is_account_auth =
          withdrawal_auth_by_account(from, withdrawals, extra_signatories)
        token_check? && only_output_check? && is_account_auth?
      }
      HydraUserTransfer ->
        withdrawal_script_validated(
          withdrawals,
          dex_order_book_input_datum.withdrawal_script_hashes.hydra_internal_transfer,
        )
      BurnIntent ->
        key_signed(extra_signatories, dex_order_book_input_datum.operation_key)
    }
  }

  else(_) {
    fail
  }
}
