# Specification - AccountOperation - HydraHeadOpen

## Parameter

- `oracle_nft`: The policy id of `OracleNFT`

## User Action

1. Validate split of merkle tree

   - Combine account balance for every single entry in `DexAccountBalance` merkle tree & `DexAccountBalance`, with key of key hash (pub key hash or script hash)
   - For the combined balance, split it into 1 distinct hydra account utxo per account at `HydraAccountBalance` with `HydraAccountBalance` auth token
   - Updated merkle output at `DexAccountBalance` with 1 auth token and empty merkle tree
   - Updated merkle output at `DexAccountBalance` with 1 auth token and empty merkle tree
