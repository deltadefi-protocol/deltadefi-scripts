# DeltaDeFi Hydra DEX

## Setup

1. Mint Oracle NFTs

   - Mint oracle nft
   - Mint DEX oracle book nft
   - Mint Account balance nft
   - Mint 2 \* Dex Net Deposit fts

2. Setup App oracle

   - Send oracle nft to app oracle validator

3. Setup DEXOrderBook utxo

   - Send nft to dex order book with empty merkle tree

4. Setup DexAccountBalnace utxo

   - Send nft to dex order book with empty merkle tree

5. Setup DexAccountBalance utxos

   - 2 \* Send nft to dex order book with empty merkle tree

6. Register all stake certs

## App User Actions

1. Deposit

   - Mint AppDepositRequest token to validator
   - Send value to AppVault

2. Internal - process deposit

   - Burn AppDepositRequest token
   - Insert / add balance to merkle tree at DexAccountBalance

3. Withdraw

   - Remove / reduce balance to merkle tree at DexAccountBalance
   - Withdraw value from vault

## Active Order Book User Actions

1. Internal - prepare order book utxos

   - Consume merkle tree, divide all order into single utxo at HydraOrderBook

2. Internal - prepare account balance utxos

   - Consume merkle tree, divide all account balance into single utxo at HydraAccountBalance

3. Internal - process deposit (DexAccountBalance)

   - Consume merkle tree, merge all account balance into utxo at HydraAccountBalance

4. Place order

5. Internl - Process order

6. Internl - Fill order

7. Withdrawal

8. Process withdrawal

9. Combine utxos for HydraOrderBook

10. Combine utxos for HydraAccountBalance

## Hydra

1. Hydra Init

2. Commit utxos into hydra

3. Close & Fanout
