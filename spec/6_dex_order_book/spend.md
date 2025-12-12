# Specification - DexOrderBook

## Parameter

- `oracle_nft`: The policy id of `OracleNFT`
- `dex_order_book_nft`: The policy id of `OracleNFT` locked in `DexOrderBook`

## Datum

- `limit_orders_merkle_root`: storing the root of merkle tree in `ByteArray`, with all limit orders
- All other oracle info

### `limit_orders_merkle_root` Merkle Tree

- Key: order id (uuid generated from backend)
- Value: Serialized `HydraOrderBook` datum

## User Action

1. Splitting merkle tree

   - Obtain the `DexOrderBook - split_order_merkle` script hash from dex order book (also an oracle within Hydra)
   - Check if `DexOrderBook - split_order_merkle` withdrawal script is run

2. Combining merkle tree

   - Obtain the `DexOrderBook - combine_order_merkle` script hash from dex order book (also an oracle within Hydra)
   - Check if `DexOrderBook - combine_order_merkle` withdrawal script is run

3. TODO - Get into hydra

4. Spam prevention withdraw

   - Current input does not contain auth token
   - Sign by operation key referencing by oracle utxo

5. Emergency Cancel

   - check if `emergency_cancel` withdrawal script is run
