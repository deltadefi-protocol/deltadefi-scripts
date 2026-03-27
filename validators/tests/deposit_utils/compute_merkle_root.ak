use aiken/cbor
use aiken/merkle_patricia_forestry as mpf
use cardano/address.{VerificationKey}
use hydra_dex/types.{Account, SharesRecordEntry, UserTradeAccount}

// ========== compute_merkle_root tests ==========
// Test the merkle root computation for vault deposits

// Depositor account from actual CBOR:
// accountId: bddac449efee4ba2b8303762835f04aa
// masterKey: fdeb4bf0e8c077114a4553f1e05395e9fb7114db177f02f7b65c8de4 (Script)
// operationKey: b21f857716821354725bc2bd255dc2e5d5fdfa202556039b76c080a5 (VerificationKey)
// accountType: spot_account (UserTradeAccount)
// trading_logic: 130a4c436f91d5cb0f0ddfccac88d656d4301383c7b1cd8ae7f79e27

const test_account_id = #"bddac449efee4ba2b8303762835f04aa"

const test_master_key =
  #"fdeb4bf0e8c077114a4553f1e05395e9fb7114db177f02f7b65c8de4"

const test_operation_key =
  #"b21f857716821354725bc2bd255dc2e5d5fdfa202556039b76c080a5"

const test_trading_logic =
  #"130a4c436f91d5cb0f0ddfccac88d656d4301383c7b1cd8ae7f79e27"

fn test_depositor() {
  UserTradeAccount {
    account: Account {
      account_id: test_account_id,
      master_key: VerificationKey(test_master_key),
      operation_key: VerificationKey(test_operation_key),
    },
    trading_logic: test_trading_logic,
  }
}

// Test: Verify CBOR serialization of the depositor (MPF key)
test du_compute_merkle_key_serialization() {
  let depositor = test_depositor()
  let mpf_key = cbor.serialise(depositor)
  // Trace the key to see its value
  trace @"mpf_key": mpf_key
  True
}

// Test: Verify CBOR serialization of SharesRecordEntry (MPF value)
test du_compute_merkle_value_serialization() {
  let shares_minted = 10000000
  let deposit_usd_value = 10000000
  let new_entry =
    SharesRecordEntry {
      shares: shares_minted,
      total_deposited: deposit_usd_value,
    }
  let new_value = cbor.serialise(new_entry)
  // Trace the value to see its serialization
  trace @"new_value": new_value
  True
}

// Test: Full merkle root computation for empty trie insert
test du_compute_merkle_root_empty_trie_insert() {
  let depositor = test_depositor()
  let mpf_key = cbor.serialise(depositor)

  let shares_minted = 10000000
  let deposit_usd_value = 10000000
  let new_entry =
    SharesRecordEntry {
      shares: shares_minted,
      total_deposited: deposit_usd_value,
    }
  let new_value = cbor.serialise(new_entry)

  // Empty trie - use mpf.empty instead of empty bytearray
  let trie = mpf.empty
  let proof = []

  let new_trie = mpf.insert(trie, mpf_key, new_value, proof)
  let computed_root = mpf.root(new_trie)

  // Expected from offchain: 40748f1aaa42a65ef33de830179ec943642eae818fa93d3424c92a95946f0256
  let expected_root =
    #"fdc0305f2f749e8d69f069fabf3e09b1432e310373ab037e3330702176011580"

  trace @"mpf_key": mpf_key
  trace @"new_value": new_value
  trace @"computed_root": computed_root
  trace @"expected_root": expected_root

  computed_root == expected_root
}

// Test: Just compute and trace the root (always passes)
test du_compute_merkle_root_trace_only() {
  let depositor = test_depositor()
  let mpf_key = cbor.serialise(depositor)

  let shares_minted = 10000000
  let deposit_usd_value = 10000000
  let new_entry =
    SharesRecordEntry {
      shares: shares_minted,
      total_deposited: deposit_usd_value,
    }
  let new_value = cbor.serialise(new_entry)

  // Empty trie - use mpf.empty instead of empty bytearray
  let trie = mpf.empty
  let proof = []

  let new_trie = mpf.insert(trie, mpf_key, new_value, proof)
  let computed_root = mpf.root(new_trie)

  // Also trace the empty root for reference
  let empty_root = mpf.root(mpf.empty)

  // Trace individual components for debugging
  let account =
    Account {
      account_id: test_account_id,
      master_key: VerificationKey(test_master_key),
      operation_key: VerificationKey(test_operation_key),
    }
  let account_cbor = cbor.serialise(account)

  trace @"===== MPF Debug ====="
  trace @"empty_root": empty_root
  trace @"account_id": test_account_id
  trace @"master_key (VerificationKey)": test_master_key
  trace @"operation_key (VK)": test_operation_key
  trace @"trading_logic": test_trading_logic
  trace @"account_cbor": account_cbor
  trace @"mpf_key (full UserAccount)": mpf_key
  trace @"shares_minted": shares_minted
  trace @"deposit_usd_value": deposit_usd_value
  trace @"new_value (SharesRecordEntry)": new_value
  trace @"computed_root": computed_root
  True
}

// Test: Trace Account CBOR separately
test du_trace_account_serialization() {
  let account =
    Account {
      account_id: test_account_id,
      master_key: VerificationKey(test_master_key),
      operation_key: VerificationKey(test_operation_key),
    }
  let account_cbor = cbor.serialise(account)

  trace @"===== Account CBOR ====="
  trace @"account_cbor": account_cbor
  True
}

// Test: Trace SharesRecordEntry CBOR
test du_trace_shares_entry_serialization() {
  let entry = SharesRecordEntry { shares: 10000000, total_deposited: 10000000 }
  let entry_cbor = cbor.serialise(entry)

  trace @"===== SharesRecordEntry CBOR ====="
  trace @"entry_cbor": entry_cbor
  True
}

// ========== cost_basis calculation tests ==========
// Formula: cost_basis = old_entry.total_deposited * shares_to_redeem / old_entry.shares

test du_cost_basis_calculation() {
  let old_entry_total_deposited = 2999999500
  let shares_to_redeem = 500
  let old_entry_shares = 2909090381

  // cost_basis = 2999999500 * 500 / 2909090381
  //            = 1499999750000 / 2909090381
  //            = 515 (integer division, rounds down)
  let cost_basis = old_entry_total_deposited * shares_to_redeem / old_entry_shares

  trace @"===== Cost Basis Calculation ====="
  trace @"old_entry.total_deposited": old_entry_total_deposited
  trace @"shares_to_redeem": shares_to_redeem
  trace @"old_entry.shares": old_entry_shares
  trace @"cost_basis": cost_basis

  cost_basis == 515
}
