use aiken/crypto.{ScriptHash, VerificationKeyHash}
use aiken/merkle_patricia_forestry.{Proof}
use cardano/address.{Address, Credential}
use cardano/assets.{AssetName, PolicyId}
use cardano/transaction.{OutputReference}

// Common

pub type Tree {
  TreeBranch { nibble: ByteArray, nodes: List<Pair<Int, Tree>> }
  TreeLeaf { path: ByteArray, key: ByteArray, value: ByteArray }
}

pub type MPFProof {
  MPFInsert { proof: Proof }
  MPFUpdate { from: ByteArray, to: ByteArray, to_proof: Proof }
  MPFDelete { proof: Proof }
}

pub type TreeOrProofs {
  FullTree { tree: Tree }
  Proofs { proofs: List<MPFProof> }
}

pub type TokenMap =
  Pairs<ByteArray, (PolicyId, AssetName)>

pub type TreeOrProofsWithTokenMap {
  proof: TreeOrProofs,
  token_map: TokenMap,
}

// Mint Redeemer

pub type MintPolarity {
  RMint
  RBurn
}

pub type UserAccount {
  UserTradeAccount { account: Account, trading_logic: ScriptHash }
  UserFundingAccount { account: Account, trading_logic: ScriptHash }
  UserMobileAccount { account: Account, trading_logic: ScriptHash }
}

pub type Account {
  account_id: ByteArray,
  master_key: Credential,
  operation_key: Credential,
}

// 0 - AppOracle

pub type WithdrawalScriptHashes {
  app_deposit: ScriptHash,
  app_withdrawal: ScriptHash,
  emergency_cancel_order: ScriptHash,
}

pub type AppOracleDatum {
  operation_key: VerificationKeyHash,
  stop_key: VerificationKeyHash,
  community_stop_keys: List<VerificationKeyHash>,
  oracle_nft: PolicyId,
  oracle_address: Address,
  app_vault_address: Address,
  app_deposit_request_token: PolicyId,
  app_deposit_request_address: Address,
  dex_account_balance_token: PolicyId,
  dex_account_balance_address: Address,
  dex_order_book_token: PolicyId,
  dex_order_book_address: Address,
  emergency_cancel_order_request_token: PolicyId,
  emergency_cancel_order_request_address: Address,
  emergency_withdrawal_request_token: PolicyId,
  emergency_withdrawal_request_address: Address,
  all_withdrawal_script_hashes: WithdrawalScriptHashes,
  hydra_info: HydraInfo,
}

pub type HydraInfo {
  hydra_signers: List<VerificationKeyHash>,
}

pub type AppOracleRedeemer {
  DexRotateKey { new_operation_key: ByteArray, new_stop_key: ByteArray }
  StopDex
  RotateHydraInfo { new_hydra_info: HydraInfo }
  RotateCommunityStopKeys { new_community_stop_keys: List<VerificationKeyHash> }
}

// 1 - AccountOperation

pub type ProcessAppDeposit {
  mpf_action: MPFProof,
}

pub type ProcessAppWithdrawalRedeemer {
  ProcessAppWithdrawal {
    account: UserAccount,
    amount: MValue,
    mpf_action: MPFProof,
  }
  CommunityStop
}

// 3 - AppDepositRequest

pub type AppDepositRequestDatum {
  account: UserAccount,
  amount: MValue,
}

pub type AppDepositRequestRedeemer {
  AppDepositRequestTransferAccountBalance
  AppDepositRequestEmergencyWithdrawal
  AppDepositRequestSpamPreventionWithdraw
}

// 4 - EmergencyRequest

pub type EmergencyWithdrawalRequestDatum {
  account: UserAccount,
  amount: MValue,
  timestamp: Int,
}

pub type EmergencyWithdrawalRequestRedeemer {
  EmergencyRequestProcessEmergencyAction
  EmergencyRequestSpamPreventionWithdraw
  EmergencyRequestExpiredWithdraw
}

pub type EmergencyCancelRedeemer {
  account: UserAccount,
  order: MerklizedOrderDatum,
  mpf_action: MPFProof,
}

pub type EmergencyCancelRequestRedeemer {
  EmergencyRequestProcessCancel
  EmergencyRequestSpamPreventionCancel
  EmergencyRequestExpiredCancel
}

pub type EmergencyCancelRequestDatum {
  account: UserAccount,
  order_id: ByteArray,
  timestamp: Int,
}

