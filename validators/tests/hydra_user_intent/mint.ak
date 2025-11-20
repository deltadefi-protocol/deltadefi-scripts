use aiken/collection/list
use cardano/assets.{add, from_asset}
use cardano/transaction.{Transaction}
use hydra_dex/account_utils.{get_trade_keys, get_withdrawal_keys}
use hydra_dex/types.{
  CancelOrderIntent, CancelWithdrawalIntent, HydraOrderBookDatum,
  HydraUserIntentDatum, HydraUserIntentRedeemer, MintCancelOrderIntent,
  MintCancelWithdrawalIntent, MintPlaceOrderIntent, MintTransferIntent,
  MintWithdrawalIntent, PlaceOrderIntent, TransferIntent, UserAccount,
  UserSpotAccount, WithdrawalIntent,
}
use hydra_user_intent/mint as hydra_user_intent_mint
use mocktail.{
  MocktailTx, complete, mint, mock_tx_hash, mocktail_tx, ref_tx_in,
  ref_tx_in_inline_datum, required_signer_hash, script_withdrawal, tx_out,
  tx_out_inline_datum,
}
use tests/utils.{
  mock_account, mock_account_2, mock_account_id, mock_dex_order_book_datum,
  mock_dex_order_book_token, mock_hydra_order_book_address,
  mock_hydra_user_intent_address, mock_hydra_user_intent_token,
}

const mock_order_id = "mock_order_id"

fn create_mock_limit_order() -> HydraOrderBookDatum {
  HydraOrderBookDatum {
    order_id: mock_order_id,
    long_token: (mock_account_id, mock_hydra_user_intent_token),
    short_token: (mock_account_id, mock_hydra_user_intent_token),
    is_long: True,
    list_price_times_1bil: 999,
    order_size: 999,
    fee_amount_bp: 999,
    account: UserSpotAccount { account: mock_account },
  }
}

fn create_mock_mint_place_order_intent() -> HydraUserIntentRedeemer {
  MintPlaceOrderIntent { order: create_mock_limit_order() }
}

fn create_mock_place_order_intent() -> HydraUserIntentDatum {
  PlaceOrderIntent {
    order: HydraOrderBookDatum {
      order_id: mock_order_id,
      long_token: (mock_account_id, mock_hydra_user_intent_token),
      short_token: (mock_account_id, mock_hydra_user_intent_token),
      is_long: True,
      list_price_times_1bil: 999,
      order_size: 999,
      fee_amount_bp: 999,
      account: UserSpotAccount { account: mock_account },
    },
  }
}

fn create_mock_mint_cancel_order_intent() -> HydraUserIntentRedeemer {
  MintCancelOrderIntent {
    account: UserSpotAccount { account: mock_account },
    order_ids: [mock_order_id],
  }
}

fn create_mock_cancel_order_intent() -> HydraUserIntentDatum {
  CancelOrderIntent {
    account: UserSpotAccount { account: mock_account },
    order_ids: [mock_order_id],
  }
}

fn create_mock_mint_withdrawal_intent() -> HydraUserIntentRedeemer {
  MintWithdrawalIntent {
    account: UserSpotAccount { account: mock_account },
    amount: [
      Pair("A", [Pair("abc", 1), Pair("def", 10)]),
      Pair("B", [Pair("abc", 1), Pair("def", 10)]),
    ],
  }
}

fn create_mock_mint_cancel_withdrawal_intent() -> HydraUserIntentRedeemer {
  MintCancelWithdrawalIntent {
    account: UserSpotAccount { account: mock_account },
    amount: [
      Pair("A", [Pair("abc", 1), Pair("def", 10)]),
      Pair("B", [Pair("abc", 1), Pair("def", 10)]),
    ],
  }
}

fn create_mock_withdrawal_intent() -> HydraUserIntentDatum {
  WithdrawalIntent {
    account: UserSpotAccount { account: mock_account },
    amount: [
      Pair("A", [Pair("abc", 1), Pair("def", 10)]),
      Pair("B", [Pair("abc", 1), Pair("def", 10)]),
    ],
  }
}

fn create_mock_cancel_withdrawal_intent() -> HydraUserIntentDatum {
  CancelWithdrawalIntent {
    account: UserSpotAccount { account: mock_account },
    amount: [
      Pair("A", [Pair("abc", 1), Pair("def", 10)]),
      Pair("B", [Pair("abc", 1), Pair("def", 10)]),
    ],
  }
}

fn create_mock_mint_transfer_intent() -> HydraUserIntentRedeemer {
  MintTransferIntent {
    from: UserSpotAccount { account: mock_account },
    to: UserSpotAccount { account: mock_account_2 },
    amount: [
      Pair("A", [Pair("abc", 1), Pair("def", 10)]),
      Pair("B", [Pair("abc", 1), Pair("def", 10)]),
    ],
  }
}

