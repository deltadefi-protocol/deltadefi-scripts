# Specification - HydraOrderBook - CombineOrderMerkle

## Parameter

- `dex_oracle_nft`: The policy id of the token attached with `DexOrderBook`

## User Action

1. Validate combining merkle tree into order utxos

   - Only one input from `DexOrderBook`
   - For every single order input from `HydraOrderBook` combine it into merkle tree
   - Only one output to `DexOrderBook` with updated merkle output
   - All `HydraTokens` locked in orders are burnt
