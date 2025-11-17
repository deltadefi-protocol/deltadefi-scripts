# Specification - HydraOrderBook - PlaceOrder

## Parameter

- `dex_oracle_nft`: The policy id of the token attached with `DexOrderBook`

## User Action

1. Process place order

   - Categorize inputs into
     - `AI` - Account Input with `account` at intent
     - `II` - Intent Inputs
     - Fail if other
   - Categorize outputs into
     - `AO` - Account Output with `account` at intent
     - `OO` - Order Output with `account` at intent
     - Fail if other
   - `II` with `PlaceOrderIntent` datum
   - `OO` with exactly datum `II`
   - `OO` has at least value
     - `is_long` == True -> short qty of short token
     - `is_long` == False -> `order_size` of long token
   - The input token is burnt
   - Signed by `operating_key`
