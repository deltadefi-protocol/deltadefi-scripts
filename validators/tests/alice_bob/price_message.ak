use aiken/builtin
use cardano/assets.{AssetName, PolicyId}
use hydra_dex/price_oracle_utils.{convert_m_value_to_usd}
use hydra_dex/types.{MValue}

// ========== Alice and Bob Price Message Tests ==========
// These tests verify Ed25519 signature verification for price oracle messages
//
// Alice keypair:
// - Public:  f665d3a9cbb3d8068aece5700771893780dbbf30302eb7ff6835ae68c9efe690
// - KeyHash: 376ca49fdbff2ebc082141951e55038468b51230e90cfc0000004204 (Blake2b-224)
//
// Bob keypair:
// - Public:  827444459fa6466ad8fd670179e23b00ea0566547a44cd67a1b37675634280f1
// - KeyHash: 9720b632701aabb325d5928b66811d624d650287c2e0e099e1eeb510 (Blake2b-224)

// Alice's full public key (Ed25519, 32 bytes)
const alice_pub_key =
  #"f665d3a9cbb3d8068aece5700771893780dbbf30302eb7ff6835ae68c9efe690"

// Bob's full public key (Ed25519, 32 bytes)
const bob_pub_key =
  #"827444459fa6466ad8fd670179e23b00ea0566547a44cd67a1b37675634280f1"

// ========== Generated Signatures from Distiller ==========
// Message 1 (vault_equity=1500000000)
const msg1_cbor =
  #"d8799f1a59682f00a29f4040ff9f0501ff9f581cc69b981db7a65e339a6d783755f85a2e03afa1cece9714c55fe4c913445553444dff9f0100ffd8799f5820aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa00ffff"

const alice_sig_1 =
  #"fbb6537a77aa2fa4c99cda827fda738610d7f9c64b915df7a216d884af534eb250fa826db87ba3b66b9d040cf8bf9837b7963f63ea0bfcc8a6ec7eb1a4a45504"

const bob_sig_1 =
  #"dd00226efff0da6387d12e10464a53b221ef40c128d7f54403bfb66d3000a68dbf5bfbf303678201fbc47a03aea5853c83c04d7084a5f9bc6710f05e2a02f904"

// Message 2 (vault_equity=1800000000)
const msg2_cbor =
  #"d8799f1a6b49d200a29f4040ff9f0501ff9f581cc69b981db7a65e339a6d783755f85a2e03afa1cece9714c55fe4c913445553444dff9f0100ffd8799f5820bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb01ffff"

const alice_sig_2 =
  #"6c864008c16bfef445af2d6711790ca57744367f851d7065f85cac842b7da40fdbda6eb9e6e3df4f322b8bc92f24f56628068d689e31bb9be988adaa95924f04"

const bob_sig_2 =
  #"e5dbbfd09404d77b1999c5b0e750d15b7ce715f6436af4b45878a2fb75b860e7c90a301d3d3eef1ed7353bb71a71ebce057e06a2100af39615c58a8448363f02"

// ========== Prices Definition ==========
// ADA price = $0.50 (price=5, scale=1 -> 5/10^1 = 0.5)
// USDM price = $1.00 (price=1, scale=0 -> 1/10^0 = 1.0)
const prices: Pairs<(PolicyId, AssetName), (Int, Int)> =
  [
    Pair((#"", #""), (5, 1)),
    Pair(
      (#"c69b981db7a65e339a6d783755f85a2e03afa1cece9714c55fe4c913", #"5553444d"),
      (1, 0),
    ),
  ]

// ========== Test 1: Verify Alice Signature on Message 1 ==========
// Uses builtin.verify_ed25519_signature to verify the signature

test ab_verify_alice_signature_message_1() {
  let is_valid =
    builtin.verify_ed25519_signature(alice_pub_key, msg1_cbor, alice_sig_1)

  trace @"Alice Signature Valid": is_valid
  is_valid
}

// ========== Test 2: Verify Bob Signature on Message 1 ==========
test ab_verify_bob_signature_message_1() {
  let is_valid =
    builtin.verify_ed25519_signature(bob_pub_key, msg1_cbor, bob_sig_1)

  trace @"Bob Signature Valid": is_valid
  is_valid
}

// ========== Test 3: Verify Both Signatures on Message 1 ==========
test ab_verify_both_signatures_message_1() {
  let alice_valid =
    builtin.verify_ed25519_signature(alice_pub_key, msg1_cbor, alice_sig_1)
  let bob_valid =
    builtin.verify_ed25519_signature(bob_pub_key, msg1_cbor, bob_sig_1)

  trace @"Alice Valid": alice_valid
  trace @"Bob Valid": bob_valid

  alice_valid && bob_valid
}

// ========== Test 4: Verify Signatures on Message 2 ==========
test ab_verify_both_signatures_message_2() {
  let alice_valid =
    builtin.verify_ed25519_signature(alice_pub_key, msg2_cbor, alice_sig_2)
  let bob_valid =
    builtin.verify_ed25519_signature(bob_pub_key, msg2_cbor, bob_sig_2)

  trace @"Alice Valid": alice_valid
  trace @"Bob Valid": bob_valid

  alice_valid && bob_valid
}

// ========== Test 5: Signature Verification Should Fail with Wrong Key ==========
test ab_verify_signature_fails_wrong_key() {
  // Verify Alice's signature with Bob's key - should return False
  let should_be_false =
    builtin.verify_ed25519_signature(bob_pub_key, msg1_cbor, alice_sig_1)

  trace @"Wrong Key Result (should be false)": should_be_false

  !should_be_false
}

// ========== Test 6: Signature Verification Should Fail with Wrong Message ==========
test ab_verify_signature_fails_wrong_message() {
  // Verify Alice's signature for msg1 against msg2 - should return False
  let should_be_false =
    builtin.verify_ed25519_signature(alice_pub_key, msg2_cbor, alice_sig_1)

  trace @"Wrong Message Result (should be false)": should_be_false

  !should_be_false
}

// ========== Test 7: Convert MValue to USD ==========
// Test USD calculation with the prices
// Example: 1000 ADA + 500 USDM = 1000 * 0.5 + 500 * 1.0 = 1000 USD

test ab_convert_mvalue_to_usd() {
  // MValue with 1000 ADA (lovelace) and 500 USDM
  let m_value: MValue =
    [
      Pair("", [Pair("", 1000)]),
      Pair(
        #"c69b981db7a65e339a6d783755f85a2e03afa1cece9714c55fe4c913",
        [Pair(#"5553444d", 500)],
      ),
    ]

  // Calculate USD value
  // USD = 1000 * 5 / 10^1 + 500 * 1 / 10^0
  //     = 1000 * 0.5 + 500 * 1.0
  //     = 500 + 500
  //     = 1000
  let usd_value = convert_m_value_to_usd(m_value, prices)
  let expected_usd = 1000

  trace @"USD Value": usd_value
  trace @"Expected": expected_usd

  usd_value == expected_usd
}

// ========== Test 8: Trace Message CBOR Format ==========
test ab_trace_message_format() {
  trace @"=== Message 1 (Vault Equity 1500 USD) ==="
  trace @"CBOR": msg1_cbor
  trace @"Alice Sig": alice_sig_1
  trace @"Bob Sig": bob_sig_1

  trace @"=== Message 2 (Vault Equity 1800 USD) ==="
  trace @"CBOR": msg2_cbor
  trace @"Alice Sig": alice_sig_2
  trace @"Bob Sig": bob_sig_2

  True
}
