# Specification - AccountOperation - HydraInternalTransfer

## User Action

1. Validate change in account balance

   - Input from `HydraUserIntent` with `TransferIntent` datum
   - Deduct the account balance from `HydraAccountBalance` with for the `from` account.
   - Add the account balance from `HydraAccountBalance` with for the `to` account.
   - Signed by `operating_key`
   - The intent token is burnt
