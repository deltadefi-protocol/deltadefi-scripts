# Specification - AppDepositRequest

## Parameter

- `oracle_nft`: The policy id of `OracleNFT`

## Datum

- `account`: the account information with withdrawal and trade key credentials
- `amount`: `MValue` - marking the account balance

## User Action

1. Transferal of account balance

   - Obtain the `AccountOperationAuth - app_deposit` script hash from oracle
   - Check if `AccountOperationAuth - app_deposit` withdrawal script is run

2. Emergency Withdraw

   - Obtain the only `AppWithdrawalRequest` input and its account value
   - The account in current datum equals to `AppWithdrawalRequest` datum's
   - The `emergency_withdrawal_request_token` is burnt
   - The `app_deposit_token` is burnt
   - Check that redeemer matches the `AppWithdrawalRequest` input datum(`AppWithdrawalRequest.account` signed && `tx.interval_start > AppWithdrawalRequest.timestamp + 86400`)

3. Spam prevention withdraw

   - Current input does not contain auth token
   - Sign by operation key referencing by oracle utxo
