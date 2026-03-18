# Specification - HydraAccount - Transfer

## User Action

- Ref input with `oracle_nft`
- Get `II` - Intent Input
- `II` with `TransferIntent` datum
- Categorize inputs into
  - `AI_from` - Account Inputs with `from` account at intent
  - `AI_to` - Account Inputs with `to` account at intent
  - Other inputs
- Categorize outputs into
  - `AO_from` - Account Outputs with `from` account at intent
  - `AO_to` - Account Outputs with `to` account at intent
  - Other outputs
- No other inputs/outputs at `hydra_account_script_hash` (only `from` and `to` account UTxOs allowed)
- The 3 value are equal (all in L2 format):
  1. Deduct in value for `from` (`AI_from` - `AO_from`)
  2. Increase in value for `to` (`AO_to` - `AI_to`)
  3. Value in transferal intent
- The intent token is burnt
- Signed by `operating_key`

## L2 Asset Units

- **Intent datum** contains `transfer_amount` in **L2 format**: `(hydra_token_policy_id, hashed_asset_name, qty)`
- **Account UTxOs** contain values in **L2 format**: `(hydra_token_policy_id, hash_token(policy_id, asset_name), qty)`
- All comparisons are done directly in L2 format (no conversion needed)
