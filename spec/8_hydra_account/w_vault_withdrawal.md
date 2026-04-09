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
  - **If `withdrawer == operator_account`**: Skip fee (economically neutral)
    - `fee = 0`, `fee_shares = 0`
    - `user_receives = gross_value`
  - **If `withdrawer != operator_account`**: Calculate fee on profit
    - `fee = floor((profit * operator_fee_rate_bp) / 10000)` if profit > 0
    - `fee_shares = floor((fee * total_shares) / vault_equity)`
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
- Apply Operator Fee Shares (only when `withdrawer != operator_account` and `fee_shares > 0`)
  - Key: `cbor.serialise(operator_account)` (UserAccount)
  - SharesInsert: New entry with `{ shares: fee_shares, total_deposited: 0 }`
  - SharesUpdate: Add fee_shares to existing entry, **`total_deposited` remains unchanged**
  - Fee shares represent earned fees, not new capital deposits
  - **Skipped when operator withdraws** (no fee collected from self)
- **Operator minimum share percentage check** (only when operator withdraws):
  - `new_operator_shares * 10000 >= operator_min_deposit_rate_bp * new_total_shares`
  - Ensures operator maintains minimum stake in the vault
- Vault Oracle output datum updated:
  - `total_shares = input_total_shares - shares_to_redeem + fee_shares`
  - `operator_shares`:
    - If `withdrawer == operator_account`: `operator_shares - shares_to_redeem` (no fee from self)
    - If `withdrawer != operator_account`: `operator_shares + fee_shares`
  - `total_deposited -= cost_basis`
  - `total_fee_share_collected += fee_shares` (0 when operator withdraws)
  - `shares_merkle_root = final_root`
- The intent token is burnt
- Signed by `operation_key` OR operator's `master_key` (from `operator_account`)

## Edge Case: Operator == Withdrawer

When the operator is also the withdrawer:

- **Fee is skipped** (economically neutral - operator paying fee to themselves)
- `fee_shares = 0`, so no operator MPF action is needed
- Only the user MPF transition is performed (update/delete withdrawer's entry)
- `final_root = new_user_root` (no second MPF step)

| Scenario           | User MPF Action | Operator MPF Action | Result         |
| ------------------ | --------------- | ------------------- | -------------- |
| Full withdrawal    | SharesDelete    | None                | Entry removed  |
| Partial withdrawal | SharesUpdate    | None                | Shares reduced |

This simplifies the transaction and reduces computation compared to the case where operator pays fees to themselves.

## L1 vs L2 Asset Units

- **Price message** contains prices in **L1 format**: `Pairs<(PolicyId, AssetName), (Int, Int)>` where tuple is `(price, scale)`
- **Account UTxOs** contain values in **L2 format**: `(hydra_token_policy_id, hash_token(policy_id, asset_name), qty)`
- **Token map** (`TokenMap = Pairs<ByteArray, (PolicyId, AssetName)>`) maps L2 asset hash → L1 asset identity
- Validator converts L2 UTxO values to L1 using `from_hydra_balance_to_value(l2_value, hydra_token_policy_id, token_map)` before price lookup
- **USD calculation**: `usd_value = Σ(amount * price / 10^scale)` for each asset

## Price Format

Each asset's price entry is a tuple `(price, scale)` where:

- `price`: Integer price value
- `scale`: Exponent for power of 10 divisor (10^scale)

| Token | Real Price | price | scale | Example Calculation                        |
| ----- | ---------- | ----- | ----- | ------------------------------------------ |
| USDC  | $1.00      | 1     | 0     | `1000000 * 1 / 10^0 = 1000000` (1 USD)     |
| ADA   | $0.50      | 5     | 1     | `1000000 * 5 / 10^1 = 500000` (0.50 USD)   |
| BTC   | $50,000    | 50000 | 0     | `100000000 * 50000 / 10^0 = 5000000000000` |

This allows each token to have its own scale factor (as power of 10) to prevent integer overflow in the backend while maintaining integer-only arithmetic on-chain.

## Redeemer

```
ProcessVaultWithdrawal(
  prices_message: ByteArray,
  signatures: List<ByteArray>,
  token_map: TokenMap,
  mpf_action: SharesMPFAction,
  operator_mpf_action: Option<SharesMPFAction>,
)
```

- `operator_mpf_action` is `Some(action)` when `fee_shares > 0` (non-operator withdrawal with profit)
- `operator_mpf_action` is `None` when `fee_shares == 0` (operator withdrawal or no profit)
