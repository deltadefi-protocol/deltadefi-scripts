use aiken/collection/list.{all, has}
use aiken/crypto.{ScriptHash, VerificationKeyHash}
use cardano/transaction.{Input, OutputReference, Redeemer, ScriptPurpose}
use hydra_dex/types.{AppOracleDatum}
use hydra_dex/utils.{get_app_oracle_datum}

pub fn validate_hydra_commit(
  reference_inputs: List<Input>,
  oracle_nft: ScriptHash,
  _inputs: List<Input>,
  _redeemers: Pairs<ScriptPurpose, Redeemer>,
  extra_signatories: List<VerificationKeyHash>,
  _utxo: OutputReference,
) -> Bool {
  let oracle_input_datum: AppOracleDatum =
    reference_inputs |> get_app_oracle_datum(oracle_nft)
  let hydra_required_signers: List<VerificationKeyHash> =
    oracle_input_datum.hydra_info.hydra_signers
  let hydra_signers_check =
    hydra_required_signers
      |> all(
          fn(signer: VerificationKeyHash) { extra_signatories |> has(signer) },
        )
  hydra_signers_check
}
