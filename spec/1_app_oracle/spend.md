# Specification - AppOracle

## Parameter

## Datum

- `operation_key`: The key for operation use. E.g. processing orders
- `stop_key`: The key for stopping the services
- `oracle_nft`: The policy id of `OracleNFT`
- `oracle_address`: The address of the current oracle validator
- `app_vault_script_hash`: The script hash of `AppVault`
- `app_deposit_request_token`: The policy id of auth token at address of `AppDepositRequest`
- `app_deposit_request_address`: The address of `AppDepositRequest`
- `dex_account_balance_token`: The policy id of auth token at address of `DexAccountBalance`
- `dex_account_balance_address`: The address of `DexAccountBalance`
- `dex_account_balance_token`: The policy id of auth token at address of `DexAccountBalance`
- `dex_account_balance_address`: The address of `DexAccountBalance`
- `dex_order_book_token`: The policy id of auth token at address of `DexOrderBook`
- `dex_order_book_address`: The address of `DexOrderBook`
- `emergency_cancel_order_request_token`: The policy id of emergency cancel order token
- `emergency_cancel_order_request_address`: The address of storing emergency cancel order token
- `emergency_withdrawal_request_token`: The policy id of emergency withdrawal token
- `emergency_withdrawal_request_address`: The address of storing emergency withdrawal token
- `all_withdrawal_script_hashes`: To store all staking script hashes
- `hydra_info`: To store hydra related info, this is important for ensuring utxos are committed correctly

## User Action

1. Rotate operation and stop keys - Redeemer `DexRotateKey {new_operation_key, new_stop_key}`

   - The only 1 output datum is updated with new operation key and stop key
   - The output value to oracle is clean (value length == 2)
   - Required signers include both original and the new stop key

2. Stop the oracle validator - Redeemer `StopDex`

   - The transaction is signed by stop key
   - The output value to oracle is clean (value length == 2)
   - Check `own_input` with `oracle_nft`, check that there is one output with same value and identical datum with `operation_key` and `stop_key` as empty bytearray

3. Rotate the Hydra related info - Redeemer `RotateHydraInfo {hydra_info}`

   - The transaction is signed by all signers listed in `hydra_info`
   - The output value to oracle is clean (value length == 2)
   - Check that datum has not changed other than the hydra info
