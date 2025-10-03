# HydraAccountBalance Token

## Parameter

- `dex_oracle_nft`: The policy id of the token attached with `DexOrderBook`

## User Action

1. Mint - Redeemer `RMint`

   - Either one:

     1. At Hydra Open

        - Current validating `AccountOperationAuth` - `hydra_open`

     2. Mint Empty Balance

        - Only a single token of current policy id minted
        - No input with current policy id token
        - Only a single output to `HydraAccountBalance` address with empty balance datum
        - Signed by operation key

2. Burn - Redeemer `RBurn`

   - Check if the current policy is only burn
