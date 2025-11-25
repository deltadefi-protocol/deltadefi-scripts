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

## Note

In cancel order we removed the need for user authorization. This design due to in DeltaDeFi it is a known trade-off that the order flow will be controlled offchain. Given we can prevent users from filling orders offchain, it did not introduce extra trade-off for user controls when cancel order does not require user auth.