// 5 - DexAccountBalance

pub type DexAccountBalanceDatum {
  account_balance_merkle_root: ByteArray,
}

pub type DexAccountBalanceRedeemer {
  // L1 actions
  AppDeposit
  AppWithdrawal
  // Hydra actions
  DABHydraIncrementalDecommit
  DABHydraCommit
  // In hydra actions
  HydraWithdrawal
  HydraCancelWithdrawal
  DABSplitMerkleTree
  DABCombineMerkleTree
  // Edge cases
  DABSpamPreventionWithdraw
  DABRemoveRegistry
}

// 6 - DexOrderBook

pub type DexOrderBookRedeemer {
  DexOrderBookSplitMerkleTree
  DexOrderBookCombineMerkleTree
  DexOrderBookHydraCommit
  DexOrderBookSpamPreventionWithdraw
  DexOrderBookEmergencyCancelOrder
}

pub type DexOrderBookDatum {
  operation_key: VerificationKeyHash,
  stop_key: VerificationKeyHash,
  fee_account: UserAccount,
  limit_orders_merkle_root: ByteArray,
  dex_account_balance_token: PolicyId,
  dex_account_balance_address: Address,
  dex_order_book_token: PolicyId,
  dex_order_book_address: Address,
  hydra_user_intent_script_hash: ScriptHash,
  hydra_account_script_hash: ScriptHash,
  hydra_order_book_script_hash: ScriptHash,
  hydra_token_policy_id: PolicyId,
}

pub type MerklizedOrderDatum {
  datum: Order,
  value: MValue,
}

// 7 - HydraUserIntent

pub type HydraUserIntentRedeemer {
  MintTradeIntent { account: UserAccount, intent: Data }
  MintMasterIntent { account: UserAccount, intent: Data }
  BurnIntent
}

pub type HydraUserIntentDatum {
  TradeIntent { account: UserAccount, intent: Data }
  MasterIntent { account: UserAccount, intent: Data }
}

// 8 - HydraAccount

pub type HydraAccountIntent {
  WithdrawalIntent { amount: MValue }
  CancelWithdrawalIntent { amount: MValue }
  TransferIntent { to: UserAccount, amount: MValue }
}

pub type HydraAccountRedeemer {
  HydraAccountTrade { trade_redeemer: Data }
  HydraAccountOperate
  HydraAccountSpamPreventionWithdraw
}

pub type HydraAccountOperation {
  ProcessWithdrawal { mpf_action: MPFProof }
  ProcessCancelWithdrawal { mpf_action: MPFProof }
  ProcessSameAccountTransferal { account: UserAccount }
  ProcessTransferal
  ProcessCombineUtxosAtClose {
    tree_or_proofs_with_token_map: TreeOrProofsWithTokenMap,
  }
  ProcessSplitUtxosAtOpen {
    tree_or_proofs_with_token_map: TreeOrProofsWithTokenMap,
  }
}

// 9 - HydraOrderBook

pub type HydraOrderBookIntent {
  PlaceOrderIntent { order: Order, authorized_account_value: MValue }
  ModifyOrderIntent { new_order: Order, authorized_account_value: MValue }
}

pub type HydraOrderBookRedeemer {
  PlaceOrder { account: UserAccount }
  CancelOrder
  FillOrder { filler_order_id: ByteArray }
  ModifyOrder { account: UserAccount }
  CombineOrderMerkle { tree_or_proofs_with_token_map: TreeOrProofsWithTokenMap }
  SplitOrderMerkle { tree_or_proofs_with_token_map: TreeOrProofsWithTokenMap }
}

pub type Order {
  order_id: ByteArray,
  base_token: (PolicyId, AssetName),
  quote_token: (PolicyId, AssetName),
  is_buy: Bool,
  list_price_times_1bil: Int,
  // if is_buy: `size` in quote_token, else `size` in base_token
  size: Int,
  fee_amount_bp: Int,
  account: UserAccount,
}

pub type MValue =
  Pairs<PolicyId, Pairs<AssetName, Int>>

// 10 - HydraTokens
pub type HydraTokensRedeemer {
  MintAtHydraOpen
  BurnAtHydraClose
  MintAtCancelWithdrawal
  BurnAtWithdrawal
  MintAtInitOrderBook
  BurnAtCombineOrderBook
}

// From Hydra scripts
pub type HydraInitialRedeemer {
  ViaAbort
  ViaCommit { committed_refs: List<OutputReference> }
}
