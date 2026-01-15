# Specification - HydraOrderBook - CombineOrderMerkle

## Redeemer

- CombineOrderMerkle { tree_or_proofs_with_token_map }

## User Action

1. Validate combining merkle tree into order utxos

   - For every single order input from `HydraOrderBook` combine it into merkle tree
   - All `HydraTokens` locked in orders are burnt
   - Only one input from `DexOrderBook`
   - Only one output to `DexOrderBook` with updated merkle output
