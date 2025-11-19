# Specification - HydraOrderBook

## Parameter

- `dex_oracle_nft`: The policy id of the token attached with `DexOrderBook`

## Datum - LimitOrder

- `order_id`: The order id without hyphens
- `long_token`: The long token unit
- `short_token`: The short token unit
- `is_long`: Long or short
- `list_price_times_1bil`: Price \* 1,000,000,000
- `order_size`: The amount of long token trading
- `fee_amount_bp`: The basis point of fee to be charged
- `account`: The account information of current order owner

## User Action

1. Filling order

   - `fill_order` withdrawal script is run

2. Cancel order

   - `cancel_order` withdrawal script is run

3. Modify Order - Redeemer `red_account`: `UserAccount`

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
   - `II` with `red_account` as account
   - `OO` with exactly datum `II`
   - `OI` & `OO` has same `order_id`
   - `OO` has at least value
     - `is_long` == True -> at least short qty of short token
     - `is_long` == False -> at least `order_size` of long token
   - The input intent token is burnt
   - Value parity: `AI` + `OI` == `AO` + `OO` (to clear: is the check needed?)
   - Signed by `operating_key`

4. Combining orders to merkle tree

   - `DexOrderBook` - `combine_merkle` withdrawal script is run
