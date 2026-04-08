# Aiken MPF Test Fixture Generation Guide

This guide explains how to generate correct Merkle Patricia Forestry (MPF) fixtures for Aiken tests using TypeScript.

## Overview

Aiken tests often require hardcoded MPF proof data (root hashes, proofs, CBOR-serialized values). When test scenarios change, these fixtures must be regenerated. TypeScript can be used to compute the correct values that match Aiken's CBOR serialization.

## Prerequisites

```bash
npm install @harmoniclabs/cbor
npm install @anastasia-labs/cardano-merkle-patricia-forestry
```

## Key Concepts

### 1. MPF Tree Structure

MPF trees store key-value pairs where:

- **Key**: A ByteArray (e.g., `order_id`, `account_id`)
- **Value**: CBOR-serialized data
- **Path**: `blake2b_256(key)` - determines position in tree
- **Nibble**: First hex digit of path (0-15) - used for tree branching

### 2. CBOR Serialization Differences

Aiken and TypeScript serialize data differently. Here's how to match Aiken's format:

| Aiken Type     | Aiken CBOR                 | TypeScript Equivalent               |
| -------------- | -------------------------- | ----------------------------------- |
| Tuple `(a, b)` | Indefinite array `9f...ff` | `{ list: [a, b] }`                  |
| Bool `False`   | `d87980` (conStr0)         | `conStr0([])`                       |
| Bool `True`    | `d87a80` (conStr1)         | `conStr1([])`                       |
| Integer        | Direct encoding            | `{ int: value }`                    |
| ByteArray      | Direct encoding            | `byteString(hex)`                   |
| Constructor    | `d879xx` / `d87axx`        | `conStr0([...])` / `conStr1([...])` |

## TypeScript Helper Functions

```typescript
import {
  Cbor,
  CborBytes,
  CborArray,
  CborUInt,
  CborTag,
} from "@harmoniclabs/cbor";
import * as crypto from "crypto";

// Helper to create ByteString
function byteString(hex: string): CborBytes {
  return new CborBytes(Buffer.from(hex, "hex"));
}

// Helper to create constructor (conStr0, conStr1, etc.)
function conStr0(fields: any[]): CborTag {
  return new CborTag(121, new CborArray(fields));
}

function conStr1(fields: any[]): CborTag {
  return new CborTag(122, new CborArray(fields));
}

// Helper for integers
function cborInt(value: number | bigint): { int: bigint } {
  return { int: BigInt(value) };
}

// Compute blake2b_256 hash
function blake2b256(data: Buffer): Buffer {
  return crypto.createHash("blake2b256").update(data).digest();
}
```

## Example: Generating Order Fixtures

### Aiken Order Structure

```aiken
type Order {
  order_id: ByteArray,
  base_token: (PolicyId, AssetName),
  quote_token: (PolicyId, AssetName),
  is_buy: Bool,
  list_price_times_1tri: Int,
  size: Int,
  fee_amount_bp: Int,
  account: UserTradeAccount,
  order_type: OrderType,
}
```

### TypeScript Serialization

```typescript
const ORDER_ID = "032f3cc8274143358eb2bbf7b58acaf8";
const USDX_POLICY_ID = "5066154a102ee037390c5236f78db23239b49c5748d3d349f3ccf04b";
const USDX_ASSET_NAME = "55534458";

// Create UserTradeAccount (conStr0 with Account and ScriptHash)
function createMockUserAccount(accountId: string, masterKeyHash: string, operationKeyHash: string, tradingLogic: string) {
  const account = conStr0([
    byteString(accountId),
    conStr0([byteString(masterKeyHash)]),  // VerificationKey
    conStr0([byteString(operationKeyHash)]), // VerificationKey
  ]);
  return conStr0([account, byteString(tradingLogic)]);
}

// Create Order
const order = conStr0([
  byteString(ORDER_ID),
  { list: [byteString(""), byteString("")] },  // base_token tuple (ADA)
  { list: [byteString(USDX_POLICY_ID), byteString(USDX_ASSET_NAME)] },  // quote_token tuple
  conStr0([]),  // is_buy: False
  { int: BigInt(1350000000000) },  // list_price_times_1tri
  { int: BigInt(250000000) },  // size
  { int: BigInt(10) },  // fee_amount_bp
  createMockUserAccount(...),  // account
  conStr0([]),  // order_type: LimitOrder
]);

// Serialize to CBOR
const orderCbor = Cbor.encode(order);
console.log("Order CBOR:", orderCbor.toString("hex"));
```

### Creating MerklizedOrderDatum

For order merkle trees, the value is `MerklizedOrderDatum`, not just `Order`:

```typescript
// MValue structure (map of map)
const mvalue = {
  map: [
    {
      k: byteString(""), // policy_id (empty for ADA)
      v: {
        map: [
          {
            k: byteString(""), // asset_name (empty for lovelace)
            v: { int: BigInt(250000000) }, // amount
          },
        ],
      },
    },
  ],
};

// MerklizedOrderDatum = conStr0([order, mvalue])
const merklizedOrderDatum = conStr0([order, mvalue]);
const value = Cbor.encode(merklizedOrderDatum);
```

