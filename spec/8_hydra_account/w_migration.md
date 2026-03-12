# Specification - HydraAccount - Migration

## Overview

Periodic migration workflow for updating `hydra_account` and `hydra_order_book` scripts.

## Migration Steps

1. Cancel all existing orders
2. Update the `dex_order_book` oracle datum with new `hydra_signers` keys
3. Migrate all `hydra_account` UTxOs:
   - Same `master_key` + `operation_key` preserved
   - `trading_logic` updated to the latest `hydra_order_book_script_hash` from `dex_order_book` oracle

## Open Questions

### Oracle Update vs Migration Ordering

If step 2 (oracle update) happens before step 3 (migration), the old `hydra_account` validator can no longer look up its own script hash from the oracle — the oracle now points to the new script hash. This means `withdrawal_script_validated(withdrawals, hydra_account_script_hash)` in the old validator would check against the **new** hash, not the old one, and the old script's withdrawal cannot be triggered.

Options:
- **Option A**: Perform step 3 before step 2 — migrate accounts while the oracle still references the old scripts
- **Option B**: Have the migration redeemer use `operation_key` signature directly (like `HydraAccountSpamPreventionWithdraw`) rather than the withdrawal-based pattern

### Output Validation

The migration validator must ensure:
- New UTxOs are sent to the **new** `hydra_account_script_hash`
- `trading_logic` in the datum is correctly updated to the new `hydra_order_book_script_hash`
- The source of truth for the new script hash must be authoritative (the updated oracle, or a validator parameter)
