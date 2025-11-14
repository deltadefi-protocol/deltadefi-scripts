use aiken/cbor
use cardano/address.{Script, VerificationKey, from_script}
use cardano/assets.{Value, from_asset}
use hydra_dex/account_utils.{hash_token}
use hydra_dex/types.{
  Account, AppOracleDatum, DexOrderBookDatum, DexOrderBookWithdrawalScripts,
  HydraInfo, HydraOrderBookDatum, MValue, PlaceOrderIntent, TokenMap,
  UserAccount, UserSpotAccount, WithdrawalScriptHashes,
}
use mocktail.{
  mock_policy_id, mock_pub_key_hash, mock_script_hash,
  mock_verfication_key_credential,
}
use mocktail/virgin_address.{mock_script_address}

pub const mock_operation_key = mock_pub_key_hash(0)

pub const mock_stop_key = mock_pub_key_hash(1)

pub const mock_oracle_nft = mock_policy_id(0)

pub const mock_app_deposit_request_token = mock_policy_id(1)

pub const mock_emergency_withdrawal_request_token = mock_policy_id(100)

pub const mock_dex_account_balance_token = mock_policy_id(3)

pub const mock_dex_order_book_token = mock_policy_id(4)

pub const mock_emergency_cancel_order_request_token = mock_policy_id(400)

pub const mock_oracle_address = from_script("oracle_address")

pub const mock_app_vault_address = from_script("app_vault_address")

pub const mock_app_deposit_request_address =
  from_script("app_deposit_request_address")

pub const mock_emergency_withdrawal_request_address =
  from_script("emergency_withdrawal_request_address")

pub const mock_dex_account_balance_address =
  from_script("dex_account_balance_address")

pub const mock_dex_order_book_address = from_script("dex_order_book_address")

pub const mock_emergency_cancel_order_request_address =
  from_script("emergency_cancel_order_request_address")

pub const mock_app_deposit = mock_script_hash(0)

pub const mock_app_withdrawal = mock_script_hash(1)

pub const mock_emergency_cancel_order = mock_script_hash(700)

pub const mock_withdrawal_script_hashes: WithdrawalScriptHashes =
  WithdrawalScriptHashes {
    app_deposit: mock_app_deposit,
    app_withdrawal: mock_app_withdrawal,
    emergency_cancel_order: mock_emergency_cancel_order,
  }

pub const mock_hydra_token_policy_id = mock_script_hash(800)

pub const mock_hydra_initial_hash = mock_script_hash(999)

pub const mock_hydra_script_address = mock_script_address(999, None)

pub const mock_hydra_signer_1 = mock_pub_key_hash(100)

pub const mock_hydra_signer_2 = mock_pub_key_hash(200)

pub const mock_hydra_signer_3 = mock_pub_key_hash(300)

pub const mock_hydra_signers =
  [mock_hydra_signer_1, mock_hydra_signer_2, mock_hydra_signer_3]

pub const mock_input_oracle_datum: AppOracleDatum =
  AppOracleDatum {
    operation_key: mock_operation_key,
    stop_key: mock_stop_key,
    oracle_nft: mock_oracle_nft,
    oracle_address: mock_oracle_address,
    app_vault_address: mock_app_vault_address,
    app_deposit_request_token: mock_app_deposit_request_token,
    app_deposit_request_address: mock_app_deposit_request_address,
    dex_account_balance_token: mock_dex_account_balance_token,
    dex_account_balance_address: mock_dex_account_balance_address,
    dex_order_book_token: mock_dex_order_book_token,
    dex_order_book_address: mock_dex_order_book_address,
    emergency_cancel_order_request_token: mock_emergency_cancel_order_request_token,
    emergency_cancel_order_request_address: mock_emergency_cancel_order_request_address,
    emergency_withdrawal_request_token: mock_emergency_withdrawal_request_token,
    emergency_withdrawal_request_address: mock_emergency_withdrawal_request_address,
    all_withdrawal_script_hashes: mock_withdrawal_script_hashes,
    hydra_tokens_policy_id: mock_hydra_token_policy_id,
    hydra_info: HydraInfo {
      hydra_initial_hash: mock_hydra_initial_hash,
      hydra_signers: mock_hydra_signers,
    },
  }

pub const mock_new_operation_key = mock_pub_key_hash(10)

pub const mock_new_stop_key = mock_pub_key_hash(11)

pub const mock_output_oracle_datum: AppOracleDatum =
  AppOracleDatum {
    ..mock_input_oracle_datum,
    operation_key: mock_new_operation_key,
    stop_key: mock_new_stop_key,
  }

pub const mock_hydra_head_open = mock_script_hash(2)

pub const mock_hydra_head_close = mock_script_hash(3)