## Computing MPF Root Hash

```typescript
import { Trie } from "@anastasia-labs/cardano-merkle-patricia-forestry";

async function computeRootHash(
  keyValuePairs: Array<{ key: Buffer; value: Buffer }>,
) {
  let trie = new Trie();

  for (const { key, value } of keyValuePairs) {
    trie = await trie.insert(key, value);
  }

  return trie.hash.toString("hex");
}

// Example usage
const key = Buffer.from(ORDER_ID, "hex");
const value = Cbor.encode(merklizedOrderDatum);

const rootHash = await computeRootHash([{ key, value }]);
console.log("Root hash:", rootHash);
```

## Generating MPF Proofs

```typescript
async function generateInsertProof(
  existingTrie: Trie,
  key: Buffer,
  value: Buffer,
) {
  const proof = await existingTrie.insert(key, value);
  return proof.proof; // Array of proof steps
}

async function generateDeleteProof(
  existingTrie: Trie,
  key: Buffer,
  value: Buffer,
) {
  const proof = await existingTrie.delete(key, value);
  return proof.proof;
}

// For single-key trie deletion, proof is empty
// new_root becomes null_hash
```

## Common Patterns

### 1. Single-Key Trie Deletion

When deleting the only key in a trie:

- `new_root` = `null_hash` (empty trie)
- `proof` = `[]` (empty proof)

```aiken
let new_root = null_hash
let proof = MPFDelete { proof: [] }
```

### 2. Tree with Multiple Leaves

```typescript
// Sort by blake2b_256(key) for correct tree ordering
const sortedPairs = keyValuePairs.sort((a, b) => {
  const pathA = blake2b256(a.key);
  const pathB = blake2b256(b.key);
  return pathA.compare(pathB);
});
```

### 3. Token Transformation

When dealing with Hydra tokens vs L1 tokens:

```typescript
// Hydra token (uses hash of policy+asset as asset name)
const hydraTokenName = blake2b256(Buffer.concat([policyId, assetName]));

// Token map lookup converts back to L1 tokens
const tokenMap = new Map([
  ["", ["", ""]], // ADA
  [hydraUsdxHash, [USDX_POLICY_ID, USDX_ASSET_NAME]],
]);
```

## Debugging Tips

### 1. Print CBOR Hex for Comparison

```typescript
console.log("TypeScript CBOR:", Cbor.encode(data).toString("hex"));
```

Compare with Aiken debug test:

```aiken
test debug_cbor() {
  trace cbor.serialise(my_data)
  True
}
```

### 2. Verify Path Calculation

```typescript
const path = blake2b256(Buffer.from(key));
const nibble = parseInt(path.toString("hex")[0], 16);
console.log(`Key: ${key}, Path: ${path.toString("hex")}, Nibble: ${nibble}`);
```

### 3. Common CBOR Mismatches

| Issue                | Symptom                            | Fix                                             |
| -------------------- | ---------------------------------- | ----------------------------------------------- |
| Tuple as constructor | `d8799f...ff` instead of `9f...ff` | Use `{ list: [...] }` not `conStr0([...])`      |
| Bool encoding        | Wrong root hash                    | `False` = `conStr0([])`, `True` = `conStr1([])` |
| Missing int wrapper  | Type error                         | Use `{ int: BigInt(n) }` not just `n`           |
| String vs ByteArray  | Wrong serialization                | Always use `byteString(hex)`                    |

## Complete Example: Order Cancel Test

```typescript
import { Cbor } from "@harmoniclabs/cbor";
import { Trie } from "@anastasia-labs/cardano-merkle-patricia-forestry";

async function generateOrderCancelFixtures() {
  const ORDER_ID = "032f3cc8274143358eb2bbf7b58acaf8";

  // Build MerklizedOrderDatum (see above)
  const merklizedOrderDatum = createMerklizedOrderDatum(...);
  const value = Cbor.encode(merklizedOrderDatum);
  const key = Buffer.from(ORDER_ID, "hex");

  // Insert into empty trie
  let trie = new Trie();
  trie = await trie.insert(key, value);

  const oldRoot = trie.hash.toString("hex");

  // Delete from trie (single key = empty trie)
  const newRoot = "0".repeat(64);  // null_hash
  const proof = [];  // empty proof for single-key deletion

  console.log(`old_root: #"${oldRoot}"`);
  console.log(`new_root: null_hash`);
  console.log(`proof: MPFDelete { proof: [] }`);
}
```

## Reference: Aiken Test Structure

```aiken
use aiken/merkle_patricia_forestry/merkling.{null_hash}
use hydra_dex/types.{MPFDelete, MerklizedOrderDatum, Order}

