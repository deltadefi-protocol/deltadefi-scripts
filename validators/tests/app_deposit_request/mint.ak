use app_deposit_request/mint as app_deposit_request_mint
use cardano/address.{Script}
use cardano/assets.{add, from_asset, from_asset_list, from_lovelace}
use cardano/transaction.{Transaction}
use hydra_dex/types.{
  Account, AppDepositRequestDatum, MValue, RBurn, RMint, UserSpotAccount,
}
use mocktail.{
  complete, mint, mock_policy_id, mock_script_hash, mock_tx_hash, mocktail_tx,
  ref_tx_in, ref_tx_in_inline_datum, tx_out, tx_out_inline_datum,
}
use tests/utils.{
  mock_app_deposit_request_address, mock_app_deposit_request_token,
  mock_input_oracle_datum, mock_oracle_address, mock_oracle_nft,
  mock_withdrawal_script_hashes, to_mvalue,
}

type MintTestCase {
  is_app_oracle_inputed: Bool,
  is_app_oracle_format_correctly: Bool,
  is_app_deposit_request_token_minted: Bool,
  is_token_output_clean: Bool,
  is_value_deposited_correctly: Bool,
}

fn mock_mint_tx(test_case: MintTestCase) -> Transaction {
  let MintTestCase {
    is_app_oracle_inputed,
    is_app_oracle_format_correctly,
    is_app_deposit_request_token_minted,
    is_token_output_clean,
    is_value_deposited_correctly,
  } = test_case

  let deposit_value: MValue =
    from_lovelace(100_000_000)
      |> add("policy1", "token1", 100_000_000)
      |> to_mvalue()

  let incorrect_deposit_value =
    from_asset("A", "abc", 1)
      |> add("C", "def", 10)
      |> to_mvalue()

  let output_datum =
    AppDepositRequestDatum {
      account: UserSpotAccount {
        account: Account {
          account_id: "1",
          master_key: Script(mock_script_hash(0)),
          operation_key: Script(mock_script_hash(1)),
        },
      },
      amount: deposit_value,
    }
  mocktail_tx()
    |> mint(
        is_app_deposit_request_token_minted,
        1,
        mock_app_deposit_request_token,
        "",
      )
    |> ref_tx_in(
        is_app_oracle_inputed,
        mock_tx_hash(0),
        0,
        from_asset(mock_oracle_nft, "", 1),
        mock_oracle_address,
      )
    |> ref_tx_in_inline_datum(
        is_app_oracle_inputed && is_app_oracle_format_correctly,
        mock_input_oracle_datum,
      )
    |> ref_tx_in_inline_datum(
        is_app_oracle_inputed && !is_app_oracle_format_correctly,
        mock_withdrawal_script_hashes,
      )
    |> tx_out(
        is_value_deposited_correctly,
        mock_app_deposit_request_address,
        from_asset_list(deposit_value)
          |> add(mock_app_deposit_request_token, "", 1),
      )
    |> tx_out(
        !is_value_deposited_correctly,
        mock_app_deposit_request_address,
        from_asset_list(incorrect_deposit_value),
      )
    |> tx_out_inline_datum(True, output_datum)
    |> tx_out(
        !is_token_output_clean,
        mock_app_deposit_request_address,
        from_asset_list(deposit_value)
          |> add(mock_app_deposit_request_token, "", 1)
          |> add(mock_policy_id(999), "", 1),
      )
    |> tx_out_inline_datum(!is_token_output_clean, output_datum)
    |> complete()
}

test s3_mint_success_mint() {
  let tx =
    mock_mint_tx(
      MintTestCase {
        is_app_oracle_inputed: True,
        is_app_oracle_format_correctly: True,
        is_app_deposit_request_token_minted: True,
        is_token_output_clean: True,
        is_value_deposited_correctly: True,
      },
    )

  app_deposit_request_mint.app_deposit_request.mint(
    mock_oracle_nft,
    RMint,
    mock_app_deposit_request_token,
    tx,
  )
}

test s3_mint_fail_mint_with_no_app_oracle_inputed() fail {
  let tx =
    mock_mint_tx(
      MintTestCase {
        is_app_oracle_inputed: False,
        is_app_oracle_format_correctly: True,
        is_app_deposit_request_token_minted: True,
        is_token_output_clean: True,
        is_value_deposited_correctly: True,
      },
    )

  !app_deposit_request_mint.app_deposit_request.mint(
    mock_oracle_nft,
    RMint,
    mock_app_deposit_request_token,
    tx,
  )
}

test s3_mint_fail_mint_with_incorrect_app_oracle_inputed() fail {
  let tx =
    mock_mint_tx(
      MintTestCase {
        is_app_oracle_inputed: True,
        is_app_oracle_format_correctly: False,
        is_app_deposit_request_token_minted: True,
        is_token_output_clean: True,
        is_value_deposited_correctly: True,
      },
    )

  !app_deposit_request_mint.app_deposit_request.mint(
    mock_oracle_nft,
    RMint,
    mock_app_deposit_request_token,
    tx,
  )
}

