# Aiken Test Results Summary

**Date:** 2026-01-13

## Overview

| Directory           | Prefix | Total | Passed | Failed | Status |
| ------------------- | ------ | ----- | ------ | ------ | ------ |
| account_utils       | `au_`  | 54    | 48     | 6      | FAIL   |
| order_utils         | `ou_`  | 26    | 26     | 0      | PASS   |
| app_oracle          | `s1_`  | 13    | 13     | 0      | PASS   |
| app_vault           | `s2_`  | 18    | 12     | 6      | FAIL   |
| app_deposit_request | `s3_`  | 31    | 28     | 3      | FAIL   |
| emergency_request   | `s4_`  | 30    | 30     | 0      | PASS   |
| dex_account_balance | `s5_`  | 40    | 40     | 0      | PASS   |
| dex_order_book      | `s6_`  | 22    | 17     | 5      | FAIL   |
| hydra_user_intent   | `s7_`  | 28    | 28     | 0      | PASS   |
| hydra_account       | `s8_`  | 60    | 45     | 15     | FAIL   |
| hydra_order_book    | `s9_`  | 145   | 143    | 2      | FAIL   |
| hydra_tokens        | `s10_` | 6     | 6      | 0      | PASS   |
| integration_tests   | `it_`  | 33    | 19     | 14     | FAIL   |

**Total:** 506 tests | **Passed:** 455 | **Failed:** 51 | **Pass Rate:** 89.9%

---

## Failure Details

### account*utils (au*) - 6 failures

| Test               | Module                          | Error                                                  |
| ------------------ | ------------------------------- | ------------------------------------------------------ |
| `au_hmbd_delete`   | account_merkle_balance_decrease | `expect including(key, value, proof) == self.root`     |
| `au_hmbd_update`   | account_merkle_balance_decrease | `expect including(key, old_value, proof) == self.root` |
| `au_hmbi_insert`   | account_merkle_balance_increase | (crashed)                                              |
| `au_hmbi_update`   | account_merkle_balance_increase | `expect including(key, old_value, proof) == self.root` |
| `au_hmbi_update_2` | account_merkle_balance_increase | `expect including(key, old_value, proof) == self.root` |

### app*vault (s2*) - 6 failures

| Test                                                        | Module         | Error                                                  |
| ----------------------------------------------------------- | -------------- | ------------------------------------------------------ |
| `s2_waw_success`                                            | app_withdrawal | `expect including(key, old_value, proof) == self.root` |
| `s2_waw_failed_without_operation_key_signed`                | app_withdrawal | `expect including(key, old_value, proof) == self.root` |
| `s2_waw_failed_without_merkle_updated`                      | app_withdrawal | `expect including(key, old_value, proof) == self.root` |
| `s2_waw_success_emergency_withdrawal`                       | app_withdrawal | `expect including(key, old_value, proof) == self.root` |
| `s2_waw_failed_emergency_withdrawal_without_time_passed`    | app_withdrawal | `expect including(key, old_value, proof) == self.root` |
| `s2_waw_failed_emergency_withdrawal_without_user_signature` | app_withdrawal | `expect including(key, old_value, proof) == self.root` |

### app*deposit_request (s3*) - 3 failures

| Test                                         | Module      | Error                                                  |
| -------------------------------------------- | ----------- | ------------------------------------------------------ |
| `s3_wad_success`                             | app_deposit | `expect including(key, old_value, proof) == self.root` |
| `s3_wad_failed_without_operation_key_signed` | app_deposit | `expect including(key, old_value, proof) == self.root` |
| `s3_wad_failed_without_updating_merkle`      | app_deposit | `expect including(key, old_value, proof) == self.root` |

### dex*order_book (s6*) - 5 failures

| Test                                                        | Module           | Error                                              |
| ----------------------------------------------------------- | ---------------- | -------------------------------------------------- |
| `s6_wec_success`                                            | emergency_cancel | `expect including(key, value, proof) == self.root` |
| `s6_wec_failed_without_merkle_updated`                      | emergency_cancel | `expect including(key, value, proof) == self.root` |
| `s6_wec_success_emergency_withdrawal`                       | emergency_cancel | `expect including(key, value, proof) == self.root` |
| `s6_wec_failed_emergency_withdrawal_without_time_passed`    | emergency_cancel | `expect including(key, value, proof) == self.root` |
| `s6_wec_failed_emergency_withdrawal_without_user_signature` | emergency_cancel | `expect including(key, value, proof) == self.root` |

### hydra*account (s8*) - 15 failures

