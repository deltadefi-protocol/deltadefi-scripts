# Specification - HydraOrderBook - CancelOrder

## Parameter

- `dex_oracle_nft`: The policy id of the token attached with `DexOrderBook`

## User Action

1. Process cancel order

   - Input from `HydraUserIntent` with `CancelOrder {account, order_id}` datum
   - Add the account balance from `HydraAccountBalance` with corresponding auth token
   - Exactly 1 input from `HydraOrderBook`, with auth token name of `order_id`
   - The datum of `HydraOrderBook` input contains same account as `HydraUserIntent`
   - `HydraOrderBook` auth token burnt with token name of `order_id`
   - The input token is burnt
   - Signed by `operating_key`