fn create_mock_transfer_intent(
  from: UserAccount,
  to: UserAccount,
) -> HydraUserIntentDatum {
  TransferIntent {
    from,
    to,
    amount: [
      Pair("A", [Pair("abc", 1), Pair("def", 10)]),
      Pair("B", [Pair("abc", 1), Pair("def", 10)]),
    ],
  }
}

pub fn add_required_signers(
  mock_tx: MocktailTx,
  condition: Bool,
  required_signers: List<ByteArray>,
) -> MocktailTx {
  required_signers
    |> list.foldr(
        mock_tx,
        fn(required_signer, tx) {
          tx |> required_signer_hash(condition, required_signer)
        },
      )
}

pub fn add_withdrawal_scripts(
  mock_tx: MocktailTx,
  condition: Bool,
  withdrawal_scripts: List<ByteArray>,
) -> MocktailTx {
  withdrawal_scripts
    |> list.foldr(
        mock_tx,
        fn(withdrawal_script, tx) {
          tx |> script_withdrawal(condition, withdrawal_script, 0)
        },
      )
}

type PlaceOrderIntentTestCase {
  is_dex_order_book_inputed: Bool,
  is_token_minted: Bool,
  is_token_name_matched: Bool,
  is_authed_by_withdrawal_key: Bool,
  is_authed_by_trade_key: Bool,
  is_output_correct: Bool,
}

fn mock_mint_place_order_intent_tx(
  test_case: PlaceOrderIntentTestCase,
) -> Transaction {
  let PlaceOrderIntentTestCase {
    is_dex_order_book_inputed,
    is_token_minted,
    is_token_name_matched,
    is_authed_by_withdrawal_key,
    is_authed_by_trade_key,
    is_output_correct,
  } = test_case

  let account = UserSpotAccount { account: mock_account }

  let output_datum: HydraUserIntentDatum = create_mock_place_order_intent()

  let correct_output_value = from_asset(mock_hydra_user_intent_token, "", 1)

  let (trade_key_hashes, trade_script_hashes) = get_trade_keys(account)
  let (withdrawal_key_hashes, withdrawal_script_hashes) =
    get_withdrawal_keys(account)

  mocktail_tx()
    |> add_required_signers(is_authed_by_trade_key, trade_key_hashes)
    |> add_withdrawal_scripts(is_authed_by_trade_key, trade_script_hashes)
    |> add_required_signers(is_authed_by_withdrawal_key, withdrawal_key_hashes)
    |> add_withdrawal_scripts(
        is_authed_by_withdrawal_key,
        withdrawal_script_hashes,
      )
    |> ref_tx_in(
        is_dex_order_book_inputed,
        mock_tx_hash(0),
        0,
        from_asset(mock_dex_order_book_token, "", 1),
        mock_hydra_order_book_address,
      )
    |> ref_tx_in_inline_datum(
        is_dex_order_book_inputed,
        mock_dex_order_book_datum,
      )
    |> mint(
        is_token_minted && is_token_name_matched,
        1,
        mock_hydra_user_intent_token,
        if is_token_name_matched {
          ""
        } else {
          "gg"
        },
      )
    |> tx_out(
        is_output_correct,
        mock_hydra_user_intent_address,
        correct_output_value,
      )
    |> tx_out_inline_datum(is_output_correct, output_datum)
    |> complete()
}

test s7_mint_success_place_order_intent_with_withdraw_key_sign() {
  let redeemer = create_mock_mint_place_order_intent()
  let tx =
    mock_mint_place_order_intent_tx(
      PlaceOrderIntentTestCase {
        is_dex_order_book_inputed: True,
        is_token_minted: True,
        is_token_name_matched: True,
        is_authed_by_withdrawal_key: True,
        is_authed_by_trade_key: False,
        is_output_correct: True,
      },
    )

  hydra_user_intent_mint.hydra_user_intent.mint(
    mock_dex_order_book_token,
    redeemer,
    mock_hydra_user_intent_token,
    tx,
  )
}

test s7_mint_success_place_order_intent_with_trade_key_sign() {
  let redeemer = create_mock_mint_place_order_intent()
  let tx =
    mock_mint_place_order_intent_tx(
      PlaceOrderIntentTestCase {
        is_dex_order_book_inputed: True,
        is_token_minted: True,
        is_token_name_matched: True,
        is_authed_by_withdrawal_key: False,
        is_authed_by_trade_key: True,
        is_output_correct: True,
      },
    )

  hydra_user_intent_mint.hydra_user_intent.mint(
    mock_dex_order_book_token,
    redeemer,
    mock_hydra_user_intent_token,
    tx,
  )
}

