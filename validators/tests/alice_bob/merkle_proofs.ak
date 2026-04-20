use aiken/cbor
use aiken/merkle_patricia_forestry as mpf
use cardano/address.{VerificationKey}
use hydra_dex/types.{Account, SharesRecordEntry, UserTradeAccount}

// ========== Alice and Bob Merkle Proof Tests ==========
// Generated from belvedere test: generateAliceBobProof.test.ts
//
// Alice keypair:
// - Private: f9fddf3603743e56af455da28a63999451011cc443ea09134a97089a8775e153
// - Public:  f665d3a9cbb3d8068aece5700771893780dbbf30302eb7ff6835ae68c9efe690
// - KeyHash: 376ca49fdbff2ebc082141951e55038468b51230e90cfc0000004204 (Blake2b-224)
//
// Bob keypair:
// - Private: 644674b75aba7f1faa3af927a4ec99648f6b5c8cf03d74f0bef11c4d23fd66e6
// - Public:  827444459fa6466ad8fd670179e23b00ea0566547a44cd67a1b37675634280f1
// - KeyHash: 9720b632701aabb325d5928b66811d624d650287c2e0e099e1eeb510 (Blake2b-224)

// Trading logic (constant across all accounts)
const trading_logic =
  #"130a4c436f91d5cb0f0ddfccac88d656d4301383c7b1cd8ae7f79e27"

// Alice account
const alice_account_id = #"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1"

const alice_key_hash =
  #"376ca49fdbff2ebc082141951e55038468b51230e90cfc0000004204"

fn alice_account() {
  UserTradeAccount {
    account: Account {
      account_id: alice_account_id,
      master_key: VerificationKey(alice_key_hash),
      operation_key: VerificationKey(alice_key_hash),
    },
    trading_logic,
  }
}

// Bob account
const bob_account_id = #"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"

const bob_key_hash = #"9720b632701aabb325d5928b66811d624d650287c2e0e099e1eeb510"

fn bob_account() {
  UserTradeAccount {
    account: Account {
      account_id: bob_account_id,
      master_key: VerificationKey(bob_key_hash),
      operation_key: VerificationKey(bob_key_hash),
    },
    trading_logic,
  }
}

// ========== Test 1: Alice Insert (Empty Trie) ==========
// Alice deposits 1000 USD (1000000000 with 6 decimals)
// Shares: 1000000000
// Expected root: 512be26ff9e974483dce99731b88f662578023793c7474cfa081255f25dcb30c

test ab_alice_insert_empty_trie() {
  let alice = alice_account()
  let mpf_key = cbor.serialise(alice)

  let shares = 1000000000
  let total_deposited = 1000000000
  let entry = SharesRecordEntry { shares, total_deposited }
  let value = cbor.serialise(entry)

  // Empty trie - no proof needed
  let trie = mpf.empty
  let proof = []

  let new_trie = mpf.insert(trie, mpf_key, value, proof)
  let computed_root = mpf.root(new_trie)

  let expected_root =
    #"512be26ff9e974483dce99731b88f662578023793c7474cfa081255f25dcb30c"

  trace @"Alice Insert - Key": mpf_key
  trace @"Alice Insert - Value": value
  trace @"Alice Insert - Computed Root": computed_root
  trace @"Alice Insert - Expected Root": expected_root

  computed_root == expected_root
}

// ========== Test 2: Bob Insert (After Alice) ==========
// Bob deposits 500 USD (500000000 with 6 decimals)
// Shares: 500000000
// Previous root: 512be26ff9e974483dce99731b88f662578023793c7474cfa081255f25dcb30c
// Expected root: 7287001c35dee04b34ad6756c69a7e76b02480e309f2e02e861eda037a8dc55f
//
// Proof from offchain:
// [Skip(0), Left(9a286602a7a703340604bba770eb01da6196925fe5a7f0f20cefd7422a9d1640),
//  Right(89d017515bd4cc392d560d2cb009359b944c1ee6826e379ecfe7cc09165477ea)]

