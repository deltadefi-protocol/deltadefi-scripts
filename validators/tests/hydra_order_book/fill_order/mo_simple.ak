use cardano/address.{Script}
use hydra_dex/types.{FillOrder}
use hydra_order_book/core as ob
use tests/hydra_order_book/fill_order/utils.{
  Balance, TestCase, TestOrder, fill_order_test,
} as test_utils
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

test s9_fill_order_6_mo_simple() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_long: True,
        size: 100000000,
        price_times_1bil: 800000000,
        fee_amount_bp: 10,
        unfilled_size: 20000000,
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
        Balance { account: 1, ada: 99900000, usd: 0 },
        Balance { account: 2, ada: 0, usd: 79920000 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_7_mo_simple() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_long: False,
        size: 100000000,
        price_times_1bil: 1200000000,
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

test s9_fill_order_8_mo_simple() {
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

test s9_fill_order_9_mo_simple() {
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

test s9_fill_order_10_mo_simple() {
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

test s9_fill_order_11_mo_simple() {
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

test s9_fill_order_12_mo_simple() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_long: True,
        size: 50000000,
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
          unfilled_size: 50000000,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 50000, usd: 50000 },
        Balance { account: 1, ada: 49950000, usd: 0 },
        Balance { account: 2, ada: 0, usd: 49950000 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_13_mo_simple() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_long: False,
        size: 50000000,
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
          unfilled_size: 50000000,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 50000, usd: 50000 },
        Balance { account: 1, ada: 0, usd: 49950000 },
        Balance { account: 2, ada: 49950000, usd: 0 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_14_mo_simple() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_long: True,
        size: 500000000,
        price_times_1bil: 1200000000,
        fee_amount_bp: 10,
        unfilled_size: 109999999,
      },
      makers: [
        TestOrder {
          account: 2,
          is_long: False,
          size: 450000000,
          price_times_1bil: 1223000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 325000, usd: -7077524 },
        Balance { account: 1, ada: 324675000, usd: 0 },
        Balance { account: 2, ada: 0, usd: 397077525 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_15_mo_simple() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_long: False,
        size: 500000000,
        price_times_1bil: 1200000000,
        fee_amount_bp: 10,
        unfilled_size: 145872270,
      },
      makers: [
        TestOrder {
          account: 2,
          is_long: True,
          size: 450000000,
          price_times_1bil: 1235000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 354127, usd: 437347 },
        Balance { account: 1, ada: 0, usd: 436910400 },
        Balance { account: 2, ada: 353773603, usd: 0 },
      ],
    }
  run_test(test_case)
}
