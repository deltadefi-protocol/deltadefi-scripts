use cardano/assets.{PolicyId}
use cardano/transaction.{OutputReference, Transaction}
use cocktail.{withdrawal_script_validated}
use hydra_dex/types.{
  AppOracleDatum, AppVaultRedeemer, AppVaultStakeKeyRotation, AppVaultWithdraw,
}
use hydra_dex/utils.{get_app_oracle_datum}

validator app_vault(oracle_nft: PolicyId) {
  spend(_, redeemer: AppVaultRedeemer, _input: OutputReference, tx: Transaction) {
    let Transaction { reference_inputs, withdrawals, .. } = tx

    let oracle_input_datum: AppOracleDatum =
      reference_inputs |> get_app_oracle_datum(oracle_nft)

    when redeemer is {
      AppVaultWithdraw ->
        withdrawal_script_validated(
          withdrawals,
          oracle_input_datum.all_withdrawal_script_hashes.app_withdrawal,
        )
      AppVaultStakeKeyRotation ->
        withdrawal_script_validated(
          withdrawals,
          oracle_input_datum.all_withdrawal_script_hashes.app_vault_stake_rotation,
        )
    }
  }

  else(_) {
    fail
  }
}
