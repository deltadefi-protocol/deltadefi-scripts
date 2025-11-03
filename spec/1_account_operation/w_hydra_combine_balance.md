# Specification - AccountOperation - HydraCombineBalance

## Parameter

- `oracle_nft`: The policy id of `OracleNFT`

## User Action

1. Validate split of merkle tree

   - Obtain the `HydraAccountBalance` inputs with auth token and value
   - Obtain the `HydraAccountBalance` output with auth token and value
   - For all the `HydraAccountBalance` inputs, check
     - Whether they come from same account
     - obtain the combined balance
   - The output balance equals the updated balance
   - Signed by `operation_key`
