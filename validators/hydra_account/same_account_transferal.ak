use cardano/assets.{PolicyId, without_lovelace}
use cardano/transaction.{Transaction}
use cocktail.{
  group_inputs, group_outputs, inputs_value, key_signed, outputs_value,
}
use hydra_dex/account_utils.{
  create_account_inputs_filter, create_account_outputs_filter,
}
use hydra_dex/types.{DexOrderBookDatum, UserAccount}
use hydra_dex/utils.{get_dex_order_book_datum}

pub fn same_account_transferal(
  oracle_nft: PolicyId,
  account: UserAccount,
  tx: Transaction,
) -> Bool {
  let Transaction { inputs, outputs, reference_inputs, extra_signatories, .. } =
    tx

  // - Ref input with `oracle_nft`
  let DexOrderBookDatum { operation_key, hydra_account_script_hash, .. }: DexOrderBookDatum =
    reference_inputs |> get_dex_order_book_datum(oracle_nft)

  // - Categorize inputs into
  //   - `AI` - Account Inputs
  //   - Other inputs
  let ai_filter =
    create_account_inputs_filter(account, hydra_account_script_hash)
  let (account_inputs, other_inputs) = inputs |> group_inputs(ai_filter)

  // - Categorize outputs into
  //   - `AO` - Account Outputs with `from` account at intent
  //   - Other outputs
  let ao_filter =
    create_account_outputs_filter(account, hydra_account_script_hash)
  let (account_outputs, other_outputs) = outputs |> group_outputs(ao_filter)

  // - No other inputs
  // - No other outputs
  let no_other_inputs = other_inputs == []
  let no_other_outputs = other_outputs == []

  // - `AI` and `AO` value are equal
  let ai_value = inputs_value(account_inputs) |> without_lovelace()
  let ao_value = outputs_value(account_outputs) |> without_lovelace()
  let is_account_value_equal = ai_value == ao_value

  //  - Signed by `operating_key`
  let is_hydra_internal_transfer_authorized =
    key_signed(extra_signatories, operation_key)

  and {
    no_other_inputs?,
    no_other_outputs?,
    is_account_value_equal?,
    is_hydra_internal_transfer_authorized?,
  }
}
