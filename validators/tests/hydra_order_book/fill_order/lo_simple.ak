use cardano/address.{Script}
use hydra_dex/types.{FillOrder}
use hydra_order_book/core as ob
use tests/hydra_order_book/fill_order/utils.{
  Balance, LimitOrder, TestCase, fill_order_test,
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
      taker: LimitOrder {
        account: 1,
        is_long: True,
        size: 100000000,
        price_times_1bil: 1000000000,
        fee_amount_bp: 10,
        unfilled_size: 0,
      },
      makers: [
        LimitOrder {
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
      taker: LimitOrder {
        account: 1,
        is_long: False,
        size: 100000000,
        price_times_1bil: 1000000000,
        fee_amount_bp: 10,
        unfilled_size: 0,
      },
      makers: [
        LimitOrder {
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
      taker: LimitOrder {
        account: 1,
        is_long: True,
        size: 100000000,
        price_times_1bil: 1000000000,
        fee_amount_bp: 10,
        unfilled_size: 0,
      },
      makers: [
        LimitOrder {
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
      taker: LimitOrder {
        account: 1,
        is_long: False,
        size: 100000000,
        price_times_1bil: 1000000000,
        fee_amount_bp: 10,
        unfilled_size: 0,
      },
      makers: [
        LimitOrder {
          account: 2,
          is_long: True,
          size: 120000000,
          price_times_1bil: 1200000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 100000, usd: 120000 },
        Balance { account: 1, ada: 0, usd: 119880000 },
        Balance { account: 2, ada: 99900000, usd: 0 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_5_lo_simple() {
  let test_case =
    TestCase {
      taker: LimitOrder {
        account: 1,
        is_long: True,
        size: 120000000,
        price_times_1bil: 1200000000,
        fee_amount_bp: 10,
        unfilled_size: 0,
      },
      makers: [
        LimitOrder {
          account: 2,
          is_long: False,
          size: 200000000,
          price_times_1bil: 1200000000,
          fee_amount_bp: 10,
          unfilled_size: 100000000,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 100000, usd: 120000 },
        Balance { account: 1, ada: 99900000, usd: 0 },
        Balance { account: 2, ada: 0, usd: 119880000 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_6_lo_simple() {
  let test_case =
    TestCase {
      taker: LimitOrder {
        account: 1,
        is_long: False,
        size: 100000000,
        price_times_1bil: 1000000000,
        fee_amount_bp: 10,
        unfilled_size: 0,
      },
      makers: [
        LimitOrder {
          account: 2,
          is_long: True,
          size: 240000000,
          price_times_1bil: 1200000000,
          fee_amount_bp: 10,
          unfilled_size: 120000000,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 100000, usd: 120000 },
        Balance { account: 1, ada: 0, usd: 119880000 },
        Balance { account: 2, ada: 99900000, usd: 0 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_7_lo_simple() {
  let test_case =
    TestCase {
      taker: LimitOrder {
        account: 1,
        is_long: True,
        size: 240000000,
        price_times_1bil: 1200000000,
        fee_amount_bp: 10,
        unfilled_size: 120000000,
      },
      makers: [
        LimitOrder {
          account: 2,
          is_long: False,
          size: 100000000,
          price_times_1bil: 1100000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 100000, usd: 110000 },
        Balance { account: 1, ada: 99900000, usd: 10000000 },
        Balance { account: 2, ada: 0, usd: 109890000 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_8_lo_simple() {
  let test_case =
    TestCase {
      taker: LimitOrder {
        account: 1,
        is_long: False,
        size: 200000000,
        price_times_1bil: 1000000000,
        fee_amount_bp: 10,
        unfilled_size: 100000000,
      },
      makers: [
        LimitOrder {
          account: 2,
          is_long: True,
          size: 110000000,
          price_times_1bil: 1100000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 100000, usd: 110000 },
        Balance { account: 1, ada: 0, usd: 109890000 },
        Balance { account: 2, ada: 99900000, usd: 0 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_9_lo_simple() {
  let test_case =
    TestCase {
      taker: LimitOrder {
        account: 1,
        is_long: True,
        size: 332578596,
        price_times_1bil: 1251700000,
        fee_amount_bp: 10,
        unfilled_size: 0,
      },
      makers: [
        LimitOrder {
          account: 2,
          is_long: False,
          size: 523523579,
          price_times_1bil: 1135300000,
          fee_amount_bp: 10,
          unfilled_size: 257822056,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 265701, usd: 301650 },
        Balance { account: 1, ada: 265435822, usd: 30927657 },
        Balance { account: 2, ada: 0, usd: 301349289 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_10_lo_simple() {
  let test_case =
    TestCase {
      taker: LimitOrder {
        account: 1,
        is_long: False,
        size: 223578901,
        price_times_1bil: 1025900000,
        fee_amount_bp: 10,
        unfilled_size: 0,
      },
      makers: [
        LimitOrder {
          account: 2,
          is_long: True,
          size: 582111037,
          price_times_1bil: 1111100000,
          fee_amount_bp: 10,
          unfilled_size: 333692520,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 223578, usd: 248418 },
        Balance { account: 1, ada: 0, usd: 248170099 },
        Balance { account: 2, ada: 223355323, usd: 0 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_11_lo_simple() {
  let test_case =
    TestCase {
      taker: LimitOrder {
        account: 1,
        is_long: True,
        size: 340435886,
        price_times_1bil: 1523100000,
        fee_amount_bp: 10,
        unfilled_size: 51781187,
      },
      makers: [
        LimitOrder {
          account: 2,
          is_long: False,
          size: 189517891,
          price_times_1bil: 1111300000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 189517, usd: 210611 },
        Balance { account: 1, ada: 189328374, usd: 78043467 },
        Balance { account: 2, ada: 0, usd: 210400621 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_12_lo_simple() {
  let test_case =
    TestCase {
      taker: LimitOrder {
        account: 1,
        is_long: False,
        size: 223578915,
        price_times_1bil: 1512100000,
        fee_amount_bp: 10,
        unfilled_size: 99813002,
      },
      makers: [
        LimitOrder {
          account: 2,
          is_long: True,
          size: 238336018,
          price_times_1bil: 1925700000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 123765, usd: 238336 },
        Balance { account: 1, ada: 1, usd: 238097682 },
        Balance { account: 2, ada: 123642147, usd: 0 },
      ],
    }
  run_test(test_case)
}
