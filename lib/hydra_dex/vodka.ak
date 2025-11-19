use aiken/collection/pairs
use aiken/crypto.{ScriptHash}
use cardano/address.{Script}
use cardano/transaction.{Redeemer, ScriptPurpose, Withdraw}

pub fn withdrawal_script_validated_with(
  redeemers: Pairs<ScriptPurpose, Redeemer>,
  withdrawal_script_hash: ScriptHash,
  target_redeemer: Data,
) -> Bool {
  expect Some(redeemer) =
    redeemers |> pairs.get_first(Withdraw(Script(withdrawal_script_hash)))
  target_redeemer == redeemer
}
