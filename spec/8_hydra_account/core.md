# Specification - HydraAccount

## Parameter

- `dex_oracle_nft`: The policy id of the token attached with `DexOrderBook`

## Datum

- UserAccount

## User Action

1. Update balance for trade - `HydraAccountTrade { trade_redeemer }`

   - The withdrawal script with `trading_logic` in account datum is run with redeemer of `trade_redeemer`

2. Hydra Account Operation - `HydraAccountOperate`

   - Find own input and obtain the `script_hash`
   - The withdrawal script with `script_hash` is run

3. Spam withdrawal prevention - `HydraAccountSpamPreventionWithdraw`

   - Operation key is signed
   - Either one of below
     - Empty balance - Check balance against value by removing lovelace - is empty
     - There is no datum
