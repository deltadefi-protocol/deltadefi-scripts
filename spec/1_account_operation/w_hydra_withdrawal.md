# Specification - DexAccountBalance - HydraWithdrawal

## Parameter

- `dex_oracle_nft`: The policy id of the token attached with `DexOrderBook`

## User Action

1. Process hydra withdrawal

   - Input datum with current policy is `WithdrawalIntent`
   - Deduct the account balance from `HydraAccountBalance` with corresponding auth token
   - Exactly 1 input from `DexAccountBalance` with auth token
   - Exactly 1 output to `DexAccountBalance` with auth token with account balance merkle root updated
   - The input token is burnt