test ab_bob_insert_after_alice() {
  let bob = bob_account()
  let mpf_key = cbor.serialise(bob)

  let shares = 500000000
  let total_deposited = 500000000
  let entry = SharesRecordEntry { shares, total_deposited }
  let value = cbor.serialise(entry)

  // Start from Alice's root
  let initial_root =
    #"512be26ff9e974483dce99731b88f662578023793c7474cfa081255f25dcb30c"

  // Proof from offchain - Leaf { skip, key, value }
  // constructor 2 = Leaf
  let proof =
    [
      mpf.Leaf {
        skip: 0,
        key: #"9a286602a7a703340604bba770eb01da6196925fe5a7f0f20cefd7422a9d1640",
        value: #"89d017515bd4cc392d560d2cb009359b944c1ee6826e379ecfe7cc09165477ea",
      },
    ]

  let trie = mpf.from_root(initial_root)
  let new_trie = mpf.insert(trie, mpf_key, value, proof)
  let computed_root = mpf.root(new_trie)

  let expected_root =
    #"7287001c35dee04b34ad6756c69a7e76b02480e309f2e02e861eda037a8dc55f"

  trace @"Bob Insert - Key": mpf_key
  trace @"Bob Insert - Value": value
  trace @"Bob Insert - Computed Root": computed_root
  trace @"Bob Insert - Expected Root": expected_root

  computed_root == expected_root
}

// ========== Test 3: Alice Update (Add More Shares) ==========
// Alice adds 500 USD more (500000000)
// Previous: shares=1000000000, total_deposited=1000000000
// New: shares=1500000000, total_deposited=1500000000
// Previous root: 7287001c35dee04b34ad6756c69a7e76b02480e309f2e02e861eda037a8dc55f
// Expected root: a5172b6c809ac4c12992851680d5de37f5819e73fe9613ea7d5aa137a4d2848f
//
// Proof from offchain (after update):
// [Skip(0), Left(8751465de93e2a74c4910c140e4c6c13a6f7259971d902ea2b10f91b5015ad85),
//  Right(c940040c98da9bd1480fcdc9abd41b747173dbc0d8ea49e5637a8a0258019eb2)]

test ab_alice_update_add_shares() {
  let alice = alice_account()
  let mpf_key = cbor.serialise(alice)

  // Old entry
  let old_entry =
    SharesRecordEntry { shares: 1000000000, total_deposited: 1000000000 }
  let old_value = cbor.serialise(old_entry)

  // New entry
  let new_entry =
    SharesRecordEntry { shares: 1500000000, total_deposited: 1500000000 }
  let new_value = cbor.serialise(new_entry)

  // Start from previous root (Alice + Bob)
  let initial_root =
    #"7287001c35dee04b34ad6756c69a7e76b02480e309f2e02e861eda037a8dc55f"

  // Proof AFTER update (proof of new state) - Leaf { skip, key, value }
  let proof =
    [
      mpf.Leaf {
        skip: 0,
        key: #"8751465de93e2a74c4910c140e4c6c13a6f7259971d902ea2b10f91b5015ad85",
        value: #"c940040c98da9bd1480fcdc9abd41b747173dbc0d8ea49e5637a8a0258019eb2",
      },
    ]

  let trie = mpf.from_root(initial_root)
  let new_trie = mpf.update(trie, mpf_key, proof, old_value, new_value)
  let computed_root = mpf.root(new_trie)

  let expected_root =
    #"a5172b6c809ac4c12992851680d5de37f5819e73fe9613ea7d5aa137a4d2848f"

  trace @"Alice Update - Old Value": old_value
  trace @"Alice Update - New Value": new_value
  trace @"Alice Update - Computed Root": computed_root
  trace @"Alice Update - Expected Root": expected_root

  computed_root == expected_root
}

// ========== Test 4: Bob Partial Withdrawal (Update) ==========
// Bob withdraws 200 USD (200000000)
// Previous: shares=500000000, total_deposited=500000000
// New: shares=300000000, total_deposited=300000000
// Previous root: a5172b6c809ac4c12992851680d5de37f5819e73fe9613ea7d5aa137a4d2848f
// Expected root: 297695211c6d2e8f8b6c9ec37871498ffbb52bfe29e048aaffa421022cbed7b8
//
// Proof from offchain (after update):
// [Skip(0), Left(9a286602a7a703340604bba770eb01da6196925fe5a7f0f20cefd7422a9d1640),
//  Right(9cbf7a4e01dee5c3b4c521b47782526bfc7f46c543da6fc21e2d89330811050b)]

