use cardano/address.{Credential}
use cardano/assets.{PolicyId, zero}
use cardano/certificate.{Certificate}
use cardano/transaction.{Transaction}
use cocktail.{
  input_inline_datum, inputs_at_with, inputs_at_with_policy, key_signed,
  outputs_at_with_policy, policy_only_minted_token,
}
use hydra_dex/account_utils.{hydra_balance_increase}
use hydra_dex/order_utils.{get_order_value}
use hydra_dex/types.{
  CancelOrderIntent, DexOrderBookDatum, HydraOrderBookDatum,
  HydraUserIntentDatum,
}
use hydra_dex/utils.{get_dex_order_book_datum}

validator cancel_order(oracle_nft: PolicyId) {
  withdraw(_redeemer: Data, _credential: Credential, tx: Transaction) {
    let Transaction {
      inputs,
      outputs,
      reference_inputs,
      extra_signatories,
      mint,
      ..
    } = tx

    let DexOrderBookDatum {
      operation_key,
      hydra_user_intent_token,
      hydra_user_intent_address,
      hydra_account_balance_token,
      hydra_account_balance_address,
      hydra_order_book_token,
      hydra_order_book_address,
      ..
    }: DexOrderBookDatum =
      reference_inputs |> get_dex_order_book_datum(oracle_nft)

    //  - Input from `HydraUserIntent` with `CancelOrder {account, order_id}` datum
    //  - Exactly 1 input from `HydraOrderBook`, with auth token name of `order_id`
    let (is_order_correctly_cancelled, order_value) =
      when
        inputs_at_with_policy(
          inputs,
          hydra_user_intent_address,
          hydra_user_intent_token,
        )
      is {
        [intent_input] -> {
          expect CancelOrderIntent { account: intent_account, order_id }: HydraUserIntentDatum =
            input_inline_datum(intent_input)
          when
            inputs_at_with(
              inputs,
              hydra_order_book_address,
              hydra_order_book_token,
              order_id,
            )
          is {
            [order_input] -> {
              expect order_datum: HydraOrderBookDatum =
                input_inline_datum(order_input)

              //  - `HydraOrderBook` auth token burnt with token name of `order_id`
              let is_order_token_minted =
                policy_only_minted_token(
                  mint,
                  hydra_order_book_token,
                  order_id,
                  -1,
                )

              //  - The input token is burnt
              let is_intent_token_burnt =
                policy_only_minted_token(mint, hydra_user_intent_token, "", -1)

              //  - The datum of `HydraOrderBook` input contains same account as `HydraUserIntent`
              let is_order_owned_by_account =
                intent_account == order_datum.account

              let order_value = get_order_value(order_datum)
              (
                is_order_token_minted && is_intent_token_burnt && is_order_owned_by_account,
                order_value,
              )
            }
            _ -> (False, zero)
          }
        }

        _ -> (False, zero)
      }
    //  - Add the account balance from `HydraAccountBalance` with corresponding auth token
    let is_account_balance_updated =
      when
        (
          inputs_at_with_policy(
            inputs,
            hydra_account_balance_address,
            hydra_account_balance_token,
          ),
          outputs_at_with_policy(
            outputs,
            hydra_account_balance_address,
            hydra_account_balance_token,
          ),
        )
      is {
        ([balance_input], [balance_output]) ->
          hydra_balance_increase(balance_input, balance_output, order_value)
        _ -> False
      }

    //  - Signed by `operating_key`
    let is_cancel_order_authorized =
      key_signed(extra_signatories, operation_key)

    is_order_correctly_cancelled && is_account_balance_updated && is_cancel_order_authorized
  }

  publish(_redeemer: Data, _credential: Certificate, _tx: Transaction) {
    True
  }

  else(_) {
    fail @"unsupported purpose"
  }
}
