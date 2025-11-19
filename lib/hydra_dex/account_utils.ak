use aiken/cbor
use aiken/collection/dict
use aiken/collection/list
use aiken/collection/pairs
use aiken/crypto.{ScriptHash, VerificationKeyHash, blake2b_256}
use aiken/merkle_patricia_forestry as mpf
use aiken/primitive/bytearray
use cardano/address.{Address, Credential, Script, VerificationKey}
use cardano/assets.{
  AssetName, Lovelace, PolicyId, Value, from_asset_list, merge, negate, tokens,
  zero,
}
use cardano/transaction.{Input, Output}
use cocktail.{input_inline_datum, one_of_keys_signed, output_inline_datum}
use hydra_dex/types.{
  DexAccountBalanceDatum, DexOrderBookDatum, MPFDelete, MPFInsert, MPFProof,
  MPFUpdate, MValue, MerklizedOrderDatum, TokenMap, UserAccount,
  UserFundingAccount, UserMobileAccount, UserSpotAccount,
}
use hydra_dex/utils.{withdrawal_script_hashes}

// Filters

pub fn create_account_inputs_filter(
  account: UserAccount,
  hydra_account_balance_address: Address,
) {
  fn(input: Input) {
    if input.output.address == hydra_account_balance_address {
      expect input_datum: UserAccount = input_inline_datum(input)
      input_datum == account
    } else {
      False
    }
  }
}

pub fn create_account_outputs_filter(
  account: UserAccount,
  hydra_account_balance_address: Address,
) {
  fn(output: Output) {
    if output.address == hydra_account_balance_address {
      expect output_datum: UserAccount = output_inline_datum(output)
      output_datum == account
    } else {
      False
    }
  }
}

//  Account Value related

pub fn hash_token(policy_id: PolicyId, asset_name: AssetName) -> AssetName {
  if policy_id == "" && asset_name == "" {
    ""
  } else {
    blake2b_256(policy_id |> bytearray.concat(asset_name))
  }
}

pub fn from_value_to_hydra_balance(
  account_value: Value,
  hydra_tokens_policy_id: PolicyId,
) -> Value {
  account_value
    |> assets.reduce(
        zero,
        fn(policy_id, asset_name, qty, acc) {
          let token_hash = hash_token(policy_id, asset_name)
          acc |> assets.add(hydra_tokens_policy_id, token_hash, qty)
        },
      )
}

pub fn from_hydra_balance_to_value(
  hydra_value: Value,
  hydra_tokens_policy_id: PolicyId,
  token_map: TokenMap,
) -> Value {
  hydra_value
    |> tokens(hydra_tokens_policy_id)
    |> dict.foldr(
        zero,
        fn(token_hash, token_qty, account_value_acc) {
          when pairs.get_first(token_map, token_hash) is {
            Some((policy_id, asset_name)) ->
              account_value_acc
                |> assets.add(policy_id, asset_name, token_qty)
            None -> fail @"Token hash not found in token map"
          }
        },
      )
}

//
pub fn compare_user_account(a: UserAccount, b: UserAccount) -> Ordering {
  let a_account_id = get_account_id(a)
  let b_account_id = get_account_id(b)
  bytearray.compare(a_account_id, b_account_id)
}

pub fn get_account_id(account: UserAccount) -> ByteArray {
  when account is {
    UserSpotAccount { account } -> account.account_id
    UserFundingAccount { account } -> account.account_id
    UserMobileAccount { account } -> account.account_id
  }
}

pub fn split_creds(
  creds: List<Credential>,
) -> (List<VerificationKeyHash>, List<ScriptHash>) {
  creds
    |> list.foldr(
        ([], []),
        fn(cred, (acc_pub_key_hashes, acc_script_hashes)) {
          when cred is {
            VerificationKey(pub_key) ->
              (acc_pub_key_hashes |> list.push(pub_key), acc_script_hashes)
            Script(script_hash) ->
              (acc_pub_key_hashes, acc_script_hashes |> list.push(script_hash))
          }
        },
      )
}

