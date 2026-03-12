# Specification - HydraAccount - Migration

## User Action

- Ref input with `oracle_nft`
- Get `account` from redeemer
- Old script hash from own `credential` (this withdrawal script's hash)
- New script hash from oracle's `hydra_account_script_hash`
- Categorize inputs into
  - `AI` - Account Inputs at old script hash with matching `account` datum
  - Other inputs
- Categorize outputs into
  - `AO` - Account Outputs at new `hydra_account_script_hash` (from oracle)
  - Other outputs
- No other inputs at old script hash (single account per tx)
- No inputs at new `hydra_account_script_hash` (prevent mixing with normal operations)
- All `AO` have datum with:
  - Same `account_id`
  - Same `master_key`
  - Same `operation_key`
  - `trading_logic` updated to new `hydra_order_book_script_hash` from oracle
- Total value preserved: `inputs_value(AI) == outputs_value(AO)`
- Signed by `operation_key`

## Note - Migration Workflow

1. Cancel all existing orders
2. Combine `hydra_account` utxos into 1 utxo per user
3. Update the `dex_order_book` oracle datum with new script hashes (`hydra_account` and `hydra_order_book` mainly) and `hydra_signers` keys
4. Migrate all `hydra_account` UTxOs using `ProcessMigration` withdrawal on the **new** script

Old account UTxOs are spent with `HydraAccountMigrate` redeemer. This derives the script's own hash from the input address and validates its own withdrawal script. The old script's `ProcessMigration` withdrawal then reads the new `hydra_account_script_hash` from the updated oracle to validate outputs are sent to the new script with correct migrated datums.