test my_mpf_test() {
  let order = Order { ... }
  let merkle_datum = MerklizedOrderDatum {
    datum: order |> order_datum_to_merkle_datum(token_map),
    value: order_value |> from_hydra_balance_to_value(...) |> to_mvalue(),
  }

  let old_root = #"<computed_root_hash>"
  let new_root = null_hash  // or computed new root
  let proof = MPFDelete { proof: [] }

  validate_operation(old_root, new_root, merkle_datum, proof)
}
```

## Alice & Bob Test Suite

A comprehensive test suite demonstrating all MPF operations and Ed25519 signature verification is located in `validators/tests/alice_bob/`.

### Test Files

| File               | Description                                              |
| ------------------ | -------------------------------------------------------- |
| `merkle_proofs.ak` | All MPF operations (insert, update, delete)              |
| `price_message.ak` | Ed25519 signature verification for price oracle messages |

### Keypairs Used

| User  | Private Key                                                        | Public Key                                                         | Key Hash (Blake2b-224)                                     |
| ----- | ------------------------------------------------------------------ | ------------------------------------------------------------------ | ---------------------------------------------------------- |
| Alice | `f9fddf3603743e56af455da28a63999451011cc443ea09134a97089a8775e153` | `f665d3a9cbb3d8068aece5700771893780dbbf30302eb7ff6835ae68c9efe690` | `376ca49fdbff2ebc082141951e55038468b51230e90cfc0000004204` |
| Bob   | `644674b75aba7f1faa3af927a4ec99648f6b5c8cf03d74f0bef11c4d23fd66e6` | `827444459fa6466ad8fd670179e23b00ea0566547a44cd67a1b37675634280f1` | `9720b632701aabb325d5928b66811d624d650287c2e0e099e1eeb510` |

**Note:** Key hash is computed using Blake2b-224 (28 bytes) of the public key:

```typescript
import { blake2bHex } from "blakejs";
const keyHash = blake2bHex(Buffer.from(publicKey, "hex"), undefined, 28);
```

### MPF Operations Tested

| Test                            | Operation    | Description                      | Root Hash     |
| ------------------------------- | ------------ | -------------------------------- | ------------- |
| `ab_alice_insert_empty_trie`    | `mpf.insert` | Insert Alice into empty trie     | `512be26f...` |
| `ab_bob_insert_after_alice`     | `mpf.insert` | Insert Bob into non-empty trie   | `7287001c...` |
| `ab_alice_update_add_shares`    | `mpf.update` | Alice deposits more shares       | `a5172b6c...` |
| `ab_bob_partial_withdrawal`     | `mpf.update` | Bob withdraws partial shares     | `29769521...` |
| `ab_bob_full_withdrawal_delete` | `mpf.delete` | Bob withdraws all (delete entry) | `5bb79ce6...` |

### Data Structures

```aiken
// MPF Key - UserTradeAccount serialized with cbor.serialise()
type UserTradeAccount {
  account: Account { account_id, master_key, operation_key },
  trading_logic: ScriptHash,
}

// MPF Value - SharesRecordEntry serialized with cbor.serialise()
type SharesRecordEntry {
  shares: Int,
  total_deposited: Int,
}
```

### Regenerating MPF Fixtures

Use the belvedere test to regenerate merkle proofs:

```bash
cd /path/to/belvedere/backend/mesh
npm test -- generateAliceBobProof.test.ts
```

The test outputs all root hashes and proofs needed for Aiken tests.

### Regenerating Signature Fixtures

Use the distiller test to regenerate signed messages:

```bash
cd /path/to/distiller
ALICE_KEY="f9fddf3603743e56af455da28a63999451011cc443ea09134a97089a8775e153" \
BOB_KEY="644674b75aba7f1faa3af927a4ec99648f6b5c8cf03d74f0bef11c4d23fd66e6" \
cargo test test_generate_aiken_sigs -- --nocapture
```

The test outputs CBOR messages and Ed25519 signatures in Aiken constant format.

### MPF Proof Format

The Aiken MPF library uses these proof step types:

```aiken
type Proof =
  List<ProofStep>

type ProofStep {
  Branch { skip: Int, neighbors: ByteArray }
  Fork { skip: Int, neighbor: Neighbor }
  Leaf { skip: Int, key: ByteArray, value: ByteArray }
}
```

Example proof for Bob insert (sibling is Alice's leaf):

```aiken
let proof = [
  mpf.Leaf {
    skip: 0,
    key: #"9a286602a7a703340604bba770eb01da6196925fe5a7f0f20cefd7422a9d1640",
    value: #"89d017515bd4cc392d560d2cb009359b944c1ee6826e379ecfe7cc09165477ea",
  },
]
```

### Ed25519 Signature Verification

```aiken
use aiken/builtin

test verify_signature() {
  let pub_key = #"f665d3a9cbb3d8068aece5700771893780dbbf30302eb7ff6835ae68c9efe690"
  let message = #"d8799f1a59682f00..."  // CBOR-encoded price message
  let signature = #"fbb6537a77aa2fa4..."  // 64-byte Ed25519 signature

  builtin.verify_ed25519_signature(pub_key, message, signature)
}
```

## Summary

1. **Understand the data structure** - Know what Aiken expects (Order vs MerklizedOrderDatum)
2. **Match CBOR serialization** - Tuples as arrays, booleans as constructors
3. **Compute correct hashes** - Use blake2b_256 for paths, MPF library for roots
4. **Test incrementally** - Use debug traces to compare CBOR hex values
5. **Use Alice/Bob tests** - Reference `validators/tests/alice_bob/` for complete MPF operation coverage
