# Specification - DexOrderBook - SplitOrderMerkle

## Parameter

- `dex_oracle_nft`: The policy id of the token attached with `DexOrderBook`

## User Action

1. Validate spliting merkle tree into order utxos

   - For every single entry in merkle tree, split it into 1 distinct order utxo at `HydraOrderBook` with `HydraOrderBook` auth token
   - Updated merkle output with 1 auth token and empty merkle tree
