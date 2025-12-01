use cardano/address.{Script}
use hydra_dex/types.{FillOrder}
use hydra_order_book/core as ob
use tests/hydra_order_book/fill_order/utils.{
  Balance, LimitOrder, TestCase, fill_order_test,
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
      taker: LimitOrder {
        account: 1,
        is_long: True,
        size: 360000000,
        price_times_1bil: 1200000000,
        fee_amount_bp: 10,
        unfilled_size: 0,
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
        LimitOrder {
          account: 3,
          is_long: False,
          size: 100000000,
          price_times_1bil: 1200000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
        LimitOrder {
          account: 4,
          is_long: False,
          size: 100000000,
          price_times_1bil: 1200000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
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
      taker: LimitOrder {
        account: 1,
        is_long: False,
        size: 300000000,
        price_times_1bil: 1200000000,
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
        LimitOrder {
          account: 3,
          is_long: True,
          size: 120000000,
          price_times_1bil: 1200000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
        LimitOrder {
          account: 4,
          is_long: True,
          size: 120000000,
          price_times_1bil: 1200000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
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
      taker: LimitOrder {
        account: 1,
        is_long: True,
        size: 450000000,
        price_times_1bil: 1500000000,
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
        LimitOrder {
          account: 3,
          is_long: False,
          size: 100000000,
          price_times_1bil: 1100000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
        LimitOrder {
          account: 4,
          is_long: False,
          size: 100000000,
          price_times_1bil: 1200000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
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
      taker: LimitOrder {
        account: 1,
        is_long: False,
        size: 300000000,
        price_times_1bil: 1200000000,
        fee_amount_bp: 10,
        unfilled_size: 0,
      },
      makers: [
        LimitOrder {
          account: 2,
          is_long: True,
          size: 150000000,
          price_times_1bil: 1500000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
        LimitOrder {
          account: 3,
          is_long: True,
          size: 140000000,
          price_times_1bil: 1400000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
        LimitOrder {
          account: 4,
          is_long: True,
          size: 130000000,
          price_times_1bil: 1300000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
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
      taker: LimitOrder {
        account: 1,
        is_long: True,
        size: 450000000,
        price_times_1bil: 1500000000,
        fee_amount_bp: 10,
        unfilled_size: 0,
      },
      makers: [
        LimitOrder {
          account: 2,
          is_long: False,
          size: 150000000,
          price_times_1bil: 1200000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
        LimitOrder {
          account: 3,
          is_long: False,
          size: 100000000,
          price_times_1bil: 1300000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
        LimitOrder {
          account: 4,
          is_long: False,
          size: 100000000,
          price_times_1bil: 1400000000,
          fee_amount_bp: 10,
          unfilled_size: 50000000,
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
      taker: LimitOrder {
        account: 1,
        is_long: False,
        size: 300000000,
        price_times_1bil: 1200000000,
        fee_amount_bp: 10,
        unfilled_size: 0,
      },
      makers: [
        LimitOrder {
          account: 2,
          is_long: True,
          size: 225000000,
          price_times_1bil: 1500000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
        LimitOrder {
          account: 3,
          is_long: True,
          size: 140000000,
          price_times_1bil: 1400000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
        LimitOrder {
          account: 4,
          is_long: True,
          size: 130000000,
          price_times_1bil: 1300000000,
          fee_amount_bp: 10,
          unfilled_size: 65000000,
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
      taker: LimitOrder {
        account: 1,
        is_long: True,
        size: 750000000,
        price_times_1bil: 1500000000,
        fee_amount_bp: 10,
        unfilled_size: 300000000,
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
        LimitOrder {
          account: 3,
          is_long: False,
          size: 100000000,
          price_times_1bil: 1300000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
        LimitOrder {
          account: 4,
          is_long: False,
          size: 100000000,
          price_times_1bil: 1400000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
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
      taker: LimitOrder {
        account: 1,
        is_long: False,
        size: 500000000,
        price_times_1bil: 1200000000,
        fee_amount_bp: 10,
        unfilled_size: 200000000,
      },
      makers: [
        LimitOrder {
          account: 2,
          is_long: True,
          size: 150000000,
          price_times_1bil: 1500000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
        LimitOrder {
          account: 3,
          is_long: True,
          size: 140000000,
          price_times_1bil: 1400000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
        LimitOrder {
          account: 4,
          is_long: True,
          size: 130000000,
          price_times_1bil: 1300000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
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
      taker: LimitOrder {
        account: 1,
        is_long: True,
        size: 445429048,
        price_times_1bil: 512500000,
        fee_amount_bp: 10,
        unfilled_size: 0,
      },
      makers: [
        LimitOrder {
          account: 2,
          is_long: False,
          size: 139061203,
          price_times_1bil: 492500000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
        LimitOrder {
          account: 3,
          is_long: False,
          size: 689329315,
          price_times_1bil: 482100000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
        LimitOrder {
          account: 4,
          is_long: False,
          size: 189528912,
          price_times_1bil: 476300000,
          fee_amount_bp: 10,
          unfilled_size: 148789579,
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
      taker: LimitOrder {
        account: 1,
        is_long: False,
        size: 1021589015,
        price_times_1bil: 491500000,
        fee_amount_bp: 10,
        unfilled_size: 0,
      },
      makers: [
        LimitOrder {
          account: 2,
          is_long: True,
          size: 166850088,
          price_times_1bil: 501200000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
        LimitOrder {
          account: 3,
          is_long: True,
          size: 232321347,
          price_times_1bil: 502300000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
        LimitOrder {
          account: 4,
          is_long: True,
          size: 120838210,
          price_times_1bil: 512500000,
          fee_amount_bp: 10,
          unfilled_size: 4924712,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 1021587, usd: 515084 },
        Balance { account: 1, ada: 0, usd: 514569849 },
        Balance { account: 2, ada: 332568312, usd: 0 },
        Balance { account: 3, ada: 462052609, usd: 0 },
        Balance { account: 4, ada: 225946507, usd: 0 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_23_lo_multiple() {
  let test_case =
    TestCase {
      taker: LimitOrder {
        account: 1,
        is_long: True,
        size: 540733901,
        price_times_1bil: 493500000,
        fee_amount_bp: 10,
        unfilled_size: 100021657,
      },
      makers: [
        LimitOrder {
          account: 2,
          is_long: False,
          size: 258907125,
          price_times_1bil: 479900000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
        LimitOrder {
          account: 2,
          is_long: False,
          size: 510250913,
          price_times_1bil: 480100000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
        LimitOrder {
          account: 2,
          is_long: False,
          size: 123875891,
          price_times_1bil: 479900000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 893033, usd: 428668 },
        Balance { account: 1, ada: 892140896, usd: 12043212 },
        Balance { account: 2, ada: 0, usd: 124125280 },
        Balance { account: 2, ada: 0, usd: 244726492 },
        Balance { account: 2, ada: 0, usd: 59388592 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_24_lo_multiple() {
  let test_case =
    TestCase {
      taker: LimitOrder {
        account: 1,
        is_long: False,
        size: 2903567801,
        price_times_1bil: 1200000000,
        fee_amount_bp: 10,
        unfilled_size: 598663486,
      },
      makers: [
        LimitOrder {
          account: 2,
          is_long: True,
          size: 621909385,
          price_times_1bil: 1200000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
        LimitOrder {
          account: 2,
          is_long: True,
          size: 1074478218,
          price_times_1bil: 1200000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
        LimitOrder {
          account: 2,
          is_long: True,
          size: 1069497577,
          price_times_1bil: 1200000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 2304902, usd: 2765885 },
        Balance { account: 1, ada: 0, usd: 2763119295 },
        Balance { account: 2, ada: 517739563, usd: 0 },
        Balance { account: 2, ada: 894503117, usd: 0 },
        Balance { account: 2, ada: 890356733, usd: 0 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_25_lo_multiple() {
  let test_case =
    TestCase {
      taker: LimitOrder {
        account: 1,
        is_long: True,
        size: 445429048,
        price_times_1bil: 512500000,
        fee_amount_bp: 10,
        unfilled_size: 0,
      },
      makers: [
        LimitOrder {
          account: 2,
          is_long: False,
          size: 139061203,
          price_times_1bil: 512500000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
        LimitOrder {
          account: 3,
          is_long: False,
          size: 689329315,
          price_times_1bil: 512500000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
        LimitOrder {
          account: 4,
          is_long: False,
          size: 40739333,
          price_times_1bil: 512500000,
          fee_amount_bp: 10,
          unfilled_size: 0,
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
      taker: LimitOrder {
        account: 1,
        is_long: False,
        size: 869129851,
        price_times_1bil: 512500000,
        fee_amount_bp: 10,
        unfilled_size: 5,
      },
      makers: [
        LimitOrder {
          account: 2,
          is_long: True,
          size: 71268866,
          price_times_1bil: 512500000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
        LimitOrder {
          account: 3,
          is_long: True,
          size: 353281273,
          price_times_1bil: 512500000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
        LimitOrder {
          account: 4,
          is_long: True,
          size: 20878908,
          price_times_1bil: 512500000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 869129, usd: 445429 },
        Balance { account: 1, ada: 0, usd: 444983618 },
        Balance { account: 2, ada: 138922140, usd: 0 },
        Balance { account: 3, ada: 688639984, usd: 0 },
        Balance { account: 4, ada: 40698593, usd: 0 },
      ],
    }
  run_test(test_case)
}
