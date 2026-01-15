# Specification - HydraOrderBook - SplitOrderMerkle

## Redeemer

- SplitOrderMerkle { tree_or_proofs_with_token_map }

## User Action

1. Validate spliting merkle tree into order utxos

   - For every single entry in merkle tree, split it into 1 distinct order utxo at `HydraOrderBook` with `HydraOrderBook` auth token
   - Updated merkle output with 1 auth token and empty merkle tree
   - Mint all `HydraTokens` needed in the hydra order outputs
