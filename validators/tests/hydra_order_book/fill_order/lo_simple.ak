use aiken/collection/list
use aiken/primitive/bytearray
use cardano/address.{Script}
use cardano/assets.{Value, from_asset, merge}
use cardano/transaction.{Transaction}
use cocktail.{convert_int_to_bytes}
use hydra_dex/types.{Account, FillOrder, Order}
use hydra_order_book/core as ob
use mocktail.{
  complete, mock_tx_hash, mocktail_tx, ref_tx_in, ref_tx_in_inline_datum,
  required_signer_hash,
}
use tests/hydra_order_book/fill_order/base.{
  add_order_inputs, add_order_output, add_output_balances, mk_balance,
  mk_base_order,
}
use tests/utils.{
  mock_account, mock_account_2, mock_account_3, mock_account_4,
  mock_dex_order_book_address, mock_dex_order_book_datum,
  mock_dex_order_book_token, mock_fee_account, mock_hydra_lovelace,
  mock_hydra_order_book, mock_hydra_usd, mock_operation_key, mock_order,
}

fn run_test(test_case: TestCase) -> Bool {
  let tx = fill_order_test(test_case)
  ob.hydra_order_book.withdraw(
    mock_dex_order_book_token,
    FillOrder { filler_order_id: "order_1" },
    Script(mock_hydra_order_book),
    tx,
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

fn fill_order_test(test_case: TestCase) -> Transaction {
  let TestCase { makers, taker, payoff } = test_case

  let (input_orders, output_order): (
    Pairs<Order, Value>,
    Option<Pair<Order, Value>>,
  ) =
    list.concat([taker], makers)
      |> list.indexed_foldr(
          ([], None),
          fn(i: Int, maker: TestOrder, acc) {
            let order_id =
              bytearray.concat("order_", convert_int_to_bytes(i + 1))
            let process_order =
              fn(size: Int) {
                mk_base_order(
                  mock_order(
                    order_id,
                    maker.is_long,
                    size,
                    maker.price_times_1bil,
                    maker.fee_amount_bp,
                    mk_fill_account(maker.account),
                  ),
                )
              }

            let order_input = process_order(maker.size)

            let unfilled_order =
              if maker.unfilled_size > 0 {
                Some(process_order(maker.unfilled_size))
              } else {
                acc.2nd
              }
            (acc.1st |> list.push(order_input), unfilled_order)
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

type TestOrder {
  account: Int,
  is_long: Bool,
  size: Int,
  price_times_1bil: Int,
  fee_amount_bp: Int,
  unfilled_size: Int,
}

type Balance {
  account: Int,
  ada: Int,
  usd: Int,
}

type TestCase {
  taker: TestOrder,
  makers: List<TestOrder>,
  payoff: List<Balance>,
}

test s9_w_lo_simple_1() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_long: True,
        size: 100000000,
        price_times_1bil: 1000000000,
        fee_amount_bp: 10,
        unfilled_size: 0,
      },
      makers: [
        TestOrder {
          account: 2,
          is_long: False,
          size: 100000000,
          price_times_1bil: 1000000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 100000, usd: 100000 },
        Balance { account: 1, ada: 99900000, usd: 0 },
        Balance { account: 2, ada: 0, usd: 99900000 },
      ],
    }
  run_test(test_case)
}

test s9_w_lo_simple_2() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_long: False,
        size: 100000000,
        price_times_1bil: 1000000000,
        fee_amount_bp: 10,
        unfilled_size: 0,
      },
      makers: [
        TestOrder {
          account: 2,
          is_long: True,
          size: 100000000,
          price_times_1bil: 1000000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 100000, usd: 100000 },
        Balance { account: 1, ada: 0, usd: 99900000 },
        Balance { account: 2, ada: 99900000, usd: 0 },
      ],
    }
  run_test(test_case)
}

test s9_w_lo_simple_3() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_long: True,
        size: 100000000,
        price_times_1bil: 1000000000,
        fee_amount_bp: 10,
        unfilled_size: 0,
      },
      makers: [
        TestOrder {
          account: 2,
          is_long: False,
          size: 100000000,
          price_times_1bil: 800000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 100000, usd: 80000 },
        Balance { account: 1, ada: 99900000, usd: 20000000 },
        Balance { account: 2, ada: 0, usd: 79920000 },
      ],
    }
  run_test(test_case)
}

test s9_w_lo_simple_4() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_long: False,
        size: 100000000,
        price_times_1bil: 1000000000,
        fee_amount_bp: 10,
        unfilled_size: 16666667,
      },
      makers: [
        TestOrder {
          account: 2,
          is_long: True,
          size: 100000000,
          price_times_1bil: 1200000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 83333, usd: 100000 },
        Balance { account: 1, ada: 0, usd: 99900000 },
        Balance { account: 2, ada: 83250000, usd: 0 },
      ],
    }
  run_test(test_case)
}

test s9_w_lo_simple_5() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_long: True,
        size: 100000000,
        price_times_1bil: 1200000000,
        fee_amount_bp: 10,
        unfilled_size: 0,
      },
      makers: [
        TestOrder {
          account: 2,
          is_long: False,
          size: 100000000,
          price_times_1bil: 1200000000,
          fee_amount_bp: 10,
          unfilled_size: 16666667,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 83333, usd: 99999 },
        Balance { account: 1, ada: 83250000, usd: 1 },
        Balance { account: 2, ada: 0, usd: 99900000 },
      ],
    }
  run_test(test_case)
}