test s7_mint_fail_place_order_intent_with_no_dex_oracle_inputed() fail {
  let redeemer = create_mock_mint_place_order_intent()
  let tx =
    mock_mint_place_order_intent_tx(
      PlaceOrderIntentTestCase {
        is_dex_order_book_inputed: False,
        is_token_minted: True,
        is_token_name_matched: True,
        is_authed_by_withdrawal_key: True,
        is_authed_by_trade_key: False,
        is_output_correct: True,
      },
    )

  hydra_user_intent_mint.hydra_user_intent.mint(
    mock_dex_order_book_token,
    redeemer,
    mock_hydra_user_intent_token,
    tx,
  )
}

test s7_mint_fail_place_order_intent_with_no_token_minted() {
  let redeemer = create_mock_mint_place_order_intent()
  let tx =
    mock_mint_place_order_intent_tx(
      PlaceOrderIntentTestCase {
        is_dex_order_book_inputed: True,
        is_token_minted: False,
        is_token_name_matched: True,
        is_authed_by_withdrawal_key: True,
        is_authed_by_trade_key: False,
        is_output_correct: True,
      },
    )

  !hydra_user_intent_mint.hydra_user_intent.mint(
    mock_dex_order_book_token,
    redeemer,
    mock_hydra_user_intent_token,
    tx,
  )
}

test s7_mint_fail_place_order_intent_with_wrong_token_name() {
  let redeemer = create_mock_mint_place_order_intent()
  let tx =
    mock_mint_place_order_intent_tx(
      PlaceOrderIntentTestCase {
        is_dex_order_book_inputed: True,
        is_token_minted: True,
        is_token_name_matched: False,
        is_authed_by_withdrawal_key: True,
        is_authed_by_trade_key: False,
        is_output_correct: True,
      },
    )

  !hydra_user_intent_mint.hydra_user_intent.mint(
    mock_dex_order_book_token,
    redeemer,
    mock_hydra_user_intent_token,
    tx,
  )
}

test s7_mint_fail_place_order_intent_with_no_key_signed() {
  let redeemer = create_mock_mint_place_order_intent()
  let tx =
    mock_mint_place_order_intent_tx(
      PlaceOrderIntentTestCase {
        is_dex_order_book_inputed: True,
        is_token_minted: True,
        is_token_name_matched: True,
        is_authed_by_withdrawal_key: False,
        is_authed_by_trade_key: False,
        is_output_correct: True,
      },
    )

  !hydra_user_intent_mint.hydra_user_intent.mint(
    mock_dex_order_book_token,
    redeemer,
    mock_hydra_user_intent_token,
    tx,
  )
}

type CancelOrderIntentTestCase {
  is_dex_order_book_inputed: Bool,
  is_token_minted: Bool,
  is_token_name_matched: Bool,
  is_authed_by_withdrawal_key: Bool,
  is_authed_by_trade_key: Bool,
  is_output_correct: Bool,
}

fn mock_mint_cancel_order_intent_tx(
  test_case: CancelOrderIntentTestCase,
) -> Transaction {
  let CancelOrderIntentTestCase {
    is_dex_order_book_inputed,
    is_token_minted,
    is_token_name_matched,
    is_authed_by_withdrawal_key,
    is_authed_by_trade_key,
    is_output_correct,
  } = test_case

  let account = UserSpotAccount { account: mock_account }
  let output_datum = create_mock_cancel_order_intent()

  let correct_output_value = from_asset(mock_hydra_user_intent_token, "", 1)

  let (trade_key_hashes, trade_script_hashes) = get_trade_keys(account)
  let (withdrawal_key_hashes, withdrawal_script_hashes) =
    get_withdrawal_keys(account)

  mocktail_tx()
    |> add_required_signers(is_authed_by_trade_key, trade_key_hashes)
    |> add_withdrawal_scripts(is_authed_by_trade_key, trade_script_hashes)
    |> add_required_signers(is_authed_by_withdrawal_key, withdrawal_key_hashes)
    |> add_withdrawal_scripts(
        is_authed_by_withdrawal_key,
        withdrawal_script_hashes,
      )
    |> ref_tx_in(
        is_dex_order_book_inputed,
        mock_tx_hash(0),
        0,
        from_asset(mock_dex_order_book_token, "", 1),
        mock_hydra_order_book_address,
      )
    |> ref_tx_in_inline_datum(
        is_dex_order_book_inputed,
        mock_dex_order_book_datum,
      )
    |> mint(
        is_token_minted && is_token_name_matched,
        1,
        mock_hydra_user_intent_token,
        if is_token_name_matched {
          ""
        } else {
          "gg"
        },
      )
    |> tx_out(
        is_output_correct,
        mock_hydra_user_intent_address,
        correct_output_value,
      )
    |> tx_out_inline_datum(is_output_correct, output_datum)
    |> complete()
}

