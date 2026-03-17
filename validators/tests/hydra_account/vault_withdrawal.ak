use cardano/address.{Script, VerificationKey, from_script}
use cardano/assets.{from_asset, merge, negate}
use cardano/transaction.{Transaction}
use hydra_account/core as ha
use hydra_dex/types.{
  Account, ProcessVaultWithdrawal, SharesDelete, SharesInsert, UserTradeAccount,
  VaultOracleDatum, VaultWithdrawalIntentDatumL2,
}
use mocktail.{
  complete, mint, mock_policy_id, mock_pub_key_hash, mock_tx_hash, mocktail_tx,
  ref_tx_in, ref_tx_in_inline_datum, required_signer_hash, tx_in,
  tx_in_inline_datum, tx_out, tx_out_inline_datum,
}
use tests/utils.{
  mock_account, mock_account_3, mock_dex_order_book_address,
  mock_dex_order_book_datum, mock_dex_order_book_token,
  mock_hydra_account_address, mock_hydra_lovelace, mock_operation_key,
  mock_user_account,
} as test_utils

// ========== Test Constants ==========

const mock_vault_oracle_nft = mock_policy_id(500)

const mock_l2_withdrawal_intent_script_hash =
  #"abcdef1234567890abcdef1234567890abcdef1234567890abcdef12"

const mock_operator_key = mock_pub_key_hash(999)

// Mock vault account - uses intent script hash as master key
fn mock_vault_account() {
  Account {
    account_id: #"aabbccdd",
    master_key: Script(mock_l2_withdrawal_intent_script_hash),
    operation_key: Script(mock_l2_withdrawal_intent_script_hash),
  }
}

fn mock_vault_user_account() {
  UserTradeAccount {
    account: mock_vault_account(),
    trading_logic: test_utils.mock_hydra_order_book,
  }
}

fn mock_operator_account() {
  Account {
    account_id: #"eeeeeeee",
    master_key: VerificationKey(mock_operator_key),
    operation_key: VerificationKey(mock_operator_key),
  }
}

fn mock_operator_user_account() {
  UserTradeAccount {
    account: mock_operator_account(),
    trading_logic: test_utils.mock_hydra_order_book,
  }
}

fn mock_vault_oracle_datum_input() -> VaultOracleDatum {
  VaultOracleDatum {
    app_oracle: mock_policy_id(0),
    vault_script_hash: #"",
    l1_deposit_intent_script_hash: #"",
    l1_withdrawal_intent_script_hash: #"",
    l2_deposit_intent_script_hash: #"",
    l2_withdrawal_intent_script_hash: mock_l2_withdrawal_intent_script_hash,
    pluggable_logic: #"",
    vault_stake_rotation_script_hash: #"",
    operator_key: mock_operator_key,
    operator_account: mock_operator_user_account(),
    operator_charge_percentage: 10,
    operator_min_deposit_percentage: 0,
    hydra_node_pub_keys: [],
    is_active: True,
    total_shares: 1_000_000_000_000,
    operator_shares: 0,
    total_deposited: 1_000_000_000,
    shares_merkle_root: #"",
    total_fee_collected: 0,
  }
}

// ========== Test Case Type ==========

type VaultWithdrawalTestCase {
  is_operation_key_signed: Bool,
  is_operator_key_signed: Bool,
  is_withdrawer_balance_increased: Bool,
  is_vault_balance_deducted: Bool,
  is_intent_token_burnt: Bool,
  has_other_account_input: Bool,
  has_other_account_output: Bool,
}

// ========== Mock Transaction Builder ==========