test ab_bob_partial_withdrawal() {
  let bob = bob_account()
  let mpf_key = cbor.serialise(bob)

  // Old entry
  let old_entry =
    SharesRecordEntry { shares: 500000000, total_deposited: 500000000 }
  let old_value = cbor.serialise(old_entry)

  // New entry (after withdrawing 200M)
  let new_entry =
    SharesRecordEntry { shares: 300000000, total_deposited: 300000000 }
  let new_value = cbor.serialise(new_entry)

  // Start from previous root
  let initial_root =
    #"a5172b6c809ac4c12992851680d5de37f5819e73fe9613ea7d5aa137a4d2848f"

  // Proof AFTER update - Leaf { skip, key, value }
  let proof =
    [
      mpf.Leaf {
        skip: 0,
        key: #"9a286602a7a703340604bba770eb01da6196925fe5a7f0f20cefd7422a9d1640",
        value: #"9cbf7a4e01dee5c3b4c521b47782526bfc7f46c543da6fc21e2d89330811050b",
      },
    ]

  let trie = mpf.from_root(initial_root)
  let new_trie = mpf.update(trie, mpf_key, proof, old_value, new_value)
  let computed_root = mpf.root(new_trie)

  let expected_root =
    #"297695211c6d2e8f8b6c9ec37871498ffbb52bfe29e048aaffa421022cbed7b8"

  trace @"Bob Withdraw - Old Value": old_value
  trace @"Bob Withdraw - New Value": new_value
  trace @"Bob Withdraw - Computed Root": computed_root
  trace @"Bob Withdraw - Expected Root": expected_root

  computed_root == expected_root
}

// ========== Test 5: Bob Full Withdrawal (Delete) ==========
// Bob withdraws all remaining 300 USD (300000000)
// Previous: shares=300000000, total_deposited=300000000
// New: Entry deleted from trie
// Previous root: 297695211c6d2e8f8b6c9ec37871498ffbb52bfe29e048aaffa421022cbed7b8
// Expected root: 5bb79ce6b41c271bb91676a5616b737e7d4c3c722d68ffd1857d6f703bec85d3
//
// Proof from offchain (BEFORE delete):
// [Skip(0), Left(9a286602a7a703340604bba770eb01da6196925fe5a7f0f20cefd7422a9d1640),
//  Right(9cbf7a4e01dee5c3b4c521b47782526bfc7f46c543da6fc21e2d89330811050b)]

test ab_bob_full_withdrawal_delete() {
  let bob = bob_account()
  let mpf_key = cbor.serialise(bob)

  // Old entry (to be deleted)
  let old_entry =
    SharesRecordEntry { shares: 300000000, total_deposited: 300000000 }
  let old_value = cbor.serialise(old_entry)

  // Start from previous root
  let initial_root =
    #"297695211c6d2e8f8b6c9ec37871498ffbb52bfe29e048aaffa421022cbed7b8"

  // Proof BEFORE delete (proof of existence) - Leaf { skip, key, value }
  let proof =
    [
      mpf.Leaf {
        skip: 0,
        key: #"9a286602a7a703340604bba770eb01da6196925fe5a7f0f20cefd7422a9d1640",
        value: #"9cbf7a4e01dee5c3b4c521b47782526bfc7f46c543da6fc21e2d89330811050b",
      },
    ]

  let trie = mpf.from_root(initial_root)
  let new_trie = mpf.delete(trie, mpf_key, old_value, proof)
  let computed_root = mpf.root(new_trie)

  let expected_root =
    #"5bb79ce6b41c271bb91676a5616b737e7d4c3c722d68ffd1857d6f703bec85d3"

  trace @"Bob Delete - Old Value": old_value
  trace @"Bob Delete - Computed Root": computed_root
  trace @"Bob Delete - Expected Root": expected_root

  computed_root == expected_root
}

// ========== Summary Test ==========
test ab_merkle_summary() {
  trace @"===== Alice and Bob Merkle Proof Summary ====="
  trace @"Empty Root": #"0000000000000000000000000000000000000000000000000000000000000000"
  trace @"After Alice Insert": #"512be26ff9e974483dce99731b88f662578023793c7474cfa081255f25dcb30c"
  trace @"After Bob Insert": #"7287001c35dee04b34ad6756c69a7e76b02480e309f2e02e861eda037a8dc55f"
  trace @"After Alice Update": #"a5172b6c809ac4c12992851680d5de37f5819e73fe9613ea7d5aa137a4d2848f"
  trace @"After Bob Partial Withdraw": #"297695211c6d2e8f8b6c9ec37871498ffbb52bfe29e048aaffa421022cbed7b8"
  trace @"After Bob Delete": #"5bb79ce6b41c271bb91676a5616b737e7d4c3c722d68ffd1857d6f703bec85d3"
  True
}
