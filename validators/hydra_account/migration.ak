use aiken/collection/list
use cardano/address.{Credential, Script, from_script}
use cardano/assets.{PolicyId, without_lovelace}
use cardano/transaction.{Input, Output, Transaction}
use cocktail.{
  group_inputs, group_outputs, input_inline_datum, key_signed,
  output_inline_datum,
}
use cocktail/vodka_value.{inputs_value, outputs_value}
use hydra_dex/types.{
  DexOrderBookDatum, UserAccount, UserFundingAccount, UserMobileAccount,
  UserTradeAccount,
}
use hydra_dex/utils.{get_dex_order_book_datum}

pub fn migration(
  oracle_nft: PolicyId,
  account: UserAccount,
  credential: Credential,
  tx: Transaction,
) -> Bool {
  let Transaction { inputs, outputs, reference_inputs, extra_signatories, .. } =
    tx

  // - Ref input with `oracle_nft`
  let DexOrderBookDatum {
    operation_key,
    hydra_account_script_hash,
    hydra_order_book_script_hash,
    ..
  }: DexOrderBookDatum =
    reference_inputs |> get_dex_order_book_datum(oracle_nft)

  // - Old script hash from own credential (this withdrawal script)
  expect Script(old_script_hash) = credential
  let old_account_address = from_script(old_script_hash)

  // - New script hash from oracle
  let new_account_address = from_script(hydra_account_script_hash)

  // - Categorize inputs into
  //   - `AI` - Account Inputs at old script hash with matching `account` datum
  //   - Other inputs
  let ai_filter =
    fn(input: Input) {
      if input.output.address == old_account_address {
        expect input_datum: UserAccount = input_inline_datum(input)
        input_datum == account
      } else {
        False
      }
    }
  let (account_inputs, other_inputs) = inputs |> group_inputs(ai_filter)

  // - Categorize outputs into
  //   - `AO` - Account Outputs at new `hydra_account_script_hash`
  //   - Other outputs
  let migrated_account = migrate_account(account, hydra_order_book_script_hash)
  let ao_filter =
    fn(output: Output) {
      if output.address == new_account_address {
        expect output_datum: UserAccount = output_inline_datum(output)
        output_datum == migrated_account
      } else {
        False
      }
    }
  let (account_outputs, _other_outputs) = outputs |> group_outputs(ao_filter)

  // - No other inputs at old script hash (single account per tx)
  let no_other_old_script_inputs =
    other_inputs
      |> list.all(fn(input) { input.output.address != old_account_address })

  // - No inputs at new `hydra_account_script_hash` (prevent mixing with normal operations)
  let no_new_script_inputs =
    inputs
      |> list.all(fn(input) { input.output.address != new_account_address })

  // - Total value preserved
  let ai_value = inputs_value(account_inputs) |> without_lovelace()
  let ao_value = outputs_value(account_outputs) |> without_lovelace()
  let is_value_preserved = ai_value == ao_value

  // - Signed by `operation_key`
  let is_authorized = key_signed(extra_signatories, operation_key)

  and {
    no_other_old_script_inputs?,
    no_new_script_inputs?,
    is_value_preserved?,
    is_authorized?,
  }
}

fn migrate_account(
  account: UserAccount,
  new_trading_logic: ByteArray,
) -> UserAccount {
  when account is {
    UserTradeAccount { account, .. } ->
      UserTradeAccount { account, trading_logic: new_trading_logic }
    UserFundingAccount { account, .. } ->
      UserFundingAccount { account, trading_logic: new_trading_logic }
    UserMobileAccount { account, .. } ->
      UserMobileAccount { account, trading_logic: new_trading_logic }
  }
}
