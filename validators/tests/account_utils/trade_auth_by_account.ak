use cardano/address.{Script}
use hydra_dex/account_utils.{trade_auth_by_account}
use hydra_dex/types.{UserFundingAccount, UserMobileAccount, UserTradeAccount}
use tests/utils.{
  mock_account, mock_account_master_key_hash, mock_account_master_key_hash_2,
  mock_account_operation_key_hash, mock_account_operation_key_hash_2,
  mock_script_account, mock_script_account_master_key_hash,
  mock_script_account_master_key_hash_2, mock_script_account_operation_key_hash,
}

test au_ta_spot_normal_1() {
  let account = UserTradeAccount { account: mock_account }
  trade_auth_by_account(account, [], [mock_account_operation_key_hash])
}

test au_ta_spot_normal_2() {
  let account = UserTradeAccount { account: mock_account }
  trade_auth_by_account(account, [], [mock_account_master_key_hash])
}

test au_ta_spot_normal_3() {
  let account = UserTradeAccount { account: mock_account }
  !trade_auth_by_account(account, [], [mock_account_master_key_hash_2])
}

test au_ta_spot_normal_4() {
  let account = UserTradeAccount { account: mock_account }
  trade_auth_by_account(
    account,
    [],
    [mock_account_master_key_hash, mock_account_operation_key_hash_2],
  )
}

test au_ta_spot_script_1() {
  let account = UserTradeAccount { account: mock_script_account }
  trade_auth_by_account(
    account,
    [Pair(Script(mock_script_account_master_key_hash), 0)],
    [],
  )
}

test au_ta_spot_script_2() {
  let account = UserTradeAccount { account: mock_script_account }
  trade_auth_by_account(
    account,
    [Pair(Script(mock_script_account_master_key_hash), 0)],
    [],
  )
}

test au_ta_spot_script_3() {
  let account = UserTradeAccount { account: mock_script_account }
  !trade_auth_by_account(
    account,
    [Pair(Script(mock_script_account_master_key_hash_2), 0)],
    [],
  )
}

test au_ta_spot_script_4() {
  let account = UserTradeAccount { account: mock_script_account }
  trade_auth_by_account(
    account,
    [
      Pair(Script(mock_script_account_master_key_hash_2), 0),
      Pair(Script(mock_script_account_master_key_hash), 0),
    ],
    [],
  )
}

test au_ta_funding_normal_1() {
  let account = UserFundingAccount { account: mock_account }
  !trade_auth_by_account(account, [], [mock_account_operation_key_hash])
}

test au_ta_funding_normal_2() {
  let account = UserFundingAccount { account: mock_account }
  trade_auth_by_account(account, [], [mock_account_master_key_hash])
}

test au_ta_funding_normal_3() {
  let account = UserFundingAccount { account: mock_account }
  !trade_auth_by_account(account, [], [mock_account_master_key_hash_2])
}

test au_ta_funding_normal_4() {
  let account = UserFundingAccount { account: mock_account }
  trade_auth_by_account(
    account,
    [],
    [mock_account_master_key_hash, mock_account_operation_key_hash_2],
  )
}

test au_ta_funding_script_1() {
  let account = UserFundingAccount { account: mock_script_account }
  !trade_auth_by_account(
    account,
    [Pair(Script(mock_script_account_operation_key_hash), 0)],
    [],
  )
}

test au_ta_funding_script_2() {
  let account = UserFundingAccount { account: mock_script_account }
  trade_auth_by_account(
    account,
    [Pair(Script(mock_script_account_master_key_hash), 0)],
    [],
  )
}

test au_ta_funding_script_3() {
  let account = UserFundingAccount { account: mock_script_account }
  !trade_auth_by_account(
    account,
    [Pair(Script(mock_script_account_master_key_hash_2), 0)],
    [],
  )
}

test au_ta_funding_script_4() {
  let account = UserFundingAccount { account: mock_script_account }
  trade_auth_by_account(
    account,
    [
      Pair(Script(mock_script_account_master_key_hash_2), 0),
      Pair(Script(mock_script_account_master_key_hash), 0),
    ],
    [],
  )
}

test au_ta_mobile_normal_1() {
  let account = UserMobileAccount { account: mock_account }
  trade_auth_by_account(account, [], [mock_account_operation_key_hash])
}

test au_ta_mobile_normal_2() {
  let account = UserMobileAccount { account: mock_account }
  trade_auth_by_account(account, [], [mock_account_master_key_hash])
}

test au_ta_mobile_normal_3() {
  let account = UserMobileAccount { account: mock_account }
  !trade_auth_by_account(account, [], [mock_account_master_key_hash_2])
}

test au_ta_mobile_normal_4() {
  let account = UserMobileAccount { account: mock_account }
  trade_auth_by_account(
    account,
    [],
    [mock_account_master_key_hash, mock_account_operation_key_hash_2],
  )
}

test au_ta_mobile_script_1() {
  let account = UserMobileAccount { account: mock_script_account }
  trade_auth_by_account(
    account,
    [Pair(Script(mock_script_account_operation_key_hash), 0)],
    [],
  )
}

test au_ta_mobile_script_2() {
  let account = UserMobileAccount { account: mock_script_account }
  trade_auth_by_account(
    account,
    [Pair(Script(mock_script_account_master_key_hash), 0)],
    [],
  )
}

test au_ta_mobile_script_3() {
  let account = UserMobileAccount { account: mock_script_account }
  !trade_auth_by_account(
    account,
    [Pair(Script(mock_script_account_master_key_hash_2), 0)],
    [],
  )
}

test au_ta_mobile_script_4() {
  let account = UserMobileAccount { account: mock_script_account }
  trade_auth_by_account(
    account,
    [
      Pair(Script(mock_script_account_master_key_hash_2), 0),
      Pair(Script(mock_script_account_master_key_hash), 0),
    ],
    [],
  )
}
