# Specification - AccountOperation - HydraHeadOpen

## Parameter

- `oracle_nft`: The policy id of `OracleNFT`

## User Action

1. Validate split of merkle tree

   - Find the `DexAccountBalance` input and output, locate the merkle root
   - Obtain the `HydraAccountBalance` outputs with auth token and value
   - Validate the merkle root is updated correctly, the deducted amount for each equal to `HydraToken` with token name of hash of unit (which is minted in current tx)
     - Split entire trie: New root is empty and the new balances minted equals to full trie
     - Split partial trie: Delete one by one and the updated root is tied.
   - Balance value is minted
   - Signed by operation key