| Test                                                                       | Module                 | Error                                                  |
| -------------------------------------------------------------------------- | ---------------------- | ------------------------------------------------------ |
| `s8_wcw_success`                                                           | cancel_withdrawal      | `expect including(key, old_value, proof) == self.root` |
| `s8_wcw_failed_without_operation_key_signed`                               | cancel_withdrawal      | `expect including(key, old_value, proof) == self.root` |
| `s8_wcw_failed_without_merkle_root_updated`                                | cancel_withdrawal      | `expect including(key, old_value, proof) == self.root` |
| `s8_wcw_failed_without_account_balance_updated`                            | cancel_withdrawal      | `expect including(key, old_value, proof) == self.root` |
| `s8_wcw_failed_without_intent_token_burnt`                                 | cancel_withdrawal      | `expect including(key, old_value, proof) == self.root` |
| `s8_wcw_failed_without_cancel_withdrawal_amount_minted`                    | cancel_withdrawal      | `expect including(key, old_value, proof) == self.root` |
| `s8_wcuac_spend_success_hydra_head_close`                                  | combine_utxos_at_close | Merkle key/path mismatch                               |
| `s8_wcuac_spend_fail_hydra_head_close_without_all_hydra_signer_signatures` | combine_utxos_at_close | Merkle key/path mismatch                               |
| `s8_wcuac_spend_fail_hydra_head_close_without_all_tokens_burnt`            | combine_utxos_at_close | Merkle key/path mismatch                               |
| `s8_wsat_success`                                                          | same_account_transfer  | `expect including(key, old_value, proof) == self.root` |
| `s8_wsat_failed_without_operation_key_signed`                              | same_account_transfer  | `expect including(key, old_value, proof) == self.root` |
| `s8_wsat_failed_without_merkle_root_updated`                               | same_account_transfer  | `expect including(key, old_value, proof) == self.root` |
| `s8_wsat_failed_without_intent_token_burnt`                                | same_account_transfer  | `expect including(key, old_value, proof) == self.root` |
| `s8_wsuao_success`                                                         | split_utxos_at_open    | `is_merkle_root_updated ? False`                       |
| `s8_ww_success`                                                            | withdrawal             | `expect including(key, old_value, proof) == self.root` |

### hydra*order_book (s9*) - 2 failures

| Test                                   | Module               | Error                                                          |
| -------------------------------------- | -------------------- | -------------------------------------------------------------- |
| `s9_wcom_success_combine_order_merkle` | combine_order_merkle | `extract_key_values(tree) == sorted_serialised_inputs ? False` |
| `s9_wsom_success_split_order_merkle`   | split_order_merkle   | `key_values == output_serialised_datum_list ? False`           |

### integration*tests (it*) - 14 failures

| Test                                                         | Module          | Error                                                  |
| ------------------------------------------------------------ | --------------- | ------------------------------------------------------ |
| `it_pd_success`                                              | process_deposit | `expect including(key, old_value, proof) == self.root` |
| `it_pd_failed_without_operation_key_signed`                  | process_deposit | `expect including(key, old_value, proof) == self.root` |
| `it_pd_failed_without_updating_merkle`                       | process_deposit | `expect including(key, old_value, proof) == self.root` |
| `it_pd_failed_without_intent_token_burnt`                    | process_deposit | `expect including(key, old_value, proof) == self.root` |
| `it_pd_failed_without_sending_value_to_vault`                | process_deposit | `expect including(key, old_value, proof) == self.root` |
| `it_pd_failed_without_withdrawal_script`                     | process_deposit | `expect including(key, old_value, proof) == self.root` |
| `it_w_success`                                               | withdraw        | `expect including(key, old_value, proof) == self.root` |
| `it_w_failed_without_operation_key_signed`                   | withdraw        | `expect including(key, old_value, proof) == self.root` |
| `it_w_failed_without_merkle_updated`                         | withdraw        | `expect including(key, old_value, proof) == self.root` |
| `it_w_failed_without_withdrawal_script`                      | withdraw        | `expect including(key, old_value, proof) == self.root` |
| `it_w_success_emergency_withdrawal`                          | withdraw        | `expect including(key, old_value, proof) == self.root` |
| `it_w_failed_emergency_withdrawal_without_time_passed`       | withdraw        | `expect including(key, old_value, proof) == self.root` |
| `it_w_failed_emergency_withdrawal_without_user_signature`    | withdraw        | `expect including(key, old_value, proof) == self.root` |
| `it_w_failed_emergency_withdrawal_without_withdrawal_script` | withdraw        | `expect including(key, old_value, proof) == self.root` |

---

## Common Failure Pattern

**All 51 failures** are related to **Merkle Patricia Forestry (MPF) proof validation**:

| Error Type | Count | Description |
|------------|-------|-------------|
| `expect including(key, value, proof) == self.root` | 46 | Direct proof validation failure |
| Merkle key/path mismatch | 3 | Key doesn't match expected path in trie |
| `is_merkle_root_updated ? False` | 1 | Root hash mismatch after operation |
| `extract_key_values(tree) != expected` | 1 | Tree serialization mismatch |

### Root Cause

Test fixtures use hardcoded MPF proof data that doesn't match the test scenarios:

```aiken
let proof = MPFUpdate {
  from: #"a140a1401a05f5e100",      // hardcoded old balance
  to: #"a240a1401a3b9aca00...",     // hardcoded new balance
  to_proof: [],                      // EMPTY - no valid merkle proof
}
```

The empty `to_proof: []` cannot verify key existence in the merkle trie, causing all MPF operations to fail.

### Resolution

Tests marked "To update root" in `spec/QA.md` require regenerating valid MPF proofs that:
1. Match the `old_root` hash in test fixtures
2. Contain valid merkle paths proving key existence
3. Have correct `from`/`to` balance values matching the test scenario
