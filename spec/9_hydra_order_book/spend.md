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
- `extra_value`: Integer of extra value locked for orders (for market orders): if (is_long) then `short_token`
- `account`: The account information of current order owner

## User Action

1. Filling order

   - `fill_order` withdrawal script is run

2. Cancel order

   - `cancel_order` withdrawal script is run

3. Release order extra value

   - `release_extra_value` withdrawal script is run

4. Combining orders to merkle tree

   - `DexOrderBook` - `combine_merkle` withdrawal script is run
