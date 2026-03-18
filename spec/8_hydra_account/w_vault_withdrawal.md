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
  - `VI` - Vault Inputs (by `master_key == Script(l2_withdrawal_intent_script_hash)`)
  - Other inputs
- Categorize outputs into
  - `WO` - Withdrawer Outputs (by full `UserAccount`)
  - `VO` - Vault Outputs (by `master_key == Script(l2_withdrawal_intent_script_hash)`)
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
  - SharesInsert or SharesUpdate for operator
- Vault Oracle output datum updated:
  - `total_shares = input_total_shares - shares_to_redeem + fee_shares`
  - `operator_shares += fee_shares`
  - `total_deposited -= cost_basis`
  - `total_fee_collected += fee`
  - `shares_merkle_root = final_root`
- The intent token is burnt
- Signed by `operation_key` OR `operator_key`

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
