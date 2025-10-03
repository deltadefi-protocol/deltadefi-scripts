# Specification - DexOrderBook - CombineOrderMerkle

## Parameter

- `dex_oracle_nft`: The policy id of the token attached with `DexOrderBook`

## User Action

1. Validate combining merkle tree into order utxos

   - For every single order input from `HydraOrderBook` combine it into merkle tree
   - All floating `HydraOrderBook` auth tokens are burnt
   - Only one input from `DexOrderBook`
   - Only one output to `DexOrderBook` with updated merkle output
