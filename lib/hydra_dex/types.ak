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

// Mint Redeemer

pub type MintPolarity {
  RMint
  RBurn
}

pub type UserAccount {
  UserSpotAccount { account: Account }
  UserFundingAccount { account: Account }
  UserMobileAccount { account: Account }
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
  hydra_initial_hash: ScriptHash,
  hydra_signers: List<VerificationKeyHash>,
}

pub type AppOracleRedeemer {
  DexRotateKey { new_operation_key: ByteArray, new_stop_key: ByteArray }
  StopDex
  RotateHydraInfo { new_hydra_info: HydraInfo }
}

// all_token_indices: Pairs<Int, (PolicyId, AssetName)>,

// 1 - AccountOperation

pub type ProcessAppDeposit {
  mpf_action: MPFProof,
}

pub type ProcessAppWithdrawal {
  account: UserAccount,
  amount: MValue,
  mpf_action: MPFProof,
}

pub type ProcessHydraHeadOpen {
  account_balance_proof: ByteArray,
  net_deposit_proof: ByteArray,
}

pub type ProcessHydraWithdrawal {
  mpf_action: MPFProof,
}

pub type ProcessHydraCancelWithdrawal {
  mpf_action: MPFProof,
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
  order: HydraOrderBookDatum,
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
  AppDeposit
  AppWithdrawal
  HydraWithdrawal
  HydraCancelWithdrawal
  DexAccountBalanceHydraCommit
  DexAccountBalanceTransferAccountBalance
  DexAccountBalanceSplitMerkleTree
  DexAccountBalanceCombineMerkleTree
  DexAccountBalanceSpamPreventionWithdraw
  DexAccountBalanceRemoveRegistry
  HydraIncrementalDecommit
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
  hydra_user_intent_token: PolicyId,
  hydra_user_intent_address: Address,
  hydra_account_balance_token: PolicyId,
  hydra_account_balance_address: Address,
  hydra_order_book_token: PolicyId,
  hydra_order_book_address: Address,
  withdrawal_script_hashes: DexOrderBookWithdrawalScripts,
  hydra_tokens_policy_id: PolicyId,
  hydra_assets_map: Pairs<(PolicyId, AssetName), ByteArray>,
}

pub type DexOrderBookWithdrawalScripts {
  hydra_head_open: ScriptHash,
  hydra_head_close: ScriptHash,
  hydra_withdrawal: ScriptHash,
  hydra_cancel_withdrawal: ScriptHash,
  hydra_internal_transfer: ScriptHash,
  hydra_combine_balance: ScriptHash,
  combine_order_merkle: ScriptHash,
  split_order_merkle: ScriptHash,
  hydra_place_order: ScriptHash,
  hydra_fill_order: ScriptHash,
  hydra_cancel_order: ScriptHash,
  hydra_release_extra_value: ScriptHash,
}

// 7 - HydraUserIntent

pub type HydraUserIntentRedeemer {
  MintPlaceOrderIntent { order: HydraOrderBookDatum }
  HydraUserPlaceOrder
  MintCancelOrderIntent { account: UserAccount, order_id: ByteArray }
  HydraUserCancelOrder
  MintWithdrawalIntent { account: UserAccount, amount: MValue }
  HydraUserWithdrawal
  MintCancelWithdrawalIntent { account: UserAccount, amount: MValue }
  HydraUserCancelWithdrawal
  MintTransferIntent { from: UserAccount, to: UserAccount, amount: MValue }
  HydraUserTransfer
  BurnIntent
}

pub type HydraUserIntentDatum {
  // - Same as `HydraOrderBook`'s `LimitOrder` with an extra field of `order_id`
  PlaceOrderIntent {
    order_id: ByteArray,
    long_token: (AssetName, PolicyId),
    short_token: (AssetName, PolicyId),
    is_long: Bool,
    list_price_times_1bil: Int,
    order_size: Int,
    fee_amount_bp: Int,
    extra_value: Int,
    account: UserAccount,
  }
  CancelOrderIntent { account: UserAccount, order_id: ByteArray }
  WithdrawalIntent { account: UserAccount, amount: MValue }
  CancelWithdrawalIntent { account: UserAccount, amount: MValue }
  TransferIntent { from: UserAccount, to: UserAccount, amount: MValue }
}

// 8 - HydraAccountBalance

pub type HydraAccountBalanceDatum {
  account: UserAccount,
  balance: MValue,
}

pub type HydraAccountBalanceRedeemer {
  UpdateBalanceWithPlaceOrder
  UpdataBalanceWithFillOrder
  UpdataBalanceWithCancelOrder
  UpdataBalanceWithReleaseExtraValue
  UpdateBalanceWithWithdrawal
  UpdateBalanceWithCancelWithdrawal
  UpdateBalanceWithTransfer
  HydraCombineUtxosAtClose
  // HydraAccountBalanceSpamPreventionWithdraw
  HydraAccountBalanceRemoveEmptyBalance
  HydraCombineUtxosAtOpen
}

// 9 - HydraOrderBook

pub type HydraOrderBookRedeemer {
  PlaceOrder
  CancelOrder
  FillOrder
  ReleaseExtraValue
  CombineOrderMerkle
  SplitOrderMerkle
}

pub type HydraOrderBookDatum {
  order_id: ByteArray,
  long_token: (PolicyId, AssetName),
  short_token: (PolicyId, AssetName),
  is_long: Bool,
  list_price_times_1bil: Int,
  order_size: Int,
  fee_amount_bp: Int,
  extra_value: Int,
  account: UserAccount,
}

pub type MValue =
  Pairs<PolicyId, Pairs<AssetName, Int>>

pub type FillOrderRedeemer {
  filler_order_id: ByteArray,
}

// 10 - HydraTokens
pub type HydraTokensRedeemer {
  MintAtHydraOpen
  BurnAtHydraClose
  BurnAtWithdrawal
}

// From Hydra scripts
pub type HydraInitialRedeemer {
  ViaAbort
  ViaCommit { committed_refs: List<OutputReference> }
}
