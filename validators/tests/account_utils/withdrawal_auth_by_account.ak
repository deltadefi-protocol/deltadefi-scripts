use cardano/address.{Script, VerificationKey}
use hydra_dex/account_utils.{withdrawal_auth_by_account}
use hydra_dex/types.{
  Account, UserFundingAccount, UserMobileAccount, UserTradeAccount,
}

pub const mock_normal_account =
  Account {
    account_id: "mock_account_id",
    master_key: VerificationKey("mock_master_key"),
    operation_key: VerificationKey("mock_operation_key"),
  }

pub const mock_script_account =
  Account {
    account_id: "mock_account_id",
    master_key: Script("mock_master_key"),
    operation_key: Script("mock_operation_key"),
  }

test au_wa_spot_normal_1() {
  let account = UserTradeAccount { account: mock_normal_account }
  !withdrawal_auth_by_account(account, [], ["mock_operation_key"])
}

test au_wa_spot_normal_2() {
  let account = UserTradeAccount { account: mock_normal_account }
  withdrawal_auth_by_account(account, [], ["mock_master_key"])
}

test au_wa_spot_normal_3() {
  let account = UserTradeAccount { account: mock_normal_account }
  !withdrawal_auth_by_account(account, [], ["mock_master_key_2"])
}

test au_wa_spot_normal_4() {
  let account = UserTradeAccount { account: mock_normal_account }
  withdrawal_auth_by_account(
    account,
    [],
    ["mock_master_key", "mock_operation_key_2"],
  )
}

test au_wa_spot_script_1() {
  let account = UserTradeAccount { account: mock_script_account }
  withdrawal_auth_by_account(account, [Pair(Script("mock_master_key"), 0)], [])
}

test au_wa_spot_script_2() {
  let account = UserTradeAccount { account: mock_script_account }
  !withdrawal_auth_by_account(
    account,
    [Pair(Script("mock_operation_key"), 0)],
    [],
  )
}

test au_wa_spot_script_3() {
  let account = UserTradeAccount { account: mock_script_account }
  !withdrawal_auth_by_account(
    account,
    [Pair(Script("mock_script_hash_3"), 0)],
    [],
  )
}

test au_wa_spot_script_4() {
  let account = UserTradeAccount { account: mock_script_account }
  withdrawal_auth_by_account(
    account,
    [Pair(Script("mock_script_hash_3"), 0), Pair(Script("mock_master_key"), 0)],
    [],
  )
}

test au_wa_funding_normal_1() {
  let account = UserFundingAccount { account: mock_normal_account }
  withdrawal_auth_by_account(account, [], ["mock_operation_key"])
}

test au_wa_funding_normal_2() {
  let account = UserFundingAccount { account: mock_normal_account }
  withdrawal_auth_by_account(account, [], ["mock_master_key"])
}

test au_wa_funding_normal_3() {
  let account = UserFundingAccount { account: mock_normal_account }
  !withdrawal_auth_by_account(account, [], ["mock_master_key_2"])
}

test au_wa_funding_normal_4() {
  let account = UserFundingAccount { account: mock_normal_account }
  withdrawal_auth_by_account(
    account,
    [],
    ["mock_master_key", "mock_operation_key_2"],
  )
}

test au_wa_funding_script_1() {
  let account = UserFundingAccount { account: mock_script_account }
  withdrawal_auth_by_account(
    account,
    [Pair(Script("mock_operation_key"), 0)],
    [],
  )
}

test au_wa_funding_script_2() {
  let account = UserFundingAccount { account: mock_script_account }
  withdrawal_auth_by_account(account, [Pair(Script("mock_master_key"), 0)], [])
}

test au_wa_funding_script_3() {
  let account = UserFundingAccount { account: mock_script_account }
  !withdrawal_auth_by_account(
    account,
    [Pair(Script("mock_script_hash_3"), 0)],
    [],
  )
}

test au_wa_funding_script_4() {
  let account = UserFundingAccount { account: mock_script_account }
  withdrawal_auth_by_account(
    account,
    [Pair(Script("mock_script_hash_3"), 0), Pair(Script("mock_master_key"), 0)],
    [],
  )
}

test au_wa_mobile_normal_1() {
  let account = UserMobileAccount { account: mock_normal_account }
  withdrawal_auth_by_account(account, [], ["mock_operation_key"])
}

test au_wa_mobile_normal_2() {
  let account = UserMobileAccount { account: mock_normal_account }
  withdrawal_auth_by_account(account, [], ["mock_master_key"])
}

test au_wa_mobile_normal_3() {
  let account = UserMobileAccount { account: mock_normal_account }
  !withdrawal_auth_by_account(account, [], ["mock_master_key_2"])
}

test au_wa_mobile_normal_4() {
  let account = UserMobileAccount { account: mock_normal_account }
  withdrawal_auth_by_account(
    account,
    [],
    ["mock_master_key", "mock_operation_key_2"],
  )
}

test au_wa_mobile_script_1() {
  let account = UserMobileAccount { account: mock_script_account }
  withdrawal_auth_by_account(
    account,
    [Pair(Script("mock_operation_key"), 0)],
    [],
  )
}

test au_wa_mobile_script_2() {
  let account = UserMobileAccount { account: mock_script_account }
  withdrawal_auth_by_account(account, [Pair(Script("mock_master_key"), 0)], [])
}

test au_wa_mobile_script_3() {
  let account = UserMobileAccount { account: mock_script_account }
  !withdrawal_auth_by_account(
    account,
    [Pair(Script("mock_script_hash_3"), 0)],
    [],
  )
}

test au_wa_mobile_script_4() {
  let account = UserMobileAccount { account: mock_script_account }
  withdrawal_auth_by_account(
    account,
    [Pair(Script("mock_script_hash_3"), 0), Pair(Script("mock_master_key"), 0)],
    [],
  )
}
