use cardano/assets.{add, from_asset, from_lovelace}
use cardano/transaction.{Transaction}
use emergency_request/cancel_order_mint
use hydra_dex/types.{EmergencyCancelRequestDatum, RMint}
use mocktail.{
  complete, invalid_before, mint, mock_tx_hash, mocktail_tx, ref_tx_in,
  ref_tx_in_inline_datum, tx_out, tx_out_inline_datum,
}
use tests/utils.{
  mock_account, mock_emergency_cancel_order_request_address,
  mock_emergency_cancel_order_request_token, mock_input_oracle_datum,
  mock_oracle_address, mock_oracle_nft, mock_user_account,
}

type MintTestCase {
  timestamp_check: Bool,
  is_mint_token_sent_to_script: Bool,
  is_only_token_minted: Bool,
}

fn mock_mint_tx(test_case: MintTestCase) -> Transaction {
  let MintTestCase {
    timestamp_check,
    is_mint_token_sent_to_script,
    is_only_token_minted,
  } = test_case

  let output_value =
    if is_mint_token_sent_to_script {
      from_lovelace(2_000_000)
        |> add(mock_emergency_cancel_order_request_token, "", 1)
    } else {
      from_lovelace(2_000_000)
    }

  let output_datum =
    EmergencyCancelRequestDatum {
      account: mock_user_account(mock_account),
      order_id: "order_id",
      timestamp: 100,
    }

  mocktail_tx()
    |> ref_tx_in(
        True,
        mock_tx_hash(0),
        0,
        from_asset(mock_oracle_nft, "", 1),
        mock_oracle_address,
      )
    |> ref_tx_in_inline_datum(True, mock_input_oracle_datum)
    |> mint(
        True,
        if is_only_token_minted {
          1
        } else {
          2
        },
        mock_emergency_cancel_order_request_token,
        "",
      )
    |> tx_out(True, mock_emergency_cancel_order_request_address, output_value)
    |> tx_out_inline_datum(True, output_datum)
    |> invalid_before(timestamp_check, 101)
    |> complete()
}

test s4_c_mint_success() {
  let test_case =
    MintTestCase {
      timestamp_check: True,
      is_mint_token_sent_to_script: True,
      is_only_token_minted: True,
    }

  let tx = mock_mint_tx(test_case)
  cancel_order_mint.emergency_cancel_order_request.mint(
    mock_oracle_nft,
    RMint,
    mock_emergency_cancel_order_request_token,
    tx,
  )
}

test s4_c_mint_failed_without_timestamp_check() {
  let test_case =
    MintTestCase {
      timestamp_check: False,
      is_mint_token_sent_to_script: True,
      is_only_token_minted: True,
    }

  let tx = mock_mint_tx(test_case)
  !cancel_order_mint.emergency_cancel_order_request.mint(
    mock_oracle_nft,
    RMint,
    mock_emergency_cancel_order_request_token,
    tx,
  )
}

test s4_c_mint_failed_without_minted_sent_to_script() fail {
  let test_case =
    MintTestCase {
      timestamp_check: True,
      is_mint_token_sent_to_script: False,
      is_only_token_minted: True,
    }

  let tx = mock_mint_tx(test_case)
  !cancel_order_mint.emergency_cancel_order_request.mint(
    mock_oracle_nft,
    RMint,
    mock_emergency_cancel_order_request_token,
    tx,
  )
}

test s4_c_mint_failed_with_multiple_tokens_minted() {
  let test_case =
    MintTestCase {
      timestamp_check: True,
      is_mint_token_sent_to_script: True,
      is_only_token_minted: False,
    }

  let tx = mock_mint_tx(test_case)
  !cancel_order_mint.emergency_cancel_order_request.mint(
    mock_oracle_nft,
    RMint,
    mock_emergency_cancel_order_request_token,
    tx,
  )
}
