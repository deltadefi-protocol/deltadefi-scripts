use cardano/address.{Credential}
use cardano/assets.{PolicyId}
use cardano/certificate.{Certificate}
use cardano/transaction.{Transaction}
use cocktail.{get_all_value_from_script, get_all_value_to_script, key_signed}
use hydra_dex/types.{AppOracleDatum}
use hydra_dex/utils.{get_app_oracle_datum}

validator app_vault_stake_rotation(oracle_nft: PolicyId) {
  withdraw(_redeemer: Data, _credential: Credential, tx: Transaction) {
    let Transaction { inputs, outputs, reference_inputs, extra_signatories, .. } =
      tx

    let AppOracleDatum { operation_key, app_vault_script_hash, .. }: AppOracleDatum =
      reference_inputs |> get_app_oracle_datum(oracle_nft)

    //  - value from vault script hash == value to vault script hash
    let value_from_vault =
      get_all_value_from_script(inputs, app_vault_script_hash)
    let value_to_vault = get_all_value_to_script(outputs, app_vault_script_hash)
    let is_vault_value_unchanged =
      value_to_vault
        |> assets.match(value_from_vault, ==)
    //  - Operation key is signed
    let is_stake_rotation_authorized =
      key_signed(extra_signatories, operation_key)

    and {
      is_vault_value_unchanged,
      is_stake_rotation_authorized?,
    }
  }

  publish(_redeemer: Data, _credential: Certificate, tx: Transaction) {
    let Transaction { reference_inputs, extra_signatories, .. } = tx
    let AppOracleDatum { operation_key, .. }: AppOracleDatum =
      reference_inputs |> get_app_oracle_datum(oracle_nft)

    key_signed(extra_signatories, operation_key)?
  }

  else(_) {
    fail @"unsupported purpose"
  }
}
