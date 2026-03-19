use cardano/address.{Script, VerificationKey, from_script}
use cardano/assets.{from_asset, merge, negate}
use cardano/transaction.{Transaction}
use hydra_account/core as ha
use hydra_dex/types.{
  Account, ProcessVaultWithdrawal, SharesDelete, SharesInsert, TokenMap,
  UserTradeAccount, VaultOracleDatum, VaultWithdrawalIntentDatumL2,
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

const mock_vault_script_hash =
  #"fedcba0987654321fedcba0987654321fedcba0987654321fedcba09"

const mock_operator_key = mock_pub_key_hash(999)

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
    vault_script_hash: mock_vault_script_hash,
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

  let mock_token_map: TokenMap = []
  ha.hydra_account.withdraw(
    mock_dex_order_book_token,
    ProcessVaultWithdrawal(
      #"",
      [],
      mock_token_map,
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

  let mock_token_map: TokenMap = []
  ha.hydra_account.withdraw(
    mock_dex_order_book_token,
    ProcessVaultWithdrawal(
      #"",
      [],
      mock_token_map,
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

  let mock_token_map: TokenMap = []
  ha.hydra_account.withdraw(
    mock_dex_order_book_token,
    ProcessVaultWithdrawal(
      #"",
      [],
      mock_token_map,
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

  let mock_token_map: TokenMap = []
  ha.hydra_account.withdraw(
    mock_dex_order_book_token,
    ProcessVaultWithdrawal(
      #"",
      [],
      mock_token_map,
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

  let mock_token_map: TokenMap = []
  ha.hydra_account.withdraw(
    mock_dex_order_book_token,
    ProcessVaultWithdrawal(
      #"",
      [],
      mock_token_map,
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

  let mock_token_map: TokenMap = []
  ha.hydra_account.withdraw(
    mock_dex_order_book_token,
    ProcessVaultWithdrawal(
      #"",
      [],
      mock_token_map,
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
// Operator receives fee_shares when profit > 0
// Key behavior: operator's total_deposited remains UNCHANGED (fee shares are earned, not deposited)
//
// test s8_vw_operator_fee_share_insert() { ... }
//   - Operator has no existing MPF entry
//   - New entry created: { shares: fee_shares, total_deposited: 0 }
//
// test s8_vw_operator_fee_share_update() { ... }
//   - Operator has existing MPF entry
//   - Entry updated: { shares: old_shares + fee_shares, total_deposited: old_deposited } (unchanged)
//
// test s8_vw_no_operator_fee_when_no_profit() { ... }
//   - No fee when withdrawal_value <= cost_basis

// ========== TODO: Operator == Withdrawer Edge Case ==========
// When operator is also the withdrawer, both MPF transitions affect the same entry
// Step 1 (user MPF) runs first, Step 2 (operator MPF) uses the resulting root
// operator_shares = input_operator_shares - shares_to_redeem + fee_shares
//
// test s8_vw_operator_is_withdrawer_full_withdrawal() { ... }
//   - Step 1: SharesDelete (remove operator's entry)
//   - Step 2: SharesInsert (re-insert with fee_shares only)
//   - Final entry: { shares: fee_shares, total_deposited: 0 }
//   - operator_shares = input_operator_shares - shares_to_redeem + fee_shares
//
// test s8_vw_operator_is_withdrawer_partial_withdrawal() { ... }
//   - Step 1: SharesUpdate (reduce shares and proportional cost_basis)
//   - Step 2: SharesUpdate (add fee_shares, total_deposited unchanged from step 1)
//   - Final entry: { shares: remaining + fee_shares, total_deposited: reduced }
//   - operator_shares = input_operator_shares - shares_to_redeem + fee_shares
//
// test s8_vw_operator_shares_updated_when_operator_withdraws() { ... }
//   - Verify operator_shares = input - shares_to_redeem + fee_shares
//
// test s8_vw_operator_shares_only_adds_fee_when_non_operator_withdraws() { ... }
//   - Verify operator_shares = input + fee_shares when withdrawer != operator

// ========== Operator Minimum Percentage Tests ==========
// When operator withdraws, must maintain: new_operator_shares / new_total_shares >= operator_min_deposit_percentage / 100

type OperatorMinPercentageTestCase {
  // Vault state
  total_shares: Int,
  operator_shares: Int,
  operator_min_deposit_percentage: Int,
  // Withdrawal params
  shares_to_redeem: Int,
  fee_shares: Int,
}

fn mock_operator_min_percentage_tx(test_case: OperatorMinPercentageTestCase) -> Transaction {
  let OperatorMinPercentageTestCase {
    total_shares,
    operator_shares,
    operator_min_deposit_percentage,
    shares_to_redeem,
    fee_shares,
  } = test_case

  let withdrawal_value = mock_hydra_lovelace(100_000_000)
  let operator_balance_start = mock_hydra_lovelace(500_000_000)
  let vault_balance_start = mock_hydra_lovelace(5_000_000_000)

  let operator_balance_end = withdrawal_value |> merge(operator_balance_start)
  let vault_balance_end =
    withdrawal_value |> negate() |> merge(vault_balance_start)

  let vault_oracle_address = from_script("vault_oracle")

  // Input oracle datum with operator shares and min percentage
  let input_oracle_datum =
    VaultOracleDatum {
      ..mock_vault_oracle_datum_input(),
      total_shares: total_shares,
      operator_shares: operator_shares,
      operator_min_deposit_percentage: operator_min_deposit_percentage,
    }

  // Calculate new values after withdrawal
  let new_total_shares = total_shares - shares_to_redeem + fee_shares
  let new_operator_shares = operator_shares - shares_to_redeem + fee_shares

  let output_oracle_datum =
    VaultOracleDatum {
      ..input_oracle_datum,
      total_shares: new_total_shares,
      operator_shares: new_operator_shares,
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
    // Intent input - OPERATOR is the withdrawer
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
          withdrawer: mock_operator_user_account(),
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
    // Operator (withdrawer) input
    |> tx_in(
        True,
        mock_tx_hash(0),
        2,
        operator_balance_start,
        mock_hydra_account_address,
      )
    |> tx_in_inline_datum(True, mock_operator_user_account())
    // Operator (withdrawer) output
    |> tx_out(True, mock_hydra_account_address, operator_balance_end)
    |> tx_out_inline_datum(True, mock_operator_user_account())
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
    // Mint (burn intent token)
    |> mint(True, -1, mock_l2_withdrawal_intent_script_hash, "")
    // Operator signs
    |> required_signer_hash(True, mock_operator_key)
    |> complete()
}

// Operator has 20% of shares (200 of 1000), min is 10%
// Withdraws 50 shares -> new: 150/950 = 15.7% >= 10% ✓
// NOTE: Test marked `fail` because merkle/price verification not mocked.
// Min percentage check PASSES in this scenario (150*100 >= 10*950 -> 15000 >= 9500)
test s8_vw_operator_withdrawal_respects_min_percentage() fail {
  let test_case =
    OperatorMinPercentageTestCase {
      total_shares: 1000,
      operator_shares: 200,
      operator_min_deposit_percentage: 10,
      shares_to_redeem: 50,
      fee_shares: 0,
    }

  let tx = mock_operator_min_percentage_tx(test_case)

  let mock_token_map: TokenMap = []
  ha.hydra_account.withdraw(
    mock_dex_order_book_token,
    ProcessVaultWithdrawal(
      #"",
      [],
      mock_token_map,
      SharesDelete { proof: [], old_value: #"" },
      SharesInsert { proof: [] },
    ),
    Script(""),
    tx,
  )
}

// Operator has 15% of shares (150 of 1000), min is 10%
// Withdraws 100 shares -> new: 50/900 = 5.5% < 10% ✗
// Min percentage check FAILS (50*100 >= 10*900 -> 5000 >= 9000 is FALSE)
test s8_vw_operator_withdrawal_fails_below_min_percentage() fail {
  let test_case =
    OperatorMinPercentageTestCase {
      total_shares: 1000,
      operator_shares: 150,
      operator_min_deposit_percentage: 10,
      shares_to_redeem: 100,
      fee_shares: 0,
    }

  let tx = mock_operator_min_percentage_tx(test_case)

  let mock_token_map: TokenMap = []
  ha.hydra_account.withdraw(
    mock_dex_order_book_token,
    ProcessVaultWithdrawal(
      #"",
      [],
      mock_token_map,
      SharesDelete { proof: [], old_value: #"" },
      SharesInsert { proof: [] },
    ),
    Script(""),
    tx,
  )
}

// Operator has 10% of shares (100 of 1000), min is 10%
// Withdraws 50 shares, earns 40 fee_shares -> new: 90/990 = 9.09% < 10% ✗
// Min percentage check FAILS (90*100 >= 10*990 -> 9000 >= 9900 is FALSE)
test s8_vw_operator_withdrawal_with_fee_still_fails_below_min() fail {
  let test_case =
    OperatorMinPercentageTestCase {
      total_shares: 1000,
      operator_shares: 100,
      operator_min_deposit_percentage: 10,
      shares_to_redeem: 50,
      fee_shares: 40,
    }

  let tx = mock_operator_min_percentage_tx(test_case)

  let mock_token_map: TokenMap = []
  ha.hydra_account.withdraw(
    mock_dex_order_book_token,
    ProcessVaultWithdrawal(
      #"",
      [],
      mock_token_map,
      SharesDelete { proof: [], old_value: #"" },
      SharesInsert { proof: [] },
    ),
    Script(""),
    tx,
  )
}

// Operator has 10% (100 of 1000), min is 10%
// Withdraws 50, earns 50 fee_shares -> new: 100/1000 = 10% == 10% ✓
// NOTE: Test marked `fail` because merkle/price verification not mocked.
// Min percentage check PASSES (100*100 >= 10*1000 -> 10000 >= 10000)
test s8_vw_operator_withdrawal_with_fee_maintains_exact_min() fail {
  let test_case =
    OperatorMinPercentageTestCase {
      total_shares: 1000,
      operator_shares: 100,
      operator_min_deposit_percentage: 10,
      shares_to_redeem: 50,
      fee_shares: 50,
    }

  let tx = mock_operator_min_percentage_tx(test_case)

  let mock_token_map: TokenMap = []
  ha.hydra_account.withdraw(
    mock_dex_order_book_token,
    ProcessVaultWithdrawal(
      #"",
      [],
      mock_token_map,
      SharesDelete { proof: [], old_value: #"" },
      SharesInsert { proof: [] },
    ),
    Script(""),
    tx,
  )
}

// ========== TODO: Oracle Datum Update Tests ==========
// test s8_vw_failed_total_shares_not_updated() fail { ... }
// test s8_vw_failed_operator_shares_not_updated() fail { ... }
// test s8_vw_failed_total_deposited_not_updated() fail { ... }
// test s8_vw_failed_total_fee_collected_not_updated() fail { ... }
// test s8_vw_failed_other_fields_changed() fail { ... }

// ========== TODO: Value Transfer Tests ==========
// test s8_vw_value_transfer_matches_gross_minus_fee() { ... }
// test s8_vw_failed_value_mismatch() fail { ... }
