use cardano/address.{Script}
use cardano/assets.{from_asset, from_lovelace, zero}
use cardano/transaction.{Transaction}
use hydra_dex/types.{ModifyOrder, Order, UserSpotAccount}
use hydra_order_book/core as ob
use mocktail.{
  complete, mint, mock_pub_key_address, mock_tx_hash, mocktail_tx, ref_tx_in,
  ref_tx_in_inline_datum, required_signer_hash, tx_in, tx_in_inline_datum,
  tx_out, tx_out_inline_datum,
}
use tests/utils.{
  mock_account, mock_account_2, mock_dex_order_book_address,
  mock_dex_order_book_datum, mock_dex_order_book_token,
  mock_hydra_account_address, mock_hydra_lovelace, mock_hydra_order_book,
  mock_hydra_order_book_address, mock_hydra_user_intent_address,
  mock_hydra_user_intent_token, mock_modify_order_intent, mock_operation_key,
  mock_order, mock_order_id, mock_order_id_2,
} as test_utils

type TestCase {
  is_single_intent_input: Bool,
  is_single_order_output: Bool,
  without_random_input: Bool,
  without_random_output: Bool,
  is_intent_account_correct: Bool,
  is_intent_order_correct: Bool,
  is_order_id_matching: Bool,
  is_intent_token_burnt: Bool,
  is_account_balance_updated: Bool,
  is_operation_key_signed: Bool,
  modify_add_value_to_order_case: Bool,
}

fn mock_tx(test_case: TestCase) -> Transaction {
  let TestCase {
    is_single_intent_input,
    is_single_order_output,
    without_random_input,
    without_random_output,
    is_intent_account_correct,
    is_intent_order_correct,
    is_order_id_matching,
    is_intent_token_burnt,
    is_account_balance_updated,
    is_operation_key_signed,
    modify_add_value_to_order_case,
  } = test_case

  let account = UserSpotAccount { account: mock_account }

  let is_long = False
  let old_size = 500_000_000
  let new_size =
    if modify_add_value_to_order_case {
      750_000_000
    } else {
      250_000_000
    }
  let list_price_times_1bil = 1_350_000_000
  let fee_amount_bp = 10

  let output_balance =
    if is_account_balance_updated {
      mock_hydra_lovelace(250_000_000)
    } else {
      mock_hydra_lovelace(500_000_000)
    }

  let intent_datum =
    mock_modify_order_intent(
      is_long,
      new_size,
      list_price_times_1bil,
      fee_amount_bp,
      if is_intent_account_correct {
        mock_account
      } else {
        mock_account_2
      },
      from_lovelace(250_000_000),
    )
  let old_order_datum =
    mock_order(
      mock_order_id,
      is_long,
      old_size,
      list_price_times_1bil,
      fee_amount_bp,
      mock_account,
    )
  let new_order_datum =
    mock_order(
      mock_order_id,
      is_long,
      new_size,
      list_price_times_1bil,
      fee_amount_bp,
      mock_account,
    )

  let new_order_datum =
    if is_intent_order_correct {
      new_order_datum
    } else {
      Order { ..new_order_datum, size: 123_456_789 }
    }

  let new_order_datum =
    if is_order_id_matching {
      new_order_datum
    } else {
      Order { ..new_order_datum, order_id: mock_order_id_2 }
    }

  mocktail_tx()
    //  - Ref input with `dex_oracle_nft`
    |> ref_tx_in(
        True,
        mock_tx_hash(0),
        0,
        from_asset(mock_dex_order_book_token, "", 1),
        mock_dex_order_book_address,
      )
    |> ref_tx_in_inline_datum(True, mock_dex_order_book_datum)
    //  - Categorize inputs into
    //    - `II` - Intent Input
    //    - `AI` - Account Inputs
    //    - `OI` - Order Input
    //    - Other inputs
    |> tx_in(
        True,
        mock_tx_hash(0),
        1,
        from_asset(mock_hydra_user_intent_token, "", 1),
        mock_hydra_user_intent_address,
      )
    |> tx_in_inline_datum(True, intent_datum)
    |> tx_in(
        modify_add_value_to_order_case,
        mock_tx_hash(1),
        0,
        mock_hydra_lovelace(200_000_000),
        mock_hydra_account_address,
      )
    |> tx_in_inline_datum(modify_add_value_to_order_case, account)
    |> tx_in(
        modify_add_value_to_order_case,
        mock_tx_hash(1),
        2,
        mock_hydra_lovelace(300_000_000),
        mock_hydra_account_address,
      )
    |> tx_in_inline_datum(modify_add_value_to_order_case, account)
    |> tx_in(
        True,
        mock_tx_hash(1),
        3,
        mock_hydra_lovelace(old_size),
        mock_hydra_order_book_address,
      )
    |> tx_in_inline_datum(True, old_order_datum)
    //  - Categorize outputs into
    //    - `AO` - Account Output with `account` at intent
    //    - `OO` - Order Output with `account` at intent
    //    - Other outputs
    |> tx_out(True, mock_hydra_account_address, output_balance)
    |> tx_out_inline_datum(True, account)
    |> tx_out(
        True,
        mock_hydra_order_book_address,
        mock_hydra_lovelace(new_size),
      )
    |> tx_out_inline_datum(True, new_order_datum)
    // - The input token is burnt
    |> mint(is_intent_token_burnt, -1, mock_hydra_user_intent_token, "")
    // - Signed by `operating_key` 
    |> required_signer_hash(is_operation_key_signed, mock_operation_key)
    // failing cases
    |> tx_in(
        !is_single_intent_input,
        mock_tx_hash(0),
        1,
        from_asset(mock_hydra_user_intent_token, "", 1),
        mock_hydra_user_intent_address,
      )
    |> tx_in_inline_datum(!is_single_intent_input, intent_datum)
    |> tx_out(
        !is_single_order_output,
        mock_hydra_order_book_address,
        mock_hydra_lovelace(250_000_000),
      )
    |> tx_out_inline_datum(!is_single_order_output, new_order_datum)
    |> tx_in(
        !without_random_input,
        mock_tx_hash(2),
        0,
        zero,
        mock_pub_key_address(10, None),
      )
    |> tx_out(!without_random_output, mock_pub_key_address(10, None), zero)
    |> complete()
}

