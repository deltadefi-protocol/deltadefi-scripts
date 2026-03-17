# Specification - HydraAccount - Vault Deposit

## User Action

- Ref input with `dex_oracle_nft`
- Get `II` - Intent Input from burn event (negative mint quantity)
- `II` with `VaultDepositIntentDatumL2` datum
  - `vault_oracle_nft`, `depositor: UserAccount`, `deposit_amount: MValue`
- Get Vault Oracle input/output (UTxO with `vault_oracle_nft`)
- Validate intent script matches vault config (`intent_policy_id == l2_deposit_intent_script_hash`)
- Verify prices message with hydra node signatures
- Calculate shares: `shares_minted = (deposit_usd_value * total_shares) / vault_equity` (round DOWN)
- Categorize inputs into
  - `DI` - Depositor Inputs (by full `UserAccount`)
  - `VI` - Vault Inputs (by `master_key == Script(l2_deposit_intent_script_hash)`)
  - Other inputs
- Categorize outputs into
  - `DO` - Depositor Outputs (by full `UserAccount`)
  - `VO` - Vault Outputs (by `master_key == Script(l2_deposit_intent_script_hash)`)
  - Other outputs
- No other inputs/outputs at `hydra_account_script_hash`
- The 3 values are equal:
  1. Deduct in value for depositor (`DI` - `DO`) without lovelace
  2. Increase in value for vault (`VO` - `VI`) without lovelace
  3. Value in deposit intent (`deposit_amount`)
- Verify Merkle transition (SharesInsert or SharesUpdate)
  - Key: `cbor.serialise(depositor)` (UserAccount)
  - Value: `SharesRecordEntry { shares, total_deposited }`
- Vault Oracle output datum updated:
  - `total_shares += shares_minted`
  - `total_deposited += deposit_usd_value`
  - `shares_merkle_root = computed_new_root`
- The intent token is burnt
- Signed by `operation_key`
