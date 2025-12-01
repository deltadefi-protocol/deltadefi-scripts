use aiken/collection/list
use aiken/primitive/bytearray
use cardano/assets.{Value, from_asset, merge}
use cardano/transaction.{Transaction}
use cocktail/vodka_converter.{convert_int_to_bytes}
use hydra_dex/order_utils.{get_min_order_value}
use hydra_dex/types.{Account, Order, UserAccount}
use mocktail.{
  MocktailTx, complete, mocktail_tx, ref_tx_in, ref_tx_in_inline_datum,
  required_signer_hash, tx_in, tx_in_inline_datum, tx_out, tx_out_inline_datum,
}
use mocktail/virgin_output_reference.{mock_tx_hash}
use tests/utils.{
  mock_account, mock_account_2, mock_account_3, mock_account_4,
  mock_dex_order_book_address, mock_dex_order_book_datum,
  mock_dex_order_book_token, mock_fee_account, mock_hydra_account_address,
  mock_hydra_lovelace, mock_hydra_order_book_address, mock_hydra_token_policy_id,
  mock_hydra_usd, mock_operation_key, mock_order, mock_user_account,
}

pub type TestOrder {
  MarketOrder {
    account: Int,
    is_long: Bool,
    size: Int,
    price_times_1bil: Int,
    fee_amount_bp: Int,
    unfilled_size: Int,
    base_balance: Int,
    quote_balance: Int,
  }
  LimitOrder {
    account: Int,
    is_long: Bool,
    size: Int,
    price_times_1bil: Int,
    fee_amount_bp: Int,
    unfilled_size: Int,
  }
}

pub type OrderConfig {
  account: Int,
  is_long: Bool,
  size: Int,
  price_times_1bil: Int,
  fee_amount_bp: Int,
  unfilled_size: Int,
}

pub type Balance {
  account: Int,
  ada: Int,
  usd: Int,
}

pub type TestCase {
  taker: TestOrder,
  makers: List<TestOrder>,
  payoff: List<Balance>,
}

pub fn mk_base_order(order: Order) -> Pair<Order, Value> {
  Pair(order, get_min_order_value(order, mock_hydra_token_policy_id))
}

pub fn mk_market_order(
  order: Order,
  base_balance: Int,
  quote_balance: Int,
) -> Pair<Order, Value> {
  let order_value =
    mock_hydra_lovelace(base_balance)
      |> merge(mock_hydra_usd(quote_balance))
  Pair(order, order_value)
}

pub fn mk_balance(account: Account, value: Value) -> Pair<UserAccount, Value> {
  Pair(mock_user_account(account), value)
}

pub fn add_order_inputs(
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

pub fn add_order_output(
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

pub fn add_output_balances(
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

pub fn mk_fill_account(index: Int) -> Account {
  if index == 1 {
    mock_account
  } else if index == 2 {
    mock_account_2
  } else if index == 3 {
    mock_account_3
  } else if index == 4 {
    mock_account_4
  } else {
    mock_fee_account
  }
}

pub fn fill_order_test(test_case: TestCase) -> Transaction {
  let TestCase { makers, taker, payoff } = test_case

  let (input_orders, output_order): (
    Pairs<Order, Value>,
    Option<Pair<Order, Value>>,
  ) =
    list.concat([taker], makers)
      |> list.indexed_foldr(
          ([], None),
          fn(i: Int, order: TestOrder, acc) {
            when order is {
              LimitOrder {
                account,
                is_long,
                size,
                price_times_1bil,
                fee_amount_bp,
                unfilled_size,
              } -> {
                let order_id =
                  bytearray.concat("order_", convert_int_to_bytes(i + 1))
                let process_order =
                  fn(size: Int) {
                    mk_base_order(
                      mock_order(
                        order_id,
                        is_long,
                        size,
                        price_times_1bil,
                        fee_amount_bp,
                        mk_fill_account(account),
                      ),
                    )
                  }

                let order_input = process_order(size)

                let unfilled_order =
                  if unfilled_size > 0 {
                    Some(process_order(unfilled_size))
                  } else {
                    acc.2nd
                  }
                (acc.1st |> list.push(order_input), unfilled_order)
              }
              _ -> acc
            }
          },
        )

  let output_balances =
    payoff
      |> list.map(
          fn(b: Balance) {
            mk_balance(
              mk_fill_account(b.account),
              mock_hydra_lovelace(b.ada) |> merge(mock_hydra_usd(b.usd)),
            )
          },
        )

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
    |> required_signer_hash(True, mock_operation_key)
    |> complete()
}
