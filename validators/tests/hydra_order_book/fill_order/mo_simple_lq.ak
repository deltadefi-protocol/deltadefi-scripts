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

test s9_fill_order_27_mo_simple_lq() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_buy: True,
        size: 120000000,
        price_times_1bil: 1200000000000,
        fee_amount_bp: 10,
        unfilled_size: 0,
        base_balance: 0,
        quote_balance: 120000000,
        order_type: MarketOrder,
      },
      makers: [
        TestOrder {
          account: 2,
          is_buy: False,
          size: 100000000,
          price_times_1bil: 1200000000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 100000000,
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

test s9_fill_order_28_mo_simple_lq() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_buy: False,
        size: 100000000,
        price_times_1bil: 1200000000000,
        fee_amount_bp: 10,
        unfilled_size: 0,
        base_balance: 100000000,
        quote_balance: 0,
        order_type: MarketOrder,
      },
      makers: [
        TestOrder {
          account: 2,
          is_buy: True,
          size: 120000000,
          price_times_1bil: 1200000000000,
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

test s9_fill_order_29_mo_simple_lq() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_buy: True,
        size: 120000000,
        price_times_1bil: 1200000000000,
        fee_amount_bp: 10,
        unfilled_size: 0,
        base_balance: 0,
        quote_balance: 120000000,
        order_type: MarketOrder,
      },
      makers: [
        TestOrder {
          account: 2,
          is_buy: False,
          size: 200000000,
          price_times_1bil: 1200000000000,
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

test s9_fill_order_30_mo_simple_lq() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_buy: False,
        size: 100000000,
        price_times_1bil: 1200000000000,
        fee_amount_bp: 10,
        unfilled_size: 0,
        base_balance: 100000000,
        quote_balance: 0,
        order_type: MarketOrder,
      },
      makers: [
        TestOrder {
          account: 2,
          is_buy: True,
          size: 240000000,
          price_times_1bil: 1200000000000,
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

test s9_fill_order_31_mo_simple_lq() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_buy: True,
        size: 200000000,
        price_times_1bil: 1200000000000,
        fee_amount_bp: 10,
        unfilled_size: 79999999,
        base_balance: 0,
        quote_balance: 200000000,
        order_type: MarketOrder,
      },
      makers: [
        TestOrder {
          account: 2,
          is_buy: False,
          size: 100000000,
          price_times_1bil: 1200000000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 100000000,
          quote_balance: 0,
          order_type: LimitOrder,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 100000, usd: 120000 },
        Balance { account: 1, ada: 99900000, usd: 1 },
        Balance { account: 2, ada: 0, usd: 119880000 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_32_mo_simple_lq() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_buy: False,
        size: 200000000,
        price_times_1bil: 1200000000000,
        fee_amount_bp: 10,
        unfilled_size: 100000000,
        base_balance: 200000000,
        quote_balance: 0,
        order_type: MarketOrder,
      },
      makers: [
        TestOrder {
          account: 2,
          is_buy: True,
          size: 120000000,
          price_times_1bil: 1200000000000,
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

test s9_fill_order_33_mo_simple_lq() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_buy: True,
        size: 912578123,
        price_times_1bil: 1214500000000,
        fee_amount_bp: 10,
        unfilled_size: 0,
        base_balance: 0,
        quote_balance: 912578123,
        order_type: MarketOrder,
      },
      makers: [
        TestOrder {
          account: 2,
          is_buy: False,
          size: 1589129525,
          price_times_1bil: 1214500000000,
          fee_amount_bp: 10,
          unfilled_size: 837727201,
          base_balance: 1589129525,
          quote_balance: 0,
          order_type: LimitOrder,
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
      taker: TestOrder {
        account: 1,
        is_buy: False,
        size: 3905901201,
        price_times_1bil: 521500000000,
        fee_amount_bp: 10,
        unfilled_size: 0,
        base_balance: 3905901201,
        quote_balance: 0,
        order_type: MarketOrder,
      },
      makers: [
        TestOrder {
          account: 2,
          is_buy: True,
          size: 3072291996,
          price_times_1bil: 521500000000,
          fee_amount_bp: 10,
          unfilled_size: 1035364520,
          base_balance: 0,
          quote_balance: 3072291996,
          order_type: LimitOrder,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 3905901, usd: 2036927 },
        Balance { account: 1, ada: 1, usd: 2034890549 },
        Balance { account: 2, ada: 3901995299, usd: 0 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_35_mo_simple_lq() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_buy: True,
        size: 1895129859,
        price_times_1bil: 712300000000,
        fee_amount_bp: 10,
        unfilled_size: 1252221038,
        base_balance: 0,
        quote_balance: 1895129859,
        order_type: MarketOrder,
      },
      makers: [
        TestOrder {
          account: 2,
          is_buy: False,
          size: 902581525,
          price_times_1bil: 712300000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 902581525,
          quote_balance: 0,
          order_type: LimitOrder,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 902581, usd: 642908 },
        Balance { account: 1, ada: 901678944, usd: 1 },
        Balance { account: 2, ada: 0, usd: 642265912 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_36_mo_simple_lq() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_buy: False,
        size: 1295712553,
        price_times_1bil: 423900000000,
        fee_amount_bp: 10,
        unfilled_size: 1060821304,
        base_balance: 1295712553,
        quote_balance: 0,
        order_type: MarketOrder,
      },
      makers: [
        TestOrder {
          account: 2,
          is_buy: True,
          size: 99570400,
          price_times_1bil: 423900000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 0,
          quote_balance: 99570400,
          order_type: LimitOrder,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 234891, usd: 99570 },
        Balance { account: 1, ada: 2, usd: 99470830 },
        Balance { account: 2, ada: 234656356, usd: 0 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_37_mo_simple_lq() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_buy: True,
        size: 1895129700,
        price_times_1bil: 712300000000,
        fee_amount_bp: 10,
        unfilled_size: 1252220897,
        base_balance: 0,
        quote_balance: 1895129700,
        order_type: MarketOrder,
      },
      makers: [
        TestOrder {
          account: 2,
          is_buy: False,
          size: 902581500,
          price_times_1bil: 712300000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 902581500,
          quote_balance: 0,
          order_type: LimitOrder,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 902581, usd: 642908 },
        Balance { account: 1, ada: 901678919, usd: 1 },
        Balance { account: 2, ada: 0, usd: 642265894 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_38_mo_simple_lq() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_buy: False,
        size: 1295712500,
        price_times_1bil: 423900000000,
        fee_amount_bp: 10,
        unfilled_size: 1060821400,
        base_balance: 1295712500,
        quote_balance: 0,
        order_type: MarketOrder,
      },
      makers: [
        TestOrder {
          account: 2,
          is_buy: True,
          size: 99570337,
          price_times_1bil: 423900000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 0,
          quote_balance: 99570337,
          order_type: LimitOrder,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 234891, usd: 99570 },
        Balance { account: 1, ada: 1, usd: 99470767 },
        Balance { account: 2, ada: 234656208, usd: 0 },
      ],
    }
  run_test(test_case)
}