test s7_mint_success_cancel_order_intent_with_withdraw_key_sign() {
  let redeemer = create_mock_mint_cancel_order_intent()
  let tx =
    mock_mint_cancel_order_intent_tx(
      CancelOrderIntentTestCase {
        is_dex_order_book_inputed: True,
        is_token_minted: True,
        is_token_name_matched: True,
        is_authed_by_withdrawal_key: True,
        is_authed_by_trade_key: False,
        is_output_correct: True,
      },
    )

  hydra_user_intent_mint.hydra_user_intent.mint(
    mock_dex_order_book_token,
    redeemer,
    mock_hydra_user_intent_token,
    tx,
  )
}

test s7_mint_success_cancel_order_intent_with_trade_key_sign() {
  let redeemer = create_mock_mint_cancel_order_intent()
  let tx =
    mock_mint_cancel_order_intent_tx(
      CancelOrderIntentTestCase {
        is_dex_order_book_inputed: True,
        is_token_minted: True,
        is_token_name_matched: True,
        is_authed_by_withdrawal_key: False,
        is_authed_by_trade_key: True,
        is_output_correct: True,
      },
    )

  hydra_user_intent_mint.hydra_user_intent.mint(
    mock_dex_order_book_token,
    redeemer,
    mock_hydra_user_intent_token,
    tx,
  )
}

test s7_mint_fail_cancel_order_intent_with_no_dex_oracle_inputed() fail {
  let redeemer = create_mock_mint_cancel_order_intent()
  let tx =
    mock_mint_cancel_order_intent_tx(
      CancelOrderIntentTestCase {
        is_dex_order_book_inputed: False,
        is_token_minted: True,
        is_token_name_matched: True,
        is_authed_by_withdrawal_key: True,
        is_authed_by_trade_key: False,
        is_output_correct: True,
      },
    )

  hydra_user_intent_mint.hydra_user_intent.mint(
    mock_dex_order_book_token,
    redeemer,
    mock_hydra_user_intent_token,
    tx,
  )
}

test s7_mint_fail_cancel_order_intent_with_no_token_minted() {
  let redeemer = create_mock_mint_cancel_order_intent()
  let tx =
    mock_mint_cancel_order_intent_tx(
      CancelOrderIntentTestCase {
        is_dex_order_book_inputed: True,
        is_token_minted: False,
        is_token_name_matched: True,
        is_authed_by_withdrawal_key: True,
        is_authed_by_trade_key: False,
        is_output_correct: True,
      },
    )

  !hydra_user_intent_mint.hydra_user_intent.mint(
    mock_dex_order_book_token,
    redeemer,
    mock_hydra_user_intent_token,
    tx,
  )
}

test s7_mint_fail_cancel_order_intent_with_wrong_token_name() {
  let redeemer = create_mock_mint_cancel_order_intent()
  let tx =
    mock_mint_cancel_order_intent_tx(
      CancelOrderIntentTestCase {
        is_dex_order_book_inputed: True,
        is_token_minted: True,
        is_token_name_matched: False,
        is_authed_by_withdrawal_key: True,
        is_authed_by_trade_key: False,
        is_output_correct: True,
      },
    )

  !hydra_user_intent_mint.hydra_user_intent.mint(
    mock_dex_order_book_token,
    redeemer,
    mock_hydra_user_intent_token,
    tx,
  )
}

test s7_mint_fail_cancel_order_intent_with_no_key_signed() {
  let redeemer = create_mock_mint_cancel_order_intent()
  let tx =
    mock_mint_cancel_order_intent_tx(
      CancelOrderIntentTestCase {
        is_dex_order_book_inputed: True,
        is_token_minted: True,
        is_token_name_matched: True,
        is_authed_by_withdrawal_key: False,
        is_authed_by_trade_key: False,
        is_output_correct: True,
      },
    )

  !hydra_user_intent_mint.hydra_user_intent.mint(
    mock_dex_order_book_token,
    redeemer,
    mock_hydra_user_intent_token,
    tx,
  )
}

type WithdrawalIntentTestCase {
  is_dex_order_book_inputed: Bool,
  is_token_minted: Bool,
  is_token_name_matched: Bool,
  is_authed_by_withdrawal_key: Bool,
  is_authed_by_trade_key: Bool,
  is_output_correct: Bool,
}

