# Specification - HydraAccount - Vault Withdrawal

## User Action

- Ref input with `dex_oracle_nft`
- Get `II` - Intent Input from burn event (negative mint quantity)
- `II` with `VaultWithdrawalIntentDatumL2` datum
  - `vault_oracle_nft`, `withdrawer: UserAccount`, `shares_to_redeem: Int`
- Get Vault Oracle input/output (UTxO with `vault_oracle_nft`)
- Validate intent script matches vault config (`intent_policy_id == l2_withdrawal_intent_script_hash`)
- Verify prices message with hydra node signatures
- Calculate withdrawal values:
  - `gross_value = (shares_to_redeem * vault_equity) / total_shares` (round DOWN)
  - `cost_basis` from merkle proof (proportional for partial withdrawal)
  - `fee = ceil((profit * operator_charge_percentage) / 100)` if profit > 0
  - `fee_shares = ceil((fee * total_shares) / vault_equity)`
  - `user_receives = gross_value - fee`
- Categorize inputs into
  - `WI` - Withdrawer Inputs (by full `UserAccount`)
  - `VI` - Vault Inputs (by `master_key == Script(vault_script_hash)`)
  - Other inputs
- Categorize outputs into
  - `WO` - Withdrawer Outputs (by full `UserAccount`)
  - `VO` - Vault Outputs (by `master_key == Script(vault_script_hash)`)
  - Other outputs
- No other inputs/outputs at `hydra_account_script_hash`
- Value transfer validated (in USD):
  - Convert L2 UTxO values to L1 using `token_map` for price lookup
  - Vault deducted (L2 → L1 → USD) == `user_receives`
  - Withdrawer added (L2 → L1 → USD) == `user_receives`
- Verify User Merkle transition (SharesUpdate or SharesDelete)
  - Key: `cbor.serialise(withdrawer)` (UserAccount)
  - SharesDelete: full withdrawal, `shares_to_redeem == old_entry.shares`
  - SharesUpdate: partial withdrawal, deduct shares and proportional cost_basis
- Apply Operator Fee Shares (if `fee_shares > 0`)
  - Key: `cbor.serialise(operator_account)` (UserAccount)
  - SharesInsert: New entry with `{ shares: fee_shares, total_deposited: 0 }`
  - SharesUpdate: Add fee_shares to existing entry, **`total_deposited` remains unchanged**
  - Fee shares represent earned fees, not new capital deposits
- **Operator minimum share percentage check** (only when operator withdraws):
  - `new_operator_shares * 100 >= operator_min_deposit_percentage * new_total_shares`
  - Ensures operator maintains minimum stake in the vault
- Vault Oracle output datum updated:
  - `total_shares = input_total_shares - shares_to_redeem + fee_shares`
  - `operator_shares`:
    - If `withdrawer == operator_account`: `operator_shares - shares_to_redeem + fee_shares`
    - If `withdrawer != operator_account`: `operator_shares + fee_shares`
  - `total_deposited -= cost_basis`
  - `total_fee_collected += fee`
  - `shares_merkle_root = final_root`
- The intent token is burnt
- Signed by `operation_key` OR `operator_key`

## Edge Case: Operator == Withdrawer

When the operator is also the withdrawer, both MPF transitions operate on the **same entry**:

1. **Step 1 (User MPF)**: Update/delete the withdrawer's entry → `new_user_root`
2. **Step 2 (Operator MPF)**: Insert/update the operator's entry using `new_user_root` → `final_root`

| Scenario | Step 1 | Step 2 | Final Entry |
|----------|--------|--------|-------------|
| Full withdrawal | Delete entry | SharesInsert | `{ shares: fee_shares, total_deposited: 0 }` |
| Partial withdrawal | Update (reduce shares/deposited) | SharesUpdate | `{ shares: remaining + fee_shares, total_deposited: reduced }` |

**Important**: The `operator_mpf_action.from` value must reflect the state **AFTER** step 1's transition.

## L1 vs L2 Asset Units

- **Price message** contains prices in **L1 format**: `Pairs<(PolicyId, AssetName), Int>`
- **Account UTxOs** contain values in **L2 format**: `(hydra_token_policy_id, hash_token(policy_id, asset_name), qty)`
- **Token map** (`TokenMap = Pairs<ByteArray, (PolicyId, AssetName)>`) maps L2 asset hash → L1 asset identity
- Validator converts L2 UTxO values to L1 using `from_hydra_balance_to_value(l2_value, hydra_token_policy_id, token_map)` before price lookup

## Redeemer

```
ProcessVaultWithdrawal(
  prices_message: ByteArray,
  signatures: List<ByteArray>,
  token_map: TokenMap,
  mpf_action: SharesMPFAction,
  operator_mpf_action: SharesMPFAction,
)
```
