# Specification - HydraAccount - SplitUtxosAtOpen

## User Action

- Find the `DexAccountBalance` input and output, locate the merkle root
- Obtain the `HydraAccount` outputs value in correct account as stated in datum
- Validate the merkle root is updated correctly, the deducted amount for each equal to `HydraToken` with token name of hash of unit (which is minted in current tx)
  - Split entire trie: New root is empty and the new balances minted equals to full trie
  - Split partial trie: Delete one by one and the updated root is tied.
- Balance value is minted
- Signed by operation key
