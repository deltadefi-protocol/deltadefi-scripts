use aiken/collection/list
use cardano/address.{Script}
use cardano/assets.{from_asset, from_lovelace, merge, negate, zero}
use cardano/transaction.{Transaction}
use hydra_dex/order_utils.{get_order_settlement_info}
use hydra_dex/types.{
  FillOrderRedeemer, HydraAccountBalanceDatum, HydraOrderBookDatum,
}
use hydra_order_book/fill_order
use mocktail.{
  MocktailTx, complete, mint, mock_tx_hash, mocktail_tx, ref_tx_in,
  ref_tx_in_inline_datum, required_signer_hash, tx_in, tx_in_inline_datum,
  tx_out, tx_out_inline_datum,
}
use tests/utils.{
  mock_account, mock_account_2, mock_account_3, mock_account_4,
  mock_dex_order_book_address, mock_dex_order_book_datum,
  mock_dex_order_book_token, mock_fee_account,
  mock_hydra_account_balance_address, mock_hydra_account_balance_token,
  mock_hydra_balance, mock_hydra_fill_order, mock_hydra_order_book_address,
  mock_hydra_order_book_token, mock_operation_key, mock_order,
  mock_script_account, mock_usd,
}

type TestCase {
  input_orders: List<HydraOrderBookDatum>,
  output_order: Option<HydraOrderBookDatum>,
  input_balances: List<HydraAccountBalanceDatum>,
  output_balances: List<HydraAccountBalanceDatum>,
  burnt_order_ids: List<ByteArray>,
  is_operation_key_signed: Bool,
}

fn add_order_inputs(
  mock_tx: MocktailTx,
  input_orders: List<HydraOrderBookDatum>,
) -> MocktailTx {
  list.foldr(
    input_orders,
    mock_tx,
    fn(input_order, tx) {
      tx
        |> tx_in(
            True,
            mock_tx_hash(0),
            0,
            from_asset(mock_hydra_order_book_token, input_order.order_id, 1),
            mock_hydra_order_book_address,
          )
        |> tx_in_inline_datum(True, input_order)
    },
  )
}

fn add_order_output(
  mock_tx: MocktailTx,
  output_order: Option<HydraOrderBookDatum>,
) -> MocktailTx {
  when output_order is {
    Some(order) ->
      mock_tx
        |> tx_out(
            True,
            mock_hydra_order_book_address,
            from_asset(mock_hydra_order_book_token, order.order_id, 1),
          )
        |> tx_out_inline_datum(True, order)
    None -> mock_tx
  }
}

fn add_input_balances(
  mock_tx: MocktailTx,
  input_balances: List<HydraAccountBalanceDatum>,
) -> MocktailTx {
  list.foldr(
    input_balances,
    mock_tx,
    fn(input_balance, tx) {
      tx
        |> tx_in(
            True,
            mock_tx_hash(0),
            0,
            from_asset(mock_hydra_account_balance_token, "", 1),
            mock_hydra_account_balance_address,
          )
        |> tx_in_inline_datum(True, input_balance)
    },
  )
}

fn add_output_balances(
  mock_tx: MocktailTx,
  output_balances: List<HydraAccountBalanceDatum>,
) -> MocktailTx {
  list.foldr(
    output_balances,
    mock_tx,
    fn(input_balance, tx) {
      tx
        |> tx_out(
            True,
            mock_hydra_account_balance_address,
            from_asset(mock_hydra_account_balance_token, "", 1),
          )
        |> tx_out_inline_datum(True, input_balance)
    },
  )
}

fn add_burnt_tokens(
  mock_tx: MocktailTx,
  burnt_order_ids: List<ByteArray>,
) -> MocktailTx {
  list.foldr(
    burnt_order_ids,
    mock_tx,
    fn(order_id, tx) {
      tx
        |> mint(True, -1, mock_hydra_order_book_token, order_id)
    },
  )
}

fn mock_tx(test_case: TestCase) -> Transaction {
  let TestCase {
    input_orders,
    output_order,
    input_balances,
    output_balances,
    burnt_order_ids,
    is_operation_key_signed,
  } = test_case

  mocktail_tx()
    |> add_order_inputs(input_orders)
    |> add_order_output(output_order)
    |> add_input_balances(input_balances)
    |> add_output_balances(output_balances)
    |> add_burnt_tokens(burnt_order_ids)
    |> ref_tx_in(
        True,
        mock_tx_hash(0),
        0,
        from_asset(mock_dex_order_book_token, "", 1),
        mock_dex_order_book_address,
      )
    |> ref_tx_in_inline_datum(True, mock_dex_order_book_datum)
    |> required_signer_hash(is_operation_key_signed, mock_operation_key)
    |> complete()
}

