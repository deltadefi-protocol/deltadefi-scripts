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
- Other inputs length == 1 (the intent input)
- No other outputs
- The 3 value are equal:
  1. Deduct in value for `from` (`AI_from` - `AO_from`)
  2. Increase in value for `to` (`AO_to` - `AI_to`)
  3. Value in transferal intent
- The intent token is burnt
- Signed by `operating_key`
