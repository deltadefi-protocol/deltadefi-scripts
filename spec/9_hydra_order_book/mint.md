# Specification - HydraUserIntent Token

## Parameter

- `dex_oracle_nft`: The policy id of the token attached with `DexOrderBook`

## User Action

1. Process place order (mint)

   - `place_order` withdrawal script is run

2. Process fill order (burn)

   - `fill_order` withdrawal script is run

3. Process cancel order (burn)

   - `cancel_order` withdrawal script is run

4. Combine into merkle tree

   - `DexOrderBook` - `combine_merkle` withdrawal script is run

5. Split merkle tree

   - `DexOrderBook` -`split_merkle` withdrawal script is run