fn base_case() {
  let order_1 =
    mock_order("order_1", True, 8_000_000, 997_300_000, 10, 0, mock_account)
  let order_2 =
    mock_order("order_2", False, 5_000_000, 954_900_000, 10, 0, mock_account)

  let input_balances =
    [
      mock_hydra_balance(
        mock_account,
        from_lovelace(4_948_810_000) |> merge(mock_usd(4_969_360_884)),
      ),
      mock_hydra_balance(
        mock_fee_account,
        from_lovelace(5_000_190_000) |> merge(mock_usd(5_000_182_316)),
      ),
    ]

  let output_balances =
    [
      mock_hydra_balance(
        mock_account,
        from_lovelace(4_956_802_000) |> merge(mock_usd(4_977_331_645)),
      ),
      mock_hydra_balance(
        mock_fee_account,
        from_lovelace(5_000_198_000) |> merge(mock_usd(5_000_189_955)),
      ),
    ]

  (order_1, order_2, input_balances, output_balances)
}

test s9_wfo_1() {
  let (order_1, order_2, input_balances, output_balances) = base_case()
  let order_3 =
    mock_order("order_3", False, 1_000_000, 951_100_000, 10, 0, mock_account)

  let order_4 =
    mock_order("order_4", False, 4_000_000, 957_400_000, 10, 0, mock_account)

  let updated_order_4 =
    mock_order("order_4", False, 2_000_000, 957_400_000, 10, 0, mock_account)

  let tx =
    mock_tx(
      TestCase {
        input_orders: [order_1, order_2, order_3, order_4],
        output_order: Some(updated_order_4),
        input_balances,
        output_balances,
        burnt_order_ids: ["order_1", "order_2", "order_3"],
        is_operation_key_signed: True,
      },
    )
  fill_order.fill_order.withdraw(
    mock_dex_order_book_token,
    FillOrderRedeemer { filler_order_id: "order_1" },
    Script(mock_hydra_fill_order),
    tx,
  )
}

test s9_wfo_1_fail_without_key() {
  let (order_1, order_2, input_balances, output_balances) = base_case()

  let tx =
    mock_tx(
      TestCase {
        input_orders: [order_1, order_2],
        output_order: None,
        input_balances,
        output_balances,
        burnt_order_ids: ["order_1", "order_2"],
        is_operation_key_signed: False,
      },
    )
  !fill_order.fill_order.withdraw(
    mock_dex_order_book_token,
    FillOrderRedeemer { filler_order_id: "order_1" },
    Script(mock_hydra_fill_order),
    tx,
  )
}

test s9_wfo_1_fail_without_all_complete_orders_burnt() {
  let (order_1, order_2, input_balances, output_balances) = base_case()

  let tx =
    mock_tx(
      TestCase {
        input_orders: [order_1, order_2],
        output_order: None,
        input_balances,
        output_balances,
        burnt_order_ids: ["order_1"],
        is_operation_key_signed: True,
      },
    )
  !fill_order.fill_order.withdraw(
    mock_dex_order_book_token,
    FillOrderRedeemer { filler_order_id: "order_1" },
    Script(mock_hydra_fill_order),
    tx,
  )
}

test s9_wfo_1_fail_without_balanced_value_1() {
  let (order_1, order_2, input_balances, _) = base_case()

  let (_, o1_payoff, _, o1_fee, _, _) = get_order_settlement_info(order_1, None)
  let (_, o2_payoff, _, o2_fee, _, _) = get_order_settlement_info(order_2, None)

  let output_balances =
    [
      mock_hydra_balance(mock_account, o1_payoff |> merge(negate(o1_fee))),
      mock_hydra_balance(mock_account_2, o2_payoff |> merge(negate(o2_fee))),
      mock_hydra_balance(mock_fee_account, o1_fee |> merge(o2_fee)),
      mock_hydra_balance(mock_script_account, from_lovelace(1_000_000)),
    ]

  let tx =
    mock_tx(
      TestCase {
        input_orders: [order_1, order_2],
        output_order: None,
        input_balances,
        output_balances,
        burnt_order_ids: ["order_1", "order_2"],
        is_operation_key_signed: True,
      },
    )
  !fill_order.fill_order.withdraw(
    mock_dex_order_book_token,
    FillOrderRedeemer { filler_order_id: "order_1" },
    Script(mock_hydra_fill_order),
    tx,
  )
}

