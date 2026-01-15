# Specification - EmergencyRequest - Withdrawal - Spend

## Parameter

- `oracle_nft`: The policy id of `OracleNFT`

## Datum

- `account`: `UserAccount` - the account information with withdrawal and trade key credentials
- `amount`: `MValue` - marking the account balance
- `timestamp`: `Int` the timestamp at which the app withdrawal request occurred

## User Action

1. Process emergency withdraw

   - Get the own input and the input value is clean
   - The emergency token in own input is burnt
   - Authorized by account owner of emergency action

2. Spam prevention withdraw

   - Current input does not contain auth token
   - Sign by operation key referencing by oracle utxo

3. Expired withdraw

   - The auth token is burnt
   - Either signed by app owner or the account
   - `tx.interval_start > datum.timestamp + 172800`
