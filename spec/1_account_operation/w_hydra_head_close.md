# Specification - AccountOperation - HydraHeadClose

## Parameter

- `oracle_nft`: The policy id of `OracleNFT`

## User Action

1. Validate combine of merkle tree

   - For every single account input from `HydraAccountBalance`
     - Convert into L1 Value and combine it into merkle tree
     - Consolidate the total `HydraToken` value
   - All `HydraTokens` are burnt
   - Only one input from `DexAccountBalance`
   - Only one output to `DexAccountBalance` with updated merkle output
