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
  - Return `total_order_value (TOV)`, `account_payoff (AP)`, `total_filled_order_value (TFOV)`, `total_order_payoff_value (TOPV)`, `filler_order_input_opt`
  - Skip the filler order for later process
  - Get `order_value (OV)`, `min_order_value (MOV)`, `min_payoff_value (MPV)`
    - Calculate the `excess_order_value (EOV)` (`OV` - `MOV`)
  - If the order is partially filled, with `filled_qty` = `start_qty` - `end_qty`, calculate:
    - If any order information other than `size` changed -> panic
    - `Spent OV (SOV)` = `OV` - output `order_value`
    - `Filled OV (FOV)` = `MOV` - output `order_size`
    - `Return OV (ROV)` = `SOV` - `FOV`
    - `Final Order Payoff (FOP)` = calculate from `FOV`
  - Process the maker order
    - Calculate `fee` (`FOP` \* 10bp round down)
    - To maker `Final Payoff (FP)` = `FOP` + `ROV` - `fee`
    - To fee collector `fee`
- Handle filler order
  - Calculate `fee` (`TFOV` \* 10bp round down)
  - Get `Maker OV`
  - Handle unfilled order value
    - Get `SOV` for filler order
    - `TOV` = `TOV` + `SOV`
  - `order remaining value (ORV)` = `TOV` - `TPV`
  - Process the taker order
    - Pay the `ORV` to taker
    - If there is negative `ORV` → deduct from fee instead
    - To taker `Final Payoff (Taker FP)` = `tfov` - `fee`
    - To fee collector `fee`

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