test s9_wfo_1_fail_without_balanced_value_2() {
  let (order_1, order_2, input_balances, _) = base_case()

  let (_, o1_payoff, _, o1_fee, _, _) = get_order_settlement_info(order_1, None)
  let (_, o2_payoff, _, o2_fee, _, _) = get_order_settlement_info(order_2, None)

  let output_balances =
    [
      mock_hydra_balance(mock_account, o1_payoff |> merge(negate(o1_fee))),
      mock_hydra_balance(mock_account_2, o2_payoff |> merge(negate(o2_fee))),
    ]

  let tx =
    mock_tx(
      TestCase {
        input_orders: [order_1, order_2],
        output_order: None,
        input_balances,
        output_balances,
        burnt_order_ids: ["order_1", "order_2"],
        is_operation_key_signed: True,
      },
    )
  !fill_order.fill_order.withdraw(
    mock_dex_order_book_token,
    FillOrderRedeemer { filler_order_id: "order_1" },
    Script(mock_hydra_fill_order),
    tx,
  )
}

test s9_wfo_2_fill_multipe_sell_orders() {
  let order_1 =
    mock_order("order_1", True, 300_000_000, 1_200_000_000, 10, 0, mock_account)
  let order_2 =
    mock_order(
      "order_2",
      False,
      100_000_000,
      1_000_000_000,
      10,
      0,
      mock_account_2,
    )
  let order_3 =
    mock_order(
      "order_3",
      False,
      100_000_000,
      1_100_000_000,
      10,
      0,
      mock_account_3,
    )
  let order_4 =
    mock_order(
      "order_4",
      False,
      100_000_000,
      1_200_000_000,
      10,
      0,
      mock_account_4,
    )

  let input_balances =
    [
      mock_hydra_balance(mock_account, zero),
      mock_hydra_balance(mock_account_2, zero),
      mock_hydra_balance(mock_account_3, zero),
      mock_hydra_balance(mock_account_4, zero),
      mock_hydra_balance(mock_fee_account, zero),
    ]

  let output_balances =
    [
      mock_hydra_balance(
        mock_account,
        from_lovelace(299_700_000) |> merge(mock_usd(30_000_000)),
      ),
      mock_hydra_balance(mock_account_2, mock_usd(99_900_000)),
      mock_hydra_balance(mock_account_3, mock_usd(109_890_000)),
      mock_hydra_balance(mock_account_4, mock_usd(119_880_000)),
      mock_hydra_balance(
        mock_fee_account,
        mock_usd(330_000) |> merge(from_lovelace(300_000)),
      ),
    ]

  let tx =
    mock_tx(
      TestCase {
        input_orders: [order_1, order_2, order_3, order_4],
        output_order: None,
        input_balances,
        output_balances,
        burnt_order_ids: ["order_1", "order_2", "order_3", "order_4"],
        is_operation_key_signed: True,
      },
    )
  fill_order.fill_order.withdraw(
    mock_dex_order_book_token,
    FillOrderRedeemer { filler_order_id: "order_1" },
    Script(mock_hydra_fill_order),
    tx,
  )
}

