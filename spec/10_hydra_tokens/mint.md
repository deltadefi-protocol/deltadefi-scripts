# Specification - HydraTokens

## Parameter

- `dex_oracle_nft`: The policy id of the token attached with `DexOrderBook`

## User Action

1. Hydra Head Open (mint)

   - `hydra_account` withdrawal script is run with redeemer `ProcessSplitUtxosAtOpen`

2. Hydra Head Close (burn)

   - `hydra_account` withdrawal script is run with redeemer `ProcessCombineUtxosAtClose`

3. CancelWithdrawal (mint)

   - `hydra_account` withdrawal script is run with redeemer `ProcessCancelWithdrawal`

4. Withdrawal (burn)

   - `hydra_account` withdrawal script is run with redeemer `ProcessWithdrawal`

5. Init Order Book (mint)

   - `hydra_order_book_script_hash` withdrawal script is run with redeemer `SplitOrderMerkle`

6. Combine Order Book (burn)

   - `hydra_order_book_script_hash` withdrawal script is run with redeemer `CombineOrderMerkle`
