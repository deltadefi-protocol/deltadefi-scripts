# QA for the Hydra DEX

Glossary

- `I`: Implement
- `SC`: Specificiation checking
- `UT`: Unit Test
- `IT`: Integration Test
- `PBT`: Property-based Test
- `E2E`: End-to-end Test

| **Utils**                                   | `UT` |
| ------------------------------------------- | ---- |
| `au_ta` - trade_auth_by_account             | ✓    |
| `au_ma` - master_auth_by_account            | ✓    |
| `au_ambi` - account_merkle_balance_increase | ✓    |
| `au_ambd` - account_merkle_balance_decrease | ✓    |
| `au_omco` - order_merkle_cancel_order       |      |
| `vhc` - validate_hydra_commit               | ✓    |
| `htu` - hydra_tree_utils                    | ✓    |
| `ou_gmov` - get_min_order_value             | ✓    |
| `ou_gmpv` - get_min_payoff_value            | ✓    |
| `ou_gpq` - get_payoff_quantity              |      |
| `ou_gf` - get_fee                           | ✓    |

| **Scripts** | `I` | `SC` | `UT`           | `PBT` |
| ----------- | --- | ---- | -------------- | ----- |
| s1_mint     | ✓   | ✓    | ✓              |       |
| s1_spend    | ✓   | ✓    | ✓              |       |
| s2_spend    | ✓   | ✓    | ✓              |       |
| s2_waw      | ✓   | ✓    | To update root |       |
| s3_mint     | ✓   | ✓    | ✓              |       |
| s3_spend    | ✓   | ✓    | ✓              |       |
| s3_wad      | ✓   | ✓    | To update root |       |
| s4_c_mint   | ✓   | ✓    | ✓              |       |
| s4_c_spend  | ✓   | ✓    | ✓              |       |
| s4_w_mint   | ✓   | ✓    | ✓              |       |
| s4_w_spend  | ✓   | ✓    | ✓              |       |
| s5_mint     | ✓   | ✓    | ✓              |       |
| s5_spend    | ✓   | ✓    | ✓              |       |
| s6_spend    | ✓   | ✓    | ✓              |       |
| s6_wec      | ✓   | ✓    | To update root |       |
| s7_mint     | ✓   | ✓    | ✓              |       |
| s7_spend    | ✓   | ✓    | ✓              |       |
| s8_mint     | ✓   | ✓    | ✓              |       |
| s8_spend    | ✓   | ✓    | ✓              |       |
| s8_wcw      | ✓   | ✓    | To update root |       |
| s8_wcuac    | ✓   | ✓    | To update root |       |
| s8_wsat     | ✓   | ✓    | ✓              |       |
| s8_wsuao    | ✓   | ✓    | To update root |       |
| s8_ww       | ✓   | ✓    | To update root |       |
| s8_wt       | ✓   | ✓    | ✓              |       |
| s9_spend    | ✓   | ✓    | NA             |       |
| s9_wpo      | ✓   | ✓    | ✓              |       |
| s9_wco      | ✓   | ✓    | ✓              |       |
| s9_wfo      | ✓   | ✓    | ✓              |       |
| s9_wmo      | ✓   | ✓    | ✓              |       |
| s9_wsom     | ✓   | ✓    | To update root |       |
| s9_wcom     | ✓   | ✓    | To update root |       |
| s10         | ✓   | ✓    |                |       |

| **Setup**                     | `I` | `IT` | `PBT` | `E2E` |
| ----------------------------- | --- | ---- | ----- | ----- |
| Mint Oracle NFTs              | ✓   | NA   | NA    |       |
| Setup App oracle              | ✓   | NA   | NA    |       |
| Setup DexOrderBook oracle     | ✓   | NA   | NA    |       |
| Setup empty DexAccountBalance | ✓   | NA   | NA    |       |
| Register all stake certs      | ✓   | NA   | NA    |       |

| Ref   | **App User Actions**       | `I` | `IT`           | `PBT` | `E2E` |
| ----- | -------------------------- | --- | -------------- | ----- | ----- |
|       | Deposit                    | ✓   | NA             |       |       |
| it_pd | Internal - process deposit | ✓   | To update root |       |       |
| it_w  | Withdraw                   | ✓   | To update root |       |       |

| Ref     | **Active Order Book User Actions**       | `I` | `IT` | `PBT` | `E2E` |
| ------- | ---------------------------------------- | --- | ---- | ----- | ----- |
|         | Internal - prepare order book utxos      |     |      |       |       |
|         | Internal - prepare account balance utxos |     |      |       |       |
|         | Place order                              | ✓   | NA   |       |       |
| it_hpo  | Internal - Process order                 | ✓   | ✓    |       |       |
| it_hfo  | Internal - Fill order                    | ✓   | ✓    |       |       |
|         | Cancel order                             | ✓   | NA   |       |       |
|         | Internal - Process cancel order          | ✓   | NA   |       |       |
|         | Request Withdrawal                       | ✓   | NA   |       |       |
| it_hpw  | Process withdrawal                       | ✓   |      |       |       |
|         | Cancel Withdrawal                        | ✓   | NA   |       |       |
| it_hpcw | Process cancel withdrawal                | ✓   |      |       |       |
|         | Combine utxos for HydraOrderBook         |     |      |       |       |
|         | Combine utxos for HydraAccount           |     |      |       |       |