test s9_wfo_2_fill_multipl_buy_orders() {
  let order_1 =
    mock_order(
      "order_1",
      False,
      300_000_000,
      1_200_000_000,
      10,
      0,
      mock_account,
    )
  let order_2 =
    mock_order(
      "order_2",
      True,
      100_000_000,
      1_200_000_000,
      10,
      0,
      mock_account_2,
    )
  let order_3 =
    mock_order(
      "order_3",
      True,
      100_000_000,
      1_300_000_000,
      10,
      0,
      mock_account_3,
    )
  let order_4 =
    mock_order(
      "order_4",
      True,
      100_000_000,
      1_400_000_000,
      10,
      0,
      mock_account_4,
    )

  let input_balances =
    [
      mock_hydra_balance(mock_account, zero),
      mock_hydra_balance(mock_account_2, zero),
      mock_hydra_balance(mock_account_3, zero),
      mock_hydra_balance(mock_account_4, zero),
      mock_hydra_balance(mock_fee_account, zero),
    ]

  let output_balances =
    [
      mock_hydra_balance(mock_account, mock_usd(389_610_000)),
      mock_hydra_balance(mock_account_2, from_lovelace(99_900_000)),
      mock_hydra_balance(mock_account_3, from_lovelace(99_900_000)),
      mock_hydra_balance(mock_account_4, from_lovelace(99_900_000)),
      mock_hydra_balance(
        mock_fee_account,
        mock_usd(390_000) |> merge(from_lovelace(300_000)),
      ),
    ]

  let tx =
    mock_tx(
      TestCase {
        input_orders: [order_1, order_2, order_3, order_4],
        output_order: None,
        input_balances,
        output_balances,
        burnt_order_ids: ["order_1", "order_2", "order_3", "order_4"],
        is_operation_key_signed: True,
      },
    )
  fill_order.fill_order.withdraw(
    mock_dex_order_book_token,
    FillOrderRedeemer { filler_order_id: "order_1" },
    Script(mock_hydra_fill_order),
    tx,
  )
}

test s9_wfo_3_fill_market_buy_order() {
  let order_1 =
    mock_order(
      "order_1",
      True,
      300_000_000,
      1_200_000_000,
      10,
      40_000_000,
      mock_account,
    )
  let order_2 =
    mock_order(
      "order_2",
      False,
      100_000_000,
      1_200_000_000,
      10,
      0,
      mock_account_2,
    )
  let order_3 =
    mock_order(
      "order_3",
      False,
      100_000_000,
      1_300_000_000,
      10,
      0,
      mock_account_3,
    )
  let order_4 =
    mock_order(
      "order_4",
      False,
      100_000_000,
      1_400_000_000,
      10,
      0,
      mock_account_4,
    )

  let input_balances =
    [
      mock_hydra_balance(mock_account, zero),
      mock_hydra_balance(mock_account_2, zero),
      mock_hydra_balance(mock_account_3, zero),
      mock_hydra_balance(mock_account_4, zero),
      mock_hydra_balance(mock_fee_account, zero),
    ]

  let output_balances =
    [
      mock_hydra_balance(
        mock_account,
        from_lovelace(299_700_000) |> merge(mock_usd(10_000_000)),
      ),
      mock_hydra_balance(mock_account_2, mock_usd(119_880_000)),
      mock_hydra_balance(mock_account_3, mock_usd(129_870_000)),
      mock_hydra_balance(mock_account_4, mock_usd(139_860_000)),
      mock_hydra_balance(
        mock_fee_account,
        mock_usd(390_000) |> merge(from_lovelace(300_000)),
      ),
    ]

  let tx =
    mock_tx(
      TestCase {
        input_orders: [order_1, order_2, order_3, order_4],
        output_order: None,
        input_balances,
        output_balances,
        burnt_order_ids: ["order_1", "order_2", "order_3", "order_4"],
        is_operation_key_signed: True,
      },
    )
  fill_order.fill_order.withdraw(
    mock_dex_order_book_token,
    FillOrderRedeemer { filler_order_id: "order_1" },
    Script(mock_hydra_fill_order),
    tx,
  )
}

// test debug_fill_orders() {
//   let order_1 =
//     mock_order("order_1", False, 5000000, 100000000000, 10, 0, mock_account)
//   // lock 5 ada
//   let order_2 =
//     mock_order("order_2", True, 5000000, 100000000000, 10, 0, mock_account)
//   // lock 500000000 usdm
//   let input_balances =
//     [
//       mock_hydra_balance(
//         mock_account,
//         from_lovelace(3995000000) |> merge(mock_usd(999500000000)),
//       ),
//       mock_hydra_balance(
//         mock_fee_account,
//         from_lovelace(4000000000) |> merge(mock_usd(1000000000000)),
//       ),
//     ]

//   let output_balances =
//     [
//       mock_hydra_balance(
//         mock_account,
//         from_lovelace(3999990000) |> merge(mock_usd(999999500000)),
//       ),
//       mock_hydra_balance(
//         mock_fee_account,
//         from_lovelace(4000010000) |> merge(mock_usd(1000000500000)),
//       ),
//     ]

