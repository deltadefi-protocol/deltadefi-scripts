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

test s9_fill_order_83_mo_edge() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_buy: True,
        size: 256868875,
        price_times_1tri: 492100000000,
        fee_amount_bp: 10,
        unfilled_size: 0,
        base_balance: 0,
        quote_balance: 385303312,
        order_type: MarketOrder,
      },
      makers: [
        TestOrder {
          account: 1,
          is_buy: False,
          size: 1125812951,
          price_times_1tri: 492100000000,
          fee_amount_bp: 10,
          unfilled_size: 603827836,
          base_balance: 1125812951,
          quote_balance: 0,
          order_type: LimitOrder,
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
        is_buy: False,
        size: 521985115,
        price_times_1tri: 492100000000,
        fee_amount_bp: 10,
        unfilled_size: 0,
        base_balance: 521985115,
        quote_balance: 0,
        order_type: MarketOrder,
      },
      makers: [
        TestOrder {
          account: 1,
          is_buy: True,
          size: 554012553,
          price_times_1tri: 492100000000,
          fee_amount_bp: 10,
          unfilled_size: 297143678,
          base_balance: 0,
          quote_balance: 554012553,
          order_type: LimitOrder,
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
        is_buy: True,
        size: 256868875,
        price_times_1tri: 492100000000,
        fee_amount_bp: 10,
        unfilled_size: 0,
        base_balance: 0,
        quote_balance: 385303312,
        order_type: MarketOrder,
      },
      makers: [
        TestOrder {
          account: 1,
          is_buy: False,
          size: 125812951,
          price_times_1tri: 492100000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 125812951,
          quote_balance: 0,
          order_type: LimitOrder,
        },
        TestOrder {
          account: 2,
          is_buy: False,
          size: 329051011,
          price_times_1tri: 492300000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 329051011,
          quote_balance: 0,
          order_type: LimitOrder,
        },
        TestOrder {
          account: 2,
          is_buy: False,
          size: 285125195,
          price_times_1tri: 492500000000,
          fee_amount_bp: 10,
          unfilled_size: 218004042,
          base_balance: 285125195,
          quote_balance: 0,
          order_type: LimitOrder,
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
        is_buy: False,
        size: 521985115,
        price_times_1tri: 492100000000,
        fee_amount_bp: 10,
        unfilled_size: 0,
        base_balance: 521985115,
        quote_balance: 0,
        order_type: MarketOrder,
      },
      makers: [
        TestOrder {
          account: 1,
          is_buy: True,
          size: 61912553,
          price_times_1tri: 492100000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 0,
          quote_balance: 61912553,
          order_type: LimitOrder,
        },
        TestOrder {
          account: 2,
          is_buy: True,
          size: 161991812,
          price_times_1tri: 492300000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 0,
          quote_balance: 161991812,
          order_type: LimitOrder,
        },
        TestOrder {
          account: 2,
          is_buy: True,
          size: 140424158,
          price_times_1tri: 492500000000,
          fee_amount_bp: 10,
          unfilled_size: 107366990,
          base_balance: 0,
          quote_balance: 140424158,
          order_type: LimitOrder,
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
        is_buy: True,
        size: 521985115,
        price_times_1tri: 492100000000,
        fee_amount_bp: 10,
        unfilled_size: 0,
        base_balance: 0,
        quote_balance: 521985115,
        order_type: MarketOrder,
      },
      makers: [
        TestOrder {
          account: 1,
          is_buy: False,
          size: 1125812951,
          price_times_1tri: 492100000000,
          fee_amount_bp: 10,
          unfilled_size: 65083191,
          base_balance: 1125812951,
          quote_balance: 0,
          order_type: LimitOrder,
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
        is_buy: False,
        size: 1060729760,
        price_times_1tri: 492100000000,
        fee_amount_bp: 10,
        unfilled_size: 0,
        base_balance: 2121459520,
        quote_balance: 0,
        order_type: MarketOrder,
      },
      makers: [
        TestOrder {
          account: 1,
          is_buy: True,
          size: 554012553,
          price_times_1tri: 492100000000,
          fee_amount_bp: 10,
          unfilled_size: 32027438,
          base_balance: 0,
          quote_balance: 554012553,
          order_type: LimitOrder,
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
        is_buy: True,
        size: 521985115,
        price_times_1tri: 492100000000,
        fee_amount_bp: 10,
        unfilled_size: 157656591,
        base_balance: 0,
        quote_balance: 521985115,
        order_type: MarketOrder,
      },
      makers: [
        TestOrder {
          account: 1,
          is_buy: False,
          size: 125812951,
          price_times_1tri: 492100000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 125812951,
          quote_balance: 0,
          order_type: LimitOrder,
        },
        TestOrder {
          account: 2,
          is_buy: False,
          size: 329051011,
          price_times_1tri: 492300000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 329051011,
          quote_balance: 0,
          order_type: LimitOrder,
        },
        TestOrder {
          account: 2,
          is_buy: False,
          size: 285125195,
          price_times_1tri: 492500000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 285125195,
          quote_balance: 0,
          order_type: LimitOrder,
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
        is_buy: False,
        size: 1060729760,
        price_times_1tri: 492100000000,
        fee_amount_bp: 10,
        unfilled_size: 320375110,
        base_balance: 2121459520,
        quote_balance: 0,
        order_type: MarketOrder,
      },
      makers: [
        TestOrder {
          account: 1,
          is_buy: True,
          size: 61912553,
          price_times_1tri: 492100000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 0,
          quote_balance: 61912553,
          order_type: LimitOrder,
        },
        TestOrder {
          account: 2,
          is_buy: True,
          size: 161991812,
          price_times_1tri: 492300000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 0,
          quote_balance: 161991812,
          order_type: LimitOrder,
        },
        TestOrder {
          account: 2,
          is_buy: True,
          size: 140424158,
          price_times_1tri: 492500000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 0,
          quote_balance: 140424158,
          order_type: LimitOrder,
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
        is_buy: True,
        size: 256868875,
        price_times_1tri: 492100000000,
        fee_amount_bp: 10,
        unfilled_size: 0,
        base_balance: 0,
        quote_balance: 385303312,
        order_type: MarketOrder,
      },
      makers: [
        TestOrder {
          account: 2,
          is_buy: False,
          size: 1125812951,
          price_times_1tri: 492100000000,
          fee_amount_bp: 10,
          unfilled_size: 603827836,
          base_balance: 1200000000,
          quote_balance: 0,
          order_type: LimitOrder,
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
        is_buy: False,
        size: 521985115,
        price_times_1tri: 492100000000,
        fee_amount_bp: 10,
        unfilled_size: 0,
        base_balance: 521985115,
        quote_balance: 0,
        order_type: MarketOrder,
      },
      makers: [
        TestOrder {
          account: 2,
          is_buy: True,
          size: 554012553,
          price_times_1tri: 492100000000,
          fee_amount_bp: 10,
          unfilled_size: 297143678,
          base_balance: 0,
          quote_balance: 600000000,
          order_type: LimitOrder,
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
        is_buy: True,
        size: 521985115,
        price_times_1tri: 492100000000,
        fee_amount_bp: 10,
        unfilled_size: 0,
        base_balance: 0,
        quote_balance: 521985115,
        order_type: MarketOrder,
      },
      makers: [
        TestOrder {
          account: 2,
          is_buy: False,
          size: 1125812951,
          price_times_1tri: 492100000000,
          fee_amount_bp: 10,
          unfilled_size: 65083191,
          base_balance: 1200000000,
          quote_balance: 0,
          order_type: LimitOrder,
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
        is_buy: False,
        size: 1060729760,
        price_times_1tri: 492100000000,
        fee_amount_bp: 10,
        unfilled_size: 0,
        base_balance: 2121459520,
        quote_balance: 0,
        order_type: MarketOrder,
      },
      makers: [
        TestOrder {
          account: 2,
          is_buy: True,
          size: 554012553,
          price_times_1tri: 492100000000,
          fee_amount_bp: 10,
          unfilled_size: 32027438,
          base_balance: 0,
          quote_balance: 600000000,
          order_type: LimitOrder,
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

test s9_fill_order_95_mo_edge() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_buy: False,
        size: 34700000,
        price_times_1tri: 471100000000,
        fee_amount_bp: 10,
        unfilled_size: 0,
        base_balance: 34700000,
        quote_balance: 0,
        order_type: MarketOrder,
      },
      makers: [
        TestOrder {
          account: 1,
          is_buy: True,
          size: 33999999,
          price_times_1tri: 613400000000,
          fee_amount_bp: 10,
          unfilled_size: 12715019,
          base_balance: 0,
          quote_balance: 34000000,
          order_type: LimitOrder,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 34700, usd: 21284 },
        Balance { account: 1, ada: 34665300, usd: 21263697 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_96_mo_edge() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_buy: False,
        size: 35800000,
        price_times_1tri: 451700000000,
        fee_amount_bp: 10,
        unfilled_size: 0,
        base_balance: 35800000,
        quote_balance: 0,
        order_type: MarketOrder,
      },
      makers: [
        TestOrder {
          account: 1,
          is_buy: True,
          size: 12430680,
          price_times_1tri: 583600000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 0,
          quote_balance: 12430680,
          order_type: LimitOrder,
        },
        TestOrder {
          account: 1,
          is_buy: True,
          size: 35499999,
          price_times_1tri: 561300000000,
          fee_amount_bp: 10,
          unfilled_size: 27361149,
          base_balance: 0,
          quote_balance: 35500000,
          order_type: LimitOrder,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 35800, usd: 20569 },
        Balance { account: 1, ada: 35764200, usd: 20548962 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_97_mo_edge() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_buy: True,
        size: 100000000,
        price_times_1tri: 10000000,
        fee_amount_bp: 10,
        unfilled_size: 18595724,
        base_balance: 0,
        quote_balance: 100000000,
        order_type: MarketOrder,
      },
      makers: [
        TestOrder {
          account: 1,
          is_buy: False,
          size: 1000000000000,
          price_times_1tri: 10000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 1000000000000,
          quote_balance: 0,
          order_type: LimitOrder,
        },
        TestOrder {
          account: 1,
          is_buy: False,
          size: 7140427670000,
          price_times_1tri: 10000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 7140427670000,
          quote_balance: 0,
          order_type: LimitOrder,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 8140427670, usd: 81404 },
        Balance { account: 1, ada: 8132287242330, usd: 81322872 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_98_mo_edge() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_buy: True,
        size: 100000000,
        price_times_1tri: 10000000,
        fee_amount_bp: 10,
        unfilled_size: 18595723,
        base_balance: 0,
        quote_balance: 100000000,
        order_type: MarketOrder,
      },
      makers: [
        TestOrder {
          account: 1,
          is_buy: False,
          size: 1000000000000,
          price_times_1tri: 10000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 1000000000000,
          quote_balance: 0,
          order_type: LimitOrder,
        },
        TestOrder {
          account: 1,
          is_buy: False,
          size: 7140427670000,
          price_times_1tri: 10000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 7140427670000,
          quote_balance: 0,
          order_type: LimitOrder,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 8140427670, usd: 81404 },
        Balance { account: 1, ada: 8132287242330, usd: 81322873 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_99_mo_edge() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_buy: True,
        size: 10000000000000,
        price_times_1tri: 10000000,
        fee_amount_bp: 10,
        unfilled_size: 9999918595724,
        base_balance: 0,
        quote_balance: 10000000000000,
        order_type: MarketOrder,
      },
      makers: [
        TestOrder {
          account: 1,
          is_buy: False,
          size: 1000000000000,
          price_times_1tri: 10000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 1000000000000,
          quote_balance: 0,
          order_type: LimitOrder,
        },
        TestOrder {
          account: 1,
          is_buy: False,
          size: 7140427670000,
          price_times_1tri: 10000000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 7140427670000,
          quote_balance: 0,
          order_type: LimitOrder,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 8140427670, usd: 81404 },
        Balance { account: 1, ada: 8132287242330, usd: 81322872 },
      ],
    }
  run_test(test_case)
}

test s9_fill_order_100_mo_edge() {
  let test_case =
    TestCase {
      taker: TestOrder {
        account: 1,
        is_buy: False,
        size: 91295129512945,
        price_times_1tri: 100000,
        fee_amount_bp: 10,
        unfilled_size: 83154701835245,
        base_balance: 91295129512945,
        quote_balance: 0,
        order_type: MarketOrder,
      },
      makers: [
        TestOrder {
          account: 1,
          is_buy: True,
          size: 100000,
          price_times_1tri: 100000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 0,
          quote_balance: 100000,
          order_type: LimitOrder,
        },
        TestOrder {
          account: 1,
          is_buy: True,
          size: 714042,
          price_times_1tri: 100000,
          fee_amount_bp: 10,
          unfilled_size: 0,
          base_balance: 0,
          quote_balance: 714042,
          order_type: LimitOrder,
        },
      ],
      payoff: [
        Balance { account: 0, ada: 8140420000, usd: 814 },
        Balance { account: 1, ada: 8132287257700, usd: 813228 },
      ],
    }
  run_test(test_case)
}
