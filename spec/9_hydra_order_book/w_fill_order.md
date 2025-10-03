# Specification - HydraOrderBook - FillOrder

## Parameter

- `dex_oracle_nft`: The policy id of the token attached with `DexOrderBook`

## User Action

1. Process fill order - Redeemer - `FillOrderRedeemer { filler_account: UserAccount }`

   - Burn all fully filled `HydraOrderBook` tokens
   - Accumulate proceeds from all filled orders, to get a payoff map, including that to fee account
     - Obtain a map of to owe value by looking at order input (payoff - fee)
     - extra value add to payoff to order placer
   - Process current filler order, adding to payoff
     - use filled order order va
     - There is no negative payoff
   - Accumulate proceeds to order placers, update all account balance accordingly
     - Obtain a map of original order value
     - Update the map by duducting the to owe value by looking at order output
   - The remaining order values go into current filler_account
   - Signed by `operating_key`
