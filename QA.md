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
| `au_wa` - withdrawal_auth_by_account        | ✓    |
| `au_hbi` - hydra_balance_increase           | ✓    |
| `au_hbd` - hydra_balance_decrease           | ✓    |
| `au_ambi` - account_merkle_balance_increase | ✓    |
| `au_ambd` - account_merkle_balance_decrease | ✓    |
| `au_omco` - order_merkle_cancel_order       | ✓    |
| `vhc` - validate_hydra_commit               | ✓    |
| `ou_gsq` - get_short_qty                    | ✓    |
| `ou_gosi` - get_order_settlement_info       | ✓    |
| `ou_gf` - get_fee                           | ✓    |

| **Scripts** | `I` | `SC` | `UT`         | `PBT` |
| ----------- | --- | ---- | ------------ | ----- |
| s0_mint     | ✓   | ✓    | ✓            |       |
| s0_spend    | ✓   | ✓    | ✓            |       |
| s1_wad      | ✓   | ✓    | ✓            |       |
| s1_waw      | ✓   | ✓    | ✓            |       |
| s1_whc      |     |      |              |       |
| s1_who      |     |      |              |       |
| s1_whit     | ✓   | ✓    | ✓            |       |
| s1_whw      | ✓   | ✓    | ✓            |       |
| s1_whcw     | ✓   | ✓    | ✓            |       |
| s2_spend    | ✓   | ✓    | ✓            |       |
| s3_mint     | ✓   | ✓    | ✓            |       |
| s3_spend    | ✓   | ✓    | ✓            |       |
| s4_c_mint   | ✓   | ✓    | ✓            |       |
| s4_c_spend  | ✓   | ✓    | ✓            |       |
| s4_w_mint   | ✓   | ✓    | ✓            |       |
| s4_w_spend  | ✓   | ✓    | ✓            |       |
| s5_mint     | ✓   | ✓    | ✓            |       |
| s5_spend    | ✓   | ✓    | ✓            |       |
| s6_spend    | ✓   | ✓    | ✓            |       |
| s6_wco      |     |      |              |       |
| s6_wso      |     |      |              |       |
| s6_wec      | ✓   | ✓    | ✓            |       |
| s7_mint     | ✓   | ✓    | ✓            |       |
| s7_spend    | ✓   | ✓    | ✓            |       |
| s8_mint     | ✓   | ✓    | ✓            |       |
| s8_spend    | ✓   | ✓    | ✓            |       |
| s9_mint     | ✓   | ✓    | NA           |       |
| s9_spend    | ✓   | ✓    | NA           |       |
| s9_wpo      | ✓   | ✓    | ✓            |       |
| s9_wco      | ✓   | ✓    | ✓            |       |
| s9_wfo      | ✓   | ✓    | ✓ (TW check) |       |
| s9_wrev     | ✓   | ✓    | ✓            |       |

| **Setup**                     | `I` | `IT` | `PBT` | `E2E` |
| ----------------------------- | --- | ---- | ----- | ----- |
| Mint Oracle NFTs              | ✓   | NA   | NA    |       |
| Setup App oracle              | ✓   | NA   | NA    |       |
| Setup DexOrderBook utxo       | ✓   | NA   | NA    |       |
| Setup DexAccountBalance utxo  | ✓   | NA   | NA    |       |
| Setup DexAccountBalance utxos | ✓   | NA   | NA    |       |
| Register all stake certs      | ✓   | NA   | NA    |       |

| Ref   | **App User Actions**       | `I` | `IT` | `PBT` | `E2E` |
| ----- | -------------------------- | --- | ---- | ----- | ----- |
|       | Deposit                    | ✓   | NA   |       |       |
| it_pd | Internal - process deposit | ✓   | ✓    |       |       |
| it_w  | Withdraw                   | ✓   | ✓    |       |       |

| Ref     | **Active Order Book User Actions**       | `I` | `IT` | `PBT` | `E2E` |
| ------- | ---------------------------------------- | --- | ---- | ----- | ----- |
| it_pobu | Internal - prepare order book utxos      |     |      |       |       |
| it_pabu | Internal - prepare account balance utxos |     |      |       |       |
| it_hplo | Place order                              | ✓   | NA   |       |       |
| it_hpro | Internal - Process order                 | ✓   | ✓    |       |       |
| it_hrev | Internal - Release order extra value     | ✓   | ✓    |       |       |
| it_hfo  | Internal - Fill order                    | ✓   | ✓    |       |       |
| it_hco  | Cancel order                             | ✓   | NA   |       |       |
| it_hpco | Internal - Process cancel order          | ✓   | ✓    |       |       |
| it_hrw  | Request Withdrawal                       | ✓   | NA   |       |       |
| it_hpw  | Process withdrawal                       | ✓   | ✓    |       |       |
| it_hcw  | Cancel Withdrawal                        | ✓   | NA   |       |       |
| it_hpcw | Process cancel withdrawal                | ✓   | ✓    |       |       |
| it_cobu | Combine utxos for HydraOrderBook         |     |      |       |       |
| it_cabu | Combine utxos for HydraAccountBalance    |     |      |       |       |
