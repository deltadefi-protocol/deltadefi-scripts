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

test s9_fill_order_22_mo_multiple() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_long: True,
        size: 300000000,
        price_times_1bil: 1200000000,
        fee_amount_bp: 10,
        unfilled_size: 0,
      },
      makers: [
        TestOrder {
          account: 2,
          is_long: False,
          size: 100000000,
          price_times_1bil: 1200000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
        TestOrder {
          account: 2,
          is_long: False,
          size: 100000000,
          price_times_1bil: 1300000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
        TestOrder {
          account: 2,
          is_long: False,
          size: 50000000,
          price_times_1bil: 1000000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 250000, usd: 300000 },
        Balance { account: 1, ada: 249750000, usd: 0 },
        Balance { account: 2, ada: 0, usd: 119880000 },
        Balance { account: 2, ada: 0, usd: 129870000 },
        Balance { account: 2, ada: 0, usd: 49950000 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_23_mo_multiple() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_long: False,
        size: 300000000,
        price_times_1bil: 1200000000,
        fee_amount_bp: 10,
        unfilled_size: 0,
      },
      makers: [
        TestOrder {
          account: 2,
          is_long: True,
          size: 100000000,
          price_times_1bil: 1000000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
        TestOrder {
          account: 2,
          is_long: True,
          size: 50000000,
          price_times_1bil: 500000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
        TestOrder {
          account: 2,
          is_long: True,
          size: 100000000,
          price_times_1bil: 1000000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 300000, usd: 250000 },
        Balance { account: 1, ada: 0, usd: 249750000 },
        Balance { account: 2, ada: 99900000, usd: 0 },
        Balance { account: 2, ada: 99900000, usd: 0 },
        Balance { account: 2, ada: 99900000, usd: 0 },
      ],
    }
  run_test(test_case)
}

// todo: 24
test s9_fill_order_25_mo_multiple() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_long: False,
        size: 250000000,
        price_times_1bil: 1200000000,
        fee_amount_bp: 10,
        unfilled_size: 0,
      },
      makers: [
        TestOrder {
          account: 2,
          is_long: True,
          size: 100000000,
          price_times_1bil: 1200000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
        TestOrder {
          account: 2,
          is_long: True,
          size: 100000000,
          price_times_1bil: 1100000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
        TestOrder {
          account: 2,
          is_long: True,
          size: 100000000,
          price_times_1bil: 1000000000,
          fee_amount_bp: 10,
          unfilled_size: 24242423,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 249999, usd: 275757 },
        Balance { account: 1, ada: 0, usd: 275481820 },
        Balance { account: 2, ada: 83250000, usd: 0 },
        Balance { account: 2, ada: 90818181, usd: 0 },
        Balance { account: 2, ada: 75681820, usd: 0 },
      ],
    }
  run_test(test_case)
}

// todo: 26
test s9_fill_order_27_mo_multiple() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_long: False,
        size: 300000000,
        price_times_1bil: 1200000000,
        fee_amount_bp: 10,
        unfilled_size: 75757577,
      },
      makers: [
        TestOrder {
          account: 2,
          is_long: True,
          size: 100000000,
          price_times_1bil: 1200000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
        TestOrder {
          account: 2,
          is_long: True,
          size: 100000000,
          price_times_1bil: 1100000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
        TestOrder {
          account: 2,
          is_long: True,
          size: 50000000,
          price_times_1bil: 1000000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 224242, usd: 250000 },
        Balance { account: 1, ada: 0, usd: 249750000 },
        Balance { account: 2, ada: 83250000, usd: 0 },
        Balance { account: 2, ada: 90818181, usd: 0 },
        Balance { account: 2, ada: 49950000, usd: 0 },
      ],
    }
  run_test(test_case)
}
// todo: 28
