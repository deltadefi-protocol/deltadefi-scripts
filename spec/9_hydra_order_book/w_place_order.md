# Specification - HydraOrderBook - PlaceOrder

## Redeemer

- PlaceOrder { account: UserAccount, authorized_account_value_l2: MValue }

## Logic

- Ref input with `dex_oracle_nft`
- Categorize inputs into
  - `AI` - Account Inputs with `account` at intent
  - `II` - Intent Input
  - Other inputs
- Categorize outputs into
  - `AO` - Account Output with `account` at intent
  - `OO` - Order Output with `account` at intent
  - Other outputs
- No other inputs and outputs
- `II` with `PlaceOrderIntent` datum
- `II` with `account` as account
- `OO` with exactly datum `II`
- `OO` has at least value
  - `is_buy` == True -> at least `size` of quote token
  - `is_buy` == False -> at least `size` of base token
- The input intent token is burnt
- The deduction of account value (`AI` - `AO`) does not exceed `authorized_account_value_l2`
- Value parity: `AI` == `AO` + `OO` (to clear: is the check needed?)
- Signed by `operating_key`