//   let tx =
//     mock_tx(
//       TestCase {
//         input_orders: [order_1, order_2],
//         output_order: None,
//         input_balances,
//         output_balances,
//         burnt_order_ids: ["order_1", "order_2"],
//         is_operation_key_signed: True,
//       },
//     )
//   fill_order.fill_order.withdraw(
//     mock_dex_order_book_token,
//     FillOrderRedeemer { filler_order_id: "order_2" },
//     Script(mock_hydra_fill_order),
//     tx,
//   )
// }

test s9_wfo_4_fill_non_exact_market_buy_order() {
  let order_1 =
    mock_order(
      "order_1",
      True,
      10_000_000,
      99_950_000_000_000,
      10,
      0,
      mock_account,
    )
  let order_2 =
    mock_order(
      "order_2",
      False,
      5_000_000,
      100_000_000_000,
      10,
      0,
      mock_account_2,
    )

  let new_order_1 =
    mock_order("order_1", True, 5_000_000, 100_000_000_000, 10, 0, mock_account)

  let input_balances =
    [
      mock_hydra_balance(mock_account, zero),
      mock_hydra_balance(mock_account_2, zero),
      mock_hydra_balance(mock_fee_account, zero),
    ]

  let output_balances =
    [
      mock_hydra_balance(
        mock_account,
        from_lovelace(4_995_000) |> merge(mock_usd(998_500_000_000)),
      ),
      mock_hydra_balance(mock_account_2, mock_usd(499_500_000)),
      mock_hydra_balance(
        mock_fee_account,
        mock_usd(500_000) |> merge(from_lovelace(5_000)),
      ),
    ]

  let tx =
    mock_tx(
      TestCase {
        input_orders: [order_1, order_2],
        output_order: Some(new_order_1),
        input_balances,
        output_balances,
        burnt_order_ids: ["order_2"],
        is_operation_key_signed: True,
      },
    )
  fill_order.fill_order.withdraw(
    mock_dex_order_book_token,
    FillOrderRedeemer { filler_order_id: "order_1" },
    Script(mock_hydra_fill_order),
    tx,
  )
}

test s9_wfo_5_rounding_negative_payoff_settle_to_fee() {
  // let a = 606300000
  // let b = 4340147900
  // let c = a * b / 1_000_000_000
  // c == 1
  let order_1 =
    mock_order(
      "order_1",
      True,
      4_340_147_900,
      606_300_000,
      10,
      0,
      mock_account_2,
    )
  let order_2 =
    mock_order(
      "order_2",
      False,
      9_288_391_000,
      606_300_000,
      10,
      0,
      mock_account,
    )

  let input_balances =
    [
      mock_hydra_balance(
        mock_account,
        from_lovelace(26_125_960_537) |> merge(mock_usd(20_270_636_513)),
      ),
      mock_hydra_balance(
        mock_account_2,
        from_lovelace(21_186_800) |> merge(mock_usd(16_164_508_829)),
      ),
      mock_hydra_balance(
        mock_fee_account,
        from_lovelace(170_054_784_049) |> merge(mock_usd(864_422_514_364)),
      ),
    ]

  let output_balances =
    [
      mock_hydra_balance(
        mock_account,
        from_lovelace(26_125_960_537) |> merge(mock_usd(22_899_436_754)),
      ),
      mock_hydra_balance(
        mock_account_2,
        from_lovelace(4_356_994_553) |> merge(mock_usd(16_164_508_829)),
      ),
      mock_hydra_balance(
        mock_fee_account,
        from_lovelace(170_059_124_196) |> merge(mock_usd(864_425_145_794)),
      ),
    ]
  let order_3 =
    mock_order(
      "order_2",
      False,
      4_948_243_100,
      606_300_000,
      10,
      0,
      mock_account,
    )

  let tx =
    mock_tx(
      TestCase {
        input_orders: [order_1, order_2],
        output_order: Some(order_3),
        input_balances,
        output_balances,
        burnt_order_ids: ["order_1"],
        is_operation_key_signed: True,
      },
    )
  fill_order.fill_order.withdraw(
    mock_dex_order_book_token,
    FillOrderRedeemer { filler_order_id: "order_1" },
    Script(mock_hydra_fill_order),
    tx,
  )
}
