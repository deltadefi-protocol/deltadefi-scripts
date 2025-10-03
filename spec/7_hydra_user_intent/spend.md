# Specification - HydraUserIntent

## Parameter

- `dex_oracle_nft`: The policy id of the token attached with `DexOrderBook`

## Datum - Either

- Same as `HydraOrderBook`'s `LimitOrder` with an extra field of `order_id` (For reference - UUID without `-`)
- `WithdrawalIntent { amount: MValue }`
- `CancelIntent { account: Account, orderId: string }`

## User Action

1. Process Intent

   - `HydraUserIntent` token in own input is burnt
