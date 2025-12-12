# Specification - DexAccountBalanace

## Parameter

- `oracle_nft`: The policy id of `OracleNFT`
- `dex_order_book_nft`: The policy id of `OracleNFT` locked in `DexOrderBook`

## Datum

- `account_merkle_root`: storing the root of merkle tree in `ByteArray`, with all balance info

### `account_merkle_root` Merkle Tree

- Key: `account`: serialized cbor of the account information with withdrawal and trade key credentials
- Value: serialized cbor of `Value` type

## User Action

1. App Deposit

   - Obtain the `AccountOperationAuth - app_deposit` script hash from oracle
   - Check if `AccountOperationAuth - app_deposit` withdrawal script is run

2. App Withdrawal

   - Obtain the `AccountOperationAuth - app_withdrawal` script hash from oracle
   - Check if `AccountOperationAuth - app_withdrawal` withdrawal script is run

3. HydraWithdrawal

   - Obtain the `AccountOperationAuth - hydra_withdrawal` script hash from dex order book (also an oracle within Hydra)
   - Check if `AccountOperationAuth - hydra_withdrawal` withdrawal script is run

4. HydraCancelWithdrawal

   - Obtain the `AccountOperationAuth - hydra_cancel_withdrawal` script hash from dex order book (also an oracle within Hydra)
   - Check if `AccountOperationAuth - hydra_cancel_withdrawal` withdrawal script is run

5. Transferal of account balance

   - Obtain the `AccountOperationAuth - hydra_internal_transfer` script hash from dex order book (also an oracle within Hydra)
   - Check if `AccountOperationAuth - hydra_internal_transfer` withdrawal script is run

6. TODO - Get into hydra

7. Splitting merkle tree

   - Obtain the `AccountOperationAuth - hydra_head_open` script hash from dex order book (also an oracle within Hydra)
   - Check if `AccountOperationAuth - hydra_head_open` withdrawal script is run

8. Combining merkle tree

   - Obtain the `AccountOperationAuth - hydra_head_close` script hash from dex order book (also an oracle within Hydra)
   - Check if `AccountOperationAuth - hydra_head_close` withdrawal script is run

9. Spam prevention withdraw

   - Current input does not contain auth token
   - Sign by operation key referencing by oracle utxo

10. Remove registry

    - Operation key is signed
    - Obtain the only `DexAccountBalance` input and its merkle tree account value
    - Merkle root is empty
    - Check if the token with `DexAccountBalance` is burnt
