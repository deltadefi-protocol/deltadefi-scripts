# Specification - HydraAccount - Vault Deposit

Supports both initial deposit (when `total_shares == 0`) and regular deposits.

## User Action

- Ref input with `dex_oracle_nft`
- Get `II` - Intent Input from burn event (negative mint quantity)
- `II` with `VaultDepositIntentDatumL2` datum
  - `vault_oracle_nft`, `depositor: UserAccount`, `deposit_amount: MValue`
- Get Vault Oracle input/output (UTxO with `vault_oracle_nft`)
- Validate intent script matches vault config (`intent_policy_id == l2_deposit_intent_script_hash`)
- Check if initial deposit: `is_initial_deposit = input_total_shares == 0`
- Verify prices message with hydra node signatures
- Calculate shares:
  - **Initial deposit**: `shares_minted = deposit_usd_value` (share price = 1.0)
  - **Regular deposit**: `shares_minted = (deposit_usd_value * total_shares) / vault_equity` (round DOWN)
- Categorize inputs into
  - `DI` - Depositor Inputs (by full `UserAccount`)
  - `VI` - Vault Inputs (by `master_key == Script(vault_script_hash)`)
  - Other inputs
- Categorize outputs into
  - `DO` - Depositor Outputs (by full `UserAccount`)
  - `VO` - Vault Outputs (by `master_key == Script(vault_script_hash)`)
  - Other outputs
- No other inputs/outputs at `hydra_account_script_hash`
- The 3 values are equal (all in L2 format):
  1. Deduct in value for depositor (`DI` - `DO`) without lovelace
  2. Increase in value for vault (`VO` - `VI`) without lovelace
  3. Value in deposit intent (`deposit_amount`)
- Verify Merkle transition (SharesInsert or SharesUpdate)
  - Key: `cbor.serialise(depositor)` (shares always go to depositor)
  - Value: `SharesRecordEntry { shares, total_deposited }`
- Vault Oracle output datum updated:
  - `total_shares += shares_minted`
  - `operator_shares += shares_minted` (only if `depositor == operator_account`)
  - `total_deposited += deposit_usd_value`
  - `shares_merkle_root = computed_new_root`
- The intent token is burnt
- Signed by `operation_key`

## Initial Deposit Notes

- Anyone can perform the initial deposit (no depositor restriction)
- Shares are minted for the depositor (same as regular deposit)
- Share price is 1.0 (shares = USD value deposited)

## Edge Case: Operator == Depositor

If the operator deposits (after previously receiving fee shares from withdrawals):

- Existing entry might be: `{ shares: fee_shares, total_deposited: 0 }` (fees don't add to deposited)
- After deposit: `{ shares: fee_shares + new_shares, total_deposited: 0 + deposit_usd_value }`

This is handled correctly by `SharesUpdate` which adds to both `shares` and `total_deposited`.

## L2 Asset Units

- **Intent datum** contains `deposit_amount` in **L2 format**: `MValue = Pairs<hydra_token_policy_id, Pairs<hashed_asset_name, Int>>`
- **Account UTxOs** contain values in **L2 format**: `(hydra_token_policy_id, hash_token(policy_id, asset_name), qty)`
- **Price message** contains prices in **L1 format**: `Pairs<(PolicyId, AssetName), (Int, Int)>` where tuple is `(price, scale)`
- **Token map** (`TokenMap`) maps L2 asset hash → L1 asset identity for price lookup
- Validator converts L2 deposit amount to L1 using `from_hydra_balance_to_value(l2_value, hydra_token_policy_id, token_map)` for USD calculation
- **USD calculation**: `usd_value = Σ(amount * price / 10^scale)` for each asset

## Price Format

Each asset's price entry is a tuple `(price, scale)` where:

- `price`: Integer price value
- `scale`: Exponent for power of 10 divisor (10^scale)

| Token | Real Price | price | scale | Example Calculation                          |
| ----- | ---------- | ----- | ----- | -------------------------------------------- |
| USDC  | $1.00      | 1     | 0     | `1000000 * 1 / 10^0 = 1000000` (1 USD)       |
| ADA   | $0.50      | 5     | 1     | `1000000 * 5 / 10^1 = 500000` (0.50 USD)     |
| BTC   | $50,000    | 50000 | 0     | `100000000 * 50000 / 10^0 = 5000000000000`   |

This allows each token to have its own scale factor (as power of 10) to prevent integer overflow in the backend while maintaining integer-only arithmetic on-chain.

## Redeemer

```
ProcessVaultDeposit(
  prices_message: ByteArray,
  signatures: List<ByteArray>,
  token_map: TokenMap,
  mpf_action: SharesMPFAction,
)
```
