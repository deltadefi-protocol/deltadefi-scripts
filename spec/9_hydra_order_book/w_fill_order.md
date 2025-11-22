# Specification - HydraOrderBook - FillOrder

## Redeemer

- FillOrder { filler_order_id: ByteArray }

## Logics

- Ref input with `dex_oracle_nft`
- Categorize inputs into
  - `OI` - Order Inputs
  - Other inputs
- Categorize outputs into
  - `AO` - Account Outputs
  - `OO` - Order Output
  - Other outputs

### Backend Logics

- Loop through `OI`
  - Return `total_order_value`, `total_min_order_value`, `total_payoff_value`, `account_payoff`, `filler_order_opt`
  - Skip the filler order for later process
  - Get `order_value (OV)`, `min_order_value (MOV)`, `min_payoff_value (MPV)`
    - Calculate the `excess_order_value (EOV)` (`OV` - `MOV`)
  - If the order is partially filled, with `filled_qty` = `start_qty` - `end_qty`, calculate:
    - If any order information other than `size` changed -> panic
    - `Final OV` = `OV` - output `OV`
    - `Final MOV` = `filled_qty`'s value
    - `Final EOV` = `FOV` - `FMOV`
    - `Final MPV` = convert `filled_qty` into pay off Int’s value
    - Return `Final OV`, `Final EOV`, `Final MPV`
  - Process the maker order
    - Calculate settlement to maker
      - payoff (i.e. `filled qty`)
      - Excessive value `EOV`
    - Calculate fee (`filled qty` \* 10bp round down)
- Handle filler order
  - Use exactly the makers’ `Final MOV` as payoff
  - Calculate fee (`Final MOV` \* 10bp round down)
  - `order remaining value` = `start qty` - `to pay qty`
  - Handle unfilled order value
    - Deduct `new order qty` from `order remaining value`
  - Pay the `order remaining value` to taker
    - If there is negative `order remaining value` → deduct from fee instead

### Contract Guards

- There is no other inputs
- There is no other outputs
- Loop through `AO`
  - Each has at least received the payoff value calculated above
- There is no negative payoff
- `OO` has at least value
  - `is_long` == True -> at least short qty of short token
  - `is_long` == False -> at least `size` of long token
- Value parity: `OI` == `AO` + `OO` (to clear: is the check needed?)
- Signed by `operating_key`
