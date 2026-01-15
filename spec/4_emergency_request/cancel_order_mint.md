# Specification - EmergencyRequest - Cancel Order - Mint

## Parameter

- `oracle_nft`: The policy id of `OracleNFT`

## User Action

1. Mint - Redeemer `RMint`

   - Only a single token of current policy id minted
   - Only a single output to `DexOrderBookCancelRequest` address with datum

   ```rs
   pub type EmergencyCancelRequestDatum {
      account: UserAccount,
      order_id: ByteArray,
      timestamp: Int,
   }
   ```

   - `tx_interval_start > datum.timestamp`

2. Burn - Redeemer `RBurn`

   - The current policy id only has negative minting value in transaction body.