fn mock_mint_withdrawal_intent_tx(
  test_case: WithdrawalIntentTestCase,
) -> Transaction {
  let WithdrawalIntentTestCase {
    is_dex_order_book_inputed,
    is_token_minted,
    is_token_name_matched,
    is_authed_by_withdrawal_key,
    is_authed_by_trade_key,
    is_output_correct,
  } = test_case

  let output_datum = create_mock_withdrawal_intent()
  let account = UserSpotAccount { account: mock_account }

  let correct_output_value = from_asset(mock_hydra_user_intent_token, "", 1)

  let (trade_key_hashes, trade_script_hashes) = get_trade_keys(account)
  let (withdrawal_key_hashes, withdrawal_script_hashes) =
    get_withdrawal_keys(account)

  mocktail_tx()
    |> add_required_signers(is_authed_by_trade_key, trade_key_hashes)
    |> add_withdrawal_scripts(is_authed_by_trade_key, trade_script_hashes)
    |> add_required_signers(is_authed_by_withdrawal_key, withdrawal_key_hashes)
    |> add_withdrawal_scripts(
        is_authed_by_withdrawal_key,
        withdrawal_script_hashes,
      )
    |> ref_tx_in(
        is_dex_order_book_inputed,
        mock_tx_hash(0),
        0,
        from_asset(mock_dex_order_book_token, "", 1),
        mock_hydra_order_book_address,
      )
    |> ref_tx_in_inline_datum(
        is_dex_order_book_inputed,
        mock_dex_order_book_datum,
      )
    |> mint(
        is_token_minted,
        1,
        mock_hydra_user_intent_token,
        if is_token_name_matched {
          ""
        } else {
          "gg"
        },
      )
    |> tx_out(
        is_output_correct,
        mock_hydra_user_intent_address,
        correct_output_value,
      )
    |> tx_out_inline_datum(is_output_correct, output_datum)
    |> complete()
}

test s7_mint_success_withdrawal_intent_with_withdraw_key_sign() {
  let redeemer = create_mock_mint_withdrawal_intent()
  let tx =
    mock_mint_withdrawal_intent_tx(
      WithdrawalIntentTestCase {
        is_dex_order_book_inputed: True,
        is_token_minted: True,
        is_token_name_matched: True,
        is_authed_by_withdrawal_key: True,
        is_authed_by_trade_key: False,
        is_output_correct: True,
      },
    )

  hydra_user_intent_mint.hydra_user_intent.mint(
    mock_dex_order_book_token,
    redeemer,
    mock_hydra_user_intent_token,
    tx,
  )
}

test s7_mint_success_withdrawal_intent_with_trade_key_sign() {
  let redeemer = create_mock_mint_withdrawal_intent()
  let tx =
    mock_mint_withdrawal_intent_tx(
      WithdrawalIntentTestCase {
        is_dex_order_book_inputed: True,
        is_token_minted: True,
        is_token_name_matched: True,
        is_authed_by_withdrawal_key: False,
        is_authed_by_trade_key: True,
        is_output_correct: True,
      },
    )

  hydra_user_intent_mint.hydra_user_intent.mint(
    mock_dex_order_book_token,
    redeemer,
    mock_hydra_user_intent_token,
    tx,
  )
}

test s7_mint_fail_withdrawal_intent_with_no_dex_oracle_inputed() fail {
  let redeemer = create_mock_mint_withdrawal_intent()
  let tx =
    mock_mint_withdrawal_intent_tx(
      WithdrawalIntentTestCase {
        is_dex_order_book_inputed: False,
        is_token_minted: True,
        is_token_name_matched: True,
        is_authed_by_withdrawal_key: True,
        is_authed_by_trade_key: False,
        is_output_correct: True,
      },
    )

  hydra_user_intent_mint.hydra_user_intent.mint(
    mock_dex_order_book_token,
    redeemer,
    mock_hydra_user_intent_token,
    tx,
  )
}

test s7_mint_fail_withdrawal_intent_with_no_token_minted() {
  let redeemer = create_mock_mint_withdrawal_intent()
  let tx =
    mock_mint_withdrawal_intent_tx(
      WithdrawalIntentTestCase {
        is_dex_order_book_inputed: True,
        is_token_minted: False,
        is_token_name_matched: True,
        is_authed_by_withdrawal_key: True,
        is_authed_by_trade_key: False,
        is_output_correct: True,
      },
    )

  !hydra_user_intent_mint.hydra_user_intent.mint(
    mock_dex_order_book_token,
    redeemer,
    mock_hydra_user_intent_token,
    tx,
  )
}

