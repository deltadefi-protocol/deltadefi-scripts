use aiken/collection/list
use cardano/address.{Script}
use cardano/assets.{Value, from_asset, merge, zero}
use cardano/transaction.{Transaction}
use hydra_dex/order_utils.{get_min_order_value}
use hydra_dex/types.{Account, FillOrder, Order, UserAccount, UserSpotAccount}
use hydra_order_book/core as ob
use mocktail.{
  MocktailTx, complete, mock_pub_key_address, mock_tx_hash, mocktail_tx,
  ref_tx_in, ref_tx_in_inline_datum, required_signer_hash, tx_in,
  tx_in_inline_datum, tx_out, tx_out_inline_datum,
}
use tests/utils.{
  mock_account, mock_account_2, mock_dex_order_book_address,
  mock_dex_order_book_datum, mock_dex_order_book_token, mock_fee_account,
  mock_hydra_account_address, mock_hydra_lovelace, mock_hydra_order_book,
  mock_hydra_order_book_address, mock_hydra_token_policy_id, mock_hydra_usd,
  mock_operation_key, mock_order,
}

type TestCase {
  input_orders: Pairs<Order, Value>,
  output_order: Option<Pair<Order, Value>>,
  output_balances: Pairs<UserAccount, Value>,
  without_other_inputs: Bool,
  without_other_outputs: Bool,
  is_fill_order_authorized: Bool,
}

fn mk_base_order(order: Order) -> Pair<Order, Value> {
  Pair(order, get_min_order_value(order, mock_hydra_token_policy_id))
}

fn mk_balance(account: Account, value: Value) -> Pair<UserAccount, Value> {
  Pair(UserSpotAccount { account }, value)
}

fn add_order_inputs(
  mock_tx: MocktailTx,
  input_orders: Pairs<Order, Value>,
) -> MocktailTx {
  list.foldr(
    input_orders,
    mock_tx,
    fn(Pair(order, value), tx) {
      tx
        |> tx_in(True, mock_tx_hash(0), 0, value, mock_hydra_order_book_address)
        |> tx_in_inline_datum(True, order)
    },
  )
}

fn add_order_output(
  mock_tx: MocktailTx,
  output_order: Option<Pair<Order, Value>>,
) -> MocktailTx {
  when output_order is {
    Some(Pair(order, value)) ->
      mock_tx
        |> tx_out(True, mock_hydra_order_book_address, value)
        |> tx_out_inline_datum(True, order)
    None -> mock_tx
  }
}

fn add_output_balances(
  mock_tx: MocktailTx,
  output_balances: Pairs<UserAccount, Value>,
) -> MocktailTx {
  list.foldr(
    output_balances,
    mock_tx,
    fn(Pair(account, value), tx) {
      tx
        |> tx_out(True, mock_hydra_account_address, value)
        |> tx_out_inline_datum(True, account)
    },
  )
}

fn mock_tx(test_case: TestCase) -> Transaction {
  let TestCase {
    input_orders,
    output_order,
    output_balances,
    without_other_inputs,
    without_other_outputs,
    is_fill_order_authorized,
  } = test_case

  mocktail_tx()
    |> add_order_inputs(input_orders)
    |> add_order_output(output_order)
    |> add_output_balances(output_balances)
    |> ref_tx_in(
        True,
        mock_tx_hash(0),
        0,
        from_asset(mock_dex_order_book_token, "", 1),
        mock_dex_order_book_address,
      )
    |> ref_tx_in_inline_datum(True, mock_dex_order_book_datum)
    |> required_signer_hash(is_fill_order_authorized, mock_operation_key)
    // fail case
    |> tx_in(
        !without_other_inputs,
        mock_tx_hash(2),
        0,
        zero,
        mock_pub_key_address(10, None),
      )
    |> tx_out(!without_other_outputs, mock_pub_key_address(10, None), zero)
    |> complete()
}

fn base_case() {
  let order_1 =
    mock_order("order_1", False, 250_000_000, 1_000_000_000, 10, mock_account)
  let order_2 =
    mock_order("order_2", True, 250_000_000, 1_000_000_000, 10, mock_account_2)

  let output_balances =
    [
      mk_balance(mock_account, mock_hydra_usd(249_750_000)),
      mk_balance(mock_account_2, mock_hydra_lovelace(249_750_000)),
      mk_balance(
        mock_fee_account,
        mock_hydra_usd(250_000) |> merge(mock_hydra_lovelace(250_000)),
      ),
    ]

  (order_1, order_2, output_balances)
}

test s9_wfo_success() {
  let (order_1, order_2, output_balances) = base_case()

  let tx =
    mock_tx(
      TestCase {
        input_orders: [mk_base_order(order_1), mk_base_order(order_2)],
        output_order: None,
        output_balances,
        without_other_inputs: True,
        without_other_outputs: True,
        is_fill_order_authorized: True,
      },
    )
  ob.hydra_order_book.withdraw(
    mock_dex_order_book_token,
    FillOrder { filler_order_id: "order_1" },
    Script(mock_hydra_order_book),
    tx,
  )
}

test s9_wfo_fail_with_other_inputs() {
  let (order_1, order_2, output_balances) = base_case()

  let tx =
    mock_tx(
      TestCase {
        input_orders: [mk_base_order(order_1), mk_base_order(order_2)],
        output_order: None,
        output_balances,
        without_other_inputs: False,
        without_other_outputs: True,
        is_fill_order_authorized: True,
      },
    )
  !ob.hydra_order_book.withdraw(
    mock_dex_order_book_token,
    FillOrder { filler_order_id: "order_1" },
    Script(mock_hydra_order_book),
    tx,
  )
}

test s9_wfo_fail_with_other_outputs() {
  let (order_1, order_2, output_balances) = base_case()

  let tx =
    mock_tx(
      TestCase {
        input_orders: [mk_base_order(order_1), mk_base_order(order_2)],
        output_order: None,
        output_balances,
        without_other_inputs: True,
        without_other_outputs: False,
        is_fill_order_authorized: True,
      },
    )
  !ob.hydra_order_book.withdraw(
    mock_dex_order_book_token,
    FillOrder { filler_order_id: "order_1" },
    Script(mock_hydra_order_book),
    tx,
  )
}

test s9_wfo_fail_without_key() {
  let (order_1, order_2, output_balances) = base_case()

  let tx =
    mock_tx(
      TestCase {
        input_orders: [mk_base_order(order_1), mk_base_order(order_2)],
        output_order: None,
        output_balances,
        without_other_inputs: True,
        without_other_outputs: True,
        is_fill_order_authorized: False,
      },
    )
  !ob.hydra_order_book.withdraw(
    mock_dex_order_book_token,
    FillOrder { filler_order_id: "order_1" },
    Script(mock_hydra_order_book),
    tx,
  )
}
