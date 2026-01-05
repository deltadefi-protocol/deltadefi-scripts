use cardano/address.{Script}
use hydra_dex/types.{FillOrder, LimitOrder}
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
        is_buy: True,
        size: 100000000,
        price_times_1tri: 1000000000000,
        fee_amount_bp: 10,
        unfilled_size: 0,
        base_balance: 0,
        quote_balance: 100000000,
        order_type: LimitOrder,
      },
      makers: [
        TestOrder {
          account: 2,
          is_buy: False,
          size: 100000000,
          price_times_1tri: 1000000000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 100000000,
          quote_balance: 0,
          order_type: LimitOrder,
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
        is_buy: False,
        size: 100000000,
        price_times_1tri: 1000000000000,
        fee_amount_bp: 10,
        unfilled_size: 0,
        base_balance: 100000000,
        quote_balance: 0,
        order_type: LimitOrder,
      },
      makers: [
        TestOrder {
          account: 2,
          is_buy: True,
          size: 100000000,
          price_times_1tri: 1000000000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 0,
          quote_balance: 100000000,
          order_type: LimitOrder,
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
        is_buy: True,
        size: 100000000,
        price_times_1tri: 1000000000000,
        fee_amount_bp: 10,
        unfilled_size: 0,
        base_balance: 0,
        quote_balance: 100000000,
        order_type: LimitOrder,
      },
      makers: [
        TestOrder {
          account: 2,
          is_buy: False,
          size: 100000000,
          price_times_1tri: 800000000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 100000000,
          quote_balance: 0,
          order_type: LimitOrder,
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
        is_buy: False,
        size: 100000000,
        price_times_1tri: 1000000000000,
        fee_amount_bp: 10,
        unfilled_size: 0,
        base_balance: 100000000,
        quote_balance: 0,
        order_type: LimitOrder,
      },
      makers: [
        TestOrder {
          account: 2,
          is_buy: True,
          size: 120000000,
          price_times_1tri: 1200000000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 0,
          quote_balance: 120000000,
          order_type: LimitOrder,
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
      taker: TestOrder {
        account: 1,
        is_buy: True,
        size: 120000000,
        price_times_1tri: 1200000000000,
        fee_amount_bp: 10,
        unfilled_size: 0,
        base_balance: 0,
        quote_balance: 120000000,
        order_type: LimitOrder,
      },
      makers: [
        TestOrder {
          account: 2,
          is_buy: False,
          size: 200000000,
          price_times_1tri: 1200000000000,
          fee_amount_bp: 10,
          unfilled_size: 100000000,
          base_balance: 200000000,
          quote_balance: 0,
          order_type: LimitOrder,
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
      taker: TestOrder {
        account: 1,
        is_buy: False,
        size: 100000000,
        price_times_1tri: 1000000000000,
        fee_amount_bp: 10,
        unfilled_size: 0,
        base_balance: 100000000,
        quote_balance: 0,
        order_type: LimitOrder,
      },
      makers: [
        TestOrder {
          account: 2,
          is_buy: True,
          size: 240000000,
          price_times_1tri: 1200000000000,
          fee_amount_bp: 10,
          unfilled_size: 120000000,
          base_balance: 0,
          quote_balance: 240000000,
          order_type: LimitOrder,
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
      taker: TestOrder {
        account: 1,
        is_buy: True,
        size: 240000000,
        price_times_1tri: 1200000000000,
        fee_amount_bp: 10,
        unfilled_size: 120000000,
        base_balance: 0,
        quote_balance: 240000000,
        order_type: LimitOrder,
      },
      makers: [
        TestOrder {
          account: 2,
          is_buy: False,
          size: 100000000,
          price_times_1tri: 1100000000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 100000000,
          quote_balance: 0,
          order_type: LimitOrder,
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
      taker: TestOrder {
        account: 1,
        is_buy: False,
        size: 200000000,
        price_times_1tri: 1000000000000,
        fee_amount_bp: 10,
        unfilled_size: 100000000,
        base_balance: 200000000,
        quote_balance: 0,
        order_type: LimitOrder,
      },
      makers: [
        TestOrder {
          account: 2,
          is_buy: True,
          size: 110000000,
          price_times_1tri: 1100000000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 0,
          quote_balance: 110000000,
          order_type: LimitOrder,
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
      taker: TestOrder {
        account: 1,
        is_buy: True,
        size: 332578596,
        price_times_1tri: 1251700000000,
        fee_amount_bp: 10,
        unfilled_size: 0,
        base_balance: 0,
        quote_balance: 332578596,
        order_type: LimitOrder,
      },
      makers: [
        TestOrder {
          account: 2,
          is_buy: False,
          size: 523523579,
          price_times_1tri: 1135300000000,
          fee_amount_bp: 10,
          unfilled_size: 257822056,
          base_balance: 523523579,
          quote_balance: 0,
          order_type: LimitOrder,
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
      taker: TestOrder {
        account: 1,
        is_buy: False,
        size: 223578901,
        price_times_1tri: 1025900000000,
        fee_amount_bp: 10,
        unfilled_size: 0,
        base_balance: 223578901,
        quote_balance: 0,
        order_type: LimitOrder,
      },
      makers: [
        TestOrder {
          account: 2,
          is_buy: True,
          size: 582111037,
          price_times_1tri: 1111100000000,
          fee_amount_bp: 10,
          unfilled_size: 333692520,
          base_balance: 0,
          quote_balance: 582111037,
          order_type: LimitOrder,
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
      taker: TestOrder {
        account: 1,
        is_buy: True,
        size: 340435886,
        price_times_1tri: 1523100000000,
        fee_amount_bp: 10,
        unfilled_size: 51781187,
        base_balance: 0,
        quote_balance: 340435886,
        order_type: LimitOrder,
      },
      makers: [
        TestOrder {
          account: 2,
          is_buy: False,
          size: 189517891,
          price_times_1tri: 1111300000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 189517891,
          quote_balance: 0,
          order_type: LimitOrder,
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
      taker: TestOrder {
        account: 1,
        is_buy: False,
        size: 223578915,
        price_times_1tri: 1512100000000,
        fee_amount_bp: 10,
        unfilled_size: 99813002,
        base_balance: 223578915,
        quote_balance: 0,
        order_type: LimitOrder,
      },
      makers: [
        TestOrder {
          account: 2,
          is_buy: True,
          size: 238336018,
          price_times_1tri: 1925700000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 0,
          quote_balance: 238336018,
          order_type: LimitOrder,
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

test s9_fill_order_13_lo_simple() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_buy: True,
        size: 100000000,
        price_times_1tri: 10000000,
        fee_amount_bp: 10,
        unfilled_size: 18595723,
        base_balance: 0,
        quote_balance: 100000000,
        order_type: LimitOrder,
      },
      makers: [
        TestOrder {
          account: 1,
          is_buy: False,
          size: 1000000000000,
          price_times_1tri: 10000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 1000000000000,
          quote_balance: 0,
          order_type: LimitOrder,
        },
        TestOrder {
          account: 1,
          is_buy: False,
          size: 7140427670000,
          price_times_1tri: 10000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 7140427670000,
          quote_balance: 0,
          order_type: LimitOrder,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 8140427670, usd: 81404 },
        Balance { account: 1, ada: 8132287242330, usd: 81322873 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_14_lo_simple() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_buy: True,
        size: 100000000,
        price_times_1tri: 10000000,
        fee_amount_bp: 10,
        unfilled_size: 18595723,
        base_balance: 0,
        quote_balance: 100000000,
        order_type: LimitOrder,
      },
      makers: [
        TestOrder {
          account: 1,
          is_buy: False,
          size: 1000000000000,
          price_times_1tri: 10000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 1000000000000,
          quote_balance: 0,
          order_type: LimitOrder,
        },
        TestOrder {
          account: 1,
          is_buy: False,
          size: 7140427670000,
          price_times_1tri: 10000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 7140427670000,
          quote_balance: 0,
          order_type: LimitOrder,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 8140427670, usd: 81404 },
        Balance { account: 1, ada: 8132287242330, usd: 81322873 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_15_lo_simple() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_buy: True,
        size: 5000000,
        price_times_1tri: 1000000,
        fee_amount_bp: 10,
        unfilled_size: 0,
        base_balance: 0,
        quote_balance: 5000000,
        order_type: LimitOrder,
      },
      makers: [
        TestOrder {
          account: 2,
          is_buy: False,
          size: 1000000000000,
          price_times_1tri: 1000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 1000000000000,
          quote_balance: 0,
          order_type: LimitOrder,
        },
        TestOrder {
          account: 3,
          is_buy: False,
          size: 1000000000000,
          price_times_1tri: 1000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 1000000000000,
          quote_balance: 0,
          order_type: LimitOrder,
        },
        TestOrder {
          account: 4,
          is_buy: False,
          size: 1000000000000,
          price_times_1tri: 1000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 1000000000000,
          quote_balance: 0,
          order_type: LimitOrder,
        },
        TestOrder {
          account: 2,
          is_buy: False,
          size: 1000000000000,
          price_times_1tri: 1000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 1000000000000,
          quote_balance: 0,
          order_type: LimitOrder,
        },
        TestOrder {
          account: 3,
          is_buy: False,
          size: 1000000000000,
          price_times_1tri: 1000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 1000000000000,
          quote_balance: 0,
          order_type: LimitOrder,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 5000000000, usd: 5000 },
        Balance { account: 1, ada: 4995000000000, usd: 0 },
        Balance { account: 2, ada: 0, usd: 1998000 },
        Balance { account: 3, ada: 0, usd: 1998000 },
        Balance { account: 4, ada: 0, usd: 999000 },
      ],
    }
  run_test(test_case)
}
