# DeltaDeFi Hydra DEX

Below we give the reference indices to relevant scripts in tests and documentation purposes.

In tests, we can run tests for example in `HydraOrderBook` by:

```sh
aiken check -m s9
```

Likewise fill order script logics:

```sh
aiken check -m s9_wfo
```

## 1. AppOracle

The address serving static app information like app operation key etc

- `s1_mint` - `oracle_nft`
- `s1_spend` - `spend`

## 2. AppVault

The address storing all value deposit into the DEX.

- `s2_spend` - `spend`
- `s2_waw` - `app_withdrawal` - The script for checking app withdrawal at L1 (withdrawal)

## 3. AppDepositRequest

The address storing incoming deposit request, to be batched into the deposit info to be committed to hydra head.

- `s3_mint` - `mint`
- `s3_spend` - `spend`
- `s3_wad` - `app_deposit` - The script for checking app deposit (process deposit)

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

- `s8_spend` - `spend`
- `s8_w` - The hydra account withdrawal script, with sub-logics:
  - `s8_whw` - `withdrawal` - The script for checking processing withdrawal request
  - `s8_wcw` - `cancel_withdrawal` - The script for checking processing withdrawal request
  - `s8_wt` - `transferal` - The script for checking transferal of value between 2 accounts
  - `s8_wsat` - `same_account_transferal` - The script for checking transferal of value between 2 accounts
  - `s8_wsuao` - `split_utxos_at_open` - The script for checking account balance splitting at hydra open
  - `s8_wcuac` - `combine_utxos_at_close` - The script for checking account balance combining at hydra close

## 9. HydraOrderBook

The address serves only inside hydra head.

- Open: Breakdown the merkle tree stored by `DexOrderBook` into one user one utxo.
- Active: Serving trades, the address hosting limit orders.
- Close, all info will be combined into `DexOrderBook` utxos.

- `s9_spend` - `spend`
- `s9_w` - The hydra order book withdrawal script, with sub-logics:
  - `s9_wpo` - `place_order`
  - `s9_wco` - `cancel_order`
  - `s9_wmo` - `modify_order`
  - `s9_wfo` - `fill_order`
  - Specific tests on fill orders numbers: `s9_fill_order`
  - `s9_wcom` - `combine_order_merkle`
  - `s9_wsom` - `split_order_merkle`

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
