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

// todo: 29

test s9_fill_order_30_mo_complex() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_long: True,
        size: 1100000000,
        price_times_1bil: 2000000000,
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
          size: 300000000,
          price_times_1bil: 1500000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
        TestOrder {
          account: 2,
          is_long: False,
          size: 50000000,
          price_times_1bil: 1190000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
        TestOrder {
          account: 2,
          is_long: False,
          size: 200000000,
          price_times_1bil: 1200000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 550000, usd: 729500 },
        Balance { account: 1, ada: 549450000, usd: 370500000 },
        Balance { account: 2, ada: 0, usd: 99900000 },
        Balance { account: 2, ada: 0, usd: 449550000 },
        Balance { account: 2, ada: 0, usd: 59440500 },
        Balance { account: 2, ada: 0, usd: 119880000 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_31_mo_complex() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_long: True,
        size: 1750000000,
        price_times_1bil: 2000000000,
        fee_amount_bp: 10,
        unfilled_size: 0,
      },
      makers: [
        TestOrder {
          account: 2,
          is_long: False,
          size: 100000000,
          price_times_1bil: 1110000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
        TestOrder {
          account: 2,
          is_long: False,
          size: 500000000,
          price_times_1bil: 1200000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
        TestOrder {
          account: 2,
          is_long: False,
          size: 50000000,
          price_times_1bil: 1190000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
        TestOrder {
          account: 2,
          is_long: False,
          size: 200000000,
          price_times_1bil: 1200000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
        TestOrder {
          account: 2,
          is_long: False,
          size: 450000000,
          price_times_1bil: 1223000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 875000, usd: 1047975 },
        Balance { account: 1, ada: 874125000, usd: 702025000 },
        Balance { account: 2, ada: 0, usd: 110889000 },
        Balance { account: 2, ada: 0, usd: 359640000 },
        Balance { account: 2, ada: 0, usd: 59440500 },
        Balance { account: 2, ada: 0, usd: 119880000 },
        Balance { account: 2, ada: 0, usd: 397077525 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_32_mo_complex() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_long: False,
        size: 300000000,
        price_times_1bil: 1200000000,
        fee_amount_bp: 10,
        unfilled_size: 71256377,
      },
      makers: [
        TestOrder {
          account: 2,
          is_long: True,
          size: 500000000,
          price_times_1bil: 1252000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 228743, usd: 286387 },
        Balance { account: 1, ada: 0, usd: 286100630 },
        Balance { account: 2, ada: 228514880, usd: 0 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_33_mo_complex() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_long: False,
        size: 349755986,
        price_times_1bil: 1500000000,
        fee_amount_bp: 10,
        unfilled_size: 0,
      },
      makers: [
        TestOrder {
          account: 2,
          is_long: True,
          size: 100000000,
          price_times_1bil: 1425000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
        TestOrder {
          account: 2,
          is_long: True,
          size: 500000000,
          price_times_1bil: 1279000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
        TestOrder {
          account: 2,
          is_long: True,
          size: 50000000,
          price_times_1bil: 1321000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
        TestOrder {
          account: 2,
          is_long: True,
          size: 200000000,
          price_times_1bil: 1295000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 349755, usd: 460408 },
        Balance { account: 1, ada: 0, usd: 459948340 },
        Balance { account: 2, ada: 70105263, usd: 0 },
        Balance { account: 2, ada: 164345848, usd: 0 },
        Balance { account: 2, ada: 37812263, usd: 0 },
        Balance { account: 2, ada: 77142857, usd: 0 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_34_mo_complex() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_long: False,
        size: 657651074,
        price_times_1bil: 1200000000,
        fee_amount_bp: 10,
        unfilled_size: 0,
      },
      makers: [
        TestOrder {
          account: 2,
          is_long: True,
          size: 100000000,
          price_times_1bil: 1500000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
        TestOrder {
          account: 2,
          is_long: True,
          size: 500000000,
          price_times_1bil: 1200000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
        TestOrder {
          account: 2,
          is_long: True,
          size: 50000000,
          price_times_1bil: 1350000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
        TestOrder {
          account: 2,
          is_long: True,
          size: 200000000,
          price_times_1bil: 1322000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
        TestOrder {
          account: 2,
          is_long: True,
          size: 450000000,
          price_times_1bil: 1200000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 657649, usd: 823965 },
        Balance { account: 1, ada: 0, usd: 823141323 },
        Balance { account: 2, ada: 66600000, usd: 0 },
        Balance { account: 2, ada: 207263602, usd: 0 },
        Balance { account: 2, ada: 37000000, usd: 0 },
        Balance { account: 2, ada: 75567323, usd: 0 },
        Balance { account: 2, ada: 270562500, usd: 0 },
      ],
    }
  run_test(test_case)
}
