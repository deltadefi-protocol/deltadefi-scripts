use cardano/assets.{add, from_asset, merge, zero}
use cardano/transaction.{Transaction}
use hydra_account_balance/mint as hydra_account_balance_mint
use hydra_dex/types.{RMint, UserSpotAccount}
use mocktail.{
  complete, mint, mock_tx_hash, mocktail_tx, ref_tx_in, ref_tx_in_inline_datum,
  required_signer_hash, script_withdrawal, tx_in, tx_out, tx_out_inline_datum,
}
use tests/utils.{
  mock_account, mock_dex_order_book_address, mock_dex_order_book_datum,
  mock_dex_order_book_token, mock_hydra_account_balance_address,
  mock_hydra_account_balance_token, mock_hydra_head_open, mock_hydra_lovelace,
  mock_operation_key,
}

type MintTestCase {
  is_dex_order_book_inputed: Bool,
  no_input_with_current_token: Bool,
  is_empty_balance: Bool,
  is_single_token_minted: Bool,
  is_operation_key_signed: Bool,
  is_auth_cred_attached: Bool,
}

fn mock_mint_tx(test_case: MintTestCase) -> Transaction {
  let MintTestCase {
    is_dex_order_book_inputed,
    no_input_with_current_token,
    is_empty_balance,
    is_single_token_minted,
    is_operation_key_signed,
    is_auth_cred_attached,
  } = test_case

  let account = UserSpotAccount { account: mock_account }

  let input_value =
    from_asset(mock_hydra_account_balance_token, "", 1)
      |> merge(mock_hydra_lovelace(2_000_000))

  let output_balance =
    if is_empty_balance {
      zero
    } else {
      mock_hydra_lovelace(1_000_000)
    }

  let output_value =
    output_balance
      |> add(mock_hydra_account_balance_token, "", 1)

  mocktail_tx()
    |> ref_tx_in(
        is_dex_order_book_inputed,
        mock_tx_hash(0),
        0,
        from_asset(mock_dex_order_book_token, "", 1),
        mock_dex_order_book_address,
      )
    |> ref_tx_in_inline_datum(
        is_dex_order_book_inputed,
        mock_dex_order_book_datum,
      )
    |> tx_in(
        !no_input_with_current_token,
        mock_tx_hash(0),
        0,
        input_value,
        mock_hydra_account_balance_address,
      )
    |> mint(
        True,
        if is_single_token_minted {
          1
        } else {
          2
        },
        mock_hydra_account_balance_token,
        "",
      )
    |> tx_out(True, mock_hydra_account_balance_address, output_value)
    |> tx_out_inline_datum(True, account)
    |> script_withdrawal(is_auth_cred_attached, mock_hydra_head_open, 0)
    |> required_signer_hash(is_operation_key_signed, mock_operation_key)
    |> complete()
}

test s8_mint_success_mint_at_hydra_open() {
  let redeemer = RMint
  let tx =
    mock_mint_tx(
      MintTestCase {
        is_dex_order_book_inputed: True,
        no_input_with_current_token: False,
        is_empty_balance: False,
        is_single_token_minted: False,
        is_operation_key_signed: False,
        is_auth_cred_attached: True,
      },
    )

  hydra_account_balance_mint.hydra_account_balance.mint(
    mock_dex_order_book_token,
    redeemer,
    mock_hydra_account_balance_token,
    tx,
  )
}

test s8_mint_success_mint_for_empty_balance() {
  let redeemer = RMint
  let tx =
    mock_mint_tx(
      MintTestCase {
        is_dex_order_book_inputed: True,
        no_input_with_current_token: True,
        is_empty_balance: True,
        is_single_token_minted: True,
        is_operation_key_signed: True,
        is_auth_cred_attached: False,
      },
    )

  hydra_account_balance_mint.hydra_account_balance.mint(
    mock_dex_order_book_token,
    redeemer,
    mock_hydra_account_balance_token,
    tx,
  )
}

test s8_mint_fail_mint_for_empty_balance_with_current_token_input() {
  let redeemer = RMint
  let tx =
    mock_mint_tx(
      MintTestCase {
        is_dex_order_book_inputed: True,
        no_input_with_current_token: False,
        is_empty_balance: True,
        is_single_token_minted: True,
        is_operation_key_signed: True,
        is_auth_cred_attached: False,
      },
    )

  !hydra_account_balance_mint.hydra_account_balance.mint(
    mock_dex_order_book_token,
    redeemer,
    mock_hydra_account_balance_token,
    tx,
  )
}

test s8_mint_fail_mint_for_empty_balance_without_empty_balance() fail {
  let redeemer = RMint
  let tx =
    mock_mint_tx(
      MintTestCase {
        is_dex_order_book_inputed: True,
        no_input_with_current_token: True,
        is_empty_balance: False,
        is_single_token_minted: True,
        is_operation_key_signed: True,
        is_auth_cred_attached: False,
      },
    )

  hydra_account_balance_mint.hydra_account_balance.mint(
    mock_dex_order_book_token,
    redeemer,
    mock_hydra_account_balance_token,
    tx,
  )
}

test s8_mint_fail_mint_for_empty_balance_with_multiple_token_minted() {
  let redeemer = RMint
  let tx =
    mock_mint_tx(
      MintTestCase {
        is_dex_order_book_inputed: True,
        no_input_with_current_token: True,
        is_empty_balance: True,
        is_single_token_minted: False,
        is_operation_key_signed: True,
        is_auth_cred_attached: False,
      },
    )

  !hydra_account_balance_mint.hydra_account_balance.mint(
    mock_dex_order_book_token,
    redeemer,
    mock_hydra_account_balance_token,
    tx,
  )
}

test s8_mint_fail_mint_for_empty_balance_without_ops_key() {
  let redeemer = RMint
  let tx =
    mock_mint_tx(
      MintTestCase {
        is_dex_order_book_inputed: True,
        no_input_with_current_token: True,
        is_empty_balance: True,
        is_single_token_minted: True,
        is_operation_key_signed: False,
        is_auth_cred_attached: False,
      },
    )

  !hydra_account_balance_mint.hydra_account_balance.mint(
    mock_dex_order_book_token,
    redeemer,
    mock_hydra_account_balance_token,
    tx,
  )
}
