# Specification - AccountOperation - AppWithdrawal

## Parameter

- `oracle_nft`: The policy id of `OracleNFT`

## Redeemer type

```rs
pub type ProcessAppWithdrawal {
  account: Account,
  amount: MValue,
  mpf_action: MPFProof
}
```

## User Action

1. Validate change in account balance
   - Operation key is signed OR
     - Obtain the only `AppWithdrawalRequest` input and its account value
     - The `emergency_withdrawal_request_token` is burnt
     - Check that redeemer matches the `AppWithdrawalRequest` input datum(`AppWithdrawalRequest.account` signed && `tx.interval_start > AppWithdrawalRequest.timestamp + 86400`)
   - Obtain the only `DexAccountBalance` input and its merkle tree account value
   - Obtain the only `DexAccountBalance` output and its merkle tree account value
   - Check if the withdrawal is processed correctly with the merkle tree
   - Obtain the input and output value to `AppVault`, check the value deducted equal to withdrawal amount
   - Check the withdrawal amounut minus 1 ADA is correctly sent to an address equal
