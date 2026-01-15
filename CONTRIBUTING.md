# Contributing to DeltaDeFi Hydra DEX Scripts

Thank you for your interest in contributing to the DeltaDeFi Hydra DEX smart contracts! This document provides guidelines and instructions for contributing to this Aiken-based Cardano smart contract project.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Development Workflow](#development-workflow)
- [Code Standards](#code-standards)
- [Testing](#testing)
- [Submitting Changes](#submitting-changes)
- [Project Structure](#project-structure)

## Code of Conduct

By participating in this project, you agree to maintain a respectful and collaborative environment. We welcome contributions from developers of all skill levels.

## Getting Started

### Prerequisites

- **Aiken** v1.1.16 or later ([Installation guide](https://aiken-lang.org/installation-instructions))
- **Cardano Node** (optional, for local testing on devnet/testnet)
- **Git**
- Basic understanding of:
  - Functional programming concepts
  - Cardano blockchain and UTxO model
  - Plutus smart contracts
  - Hydra Layer 2 protocol (for advanced contributions)

### Recommended Tools

- **VS Code** with Aiken extension for syntax highlighting
- **Cardano CLI** for transaction building and testing
- **Hydra Node** for Layer 2 testing (advanced)

## Development Setup

1. **Clone the repository**:

   ```bash
   git clone https://github.com/deltadefi-protocol/deltadefi-scripts.git
   cd deltadefi-scripts
   ```

2. **Install Aiken** (if not already installed):

   ```bash
   # On macOS/Linux
   curl --proto '=https' --tlsv1.2 -LsSf https://install.aiken-lang.org | sh

   # Verify installation
   aiken --version  # Should show v1.1.16 or later
   ```

3. **Build the project**:

   ```bash
   aiken build
   ```

   This will compile all validators and generate Plutus scripts in `plutus.json`.

4. **Run tests**:

   ```bash
   aiken check
   ```

   This runs all unit tests and integration tests defined in the `validators/tests/` directory.

## Development Workflow

### Making Changes

1. **Create a feature branch**:

   ```bash
   git checkout -b feature/your-feature-name
   # or
   git checkout -b fix/your-bug-fix
   ```

2. **Make your changes** following the [Code Standards](#code-standards)

3. **Run tests frequently**:

   ```bash
   aiken check
   ```

4. **Build to verify compilation**:

   ```bash
   aiken build
   ```

5. **Update documentation**:
   - Add/update specification files in `spec/` directory
   - Update QA checklist in `QA.md` if adding new validators or tests
   - Update README.md if changing setup or usage

6. **Commit your changes** using [conventional commits](#commit-message-format)

### Development Tips

- **Incremental Testing**: Test individual validators with `aiken check -m <module_name>`
- **Type-Driven Development**: Start by defining types in `lib/hydra_dex/types.ak`
- **Specification First**: Document expected behavior in `spec/` before implementing
- **Use Traces**: Add `trace` statements for debugging test failures
- **Pattern Matching**: Leverage Aiken's exhaustive pattern matching to ensure all cases are covered

## Code Standards

### Aiken Style Guide

Follow these conventions for consistency with the existing codebase:

#### Naming Conventions

- **Types and Type Constructors**: `PascalCase`
  ```aiken
  pub type AppOracleDatum {
    oracle_nft: AssetClass,
    ...
  }
  ```

- **Functions**: `snake_case`
  ```aiken
  pub fn get_app_oracle_datum(...) -> AppOracleDatum { ... }
  ```

- **Variables and Parameters**: `snake_case`
  ```aiken
  let account_balance = ...
  ```

- **Constants**: `PascalCase` for type variants
  ```aiken
  pub type AccountOperationRedeemer {
    WithdrawAda
    WithdrawAssetDeposit
    ...
  }
  ```

#### Formatting

- **Indentation**: 2 spaces (enforced by `.editorconfig`)
- **Line Endings**: LF (Unix-style)
- **Encoding**: UTF-8
- **Import Organization**: Group imports by category
  ```aiken
  // Standard library
  use aiken/collection/list
  use aiken/crypto

  // Cardano modules
  use cardano/transaction.{Input, Output}

  // Project modules
  use hydra_dex/types.{AppOracleDatum}
  use hydra_dex/utils
  ```

#### Code Organization

```aiken
// 1. Imports
use aiken/collection/list
use cardano/transaction

// 2. Type definitions
pub type MyDatum {
  field1: Int,
  field2: ByteArray,
}

// 3. Public functions
pub fn my_public_function(...) -> Bool {
  ...
}

// 4. Private/helper functions
fn my_helper_function(...) -> Bool {
  ...
}

// 5. Validators (in validator files)
validator my_validator(...) {
  spend(...) {
    ...
  }
}
```

#### Best Practices

**Error Handling:**
```aiken
// Use expect for safe unwrapping with clear error messages
expect Some(value) = list.head(my_list)

// Use when/is for explicit pattern matching
when result is {
  Some(val) -> val,
  None -> fail @"Expected value not found"
}
```

**Validation Logic:**
```aiken
// Use &&, ||, ! for boolean logic
let valid_signature = verify_signature(...) && check_deadline(...)

// Use list comprehensions for filtering
let valid_outputs =
  list.filter(outputs, fn(out) { out.value > threshold })
```

**Performance:**
- Minimize recursive calls in validators (gas limits)
- Use `list.foldl` instead of explicit recursion when possible
- Avoid redundant computations in pattern matching
- Use `expect` instead of nested `when/is` for known structures

**Documentation:**
```aiken
/// Calculate the settlement amount for a filled order.
///
/// This function computes the asset quantities exchanged based on
/// the order price and quantity filled.
///
/// ## Arguments
/// - `order`: The order being filled
/// - `fill_qty`: Quantity being filled in this transaction
///
/// ## Returns
/// Tuple of (quote_amount, base_amount)
pub fn calculate_settlement(order: Order, fill_qty: Int) -> (Int, Int) {
  ...
}
```

### Project-Specific Conventions

**Utility Functions** (in `lib/hydra_dex/`):
- Prefix account utilities with `au_`
- Prefix order utilities with `ou_`
- Prefix Hydra tree utilities with `htu_`
- Keep utilities pure and side-effect free

**Validator Scripts** (in `validators/`):
- One validator per file (except related mint/spend pairs)
- Name files with numeric prefix matching layer number: `0_app_oracle/`, `1_account_operation/`
- Redeemer types must be exhaustive (cover all operations)

**Test Files** (in `validators/tests/`):
- Mirror the structure of validators directory
- Name tests descriptively: `test_withdraw_ada_success`, `test_invalid_signature_fails`
- Group related tests using test modules
- Include both positive (valid) and negative (should fail) test cases

## Testing

### Test Categories

Our QA process includes multiple test types (see `QA.md` for full checklist):

1. **UT (Unit Tests)**: Test individual utility functions and simple validator logic
2. **SC (Specification Checking)**: Ensure code matches documented specifications
3. **IT (Integration Tests)**: Test complete transaction workflows across multiple validators
4. **PBT (Property-Based Tests)**: Test invariants with random inputs (limited coverage currently)
5. **E2E (End-to-End Tests)**: Full protocol testing with Hydra nodes (planned)

### Running Tests

```bash
# Run all tests
aiken check

# Run tests for specific module
aiken check -m validators/tests/app_oracle

# Run tests with verbose output
aiken check -v

# Run specific test by name pattern
aiken check -m validators/tests/integration_tests/it_withdraw
```

### Writing Tests

**Unit Test Example** (`validators/tests/account_utils_test.ak`):

```aiken
use aiken/collection/list
use hydra_dex/account_utils.{au_ta}
use hydra_dex/types.{TradeAuth}

test test_au_ta_valid_single_trade() {
  let trades = [
    TradeAuth {
      account: "addr1...",
      asset_a: ("", ""),
      asset_b: ("policy1", "token1"),
      qty_a: 100,
      qty_b: 50,
    }
  ]

  au_ta(trades, "addr1...")
}

test test_au_ta_invalid_different_account() fail {
  let trades = [
    TradeAuth {
      account: "addr2...",
      asset_a: ("", ""),
      asset_b: ("policy1", "token1"),
      qty_a: 100,
      qty_b: 50,
    }
  ]

  au_ta(trades, "addr1...")
}
```

**Integration Test Example** (`validators/tests/integration_tests/it_withdraw.ak`):

```aiken
use aiken/crypto.{Script}
use cardano/transaction.{Transaction, Input, Output}
use hydra_dex/types.{DexAccountBalanceDatum, AccountOperationRedeemer}

test test_withdraw_ada_complete_flow() {
  // 1. Setup: Create initial state
  let oracle_utxo = ...
  let vault_utxo = ...
  let account_balance_utxo = ...

  // 2. Build transaction
  let tx = Transaction {
    inputs: [account_balance_utxo_input, vault_input],
    outputs: [updated_account_balance, withdrawal_output],
    ...
  }

  // 3. Validate with all relevant validators
  let account_balance_valid = s5_spend.spend(
    datum,
    redeemer,
    account_balance_utxo_input,
    tx
  )

  let vault_valid = s2_spend.spend(
    vault_datum,
    vault_redeemer,
    vault_input,
    tx
  )

  // 4. Assert both validators pass
  account_balance_valid && vault_valid
}
```

### Test Coverage Requirements

Before submitting a PR:

- [ ] All new validators must have unit tests (`UT` column in QA.md)
- [ ] New validators must have specification documentation (`SC` in QA.md)
- [ ] Integration tests for new transaction workflows (`IT` in QA.md)
- [ ] Update QA.md checklist with new test coverage

## Submitting Changes

### Commit Message Format

We follow [Conventional Commits](https://www.conventionalcommits.org/) specification:

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types**:

- `feat`: New validator, feature, or capability
- `fix`: Bug fix in existing validator logic
- `docs`: Documentation updates (specs, README, comments)
- `test`: Adding or updating tests
- `refactor`: Code refactoring without changing functionality
- `perf`: Performance improvements (gas optimization)
- `chore`: Dependency updates, build changes

**Scopes** (use validator layer numbers):

- `s0`, `s1`, `s2`, ..., `s9`: Specific validator layer
- `lib`: Changes to shared libraries
- `types`: Type definition changes
- `utils`: Utility function changes
- `test`: Test infrastructure
- `build`: Build system changes

**Examples**:

```
feat(s5): add support for multi-asset account balances

Extend DexAccountBalance validator to handle multiple asset types
in a single account using a map structure.

Closes #42
```

```
fix(s9): prevent order double-spend in fill operation

Add check to ensure order NFT is consumed when partially filled.
Previously allowed reusing same order in multiple transactions.
```

```
perf(lib): optimize merkle proof validation

Reduce script size by 15% through more efficient proof checking.
Saves ~50 execution units per transaction.
```

```
test(it): add integration test for emergency withdrawal

Cover complete emergency request workflow from creation to execution.
```

### Pull Request Process

1. **Update documentation**:
   - Add/update specifications in `spec/` directory
   - Update `QA.md` checklist with test coverage
   - Update `README.md` if adding new setup steps or user actions

2. **Ensure all tests pass**:
   ```bash
   aiken check
   aiken build  # Verify compilation succeeds
   ```

3. **Create a Pull Request** with:
   - Clear title following commit message format
   - Description of changes and rationale
   - Link to related issues
   - Checklist of validator changes
   - Gas/execution cost impact (if applicable)

4. **Address review comments** and update your PR

5. **Squash commits** if requested before merging

### PR Checklist

Before submitting your PR, ensure:

- [ ] Code follows Aiken style guide
- [ ] All new validators have unit tests
- [ ] Integration tests added for new transaction flows
- [ ] Specification documentation updated in `spec/`
- [ ] QA.md checklist updated
- [ ] All tests pass (`aiken check`)
- [ ] Project builds successfully (`aiken build`)
- [ ] Commit messages follow conventional commits format
- [ ] No debug traces or commented-out code in final version
- [ ] Gas optimization considered (if applicable)

## Project Structure

```
deltadefi-scripts/
├── lib/                          # Shared utility library
│   └── hydra_dex/               # Core domain types and utilities
│       ├── types.ak             # Type definitions for all validators
│       ├── utils.ak             # General helper functions
│       ├── account_utils.ak      # Account operation utilities
│       ├── order_utils.ak        # Order processing utilities
│       ├── hydra_tree_utils.ak   # Merkle tree operations
│       └── hydra_commit_utils.ak # Hydra state commit operations
│
├── validators/                   # Smart contract validators (9 layers)
│   ├── 0_app_oracle/            # Layer 0: Static configuration oracle
│   │   ├── oracle_nft.ak        # NFT minting for oracle
│   │   ├── mint.ak              # Oracle NFT mint policy
│   │   └── spend.ak             # Oracle spend validator
│   │
│   ├── 1_account_operation/      # Layer 1: Withdrawal operations
│   │   ├── wad.ak               # Withdraw ADA
│   │   ├── waw.ak               # Withdraw asset (deposit)
│   │   ├── whc.ak               # Withdraw (cancel order)
│   │   ├── who.ak               # Withdraw (order settlement)
│   │   ├── whit.ak              # Withdraw (internal transfer)
│   │   ├── whw.ak               # Withdraw (withdrawal request)
│   │   └── whcw.ak              # Withdraw (cancel withdrawal)
│   │
│   ├── 2_app_vault/              # Layer 2: Main asset custody
│   │   └── spend.ak             # Vault spend validator
│   │
│   ├── 3_app_deposit_request/    # Layer 3: Deposit batching
│   │   ├── mint.ak              # Deposit request token minting
│   │   └── spend.ak             # Deposit processing
│   │
│   ├── 4_emergency_request/      # Layer 4: Emergency operations
│   │   ├── cancel_mint.ak       # Cancel request tokens
│   │   ├── cancel_spend.ak      # Process cancellation
│   │   ├── withdraw_mint.ak     # Emergency withdrawal tokens
│   │   └── withdraw_spend.ak    # Emergency withdrawal execution
│   │
│   ├── 5_dex_account_balance/    # Layer 5: L1 account balance merkle tree
│   │   ├── mint.ak              # Account balance token minting
│   │   └── spend.ak             # Balance update operations
│   │
│   ├── 6_dex_order_book/         # Layer 6: L1 order book merkle tree
│   │   ├── spend.ak             # Order book root updates
│   │   ├── wco.ak               # Cancel order
│   │   ├── wso.ak               # Settle order
│   │   └── wec.ak               # Emergency cancel
│   │
│   ├── 7_hydra_user_intent/      # Layer 7: L2 user intent tokens
│   │   ├── mint.ak              # User intent minting
│   │   └── spend.ak             # Intent processing
│   │
│   ├── 8_hydra_account_balance/  # Layer 8: L2 individual account balances
│   │   ├── mint.ak              # Balance token minting
│   │   └── spend.ak             # Balance updates in Hydra
│   │
│   └── 9_hydra_order_book/       # Layer 9: L2 individual orders
│       ├── mint.ak              # Order token minting
│       ├── spend.ak             # Order spend validator
│       ├── wpo.ak               # Place order
│       ├── wco.ak               # Cancel order
│       ├── wfo.ak               # Fill order
│       └── wrev.ak              # Release extra value
│
├── validators/tests/             # Test suite
│   ├── app_oracle/              # Layer 0 tests
│   ├── account_operation/        # Layer 1 tests
│   ├── app_vault/                # Layer 2 tests
│   ├── ...                       # Layers 3-9 tests
│   └── integration_tests/        # Cross-validator workflow tests
│       ├── it_withdraw.ak       # Withdrawal integration test
│       ├── it_process_deposit.ak # Deposit flow test
│       └── ...                   # Other integration tests
│
├── spec/                         # Specification documentation
│   ├── _scripts.md              # Overview and dependencies
│   ├── 0_app_oracle/            # Oracle specifications
│   ├── 1_account_operation/      # Account operation specs
│   └── ...                       # Specs for all 9 layers
│
├── build/                        # Compiled artifacts (generated)
│   └── packages/                 # Dependencies and Plutus output
│
├── aiken.toml                   # Project configuration
├── aiken.lock                   # Dependency lock file
├── plutus.json                  # Compiled Plutus scripts (generated)
├── README.md                    # Project overview
├── CONTRIBUTING.md              # This file
├── QA.md                        # Quality assurance checklist
├── LICENSE                      # Apache 2.0 license
└── .editorconfig               # Editor configuration
```

### Architecture Overview

The Hydra DEX is built as a **9-layer modular system**:

| Layer | Name | Purpose |
|-------|------|---------|
| 0 | AppOracle | Static configuration and constants |
| 1 | AccountOperation | Withdrawal authorization scripts |
| 2 | AppVault | Main asset custody (treasury) |
| 3 | AppDepositRequest | Batch incoming deposits |
| 4 | EmergencyRequest | Risk management and cancellations |
| 5 | DexAccountBalance | L1 merkle tree of all account balances |
| 6 | DexOrderBook | L1 merkle tree of all limit orders |
| 7 | HydraUserIntent | L2 user action intents (trades, transfers) |
| 8 | HydraAccountBalance | L2 individual account balance UTxOs |
| 9 | HydraOrderBook | L2 individual limit order UTxOs |

**Key Concepts:**

- **Dual State Representation**: Layer 1 (L1) uses merkle trees for compact state commitments, while Layer 2 (L2) expands state into individual UTxOs for fast processing within Hydra heads
- **Token-Based Validation**: Most validators use paired mint/spend scripts where tokens represent authorization or state ownership
- **Merkle Patricia Forestry**: Uses `aiken-lang/merkle-patricia-forestry` library for efficient state proofs
- **Hydra Integration**: Designed to work with Cardano Hydra protocol for Layer 2 scaling

## Additional Resources

### Aiken Documentation
- [Aiken Language Tour](https://aiken-lang.org/language-tour/primitive-types)
- [Aiken Standard Library](https://aiken-lang.github.io/stdlib/)
- [Aiken Examples](https://github.com/aiken-lang/aiken/tree/main/examples)

### Cardano Resources
- [Cardano Documentation](https://docs.cardano.org/)
- [Plutus Documentation](https://plutus.readthedocs.io/)
- [UTxO Model Explained](https://docs.cardano.org/learn/eutxo-explainer)

### Hydra Protocol
- [Hydra Head Protocol](https://hydra.family/head-protocol/)
- [Hydra Specification](https://hydra.family/head-protocol/core-concepts/)
- [Cardano Scaling](https://github.com/cardano-scaling/hydra)

### Testing
- [Aiken Testing Guide](https://aiken-lang.org/fundamentals/testing)
- [Property-Based Testing Concepts](https://hypothesis.works/articles/what-is-property-based-testing/)

### Merkle Trees
- [Merkle Patricia Forestry Library](https://github.com/aiken-lang/merkle-patricia-forestry)
- [Merkle Trees in Blockchain](https://ethereum.org/en/developers/docs/data-structures-and-encoding/patricia-merkle-trie/)

## Getting Help

- **Issues**: Check [existing issues](https://github.com/deltadefi-protocol/deltadefi-scripts/issues) or create a new one
- **Discussions**: Join conversations in [GitHub Discussions](https://github.com/deltadefi-protocol/deltadefi-scripts/discussions)
- **Documentation**: Refer to specifications in `spec/` and inline code comments
- **Aiken Discord**: Join the [Aiken community](https://discord.gg/Vc3x8N9nz2) for language-specific questions

## License

By contributing to DeltaDeFi Hydra DEX Scripts, you agree that your contributions will be licensed under the Apache License 2.0.

---

Thank you for contributing to the future of decentralized finance on Cardano!
