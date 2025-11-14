# Specification - DexAccountBalance - HydraCancelWithdrawal

## Parameter

- `dex_oracle_nft`: The policy id of the token attached with `DexOrderBook`

## User Action

1. Process hydra withdrawal

   - Input datum with current policy is `CancelWithdrawalIntent`
   - Add the account balance (for the `HydraToken`) from `HydraAccountBalance`
   - Exactly 1 input from `DexAccountBalance` with auth token
   - Exactly 1 output to `DexAccountBalance` with auth token with account balance merkle root updated (with translated L1 value)
   - The `HydraToken` added is minted
   - The input token is burnt
   - Signed by operation key
