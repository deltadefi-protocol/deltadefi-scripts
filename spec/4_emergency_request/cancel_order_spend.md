# Specification - EmergencyRequest - Cancel Order - Spend

## Parameter

- `oracle_nft`: The policy id of `OracleNFT`

## Datum

- `account`: `UserAccount` - the account information with withdrawal and trade key credentials
- `order_id`: `ByteArray` - order id
- `timestamp`: `Int` the timestamp at which the app withdrawal request occurred

## User Action

1. Transferal of account balance

   - Obtain the `DexOrderBook - emergency_cancel_order` script hash from oracle
   - Check if `DexOrderBook - emergency_cancel_order` withdrawal script is run

2. Spam prevention withdraw

   - Current input does not contain auth token
   - Sign by operation key referencing by oracle utxo

3. Expired withdraw

   - The auth token is burnt
   - Either signed by app owner or the account
   - `tx.interval_start > datum.timestamp + 172800`
