use aiken/collection/list
use cardano/address.{Address}
use cardano/assets.{
  AssetName, PolicyId, Value, flatten, merge, quantity_of, zero,
}
use cardano/transaction.{InlineDatum, Input, Output}
use mocktail.{complete, mock_pub_key_address, mock_tx_hash, mocktail_tx, tx_in}

/// Extracts the inline datum from an output.
/// ```aiken
/// expect inline_datum: MyDatumType = output_inline_datum(output)
/// ```
pub fn output_inline_datum(output: Output) {
  expect InlineDatum(raw_datum) = output.datum
  raw_datum
}

/// Filters outputs by Address.
/// ```aiken
/// let filtered_outputs = outputs_at(outputs, address)
/// ```
pub fn outputs_at(outputs: List<Output>, address: Address) -> List<Output> {
  list.filter(outputs, o_at(address))
}

pub fn o_at(address: Address) -> fn(Output) -> Bool {
  fn(o: Output) { o.address == address }
}

/// Filters outputs by PolicyId and AssetName.
/// ```aiken
/// let filtered_outputs = outputs_with(outputs, policy, name)
/// ```
pub fn outputs_with(
  outputs: List<Output>,
  policy: PolicyId,
  name: AssetName,
) -> List<Output> {
  list.filter(outputs, o_with(policy, name))
}

pub fn o_with(policy: PolicyId, name: AssetName) -> fn(Output) -> Bool {
  fn(o: Output) { quantity_of(o.value, policy, name) == 1 }
}

/// Filters outputs by token policy.
/// ```aiken
/// let filtered_outputs = outputs_with_policy(outputs, policy)
/// ```
pub fn outputs_with_policy(
  outputs: List<Output>,
  policy: PolicyId,
) -> List<Output> {
  list.filter(outputs, o_with_policy(policy))
}

pub fn o_with_policy(policy: PolicyId) -> fn(Output) -> Bool {
  fn(o: Output) {
    list.any(flatten(o.value), fn(token) { token.1st == policy })
  }
}

/// Filters outputs by Address, PolicyId, and AssetName.
/// ```aiken
/// let filtered_outputs = outputs_at_with(outputs, address, policy, name)
/// ```
pub fn outputs_at_with(
  outputs: List<Output>,
  address: Address,
  policy: PolicyId,
  name: AssetName,
) -> List<Output> {
  list.filter(outputs, o_at_with(address, policy, name))
}

pub fn o_at_with(
  address: Address,
  policy: PolicyId,
  name: AssetName,
) -> fn(Output) -> Bool {
  fn(o: Output) {
    o.address == address && quantity_of(o.value, policy, name) == 1
  }
}

/// Filters outputs by Address and PolicyId.
/// ```aiken
/// let filtered_outputs = outputs_at_with_policy(outputs, address, policy)
/// ```
pub fn outputs_at_with_policy(
  outputs: List<Output>,
  address: Address,
  policy: PolicyId,
) -> List<Output> {
  list.filter(
    outputs,
    fn(output) {
      output.address == address && list.any(
        flatten(output.value),
        fn(token) { token.1st == policy },
      )
    },
  )
}

pub fn o_at_with_policy(
  address: Address,
  policy: PolicyId,
) -> fn(Output) -> Bool {
  fn(o: Output) {
    o.address == address && list.any(
      flatten(o.value),
      fn(token) { token.1st == policy },
    )
  }
}

pub fn group_outputs(
  outputs: List<Output>,
  group: fn(Output) -> Bool,
) -> (List<Output>, List<Output>) {
  outputs
    |> list.foldr(
        ([], []),
        fn(output, acc) {
          if group(output) {
            (acc.1st |> list.push(output), acc.2nd)
          } else {
            (acc.1st, acc.2nd |> list.push(output))
          }
        },
      )
}

pub fn group_outputs_2(
  outputs: List<Output>,
  group1: fn(Output) -> Bool,
  group2: fn(Output) -> Bool,
) -> (List<Output>, List<Output>, List<Output>) {
  outputs
    |> list.foldr(
        ([], [], []),
        fn(output, acc) {
          if group1(output) {
            (acc.1st |> list.push(output), acc.2nd, acc.3rd)
          } else if group2(output) {
            (acc.1st, acc.2nd |> list.push(output), acc.3rd)
          } else {
            (acc.1st, acc.2nd, acc.3rd |> list.push(output))
          }
        },
      )
}

/// Extracts the inline datum from an input.
/// ```aiken
/// expect inline_datum: MyDatumType = input_inline_datum(input)
/// ```
pub fn input_inline_datum(input: Input) {
  expect InlineDatum(raw_datum) = input.output.datum
  raw_datum
}

/// Extract the inline datum by locating the first input in a list of inputs by Address and PolicyId.
/// ```aiken
/// expect inline_datum: MyDatumType = only_input_datum_with(inputs, policy, name)
/// ```
pub fn only_input_datum_with(
  inputs: List<Input>,
  policy: PolicyId,
  name: AssetName,
) {
  expect Some(input) = list.find(inputs, i_with(policy, name))
  input_inline_datum(input)
}

/// Filters inputs by Address.
/// ```aiken
/// let filtered_inputs = inputs_at(inputs, address)
/// ```
pub fn inputs_at(inputs: List<Input>, address: Address) -> List<Input> {
  list.filter(inputs, i_at(address))
}

pub fn i_at(address: Address) -> fn(Input) -> Bool {
  fn(i: Input) { i.output.address == address }
}

