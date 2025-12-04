use cardano/address.{Script}
use hydra_dex/types.{FillOrder}
use hydra_order_book/core as ob
use tests/hydra_order_book/fill_order/utils.{
  Balance, LimitOrder, MarketOrder, TestCase, fill_order_test,
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

test s9_fill_order_67_mo_db() {
  let test_case =
    TestCase {
      taker: MarketOrder {
        account: 1,
        is_long: True,
        size: 300000000,
        price_times_1bil: 1200000000,
        fee_amount_bp: 10,
        unfilled_size: 0,
        base_balance: 0,
        quote_balance: 540000000,
      },
      makers: [
        LimitOrder {
          account: 2,
          is_long: False,
          size: 800000000,
          price_times_1bil: 1200000000,
          fee_amount_bp: 10,
          unfilled_size: 500000000,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 300000, usd: 360000 },
        Balance { account: 1, ada: 299700000, usd: 180000000 },
        Balance { account: 2, ada: 0, usd: 359640000 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_68_mo_db() {
  let test_case =
    TestCase {
      taker: MarketOrder {
        account: 1,
        is_long: True,
        size: 330000000,
        price_times_1bil: 1200000000,
        fee_amount_bp: 10,
        unfilled_size: 36000000,
        base_balance: 0,
        quote_balance: 594000000,
      },
      makers: [
        LimitOrder {
          account: 2,
          is_long: False,
          size: 300000000,
          price_times_1bil: 1200000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 300000, usd: 360000 },
        Balance { account: 1, ada: 299700000, usd: 198000000 },
        Balance { account: 2, ada: 0, usd: 359640000 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_69_mo_db() {
  let test_case =
    TestCase {
      taker: MarketOrder {
        account: 1,
        is_long: True,
        size: 330000000,
        price_times_1bil: 1200000000,
        fee_amount_bp: 10,
        unfilled_size: 0,
        base_balance: 0,
        quote_balance: 330000000,
      },
      makers: [
        LimitOrder {
          account: 2,
          is_long: False,
          size: 633333333,
          price_times_1bil: 1200000000,
          fee_amount_bp: 10,
          unfilled_size: 358333333,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 275000, usd: 330000 },
        Balance { account: 1, ada: 274725000, usd: 0 },
        Balance { account: 2, ada: 0, usd: 329670000 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_70_mo_db() {
  let test_case =
    TestCase {
      taker: MarketOrder {
        account: 1,
        is_long: False,
        size: 300000000,
        price_times_1bil: 1200000000,
        fee_amount_bp: 10,
        unfilled_size: 0,
        base_balance: 300000000,
        quote_balance: 0,
      },
      makers: [
        LimitOrder {
          account: 2,
          is_long: True,
          size: 960000000,
          price_times_1bil: 1200000000,
          fee_amount_bp: 10,
          unfilled_size: 600000000,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 300000, usd: 360000 },
        Balance { account: 1, ada: 0, usd: 359640000 },
        Balance { account: 2, ada: 299700000, usd: 0 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_71_mo_db() {
  let test_case =
    TestCase {
      taker: MarketOrder {
        account: 1,
        is_long: False,
        size: 330000000,
        price_times_1bil: 1200000000,
        fee_amount_bp: 10,
        unfilled_size: 0,
        base_balance: 330000000,
        quote_balance: 0,
      },
      makers: [
        LimitOrder {
          account: 2,
          is_long: True,
          size: 960000000,
          price_times_1bil: 1200000000,
          fee_amount_bp: 10,
          unfilled_size: 564000000,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 330000, usd: 396000 },
        Balance { account: 1, ada: 0, usd: 395604000 },
        Balance { account: 2, ada: 329670000, usd: 0 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_72_mo_db() {
  let test_case =
    TestCase {
      taker: MarketOrder {
        account: 1,
        is_long: False,
        size: 330000000,
        price_times_1bil: 1200000000,
        fee_amount_bp: 10,
        unfilled_size: 0,
        base_balance: 550000000,
        quote_balance: 0,
      },
      makers: [
        LimitOrder {
          account: 2,
          is_long: True,
          size: 760000000,
          price_times_1bil: 1200000000,
          fee_amount_bp: 10,
          unfilled_size: 429999999,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 275000, usd: 330000 },
        Balance { account: 1, ada: 274999999, usd: 329670001 },
        Balance { account: 2, ada: 274725001, usd: 0 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_73_mo_db() {
  let test_case =
    TestCase {
      taker: MarketOrder {
        account: 1,
        is_long: True,
        size: 300000000,
        price_times_1bil: 1200000000,
        fee_amount_bp: 10,
        unfilled_size: 0,
        base_balance: 0,
        quote_balance: 300000000,
      },
      makers: [
        LimitOrder {
          account: 2,
          is_long: False,
          size: 800000000,
          price_times_1bil: 1200000000,
          fee_amount_bp: 10,
          unfilled_size: 550000000,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 250000, usd: 300000 },
        Balance { account: 1, ada: 249750000, usd: 0 },
        Balance { account: 2, ada: 0, usd: 299700000 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_74_mo_db() {
  let test_case =
    TestCase {
      taker: MarketOrder {
        account: 1,
        is_long: True,
        size: 330000000,
        price_times_1bil: 1200000000,
        fee_amount_bp: 10,
        unfilled_size: 0,
        base_balance: 0,
        quote_balance: 330000000,
      },
      makers: [
        LimitOrder {
          account: 2,
          is_long: False,
          size: 300000000,
          price_times_1bil: 1200000000,
          fee_amount_bp: 10,
          unfilled_size: 25000000,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 275000, usd: 330000 },
        Balance { account: 1, ada: 274725000, usd: 0 },
        Balance { account: 2, ada: 0, usd: 329670000 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_75_mo_db() {
  let test_case =
    TestCase {
      taker: MarketOrder {
        account: 1,
        is_long: True,
        size: 330000000,
        price_times_1bil: 1200000000,
        fee_amount_bp: 10,
        unfilled_size: 0,
        base_balance: 0,
        quote_balance: 330000000,
      },
      makers: [
        LimitOrder {
          account: 2,
          is_long: False,
          size: 633333333,
          price_times_1bil: 1200000000,
          fee_amount_bp: 10,
          unfilled_size: 358333333,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 275000, usd: 330000 },
        Balance { account: 1, ada: 274725000, usd: 0 },
        Balance { account: 2, ada: 0, usd: 329670000 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_76_mo_db() {
  let test_case =
    TestCase {
      taker: MarketOrder {
        account: 1,
        is_long: False,
        size: 300000000,
        price_times_1bil: 1200000000,
        fee_amount_bp: 10,
        unfilled_size: 0,
        base_balance: 500000000,
        quote_balance: 0,
      },
      makers: [
        LimitOrder {
          account: 2,
          is_long: True,
          size: 960000000,
          price_times_1bil: 1200000000,
          fee_amount_bp: 10,
          unfilled_size: 660000000,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 250000, usd: 300000 },
        Balance { account: 1, ada: 250000000, usd: 299700000 },
        Balance { account: 2, ada: 249750000, usd: 0 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_77_mo_db() {
  let test_case =
    TestCase {
      taker: MarketOrder {
        account: 1,
        is_long: False,
        size: 330000000,
        price_times_1bil: 1200000000,
        fee_amount_bp: 10,
        unfilled_size: 0,
        base_balance: 550000000,
        quote_balance: 0,
      },
      makers: [
        LimitOrder {
          account: 2,
          is_long: True,
          size: 960000000,
          price_times_1bil: 1200000000,
          fee_amount_bp: 10,
          unfilled_size: 630000000,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 275000, usd: 330000 },
        Balance { account: 1, ada: 275000000, usd: 329670000 },
        Balance { account: 2, ada: 274725000, usd: 0 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_78_mo_db() {
  let test_case =
    TestCase {
      taker: MarketOrder {
        account: 1,
        is_long: False,
        size: 330000000,
        price_times_1bil: 1200000000,
        fee_amount_bp: 10,
        unfilled_size: 0,
        base_balance: 550000000,
        quote_balance: 0,
      },
      makers: [
        LimitOrder {
          account: 2,
          is_long: True,
          size: 760000000,
          price_times_1bil: 1200000000,
          fee_amount_bp: 10,
          unfilled_size: 429999999,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 275000, usd: 330000 },
        Balance { account: 1, ada: 274999999, usd: 329670001 },
        Balance { account: 2, ada: 274725001, usd: 0 },
      ],
    }
  run_test(test_case)
}
