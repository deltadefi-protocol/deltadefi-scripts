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

test s9_fill_order_16_lo_multiple() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_long: True,
        size: 300000000,
        price_times_1bil: 1200000000,
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
        TestOrder {
          account: 2,
          is_long: False,
          size: 100000000,
          price_times_1bil: 1100000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
        TestOrder {
          account: 2,
          is_long: False,
          size: 50000000,
          price_times_1bil: 800000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 250000, usd: 250000 },
        Balance { account: 1, ada: 249750000, usd: 50000000 },
        Balance { account: 2, ada: 0, usd: 99900000 },
        Balance { account: 2, ada: 0, usd: 109890000 },
        Balance { account: 2, ada: 0, usd: 39960000 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_17_lo_multiple() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_long: False,
        size: 300000000,
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
        TestOrder {
          account: 2,
          is_long: True,
          size: 200000000,
          price_times_1bil: 2000000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
        TestOrder {
          account: 2,
          is_long: True,
          size: 400000000,
          price_times_1bil: 4000000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 300000, usd: 700000 },
        Balance { account: 1, ada: 0, usd: 699300000 },
        Balance { account: 2, ada: 99900000, usd: 0 },
        Balance { account: 2, ada: 99900000, usd: 0 },
        Balance { account: 2, ada: 99900000, usd: 0 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_18_lo_multiple() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_long: True,
        size: 250000000,
        price_times_1bil: 1200000000,
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
        TestOrder {
          account: 2,
          is_long: False,
          size: 100000000,
          price_times_1bil: 1100000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
        TestOrder {
          account: 2,
          is_long: False,
          size: 100000000,
          price_times_1bil: 1200000000,
          fee_amount_bp: 10,
          unfilled_size: 91666667,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 208333, usd: 219999 },
        Balance { account: 1, ada: 208125000, usd: 30000001 },
        Balance { account: 2, ada: 0, usd: 99900000 },
        Balance { account: 2, ada: 0, usd: 109890000 },
        Balance { account: 2, ada: 0, usd: 9990000 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_19_lo_multiple() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_long: False,
        size: 200000000,
        price_times_1bil: 1200000000,
        fee_amount_bp: 10,
        unfilled_size: 0,
      },
      makers: [
        TestOrder {
          account: 2,
          is_long: True,
          size: 100000000,
          price_times_1bil: 1400000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
        TestOrder {
          account: 2,
          is_long: True,
          size: 100000000,
          price_times_1bil: 1300000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
        TestOrder {
          account: 2,
          is_long: True,
          size: 100000000,
          price_times_1bil: 1200000000,
          fee_amount_bp: 10,
          unfilled_size: 38021976,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 199999, usd: 261978 },
        Balance { account: 1, ada: 0, usd: 261716046 },
        Balance { account: 2, ada: 71357143, usd: 0 },
        Balance { account: 2, ada: 76846153, usd: 0 },
        Balance { account: 2, ada: 51596705, usd: 0 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_20_lo_multiple() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_long: True,
        size: 400000000,
        price_times_1bil: 1200000000,
        fee_amount_bp: 10,
        unfilled_size: 99999999,
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
        TestOrder {
          account: 2,
          is_long: False,
          size: 100000000,
          price_times_1bil: 1100000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
        TestOrder {
          account: 2,
          is_long: False,
          size: 50000000,
          price_times_1bil: 1200000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 250000, usd: 270000 },
        Balance { account: 1, ada: 249750000, usd: 30000001 },
        Balance { account: 2, ada: 0, usd: 99900000 },
        Balance { account: 2, ada: 0, usd: 109890000 },
        Balance { account: 2, ada: 0, usd: 59940000 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_21_lo_multiple() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_long: False,
        size: 300000000,
        price_times_1bil: 1200000000,
        fee_amount_bp: 10,
        unfilled_size: 109981687,
      },
      makers: [
        TestOrder {
          account: 2,
          is_long: True,
          size: 100000000,
          price_times_1bil: 1400000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
        TestOrder {
          account: 2,
          is_long: True,
          size: 100000000,
          price_times_1bil: 1300000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
        TestOrder {
          account: 2,
          is_long: True,
          size: 50000000,
          price_times_1bil: 1200000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 190017, usd: 250000 },
        Balance { account: 1, ada: 0, usd: 249750000 },
        Balance { account: 2, ada: 71357143, usd: 0 },
        Balance { account: 2, ada: 76846153, usd: 0 },
        Balance { account: 2, ada: 41625000, usd: 0 },
      ],
    }
  run_test(test_case)
}
