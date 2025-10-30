use cardano/address.{Credential}
use cardano/assets.{PolicyId, zero}
use cardano/certificate.{Certificate}
use cardano/transaction.{Transaction}
use cocktail.{
  input_inline_datum, inputs_at_with_policy, key_signed, output_inline_datum,
  outputs_at_with_policy, policy_only_minted_token,
}
use cocktail/vodka_outputs.{outputs_at_with}
use hydra_dex/account_utils.{hydra_balance_decrease}
use hydra_dex/order_utils.{get_order_value}
use hydra_dex/types.{
  DexOrderBookDatum, HydraOrderBookDatum, HydraUserIntentDatum, PlaceOrderIntent,
}
use hydra_dex/utils.{get_dex_order_book_datum}

validator place_order(oracle_nft: PolicyId) {
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

    //  - Input from `HydraUserIntent` with `LimitOrder` datum
    //  - Exactly 1 output to `HydraOrderBook`, with exactly the same datum as input from current address (i.e. `LimitOrder`), except `order_id`
    let (is_order_correctly_placed, order_value) =
      when
        inputs_at_with_policy(
          inputs,
          hydra_user_intent_address,
          hydra_user_intent_token,
        )
      is {
        [intent_input] -> {
          expect PlaceOrderIntent {
            order_id: intent_order_id,
            long_token: intent_long_token,
            short_token: intent_short_token,
            is_long: intent_is_long,
            list_price_times_1bil: intent_list_price_times_1bil,
            order_size: intent_order_size,
            fee_amount_bp: intent_fee_amount_bp,
            account: intent_account,
            ..
          }: HydraUserIntentDatum = input_inline_datum(intent_input)

          when
            outputs_at_with(
              outputs,
              hydra_order_book_address,
              hydra_order_book_token,
              intent_order_id,
            )
          is {
            [order_output] -> {
              expect order_datum: HydraOrderBookDatum =
                output_inline_datum(order_output)

              let HydraOrderBookDatum {
                order_id,
                long_token,
                short_token,
                is_long,
                fee_amount_bp,
                account,
                list_price_times_1bil,
                order_size,
                ..
              } = order_datum

              //  - `HydraOrderBook` auth token minted with token name of `order_id`
              let is_order_token_minted =
                policy_only_minted_token(
                  mint,
                  hydra_order_book_token,
                  order_id,
                  1,
                )

              //  - The input token is burnt
              let is_intent_token_burnt =
                policy_only_minted_token(mint, hydra_user_intent_token, "", -1)

              let is_datum_correct =
                intent_order_id == order_id && intent_long_token == long_token && intent_short_token == short_token && intent_is_long == is_long && intent_fee_amount_bp == fee_amount_bp && intent_account == account && intent_order_size == order_size
              let order_value = get_order_value(order_datum)

              let is_price_correct =
                when intent_is_long is {
                  True -> list_price_times_1bil <= intent_list_price_times_1bil
                  False -> list_price_times_1bil >= intent_list_price_times_1bil
                }

              (
                is_order_token_minted? && is_intent_token_burnt? && is_datum_correct? && is_price_correct?,
                order_value,
              )
            }
            _ -> (False, zero)
          }
        }

        _ -> (False, zero)
      }
    //  - Deduct the account balance from `HydraAccountBalance` with corresponding auth token
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
          hydra_balance_decrease(balance_input, balance_output, order_value)
        _ -> False
      }

    let is_place_order_authorized = key_signed(extra_signatories, operation_key)

    is_order_correctly_placed? && is_account_balance_updated? && is_place_order_authorized?
  }

  publish(_redeemer: Data, _credential: Certificate, _tx: Transaction) {
    True
  }

  else(_) {
    fail @"unsupported purpose"
  }
}
