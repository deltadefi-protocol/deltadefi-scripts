# Specification - HydraOrderBook - Modify Order

## Redeemer

- ModifyOrder { red_account: UserAccount }

## Logic

- Redeemers contain withdrawal script validation with same `modify_order` redeemer
- Ref input with `dex_oracle_nft`
- Categorize inputs into
  - `II` - Intent Input
  - `AI` - Account Inputs
  - `OI` - Order Input
  - Other inputs
- Categorize outputs into
  - `AO` - Account Output with `account` at intent
  - `OO` - Order Output with `account` at intent
  - Other outputs
- No other inputs and outputs
- `II` with `ModifyOrderIntent` datum
- `II` with `account` as account
- `OO` with exactly datum `II`
- `OI` & `OO` has same `order_id`
- `OO` has at least value
  - `is_long` == True -> at least short qty of short token
  - `is_long` == False -> at least `order_size` of long token
- The input intent token is burnt
- Value parity: `AI` + `OI` == `AO` + `OO` (to clear: is the check needed?)
- Signed by `operating_key`
