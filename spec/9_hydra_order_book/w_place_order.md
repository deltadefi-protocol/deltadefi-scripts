# Specification - HydraOrderBook - PlaceOrder

## Parameter

- `dex_oracle_nft`: The policy id of the token attached with `DexOrderBook`

## User Action

1. Process place order

   - Input from `HydraUserIntent` with `PlaceOrderIntent` datum
   - Deduct the account balance from `HydraAccountBalance` with corresponding auth token
   - Exactly 1 output to `HydraOrderBook`, with exactly the same datum as input from current address (i.e. `HydraOrderBookDatum`)
   - `HydraOrderBook` auth token minted with token name of `order_id`
   - The input token is burnt
   - Signed by `operating_key`
