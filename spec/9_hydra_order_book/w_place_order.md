# Specification - HydraOrderBook - PlaceOrder

## Parameter

- `dex_oracle_nft`: The policy id of the token attached with `DexOrderBook`

## User Action

1. Process place order - Redeemer `red_account`: `UserAccount`

   - Ref input with `dex_oracle_nft`
   - Categorize inputs into
     - `AI` - Account Inputs with `red_account` at intent
     - `II` - Intent Input
     - Other inputs
   - Categorize outputs into
     - `AO` - Account Output with `red_account` at intent
     - `OO` - Order Output with `red_account` at intent
     - Other outputs
   - No other inputs and outputs
   - `II` with `PlaceOrderIntent` datum
   - `II` with `red_account` as account
   - `OO` with exactly datum `II`
   - `OO` has at least value
     - `is_long` == True -> at least short qty of short token
     - `is_long` == False -> at least `order_size` of long token
   - The input intent token is burnt
   - Value parity: `AI` == `AO` + `OO` (to clear: is the check needed?)
   - Signed by `operating_key`
