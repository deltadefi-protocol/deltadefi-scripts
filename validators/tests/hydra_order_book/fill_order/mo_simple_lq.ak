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

test s9_fill_order_27_mo_simple_lq() {
  let test_case =
    TestCase {
      taker: MarketOrder {
        account: 1,
        is_long: True,
        size: 120000000,
        price_times_1bil: 1200000000,
        fee_amount_bp: 10,
        unfilled_size: 0,
        base_balance: 0,
        quote_balance: 120000000,
      },
      makers: [
        LimitOrder {
          account: 2,
          is_long: False,
          size: 100000000,
          price_times_1bil: 1200000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
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

test s9_fill_order_28_mo_simple_lq() {
  let test_case =
    TestCase {
      taker: MarketOrder {
        account: 1,
        is_long: False,
        size: 100000000,
        price_times_1bil: 1200000000,
        fee_amount_bp: 10,
        unfilled_size: 0,
        base_balance: 100000000,
        quote_balance: 0,
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

test s9_fill_order_29_mo_simple_lq() {
  let test_case =
    TestCase {
      taker: MarketOrder {
        account: 1,
        is_long: True,
        size: 120000000,
        price_times_1bil: 1200000000,
        fee_amount_bp: 10,
        unfilled_size: 0,
        base_balance: 0,
        quote_balance: 120000000,
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

test s9_fill_order_30_mo_simple_lq() {
  let test_case =
    TestCase {
      taker: MarketOrder {
        account: 1,
        is_long: False,
        size: 100000000,
        price_times_1bil: 1200000000,
        fee_amount_bp: 10,
        unfilled_size: 0,
        base_balance: 100000000,
        quote_balance: 0,
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

test s9_fill_order_31_mo_simple_lq() {
  let test_case =
    TestCase {
      taker: MarketOrder {
        account: 1,
        is_long: True,
        size: 200000000,
        price_times_1bil: 1200000000,
        fee_amount_bp: 10,
        unfilled_size: 66666666,
        base_balance: 0,
        quote_balance: 200000000,
      },
      makers: [
        LimitOrder {
          account: 2,
          is_long: False,
          size: 100000000,
          price_times_1bil: 1200000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 100000, usd: 120000 },
        Balance { account: 1, ada: 99900000, usd: 13333334 },
        Balance { account: 2, ada: 0, usd: 119880000 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_32_mo_simple_lq() {
  let test_case =
    TestCase {
      taker: MarketOrder {
        account: 1,
        is_long: False,
        size: 200000000,
        price_times_1bil: 1200000000,
        fee_amount_bp: 10,
        unfilled_size: 100000000,
        base_balance: 200000000,
        quote_balance: 0,
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

test s9_fill_order_33_mo_simple_lq() {
  let test_case =
    TestCase {
      taker: MarketOrder {
        account: 1,
        is_long: True,
        size: 912578123,
        price_times_1bil: 1214500000,
        fee_amount_bp: 10,
        unfilled_size: 0,
        base_balance: 0,
        quote_balance: 912578123,
      },
      makers: [
        LimitOrder {
          account: 2,
          is_long: False,
          size: 1589129525,
          price_times_1bil: 1214500000,
          fee_amount_bp: 10,
          unfilled_size: 837727201,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 751402, usd: 912578 },
        Balance { account: 1, ada: 750650922, usd: 0 },
        Balance { account: 2, ada: 0, usd: 911665545 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_34_mo_simple_lq() {
  let test_case =
    TestCase {
      taker: MarketOrder {
        account: 1,
        is_long: False,
        size: 3905901201,
        price_times_1bil: 521500000,
        fee_amount_bp: 10,
        unfilled_size: 0,
        base_balance: 3905901201,
        quote_balance: 0,
      },
      makers: [
        LimitOrder {
          account: 2,
          is_long: True,
          size: 3072291996,
          price_times_1bil: 521500000,
          fee_amount_bp: 10,
          unfilled_size: 1035364519,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 3905900, usd: 2036927 },
        Balance { account: 1, ada: 0, usd: 2034890550 },
        Balance { account: 2, ada: 3901995301, usd: 0 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_35_mo_simple_lq() {
  let test_case =
    TestCase {
      taker: MarketOrder {
        account: 1,
        is_long: True,
        size: 1895129859,
        price_times_1bil: 712300000,
        fee_amount_bp: 10,
        unfilled_size: 1757996685,
        base_balance: 0,
        quote_balance: 1895129859,
      },
      makers: [
        LimitOrder {
          account: 2,
          is_long: False,
          size: 902581525,
          price_times_1bil: 712300000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 902581, usd: -505132738 },
        Balance { account: 1, ada: 901678944, usd: 0 },
        Balance { account: 2, ada: 0, usd: 642265912 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_36_mo_simple_lq() {
  let test_case =
    TestCase {
      taker: MarketOrder {
        account: 1,
        is_long: False,
        size: 1295712553,
        price_times_1bil: 423900000,
        fee_amount_bp: 10,
        unfilled_size: 1060821306,
        base_balance: 1295712553,
        quote_balance: 0,
      },
      makers: [
        LimitOrder {
          account: 2,
          is_long: True,
          size: 99570400,
          price_times_1bil: 423900000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 234891, usd: 99570 },
        Balance { account: 1, ada: 0, usd: 99470830 },
        Balance { account: 2, ada: 234656356, usd: 0 },
      ],
    }
  run_test(test_case)
}
