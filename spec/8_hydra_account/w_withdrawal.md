# Specification - DexAccountBalance - HydraWithdrawal

## User Action

- Ref input with `oracle_nft`
- Get `II` - Intent Input
- `II` with `WithdrawalIntent` datum
- Categorize inputs into
  - `AI` - Account Inputs with `from` account at intent
  - `DI` - Dex Account Balance Input
  - Other inputs
- Categorize outputs into
  - `AO` - Account Outputs with `from` account at intent
  - `DO` - Dex Account Balance Output
  - Other outputs- Other inputs length == 1 (the intent input)
- No other inputs
- No other outputs
- `DO` with updated merkle root (with translated L1 value)
- The `HydraToken` deducted is burnt
- Intent value is burnt
- The 3 value are equal:
  1. Deduct in value for `account` (`AI` - `AO`)
  2. Increase in value for in root (change in root in `DO`) -> translate into hydra balance
  3. Value in withdrawal intent -> translate into hydra balance
- Signed by `operating_key`