test s7_mint_fail_withdrawal_intent_with_wrong_token_name() {
  let redeemer = create_mock_mint_withdrawal_intent()
  let tx =
    mock_mint_withdrawal_intent_tx(
      WithdrawalIntentTestCase {
        is_dex_order_book_inputed: True,
        is_token_minted: True,
        is_token_name_matched: False,
        is_authed_by_withdrawal_key: True,
        is_authed_by_trade_key: False,
        is_output_correct: True,
      },
    )

  !hydra_user_intent_mint.hydra_user_intent.mint(
    mock_dex_order_book_token,
    redeemer,
    mock_hydra_user_intent_token,
    tx,
  )
}

test s7_mint_fail_withdrawal_intent_with_no_key_signed() {
  let redeemer = create_mock_mint_withdrawal_intent()
  let tx =
    mock_mint_withdrawal_intent_tx(
      WithdrawalIntentTestCase {
        is_dex_order_book_inputed: True,
        is_token_minted: True,
        is_token_name_matched: True,
        is_authed_by_withdrawal_key: False,
        is_authed_by_trade_key: False,
        is_output_correct: True,
      },
    )

  !hydra_user_intent_mint.hydra_user_intent.mint(
    mock_dex_order_book_token,
    redeemer,
    mock_hydra_user_intent_token,
    tx,
  )
}

type CancelWithdrawalIntentTestCase {
  is_dex_order_book_inputed: Bool,
  is_token_minted: Bool,
  is_token_name_matched: Bool,
  is_authed_by_withdrawal_key: Bool,
  is_authed_by_trade_key: Bool,
  is_output_correct: Bool,
}

fn mock_mint_cancel_withdrawal_intent_tx(
  test_case: CancelWithdrawalIntentTestCase,
) -> Transaction {
  let CancelWithdrawalIntentTestCase {
    is_dex_order_book_inputed,
    is_token_minted,
    is_token_name_matched,
    is_authed_by_withdrawal_key,
    is_authed_by_trade_key,
    is_output_correct,
  } = test_case

  let output_datum = create_mock_cancel_withdrawal_intent()
  let account = UserSpotAccount { account: mock_account }

  let correct_output_value = from_asset(mock_hydra_user_intent_token, "", 1)

  let (trade_key_hashes, trade_script_hashes) = get_trade_keys(account)
  let (withdrawal_key_hashes, withdrawal_script_hashes) =
    get_withdrawal_keys(account)

  mocktail_tx()
    |> add_required_signers(is_authed_by_trade_key, trade_key_hashes)
    |> add_withdrawal_scripts(is_authed_by_trade_key, trade_script_hashes)
    |> add_required_signers(is_authed_by_withdrawal_key, withdrawal_key_hashes)
    |> add_withdrawal_scripts(
        is_authed_by_withdrawal_key,
        withdrawal_script_hashes,
      )
    |> ref_tx_in(
        is_dex_order_book_inputed,
        mock_tx_hash(0),
        0,
        from_asset(mock_dex_order_book_token, "", 1),
        mock_hydra_order_book_address,
      )
    |> ref_tx_in_inline_datum(
        is_dex_order_book_inputed,
        mock_dex_order_book_datum,
      )
    |> mint(
        is_token_minted,
        1,
        mock_hydra_user_intent_token,
        if is_token_name_matched {
          ""
        } else {
          "gg"
        },
      )
    |> tx_out(
        is_output_correct,
        mock_hydra_user_intent_address,
        correct_output_value,
      )
    |> tx_out_inline_datum(is_output_correct, output_datum)
    |> complete()
}

test s7_mint_success_cancel_withdrawal_intent_with_withdraw_key_sign() {
  let redeemer = create_mock_mint_cancel_withdrawal_intent()
  let tx =
    mock_mint_cancel_withdrawal_intent_tx(
      CancelWithdrawalIntentTestCase {
        is_dex_order_book_inputed: True,
        is_token_minted: True,
        is_token_name_matched: True,
        is_authed_by_withdrawal_key: True,
        is_authed_by_trade_key: False,
        is_output_correct: True,
      },
    )

  hydra_user_intent_mint.hydra_user_intent.mint(
    mock_dex_order_book_token,
    redeemer,
    mock_hydra_user_intent_token,
    tx,
  )
}

test s7_mint_success_cancel_withdrawal_intent_with_trade_key_sign() {
  let redeemer = create_mock_mint_cancel_withdrawal_intent()
  let tx =
    mock_mint_cancel_withdrawal_intent_tx(
      CancelWithdrawalIntentTestCase {
        is_dex_order_book_inputed: True,
        is_token_minted: True,
        is_token_name_matched: True,
        is_authed_by_withdrawal_key: False,
        is_authed_by_trade_key: True,
        is_output_correct: True,
      },
    )

  hydra_user_intent_mint.hydra_user_intent.mint(
    mock_dex_order_book_token,
    redeemer,
    mock_hydra_user_intent_token,
    tx,
  )
}