test s3_mint_fail_mint_with_no_mint() {
  let tx =
    mock_mint_tx(
      MintTestCase {
        is_app_oracle_inputed: True,
        is_app_oracle_format_correctly: True,
        is_app_deposit_request_token_minted: False,
        is_token_output_clean: True,
        is_value_deposited_correctly: True,
      },
    )

  !app_deposit_request_mint.app_deposit_request.mint(
    mock_oracle_nft,
    RMint,
    mock_app_deposit_request_token,
    tx,
  )
}

test s3_mint_fail_mint_with_output_not_clean() {
  let tx =
    mock_mint_tx(
      MintTestCase {
        is_app_oracle_inputed: True,
        is_app_oracle_format_correctly: True,
        is_app_deposit_request_token_minted: True,
        is_token_output_clean: False,
        is_value_deposited_correctly: True,
      },
    )

  !app_deposit_request_mint.app_deposit_request.mint(
    mock_oracle_nft,
    RMint,
    mock_app_deposit_request_token,
    tx,
  )
}

test s3_mint_fail_mint_with_deposit_value_output_incorrect() {
  let tx =
    mock_mint_tx(
      MintTestCase {
        is_app_oracle_inputed: True,
        is_app_oracle_format_correctly: True,
        is_app_deposit_request_token_minted: True,
        is_token_output_clean: True,
        is_value_deposited_correctly: False,
      },
    )

  !app_deposit_request_mint.app_deposit_request.mint(
    mock_oracle_nft,
    RMint,
    mock_app_deposit_request_token,
    tx,
  )
}

type BurnTestCase {
  is_app_oracle_inputed: Bool,
  is_app_oracle_format_correctly: Bool,
  is_app_deposit_request_token_burnt: Bool,
  is_burnt_with_minting: Bool,
  is_burnt_with_other_minting: Bool,
}

fn mock_burn_tx(test_case: BurnTestCase) -> Transaction {
  let BurnTestCase {
    is_app_oracle_inputed,
    is_app_oracle_format_correctly,
    is_app_deposit_request_token_burnt,
    is_burnt_with_minting,
    is_burnt_with_other_minting,
  } = test_case

  mocktail_tx()
    |> mint(
        is_app_deposit_request_token_burnt,
        -1,
        mock_app_deposit_request_token,
        "",
      )
    |> mint(is_burnt_with_minting, 1, mock_app_deposit_request_token, "")
    |> mint(is_burnt_with_other_minting, 1, mock_policy_id(999), "")
    |> ref_tx_in(
        is_app_oracle_inputed,
        mock_tx_hash(0),
        0,
        from_asset(mock_oracle_nft, "", 1),
        mock_oracle_address,
      )
    |> ref_tx_in_inline_datum(
        is_app_oracle_inputed && is_app_oracle_format_correctly,
        mock_input_oracle_datum,
      )
    |> ref_tx_in_inline_datum(
        is_app_oracle_inputed && !is_app_oracle_format_correctly,
        mock_withdrawal_script_hashes,
      )
    |> complete()
}

test s3_mint_success_burn() {
  let redeemer = RBurn

  let tx =
    mock_burn_tx(
      BurnTestCase {
        is_app_oracle_inputed: True,
        is_app_oracle_format_correctly: True,
        is_app_deposit_request_token_burnt: True,
        is_burnt_with_minting: False,
        is_burnt_with_other_minting: False,
      },
    )
  app_deposit_request_mint.app_deposit_request.mint(
    mock_oracle_nft,
    redeemer,
    mock_app_deposit_request_token,
    tx,
  )
}

test s3_mint_success_burn_with_other_minting() {
  let redeemer = RBurn

  let tx =
    mock_burn_tx(
      BurnTestCase {
        is_app_oracle_inputed: True,
        is_app_oracle_format_correctly: True,
        is_app_deposit_request_token_burnt: True,
        is_burnt_with_minting: False,
        is_burnt_with_other_minting: True,
      },
    )
  app_deposit_request_mint.app_deposit_request.mint(
    mock_oracle_nft,
    redeemer,
    mock_app_deposit_request_token,
    tx,
  )
}

test s3_mint_fail_burn_with_mint() {
  let redeemer = RBurn
  let tx =
    mock_burn_tx(
      BurnTestCase {
        is_app_oracle_inputed: True,
        is_app_oracle_format_correctly: True,
        is_app_deposit_request_token_burnt: True,
        is_burnt_with_minting: True,
        is_burnt_with_other_minting: False,
      },
    )
  !app_deposit_request_mint.app_deposit_request.mint(
    mock_oracle_nft,
    redeemer,
    mock_app_deposit_request_token,
    tx,
  )
}
