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

test s9_fill_order_51_mo_multiple_lq() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_long: True,
        size: 390000000,
        price_times_1bil: 1200000000,
        fee_amount_bp: 10,
        unfilled_size: 0,
        base_balance: 0,
        quote_balance: 390000000,
      },
      makers: [
        TestOrder {
          account: 2,
          is_long: False,
          size: 100000000,
          price_times_1bil: 1200000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 100000000,
          quote_balance: 0,
        },
        TestOrder {
          account: 3,
          is_long: False,
          size: 100000000,
          price_times_1bil: 1300000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 100000000,
          quote_balance: 0,
        },
        TestOrder {
          account: 4,
          is_long: False,
          size: 100000000,
          price_times_1bil: 1400000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 100000000,
          quote_balance: 0,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 300000, usd: 390000 },
        Balance { account: 1, ada: 299700000, usd: 0 },
        Balance { account: 2, ada: 0, usd: 119880000 },
        Balance { account: 3, ada: 0, usd: 129870000 },
        Balance { account: 4, ada: 0, usd: 139860000 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_52_mo_multiple_lq() {
  let test_case =
    TestCase {
      taker: TestOrder {
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
        TestOrder {
          account: 2,
          is_long: True,
          size: 120000000,
          price_times_1bil: 1200000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 0,
          quote_balance: 120000000,
        },
        TestOrder {
          account: 3,
          is_long: True,
          size: 110000000,
          price_times_1bil: 1100000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 0,
          quote_balance: 110000000,
        },
        TestOrder {
          account: 4,
          is_long: True,
          size: 100000000,
          price_times_1bil: 1000000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 0,
          quote_balance: 100000000,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 300000, usd: 330000 },
        Balance { account: 1, ada: 0, usd: 329670000 },
        Balance { account: 2, ada: 99900000, usd: 0 },
        Balance { account: 3, ada: 99900000, usd: 0 },
        Balance { account: 4, ada: 99900000, usd: 0 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_53_mo_multiple_lq() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_long: True,
        size: 390000000,
        price_times_1bil: 1200000000,
        fee_amount_bp: 10,
        unfilled_size: 0,
        base_balance: 0,
        quote_balance: 390000000,
      },
      makers: [
        TestOrder {
          account: 2,
          is_long: False,
          size: 100000000,
          price_times_1bil: 1200000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 100000000,
          quote_balance: 0,
        },
        TestOrder {
          account: 3,
          is_long: False,
          size: 100000000,
          price_times_1bil: 1300000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 100000000,
          quote_balance: 0,
        },
        TestOrder {
          account: 4,
          is_long: False,
          size: 150000000,
          price_times_1bil: 1400000000,
          fee_amount_bp: 10,
          unfilled_size: 50000000,
          base_balance: 150000000,
          quote_balance: 0,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 300000, usd: 390000 },
        Balance { account: 1, ada: 299700000, usd: 0 },
        Balance { account: 2, ada: 0, usd: 119880000 },
        Balance { account: 3, ada: 0, usd: 129870000 },
        Balance { account: 4, ada: 0, usd: 139860000 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_54_mo_multiple_lq() {
  let test_case =
    TestCase {
      taker: TestOrder {
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
        TestOrder {
          account: 2,
          is_long: True,
          size: 120000000,
          price_times_1bil: 1200000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 0,
          quote_balance: 120000000,
        },
        TestOrder {
          account: 3,
          is_long: True,
          size: 110000000,
          price_times_1bil: 1100000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 0,
          quote_balance: 110000000,
        },
        TestOrder {
          account: 4,
          is_long: True,
          size: 150000000,
          price_times_1bil: 1000000000,
          fee_amount_bp: 10,
          unfilled_size: 50000000,
          base_balance: 0,
          quote_balance: 150000000,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 300000, usd: 330000 },
        Balance { account: 1, ada: 0, usd: 329670000 },
        Balance { account: 2, ada: 99900000, usd: 0 },
        Balance { account: 3, ada: 99900000, usd: 0 },
        Balance { account: 4, ada: 99900000, usd: 0 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_55_mo_multiple_lq() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_long: True,
        size: 500000000,
        price_times_1bil: 1200000000,
        fee_amount_bp: 10,
        unfilled_size: 109999999,
        base_balance: 0,
        quote_balance: 500000000,
      },
      makers: [
        TestOrder {
          account: 2,
          is_long: False,
          size: 100000000,
          price_times_1bil: 1200000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 100000000,
          quote_balance: 0,
        },
        TestOrder {
          account: 3,
          is_long: False,
          size: 100000000,
          price_times_1bil: 1300000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 100000000,
          quote_balance: 0,
        },
        TestOrder {
          account: 4,
          is_long: False,
          size: 100000000,
          price_times_1bil: 1400000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 100000000,
          quote_balance: 0,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 300000, usd: 390000 },
        Balance { account: 1, ada: 299700000, usd: 1 },
        Balance { account: 2, ada: 0, usd: 119880000 },
        Balance { account: 3, ada: 0, usd: 129870000 },
        Balance { account: 4, ada: 0, usd: 139860000 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_56_mo_multiple_lq() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_long: False,
        size: 500000000,
        price_times_1bil: 1200000000,
        fee_amount_bp: 10,
        unfilled_size: 200000000,
        base_balance: 500000000,
        quote_balance: 0,
      },
      makers: [
        TestOrder {
          account: 2,
          is_long: True,
          size: 120000000,
          price_times_1bil: 1200000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 0,
          quote_balance: 120000000,
        },
        TestOrder {
          account: 3,
          is_long: True,
          size: 110000000,
          price_times_1bil: 1100000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 0,
          quote_balance: 110000000,
        },
        TestOrder {
          account: 4,
          is_long: True,
          size: 100000000,
          price_times_1bil: 1000000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 0,
          quote_balance: 100000000,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 300000, usd: 330000 },
        Balance { account: 1, ada: 0, usd: 329670000 },
        Balance { account: 2, ada: 99900000, usd: 0 },
        Balance { account: 3, ada: 99900000, usd: 0 },
        Balance { account: 4, ada: 99900000, usd: 0 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_57_mo_multiple_lq() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_long: True,
        size: 891250911,
        price_times_1bil: 1212100000,
        fee_amount_bp: 10,
        unfilled_size: 0,
        base_balance: 0,
        quote_balance: 891250911,
      },
      makers: [
        TestOrder {
          account: 2,
          is_long: False,
          size: 249214511,
          price_times_1bil: 1212100000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 249214511,
          quote_balance: 0,
        },
        TestOrder {
          account: 3,
          is_long: False,
          size: 412389419,
          price_times_1bil: 1225000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 412389419,
          quote_balance: 0,
        },
        TestOrder {
          account: 4,
          is_long: False,
          size: 1258921985,
          price_times_1bil: 1523500000,
          fee_amount_bp: 10,
          unfilled_size: 1203785153,
          base_balance: 1258921985,
          quote_balance: 0,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 716740, usd: 891249 },
        Balance { account: 1, ada: 716024022, usd: 1 },
        Balance { account: 2, ada: 0, usd: 301770836 },
        Balance { account: 3, ada: 0, usd: 504671861 },
        Balance { account: 4, ada: 0, usd: 83916964 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_58_mo_multiple_lq() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_long: False,
        size: 518501215,
        price_times_1bil: 512300000,
        fee_amount_bp: 10,
        unfilled_size: 0,
        base_balance: 518501215,
        quote_balance: 0,
      },
      makers: [
        TestOrder {
          account: 2,
          is_long: True,
          size: 64147992,
          price_times_1bil: 512300000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 0,
          quote_balance: 64147992,
        },
        TestOrder {
          account: 3,
          is_long: True,
          size: 129795393,
          price_times_1bil: 501300000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 0,
          quote_balance: 129795393,
        },
        TestOrder {
          account: 4,
          is_long: True,
          size: 311001943,
          price_times_1bil: 500100000,
          fee_amount_bp: 10,
          unfilled_size: 243804539,
          base_balance: 0,
          quote_balance: 311001943,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 518499, usd: 261140 },
        Balance { account: 1, ada: 2, usd: 260879649 },
        Balance { account: 2, ada: 125090463, usd: 0 },
        Balance { account: 3, ada: 258658683, usd: 0 },
        Balance { account: 4, ada: 134233568, usd: 0 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_59_mo_multiple_lq() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_long: True,
        size: 1036981165,
        price_times_1bil: 521100000,
        fee_amount_bp: 10,
        unfilled_size: 683595737,
        base_balance: 0,
        quote_balance: 1036981165,
      },
      makers: [
        TestOrder {
          account: 2,
          is_long: False,
          size: 235151567,
          price_times_1bil: 521100000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 235151567,
          quote_balance: 0,
        },
        TestOrder {
          account: 3,
          is_long: False,
          size: 129805613,
          price_times_1bil: 521300000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 129805613,
          quote_balance: 0,
        },
        TestOrder {
          account: 4,
          is_long: False,
          size: 312905619,
          price_times_1bil: 521500000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 312905619,
          quote_balance: 0,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 677862, usd: 353384 },
        Balance { account: 1, ada: 677184937, usd: 1 },
        Balance { account: 2, ada: 0, usd: 122414944 },
        Balance { account: 3, ada: 0, usd: 67599999 },
        Balance { account: 4, ada: 0, usd: 163017100 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_60_mo_multiple_lq() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_long: False,
        size: 10369081089,
        price_times_1bil: 1200000000,
        fee_amount_bp: 10,
        unfilled_size: 1880391208,
        base_balance: 10369081089,
        quote_balance: 0,
      },
      makers: [
        TestOrder {
          account: 2,
          is_long: True,
          size: 2809518162,
          price_times_1bil: 1200000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 0,
          quote_balance: 2809518162,
        },
        TestOrder {
          account: 3,
          is_long: True,
          size: 1381738739,
          price_times_1bil: 1100000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 0,
          quote_balance: 1381738739,
        },
        TestOrder {
          account: 4,
          is_long: True,
          size: 4891298619,
          price_times_1bil: 1000000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 0,
          quote_balance: 4891298619,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 8488689, usd: 9082555 },
        Balance { account: 1, ada: 1, usd: 9073472965 },
        Balance { account: 2, ada: 2338923870, usd: 0 },
        Balance { account: 3, ada: 1254870000, usd: 0 },
        Balance { account: 4, ada: 4886407321, usd: 0 },
      ],
    }
  run_test(test_case)
}
