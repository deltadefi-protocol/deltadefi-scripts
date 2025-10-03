# AppDepositRequest Token

## Parameter

- `oracle_nft`: The policy id of `OracleNFT`

## User Action

1. Mint - Redeemer `RMint`

   - The net deposit value sent to `AppDepositRequest` address is equal to the datum value of `AppDepositRequest`

2. Burn - Redeemer `RBurn`

   - The current policy id only has negative minting value in transaction body.
