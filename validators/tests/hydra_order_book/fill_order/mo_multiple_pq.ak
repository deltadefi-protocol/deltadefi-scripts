use cardano/address.{Script}
use hydra_dex/types.{FillOrder, LimitOrder, MarketOrder}
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

test s9_fill_order_61_mo_multiple_pq() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_buy: True,
        size: 300000000,
        price_times_1bil: 1200000000,
        fee_amount_bp: 10,
        unfilled_size: 0,
        base_balance: 0,
        quote_balance: 540000000,
        order_type: MarketOrder,
      },
      makers: [
        TestOrder {
          account: 2,
          is_buy: False,
          size: 100000000,
          price_times_1bil: 1200000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 100000000,
          quote_balance: 0,
          order_type: LimitOrder,
        },
        TestOrder {
          account: 3,
          is_buy: False,
          size: 100000000,
          price_times_1bil: 1300000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 100000000,
          quote_balance: 0,
          order_type: LimitOrder,
        },
        TestOrder {
          account: 4,
          is_buy: False,
          size: 100000000,
          price_times_1bil: 1400000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 100000000,
          quote_balance: 0,
          order_type: LimitOrder,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 300000, usd: 390000 },
        Balance { account: 1, ada: 299700000, usd: 150000000 },
        Balance { account: 2, ada: 0, usd: 119880000 },
        Balance { account: 3, ada: 0, usd: 129870000 },
        Balance { account: 4, ada: 0, usd: 139860000 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_62_mo_multiple_pq() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_buy: False,
        size: 330000000,
        price_times_1bil: 1200000000,
        fee_amount_bp: 10,
        unfilled_size: 0,
        base_balance: 550000000,
        quote_balance: 0,
        order_type: MarketOrder,
      },
      makers: [
        TestOrder {
          account: 2,
          is_buy: True,
          size: 120000000,
          price_times_1bil: 1200000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 0,
          quote_balance: 120000000,
          order_type: LimitOrder,
        },
        TestOrder {
          account: 3,
          is_buy: True,
          size: 110000000,
          price_times_1bil: 1100000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 0,
          quote_balance: 110000000,
          order_type: LimitOrder,
        },
        TestOrder {
          account: 4,
          is_buy: True,
          size: 100000000,
          price_times_1bil: 1000000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 0,
          quote_balance: 100000000,
          order_type: LimitOrder,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 300000, usd: 330000 },
        Balance { account: 1, ada: 250000000, usd: 329670000 },
        Balance { account: 2, ada: 99900000, usd: 0 },
        Balance { account: 3, ada: 99900000, usd: 0 },
        Balance { account: 4, ada: 99900000, usd: 0 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_63_mo_multiple_pq() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_buy: True,
        size: 300000000,
        price_times_1bil: 1200000000,
        fee_amount_bp: 10,
        unfilled_size: 0,
        base_balance: 0,
        quote_balance: 540000000,
        order_type: MarketOrder,
      },
      makers: [
        TestOrder {
          account: 2,
          is_buy: False,
          size: 100000000,
          price_times_1bil: 1200000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 100000000,
          quote_balance: 0,
          order_type: LimitOrder,
        },
        TestOrder {
          account: 3,
          is_buy: False,
          size: 100000000,
          price_times_1bil: 1300000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 100000000,
          quote_balance: 0,
          order_type: LimitOrder,
        },
        TestOrder {
          account: 4,
          is_buy: False,
          size: 150000000,
          price_times_1bil: 1400000000,
          fee_amount_bp: 10,
          unfilled_size: 50000000,
          base_balance: 150000000,
          quote_balance: 0,
          order_type: LimitOrder,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 300000, usd: 390000 },
        Balance { account: 1, ada: 299700000, usd: 150000000 },
        Balance { account: 2, ada: 0, usd: 119880000 },
        Balance { account: 3, ada: 0, usd: 129870000 },
        Balance { account: 4, ada: 0, usd: 139860000 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_64_mo_multiple_pq() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_buy: False,
        size: 330000000,
        price_times_1bil: 1200000000,
        fee_amount_bp: 10,
        unfilled_size: 0,
        base_balance: 550000000,
        quote_balance: 0,
        order_type: MarketOrder,
      },
      makers: [
        TestOrder {
          account: 2,
          is_buy: True,
          size: 120000000,
          price_times_1bil: 1200000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 0,
          quote_balance: 120000000,
          order_type: LimitOrder,
        },
        TestOrder {
          account: 3,
          is_buy: True,
          size: 110000000,
          price_times_1bil: 1100000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 0,
          quote_balance: 110000000,
          order_type: LimitOrder,
        },
        TestOrder {
          account: 4,
          is_buy: True,
          size: 150000000,
          price_times_1bil: 1000000000,
          fee_amount_bp: 10,
          unfilled_size: 50000000,
          base_balance: 0,
          quote_balance: 150000000,
          order_type: LimitOrder,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 300000, usd: 330000 },
        Balance { account: 1, ada: 250000000, usd: 329670000 },
        Balance { account: 2, ada: 99900000, usd: 0 },
        Balance { account: 3, ada: 99900000, usd: 0 },
        Balance { account: 4, ada: 99900000, usd: 0 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_65_mo_multiple_pq() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_buy: True,
        size: 500000000,
        price_times_1bil: 1200000000,
        fee_amount_bp: 10,
        unfilled_size: 240000000,
        base_balance: 0,
        quote_balance: 900000000,
        order_type: MarketOrder,
      },
      makers: [
        TestOrder {
          account: 2,
          is_buy: False,
          size: 100000000,
          price_times_1bil: 1200000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 100000000,
          quote_balance: 0,
          order_type: LimitOrder,
        },
        TestOrder {
          account: 3,
          is_buy: False,
          size: 100000000,
          price_times_1bil: 1300000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 100000000,
          quote_balance: 0,
          order_type: LimitOrder,
        },
        TestOrder {
          account: 4,
          is_buy: False,
          size: 100000000,
          price_times_1bil: 1400000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 100000000,
          quote_balance: 0,
          order_type: LimitOrder,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 300000, usd: 390000 },
        Balance { account: 1, ada: 299700000, usd: 270000000 },
        Balance { account: 2, ada: 0, usd: 119880000 },
        Balance { account: 3, ada: 0, usd: 129870000 },
        Balance { account: 4, ada: 0, usd: 139860000 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_66_mo_multiple_pq() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_buy: False,
        size: 500000000,
        price_times_1bil: 1200000000,
        fee_amount_bp: 10,
        unfilled_size: 141666666,
        base_balance: 833333333,
        quote_balance: 0,
        order_type: MarketOrder,
      },
      makers: [
        TestOrder {
          account: 2,
          is_buy: True,
          size: 120000000,
          price_times_1bil: 1200000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 0,
          quote_balance: 120000000,
          order_type: LimitOrder,
        },
        TestOrder {
          account: 3,
          is_buy: True,
          size: 110000000,
          price_times_1bil: 1100000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 0,
          quote_balance: 110000000,
          order_type: LimitOrder,
        },
        TestOrder {
          account: 4,
          is_buy: True,
          size: 100000000,
          price_times_1bil: 1000000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 0,
          quote_balance: 100000000,
          order_type: LimitOrder,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 300000, usd: 330000 },
        Balance { account: 1, ada: 391666667, usd: 329670000 },
        Balance { account: 2, ada: 99900000, usd: 0 },
        Balance { account: 3, ada: 99900000, usd: 0 },
        Balance { account: 4, ada: 99900000, usd: 0 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_67_mo_multiple_pq() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_buy: True,
        size: 891250911,
        price_times_1bil: 1212100000,
        fee_amount_bp: 10,
        unfilled_size: 0,
        base_balance: 0,
        quote_balance: 1620427843,
        order_type: MarketOrder,
      },
      makers: [
        TestOrder {
          account: 2,
          is_buy: False,
          size: 249214511,
          price_times_1bil: 1212100000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 249214511,
          quote_balance: 0,
          order_type: LimitOrder,
        },
        TestOrder {
          account: 3,
          is_buy: False,
          size: 412389419,
          price_times_1bil: 1225000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 412389419,
          quote_balance: 0,
          order_type: LimitOrder,
        },
        TestOrder {
          account: 4,
          is_buy: False,
          size: 1258921985,
          price_times_1bil: 1523500000,
          fee_amount_bp: 10,
          unfilled_size: 1029275004,
          base_balance: 1258921985,
          quote_balance: 0,
          order_type: LimitOrder,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 891250, usd: 1157116 },
        Balance { account: 1, ada: 890359661, usd: 463310721 },
        Balance { account: 2, ada: 0, usd: 301770836 },
        Balance { account: 3, ada: 0, usd: 504671861 },
        Balance { account: 4, ada: 0, usd: 349517309 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_68_mo_multiple_pq() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_buy: False,
        size: 518501215,
        price_times_1bil: 512300000,
        fee_amount_bp: 10,
        unfilled_size: 0,
        base_balance: 2024209310,
        quote_balance: 0,
        order_type: MarketOrder,
      },
      makers: [
        TestOrder {
          account: 2,
          is_buy: True,
          size: 64147992,
          price_times_1bil: 512300000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 0,
          quote_balance: 64147992,
          order_type: LimitOrder,
        },
        TestOrder {
          account: 3,
          is_buy: True,
          size: 129795393,
          price_times_1bil: 501300000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 0,
          quote_balance: 129795393,
          order_type: LimitOrder,
        },
        TestOrder {
          account: 4,
          is_buy: True,
          size: 811101943,
          price_times_1bil: 500100000,
          fee_amount_bp: 10,
          unfilled_size: 486544114,
          base_balance: 0,
          quote_balance: 811101943,
          order_type: LimitOrder,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 1033117, usd: 518501 },
        Balance { account: 1, ada: 991090171, usd: 517982713 },
        Balance { account: 2, ada: 125090463, usd: 0 },
        Balance { account: 3, ada: 258658683, usd: 0 },
        Balance { account: 4, ada: 648336876, usd: 0 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_69_mo_multiple_pq() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_buy: True,
        size: 1036981165,
        price_times_1bil: 521100000,
        fee_amount_bp: 10,
        unfilled_size: 187136580,
        base_balance: 0,
        quote_balance: 810556327,
        order_type: MarketOrder,
      },
      makers: [
        TestOrder {
          account: 2,
          is_buy: False,
          size: 235151567,
          price_times_1bil: 521100000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 235151567,
          quote_balance: 0,
          order_type: LimitOrder,
        },
        TestOrder {
          account: 3,
          is_buy: False,
          size: 129805613,
          price_times_1bil: 521300000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 129805613,
          quote_balance: 0,
          order_type: LimitOrder,
        },
        TestOrder {
          account: 4,
          is_buy: False,
          size: 312905619,
          price_times_1bil: 521500000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 312905619,
          quote_balance: 0,
          order_type: LimitOrder,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 677862, usd: 353384 },
        Balance { account: 1, ada: 677184937, usd: 270034320 },
        Balance { account: 2, ada: 0, usd: 122414944 },
        Balance { account: 3, ada: 0, usd: 67599999 },
        Balance { account: 4, ada: 0, usd: 163017100 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_70_mo_multiple_pq() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_buy: False,
        size: 16123743813,
        price_times_1bil: 492100000,
        fee_amount_bp: 10,
        unfilled_size: 19374043015,
        base_balance: 65530354858,
        quote_balance: 0,
        order_type: MarketOrder,
      },
      makers: [
        TestOrder {
          account: 2,
          is_buy: True,
          size: 2555184528,
          price_times_1bil: 492100000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 0,
          quote_balance: 2555184528,
          order_type: LimitOrder,
        },
        TestOrder {
          account: 3,
          is_buy: True,
          size: 827011263,
          price_times_1bil: 491900000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 0,
          quote_balance: 827011263,
          order_type: LimitOrder,
        },
        TestOrder {
          account: 4,
          is_buy: True,
          size: 3207581454,
          price_times_1bil: 491700000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 0,
          quote_balance: 3207581454,
          order_type: LimitOrder,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 13397119, usd: 6589777 },
        Balance { account: 1, ada: 32759191589, usd: 6583187468 },
        Balance { account: 2, ada: 5187216711, usd: 0 },
        Balance { account: 3, ada: 1679577662, usd: 0 },
        Balance { account: 4, ada: 6516928762, usd: 0 },
      ],
    }
  run_test(test_case)
}
