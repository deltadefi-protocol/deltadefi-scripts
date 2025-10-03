# Specification - AccountOperation - HydraHeadClose

## Parameter

- `oracle_nft`: The policy id of `OracleNFT`

## User Action

1. Validate combine of merkle tree

   - For every single account input from `HydraAccountBalance` combine it into merkle tree
   - All floating `HydraAccountBalance` auth tokens are burnt
   - Only one input from `DexAccountBalance`
   - Only one output to `DexAccountBalance` with updated merkle output
