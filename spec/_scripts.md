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

- `s1_mint` - `oracle_nft` [(script)](../validators/app_oracle/oracle_nft.ak)
- `s1_spend` - `spend` [(script)](../validators/app_oracle/spend.ak)

## 2. AppVault

The address storing all value deposit into the DEX.

- `s2_spend` - `spend` [(script)](../validators/app_vault/spend.ak)
- `s2_waw` - `app_withdrawal` - The script for checking app withdrawal at L1 (withdrawal) [(script)](../validators/app_vault/app_withdrawal.ak)
- `s2_wavsr` - `app_vault_stake_rotation` [(script)](../validators/app_vault/app_vault_stake_rotation.ak)

## 3. AppDepositRequest

The address storing incoming deposit request, to be batched into the deposit info to be committed to hydra head.

- `s3_mint` - `mint` [(script)](../validators/app_deposit_request/mint.ak)
- `s3_spend` - `spend` [(script)](../validators/app_deposit_request/spend.ak)
- `s3_wad` - `app_deposit` - The script for checking app deposit (process deposit) [(script)](../validators/app_deposit_request/app_deposit.ak)

## 4. EmergencyRequest

The set of scripts to handle emergency request at L1, i.e. cancelling orders and withdrawal directly from merkle root without app owner signature.

- `s4_w_spend` - `withdrawal_spend` [(script)](../validators/emergency_request/withdrawal_spend.ak)
- `s4_w_mint` - `withdrawal_mint` [(script)](../validators/emergency_request/withdrawal_mint.ak)
- `s4_c_spend` - `cancel_order_spend` [(script)](../validators/emergency_request/cancel_order_spend.ak)
- `s4_c_mint` - `cancel_order_mint` [(script)](../validators/emergency_request/cancel_order_mint.ak)

## 5. DexAccountBalance

The single utxo to be committed into hydra head, serving user account balance information.

- `s5_mint` - `mint` [(script)](../validators/dex_account_balance/mint.ak)
- `s5_spend` - `spend` [(script)](../validators/dex_account_balance/spend.ak)

## 6. DexOrderBook

The single utxo to be committed into hydra head, serving orders information (limit orders).

- `s6_spend` - `spend` [(script)](../validators/dex_order_book/spend.ak)
- `s6_wec` - `emergency_cancel` [(script)](../validators/dex_order_book/emergency_cancel.ak)

## 7. HydraUserIntent

The address serves only inside hydra head.

- Serving trades, the address hosting limit / market order intents for further processing / batching.
- Empty state at open and close (processed into `HydraOrderBook`)

- `s7_mint` - `mint` [(script)](../validators/hydra_user_intent.ak)
- `s7_spend` - `spend` [(script)](../validators/hydra_user_intent.ak)

## 8. HydraAccount

The address serves only inside hydra head.

- Open: Breakdown the merkle tree stored by `DexAccountBalance` into one user one utxo.
- Active: Serving trade and withdrawal requests.
- Close, all info will be combined into `DexAccountBalance` utxos.

- `s8_spend` - `spend` [(script)](../validators/hydra_account/core.ak)
- `s8_w` - The hydra account withdrawal script, with sub-logics:
  - `s8_whw` - `withdrawal` - The script for checking processing withdrawal request [(script)](../validators/hydra_account/withdrawal.ak)
  - `s8_wcw` - `cancel_withdrawal` - The script for checking processing withdrawal request [(script)](../validators/hydra_account/cancel_withdrawal.ak)
  - `s8_wt` - `transferal` - The script for checking transferal of value between 2 accounts [(script)](../validators/hydra_account/transferal.ak)
  - `s8_wsat` - `same_account_transferal` - The script for checking transferal of value between 2 accounts [(script)](../validators/hydra_account/same_account_transferal.ak)
  - `s8_wsuao` - `split_utxos_at_open` - The script for checking account balance splitting at hydra open [(script)](../validators/hydra_account/split_utxos_at_open.ak)
  - `s8_wcuac` - `combine_utxos_at_close` - The script for checking account balance combining at hydra close [(script)](../validators/hydra_account/combine_utxos_at_close.ak)

## 9. HydraOrderBook

The address serves only inside hydra head.

- Open: Breakdown the merkle tree stored by `DexOrderBook` into one user one utxo.
- Active: Serving trades, the address hosting limit orders.
- Close, all info will be combined into `DexOrderBook` utxos.

- `s9_spend` - `spend` [(script)](../validators/hydra_order_book/core.ak)
- `s9_w` - The hydra order book withdrawal script, with sub-logics:
  - `s9_wpo` - `place_order` [(script)](../validators/hydra_order_book/place_order.ak)
  - `s9_wco` - `cancel_order` [(script)](../validators/hydra_order_book/cancel_order.ak)
  - `s9_wmo` - `modify_order` [(script)](../validators/hydra_order_book/modify_order.ak)
  - `s9_wfo` - `fill_order` [(script)](../validators/hydra_order_book/fill_order.ak)
    - Specific tests on fill orders numbers: `s9_fill_order`
  - `s9_wcom` - `combine_order_merkle` [(script)](../validators/hydra_order_book/combine_order_merkle.ak)
  - `s9_wsom` - `split_order_merkle` [(script)](../validators/hydra_order_book/split_order_merkle.ak)
