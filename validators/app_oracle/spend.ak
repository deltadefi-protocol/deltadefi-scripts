use aiken/collection/list.{all}
use cardano/transaction.{OutputReference, Transaction, find_input}
use cocktail.{
  key_signed, output_inline_datum, outputs_at_with_policy, value_length,
  value_tokens,
}
use hydra_dex/types.{
  AppOracleDatum, AppOracleRedeemer, DexRotateKey, HydraInfo, RotateHydraInfo,
  StopDex,
}

validator app_oracle {
  spend(
    datum_opt: Option<AppOracleDatum>,
    redeemer: AppOracleRedeemer,
    input: OutputReference,
    self: Transaction,
  ) {
    let Transaction { outputs, inputs, extra_signatories, .. } = self
    expect Some(own_input) = find_input(inputs, input)
    expect [(oracle_nft_policy, _, _)] = value_tokens(own_input.output.value)
    expect Some(datum) = datum_opt
    let is_stop_key_signed = key_signed(extra_signatories, datum.stop_key)

    when
      (
        redeemer,
        outputs_at_with_policy(
          outputs,
          own_input.output.address,
          oracle_nft_policy,
        ),
      )
    is {
      (DexRotateKey { new_operation_key, new_stop_key }, [only_output]) -> {
        let is_new_stop_key_signed = key_signed(extra_signatories, new_stop_key)
        let is_output_value_clean = value_length(only_output.value) == 2

        expect only_output_datum: AppOracleDatum =
          output_inline_datum(only_output)
        let updated_output_datum =
          AppOracleDatum {
            ..datum,
            operation_key: new_operation_key,
            stop_key: new_stop_key,
          }
        let is_output_datum_updated = only_output_datum == updated_output_datum
        and {
          is_stop_key_signed?,
          is_output_value_clean?,
          is_new_stop_key_signed?,
          is_output_datum_updated?,
        }
      }
      (StopDex, [only_output]) -> {
        let is_output_value_clean = value_length(only_output.value) == 2
        expect only_output_datum: AppOracleDatum =
          output_inline_datum(only_output)
        let updated_output_datum =
          AppOracleDatum { ..datum, operation_key: #"", stop_key: #"" }
        let is_output_datum_updated = only_output_datum == updated_output_datum
        and {
          is_stop_key_signed?,
          is_output_value_clean?,
          is_output_datum_updated?,
        }
      }
      (RotateHydraInfo { new_hydra_info }, [only_output]) -> {
        let is_output_value_clean = value_length(only_output.value) == 2
        expect only_output_datum: AppOracleDatum =
          output_inline_datum(only_output)
        let updated_output_datum =
          AppOracleDatum { ..datum, hydra_info: new_hydra_info }
        let is_output_datum_updated = only_output_datum == updated_output_datum

        let is_all_hydra_signers_signed =
          datum.hydra_info.hydra_signers
            |> all(fn(signer) { key_signed(extra_signatories, signer) })

        and {
          is_all_hydra_signers_signed?,
          is_output_value_clean,
          is_output_datum_updated?,
        }
      }
      _ -> False
    }
  }

  else(_) {
    fail
  }
}