fn mock_vault_withdrawal_tx(test_case: VaultWithdrawalTestCase) -> Transaction {
  let VaultWithdrawalTestCase {
    is_operation_key_signed,
    is_operator_key_signed,
    is_withdrawer_balance_increased,
    is_vault_balance_deducted,
    is_intent_token_burnt,
    has_other_account_input,
    has_other_account_output,
  } = test_case

  // Withdrawal: user receives value from vault
  let withdrawal_value = mock_hydra_lovelace(100_000_000)
  let withdrawer_balance_start = mock_hydra_lovelace(500_000_000)
  let vault_balance_start = mock_hydra_lovelace(5_000_000_000)

  let withdrawer_balance_end =
    if is_withdrawer_balance_increased {
      withdrawal_value |> merge(withdrawer_balance_start)
    } else {
      withdrawer_balance_start
    }

  let vault_balance_end =
    if is_vault_balance_deducted {
      withdrawal_value |> negate() |> merge(vault_balance_start)
    } else {
      vault_balance_start
    }

  let vault_oracle_address = from_script("vault_oracle")

  // Input oracle datum
  let input_oracle_datum = mock_vault_oracle_datum_input()

  // Output oracle datum - updated after withdrawal
  // TODO: Update shares calculation when price/fee tests are added
  let shares_to_redeem = 100_000_000_000
  let output_oracle_datum =
    VaultOracleDatum {
      ..input_oracle_datum,
      total_shares: input_oracle_datum.total_shares - shares_to_redeem,
      total_deposited: input_oracle_datum.total_deposited - 100_000_000,
      shares_merkle_root: #"0000000000000000000000000000000000000000",
    }

  let intent_address = from_script(mock_l2_withdrawal_intent_script_hash)

  mocktail_tx()
    // Reference input: DexOrderBook
    |> ref_tx_in(
        True,
        mock_tx_hash(1),
        0,
        from_asset(mock_dex_order_book_token, "", 1),
        mock_dex_order_book_address,
      )
    |> ref_tx_in_inline_datum(True, mock_dex_order_book_datum)
    // Intent input (to be burnt)
    |> tx_in(
        True,
        mock_tx_hash(0),
        0,
        from_asset(mock_l2_withdrawal_intent_script_hash, "", 1),
        intent_address,
      )
    |> tx_in_inline_datum(
        True,
        VaultWithdrawalIntentDatumL2 {
          vault_oracle_nft: mock_vault_oracle_nft,
          withdrawer: mock_user_account(mock_account),
          shares_to_redeem,
        },
      )
    // Vault Oracle input
    |> tx_in(
        True,
        mock_tx_hash(0),
        1,
        from_asset(mock_vault_oracle_nft, "", 1),
        vault_oracle_address,
      )
    |> tx_in_inline_datum(True, input_oracle_datum)
    // Vault Oracle output
    |> tx_out(
        True,
        vault_oracle_address,
        from_asset(mock_vault_oracle_nft, "", 1),
      )
    |> tx_out_inline_datum(True, output_oracle_datum)
    // Withdrawer input
    |> tx_in(
        True,
        mock_tx_hash(0),
        2,
        withdrawer_balance_start,
        mock_hydra_account_address,
      )
    |> tx_in_inline_datum(True, mock_user_account(mock_account))
    // Withdrawer output
    |> tx_out(True, mock_hydra_account_address, withdrawer_balance_end)
    |> tx_out_inline_datum(True, mock_user_account(mock_account))
    // Vault account input
    |> tx_in(
        True,
        mock_tx_hash(0),
        3,
        vault_balance_start,
        mock_hydra_account_address,
      )
    |> tx_in_inline_datum(True, mock_vault_user_account())
    // Vault account output
    |> tx_out(True, mock_hydra_account_address, vault_balance_end)
    |> tx_out_inline_datum(True, mock_vault_user_account())
    // Other account (for testing isolation)
    |> tx_in(
        has_other_account_input,
        mock_tx_hash(0),
        4,
        mock_hydra_lovelace(500_000_000),
        mock_hydra_account_address,
      )
    |> tx_in_inline_datum(
        has_other_account_input,
        mock_user_account(mock_account_3),
      )
    |> tx_out(
        has_other_account_output,
        mock_hydra_account_address,
        mock_hydra_lovelace(500_000_000),
      )
    |> tx_out_inline_datum(
        has_other_account_output,
        mock_user_account(mock_account_3),
      )
    // Mint (burn intent token)
    |> mint(
        is_intent_token_burnt,
        -1,
        mock_l2_withdrawal_intent_script_hash,
        "",
      )
    // Required signers (operation_key OR operator_key)
    |> required_signer_hash(is_operation_key_signed, mock_operation_key)
    |> required_signer_hash(is_operator_key_signed, mock_operator_key)
    |> complete()
}

// ========== Success Tests ==========

// TODO: Add success test with proper merkle proof and price verification
// test s8_vw_success_operation_key() {
//   ...
// }

// TODO: Test operator_key as alternative signer
// test s8_vw_success_operator_key() {
//   ...
// }

// ========== Failure Tests ==========

