# Specification - HydraUserIntent Token

## Parameter

- `dex_oracle_nft`: The policy id of the token attached with `DexOrderBook`

## User Action

1. User Intent - Redeemer `MintTradeIntent { account: UserAccount, intent: Data }`

   - Exactly 1 token with empty token name minted
   - Auth by account (either sign by any `trade_key` or `master_key`, or pass any script validation of `trade_key` or `master_key`)
   - Only 1 output to `HydraUserIntent` address with datum `TradeDatum { account, intent }`

2. User Intent - Redeemer `MintMasterIntent { account: UserAccount, intent: Data }`

   - Exactly 1 token with empty token name minted
   - Auth by account (sign by `master_key`, or pass script validation of `master_key`)
   - Only 1 output to `HydraUserIntent` address with datum `MasterDatum { account, intent }`

3. Process Intent / Burn

   - Operation key is signed