pub fn get_master_key(account: UserAccount) -> Credential {
  when account is {
    UserSpotAccount { account } -> account.master_key
    UserFundingAccount { account } -> account.master_key
    UserMobileAccount { account } -> account.master_key
  }
}

pub fn get_trade_keys(
  account: UserAccount,
) -> (List<VerificationKeyHash>, List<ScriptHash>) {
  let creds =
    when account is {
      UserSpotAccount { account } -> [account.master_key, account.operation_key]
      UserFundingAccount { account } -> [account.master_key]
      UserMobileAccount { account } ->
        [account.master_key, account.operation_key]
    }
  split_creds(creds)
}

pub fn get_withdrawal_keys(
  account: UserAccount,
) -> (List<VerificationKeyHash>, List<ScriptHash>) {
  let creds =
    when account is {
      UserSpotAccount { account } -> [account.master_key]
      UserFundingAccount { account } ->
        [account.master_key, account.operation_key]
      UserMobileAccount { account } ->
        [account.master_key, account.operation_key]
    }
  split_creds(creds)
}

pub fn trade_auth_by_account(
  account: UserAccount,
  withdrawals: Pairs<Credential, Lovelace>,
  extra_signatories: List<VerificationKeyHash>,
) -> Bool {
  let (pub_key_hashes, script_hashes) = get_trade_keys(account)
  let signature_auth = one_of_keys_signed(extra_signatories, pub_key_hashes)
  let script_auth =
    withdrawal_script_hashes(withdrawals)
      |> one_of_keys_signed(script_hashes)
  signature_auth || script_auth
}

pub fn withdrawal_auth_by_account(
  account: UserAccount,
  withdrawals: Pairs<Credential, Lovelace>,
  extra_signatories: List<VerificationKeyHash>,
) -> Bool {
  let (pub_key_hashes, script_hashes) = get_withdrawal_keys(account)
  let signature_auth = one_of_keys_signed(extra_signatories, pub_key_hashes)
  let script_auth =
    withdrawal_script_hashes(withdrawals) |> one_of_keys_signed(script_hashes)
  signature_auth || script_auth
}

pub fn hydra_balance_increase(
  input: Input,
  output: Output,
  increase: Value,
) -> Bool {
  expect input_datum: UserAccount = input_inline_datum(input)
  expect output_datum: UserAccount = output_inline_datum(output)
  let old_balance = input.output.value
  let new_balance = output.value
  let expected_balance = old_balance |> merge(increase)
  let is_same_account = input_datum == output_datum
  is_same_account? && (expected_balance == new_balance)?
}

pub fn hydra_balance_decrease(
  input: Input,
  output: Output,
  decrease: Value,
) -> Bool {
  expect input_datum: UserAccount = input_inline_datum(input)
  expect output_datum: UserAccount = output_inline_datum(output)
  let old_balance = input.output.value
  let new_balance = output.value
  let expected_balance = old_balance |> merge(negate(decrease))
  let is_same_account = input_datum == output_datum
  is_same_account && expected_balance == new_balance
}

pub fn dex_account_balance_balance_increase(
  input: Input,
  output: Output,
  account: UserAccount,
  increase: Value,
  proof: MPFProof,
) -> Bool {
  expect input_datum: DexAccountBalanceDatum = input_inline_datum(input)
  expect output_datum: DexAccountBalanceDatum = output_inline_datum(output)

  account_merkle_balance_increase(
    input_datum.account_balance_merkle_root,
    output_datum.account_balance_merkle_root,
    account,
    increase,
    proof,
  )
}

pub fn dex_account_balance_balance_decrease(
  input: Input,
  output: Output,
  account: UserAccount,
  decrease: Value,
  proof: MPFProof,
) -> Bool {
  expect input_datum: DexAccountBalanceDatum = input_inline_datum(input)
  expect output_datum: DexAccountBalanceDatum = output_inline_datum(output)

  account_merkle_balance_decrease(
    input_datum.account_balance_merkle_root,
    output_datum.account_balance_merkle_root,
    account,
    decrease,
    proof,
  )
}

