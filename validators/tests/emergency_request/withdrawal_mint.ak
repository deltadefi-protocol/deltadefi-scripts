use cardano/assets.{add, from_asset, from_lovelace}
use cardano/transaction.{Transaction}
use emergency_request/withdrawal_mint
use hydra_dex/types.{EmergencyWithdrawalRequestDatum, RMint, UserSpotAccount}
use hydra_dex/utils.{to_mvalue} as test_utils
use mocktail.{
  complete, invalid_before, mint, mock_tx_hash, mocktail_tx, ref_tx_in,
  ref_tx_in_inline_datum, tx_out, tx_out_inline_datum,
}
use tests/utils.{
  mock_account, mock_app_deposit_request_token,
  mock_emergency_withdrawal_request_address,
  mock_emergency_withdrawal_request_token, mock_input_oracle_datum,
  mock_oracle_address, mock_oracle_nft,
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
        |> add(mock_emergency_withdrawal_request_token, "", 1)
    } else {
      from_lovelace(2_000_000)
    }

  let withdrawal_amount =
    from_asset(mock_emergency_withdrawal_request_token, "", 1)
      |> add(mock_app_deposit_request_token, "", 1)
      |> to_mvalue()

  let output_datum =
    EmergencyWithdrawalRequestDatum {
      account: UserSpotAccount { account: mock_account },
      amount: withdrawal_amount,
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
        mock_emergency_withdrawal_request_token,
        "",
      )
    |> tx_out(True, mock_emergency_withdrawal_request_address, output_value)
    |> tx_out_inline_datum(True, output_datum)
    |> invalid_before(timestamp_check, 101)
    |> complete()
}

test s4_w_mint_success() {
  let test_case =
    MintTestCase {
      timestamp_check: True,
      is_mint_token_sent_to_script: True,
      is_only_token_minted: True,
    }

  let tx = mock_mint_tx(test_case)
  withdrawal_mint.emergency_withdrawal_request.mint(
    mock_oracle_nft,
    RMint,
    mock_emergency_withdrawal_request_token,
    tx,
  )
}

test s4_w_mint_failed_without_timestamp_check() {
  let test_case =
    MintTestCase {
      timestamp_check: False,
      is_mint_token_sent_to_script: True,
      is_only_token_minted: True,
    }

  let tx = mock_mint_tx(test_case)
  !withdrawal_mint.emergency_withdrawal_request.mint(
    mock_oracle_nft,
    RMint,
    mock_emergency_withdrawal_request_token,
    tx,
  )
}

test s4_w_mint_failed_without_minted_sent_to_script() fail {
  let test_case =
    MintTestCase {
      timestamp_check: True,
      is_mint_token_sent_to_script: False,
      is_only_token_minted: True,
    }

  let tx = mock_mint_tx(test_case)
  !withdrawal_mint.emergency_withdrawal_request.mint(
    mock_oracle_nft,
    RMint,
    mock_emergency_withdrawal_request_token,
    tx,
  )
}

test s4_w_mint_failed_with_multiple_tokens_minted() {
  let test_case =
    MintTestCase {
      timestamp_check: True,
      is_mint_token_sent_to_script: True,
      is_only_token_minted: False,
    }

  let tx = mock_mint_tx(test_case)
  !withdrawal_mint.emergency_withdrawal_request.mint(
    mock_oracle_nft,
    RMint,
    mock_emergency_withdrawal_request_token,
    tx,
  )
}