test s9_wmo_success_decrease_order_value_case() {
  let tx =
    mock_tx(
      TestCase {
        is_single_intent_input: True,
        is_single_order_output: True,
        without_random_input: True,
        without_random_output: True,
        is_intent_account_correct: True,
        is_intent_order_correct: True,
        is_order_id_matching: True,
        is_intent_token_burnt: True,
        is_account_balance_updated: True,
        is_operation_key_signed: True,
        modify_add_value_to_order_case: False,
      },
    )
  ob.hydra_order_book.withdraw(
    mock_dex_order_book_token,
    ModifyOrder { account: UserSpotAccount { account: mock_account } },
    Script(mock_hydra_order_book),
    tx,
  )
}

test s9_wmo_success_increase_order_value_case() {
  let tx =
    mock_tx(
      TestCase {
        is_single_intent_input: True,
        is_single_order_output: True,
        without_random_input: True,
        without_random_output: True,
        is_intent_account_correct: True,
        is_intent_order_correct: True,
        is_order_id_matching: True,
        is_intent_token_burnt: True,
        is_account_balance_updated: True,
        is_operation_key_signed: True,
        modify_add_value_to_order_case: True,
      },
    )
  ob.hydra_order_book.withdraw(
    mock_dex_order_book_token,
    ModifyOrder { account: UserSpotAccount { account: mock_account } },
    Script(mock_hydra_order_book),
    tx,
  )
}

test s9_wmo_fail_with_multiple_intent_input() fail {
  let tx =
    mock_tx(
      TestCase {
        is_single_intent_input: False,
        is_single_order_output: True,
        without_random_input: True,
        without_random_output: True,
        is_intent_account_correct: True,
        is_intent_order_correct: True,
        is_order_id_matching: True,
        is_intent_token_burnt: True,
        is_account_balance_updated: True,
        is_operation_key_signed: True,
        modify_add_value_to_order_case: True,
      },
    )
  !ob.hydra_order_book.withdraw(
    mock_dex_order_book_token,
    ModifyOrder { account: UserSpotAccount { account: mock_account } },
    Script(mock_hydra_order_book),
    tx,
  )
}

test s9_wmo_fail_with_multiple_order_output() fail {
  let tx =
    mock_tx(
      TestCase {
        is_single_intent_input: True,
        is_single_order_output: False,
        without_random_input: True,
        without_random_output: True,
        is_intent_account_correct: True,
        is_intent_order_correct: True,
        is_order_id_matching: True,
        is_intent_token_burnt: True,
        is_account_balance_updated: True,
        is_operation_key_signed: True,
        modify_add_value_to_order_case: True,
      },
    )
  ob.hydra_order_book.withdraw(
    mock_dex_order_book_token,
    ModifyOrder { account: UserSpotAccount { account: mock_account } },
    Script(mock_hydra_order_book),
    tx,
  )
}

test s9_wmo_fail_with_random_input() fail {
  let tx =
    mock_tx(
      TestCase {
        is_single_intent_input: True,
        is_single_order_output: True,
        without_random_input: False,
        without_random_output: True,
        is_intent_account_correct: True,
        is_intent_order_correct: True,
        is_order_id_matching: True,
        is_intent_token_burnt: True,
        is_account_balance_updated: True,
        is_operation_key_signed: True,
        modify_add_value_to_order_case: True,
      },
    )
  ob.hydra_order_book.withdraw(
    mock_dex_order_book_token,
    ModifyOrder { account: UserSpotAccount { account: mock_account } },
    Script(mock_hydra_order_book),
    tx,
  )
}