pub fn deser_value(serialised_value: ByteArray) -> Value {
  expect Some(deserialised_value) = cbor.deserialise(serialised_value)
  expect asset_list: MValue = deserialised_value
  from_asset_list(asset_list)
}

pub fn account_merkle_balance_increase(
  old_root: ByteArray,
  new_root: ByteArray,
  account: UserAccount,
  increase: Value,
  proof: MPFProof,
) -> Bool {
  let old_trie = mpf.from_root(old_root)
  let key = cbor.serialise(account)
  when proof is {
    MPFInsert { proof } -> {
      let updated_trie =
        mpf.insert(old_trie, key, cbor.serialise(increase), proof)
      mpf.root(updated_trie) == new_root
    }
    MPFUpdate { from, to, to_proof } -> {
      let from_balance = deser_value(from)
      let to_balance = deser_value(to)
      let is_balance_updated =
        from_balance |> merge(increase) |> assets.match(to_balance, ==)
      let updated_trie = mpf.update(old_trie, key, to_proof, from, to)
      let is_new_balance_correct = mpf.root(updated_trie) == new_root
      is_balance_updated? && is_new_balance_correct?
    }
    _ -> False
  }
}

pub fn account_merkle_balance_decrease(
  old_root: ByteArray,
  new_root: ByteArray,
  account: UserAccount,
  decrease: Value,
  proof: MPFProof,
) {
  let old_trie = mpf.from_root(old_root)
  let key = cbor.serialise(account)
  when proof is {
    MPFDelete { proof } -> {
      let updated_trie =
        mpf.delete(old_trie, key, cbor.serialise(decrease), proof)
      mpf.root(updated_trie) == new_root
    }
    MPFUpdate { from, to, to_proof } -> {
      let from_balance = deser_value(from)
      let to_balance = deser_value(to)
      let is_balance_updated =
        from_balance |> merge(negate(decrease)) |> assets.match(to_balance, ==)
      let updated_trie = mpf.update(old_trie, key, to_proof, from, to)
      let is_new_balance_correct = mpf.root(updated_trie) == new_root
      is_balance_updated && is_new_balance_correct
    }
    _ -> False
  }
}

pub fn get_account_input(
  inputs: List<Input>,
  account: UserAccount,
) -> Option<Input> {
  inputs
    |> list.find(
        fn(account_input) {
          expect datum_account: UserAccount = input_inline_datum(account_input)
          datum_account == account
        },
      )
}

pub fn get_account_output(
  outputs: List<Output>,
  account: UserAccount,
) -> Option<Output> {
  outputs
    |> list.find(
        fn(account_output) {
          expect datum_account: UserAccount =
            output_inline_datum(account_output)
          datum_account == account
        },
      )
}

// Dex Order Book
pub fn dex_order_book_cancel_order(
  input: Input,
  output: Output,
  order: MerklizedOrderDatum,
  proof: MPFProof,
) -> Bool {
  expect input_datum: DexOrderBookDatum = input_inline_datum(input)
  expect output_datum: DexOrderBookDatum = output_inline_datum(output)

  order_merkle_cancel_order(
    input_datum.limit_orders_merkle_root,
    output_datum.limit_orders_merkle_root,
    order,
    proof,
  )
}

pub fn order_merkle_cancel_order(
  old_root: ByteArray,
  new_root: ByteArray,
  order: MerklizedOrderDatum,
  proof: MPFProof,
) -> Bool {
  let old_trie = mpf.from_root(old_root)
  let new_trie = mpf.from_root(new_root)
  when proof is {
    MPFDelete { proof } ->
      mpf.delete(old_trie, order.datum.order_id, cbor.serialise(order), proof) == new_trie
    _ -> False
  }
}