test s8_vw_failed_without_any_signature() fail {
  let test_case =
    VaultWithdrawalTestCase {
      is_operation_key_signed: False,
      is_operator_key_signed: False,
      is_withdrawer_balance_increased: True,
      is_vault_balance_deducted: True,
      is_intent_token_burnt: True,
      has_other_account_input: False,
      has_other_account_output: False,
    }

  let tx = mock_vault_withdrawal_tx(test_case)

  ha.hydra_account.withdraw(
    mock_dex_order_book_token,
    ProcessVaultWithdrawal(
      #"",
      [],
      SharesDelete { proof: [], old_value: #"" },
      SharesInsert { proof: [] },
    ),
    Script(""),
    tx,
  )
}

test s8_vw_failed_without_withdrawer_balance_increased() fail {
  let test_case =
    VaultWithdrawalTestCase {
      is_operation_key_signed: True,
      is_operator_key_signed: False,
      is_withdrawer_balance_increased: False,
      is_vault_balance_deducted: True,
      is_intent_token_burnt: True,
      has_other_account_input: False,
      has_other_account_output: False,
    }

  let tx = mock_vault_withdrawal_tx(test_case)

  ha.hydra_account.withdraw(
    mock_dex_order_book_token,
    ProcessVaultWithdrawal(
      #"",
      [],
      SharesDelete { proof: [], old_value: #"" },
      SharesInsert { proof: [] },
    ),
    Script(""),
    tx,
  )
}

test s8_vw_failed_without_vault_balance_deducted() fail {
  let test_case =
    VaultWithdrawalTestCase {
      is_operation_key_signed: True,
      is_operator_key_signed: False,
      is_withdrawer_balance_increased: True,
      is_vault_balance_deducted: False,
      is_intent_token_burnt: True,
      has_other_account_input: False,
      has_other_account_output: False,
    }

  let tx = mock_vault_withdrawal_tx(test_case)

  ha.hydra_account.withdraw(
    mock_dex_order_book_token,
    ProcessVaultWithdrawal(
      #"",
      [],
      SharesDelete { proof: [], old_value: #"" },
      SharesInsert { proof: [] },
    ),
    Script(""),
    tx,
  )
}

test s8_vw_failed_without_intent_token_burnt() fail {
  let test_case =
    VaultWithdrawalTestCase {
      is_operation_key_signed: True,
      is_operator_key_signed: False,
      is_withdrawer_balance_increased: True,
      is_vault_balance_deducted: True,
      is_intent_token_burnt: False,
      has_other_account_input: False,
      has_other_account_output: False,
    }

  let tx = mock_vault_withdrawal_tx(test_case)

  ha.hydra_account.withdraw(
    mock_dex_order_book_token,
    ProcessVaultWithdrawal(
      #"",
      [],
      SharesDelete { proof: [], old_value: #"" },
      SharesInsert { proof: [] },
    ),
    Script(""),
    tx,
  )
}

test s8_vw_failed_with_other_account_input() fail {
  let test_case =
    VaultWithdrawalTestCase {
      is_operation_key_signed: True,
      is_operator_key_signed: False,
      is_withdrawer_balance_increased: True,
      is_vault_balance_deducted: True,
      is_intent_token_burnt: True,
      has_other_account_input: True,
      has_other_account_output: False,
    }

  let tx = mock_vault_withdrawal_tx(test_case)

  ha.hydra_account.withdraw(
    mock_dex_order_book_token,
    ProcessVaultWithdrawal(
      #"",
      [],
      SharesDelete { proof: [], old_value: #"" },
      SharesInsert { proof: [] },
    ),
    Script(""),
    tx,
  )
}

test s8_vw_failed_with_other_account_output() fail {
  let test_case =
    VaultWithdrawalTestCase {
      is_operation_key_signed: True,
      is_operator_key_signed: False,
      is_withdrawer_balance_increased: True,
      is_vault_balance_deducted: True,
      is_intent_token_burnt: True,
      has_other_account_input: False,
      has_other_account_output: True,
    }

  let tx = mock_vault_withdrawal_tx(test_case)

  ha.hydra_account.withdraw(
    mock_dex_order_book_token,
    ProcessVaultWithdrawal(
      #"",
      [],
      SharesDelete { proof: [], old_value: #"" },
      SharesInsert { proof: [] },
    ),
    Script(""),
    tx,
  )
}
// ========== TODO: Signature Tests ==========
// test s8_vw_success_with_operation_key_only() { ... }
// test s8_vw_success_with_operator_key_only() { ... }

// ========== TODO: Merkle Tests ==========
// test s8_vw_success_full_withdrawal_merkle_delete() { ... }
// test s8_vw_success_partial_withdrawal_merkle_update() { ... }
// test s8_vw_failed_invalid_merkle_root_transition() fail { ... }
// test s8_vw_failed_shares_mismatch_in_merkle() fail { ... }
// test s8_vw_failed_partial_withdrawal_exceeds_shares() fail { ... }

// ========== TODO: Price Verification Tests ==========
// test s8_vw_success_with_valid_price_signatures() { ... }
// test s8_vw_failed_invalid_price_signatures() fail { ... }

// ========== TODO: Fee Calculation Tests ==========
// test s8_vw_fee_calculated_when_profit() { ... }
// test s8_vw_no_fee_when_no_profit() { ... }
// test s8_vw_fee_rounds_up() { ... }
// test s8_vw_fee_shares_rounds_up() { ... }

// ========== TODO: Operator Fee Share Tests ==========
// test s8_vw_operator_fee_share_insert() { ... }
// test s8_vw_operator_fee_share_update() { ... }
// test s8_vw_no_operator_fee_when_no_profit() { ... }

// ========== TODO: Oracle Datum Update Tests ==========
// test s8_vw_failed_total_shares_not_updated() fail { ... }
// test s8_vw_failed_operator_shares_not_updated() fail { ... }
// test s8_vw_failed_total_deposited_not_updated() fail { ... }
// test s8_vw_failed_total_fee_collected_not_updated() fail { ... }
// test s8_vw_failed_other_fields_changed() fail { ... }

// ========== TODO: Value Transfer Tests ==========
// test s8_vw_value_transfer_matches_gross_minus_fee() { ... }
// test s8_vw_failed_value_mismatch() fail { ... }
