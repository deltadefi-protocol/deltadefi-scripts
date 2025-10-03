use aiken/merkle_patricia_forestry as mpf
use cardano/assets.{from_asset}
use cardano/transaction.{Transaction}
use dex_account_balance/mint as dex_account_balance
use hydra_dex/types.{DexAccountBalanceDatum, RMint}
use mocktail.{
  complete, mint, mock_tx_hash, mocktail_tx, ref_tx_in, ref_tx_in_inline_datum,
  required_signer_hash, tx_in, tx_out, tx_out_inline_datum,
}
use mocktail/virgin_address.{mock_pub_key_address}
use tests/utils.{
  mock_dex_account_balance_address, mock_dex_account_balance_token,
  mock_input_oracle_datum, mock_operation_key, mock_oracle_address,
  mock_oracle_nft,
}

type MintTestCase {
  no_input_with_current_token: Bool,
  is_empty_root: Bool,
  is_single_token_minted: Bool,
  is_operation_key_signed: Bool,
}

fn mock_mint_tx(test_case: MintTestCase) -> Transaction {
  let MintTestCase {
    no_input_with_current_token,
    is_empty_root,
    is_single_token_minted,
    is_operation_key_signed,
  } = test_case

  let merkle_root =
    if is_empty_root {
      mpf.root(mpf.empty)
    } else {
      "0000002412421"
    }
  let output_datum =
    DexAccountBalanceDatum { account_balance_merkle_root: merkle_root }
  mocktail_tx()
    |> ref_tx_in(
        True,
        mock_tx_hash(0),
        0,
        from_asset(mock_oracle_nft, "", 1),
        mock_oracle_address,
      )
    |> ref_tx_in_inline_datum(True, mock_input_oracle_datum)
    |> tx_in(
        !no_input_with_current_token,
        mock_tx_hash(0),
        0,
        from_asset(mock_dex_account_balance_token, "", 1),
        mock_pub_key_address(0, None),
      )
    |> mint(
        True,
        if is_single_token_minted {
          1
        } else {
          2
        },
        mock_dex_account_balance_token,
        "",
      )
    |> tx_out(
        True,
        mock_dex_account_balance_address,
        from_asset(mock_dex_account_balance_token, "", 1),
      )
    |> tx_out_inline_datum(True, output_datum)
    |> tx_out(
        !is_single_token_minted,
        mock_dex_account_balance_address,
        from_asset(mock_dex_account_balance_token, "", 1),
      )
    |> tx_out_inline_datum(!is_single_token_minted, output_datum)
    |> required_signer_hash(is_operation_key_signed, mock_operation_key)
    |> complete()
}

test s5_mint_success() {
  let tx =
    mock_mint_tx(
      MintTestCase {
        no_input_with_current_token: True,
        is_empty_root: True,
        is_single_token_minted: True,
        is_operation_key_signed: True,
      },
    )

  dex_account_balance.dex_account_balance.mint(
    mock_oracle_nft,
    RMint,
    mock_dex_account_balance_token,
    tx,
  )
}

test s5_mint_succeed_with_more_token_minted_with_empty_root() {
  let tx =
    mock_mint_tx(
      MintTestCase {
        no_input_with_current_token: True,
        is_empty_root: True,
        is_single_token_minted: False,
        is_operation_key_signed: True,
      },
    )

  dex_account_balance.dex_account_balance.mint(
    mock_oracle_nft,
    RMint,
    mock_dex_account_balance_token,
    tx,
  )
}

test s5_mint_fail_with_input_with_current_token() {
  let tx =
    mock_mint_tx(
      MintTestCase {
        no_input_with_current_token: False,
        is_empty_root: True,
        is_single_token_minted: True,
        is_operation_key_signed: True,
      },
    )

  !dex_account_balance.dex_account_balance.mint(
    mock_oracle_nft,
    RMint,
    mock_dex_account_balance_token,
    tx,
  )
}

test s5_mint_fail_without_empty_root() {
  let tx =
    mock_mint_tx(
      MintTestCase {
        no_input_with_current_token: True,
        is_empty_root: False,
        is_single_token_minted: True,
        is_operation_key_signed: True,
      },
    )

  !dex_account_balance.dex_account_balance.mint(
    mock_oracle_nft,
    RMint,
    mock_dex_account_balance_token,
    tx,
  )
}

test s5_mint_fail_with_more_token_minted_non_empty_root() fail {
  let tx =
    mock_mint_tx(
      MintTestCase {
        no_input_with_current_token: True,
        is_empty_root: False,
        is_single_token_minted: False,
        is_operation_key_signed: True,
      },
    )

  dex_account_balance.dex_account_balance.mint(
    mock_oracle_nft,
    RMint,
    mock_dex_account_balance_token,
    tx,
  )
}

test s5_mint_fail_without_operation_key_signed() {
  let tx =
    mock_mint_tx(
      MintTestCase {
        no_input_with_current_token: True,
        is_empty_root: True,
        is_single_token_minted: True,
        is_operation_key_signed: False,
      },
    )

  !dex_account_balance.dex_account_balance.mint(
    mock_oracle_nft,
    RMint,
    mock_dex_account_balance_token,
    tx,
  )
}