pub const mock_hydra_withdrawal = mock_script_hash(4)

pub const mock_hydra_cancel_withdrawal = mock_script_hash(5)

pub const mock_hydra_internal_transfer = mock_script_hash(6)

pub const mock_combine_order_merkle = mock_script_hash(7)

pub const mock_split_order_merkle = mock_script_hash(8)

pub const mock_hydra_place_order = mock_script_hash(9)

pub const mock_hydra_fill_order = mock_script_hash(10)

pub const mock_hydra_cancel_order = mock_script_hash(11)

pub const mock_hydra_release_extra_value = mock_script_hash(12)

pub const mock_hydra_combine_balance = mock_script_hash(13)

pub const mock_dex_order_book_withdrawal_scripts: DexOrderBookWithdrawalScripts =
  DexOrderBookWithdrawalScripts {
    hydra_head_open: mock_hydra_head_open,
    hydra_head_close: mock_hydra_head_close,
    hydra_withdrawal: mock_hydra_withdrawal,
    hydra_cancel_withdrawal: mock_hydra_cancel_withdrawal,
    hydra_internal_transfer: mock_hydra_internal_transfer,
    hydra_combine_balance: mock_hydra_combine_balance,
    combine_order_merkle: mock_combine_order_merkle,
    split_order_merkle: mock_split_order_merkle,
    hydra_place_order: mock_hydra_place_order,
    hydra_fill_order: mock_hydra_fill_order,
    hydra_cancel_order: mock_hydra_cancel_order,
    hydra_release_extra_value: mock_hydra_release_extra_value,
  }

pub const mock_hydra_user_intent_token = mock_policy_id(5)

pub const mock_hydra_user_intent_address =
  from_script("hydra_user_intent_address")

// pub const mock_hydra_account_balance_token = mock_policy_id(6)

pub const mock_hydra_account_balance_address =
  from_script("hydra_account_balance_address")

pub const mock_hydra_order_book_token = mock_policy_id(7)

pub const mock_hydra_order_book_address =
  from_script("hydra_order_book_address")

pub const mock_fee_account =
  Account {
    account_id: "fee_account_id",
    operation_key: mock_verfication_key_credential(999),
    master_key: mock_verfication_key_credential(1000),
  }

pub const mock_dex_order_book_datum: DexOrderBookDatum =
  DexOrderBookDatum {
    operation_key: mock_operation_key,
    stop_key: mock_stop_key,
    fee_account: UserSpotAccount { account: mock_fee_account },
    limit_orders_merkle_root: "mock_limit_orders_merkle_root",
    dex_account_balance_token: mock_dex_account_balance_token,
    dex_account_balance_address: mock_dex_account_balance_address,
    dex_order_book_token: mock_dex_order_book_token,
    dex_order_book_address: mock_dex_order_book_address,
    hydra_user_intent_token: mock_hydra_user_intent_token,
    hydra_user_intent_address: mock_hydra_user_intent_address,
    // hydra_account_balance_token: mock_hydra_account_balance_token,
    hydra_account_balance_address: mock_hydra_account_balance_address,
    hydra_order_book_token: mock_hydra_order_book_token,
    hydra_order_book_address: mock_hydra_order_book_address,
    withdrawal_script_hashes: mock_dex_order_book_withdrawal_scripts,
    hydra_tokens_policy_id: mock_hydra_token_policy_id,
  }

pub fn to_mvalue(value: Value) -> MValue {
  let data = cbor.serialise(value)
  expect Some(mvalue_raw): Option<Data> = cbor.deserialise(data)
  expect mvalue: MValue = mvalue_raw
  mvalue
}

pub const mock_account_id = #"3450e8e7ff044148af0b0f151f490d99"

pub const mock_account_master_key_hash =
  #"4ba6dd244255995969d2c05e323686bcbaba83b736e729941825d79b"

pub const mock_account_operation_key_hash =
  #"ec4574aacf96128597eff93ab9bc36c6bdc13d7f16ef5b62840ffa1f"

pub const mock_account =
  Account {
    account_id: mock_account_id,
    master_key: VerificationKey(mock_account_master_key_hash),
    operation_key: VerificationKey(mock_account_operation_key_hash),
  }

pub const mock_account_id_2 = #"5bade4195c2e4136b9bca9b563725cad"

pub const mock_account_master_key_hash_2 =
  #"fdeb4bf0e8c077114a4553f1e05395e9fb7114db177f02f7b65c8de4"

pub const mock_account_operation_key_hash_2 =
  #"fd92839136c47054fda09f2fbbb1792386a3b143cea5fca14fb8bace"

pub const mock_account_2 =
  Account {
    account_id: mock_account_id_2,
    master_key: VerificationKey(mock_account_master_key_hash_2),
    operation_key: VerificationKey(mock_account_operation_key_hash_2),
  }

