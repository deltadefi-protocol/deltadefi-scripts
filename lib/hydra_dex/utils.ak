use aiken/cbor
use aiken/collection/list.{difference, is_empty}
use aiken/crypto.{ScriptHash}
use cardano/address.{Address, Credential, Script}
use cardano/assets.{
  AssetName, Lovelace, PolicyId, Value, flatten, merge, quantity_of, zero,
}
use cardano/transaction.{DatumHash, InlineDatum, Input, NoDatum, Output}
use hydra_dex/types.{AppOracleDatum, DexOrderBookDatum, MValue}

pub fn get_app_oracle_datum(
  reference_inputs: List<Input>,
  oracle_nft: PolicyId,
) -> AppOracleDatum {
  expect Some(oracle_input) =
    reference_inputs
      |> list.find(
          fn(ref_input: Input) {
            quantity_of(ref_input.output.value, oracle_nft, "") == 1
          },
        )

  let oracle_input_data: Data =
    when oracle_input.output.datum is {
      NoDatum -> fail @"Oracle input does not contain any datum"
      DatumHash(_) -> fail @"Oracle input datum must be inlined"
      InlineDatum(data) -> data
    }
  expect oracle_input_datum: AppOracleDatum = oracle_input_data
  oracle_input_datum
}

pub fn get_dex_order_book_datum(
  inputs: List<Input>,
  dex_order_book_token: PolicyId,
) -> DexOrderBookDatum {
  expect Some(dex_order_book_ref_input) =
    inputs
      |> list.find(
          fn(ref_input: Input) {
            quantity_of(ref_input.output.value, dex_order_book_token, "") == 1
          },
        )

  let dex_order_book_ref_input_data: Data =
    when dex_order_book_ref_input.output.datum is {
      NoDatum -> fail @"Oracle input does not contain any datum"
      DatumHash(_) -> fail @"Oracle input datum must be inlined"
      InlineDatum(data) -> data
    }
  expect dex_order_book_input_datum: DexOrderBookDatum =
    dex_order_book_ref_input_data
  dex_order_book_input_datum
}

pub fn output_at_with_values(
  outputs: List<Output>,
  address: Address,
  values: List<(PolicyId, AssetName, Int)>,
) -> List<Output> {
  list.filter(
    outputs,
    fn(output) {
      let are_two_lists_equal =
        flatten(output.value) |> difference(values) |> is_empty()
      are_two_lists_equal && output.address == address
    },
  )
}

/// Get the value send to a particular payment credential in a list of outputs
/// ```aiken
/// let value_to = get_all_value_to(outputs, address)
/// ```
pub fn get_all_value_to_cred(outputs: List<Output>, cred: Credential) -> Value {
  list.foldr(
    outputs,
    zero,
    fn(output, acc_value) {
      if output.address.payment_credential == cred {
        merge(acc_value, output.value)
      } else {
        acc_value
      }
    },
  )
}

/// Get the value coming from a particular payment credential in a list of inputs
/// ```aiken
/// let value_from = get_all_value_from(inputs, address)
/// ```
pub fn get_all_value_from_cred(inputs: List<Input>, cred: Credential) -> Value {
  list.foldr(
    inputs,
    zero,
    fn(input, acc_value) {
      if input.output.address.payment_credential == cred {
        merge(acc_value, input.output.value)
      } else {
        acc_value
      }
    },
  )
}

pub fn withdrawal_script_hashes(
  withdrawals: Pairs<Credential, Lovelace>,
) -> List<ScriptHash> {
  withdrawals
    |> list.foldr(
        [],
        fn(pair, acc) {
          let Pair(cred, _) = pair
          when cred is {
            Script(script_hash) -> acc |> list.push(script_hash)
            _ -> acc
          }
        },
      )
}

pub fn to_mvalue(value: Value) -> MValue {
  let data = cbor.serialise(value)
  expect Some(mvalue_raw): Option<Data> = cbor.deserialise(data)
  expect mvalue: MValue = mvalue_raw
  mvalue
}
