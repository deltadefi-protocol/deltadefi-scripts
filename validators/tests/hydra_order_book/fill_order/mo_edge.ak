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

test s9_fill_order_35_mo_edge() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_long: True,
        size: 100000000,
        price_times_1bil: 1200000000,
        fee_amount_bp: 10,
        unfilled_size: 0,
      },
      makers: [
        TestOrder {
          account: 1,
          is_long: False,
          size: 100000000,
          price_times_1bil: 1100000000,
          fee_amount_bp: 10,
          unfilled_size: 16666667,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 83333, usd: 91666 },
        Balance { account: 1, ada: 83250000, usd: 8333334 },
        Balance { account: 1, ada: 0, usd: 91575000 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_36_mo_edge() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_long: True,
        size: 100000000,
        price_times_1bil: 1200000000,
        fee_amount_bp: 10,
        unfilled_size: 0,
      },
      makers: [
        TestOrder {
          account: 1,
          is_long: False,
          size: 100000000,
          price_times_1bil: 1100000000,
          fee_amount_bp: 10,
          unfilled_size: 16666667,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 83333, usd: 91666 },
        Balance { account: 1, ada: 83250000, usd: 8333334 },
        Balance { account: 1, ada: 0, usd: 91575000 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_37_mo_edge() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_long: True,
        size: 250000000,
        price_times_1bil: 1200000000,
        fee_amount_bp: 10,
        unfilled_size: 0,
      },
      makers: [
        TestOrder {
          account: 1,
          is_long: False,
          size: 100000000,
          price_times_1bil: 1100000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
        TestOrder {
          account: 2,
          is_long: False,
          size: 125000000,
          price_times_1bil: 1150000000,
          fee_amount_bp: 10,
          unfilled_size: 16666667,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 208333, usd: 234583 },
        Balance { account: 1, ada: 208125000, usd: 15416668 },
        Balance { account: 1, ada: 0, usd: 109890000 },
        Balance { account: 2, ada: 0, usd: 124458749 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_38_mo_edge() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_long: False,
        size: 250000000,
        price_times_1bil: 1200000000,
        fee_amount_bp: 10,
        unfilled_size: 73076924,
      },
      makers: [
        TestOrder {
          account: 1,
          is_long: True,
          size: 100000000,
          price_times_1bil: 1300000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
        TestOrder {
          account: 2,
          is_long: True,
          size: 125000000,
          price_times_1bil: 1250000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 176923, usd: 225000 },
        Balance { account: 1, ada: 0, usd: 224775000 },
        Balance { account: 1, ada: 76846153, usd: 0 },
        Balance { account: 2, ada: 99900000, usd: 0 },
      ],
    }
  run_test(test_case)
}
