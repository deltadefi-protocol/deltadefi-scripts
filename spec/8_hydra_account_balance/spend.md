# Specification - HydraAccountBalance

## Parameter

- `dex_oracle_nft`: The policy id of the token attached with `DexOrderBook`

## Datum

- Key: `account`: the account information with withdrawal and trade key credentials
- `balance`: `MValue` - marking the account balance

## User Action

1. Update balance with user intent - place order

   - Obtain the `HydraOrderBook - hydra_place_order` script hash from dex order book (also an oracle)
   - Check if `HydraOrderBook - hydra_place_order` withdrawal script is run

2. Update balance with fill order

   - Obtain the `HydraOrderBook - hydra_fill_order` script hash from dex order book (also an oracle)
   - Check if `HydraOrderBook - hydra_fill_order` withdrawal script is run

3. Update balanace with cancel order

   - Obtain the `HydraOrderBook - hydra_cancel_order` script hash from dex order book (also an oracle)
   - Check if `HydraOrderBook - hydra_cancel_order` withdrawal script is run

4. Update balance with user intent - withdrawal

   - Obtain the `HydraOrderBook - hydra_withdrawal` script hash from dex order book (also an oracle)
   - Check if `HydraOrderBook - hydra_withdrawal` withdrawal script is run

5. Update balance with user intent - cancel withdrawal

   - Obtain the `HydraOrderBook - hydra_cancel_withdrawal` script hash from dex order book (also an oracle)
   - Check if `HydraOrderBook - hydra_cancel_withdrawal` withdrawal script is run

6. Hydra combine utxos at close

   - Obtain the `AccountOperationAuth - hydra_head_close` script hash from dex order book (also an oracle)
   - Check if `AccountOperationAuth - hydra_head_close` withdrawal script is run

7. Remove Empty Account Balance

   - Operation key is signed
   - Obtain the only `HydraAccountBalance` input and its merkle tree account value
   - Balance is empty
   - Check if the token with `HydraAccountBalance` is burnt
