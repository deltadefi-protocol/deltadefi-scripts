use aiken/collection/list
use cardano/address.{Script}
use cardano/assets.{from_asset, from_lovelace, merge, negate, zero}
use cardano/transaction.{Transaction}
use hydra_account_balance/spend as hydra_account_balance
use hydra_dex/order_utils.{get_order_settlement_info}
use hydra_dex/types.{
  FillOrder, FillOrderRedeemer, HydraAccountBalanceDatum, HydraOrderBookDatum,
  UpdataBalanceWithFillOrder,
}
use hydra_order_book/fill_order
use hydra_order_book/mint as ob_mint
use hydra_order_book/spend as ob_spend
use mocktail.{
  MocktailTx, complete, mint, mock_tx_hash, mock_utxo_ref, mocktail_tx,
  ref_tx_in, ref_tx_in_inline_datum, required_signer_hash, script_withdrawal,
  tx_in, tx_in_inline_datum, tx_out, tx_out_inline_datum,
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
  is_withdrawal_script_validated: Bool,
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
        |> tx_out_inline_datum(True, output_order)
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
    is_withdrawal_script_validated,
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
    |> script_withdrawal(
        is_withdrawal_script_validated,
        mock_hydra_fill_order,
        0,
      )
    |> complete()
}

fn base_case() {
  let order_1 =
    mock_order(
      "order_1",
      False,
      250_000_000,
      1_000_000_000,
      10,
      0,
      mock_account,
    )
  let order_2 =
    mock_order(
      "order_2",
      True,
      250_000_000,
      1_000_000_000,
      10,
      0,
      mock_account_2,
    )

  let input_balances =
    [
      mock_hydra_balance(mock_account, zero),
      mock_hydra_balance(mock_account_2, zero),
      mock_hydra_balance(mock_fee_account, zero),
    ]

  let output_balances =
    [
      mock_hydra_balance(mock_account, mock_usd(249_750_000)),
      mock_hydra_balance(mock_account_2, from_lovelace(249_750_000)),
      mock_hydra_balance(
        mock_fee_account,
        mock_usd(250_000) |> merge(from_lovelace(250_000)),
      ),
    ]

  (order_1, order_2, input_balances, output_balances)
}

fn check_all_scripts(test_case: TestCase) {
  let tx = mock_tx(test_case)
  let withdraw =
    fill_order.fill_order.withdraw(
      mock_dex_order_book_token,
      FillOrderRedeemer { filler_order_id: "order_1" },
      Script(mock_hydra_fill_order),
      tx,
    )

  let check_ob_mint =
    test_case.burnt_order_ids
      |> list.all(
          fn(_) {
            ob_mint.hydra_order_book.mint(
              mock_dex_order_book_token,
              FillOrder,
              mock_hydra_order_book_token,
              tx,
            )
          },
        )

  let check_ob_spend =
    test_case.input_orders
      |> list.all(
          fn(order_datum) {
            ob_spend.hydra_order_book.spend(
              mock_dex_order_book_token,
              Some(order_datum),
              FillOrder,
              mock_utxo_ref(0, 0),
              tx,
            )
          },
        )

  let check_balance =
    test_case.input_balances
      |> list.all(
          fn(input_balance) {
            hydra_account_balance.hydra_account_balance.spend(
              mock_dex_order_book_token,
              Some(input_balance),
              UpdataBalanceWithFillOrder,
              mock_utxo_ref(0, 0),
              tx,
            )
          },
        )

  withdraw? && check_ob_mint? && check_ob_spend? && check_balance?
}

test it_hfo_1() {
  let (order_1, order_2, input_balances, output_balances) = base_case()

  let test_case =
    TestCase {
      input_orders: [order_1, order_2],
      output_order: None,
      input_balances,
      output_balances,
      burnt_order_ids: ["order_1", "order_2"],
      is_operation_key_signed: True,
      is_withdrawal_script_validated: True,
    }
  check_all_scripts(test_case)
}

