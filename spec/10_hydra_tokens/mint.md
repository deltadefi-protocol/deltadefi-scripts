# Specification - HydraTokens

## Parameter

- `dex_oracle_nft`: The policy id of the token attached with `DexOrderBook`

## User Action

1. Hydra Head Open (mint)

   - `hydra_head_open` withdrawal script is run

2. Hydra Head Close (burn)

   - `hydra_head_close` withdrawal script is run

3. Withdrawal (burn)

   - `hydra_withdrawal` withdrawal script is run
