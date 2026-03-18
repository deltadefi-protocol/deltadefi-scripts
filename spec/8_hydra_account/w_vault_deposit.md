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
  - `VI` - Vault Inputs (by `master_key == Script(l2_deposit_intent_script_hash)`)
  - Other inputs
- Categorize outputs into
  - `DO` - Depositor Outputs (by full `UserAccount`)
  - `VO` - Vault Outputs (by `master_key == Script(l2_deposit_intent_script_hash)`)
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
  - `total_deposited += deposit_usd_value`
  - `shares_merkle_root = computed_new_root`
- The intent token is burnt
- Signed by `operation_key`

## Initial Deposit Notes

- Anyone can perform the initial deposit (no depositor restriction)
- Shares are minted for the depositor (same as regular deposit)
- Share price is 1.0 (shares = USD value deposited)

## L2 Asset Units

- **Intent datum** contains `deposit_amount` in **L2 format**: `MValue = Pairs<hydra_token_policy_id, Pairs<hashed_asset_name, Int>>`
- **Account UTxOs** contain values in **L2 format**: `(hydra_token_policy_id, hash_token(policy_id, asset_name), qty)`
- **Price message** contains prices in **L1 format**: `Pairs<(PolicyId, AssetName), Int>`
- **Token map** (`TokenMap`) maps L2 asset hash → L1 asset identity for price lookup
- Validator converts L2 deposit amount to L1 using `from_hydra_balance_to_value(l2_value, hydra_token_policy_id, token_map)` for USD calculation

## Redeemer

```
ProcessVaultDeposit(
  prices_message: ByteArray,
  signatures: List<ByteArray>,
  token_map: TokenMap,
  mpf_action: SharesMPFAction,
)
```
