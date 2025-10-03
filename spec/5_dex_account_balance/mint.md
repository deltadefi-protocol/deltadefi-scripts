# DexAccountBalance Token

## Parameter

- `oracle_nft`: The policy id of `OracleNFT`

## User Action

1. Mint - Redeemer `RMint`

   - Only a single token of current policy id minted
   - No input with current policy id token
   - Only a single output to `DexAccountBalance` address with empty merkle root datum
   - Signed by operation key

2. Burn - Redeemer `RBurn`

   - The current policy id only has negative minting value in transaction body.
