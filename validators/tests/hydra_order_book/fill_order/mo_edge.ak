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

test s9_fill_order_83_mo_edge() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_long: True,
        size: 521985115,
        price_times_1bil: 492100000,
        fee_amount_bp: 10,
        unfilled_size: 0,
        base_balance: 0,
        quote_balance: 385303312,
      },
      makers: [
        TestOrder {
          account: 1,
          is_long: False,
          size: 1125812951,
          price_times_1bil: 492100000,
          fee_amount_bp: 10,
          unfilled_size: 603827836,
          base_balance: 1125812951,
          quote_balance: 0,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 521985, usd: 256868 },
        Balance { account: 1, ada: 521463130, usd: 385046444 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_84_mo_edge() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_long: False,
        size: 521985115,
        price_times_1bil: 492100000,
        fee_amount_bp: 10,
        unfilled_size: 0,
        base_balance: 521985115,
        quote_balance: 0,
      },
      makers: [
        TestOrder {
          account: 1,
          is_long: True,
          size: 554012553,
          price_times_1bil: 492100000,
          fee_amount_bp: 10,
          unfilled_size: 297143678,
          base_balance: 0,
          quote_balance: 554012553,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 521985, usd: 256868 },
        Balance { account: 1, ada: 521463130, usd: 256612007 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_85_mo_edge() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_long: True,
        size: 521985115,
        price_times_1bil: 492100000,
        fee_amount_bp: 10,
        unfilled_size: 0,
        base_balance: 0,
        quote_balance: 385303312,
      },
      makers: [
        TestOrder {
          account: 1,
          is_long: False,
          size: 125812951,
          price_times_1bil: 492100000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 125812951,
          quote_balance: 0,
        },
        TestOrder {
          account: 2,
          is_long: False,
          size: 329051011,
          price_times_1bil: 492300000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 329051011,
          quote_balance: 0,
        },
        TestOrder {
          account: 2,
          is_long: False,
          size: 285125195,
          price_times_1bil: 492500000,
          fee_amount_bp: 10,
          unfilled_size: 218004042,
          base_balance: 285125195,
          quote_balance: 0,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 521985, usd: 256960 },
        Balance { account: 1, ada: 521463130, usd: 190192420 },
        Balance { account: 2, ada: 0, usd: 194853932 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_86_mo_edge() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_long: False,
        size: 521985115,
        price_times_1bil: 492100000,
        fee_amount_bp: 10,
        unfilled_size: 0,
        base_balance: 521985115,
        quote_balance: 0,
      },
      makers: [
        TestOrder {
          account: 1,
          is_long: True,
          size: 61912553,
          price_times_1bil: 492100000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 0,
          quote_balance: 61912553,
        },
        TestOrder {
          account: 2,
          is_long: True,
          size: 161991812,
          price_times_1bil: 492300000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 0,
          quote_balance: 161991812,
        },
        TestOrder {
          account: 2,
          is_long: True,
          size: 140424158,
          price_times_1bil: 492500000,
          fee_amount_bp: 10,
          unfilled_size: 107366990,
          base_balance: 0,
          quote_balance: 140424158,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 521984, usd: 256961 },
        Balance { account: 1, ada: 125687141, usd: 256704572 },
        Balance { account: 2, ada: 395775990, usd: 0 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_87_mo_edge() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_long: True,
        size: 521985115,
        price_times_1bil: 492100000,
        fee_amount_bp: 10,
        unfilled_size: 0,
        base_balance: 0,
        quote_balance: 521985115,
      },
      makers: [
        TestOrder {
          account: 1,
          is_long: False,
          size: 1125812951,
          price_times_1bil: 492100000,
          fee_amount_bp: 10,
          unfilled_size: 65083191,
          base_balance: 1125812951,
          quote_balance: 0,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 1060729, usd: 521985 },
        Balance { account: 1, ada: 1059669031, usd: 521463130 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_88_mo_edge() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_long: False,
        size: 521985115,
        price_times_1bil: 492100000,
        fee_amount_bp: 10,
        unfilled_size: 0,
        base_balance: 2121459520,
        quote_balance: 0,
      },
      makers: [
        TestOrder {
          account: 1,
          is_long: True,
          size: 554012553,
          price_times_1bil: 492100000,
          fee_amount_bp: 10,
          unfilled_size: 32027438,
          base_balance: 0,
          quote_balance: 554012553,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 1060729, usd: 521985 },
        Balance { account: 1, ada: 2120398791, usd: 521463130 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_89_mo_edge() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_long: True,
        size: 521985115,
        price_times_1bil: 492100000,
        fee_amount_bp: 10,
        unfilled_size: 157656591,
        base_balance: 0,
        quote_balance: 521985115,
      },
      makers: [
        TestOrder {
          account: 1,
          is_long: False,
          size: 125812951,
          price_times_1bil: 492100000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 125812951,
          quote_balance: 0,
        },
        TestOrder {
          account: 2,
          is_long: False,
          size: 329051011,
          price_times_1bil: 492300000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 329051011,
          quote_balance: 0,
        },
        TestOrder {
          account: 2,
          is_long: False,
          size: 285125195,
          price_times_1bil: 492500000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 285125195,
          quote_balance: 0,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 739989, usd: 364327 },
        Balance { account: 1, ada: 739249168, usd: 61850642 },
        Balance { account: 2, ada: 0, usd: 302113555 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_90_mo_edge() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_long: False,
        size: 521985115,
        price_times_1bil: 492100000,
        fee_amount_bp: 10,
        unfilled_size: 320375110,
        base_balance: 2121459520,
        quote_balance: 0,
      },
      makers: [
        TestOrder {
          account: 1,
          is_long: True,
          size: 61912553,
          price_times_1bil: 492100000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 0,
          quote_balance: 61912553,
        },
        TestOrder {
          account: 2,
          is_long: True,
          size: 161991812,
          price_times_1bil: 492300000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 0,
          quote_balance: 161991812,
        },
        TestOrder {
          account: 2,
          is_long: True,
          size: 140424158,
          price_times_1bil: 492500000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 0,
          quote_balance: 140424158,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 739988, usd: 364328 },
        Balance { account: 1, ada: 1186782396, usd: 363964195 },
        Balance { account: 2, ada: 613562026, usd: 0 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_91_mo_edge() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_long: True,
        size: 521985115,
        price_times_1bil: 492100000,
        fee_amount_bp: 10,
        unfilled_size: 0,
        base_balance: 0,
        quote_balance: 385303312,
      },
      makers: [
        TestOrder {
          account: 2,
          is_long: False,
          size: 1125812951,
          price_times_1bil: 492100000,
          fee_amount_bp: 10,
          unfilled_size: 603827836,
          base_balance: 1200000000,
          quote_balance: 0,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 521985, usd: 256868 },
        Balance { account: 1, ada: 521463130, usd: 128434437 },
        Balance { account: 2, ada: 74187049, usd: 256612007 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_92_mo_edge() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_long: False,
        size: 521985115,
        price_times_1bil: 492100000,
        fee_amount_bp: 10,
        unfilled_size: 0,
        base_balance: 521985115,
        quote_balance: 0,
      },
      makers: [
        TestOrder {
          account: 2,
          is_long: True,
          size: 554012553,
          price_times_1bil: 492100000,
          fee_amount_bp: 10,
          unfilled_size: 297143678,
          base_balance: 0,
          quote_balance: 600000000,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 521985, usd: 256868 },
        Balance { account: 1, ada: 0, usd: 256612007 },
        Balance { account: 2, ada: 521463130, usd: 45987447 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_93_mo_edge() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_long: True,
        size: 521985115,
        price_times_1bil: 492100000,
        fee_amount_bp: 10,
        unfilled_size: 0,
        base_balance: 0,
        quote_balance: 521985115,
      },
      makers: [
        TestOrder {
          account: 2,
          is_long: False,
          size: 1125812951,
          price_times_1bil: 492100000,
          fee_amount_bp: 10,
          unfilled_size: 65083191,
          base_balance: 1200000000,
          quote_balance: 0,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 1060729, usd: 521985 },
        Balance { account: 1, ada: 1059669031, usd: 0 },
        Balance { account: 2, ada: 74187049, usd: 521463130 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_94_mo_edge() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_long: False,
        size: 521985115,
        price_times_1bil: 492100000,
        fee_amount_bp: 10,
        unfilled_size: 0,
        base_balance: 2121459520,
        quote_balance: 0,
      },
      makers: [
        TestOrder {
          account: 2,
          is_long: True,
          size: 554012553,
          price_times_1bil: 492100000,
          fee_amount_bp: 10,
          unfilled_size: 32027438,
          base_balance: 0,
          quote_balance: 600000000,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 1060729, usd: 521985 },
        Balance { account: 1, ada: 1060729760, usd: 521463130 },
        Balance { account: 2, ada: 1059669031, usd: 45987447 },
      ],
    }
  run_test(test_case)
}
