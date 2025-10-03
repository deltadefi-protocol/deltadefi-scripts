use cardano/address.{Credential}
use cardano/assets.{PolicyId, from_asset, zero}
use cardano/certificate.{Certificate}
use cardano/transaction.{Transaction}
use cocktail.{
  input_inline_datum, inputs_at_with_policy, key_signed, output_inline_datum,
  outputs_at_with_policy,
}
use cocktail/vodka_outputs.{outputs_at_with}
use hydra_dex/account_utils.{hydra_balance_increase}
use hydra_dex/types.{DexOrderBookDatum, HydraOrderBookDatum}
use hydra_dex/utils.{get_dex_order_book_datum}

validator release_extra_value(oracle_nft: PolicyId) {
  withdraw(_redeemer: Data, _credential: Credential, tx: Transaction) {
    let Transaction { inputs, outputs, reference_inputs, extra_signatories, .. } =
      tx

    let DexOrderBookDatum {
      operation_key,
      hydra_account_balance_token,
      hydra_account_balance_address,
      hydra_order_book_token,
      hydra_order_book_address,
      ..
    }: DexOrderBookDatum =
      reference_inputs |> get_dex_order_book_datum(oracle_nft)

    //  - Only 1 input and output from and to `HydraOrderBook`
    //  - The updated datum to `HydraOrderBook` has nothing different apart from `extra_value` is leq original one
    let (is_order_correctly_cancelled, extra_value) =
      when
        inputs_at_with_policy(
          inputs,
          hydra_order_book_address,
          hydra_order_book_token,
        )
      is {
        [order_input] -> {
          expect input_order_datum: HydraOrderBookDatum =
            input_inline_datum(order_input)
          when
            outputs_at_with(
              outputs,
              hydra_order_book_address,
              hydra_order_book_token,
              input_order_datum.order_id,
            )
          is {
            [order_output] -> {
              expect output_order_datum: HydraOrderBookDatum =
                output_inline_datum(order_output)

              let is_order_value_updated =
                output_order_datum == HydraOrderBookDatum {
                  ..input_order_datum,
                  extra_value: 0,
                }
              let extra_value =
                if input_order_datum.is_long {
                  let (policy, name) = input_order_datum.short_token
                  from_asset(policy, name, input_order_datum.extra_value)
                } else {
                  let (policy, name) = input_order_datum.long_token
                  from_asset(policy, name, input_order_datum.extra_value)
                }
              (is_order_value_updated, extra_value)
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
          hydra_balance_increase(balance_input, balance_output, extra_value)
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
