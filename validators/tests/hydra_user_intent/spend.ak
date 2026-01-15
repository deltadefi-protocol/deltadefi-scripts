use cardano/assets.{from_asset}
use cardano/transaction.{Transaction}
use hydra_user_intent as hui
use mocktail.{
  complete, mint, mock_tx_hash, mock_utxo_ref, mocktail_tx, ref_tx_in,
  ref_tx_in_inline_datum, tx_in,
}
use tests/utils.{
  mock_dex_order_book_datum, mock_dex_order_book_token,
  mock_hydra_order_book_address, mock_hydra_user_intent_token,
}

type DexSpendTestCase {
  is_dex_order_book_inputed: Bool,
  is_token_burnt: Bool,
}

fn mock_burn_tx(test_case: DexSpendTestCase) -> Transaction {
  let DexSpendTestCase { is_dex_order_book_inputed, is_token_burnt } = test_case

  mocktail_tx()
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
    |> tx_in(
        True,
        mock_tx_hash(0),
        1,
        from_asset(mock_hydra_user_intent_token, "", 1),
        mock_hydra_order_book_address,
      )
    |> mint(is_token_burnt, -1, mock_hydra_user_intent_token, "")
    |> complete()
}

test s7_spend_success_burn() {
  let tx =
    mock_burn_tx(
      DexSpendTestCase { is_dex_order_book_inputed: True, is_token_burnt: True },
    )

  hui.hydra_user_intent.spend(
    mock_dex_order_book_token,
    None,
    Void,
    mock_utxo_ref(0, 1),
    tx,
  )
}

test s7_spend_fail_burn_with_with_no_dex_oracle_inputed() fail {
  let tx =
    mock_burn_tx(
      DexSpendTestCase {
        is_dex_order_book_inputed: False,
        is_token_burnt: True,
      },
    )

  hui.hydra_user_intent.spend(
    mock_dex_order_book_token,
    None,
    Void,
    mock_utxo_ref(0, 1),
    tx,
  )
}

test s7_spend_fail_burn_with_no_burn() {
  let tx =
    mock_burn_tx(
      DexSpendTestCase {
        is_dex_order_book_inputed: True,
        is_token_burnt: False,
      },
    )

  !hui.hydra_user_intent.spend(
    mock_dex_order_book_token,
    None,
    Void,
    mock_utxo_ref(0, 1),
    tx,
  )
}