test s7_mint_fail_cancel_withdrawal_intent_with_no_dex_oracle_inputed() fail {
  let redeemer = create_mock_mint_cancel_withdrawal_intent()
  let tx =
    mock_mint_cancel_withdrawal_intent_tx(
      CancelWithdrawalIntentTestCase {
        is_dex_order_book_inputed: False,
        is_token_minted: True,
        is_token_name_matched: True,
        is_authed_by_withdrawal_key: True,
        is_authed_by_trade_key: False,
        is_output_correct: True,
      },
    )

  hydra_user_intent_mint.hydra_user_intent.mint(
    mock_dex_order_book_token,
    redeemer,
    mock_hydra_user_intent_token,
    tx,
  )
}

test s7_mint_fail_cancel_withdrawal_intent_with_no_token_minted() {
  let redeemer = create_mock_mint_cancel_withdrawal_intent()
  let tx =
    mock_mint_cancel_withdrawal_intent_tx(
      CancelWithdrawalIntentTestCase {
        is_dex_order_book_inputed: True,
        is_token_minted: False,
        is_token_name_matched: True,
        is_authed_by_withdrawal_key: True,
        is_authed_by_trade_key: False,
        is_output_correct: True,
      },
    )

  !hydra_user_intent_mint.hydra_user_intent.mint(
    mock_dex_order_book_token,
    redeemer,
    mock_hydra_user_intent_token,
    tx,
  )
}

test s7_mint_fail_cancel_withdrawal_intent_with_wrong_token_name() {
  let redeemer = create_mock_mint_cancel_withdrawal_intent()
  let tx =
    mock_mint_cancel_withdrawal_intent_tx(
      CancelWithdrawalIntentTestCase {
        is_dex_order_book_inputed: True,
        is_token_minted: True,
        is_token_name_matched: False,
        is_authed_by_withdrawal_key: True,
        is_authed_by_trade_key: False,
        is_output_correct: True,
      },
    )

  !hydra_user_intent_mint.hydra_user_intent.mint(
    mock_dex_order_book_token,
    redeemer,
    mock_hydra_user_intent_token,
    tx,
  )
}

test s7_mint_fail_cancel_withdrawal_intent_with_no_key_signed() {
  let redeemer = create_mock_mint_cancel_withdrawal_intent()
  let tx =
    mock_mint_cancel_withdrawal_intent_tx(
      CancelWithdrawalIntentTestCase {
        is_dex_order_book_inputed: True,
        is_token_minted: True,
        is_token_name_matched: True,
        is_authed_by_withdrawal_key: False,
        is_authed_by_trade_key: False,
        is_output_correct: True,
      },
    )

  !hydra_user_intent_mint.hydra_user_intent.mint(
    mock_dex_order_book_token,
    redeemer,
    mock_hydra_user_intent_token,
    tx,
  )
}

type TransferIntentTestCase {
  is_dex_order_book_inputed: Bool,
  is_token_minted: Bool,
  is_token_name_matched: Bool,
  is_authed_by_withdrawal_key: Bool,
  is_authed_by_trade_key: Bool,
  is_output_correct: Bool,
}

fn mock_mint_transfer_intent_tx(
  test_case: TransferIntentTestCase,
) -> Transaction {
  let TransferIntentTestCase {
    is_dex_order_book_inputed,
    is_token_minted,
    is_token_name_matched,
    is_authed_by_withdrawal_key,
    is_authed_by_trade_key,
    is_output_correct,
  } = test_case

  let account = UserSpotAccount { account: mock_account }

  let output_datum =
    create_mock_transfer_intent(
      from: account,
      to: UserSpotAccount { account: mock_account_2 },
    )

  let correct_output_value =
    from_asset(mock_hydra_user_intent_token, "", 1)
      |> add("", "", 2_000_000)
  let (trade_key_hashes, trade_script_hashes) = get_trade_keys(account)
  let (withdrawal_key_hashes, withdrawal_script_hashes) =
    get_withdrawal_keys(account)

  mocktail_tx()
    |> add_required_signers(is_authed_by_trade_key, trade_key_hashes)
    |> add_withdrawal_scripts(is_authed_by_trade_key, trade_script_hashes)
    |> add_required_signers(is_authed_by_withdrawal_key, withdrawal_key_hashes)
    |> add_withdrawal_scripts(
        is_authed_by_withdrawal_key,
        withdrawal_script_hashes,
      )
    |> ref_tx_in(
        is_dex_order_book_inputed,
        mock_tx_hash(0),
        0,
        from_asset(mock_dex_order_book_token, "", 1),
        mock_hydra_order_book_address,
      )
    |> ref_tx_in_inline_datum(
        is_dex_order_book_inputed,
        mock_dex_order_book_datum,
      )
    |> mint(
        is_token_minted && is_token_name_matched,
        1,
        mock_hydra_user_intent_token,
        if is_token_name_matched {
          ""
        } else {
          "gg"
        },
      )
    |> tx_out(
        is_output_correct,
        mock_hydra_user_intent_address,
        correct_output_value,
      )
    |> tx_out_inline_datum(is_output_correct, output_datum)
    |> complete()
}

