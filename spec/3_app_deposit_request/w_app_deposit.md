# Specification - AccountOperation - AppDeposit

## Parameter

- `oracle_nft`: The policy id of `OracleNFT`

## Redeemer type

```rs
pub type ProcessAppDeposit {
  account: UserAccount,
  amount: MValue,
  mpf_action: MPFProof,
}
```

## User Action

1. Validate change in account balance

   - Operation key is signed
   - Obtain the only `AppDepositRequest` input and its account value
   - Obtain the only `DexAccountBalance` input and its merkle tree account value
   - Obtain the only `DexAccountBalance` output and its merkle tree account value
   - Check if the deposit is processed correctly with the merkle tree
   - Check if the token with `AppDepositRequest` is burnt, and the deposit value is sent to vault
