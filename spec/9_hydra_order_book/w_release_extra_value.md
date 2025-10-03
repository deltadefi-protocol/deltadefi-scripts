# Specification - HydraOrderBook - ReleaseExtraValue

## Parameter

- `dex_oracle_nft`: The policy id of the token attached with `DexOrderBook`

## User Action

1. Release extra value

   - Only 1 input and output from and to `HydraOrderBook`
   - The updated datum to `HydraOrderBook` has nothing different apart from `extra_value` set to 0
   - Add the account balance with `extra_value` from `HydraAccountBalance` with corresponding auth token
   - Signed by `operation_key`