/// Filters inputs by PolicyId and AssetName.
/// ```aiken
/// let filtered_inputs = inputs_with(inputs, policy, name)
/// ```
pub fn inputs_with(
  inputs: List<Input>,
  policy: PolicyId,
  name: AssetName,
) -> List<Input> {
  list.filter(inputs, i_with(policy, name))
}

pub fn i_with(policy: PolicyId, name: AssetName) -> fn(Input) -> Bool {
  fn(i: Input) { quantity_of(i.output.value, policy, name) == 1 }
}

/// Filters inputs by token policy.
/// ```aiken
/// let filtered_inputs = inputs_with_policy(inputs, policy)
/// ```
pub fn inputs_with_policy(inputs: List<Input>, policy: PolicyId) -> List<Input> {
  list.filter(inputs, i_with_policy(policy))
}

pub fn i_with_policy(policy: PolicyId) -> fn(Input) -> Bool {
  fn(i: Input) {
    list.any(flatten(i.output.value), fn(token) { token.1st == policy })
  }
}

/// Filters inputs by Address, PolicyId, and AssetName.
/// ```aiken
/// let filtered_inputs = inputs_at_with(inputs, address, policy, name)
/// ```
pub fn inputs_at_with(
  inputs: List<Input>,
  address: Address,
  policy: PolicyId,
  name: AssetName,
) -> List<Input> {
  list.filter(inputs, i_at_with(address, policy, name))
}

pub fn i_at_with(
  address: Address,
  policy: PolicyId,
  name: AssetName,
) -> fn(Input) -> Bool {
  fn(i: Input) {
    i.output.address == address && quantity_of(i.output.value, policy, name) == 1
  }
}

/// Filters inputs by Address and PolicyId.
/// ```aiken
/// let filtered_inputs = inputs_at_with_policy(inputs, address, policy)
/// ```
pub fn inputs_at_with_policy(
  inputs: List<Input>,
  address: Address,
  policy: PolicyId,
) -> List<Input> {
  list.filter(inputs, i_at_with_policy(address, policy))
}

pub fn i_at_with_policy(address: Address, policy: PolicyId) -> fn(Input) -> Bool {
  fn(i: Input) {
    i.output.address == address && list.any(
      flatten(i.output.value),
      fn(token) { token.1st == policy },
    )
  }
}

/// Calculate the total quantity of a token in a list of inputs.
/// ```aiken
/// let total_quantity = inputs_token_quantity(inputs, token)
/// ```
pub fn inputs_token_quantity(
  inputs: List<Input>,
  token: (PolicyId, AssetName),
) -> Int {
  list.map(
    inputs,
    fn(input) { quantity_of(input.output.value, token.1st, token.2nd) },
  )
    |> list.foldr(0, fn(n, total) { n + total })
}

pub fn group_inputs(
  inputs: List<Input>,
  group: fn(Input) -> Bool,
) -> (List<Input>, List<Input>) {
  inputs
    |> list.foldr(
        ([], []),
        fn(input, acc) {
          if group(input) {
            (acc.1st |> list.push(input), acc.2nd)
          } else {
            (acc.1st, acc.2nd |> list.push(input))
          }
        },
      )
}

pub fn group_inputs_2(
  inputs: List<Input>,
  group1: fn(Input) -> Bool,
  group2: fn(Input) -> Bool,
) -> (List<Input>, List<Input>, List<Input>) {
  inputs
    |> list.foldr(
        ([], [], []),
        fn(input, acc) {
          if group1(input) {
            (acc.1st |> list.push(input), acc.2nd, acc.3rd)
          } else if group2(input) {
            (acc.1st, acc.2nd |> list.push(input), acc.3rd)
          } else {
            (acc.1st, acc.2nd, acc.3rd |> list.push(input))
          }
        },
      )
}

test test_group_inputs_at() {
  let tx =
    mocktail_tx()
      |> tx_in(True, mock_tx_hash(0), 0, zero, mock_pub_key_address(0, None))
      |> tx_in(True, mock_tx_hash(0), 1, zero, mock_pub_key_address(0, None))
      |> tx_in(True, mock_tx_hash(0), 2, zero, mock_pub_key_address(0, None))
      |> tx_in(True, mock_tx_hash(0), 3, zero, mock_pub_key_address(1, None))
      |> complete()

  let mock_inputs = tx.inputs

  let (inputs, inputs_2) =
    mock_inputs |> group_inputs(i_at(mock_pub_key_address(0, None)))
  list.length(inputs_2) == 1 && list.length(inputs) == 3
}

test test_inputs_at() {
  let tx =
    mocktail_tx()
      |> tx_in(True, mock_tx_hash(0), 0, zero, mock_pub_key_address(0, None))
      |> tx_in(True, mock_tx_hash(0), 1, zero, mock_pub_key_address(0, None))
      |> tx_in(True, mock_tx_hash(0), 2, zero, mock_pub_key_address(0, None))
      |> tx_in(True, mock_tx_hash(0), 3, zero, mock_pub_key_address(1, None))
      |> complete()

  let mock_inputs = tx.inputs

  let inputs = mock_inputs |> inputs_at(mock_pub_key_address(0, None))
  let inputs_2 = mock_inputs |> inputs_at(mock_pub_key_address(1, None))
  list.length(inputs_2) == 1 && list.length(inputs) == 3
}

pub fn inputs_value(inputs: List<Input>) -> Value {
  list.reduce(inputs, zero, fn(acc, input) { merge(acc, input.output.value) })
}

pub fn outputs_value(outputs: List<Output>) -> Value {
  list.reduce(outputs, zero, fn(acc, output) { merge(acc, output.value) })
}
