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

test s9_fill_order_13_lo_multiple() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_long: True,
        size: 360000000,
        price_times_1bil: 1200000000,
        fee_amount_bp: 10,
        unfilled_size: 0,
        base_balance: 0,
        quote_balance: 360000000,
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
          price_times_1bil: 1200000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 100000000,
          quote_balance: 0,
        },
        TestOrder {
          account: 4,
          is_long: False,
          size: 100000000,
          price_times_1bil: 1200000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 100000000,
          quote_balance: 0,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 300000, usd: 360000 },
        Balance { account: 1, ada: 299700000, usd: 0 },
        Balance { account: 2, ada: 0, usd: 119880000 },
        Balance { account: 3, ada: 0, usd: 119880000 },
        Balance { account: 4, ada: 0, usd: 119880000 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_14_lo_multiple() {
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
          size: 120000000,
          price_times_1bil: 1200000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 0,
          quote_balance: 120000000,
        },
        TestOrder {
          account: 4,
          is_long: True,
          size: 120000000,
          price_times_1bil: 1200000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 0,
          quote_balance: 120000000,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 300000, usd: 360000 },
        Balance { account: 1, ada: 0, usd: 359640000 },
        Balance { account: 2, ada: 99900000, usd: 0 },
        Balance { account: 3, ada: 99900000, usd: 0 },
        Balance { account: 4, ada: 99900000, usd: 0 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_15_lo_multiple() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_long: True,
        size: 450000000,
        price_times_1bil: 1500000000,
        fee_amount_bp: 10,
        unfilled_size: 0,
        base_balance: 0,
        quote_balance: 450000000,
      },
      makers: [
        TestOrder {
          account: 2,
          is_long: False,
          size: 100000000,
          price_times_1bil: 1000000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 100000000,
          quote_balance: 0,
        },
        TestOrder {
          account: 3,
          is_long: False,
          size: 100000000,
          price_times_1bil: 1100000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 100000000,
          quote_balance: 0,
        },
        TestOrder {
          account: 4,
          is_long: False,
          size: 100000000,
          price_times_1bil: 1200000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 100000000,
          quote_balance: 0,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 300000, usd: 330000 },
        Balance { account: 1, ada: 299700000, usd: 120000000 },
        Balance { account: 2, ada: 0, usd: 99900000 },
        Balance { account: 3, ada: 0, usd: 109890000 },
        Balance { account: 4, ada: 0, usd: 119880000 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_16_lo_multiple() {
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
          size: 150000000,
          price_times_1bil: 1500000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 0,
          quote_balance: 150000000,
        },
        TestOrder {
          account: 3,
          is_long: True,
          size: 140000000,
          price_times_1bil: 1400000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 0,
          quote_balance: 140000000,
        },
        TestOrder {
          account: 4,
          is_long: True,
          size: 130000000,
          price_times_1bil: 1300000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 0,
          quote_balance: 130000000,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 300000, usd: 420000 },
        Balance { account: 1, ada: 0, usd: 419580000 },
        Balance { account: 2, ada: 99900000, usd: 0 },
        Balance { account: 3, ada: 99900000, usd: 0 },
        Balance { account: 4, ada: 99900000, usd: 0 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_17_lo_multiple() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_long: True,
        size: 450000000,
        price_times_1bil: 1500000000,
        fee_amount_bp: 10,
        unfilled_size: 0,
        base_balance: 0,
        quote_balance: 450000000,
      },
      makers: [
        TestOrder {
          account: 2,
          is_long: False,
          size: 150000000,
          price_times_1bil: 1200000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 150000000,
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
          unfilled_size: 50000000,
          base_balance: 100000000,
          quote_balance: 0,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 300000, usd: 380000 },
        Balance { account: 1, ada: 299700000, usd: 70000000 },
        Balance { account: 2, ada: 0, usd: 179820000 },
        Balance { account: 3, ada: 0, usd: 129870000 },
        Balance { account: 4, ada: 0, usd: 69930000 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_18_lo_multiple() {
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
          size: 225000000,
          price_times_1bil: 1500000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 0,
          quote_balance: 225000000,
        },
        TestOrder {
          account: 3,
          is_long: True,
          size: 140000000,
          price_times_1bil: 1400000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 0,
          quote_balance: 140000000,
        },
        TestOrder {
          account: 4,
          is_long: True,
          size: 130000000,
          price_times_1bil: 1300000000,
          fee_amount_bp: 10,
          unfilled_size: 65000000,
          base_balance: 0,
          quote_balance: 130000000,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 300000, usd: 430000 },
        Balance { account: 1, ada: 0, usd: 429570000 },
        Balance { account: 2, ada: 149850000, usd: 0 },
        Balance { account: 3, ada: 99900000, usd: 0 },
        Balance { account: 4, ada: 49950000, usd: 0 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_19_lo_multiple() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_long: True,
        size: 750000000,
        price_times_1bil: 1500000000,
        fee_amount_bp: 10,
        unfilled_size: 300000000,
        base_balance: 0,
        quote_balance: 750000000,
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
        Balance { account: 1, ada: 299700000, usd: 60000000 },
        Balance { account: 2, ada: 0, usd: 119880000 },
        Balance { account: 3, ada: 0, usd: 129870000 },
        Balance { account: 4, ada: 0, usd: 139860000 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_20_lo_multiple() {
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
          size: 150000000,
          price_times_1bil: 1500000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 0,
          quote_balance: 150000000,
        },
        TestOrder {
          account: 3,
          is_long: True,
          size: 140000000,
          price_times_1bil: 1400000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 0,
          quote_balance: 140000000,
        },
        TestOrder {
          account: 4,
          is_long: True,
          size: 130000000,
          price_times_1bil: 1300000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 0,
          quote_balance: 130000000,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 300000, usd: 420000 },
        Balance { account: 1, ada: 0, usd: 419580000 },
        Balance { account: 2, ada: 99900000, usd: 0 },
        Balance { account: 3, ada: 99900000, usd: 0 },
        Balance { account: 4, ada: 99900000, usd: 0 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_21_lo_multiple() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_long: True,
        size: 445429048,
        price_times_1bil: 512500000,
        fee_amount_bp: 10,
        unfilled_size: 0,
        base_balance: 0,
        quote_balance: 445429048,
      },
      makers: [
        TestOrder {
          account: 2,
          is_long: False,
          size: 139061203,
          price_times_1bil: 492500000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 139061203,
          quote_balance: 0,
        },
        TestOrder {
          account: 3,
          is_long: False,
          size: 689329315,
          price_times_1bil: 482100000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 689329315,
          quote_balance: 0,
        },
        TestOrder {
          account: 4,
          is_long: False,
          size: 189528912,
          price_times_1bil: 476300000,
          fee_amount_bp: 10,
          unfilled_size: 148789579,
          base_balance: 189528912,
          quote_balance: 0,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 869129, usd: 420216 },
        Balance { account: 1, ada: 868260722, usd: 25211600 },
        Balance { account: 2, ada: 0, usd: 68419155 },
        Balance { account: 3, ada: 0, usd: 331993337 },
        Balance { account: 4, ada: 0, usd: 19384740 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_22_lo_multiple() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_long: False,
        size: 1021589015,
        price_times_1bil: 491500000,
        fee_amount_bp: 10,
        unfilled_size: 0,
        base_balance: 1021589015,
        quote_balance: 0,
      },
      makers: [
        TestOrder {
          account: 2,
          is_long: True,
          size: 166850088,
          price_times_1bil: 501200000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 0,
          quote_balance: 166850088,
        },
        TestOrder {
          account: 3,
          is_long: True,
          size: 232321347,
          price_times_1bil: 502300000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 0,
          quote_balance: 232321347,
        },
        TestOrder {
          account: 4,
          is_long: True,
          size: 120838210,
          price_times_1bil: 512500000,
          fee_amount_bp: 10,
          unfilled_size: 4924715,
          base_balance: 0,
          quote_balance: 120838210,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 1021588, usd: 515084 },
        Balance { account: 1, ada: 5, usd: 514569846 },
        Balance { account: 2, ada: 332568312, usd: 0 },
        Balance { account: 3, ada: 462052609, usd: 0 },
        Balance { account: 4, ada: 225946501, usd: 0 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_23_lo_multiple() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_long: True,
        size: 540733901,
        price_times_1bil: 493500000,
        fee_amount_bp: 10,
        unfilled_size: 100021657,
        base_balance: 0,
        quote_balance: 540733901,
      },
      makers: [
        TestOrder {
          account: 2,
          is_long: False,
          size: 258907125,
          price_times_1bil: 479900000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 258907125,
          quote_balance: 0,
        },
        TestOrder {
          account: 2,
          is_long: False,
          size: 510250913,
          price_times_1bil: 480100000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 510250913,
          quote_balance: 0,
        },
        TestOrder {
          account: 2,
          is_long: False,
          size: 123875891,
          price_times_1bil: 479900000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 123875891,
          quote_balance: 0,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 893033, usd: 428668 },
        Balance { account: 1, ada: 892140896, usd: 12043212 },
        Balance { account: 2, ada: 0, usd: 428240364 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_24_lo_multiple() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_long: False,
        size: 2903567801,
        price_times_1bil: 1200000000,
        fee_amount_bp: 10,
        unfilled_size: 598663484,
        base_balance: 2903567801,
        quote_balance: 0,
      },
      makers: [
        TestOrder {
          account: 2,
          is_long: True,
          size: 621909385,
          price_times_1bil: 1200000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 0,
          quote_balance: 621909385,
        },
        TestOrder {
          account: 2,
          is_long: True,
          size: 1074478218,
          price_times_1bil: 1200000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 0,
          quote_balance: 1074478218,
        },
        TestOrder {
          account: 2,
          is_long: True,
          size: 1069497577,
          price_times_1bil: 1200000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 0,
          quote_balance: 1069497577,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 2304902, usd: 2765885 },
        Balance { account: 1, ada: 2, usd: 2763119295 },
        Balance { account: 2, ada: 2302599413, usd: 0 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_25_lo_multiple() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_long: True,
        size: 445429048,
        price_times_1bil: 512500000,
        fee_amount_bp: 10,
        unfilled_size: 0,
        base_balance: 0,
        quote_balance: 445429048,
      },
      makers: [
        TestOrder {
          account: 2,
          is_long: False,
          size: 139061203,
          price_times_1bil: 512500000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 139061203,
          quote_balance: 0,
        },
        TestOrder {
          account: 3,
          is_long: False,
          size: 689329315,
          price_times_1bil: 512500000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 689329315,
          quote_balance: 0,
        },
        TestOrder {
          account: 4,
          is_long: False,
          size: 40739333,
          price_times_1bil: 512500000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 40739333,
          quote_balance: 0,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 869129, usd: 445427 },
        Balance { account: 1, ada: 868260722, usd: 1 },
        Balance { account: 2, ada: 0, usd: 71197598 },
        Balance { account: 3, ada: 0, usd: 352927992 },
        Balance { account: 4, ada: 0, usd: 20858030 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_26_lo_multiple() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_long: False,
        size: 869129851,
        price_times_1bil: 512500000,
        fee_amount_bp: 10,
        unfilled_size: 0,
        base_balance: 869129851,
        quote_balance: 0,
      },
      makers: [
        TestOrder {
          account: 2,
          is_long: True,
          size: 71268866,
          price_times_1bil: 512500000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 0,
          quote_balance: 71268866,
        },
        TestOrder {
          account: 3,
          is_long: True,
          size: 353281273,
          price_times_1bil: 512500000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 0,
          quote_balance: 353281273,
        },
        TestOrder {
          account: 4,
          is_long: True,
          size: 20878908,
          price_times_1bil: 512500000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 0,
          quote_balance: 20878908,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 869129, usd: 445429 },
        Balance { account: 1, ada: 5, usd: 444983618 },
        Balance { account: 2, ada: 138922140, usd: 0 },
        Balance { account: 3, ada: 688639984, usd: 0 },
        Balance { account: 4, ada: 40698593, usd: 0 },
      ],
    }
  run_test(test_case)
}