pub const mock_account_id_3 = #"5bade4195c2e4136b9bca9b563725eee"

pub const mock_account_master_key_hash_3 = mock_pub_key_hash(1003)

pub const mock_account_operaion_key_hash_3 = mock_pub_key_hash(1103)

pub const mock_account_3 =
  Account {
    account_id: mock_account_id_3,
    master_key: VerificationKey(mock_account_master_key_hash_3),
    operation_key: VerificationKey(mock_account_operaion_key_hash_3),
  }

pub const mock_account_id_4 = #"5bade4195c2e4136b9bca9b563725fff"

pub const mock_account_master_key_hash_4 = mock_pub_key_hash(1004)

pub const mock_account_operaion_key_hash_4 = mock_pub_key_hash(1104)

pub const mock_account_4 =
  Account {
    account_id: mock_account_id_4,
    master_key: VerificationKey(mock_account_master_key_hash_4),
    operation_key: VerificationKey(mock_account_operaion_key_hash_4),
  }

pub const mock_script_account_id = #"3450e8e7ff044148a000000000000000"

pub const mock_script_account_master_key_hash = mock_script_hash(111)

pub const mock_script_account_operation_key_hash = mock_script_hash(112)

pub const mock_script_account =
  Account {
    account_id: mock_script_account_id,
    master_key: Script(mock_script_account_master_key_hash),
    operation_key: Script(mock_script_account_operation_key_hash),
  }

pub const mock_script_account_id_2 = #"5bade4195c2e41360000000000000000"

pub const mock_script_account_master_key_hash_2 = mock_script_hash(121)

pub const mock_script_account_operation_key_hash_2 = mock_script_hash(122)

pub const mock_script_account_2 =
  Account {
    account_id: mock_script_account_id_2,
    master_key: Script(mock_script_account_master_key_hash_2),
    operation_key: Script(mock_script_account_operation_key_hash_2),
  }

pub const mock_order_id = "order_id"

pub fn mock_order(
  order_id: ByteArray,
  is_long: Bool,
  order_size: Int,
  list_price_times_1bil: Int,
  fee_amount_bp: Int,
  extra_value: Int,
  account: Account,
) {
  HydraOrderBookDatum {
    order_id,
    long_token: ("", ""),
    short_token: (
      #"5066154a102ee037390c5236f78db23239b49c5748d3d349f3ccf04b",
      #"55534458",
    ),
    is_long,
    list_price_times_1bil,
    order_size,
    fee_amount_bp,
    extra_value,
    account: UserSpotAccount { account },
  }
}

pub fn mock_order_intent(
  is_long: Bool,
  order_size: Int,
  list_price_times_1bil: Int,
  fee_amount_bp: Int,
  extra_value: Int,
) {
  PlaceOrderIntent {
    order_id: mock_order_id,
    long_token: ("", ""),
    short_token: (
      #"5066154a102ee037390c5236f78db23239b49c5748d3d349f3ccf04b",
      #"55534458",
    ),
    is_long,
    list_price_times_1bil,
    order_size,
    fee_amount_bp,
    extra_value,
    account: UserSpotAccount { account: mock_account },
  }
}

pub fn mock_usd(qty: Int) -> Value {
  from_asset(
    #"5066154a102ee037390c5236f78db23239b49c5748d3d349f3ccf04b",
    #"55534458",
    qty,
  )
}

pub const mock_hydra_usd_token_name: ByteArray =
  hash_token(
    #"5066154a102ee037390c5236f78db23239b49c5748d3d349f3ccf04b",
    #"55534458",
  )

pub fn mock_hydra_usd(qty: Int) -> Value {
  from_asset(mock_hydra_token_policy_id, mock_hydra_usd_token_name, qty)
}

pub fn mock_hydra_lovelace(qty: Int) -> Value {
  from_asset(mock_hydra_token_policy_id, hash_token("", ""), qty)
}

pub fn mock_hydra_account(account: Account) -> UserAccount {
  UserSpotAccount { account }
}

pub const mock_token_map: TokenMap =
  [
    Pair("", ("", "")),
    Pair(
      #"578df351072da33dc2f3d2abb4706b5847562419d315962fb86909406b883960",
      (#"5066154a102ee037390c5236f78db23239b49c5748d3d349f3ccf04b", #"55534458"),
    ),
  ]

test hashing_tokens() {
  let hash =
    hash_token(
      #"5066154a102ee037390c5236f78db23239b49c5748d3d349f3ccf04b",
      #"55534458",
    )
  hash == #"578df351072da33dc2f3d2abb4706b5847562419d315962fb86909406b883960"
}
