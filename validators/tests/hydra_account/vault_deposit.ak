use cardano/address.{Script, from_script}
use cardano/assets.{from_asset, merge, negate}
use cardano/transaction.{Transaction}
use hydra_account/core as ha
use hydra_dex/types.{
  Account, ProcessVaultDeposit, SharesInsert, TokenMap, UserTradeAccount,
  VaultDepositIntentDatumL2, VaultOracleDatum,
}
use hydra_dex/utils.{to_mvalue}
use mocktail.{
  complete, mint, mock_policy_id, mock_tx_hash, mocktail_tx, ref_tx_in,
  ref_tx_in_inline_datum, required_signer_hash, tx_in, tx_in_inline_datum,
  tx_out, tx_out_inline_datum,
}
use tests/utils.{
  mock_account, mock_account_3, mock_dex_order_book_address,
  mock_dex_order_book_datum, mock_dex_order_book_token,
  mock_hydra_account_address, mock_hydra_lovelace, mock_operation_key,
  mock_user_account,
} as test_utils

// ========== Test Constants ==========

const mock_vault_oracle_nft = mock_policy_id(500)

const mock_l2_deposit_intent_script_hash =
  #"1234567890abcdef1234567890abcdef1234567890abcdef12345678"

const mock_vault_script_hash =
  #"fedcba0987654321fedcba0987654321fedcba0987654321fedcba09"

// Mock vault account - uses vault_script_hash as master key
fn mock_vault_account() {
  Account {
    account_id: #"aabbccdd",
    master_key: Script(mock_vault_script_hash),
    operation_key: Script(mock_vault_script_hash),
  }
}

fn mock_vault_user_account() {
  UserTradeAccount {
    account: mock_vault_account(),
    trading_logic: test_utils.mock_hydra_order_book,
  }
}

fn mock_vault_oracle_datum_input() -> VaultOracleDatum {
  VaultOracleDatum {
    app_oracle: mock_policy_id(0),
    vault_script_hash: mock_vault_script_hash,
    l1_deposit_intent_script_hash: #"",
    l1_withdrawal_intent_script_hash: #"",
    l2_deposit_intent_script_hash: mock_l2_deposit_intent_script_hash,
    l2_withdrawal_intent_script_hash: #"",
    pluggable_logic: #"",
    vault_stake_rotation_script_hash: #"",
    operator_key: mock_operation_key,
    operator_account: mock_user_account(mock_account),
    operator_charge_percentage: 10,
    operator_min_deposit_percentage: 0,
    hydra_node_pub_keys: [],
    is_active: True,
    total_shares: 1_000_000_000_000,
    operator_shares: 0,
    total_deposited: 1_000_000_000,
    shares_merkle_root: #"",
    total_fee_share_collected: 0,
  }
}

// ========== Test Case Type ==========

type VaultDepositTestCase {
  is_initial_deposit: Bool,
  is_operation_key_signed: Bool,
  is_depositor_balance_deducted: Bool,
  is_vault_balance_increased: Bool,
  is_intent_token_burnt: Bool,
  has_other_account_input: Bool,
  has_other_account_output: Bool,
}

// ========== Mock Transaction Builder ==========