test s9_wmo_fail_with_random_output() {
  let tx =
    mock_tx(
      TestCase {
        is_single_intent_input: True,
        is_single_order_output: True,
        without_random_input: True,
        without_random_output: False,
        is_intent_account_correct: True,
        is_intent_order_correct: True,
        is_order_id_matching: True,
        is_intent_token_burnt: True,
        is_account_balance_updated: True,
        is_operation_key_signed: True,
        modify_add_value_to_order_case: True,
      },
    )
  !ob.hydra_order_book.withdraw(
    mock_dex_order_book_token,
    ModifyOrder { account: UserSpotAccount { account: mock_account } },
    Script(mock_hydra_order_book),
    tx,
  )
}

test s9_wmo_fail_with_incorrect_intent_account() {
  let tx =
    mock_tx(
      TestCase {
        is_single_intent_input: True,
        is_single_order_output: True,
        without_random_input: True,
        without_random_output: True,
        is_intent_account_correct: False,
        is_intent_order_correct: True,
        is_order_id_matching: True,
        is_intent_token_burnt: True,
        is_account_balance_updated: True,
        is_operation_key_signed: True,
        modify_add_value_to_order_case: True,
      },
    )
  !ob.hydra_order_book.withdraw(
    mock_dex_order_book_token,
    ModifyOrder { account: UserSpotAccount { account: mock_account } },
    Script(mock_hydra_order_book),
    tx,
  )
}

test s9_wmo_fail_without_following_intent() {
  let tx =
    mock_tx(
      TestCase {
        is_single_intent_input: True,
        is_single_order_output: True,
        without_random_input: True,
        without_random_output: True,
        is_intent_account_correct: True,
        is_intent_order_correct: False,
        is_order_id_matching: True,
        is_intent_token_burnt: True,
        is_account_balance_updated: True,
        is_operation_key_signed: True,
        modify_add_value_to_order_case: True,
      },
    )
  !ob.hydra_order_book.withdraw(
    mock_dex_order_book_token,
    ModifyOrder { account: UserSpotAccount { account: mock_account } },
    Script(mock_hydra_order_book),
    tx,
  )
}

test s9_wmo_fail_without_order_id_matched() {
  let tx =
    mock_tx(
      TestCase {
        is_single_intent_input: True,
        is_single_order_output: True,
        without_random_input: True,
        without_random_output: True,
        is_intent_account_correct: True,
        is_intent_order_correct: True,
        is_order_id_matching: False,
        is_intent_token_burnt: True,
        is_account_balance_updated: True,
        is_operation_key_signed: True,
        modify_add_value_to_order_case: True,
      },
    )
  !ob.hydra_order_book.withdraw(
    mock_dex_order_book_token,
    ModifyOrder { account: UserSpotAccount { account: mock_account } },
    Script(mock_hydra_order_book),
    tx,
  )
}

test s9_wmo_fail_without_intent_token_burnt() {
  let tx =
    mock_tx(
      TestCase {
        is_single_intent_input: True,
        is_single_order_output: True,
        without_random_input: True,
        without_random_output: True,
        is_intent_account_correct: True,
        is_intent_order_correct: True,
        is_order_id_matching: True,
        is_intent_token_burnt: False,
        is_account_balance_updated: True,
        is_operation_key_signed: True,
        modify_add_value_to_order_case: True,
      },
    )
  !ob.hydra_order_book.withdraw(
    mock_dex_order_book_token,
    ModifyOrder { account: UserSpotAccount { account: mock_account } },
    Script(mock_hydra_order_book),
    tx,
  )
}

test s9_wmo_fail_without_balance_updated() {
  let tx =
    mock_tx(
      TestCase {
        is_single_intent_input: True,
        is_single_order_output: True,
        without_random_input: True,
        without_random_output: True,
        is_intent_account_correct: True,
        is_intent_order_correct: True,
        is_order_id_matching: True,
        is_intent_token_burnt: True,
        is_account_balance_updated: False,
        is_operation_key_signed: True,
        modify_add_value_to_order_case: True,
      },
    )
  !ob.hydra_order_book.withdraw(
    mock_dex_order_book_token,
    ModifyOrder { account: UserSpotAccount { account: mock_account } },
    Script(mock_hydra_order_book),
    tx,
  )
}

test s9_wmo_fail_without_operation_key_signed() {
  let tx =
    mock_tx(
      TestCase {
        is_single_intent_input: True,
        is_single_order_output: True,
        without_random_input: True,
        without_random_output: True,
        is_intent_account_correct: True,
        is_intent_order_correct: True,
        is_order_id_matching: True,
        is_intent_token_burnt: True,
        is_account_balance_updated: True,
        is_operation_key_signed: False,
        modify_add_value_to_order_case: True,
      },
    )
  !ob.hydra_order_book.withdraw(
    mock_dex_order_book_token,
    ModifyOrder { account: UserSpotAccount { account: mock_account } },
    Script(mock_hydra_order_book),
    tx,
  )
}
