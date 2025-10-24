use aiken/builtin.{blake2b_256}
use aiken/collection/list
use aiken/merkle_patricia_forestry as mpf
use aiken/merkle_patricia_forestry/helpers.{combine, nibbles, suffix}
use aiken/merkle_patricia_forestry/merkling.{null_hash}
use aiken/primitive/bytearray
use hydra_dex/types.{MPFDelete, MPFInsert, MPFProof, Tree, TreeBranch, TreeLeaf}

// -----------------------------------------------------------------------------
// ---------------------------------------------------- Custom Tree Computations
// -----------------------------------------------------------------------------

// Experimental function to compute the hash of an entire tree. The structure
// is expected to be a valid tree, and branch nodes are given in a sorted order

pub fn compute_tree_hash(tree: Tree) -> ByteArray {
  go_compute_tree_hash(tree, "")
}

pub fn go_compute_tree_hash(tree: Tree, prefix_nibbles: ByteArray) -> ByteArray {
  when tree is {
    TreeBranch { nibble, nodes } -> {
      // Maybe we can do something without reversing the list?
      let child_hashes =
        list.reverse(
          build_child_hashes(
            [],
            nodes,
            0,
            bytearray.concat(prefix_nibbles, nibble),
          ),
        )
      let merkle_root = build_merkle_hash(child_hashes)
      compute_branch_hash(nibble, merkle_root)
    }
    TreeLeaf { path, key, value } ->
      if blake2b_256(key) != path {
        trace @"key": key
        trace @"path": path
        fail @"invalid tree, path is not the hash of the key"
      } else {
        let cursor = bytearray.length(prefix_nibbles)
        let path_nibbles = nibbles(path, 0, cursor)
        if path_nibbles == prefix_nibbles {
          compute_leaf_hash(path, value, cursor)
        } else {
          trace @"path_nibbles": path_nibbles
          trace @"prefix_nibbles": prefix_nibbles
          fail @"invalid tree, prefix does not match path"
        }
      }
  }
}

fn build_merkle_hash(child_hashes: List<ByteArray>) -> ByteArray {
  when child_hashes is {
    [x] -> x
    [_x, ..] -> go_build_merkle_hash(child_hashes, [])
    _ -> fail @"invalid child hashes, must be a non-empty list"
  }
}

fn go_build_merkle_hash(
  unmerged: List<ByteArray>,
  merged: List<ByteArray>,
) -> ByteArray {
  when unmerged is {
    [] -> go_build_merkle_hash(list.reverse(merged), [])
    [x] ->
      when merged is {
        [] -> x
        [_z, ..] ->
          go_build_merkle_hash(list.reverse(merged) |> list.push(x), [])
      }
    [x, y, ..xs] -> go_build_merkle_hash(xs, merged |> list.push(combine(x, y)))
  }
}

fn build_child_hashes(
  child_hashes: List<ByteArray>,
  nodes: List<Pair<Int, Tree>>,
  cursor: Int,
  prefix_nibbles: ByteArray,
) -> List<ByteArray> {
  if cursor == 16 {
    child_hashes
  } else {
    let maybe_node_head = list.head(nodes)
    when maybe_node_head is {
      None ->
        // If we reach the end of the nodes list, we fill the remaining child hashes with null_hash
        build_child_hashes(
          list.push(child_hashes, null_hash),
          nodes,
          cursor + 1,
          prefix_nibbles,
        )
      Some(node_head) -> {
        // If we have a node, we check its index and compute the hash accordingly
        let node_index = node_head.1st
        if cursor > node_index {
          fail @"invalid tree, children must be sorted by index"
        } else {
          expect Some(tail_nodes) = list.tail(nodes)
          if cursor == node_index {
            let new_prefix =
              bytearray.concat(
                prefix_nibbles,
                bytearray.from_int_big_endian(cursor, 1),
              )
            build_child_hashes(
              list.push(
                child_hashes,
                go_compute_tree_hash(node_head.2nd, new_prefix),
              ),
              tail_nodes,
              cursor + 1,
              prefix_nibbles,
            )
          } else {
            build_child_hashes(
              list.push(child_hashes, null_hash),
              nodes,
              cursor + 1,
              prefix_nibbles,
            )
          }
        }
      }
    }
  }
}

fn compute_leaf_hash(key: ByteArray, value: ByteArray, cursor: Int) -> ByteArray {
  combine(suffix(key, cursor), blake2b_256(value))
}

fn compute_branch_hash(nibble: ByteArray, root: ByteArray) -> ByteArray {
  combine(nibble, root)
}

pub fn extract_key_values(tree: Tree) -> List<Pair<ByteArray, ByteArray>> {
  when tree is {
    TreeLeaf { key, value, .. } -> [Pair(key, value)]
    TreeBranch { nodes, .. } ->
      nodes
        |> list.map(fn(pair: Pair<Int, Tree>) { pair.2nd })
        |> list.foldr([], fn(x, xs) { list.concat(extract_key_values(x), xs) })
  }
}

pub fn recursive_insert(
  old_root: mpf.MerklePatriciaForestry,
  serialised_inputs: List<Pair<ByteArray, ByteArray>>,
  proofs: List<MPFProof>,
) -> mpf.MerklePatriciaForestry {
  when proofs is {
    [] -> old_root
    [proof_head, ..proof_tail] ->
      when serialised_inputs is {
        [] -> fail @"not enough key-values to match proofs"
        [key_value_head, ..key_value_tail] -> {
          let proof: MPFProof = proof_head
          expect MPFInsert { proof: insert_proof } = proof
          let Pair(input_key, input_value) = key_value_head
          let new_root =
            mpf.insert(old_root, input_key, input_value, insert_proof)
          recursive_insert(new_root, key_value_tail, proof_tail)
        }
      }
  }
}

pub fn recursive_delete(
  old_root: mpf.MerklePatriciaForestry,
  serialised_inputs: List<Pair<ByteArray, ByteArray>>,
  proofs: List<MPFProof>,
) -> mpf.MerklePatriciaForestry {
  when proofs is {
    [] -> old_root
    [proof_head, ..proof_tail] ->
      when serialised_inputs is {
        [] -> fail @"not enough key-value pairs to match proofs"
        [key_value_head, ..key_value_tail] -> {
          let proof: MPFProof = proof_head
          expect MPFDelete { proof: delete_proof } = proof
          let Pair(input_key, input_value) = key_value_head
          let new_root =
            mpf.delete(old_root, input_key, input_value, delete_proof)
          recursive_delete(new_root, key_value_tail, proof_tail)
        }
      }
  }
}