test s7_mint_success_transfer_intent_with_withdraw_key_sign() {
  let redeemer = create_mock_mint_transfer_intent()
  let tx =
    mock_mint_transfer_intent_tx(
      TransferIntentTestCase {
        is_dex_order_book_inputed: True,
        is_token_minted: True,
        is_token_name_matched: True,
        is_authed_by_withdrawal_key: True,
        is_authed_by_trade_key: False,
        is_output_correct: True,
      },
    )

  hydra_user_intent_mint.hydra_user_intent.mint(
    mock_dex_order_book_token,
    redeemer,
    mock_hydra_user_intent_token,
    tx,
  )
}

test s7_mint_success_transfer_intent_with_trade_key_sign() {
  let redeemer = create_mock_mint_transfer_intent()

  let tx =
    mock_mint_transfer_intent_tx(
      TransferIntentTestCase {
        is_dex_order_book_inputed: True,
        is_token_minted: True,
        is_token_name_matched: True,
        is_authed_by_withdrawal_key: False,
        is_authed_by_trade_key: True,
        is_output_correct: True,
      },
    )

  hydra_user_intent_mint.hydra_user_intent.mint(
    mock_dex_order_book_token,
    redeemer,
    mock_hydra_user_intent_token,
    tx,
  )
}

test s7_mint_fail_transfer_intent_with_no_dex_oracle_inputed() fail {
  let redeemer = create_mock_mint_transfer_intent()

  let tx =
    mock_mint_transfer_intent_tx(
      TransferIntentTestCase {
        is_dex_order_book_inputed: False,
        is_token_minted: True,
        is_token_name_matched: True,
        is_authed_by_withdrawal_key: True,
        is_authed_by_trade_key: False,
        is_output_correct: True,
      },
    )

  hydra_user_intent_mint.hydra_user_intent.mint(
    mock_dex_order_book_token,
    redeemer,
    mock_hydra_user_intent_token,
    tx,
  )
}

test s7_mint_fail_transfer_intent_with_no_token_minted() {
  let redeemer = create_mock_mint_transfer_intent()
  let tx =
    mock_mint_transfer_intent_tx(
      TransferIntentTestCase {
        is_dex_order_book_inputed: True,
        is_token_minted: False,
        is_token_name_matched: True,
        is_authed_by_withdrawal_key: True,
        is_authed_by_trade_key: False,
        is_output_correct: True,
      },
    )

  !hydra_user_intent_mint.hydra_user_intent.mint(
    mock_dex_order_book_token,
    redeemer,
    mock_hydra_user_intent_token,
    tx,
  )
}

test s7_mint_fail_transfer_intent_with_wrong_token_name() {
  let redeemer = create_mock_mint_transfer_intent()
  let tx =
    mock_mint_transfer_intent_tx(
      TransferIntentTestCase {
        is_dex_order_book_inputed: True,
        is_token_minted: True,
        is_token_name_matched: False,
        is_authed_by_withdrawal_key: True,
        is_authed_by_trade_key: False,
        is_output_correct: True,
      },
    )

  !hydra_user_intent_mint.hydra_user_intent.mint(
    mock_dex_order_book_token,
    redeemer,
    mock_hydra_user_intent_token,
    tx,
  )
}

test fail_transfer_intent_with_no_key_signed() {
  let redeemer = create_mock_mint_transfer_intent()
  let tx =
    mock_mint_transfer_intent_tx(
      TransferIntentTestCase {
        is_dex_order_book_inputed: True,
        is_token_minted: True,
        is_token_name_matched: True,
        is_authed_by_withdrawal_key: False,
        is_authed_by_trade_key: False,
        is_output_correct: True,
      },
    )

  !hydra_user_intent_mint.hydra_user_intent.mint(
    mock_dex_order_book_token,
    redeemer,
    mock_hydra_user_intent_token,
    tx,
  )
}
