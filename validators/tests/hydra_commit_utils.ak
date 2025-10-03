use cardano/assets.{from_asset, zero}
use cardano/transaction.{Redeemer, Spend, Transaction}
use hydra_dex/hydra_commit_utils.{validate_hydra_commit}
use hydra_dex/types.{ViaCommit}
use mocktail.{
  add_redeemer, complete, mock_tx_hash, mock_utxo_ref, mocktail_tx, ref_tx_in,
  ref_tx_in_inline_datum, required_signer_hash, tx_in,
}
use tests/utils.{
  mock_hydra_script_address, mock_hydra_signer_1, mock_hydra_signer_2,
  mock_hydra_signer_3, mock_input_oracle_datum, mock_oracle_address,
  mock_oracle_nft,
}

fn mock_hydra_commit_tx(
  is_utxo_committed: Bool,
  is_all_keys_signed: Bool,
) -> Transaction {
  let hydra_redeemer: Redeemer =
    if is_utxo_committed {
      ViaCommit { committed_refs: [mock_utxo_ref(0, 1)] }
    } else {
      ViaCommit { committed_refs: [] }
    }

  mocktail_tx()
    |> ref_tx_in(
        True,
        mock_tx_hash(0),
        0,
        from_asset(mock_oracle_nft, "", 1),
        mock_oracle_address,
      )
    |> ref_tx_in_inline_datum(True, mock_input_oracle_datum)
    |> tx_in(True, mock_tx_hash(0), 1, zero, mock_hydra_script_address)
    |> required_signer_hash(True, mock_hydra_signer_1)
    |> required_signer_hash(True, mock_hydra_signer_2)
    |> required_signer_hash(is_all_keys_signed, mock_hydra_signer_3)
    |> complete()
    |> add_redeemer(True, Pair(Spend(mock_utxo_ref(0, 1)), hydra_redeemer))
}

test vhc_success() {
  let tx = mock_hydra_commit_tx(True, True)
  let reference_inputs = tx.reference_inputs
  let inputs = tx.inputs
  let redeemers = tx.redeemers
  let extra_signatories = tx.extra_signatories
  validate_hydra_commit(
    reference_inputs,
    mock_oracle_nft,
    inputs,
    redeemers,
    extra_signatories,
    mock_utxo_ref(0, 1),
  )
}

test vhc_failed_without_utxo_committed() {
  let tx = mock_hydra_commit_tx(False, True)
  let reference_inputs = tx.reference_inputs
  let inputs = tx.inputs
  let redeemers = tx.redeemers
  let extra_signatories = tx.extra_signatories
  !validate_hydra_commit(
    reference_inputs,
    mock_oracle_nft,
    inputs,
    redeemers,
    extra_signatories,
    mock_utxo_ref(0, 1),
  )
}

test vhc_failed_without_all_hydra_signer_signatures() {
  let tx = mock_hydra_commit_tx(True, False)
  let reference_inputs = tx.reference_inputs
  let inputs = tx.inputs
  let redeemers = tx.redeemers
  let extra_signatories = tx.extra_signatories
  !validate_hydra_commit(
    reference_inputs,
    mock_oracle_nft,
    inputs,
    redeemers,
    extra_signatories,
    mock_utxo_ref(0, 1),
  )
}
