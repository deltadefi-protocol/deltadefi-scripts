# Specification - HydraOrderBook

## Spend

### Parameter

- `dex_oracle_nft`: The policy id of the token attached with `DexOrderBook`

### Datum - LimitOrder

- `order_id`: The order id without hyphens
- `long_token`: The long token unit
- `short_token`: The short token unit
- `is_long`: Long or short
- `list_price_times_1bil`: Price \* 1,000,000,000
- `size`: The amount of long token trading
- `fee_amount_bp`: The basis point of fee to be charged
- `account`: The account information of current order owner

### User Action

1. Filling order

   - Redeemers contain withdrawal script validation with same `fill_order` redeemer

2. Cancel order

   - Redeemers contain withdrawal script validation with same `cancel_order` redeemer

3. Modify Order - Redeemer `red_account`: `UserAccount`

   - Redeemers contain withdrawal script validation with same `modify_order` redeemer

4. Combining orders to merkle tree

   - `DexOrderBook` - `combine_merkle` withdrawal script is run