test it_hfo_1_fail_without_key() {
  let (order_1, order_2, input_balances, output_balances) = base_case()

  let test_case =
    TestCase {
      input_orders: [order_1, order_2],
      output_order: None,
      input_balances,
      output_balances,
      burnt_order_ids: ["order_1", "order_2"],
      is_operation_key_signed: False,
      is_withdrawal_script_validated: True,
    }
  !check_all_scripts(test_case)
}

test it_hfo_1_fail_without_withdrawal_script() {
  let (order_1, order_2, input_balances, output_balances) = base_case()

  let test_case =
    TestCase {
      input_orders: [order_1, order_2],
      output_order: None,
      input_balances,
      output_balances,
      burnt_order_ids: ["order_1", "order_2"],
      is_operation_key_signed: True,
      is_withdrawal_script_validated: False,
    }
  !check_all_scripts(test_case)
}

test it_hfo_1_fail_without_all_complete_orders_burnt() {
  let (order_1, order_2, input_balances, output_balances) = base_case()

  let test_case =
    TestCase {
      input_orders: [order_1, order_2],
      output_order: None,
      input_balances,
      output_balances,
      burnt_order_ids: ["order_1"],
      is_operation_key_signed: True,
      is_withdrawal_script_validated: True,
    }
  !check_all_scripts(test_case)
}

test it_hfo_1_fail_without_balanced_value_1() {
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

  let test_case =
    TestCase {
      input_orders: [order_1, order_2],
      output_order: None,
      input_balances,
      output_balances,
      burnt_order_ids: ["order_1", "order_2"],
      is_operation_key_signed: True,
      is_withdrawal_script_validated: True,
    }
  !check_all_scripts(test_case)
}

test it_hfo_1_fail_without_balanced_value_2() {
  let (order_1, order_2, input_balances, _) = base_case()

  let (_, o1_payoff, _, o1_fee, _, _) = get_order_settlement_info(order_1, None)
  let (_, o2_payoff, _, o2_fee, _, _) = get_order_settlement_info(order_2, None)

  let output_balances =
    [
      mock_hydra_balance(mock_account, o1_payoff |> merge(negate(o1_fee))),
      mock_hydra_balance(mock_account_2, o2_payoff |> merge(negate(o2_fee))),
    ]

  let test_case =
    TestCase {
      input_orders: [order_1, order_2],
      output_order: None,
      input_balances,
      output_balances,
      burnt_order_ids: ["order_1", "order_2"],
      is_operation_key_signed: True,
      is_withdrawal_script_validated: True,
    }
  !check_all_scripts(test_case)
}

test it_hfo_2_fill_multipe_sell_orders() {
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

  let test_case =
    TestCase {
      input_orders: [order_1, order_2, order_3, order_4],
      output_order: None,
      input_balances,
      output_balances,
      burnt_order_ids: ["order_1", "order_2", "order_3", "order_4"],
      is_operation_key_signed: True,
      is_withdrawal_script_validated: True,
    }
  check_all_scripts(test_case)
}

test it_hfo_2_fill_multipl_buy_orders() {
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

  let test_case =
    TestCase {
      input_orders: [order_1, order_2, order_3, order_4],
      output_order: None,
      input_balances,
      output_balances,
      burnt_order_ids: ["order_1", "order_2", "order_3", "order_4"],
      is_operation_key_signed: True,
      is_withdrawal_script_validated: True,
    }
  check_all_scripts(test_case)
}

test it_hfo_3_fill_market_buy_order() {
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

  let test_case =
    TestCase {
      input_orders: [order_1, order_2, order_3, order_4],
      output_order: None,
      input_balances,
      output_balances,
      burnt_order_ids: ["order_1", "order_2", "order_3", "order_4"],
      is_operation_key_signed: True,
      is_withdrawal_script_validated: True,
    }
  check_all_scripts(test_case)
}
