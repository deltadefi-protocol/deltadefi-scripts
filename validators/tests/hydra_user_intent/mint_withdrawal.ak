use cardano/assets.{from_asset}
use cardano/transaction.{Transaction}
use hydra_dex/types.{BurnIntent}
use hydra_user_intent/mint as hydra_user_intent_mint
use mocktail.{
  complete, mock_tx_hash, mocktail_tx, ref_tx_in, ref_tx_in_inline_datum,
  required_signer_hash,
}
use tests/utils.{
  mock_dex_order_book_datum, mock_dex_order_book_token,
  mock_hydra_order_book_address, mock_hydra_user_intent_token,
}

fn mock_process_intent_tx(is_operation_key_signed: Bool) -> Transaction {
  mocktail_tx()
    |> ref_tx_in(
        True,
        mock_tx_hash(0),
        0,
        from_asset(mock_dex_order_book_token, "", 1),
        mock_hydra_order_book_address,
      )
    |> ref_tx_in_inline_datum(True, mock_dex_order_book_datum)
    |> required_signer_hash(
        is_operation_key_signed,
        mock_dex_order_book_datum.operation_key,
      )
    |> complete()
}

test s7_mint_w_success_process_place_order() {
  let tx = mock_process_intent_tx(True)

  hydra_user_intent_mint.hydra_user_intent.mint(
    mock_dex_order_book_token,
    BurnIntent,
    mock_hydra_user_intent_token,
    tx,
  )
}

test s7_mint_w_fail_process_place_order_not_signed() {
  let tx = mock_process_intent_tx(False)

  !hydra_user_intent_mint.hydra_user_intent.mint(
    mock_dex_order_book_token,
    BurnIntent,
    mock_hydra_user_intent_token,
    tx,
  )
}