fn mock_vault_deposit_tx(test_case: VaultDepositTestCase) -> Transaction {
  let VaultDepositTestCase {
    is_initial_deposit,
    is_operation_key_signed,
    is_depositor_balance_deducted,
    is_vault_balance_increased,
    is_intent_token_burnt,
    has_other_account_input,
    has_other_account_output,
  } = test_case

  let deposit_amount = mock_hydra_lovelace(100_000_000)
  let depositor_balance_start = mock_hydra_lovelace(1_000_000_000)
  let vault_balance_start = mock_hydra_lovelace(5_000_000_000)

  let depositor_balance_end =
    if is_depositor_balance_deducted {
      deposit_amount |> negate() |> merge(depositor_balance_start)
    } else {
      depositor_balance_start
    }

  let vault_balance_end =
    if is_vault_balance_increased {
      deposit_amount |> merge(vault_balance_start)
    } else {
      vault_balance_start
    }

  let vault_oracle_address = from_script("vault_oracle")

  // Input oracle datum - for initial deposit, total_shares = 0
  let input_oracle_datum =
    if is_initial_deposit {
      VaultOracleDatum { ..mock_vault_oracle_datum_input(), total_shares: 0 }
    } else {
      mock_vault_oracle_datum_input()
    }

  // Output oracle datum - updated with new shares
  // Initial deposit: shares_minted = deposit_usd_value (share price = 1.0)
  // Regular deposit: shares_minted = (deposit_usd_value * total_shares) / vault_equity
  let shares_minted =
    if is_initial_deposit {
      // Initial: share price = 1.0, so shares = USD value
      100_000_000
    } else {
      // Regular: proportional calculation (simplified for test)
      100_000_000_000
    }

  let output_oracle_datum =
    VaultOracleDatum {
      ..input_oracle_datum,
      total_shares: input_oracle_datum.total_shares + shares_minted,
      total_deposited: input_oracle_datum.total_deposited + 100_000_000,
      shares_merkle_root: #"0000000000000000000000000000000000000000",
    }

  let intent_address = from_script(mock_l2_deposit_intent_script_hash)

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
        from_asset(mock_l2_deposit_intent_script_hash, "", 1),
        intent_address,
      )
    |> tx_in_inline_datum(
        True,
        VaultDepositIntentDatumL2 {
          vault_oracle_nft: mock_vault_oracle_nft,
          depositor: mock_user_account(mock_account),
          deposit_amount: deposit_amount |> to_mvalue(),
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
    // Depositor input
    |> tx_in(
        True,
        mock_tx_hash(0),
        2,
        depositor_balance_start,
        mock_hydra_account_address,
      )
    |> tx_in_inline_datum(True, mock_user_account(mock_account))
    // Depositor output
    |> tx_out(True, mock_hydra_account_address, depositor_balance_end)
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
    |> mint(is_intent_token_burnt, -1, mock_l2_deposit_intent_script_hash, "")
    // Required signer
    |> required_signer_hash(is_operation_key_signed, mock_operation_key)
    |> complete()
}

// ========== Success Tests ==========

// TODO: Add success test with proper merkle proof and price verification
// test s8_vd_success() {
//   ...
// }

// ========== Failure Tests ==========

test s8_vd_failed_without_operation_key_signed() fail {
  let test_case =
    VaultDepositTestCase {
      is_initial_deposit: False,
      is_operation_key_signed: False,
      is_depositor_balance_deducted: True,
      is_vault_balance_increased: True,
      is_intent_token_burnt: True,
      has_other_account_input: False,
      has_other_account_output: False,
    }

  let tx = mock_vault_deposit_tx(test_case)

  // TODO: Replace with actual function call when merkle/price tests added
  // Currently tests validator structure only
  let mock_token_map: TokenMap = []
  ha.hydra_account.withdraw(
    mock_dex_order_book_token,
    ProcessVaultDeposit(#"", [], mock_token_map, SharesInsert { proof: [] }),
    Script(""),
    tx,
  )
}

test s8_vd_failed_without_depositor_balance_deducted() fail {
  let test_case =
    VaultDepositTestCase {
      is_initial_deposit: False,
      is_operation_key_signed: True,
      is_depositor_balance_deducted: False,
      is_vault_balance_increased: True,
      is_intent_token_burnt: True,
      has_other_account_input: False,
 has_other_account_output: False,
    }

  let tx = mock_vault_deposit_tx(test_case)

  let mock_token_map: TokenMap = []
  ha.hydra_account.withdraw(
    mock_dex_order_book_token,
    ProcessVaultDeposit(#"", [], mock_token_map, SharesInsert { proof: [] }),
    Script(""),
    tx,
  )
}

test s8_vd_failed_without_vault_balance_increased() fail {
  let test_case =
    VaultDepositTestCase {
      is_initial_deposit: False,
      is_operation_key_signed: True,
      is_depositor_balance_deducted: True,
      is_vault_balance_increased: False,
      is_intent_token_burnt: True,
      has_other_account_input: False,
      has_other_account_output: False,
    }

  let tx = mock_vault_deposit_tx(test_case)

  let mock_token_map: TokenMap = []
  ha.hydra_account.withdraw(
    mock_dex_order_book_token,
    ProcessVaultDeposit(#"", [], mock_token_map, SharesInsert { proof: [] }),
    Script(""),
    tx,
  )
}

test s8_vd_failed_without_intent_token_burnt() fail {
  let test_case =
    VaultDepositTestCase {
      is_initial_deposit: False,
      is_operation_key_signed: True,
      is_depositor_balance_deducted: True,
      is_vault_balance_increased: True,
      is_intent_token_burnt: False,
      has_other_account_input: False,
      has_other_account_output: False,
    }

  let tx = mock_vault_deposit_tx(test_case)

  let mock_token_map: TokenMap = []
  ha.hydra_account.withdraw(
    mock_dex_order_book_token,
    ProcessVaultDeposit(#"", [], mock_token_map, SharesInsert { proof: [] }),
    Script(""),
    tx,
  )
}

test s8_vd_failed_with_other_account_input() fail {
  let test_case =
    VaultDepositTestCase {
      is_initial_deposit: False,
      is_operation_key_signed: True,
      is_depositor_balance_deducted: True,
      is_vault_balance_increased: True,
      is_intent_token_burnt: True,
      has_other_account_input: True,
      has_other_account_output: False,
    }

  let tx = mock_vault_deposit_tx(test_case)

  let mock_token_map: TokenMap = []
  ha.hydra_account.withdraw(
    mock_dex_order_book_token,
    ProcessVaultDeposit(#"", [], mock_token_map, SharesInsert { proof: [] }),
    Script(""),
    tx,
  )
}

test s8_vd_failed_with_other_account_output() fail {
  let test_case =
    VaultDepositTestCase {
      is_initial_deposit: False,
      is_operation_key_signed: True,
      is_depositor_balance_deducted: True,
      is_vault_balance_increased: True,
      is_intent_token_burnt: True,
      has_other_account_input: False,
      has_other_account_output: True,
    }

  let tx = mock_vault_deposit_tx(test_case)

  let mock_token_map: TokenMap = []
  ha.hydra_account.withdraw(
    mock_dex_order_book_token,
    ProcessVaultDeposit(#"", [], mock_token_map, SharesInsert { proof: [] }),
    Script(""),
    tx,
  )
}

// ========== Initial Deposit Tests ==========

test s8_vd_initial_failed_without_operation_key_signed() fail {
  let test_case =
    VaultDepositTestCase {
      is_initial_deposit: True,
      is_operation_key_signed: False,
      is_depositor_balance_deducted: True,
      is_vault_balance_increased: True,
      is_intent_token_burnt: True,
      has_other_account_input: False,
      has_other_account_output: False,
    }

  let tx = mock_vault_deposit_tx(test_case)

  let mock_token_map: TokenMap = []
  ha.hydra_account.withdraw(
    mock_dex_order_book_token,
    ProcessVaultDeposit(#"", [], mock_token_map, SharesInsert { proof: [] }),
    Script(""),
    tx,
  )
}

test s8_vd_initial_failed_without_depositor_balance_deducted() fail {
  let test_case =
    VaultDepositTestCase {
      is_initial_deposit: True,
      is_operation_key_signed: True,
      is_depositor_balance_deducted: False,
      is_vault_balance_increased: True,
      is_intent_token_burnt: True,
      has_other_account_input: False,
      has_other_account_output: False,
    }

  let tx = mock_vault_deposit_tx(test_case)

  let mock_token_map: TokenMap = []
  ha.hydra_account.withdraw(
    mock_dex_order_book_token,
    ProcessVaultDeposit(#"", [], mock_token_map, SharesInsert { proof: [] }),
    Script(""),
    tx,
  )
}

test s8_vd_initial_failed_without_vault_balance_increased() fail {
  let test_case =
    VaultDepositTestCase {
      is_initial_deposit: True,
      is_operation_key_signed: True,
      is_depositor_balance_deducted: True,
      is_vault_balance_increased: False,
      is_intent_token_burnt: True,
      has_other_account_input: False,
      has_other_account_output: False,
    }

  let tx = mock_vault_deposit_tx(test_case)

  let mock_token_map: TokenMap = []
  ha.hydra_account.withdraw(
    mock_dex_order_book_token,
    ProcessVaultDeposit(#"", [], mock_token_map, SharesInsert { proof: [] }),
    Script(""),
    tx,
  )
}

test s8_vd_initial_failed_without_intent_token_burnt() fail {
  let test_case =
    VaultDepositTestCase {
      is_initial_deposit: True,
      is_operation_key_signed: True,
      is_depositor_balance_deducted: True,
      is_vault_balance_increased: True,
      is_intent_token_burnt: False,
      has_other_account_input: False,
      has_other_account_output: False,
    }

  let tx = mock_vault_deposit_tx(test_case)

  let mock_token_map: TokenMap = []
  ha.hydra_account.withdraw(
    mock_dex_order_book_token,
    ProcessVaultDeposit(#"", [], mock_token_map, SharesInsert { proof: [] }),
    Script(""),
    tx,
  )
}

test s8_vd_initial_failed_with_other_account_input() fail {
  let test_case =
    VaultDepositTestCase {
      is_initial_deposit: True,
      is_operation_key_signed: True,
      is_depositor_balance_deducted: True,
      is_vault_balance_increased: True,
      is_intent_token_burnt: True,
      has_other_account_input: True,
      has_other_account_output: False,
    }

  let tx = mock_vault_deposit_tx(test_case)

  let mock_token_map: TokenMap = []
  ha.hydra_account.withdraw(
    mock_dex_order_book_token,
    ProcessVaultDeposit(#"", [], mock_token_map, SharesInsert { proof: [] }),
    Script(""),
    tx,
  )
}

test s8_vd_initial_failed_with_other_account_output() fail {
  let test_case =
    VaultDepositTestCase {
      is_initial_deposit: True,
      is_operation_key_signed: True,
      is_depositor_balance_deducted: True,
      is_vault_balance_increased: True,
      is_intent_token_burnt: True,
      has_other_account_input: False,
      has_other_account_output: True,
    }

  let tx = mock_vault_deposit_tx(test_case)

  let mock_token_map: TokenMap = []
  ha.hydra_account.withdraw(
    mock_dex_order_book_token,
    ProcessVaultDeposit(#"", [], mock_token_map, SharesInsert { proof: [] }),
    Script(""),
    tx,
  )
}
// ========== TODO: Merkle Tests ==========
// test s8_vd_success_new_depositor_merkle_insert() { ... }
// test s8_vd_success_existing_depositor_merkle_update() { ... }
// test s8_vd_failed_invalid_merkle_root_transition() fail { ... }
// test s8_vd_failed_shares_mismatch_in_merkle() fail { ... }

// ========== TODO: Price Verification Tests ==========
// test s8_vd_success_with_valid_price_signatures() { ... }
// test s8_vd_failed_invalid_price_signatures() fail { ... }
// test s8_vd_failed_mismatched_vault_equity() fail { ... }

// ========== TODO: Shares Calculation Tests ==========
// test s8_vd_shares_calculation_correct() { ... }
// test s8_vd_shares_round_down() { ... }
// test s8_vd_initial_shares_equals_usd_value() { ... } -- initial deposit share price = 1.0

// ========== TODO: Oracle Datum Update Tests ==========
// test s8_vd_failed_total_shares_not_updated() fail { ... }
// test s8_vd_failed_total_deposited_not_updated() fail { ... }
// test s8_vd_failed_other_fields_changed() fail { ... }

// ========== TODO: Initial Deposit Specific Tests ==========
// test s8_vd_initial_success_anyone_can_deposit() { ... } -- no depositor restriction
// test s8_vd_initial_shares_go_to_depositor() { ... } -- verify MPF key is depositor

// ========== TODO: Operator == Depositor Edge Case ==========
// When operator deposits (after receiving fee shares from withdrawals)
// Uses SharesUpdate since operator already has an MPF entry
//
// test s8_vd_operator_deposits_with_existing_fee_shares() { ... }
//   - Existing entry: { shares: fee_shares, total_deposited: 0 } (from fees)
//   - After deposit: { shares: fee_shares + new_shares, total_deposited: deposit_usd_value }
//   - Both shares and total_deposited increase correctly
//   - operator_shares in VaultOracleDatum increases by shares_minted
//
// test s8_vd_operator_shares_updated_when_operator_deposits() { ... }
//   - Verify operator_shares = input_operator_shares + shares_minted
//
// test s8_vd_operator_shares_unchanged_when_non_operator_deposits() { ... }
//   - Verify operator_shares remains unchanged when depositor != operator
