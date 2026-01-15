# Specification - HydraAccount - SameAccountTransferal

## Redeemer

- ProcessSameAccountTransferal { account: UserAccount }

## User Action

- Ref input with `oracle_nft`
- Categorize inputs into
  - `AI` - Account Inputs at `account`
  - Other inputs
- Categorize outputs into
  - `AO` - Account Outputs at `account`
  - Other outputs
- No other inputs
- No other outputs
- `AI` and `AO` value are equal
- Signed by `operating_key`
