# Specification - HydraAccount - CancelWithdrawal

## User Action

- Ref input with `oracle_nft`
- Get `II` - Intent Input
- `II` with `CancelWithdrawalIntent` datum
- Categorize inputs into
  - `AI` - Account Inputs with `from` account at intent
  - `DI` - Dex Account Balance Input
  - Other inputs
- Categorize outputs into
  - `AO` - Account Outputs with `from` account at intent
  - `DO` - Dex Account Balance Output
  - Other outputs
- Other inputs length == 1 (the intent input)
- No other outputs
- `DO` with updated merkle root (with translated L1 value)
- The `HydraToken` added is minted
- Intent value is burnt
- The 3 value are equal:
  1. Increase in value for `account` (`AO` - `AI`)
  2. Deduct in value for in root (change in root in `DO`) -> translate into hydra balance
  3. Value in cancel withdrawal intent -> translate into hydra balance
- Signed by `operating_key`
