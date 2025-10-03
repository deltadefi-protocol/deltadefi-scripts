use cardano/assets.{PolicyId}
use cardano/transaction.{OutputReference, Transaction}
use hydra_dex/types.{AppOracleDatum}
use hydra_dex/utils.{get_app_oracle_datum, withdrawal_script_validated}

validator app_vault(oracle_nft: PolicyId) {
  spend(_, _redeemer: Data, _input: OutputReference, tx: Transaction) {
    let Transaction { reference_inputs, withdrawals, .. } = tx

    let oracle_input_datum: AppOracleDatum =
      reference_inputs |> get_app_oracle_datum(oracle_nft)

    withdrawal_script_validated(
      withdrawals,
      oracle_input_datum.all_withdrawal_script_hashes.app_withdrawal,
    )
  }

  else(_) {
    fail
  }
}
