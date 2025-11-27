use cardano/address.{Script}
use hydra_dex/types.{FillOrder}
use hydra_order_book/core as ob
use tests/hydra_order_book/fill_order/utils.{
  Balance, TestCase, TestOrder, fill_order_test,
} as fill_utils
use tests/utils.{mock_dex_order_book_token, mock_hydra_order_book}

fn run_test(test_case: TestCase) -> Bool {
  let tx = fill_order_test(test_case)
  ob.hydra_order_book.withdraw(
    mock_dex_order_book_token,
    FillOrder { filler_order_id: "order_1" },
    Script(mock_hydra_order_book),
    tx,
  )
}

test s9_fill_order_1_lo_simple() {
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

test s9_fill_order_2_lo_simple() {
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

test s9_fill_order_3_lo_simple() {
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

test s9_fill_order_4_lo_simple() {
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

test s9_fill_order_5_lo_simple() {
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
