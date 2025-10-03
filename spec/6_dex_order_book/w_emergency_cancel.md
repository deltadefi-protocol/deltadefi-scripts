# Specification - AccountOperation - AppWithdrawal

## Parameter

- `oracle_nft`: The policy id of `OracleNFT`
- `dex_oracle_nft`: The policy id of the token attached with `DexOrderBook`

## Redeemer type

```rs
pub type EmergencyCancelRequestRedeemer {
    account: UserAccount,
    order_id: ByteArray,
    proof: MPFProof,
}
```

## User Action

1. Validate change in account balance

   - Operation key is signed OR
     - Obtain the only `DexOrderBookCancelRequest` input and its account value
     - Check that redeemer matches the `DexOrderBookCancelRequest` input datum
       - The `emergency_withdrawal_request_token` is burnt
     - (`DexOrderBookCancelRequest.account` signed && `tx.interval_start > DexOrderBookCancelRequest.timestamp + 86400`)
   - Obtain the only `DexOrderBook` input and its merkle tree account value
   - Obtain the only `DexOrderBook` output and its merkle tree account value
   - Check if the withdrawal is processed correctly with the merkle tree
   - Obtain the input and output value to `AppVault`, check the value deducted equal to withdrawal amount
   - Check the withdrawal amounut is correct sent to an address equal
