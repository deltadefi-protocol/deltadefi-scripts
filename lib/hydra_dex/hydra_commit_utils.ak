use aiken/collection/list.{all, find, has}
use aiken/crypto.{ScriptHash, VerificationKeyHash}
use cardano/address.{Script}
use cardano/transaction.{Input, OutputReference, Redeemer, ScriptPurpose, Spend}
use hydra_dex/types.{AppOracleDatum, ViaCommit}
use hydra_dex/utils.{get_app_oracle_datum}

pub fn validate_hydra_commit(
  reference_inputs: List<Input>,
  oracle_nft: ScriptHash,
  inputs: List<Input>,
  redeemers: Pairs<ScriptPurpose, Redeemer>,
  extra_signatories: List<VerificationKeyHash>,
  utxo: OutputReference,
) -> Bool {
  let oracle_input_datum: AppOracleDatum =
    reference_inputs |> get_app_oracle_datum(oracle_nft)
  let hydra_initial_hash: ScriptHash =
    oracle_input_datum.hydra_info.hydra_initial_hash
  let hydra_required_signers: List<VerificationKeyHash> =
    oracle_input_datum.hydra_info.hydra_signers
  expect Some(hydra_initial_input) =
    inputs
      |> find(
          fn(input: Input) {
            let input_cred = input.output.address.payment_credential
            when input_cred is {
              Script(input_script_hash) ->
                input_script_hash == hydra_initial_hash
              _ -> False
            }
          },
        )
  expect Some(hydra_initial_redeemer_data) =
    redeemers
      |> find(
          fn(redeemer: Pair<ScriptPurpose, Redeemer>) {
            let purpose = redeemer.1st
            when purpose is {
              Spend(input_ref) ->
                input_ref == hydra_initial_input.output_reference
              _ -> False
            }
          },
        )
  expect ViaCommit { committed_refs } = hydra_initial_redeemer_data.2nd
  let committed_ref_check = committed_refs |> has(utxo)
  let hydra_signers_check =
    hydra_required_signers
      |> all(
          fn(signer: VerificationKeyHash) { extra_signatories |> has(signer) },
        )
  committed_ref_check? && hydra_signers_check?
}
