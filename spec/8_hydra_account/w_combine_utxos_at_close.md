# Specification - HydraAccount - CombineUtxosAtClose

## Redeemer

- ProcessCombineUtxosAtClose { tree_or_proofs_with_token_map: TreeOrProofsWithTokenMap }

## User Action

- For every single account input from `HydraAccount`
  - Convert into L1 Value and combine it into merkle tree
  - Consolidate the total `HydraToken` value
- All `HydraTokens` are burnt
- Only one input from `DexAccountBalance`
- Only one output to `DexAccountBalance` with updated merkle output
