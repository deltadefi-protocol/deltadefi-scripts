# Specification - HydraUserIntent Token

## Parameter

- `dex_oracle_nft`: The policy id of the token attached with `DexOrderBook`

## User Action

1. User Intent - Redeemer `MintPlaceOrderIntent { order: HydraOrderBookDatum }`

   - Exactly 1 token minted
   - Token name equals empty byte array
   - Auth by account (either sign by any `trade_key` or `withdrawal_key`, or pass any script validation of `trade_key` or `withdrawal_key`)
   - Output to `HydraUserIntent` address with correct datum

2. User Intent - Redeemer `MintCancelOrderIntent { account: UserAccount, order_id: ByteArray }`

   - Exactly 1 token minted
   - Token name equals empty byte array
   - Auth by account (either sign by any `trade_key` or `withdrawal_key`, or pass any script validation of `trade_key` or `withdrawal_key`)
   - Output to `HydraUserIntent` address with correct datum

3. User Intent - Redeemer `MintModifyOrderIntent { new_order: HydraOrderBookDatum }`

   - Exactly 1 token minted
   - Token name equals empty byte array
   - Auth by account (either sign by any `trade_key` or `withdrawal_key`, or pass any script validation of `trade_key` or `withdrawal_key`)
   - Output to `HydraUserIntent` address with correct datum

4. User Intent - Redeemer `MintWithdrawalIntent { account: UserAccount, amount: MValue }`

   - Exactly 1 token minted
   - Token name equals empty byte array
   - Auth by account (sign by `withdrawal_key`, or pass script validation of `withdrawal_key`)
   - Output to `HydraUserIntent` address with correct `WithdrawalIntent` datum

5. User Intent - Redeemer `MintCancelWithdrawalIntent { account: UserAccount, amount: MValue }`

   - Exactly 1 token minted
   - Token name equals empty byte array
   - Auth by account (sign by `withdrawal_key`, or pass script validation of `withdrawal_key`)
   - Output to `HydraUserIntent` address with correct `WithdrawalIntent` datum

6. User Intent - Redeemer `MintCancelTransferIntent`

   - Exactly 1 token minted
   - Token name equals empty byte array
   - Auth by account (sign by `withdrawal_key`, or pass script validation of `withdrawal_key`)
   - Output to `HydraUserIntent` address with correct `TransferIntent` datum

7. Process Intent / Burn

   - Operation key is signed
