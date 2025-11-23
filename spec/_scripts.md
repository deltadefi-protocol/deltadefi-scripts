# DeltaDeFi Hydra DEX

In the hydra dex design, it is hugely rely on datum serving assets ownership information. Therefore, apart from `AppVault`, the actual script storing meaningful asset value, the rest of the scripts will come in pairs, where the `Token` script provides validity to datum serving in address.

## 0. AppOracle

The address serving static app information like app operation key etc

- `s0_mint` - `oracle_nft`
- `s0_spend` - `spend`

## 1. AccountOperation

Organising all the withdrawal scripts validating account balance transfer operation

- `s1_wad` - `app_deposit` - The script for checking app deposit (process deposit)
- `s1_waw` - `app_withdrawal` - The script for checking app withdrawal at L1 (withdrawal)
- `s1_whw` - `hydra_withdrawal` - The script for checking processing withdrawal request
- `s1_whcw` - `hydra_cancel_withdrawal` - The script for checking processing withdrawal request
- `s1_whit` - `hydra_internal_transfer` - The script for checking transferal of value between 2 accounts
- `s1_who` - `hydra_head_open` - The script for checking account balance splitting at hydra open
- `s1_whc` - `hydra_head_close` - The script for checking account balance combining at hydra close

## 2. AppVault

The address storing all value deposit into the DEX.

- `s2_spend` - `spend`

## 3. AppDepositRequest

The address storing incoming deposit request, to be batched into the deposit info to be committed to hydra head.

- `s3_mint` - `mint`
- `s3_spend` - `spend`

## 4. EmergencyRequest

The set of scripts to handle emergency request at L1, i.e. cancelling orders and withdrawal directly from merkle root without app owner signature.

- `s4_w_spend` - `withdrawal_spend`
- `s4_w_mint` - `withdrawal_mint`
- `s4_c_spend` - `cancel_order_spend`
- `s4_c_mint` - `cancel_order_mint`

## 5. DexAccountBalance

The single utxo to be committed into hydra head, serving user account balance information.

- `s5_mint` - `mint`
- `s5_spend` - `spend`

## 6. DexOrderBook

The single utxo to be committed into hydra head, serving orders information (limit orders).

- `s6_spend` - `spend`
- `s6_wso` - `split_order_merkle`
- `s6_wco` - `combine_order_merkle`
- `s6_wec` - `emergency_cancel`

## 7. HydraTradeIntent

The address serves only inside hydra head.

- Serving trades, the address hosting limit / market order intents for further processing / batching.
- Empty state at open and close (processed into `HydraOrderBook`)

- `s7_mint` - `mint`
- `s7_spend` - `spend`

## 8. HydraAccount

The address serves only inside hydra head.

- Open: Breakdown the merkle tree stored by `DexAccountBalance` into one user one utxo.
- Active: Serving trade and withdrawal requests.
- Close, all info will be combined into `DexAccountBalance` utxos.

- `s8_mint` - `mint`
- `s8_spend` - `spend`

## 9. HydraOrderBook

The address serves only inside hydra head.

- Open: Breakdown the merkle tree stored by `DexOrderBook` into one user one utxo.
- Active: Serving trades, the address hosting limit orders.
- Close, all info will be combined into `DexOrderBook` utxos.

- `s9_mint` - `mint`
- `s9_spend` - `spend`
- `s9_wpo` - `place_order`
- `s9_wco` - `cancel_order`
- `s9_wfo` - `fill_order`
- `s9_wrev` - `release_extra_value`

## Param Dependency Graph

1. First layer

   - 0.mint `OracleNFT` (param: `utxo_ref`)
   - 0.spend `AppOracle` (no param)

2. Second layer

   - 2.1 All account actions (param: `owner`, 1.1, 1.2)
   - 2.2 All dex actions (param: 1.1, 1.2)
   - 2.3 `EmergencyUnlock` (param: 1.2)

3. Third layer

   - 3.1 `EmergencyToken` (param: 2.3)

4. Fourth layer

   - 4.1 `Account` (param: 2.1, 2.3, 3.1)
   - 4.2 `VirtualDEX` (param: 2.2, 2.3, 3.1)
