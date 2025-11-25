# Specification - HydraOrderBook - CancelOrder

## Redeemer

- CancelOrder { account: UserAccount }

## User Action

- Ref input with `dex_oracle_nft`
- Categorize inputs into
  - `OI` - Order Inputs
  - Other inputs
- Categorize outputs into
  - `AO` - Account Outputs
  - Other outputs
- No other inputs and outputs
- For all `OI`, check
  - Return `account_payoff` - `AccountPayoff`
  - Cummulate order value to the `account_payoff`
- For all `account_payoff` - `<account, value>`
  - Check output value to `account` equals `value`
- Signed by `operating_key`
