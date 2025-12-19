# Specification - HydraOrderBook

## Spend

### Parameter

- `dex_oracle_nft`: The policy id of the token attached with `DexOrderBook`

### Datum - LimitOrder

- `order_id`: The order id without hyphens
- `base_token`: The base token unit
- `quote_token`: The quote token unit
- `is_buy`: if it is a buy order
- `list_price_times_1tri`: Price \* 1,000,000,000
- `size`: The amount of token trading - if `is_buy` it represents quote token, if `!is_buy` it represents base token
- `fee_amount_bp`: The basis point of fee to be charged
- `account`: The account information of current order owner
- `order_type`: Limit order or market order

### User Action

1. Filling order

   - Redeemers contain withdrawal script validation with same `fill_order` redeemer

2. Cancel order

   - Redeemers contain withdrawal script validation with same `cancel_order` redeemer

3. Modify Order - Redeemer `account`: `UserAccount`

   - Redeemers contain withdrawal script validation with same `modify_order` redeemer

4. Combining orders to merkle tree

   - `DexOrderBook` - `combine_merkle` withdrawal script is run
