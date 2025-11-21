# Specification - HydraOrderBook - CancelOrder

## Redeemer

- CancelOrder

## User Action

- Ref input with `dex_oracle_nft`
- Categorize inputs into
  - `II` - Intent Input
  - `OI` - Order Inputs
  - Other inputs
- `II` with `CancelOrder {account, order_ids}` datum
- Categorize outputs into
  - `AO` - Account Output with `account` at intent
  - Other outputs
- No other inputs and outputs
- For all `OI`, check
  - `order_id` is included in `order_ids`
  - `account` == `account` at intent
- The input intent token is burnt
- Value parity: `OI` == `AO` (to clear: is the check needed?)
- Signed by `operating_key`
