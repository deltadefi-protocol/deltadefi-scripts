# Vault Calculation Unit Test Plan

Pure number calculation tests only. Each test has two cases: **clean** (beautiful round numbers) and **ugly** (numbers that cause rounding, large intermediates, edge precision).

All values in lovelace scale (10^6). Shares scaled by 10^6. Fee rate in basis points (denominator 10000).

---

## 1.1 Vault Equity (NAV)

Formula: `vaultEquity = usdcBalance + SUM(FLOOR(holdings[i].amount * holdings[i].price / 10^scale))`

Prices are sub-dollar (e.g. ADA ≈ 0.35 USD), stored as scaled integers: price=350_000, scale=6 → 0.35.

| #     | Test Case                           | Clean                                                                                                         | Ugly                                                                                                                        |
| ----- | ----------------------------------- | ------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| 1.1.1 | USDC only, no holdings              | `100_000_000` USDC, 0 holdings = `100_000_000`                                                                | `123_456_789` USDC, 0 holdings = `123_456_789`                                                                              |
| 1.1.2 | USDC + single holding               | `50_000_000` USDC + `100_000_000` ADA @ price=`500_000` scale=6 → `50M + floor(100M*500K/1M)` = `100_000_000` | `33_333_333` USDC + `77_777_777` ADA @ price=`412_345` scale=6 → `33_333_333 + floor(77_777_777*412_345/1M)` = `65_404_610` |
| 1.1.3 | USDC + multiple holdings            | `10_000_000` + `50_000_000` ADA @ `500_000`/10^6 + `20_000_000` BTC @ `2_000_000`/10^6 = `75_000_000`         | `7_777_777` + `33_333_333` ADA @ `999_999`/10^6 + `17_777_777` BTC @ `1_234_567`/10^6 = `63_058_932`                        |
| 1.1.4 | Zero USDC, only holdings            | 0 USDC + `100_000_000` ADA @ `1_000_000`/10^6 = `100_000_000`                                                 | 0 USDC + `137_777_777` ADA @ `729_927`/10^6 = `100_567_719`                                                                 |
| 1.1.5 | Zero equity (empty vault)           | 0 USDC, 0 holdings = 0                                                                                        | N/A                                                                                                                         |
| 1.1.6 | Floor rounding on holding valuation | `0` USDC + `3_000_000` tokens @ `333_333`/10^6 = `999_999` (no remainder)                                     | `0` USDC + `7_654_321` tokens @ `142_857`/10^6 = `1_093_473` (remainder `335_097`)                                          |

---

## 2.1 Shares Minted (Deposit)

Formula: `sharesMinted = floor(depositAmount * totalShares / vaultEquity)`
Genesis: `sharesMinted = depositAmount` when `totalShares == 0`

| #      | Test Case                                                  | Clean                                                                                                                                                                                                                                                        | Ugly                                                                                                                                             |
| ------ | ---------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| 2.1.1  | Owner genesis deposit (first ever)                         | deposit=`100_000_000`, totalShares=0 => minted=`100_000_000`                                                                                                                                                                                                 | deposit=`77_777_777`, totalShares=0 => minted=`77_777_777`                                                                                       |
| 2.1.2  | User first deposit (vault near par)                        | deposit=`50_000_000`, equity=`100_000_000`, shares=`100_000_000` => `50_000_000`                                                                                                                                                                             | deposit=`33_333_333`, equity=`99_999_997`, shares=`100_000_000` => `floor(33_333_333 * 100M / 99_999_997)` = `33_333_334`                        |
| 2.1.3  | User deposit when vault earning                            | deposit=`50_000_000`, equity=`120_000_000`, shares=`100_000_000` => `floor(50M * 100M / 120M)` = `41_666_666`                                                                                                                                                | deposit=`37_123_456`, equity=`113_456_789`, shares=`98_765_432` => floor(37_123_456 \* 98_765_432 / 113_456_789)                                 |
| 2.1.4  | User deposit when vault losing                             | deposit=`50_000_000`, equity=`80_000_000`, shares=`100_000_000` => `62_500_000`                                                                                                                                                                              | deposit=`41_111_111`, equity=`73_333_333`, shares=`100_000_000` => floor(41_111_111 \* 100_000_000 / 73_333_333)                                 |
| 2.1.5  | Owner deposit when vault earning                           | deposit=`100_000_000`, equity=`150_000_000`, shares=`100_000_000` => `floor(100M * 100M / 150M)` = `66_666_666`                                                                                                                                              | deposit=`88_888_888`, equity=`133_333_333`, shares=`100_000_000` => floor(88_888_888 \* 100_000_000 / 133_333_333)                               |
| 2.1.6  | Owner deposit when vault losing                            | deposit=`100_000_000`, equity=`80_000_000`, shares=`100_000_000` => `125_000_000`                                                                                                                                                                            | deposit=`55_555_555`, equity=`66_666_666`, shares=`100_000_000` => floor(55_555_555 \* 100_000_000 / 66_666_666)                                 |
| 2.1.7  | Dilution attack: deposit would make owner % < min required | Setup: owner has 5_000_000 shares of 100_000_000 total (5%). ownerMinPctBp=500. User deposits enough to dilute owner below 5%. Verify: sharesMinted calculation is correct, then separately check `ownerShares * 10000 / newTotalShares < 500` => **REJECT** | Same with ugly numbers: owner=4_999_999 of 99_999_999. Deposit that just barely dilutes.                                                         |
| 2.1.8  | Small deposit that mints 0 shares                          | deposit=1, equity=`1_000_000_000`, shares=`100_000_000` => `floor(1 * 100M / 1B)` = `floor(0.1)` = 0 => **REJECT**                                                                                                                                           | deposit=`999`, equity=`1_000_000_001`, shares=`1_000_000` => `floor(999 * 1M / 1_000_000_001)` = 0 => **REJECT**                                 |
| 2.1.9  | Large intermediate product precision                       | deposit=`1_000_000_000_000` (1M USDC), equity=`500_000_000_000`, shares=`500_000_000_000` => intermediate=`500_000_000_000_000_000_000_000`, result=`1_000_000_000_000`                                                                                      | deposit=`999_999_999_999`, equity=`777_777_777_777`, shares=`888_888_888_888` => intermediate has 36 digits, verify floor division still correct |
| 2.1.10 | Deposit of 1 lovelace that still mints > 0                 | deposit=1, equity=`100`, shares=`100_000_000` => `floor(1 * 100M / 100)` = `1_000_000`                                                                                                                                                                       | deposit=1, equity=`3`, shares=`10_000_000` => `floor(10M / 3)` = `3_333_333`                                                                     |

---

## 3.1 Gross Value (Withdrawal)

Formula: `grossValue = floor(sharesToRedeem * vaultEquity / totalShares)`

Full vs partial withdrawal is just different input magnitudes to the same formula — no separate tests needed.

| #     | Test Case                       | Clean                                                            | Ugly                                                                                                                             |
| ----- | ------------------------------- | ---------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------- |
| 3.1.1 | Withdrawal at par               | redeem=`25M`, equity=`100M`, total=`100M` => `25_000_000`        | redeem=`77_777_777`, equity=`100_000_003`, total=`100_000_000` => `floor(77_777_777 * 100_000_003 / 100_000_000)` = `77_777_779` |
| 3.1.2 | Withdrawal at profit            | redeem=`50M`, equity=`120M`, total=`100M` => `60_000_000`        | redeem=`33_333_333`, equity=`113_456_789`, total=`98_765_432` => `38_291_665`                                                    |
| 3.1.3 | Withdrawal at loss              | redeem=`50M`, equity=`80M`, total=`100M` => `40_000_000`         | redeem=`44_444_444`, equity=`66_666_666`, total=`100_000_000` => `29_629_629`                                                    |
| 3.1.4 | Rounding: non-divisible numbers | redeem=`33_333_333`, equity=`100M`, total=`100M` => `33_333_333` | redeem=`7_777_777`, equity=`111_111_111`, total=`99_999_999` => `8_641_974`                                                      |

---

## 3.2 Cost Basis Redeemed (Withdrawal)

Formula: `costBasisRedeemed = total_deposited * shares_to_redeem / total_shares_of_user`

On-chain uses: `old_entry.total_deposited * shares_to_redeem / old_entry.shares`

| #     | Test Case                              | Clean                                                                                               | Ugly                                                                                                                                          |
| ----- | -------------------------------------- | --------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| 3.2.1 | Full withdrawal (all shares)           | total_deposited=`100M`, redeem=`100M`, user_shares=`100M` => `100_000_000`                          | total_deposited=`83_456_789`, redeem=`77_777_776`, user_shares=`77_777_777` => `floor(83_456_789 * 77_777_776 / 77_777_777)` = `83_456_787`   |
| 3.2.2 | Partial withdrawal (half)              | total_deposited=`100M`, redeem=`50M`, user_shares=`100M` => `50_000_000`                            | total_deposited=`123_456_789`, redeem=`33_333_333`, user_shares=`77_777_777` => floor(123_456_789 \* 33_333_333 / 77_777_777)                 |
| 3.2.3 | Partial withdrawal (1/3)               | total_deposited=`90M`, redeem=`30M`, user_shares=`90M` => `30_000_000`                              | total_deposited=`109_876_543`, redeem=`33_333_333`, user_shares=`98_765_432` => `floor(109_876_543 * 33_333_333 / 98_765_432)` = `37_083_332` |
| 3.2.4 | After blended cost (multiple deposits) | total_deposited=`150M`, redeem=`50M`, user_shares=`141_666_666` => floor(150M \* 50M / 141_666_666) | total_deposited=`137_123_456`, redeem=`22_222_222`, user_shares=`131_765_432` => floor                                                        |

---

## 3.3 Fee Amount (Withdrawal)

Formula: `grossProfit = max(0, grossValue - costBasisRedeemed)`, `feeAmount = floor(grossProfit * feeRateBp / 10000)`

| #     | Test Case                       | Clean                                                                                                   | Ugly                                                                                                                                    |
| ----- | ------------------------------- | ------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| 3.3.1 | Standard profit, 10% fee        | grossValue=`60M`, costBasis=`50M`, feeBp=1000 => profit=`10M`, fee=`1_000_000`                          | grossValue=`57_777_777`, costBasis=`43_333_333`, feeBp=1000 => profit=`14_444_444`, fee=floor(14_444_444 \* 1000 / 10000) = `1_444_444` |
| 3.3.2 | No profit (break even)          | grossValue=`50M`, costBasis=`50M`, feeBp=1000 => fee=0                                                  | grossValue=`33_333_333`, costBasis=`33_333_333`, feeBp=1500 => fee=0                                                                    |
| 3.3.3 | Loss (no fee)                   | grossValue=`40M`, costBasis=`50M`, feeBp=1000 => fee=0                                                  | grossValue=`29_999_999`, costBasis=`33_333_333`, feeBp=2000 => fee=0                                                                    |
| 3.3.4 | Owner withdrawal (fee skipped)  | grossValue=`60M`, costBasis=`50M`, feeBp=1000, isOwner=true => fee=0                                    | grossValue=`57_777_777`, costBasis=`43_333_333`, feeBp=1000, isOwner=true => fee=0                                                      |
| 3.3.5 | Small profit, fee rounds to 0   | grossValue=`50_000_009`, costBasis=`50M`, feeBp=1000 => profit=9, fee=floor(9\*1000/10000)=floor(0.9)=0 | grossValue=`100_000_003`, costBasis=`100M`, feeBp=1 => profit=3, fee=floor(3\*1/10000)=0                                                |
| 3.3.6 | 20% fee rate                    | grossValue=`60M`, costBasis=`50M`, feeBp=2000 => profit=`10M`, fee=`2_000_000`                          | grossValue=`54_321_098`, costBasis=`43_210_987`, feeBp=2000 => profit=`11_110_111`, fee=floor(11_110_111 \* 2000 / 10000) = `2_222_022` |
| 3.3.7 | 99.99% fee rate (edge)          | grossValue=`60M`, costBasis=`50M`, feeBp=10000 => fee=`10_000_000`                                      | grossValue=`57_777_777`, costBasis=`43_333_333`, feeBp=9999 => profit=`14_444_444`, fee=`floor(14_444_444*9999/10000)` = `14_442_999`   |
| 3.3.8 | Near-zero fee rate (0.03%)      | grossValue=`60M`, costBasis=`50M`, feeBp=0 => fee=0                                                     | grossValue=`57_777_777`, costBasis=`43_333_333`, feeBp=3 => profit=`14_444_444`, fee=`floor(14_444_444*3/10000)` = `4_333`              |
| 3.3.9 | Minimum fee rate (1 bp = 0.01%) | grossValue=`60M`, costBasis=`50M`, feeBp=1 => profit=`10M`, fee=floor(10M\*1/10000)=`1_000`             | grossValue=`50_099_999`, costBasis=`50M`, feeBp=1 => profit=`99_999`, fee=floor(99_999/10000)=`9`                                       |

---

## 3.4 Fee Shares Minted (Withdrawal)

Formula: `feeSharesMinted = floor(feeAmount * totalShares / vaultEquity)`

| #     | Test Case                    | Clean                                                                           | Ugly                                                                                                              |
| ----- | ---------------------------- | ------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------- |
| 3.4.1 | Standard fee shares          | fee=`1M`, totalShares=`100M`, equity=`120M` => floor(1M\*100M/120M) = `833_333` | fee=`1_444_444`, totalShares=`98_765_432`, equity=`113_456_789` => floor                                          |
| 3.4.2 | Zero fee => zero shares      | fee=0, totalShares=`100M`, equity=`120M` => 0                                   | fee=0, totalShares=`77_777_777`, equity=`99_999_999` => 0                                                         |
| 3.4.3 | Large fee shares             | fee=`10M`, totalShares=`1_000M`, equity=`500M` => `20_000_000`                  | fee=`7_777_777`, totalShares=`888_888_888`, equity=`444_444_444` => floor(7_777_777 \* 888_888_888 / 444_444_444) |
| 3.4.4 | Small fee rounds to 0 shares | fee=1, totalShares=`100M`, equity=`1_000M` => floor(1\*100M/1000M)=floor(0.1)=0 | fee=`99`, totalShares=`100M`, equity=`999_999_999` => floor(99\*100M/999_999_999)                                 |

---

## 3.5 Net Payout (Withdrawal)

Formula: `netPayout = grossValue - feeAmount`

| #     | Test Case                     | Clean                                               | Ugly                                                                                   |
| ----- | ----------------------------- | --------------------------------------------------- | -------------------------------------------------------------------------------------- |
| 3.5.1 | Standard payout with fee      | grossValue=`60M`, fee=`1M` => `59_000_000`          | grossValue=`57_777_777`, fee=`1_444_444` => `56_333_333`                               |
| 3.5.2 | No fee (loss)                 | grossValue=`40M`, fee=0 => `40_000_000`             | grossValue=`29_999_999`, fee=0 => `29_999_999`                                         |
| 3.5.3 | No fee (owner)                | grossValue=`60M`, fee=0 => `60_000_000`             | grossValue=`57_777_777`, fee=0 => `57_777_777`                                         |
| 3.5.4 | Invariant: net + fee == gross | grossValue=`60M`, fee=`1M` => `59M` + `1M` == `60M` | grossValue=`54_321_098`, fee=`2_222_022` => `52_099_076` + `2_222_022` == `54_321_098` |

---

## 3.7 Owner Min % Check (Withdrawal)

Formula: `ownerPctAfter = floor(ownerSharesAfter * 10000 / totalSharesAfter)`, require `>= ownerMinPctBp`

| #     | Test Case                                | Clean                                                                                                                                                  | Ugly                                                                                                                                                                |
| ----- | ---------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 3.7.1 | Owner withdrawal passes min check        | ownerShares=`10M`, redeem=`4M`, feeMinted=0, totalShares=`100M`, minPct=500 => after: `floor(6M * 10000 / 96M)` = 625 >= 500 PASS                      | ownerShares=`7_777_777`, redeem=`2_000_000`, feeMinted=`100_000`, totalShares=`99_999_999`, minPct=500 => `floor(5_877_777 * 10000 / 98_099_999)` = 599 >= 500 PASS |
| 3.7.2 | Owner withdrawal fails min check         | ownerShares=`6M`, redeem=`2M`, feeMinted=0, totalShares=`100M`, minPct=500 => after: `floor(4M * 10000 / 98M)` = 408 < 500 FAIL                        | ownerShares=`5_100_000`, redeem=`600_001`, feeMinted=0, totalShares=`100M`, minPct=500 => `floor(4_499_999 * 10000 / 99_399_999)` = 452 < 500 FAIL                  |
| 3.7.3 | Owner withdrawal exactly at boundary     | ownerShares=`5M`, redeem=0 (static check), totalShares=`100M`, minPct=500 => `floor(5M * 10000 / 100M)` = 500 == 500 PASS                              | ownerShares=`5_000_001`, redeem=0, totalShares=`100_000_000`, minPct=500 => `floor(5_000_001 * 10000 / 100_000_000)` = 500 PASS                                     |
| 3.7.4 | Fee shares help owner pass check         | ownerShares=`5M`, redeem=`1M`, feeMinted=`500_000`, totalShares=`100M`, minPct=400 => after: `floor(4_500_000 * 10000 / 99_500_000)` = 452 >= 400 PASS | ownerShares=`4_444_444`, redeem=`500_000`, feeMinted=`333_333`, totalShares=`88_888_888`, minPct=400 => `floor(4_277_777 * 10000 / 88_722_221)` = 482 >= 400 PASS   |
| 3.7.5 | Owner withdrawal to 0 (force-close only) | ownerShares=`5M`, redeem=`5M`, feeMinted=0, totalShares=`5M` => ownerSharesAfter=0, totalAfter=0 => ALLOWED (force-close path)                         | ownerShares=`3_333_333`, redeem=`3_333_333`, totalShares=`3_333_333` => 0/0 force-close                                                                             |

---

## 4.2 Path Independence (Profit Case)

Verify that withdrawing in parts vs all at once yields the same total fee (within floor rounding bounds).

Pure arithmetic: `floor(total_profit * bp / 10000) >= SUM(floor(profit_i * bp / 10000))`. Difference is at most N-1 (N = number of splits).

With full state transitions (fee shares minted, equity reduced by net payout): difference remains bounded.

| #     | Test Case                             | Clean                                                                                                                               | Ugly                                                                                                                                                 |
| ----- | ------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| 4.2.1 | Pure arithmetic: single >= 4-split    | profit=`20M`, bp=1000. single=`2_000_000`, split4=`2_000_000`, diff=0                                                               | profit=`13_333_337`, bp=1337. single=`1_782_667`, split3=`1_782_666`, diff=1                                                                         |
| 4.2.2 | With state changes: single vs 3-split | equity=`120M`, total=`100M`, user: shares=`100M`, deposited=`100M`, bp=1000. single_fee=`2_000_000`, split4_fee=`2_000_000`, diff=0 | equity=`113_456_789`, total=`98_765_432`, user: shares=`77_777_777`, deposited=`77_777_777`, bp=1337. single=`1_546_834`, split3=`1_546_833`, diff=1 |

---

## 4.3 Loss Crystallization

Verify that partial withdrawal at loss resets cost basis, so recovery charges more total fee than holding through.

| #     | Test Case                            | Clean                                                                                                                                                                                                      | Ugly                                                                                                                                                                                  |
| ----- | ------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 4.3.1 | Partial at loss, then full at profit | deposit `100M`, shares=`100M`. Vault drops equity=`90M`. Withdraw `25M` shares (loss, fee=0). Vault recovers equity=`110M`. Withdraw remaining `75M` shares. split_fee=`3_500_000` >= hold_fee=`1_000_000` | deposit `100M`, shares=`100M`. Vault drops equity=`87_654_321`, total=`98_765_432`. Withdraw `25_925_925`. Recovery equity=`106_789_012`. split_fee=`3_452_492` >= hold_fee=`812_387` |
| 4.3.2 | Multiple partials at loss            | deposit `100M`, shares=`100M`. Equity drops `95M`→`85M`→recovers `115M`. Withdraw `20M` at each stage. split_fee=`5_625_000` >= hold_fee=`1_500_000`                                                       | Same with equity `93_827_160`/total `98_765_432`→`82_716_049`→`111_111_111`. split_fee=`5_385_801` >= hold_fee=`1_250_000`                                                            |

---

## 6. Invariant Tests

Verify mathematical invariants hold across operations.

| #   | Test Case                                                     | Clean                                                                     | Ugly                                                                                                                             |
| --- | ------------------------------------------------------------- | ------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------- |
| 6.1 | `netPayout + feeAmount == grossValue`                         | gross=`60M`, fee=`1M` => net=`59M`, `59M+1M==60M`                         | gross=`57_777_777`, fee=`1_444_444` => net=`56_333_333`, sum=`57_777_777`                                                        |
| 6.2 | `feeAmount <= grossProfit`                                    | profit=9, fee=0 <= 9                                                      | profit=3, feeBp=777, fee=0 <= 3                                                                                                  |
| 6.3 | `feeSharesMinted * equity / totalShares <= feeAmount`         | fee=`1M`, feeShares=`833_333`, reconstructed=`999_999` <= `1M`            | fee=`1_444_444`, feeShares=`1_257_405`, reconstructed=`1_444_443` <= `1_444_444`                                                 |
| 6.4 | Deposit-then-withdraw at same equity: `returned <= deposited` | deposit=`50M` at equity=`100M`/shares=`100M` => gross_back=`50M` <= `50M` | deposit=`33_333_333` at equity=`109_876_543`/shares=`98_765_432` => minted=`29_962_546`, gross_back=`33_333_332` <= `33_333_333` |
| 6.5 | Sum of all depositor shares == totalShares                    | 3 deposits: `100M`+`50M`+`30M` => sum=`180M` == totalShares               | 3 deposits: `77_777_777`+`33_333_333`+`22_222_222` => sum=`133_333_332` == totalShares                                           |
| 6.6 | No depositor can claim more than vault holds                  | `floor(shares * equity / totalShares) <= equity` for any depositor        | shares=`98_765_431`, total=`98_765_432`, equity=`113_456_789` => claim=`113_456_787` <= equity                                   |
| 6.7 | Split deposits yield <= bulk deposit shares                   | 2x`25M` vs 1x`50M` at equity=`100M`/shares=`100M` => `50M == 50M`         | 3x`11_111_111` vs 1x`33_333_333` at equity=`109_876_543`/shares=`98_765_432` => `29_962_545 <= 29_962_546`                       |

---

## 10. End-to-End Deposit Scenarios

Full state transition tests. Compute sharesMinted, new totalShares, new vaultEquity.

| #    | Test Case                            | Clean                                                                                                                                                  | Ugly                                                                                                                                                                                     |
| ---- | ------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 10.1 | Owner genesis deposit                | deposit=`100M`, totalShares=0, equity=0 => minted=`100M`, newTotal=`100M`, newEquity=`100M`                                                            | deposit=`77_777_777` => same pattern (genesis: minted=deposit, no rounding)                                                                                                              |
| 10.2 | User deposit (vault earning)         | deposit=`50M`, equity=`120M`, totalShares=`100M` => minted=`41_666_666`, newTotal=`141_666_666`, newEquity=`170M`                                      | deposit=`37_123_456`, equity=`113_456_789`, totalShares=`98_765_432` => minted=`32_316_392`, newTotal=`131_081_824`, newEquity=`150_580_245`                                             |
| 10.3 | User deposit (vault losing)          | deposit=`50M`, equity=`80M`, totalShares=`100M` => minted=`62_500_000`, newTotal=`162_500_000`, newEquity=`130M`                                       | deposit=`41_111_111`, equity=`73_333_333`, totalShares=`100M` => minted=`56_060_606`, newTotal=`156_060_606`, newEquity=`114_444_444`                                                    |
| 10.4 | Second deposit                       | deposit=`30M`, equity=`120M`, totalShares=`100M` => minted=`25_000_000`, newTotal=`125M`, newEquity=`150M`                                             | deposit=`27_654_321`, equity=`109_876_543`, totalShares=`98_765_432` => minted=`24_857_816`, newTotal=`123_623_248`, newEquity=`137_530_864`                                             |
| 10.5 | Owner deposit when earning           | deposit=`50M`, equity=`150M`, totalShares=`100M` => minted=`33_333_333`, newTotal=`133_333_333`, newEquity=`200M`                                      | deposit=`88_888_888`, equity=`133_333_333`, totalShares=`100M` => minted=`66_666_666`, newTotal=`166_666_666`, newEquity=`222_222_221`                                                   |
| 10.6 | Owner deposit when losing            | deposit=`50M`, equity=`80M`, totalShares=`100M` => minted=`62_500_000`, newTotal=`162_500_000`, newEquity=`130M`                                       | deposit=`55_555_555`, equity=`66_666_666`, totalShares=`100M` => minted=`83_333_333`, newTotal=`183_333_333`, newEquity=`122_222_221`                                                    |
| 10.7 | Dilution attack (rejected)           | owner=`5M` of `100M` shares. minPct=500. User deposits `10_000M` at par, minted=`10_000_000_000`. ownerPct=`floor(5M*10000/10_100M)`=4 < 500 => REJECT | owner=`4_999_999` of `100M`. deposit=`4_987_654_321`, equity=`99_876_543`, totalShares=`100M`. minted=`4_993_819_540`. ownerPct=`floor(4_999_999*10000/5_093_819_540)`=9 < 500 => REJECT |
| 10.8 | Zero-share mint (rejected)           | deposit=1, equity=`10_000M`, totalShares=`100M` => minted=0 => REJECT                                                                                  | deposit=`9_999`, equity=`10_000_000_001`, totalShares=`1M` => minted=0 => REJECT                                                                                                         |
| 10.9 | Large intermediate product precision | deposit=`1T`, equity=`500B`, totalShares=`500B` => minted=`1T`, newTotal=`1.5T`, newEquity=`1.5T`                                                      | deposit=`999_999_999_999`, equity=`777_777_777_773`, totalShares=`888_888_888_881` => minted=`1_142_857_142_852` (36-digit intermediate)                                                 |

---

## 11. End-to-End Withdrawal Scenarios

Full state transition: grossValue, costBasis, profit, fee, feeShares, net, newTotalShares.

On-chain data per user: `SharesRecordEntry { shares, total_deposited }`.

| #     | Test Case                                   | Clean                                                                                                                                                                                                                      | Ugly                                                                                                                                                                                                                                                                      |
| ----- | ------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 11.1  | User full withdrawal at profit              | user: shares=`50M`, deposited=`50M`. equity=`120M`, total=`100M`, feeBp=1000. gross=`60M`, cb=`50M`, profit=`10M`, fee=`1M`, feeShares=`833_333`, net=`59M`, newTotal=`50_833_333`                                         | user: shares=`33_333_333`, deposited=`33_333_333`. equity=`113_456_789`, total=`98_765_432`, feeBp=1000. gross=`38_291_665`, cb=`33_333_333`, profit=`4_958_332`, fee=`495_833`, feeShares=`431_628`, net=`37_795_832`, newTotal=`65_863_727`                             |
| 11.2  | User full withdrawal at loss                | user: shares=`50M`, deposited=`50M`. equity=`80M`, total=`100M`, feeBp=1000. gross=`40M`, cb=`50M`, profit=0, fee=0, net=`40M`, newTotal=`50M`                                                                             | user: shares=`44_444_444`, deposited=`44_444_444`. equity=`66_666_666`, total=`100M`, feeBp=1500. gross=`29_629_629`, cb=`44_444_444`, profit=0, fee=0, net=`29_629_629`, newTotal=`55_555_556`                                                                           |
| 11.3  | User partial withdrawal at profit           | user: shares=`100M`, deposited=`100M`, redeem=`25M`. equity=`120M`, total=`100M`, feeBp=1000. gross=`30M`, cb=`25M`, profit=`5M`, fee=`500_000`, feeShares=`416_666`, net=`29_500_000`, newTotal=`75_416_666`              | user: shares=`77_777_777`, deposited=`77_777_777`, redeem=`22_222_222`. equity=`113_456_789`, total=`98_765_432`, feeBp=1000. gross=`25_527_777`, cb=`22_222_222`, profit=`3_305_555`, fee=`330_555`, feeShares=`287_751`, net=`25_197_222`, newTotal=`76_830_961`        |
| 11.4  | User partial withdrawal at loss             | user: shares=`100M`, deposited=`100M`, redeem=`20M`. equity=`90M`, total=`100M`, feeBp=1000. gross=`18M`, cb=`20M`, profit=0, fee=0, net=`18M`, newTotal=`80M`                                                             | user: shares=`77_777_777`, deposited=`77_777_777`, redeem=`22_222_222`. equity=`66_666_666`, total=`98_765_432`, feeBp=1000. gross=`14_999_999`, cb=`22_222_222`, profit=0, fee=0, net=`14_999_999`, newTotal=`76_543_210`                                                |
| 11.5  | User partial withdrawal near par            | user: shares=`100M`, deposited=`100M`, redeem=`25M`. equity=`100M`, total=`100M`, feeBp=1000. gross=`25M`, cb=`25M`, profit=0, fee=0, net=`25M`, newTotal=`75M`                                                            | user: shares=`77_777_777`, deposited=`77_777_777`, redeem=`22_222_222`. equity=`99_999_997`, total=`98_765_432`, feeBp=1000. gross=`22_499_999`, cb=`22_222_222`, profit=`277_777`, fee=`27_777`, feeShares=`27_434`, net=`22_472_222`, newTotal=`76_570_644`             |
| 11.6  | Owner partial at profit (no fee)            | owner: shares=`50M`, deposited=`50M`, redeem=`10M`. equity=`120M`, total=`100M`, feeBp=1000. gross=`12M`, cb=`10M`, profit=`2M`, fee=0, net=`12M`, newTotal=`90M`                                                          | owner: shares=`44_444_444`, deposited=`44_444_444`, redeem=`11_111_111`. equity=`113_456_789`, total=`98_765_432`, feeBp=1000. gross=`12_763_888`, cb=`11_111_111`, profit=`1_652_777`, fee=0, net=`12_763_888`, newTotal=`87_654_321`                                    |
| 11.7  | Owner partial at loss                       | owner: shares=`50M`, deposited=`50M`, redeem=`10M`. equity=`80M`, total=`100M`. gross=`8M`, cb=`10M`, profit=0, fee=0, net=`8M`, newTotal=`90M`                                                                            | owner: shares=`44_444_444`, deposited=`44_444_444`, redeem=`11_111_111`. equity=`73_333_333`, total=`98_765_432`. gross=`8_249_999`, cb=`11_111_111`, profit=0, fee=0, net=`8_249_999`, newTotal=`87_654_321`                                                             |
| 11.8  | Owner partial near par                      | owner: shares=`50M`, deposited=`50M`, redeem=`10M`. equity=`100M`, total=`100M`. gross=`10M`, cb=`10M`, profit=0, fee=0, net=`10M`, newTotal=`90M`                                                                         | owner: shares=`44_444_444`, deposited=`44_444_444`, redeem=`11_111_111`. equity=`99_999_997`, total=`98_765_432`. gross=`11_249_999`, cb=`11_111_111`, profit=`138_888`, fee=0, net=`11_249_999`, newTotal=`87_654_321`                                                   |
| 11.9  | Owner withdrawal fails min %                | owner: shares=`6M`, deposited=`6M`, redeem=`2M`. equity=`100M`, total=`100M`. ownerAfter=`4M`, totalAfter=`98M`, pct=408 < 500 → REJECT                                                                                    | owner: shares=`5_555_555`, deposited=`5_555_555`, redeem=`1_777_777`. equity=`109_876_543`, total=`98_765_432`. ownerAfter=`3_777_778`, totalAfter=`96_987_655`, pct=389 < 500 → REJECT                                                                                   |
| 11.10 | User withdrawal: fee shares boost owner pct | owner=`6M` of `100M`. User: shares=`10M`, deposited=`10M`, redeem=`10M`. equity=`120M`, total=`100M`, feeBp=1000. fee=`200_000`, feeShares=`166_666`. ownerAfter=`6_166_666`, totalAfter=`90_166_666`, pct=683 >= 500 PASS | owner=`5_555_555` of `98_765_432`. User: shares=`11_111_111`, deposited=`11_111_111`, redeem=`11_111_111`. equity=`113_456_789`, total=`98_765_432`, feeBp=1000. fee=`165_277`, feeShares=`143_875`. ownerAfter=`5_699_430`, totalAfter=`87_798_196`, pct=649 >= 500 PASS |

---

## Summary Count

| Section                  | Tests  | Cases per test | Total cases |
| ------------------------ | ------ | -------------- | ----------- |
| 1.1 Vault Equity (NAV)   | 6      | 2              | 12          |
| 2.1 Shares Minted        | 10     | 2              | 20          |
| 3.1 Gross Value          | 4      | 2              | 8           |
| 3.2 Cost Basis Redeemed  | 4      | 2              | 8           |
| 3.3 Fee Amount           | 9      | 2              | 18          |
| 3.4 Fee Shares Minted    | 4      | 2              | 8           |
| 3.5 Net Payout           | 4      | 2              | 8           |
| 3.7 Owner Min % Check    | 5      | 2              | 10          |
| 4.2 Path Independence    | 2      | 2              | 4           |
| 4.3 Loss Crystallization | 2      | 2              | 4           |
| 6. Invariants            | 7      | 2              | 14          |
| 10. E2E Deposit          | 9      | 2              | 18          |
| 11. E2E Withdrawal       | 10     | 2              | 20          |
| **Total**                | **76** |                | **152**     |

---

## Appendix A: On-Chain Function Reference

### Source Functions

#### `cal_shares_amount` — `lib/hydra_dex/deposit_utils.ak:39-49`

```aiken
pub fn cal_shares_amount(usd_value: Int, vault_equity: Int, total_shares: Int) -> Int {
  if total_shares == 0 { usd_value }
  else { usd_value * total_shares / vault_equity }
}
```

- Genesis (total_shares == 0): returns `usd_value` directly
- Subsequent: `floor(usd_value * total_shares / vault_equity)`

#### `convert_shares_to_usd` — `lib/hydra_dex/withdraw_utils.ak:15-21`

```aiken
pub fn convert_shares_to_usd(shares_amount: Int, total_shares: Int, vault_equity: Int) -> Int {
  shares_amount * vault_equity / total_shares
}
```

- Inverse of `cal_shares_amount`. Used for gross withdrawal value (Section 3.1).

#### `cal_per_user_operator_fee` — `lib/hydra_dex/withdraw_utils.ak:23-35`

```aiken
pub fn cal_per_user_operator_fee(withdrawal_value: Int, cost_basis: Int, operator_fee_rate_bp: Int) -> Int {
  let profit = withdrawal_value - cost_basis
  if profit <= 0 { 0 }
  else { profit * operator_fee_rate_bp / 10000 }
}
```

- Fee on profit only, floor division. Fee = 0 when loss or break-even.

#### `compute_fee_shares` — `lib/hydra_dex/withdraw_utils.ak:37-40`

```aiken
pub fn compute_fee_shares(fee: Int, total_shares: Int, vault_equity: Int) -> Int {
  fee * total_shares / vault_equity
}
```

#### `convert_m_value_to_usd` — `lib/hydra_dex/price_oracle_utils.ak:54-74`

- Computes `SUM(amount * price / 10^scale)` over an MValue (multi-asset map).
- Used for vault equity computation with price oracle scale factors.

#### `convert_value_to_usd` — `lib/hydra_dex/price_oracle_utils.ak:37-51`

- Same as above but operates on cardano `Value` type instead of `MValue`.

### On-Chain Data Model

#### `SharesRecordEntry` — `lib/hydra_dex/types.ak`

```aiken
type SharesRecordEntry { shares: Int, total_deposited: Int }
```

- Cost basis for withdrawal: `total_deposited * shares_to_redeem / user_shares`
- Cost per share is NOT stored on-chain; it is derived: `total_deposited / shares`

#### `vault_equity` — `lib/hydra_dex/types.ak:337-341`

- Passed as a signed `Message { vault_equity, prices, utxo_ref }` from Hydra nodes.
- Computed off-chain. On-chain verifies signatures and UTxO consumption.

---

## Appendix B: Test Code Structure

### Directory Layout

```
validators/tests/
  deposit_utils/
    cal_shares_amount.ak       # existing tests for cal_shares_amount
    convert_m_value_to_usd.ak  # existing tests for convert_m_value_to_usd
  withdraw_utils/
    convert_shares_to_usd.ak   # existing tests
    compute_fee_shares.ak      # existing tests
    cal_per_user_operator_fee.ak
  vault_calculations/          # NEW — unit tests per formula
    vault_equity.ak            # 1.1
    shares_minted.ak           # 2.1
    gross_value.ak             # 3.1
    cost_basis_redeemed.ak     # 3.2
    fee_amount.ak              # 3.3
    fee_shares_minted.ak       # 3.4
    net_payout.ak              # 3.5
    owner_min_pct.ak           # 3.7
    e2e_deposit.ak             # 10
    e2e_withdrawal.ak          # 11
    path_independence.ak       # 4.2
    loss_crystallization.ak    # 4.3
    invariants.ak              # 6
```

### Test Conventions

- **Naming**: `test <prefix>_<section>_<scenario>_<clean|ugly>()`
- **Prefixes**: `du_` = deposit*utils, `wu*`= withdraw_utils,`ve*`= vault_equity,`sm*`= shares_minted,`gv*`= gross_value,`cb*`= cost_basis,`fa*`= fee_amount,`fs*`= fee_shares,`np*`= net_payout,`om*` = owner_min_pct
- **Imports**: `use hydra_dex/deposit_utils.{cal_shares_amount}`
- **Assertions**: direct equality `==` on return value
- **Expected failures**: `test foo() fail { expr == wrong_value }` — Aiken `fail` annotation means the test body must evaluate to `False`
- **No scaling on integer division**: Aiken integer division truncates toward zero (equivalent to floor for positive operands)

---

## Appendix C: Pre-Computed Expected Values (Python)

All values computed with Python integer arithmetic (`//` = floor division).

### Section 1.1: Vault Equity (`amount * price / 10^scale`)

| Test      | Expression                                                                  | Result        | Remainder                      |
| --------- | --------------------------------------------------------------------------- | ------------- | ------------------------------ |
| 1.2 clean | `100_000_000 * 500_000 // 10^6`                                             | `50_000_000`  | `0`                            |
| 1.2 ugly  | `33_333_333 + 77_777_777 * 412_345 // 10^6`                                 | `65_404_610`  | `457_065`                      |
| 1.3 ugly  | `7_777_777 + 33_333_333 * 999_999 // 10^6 + 17_777_777 * 1_234_567 // 10^6` | `63_058_932`  | ADA: `666_667`, BTC: `817_559` |
| 1.4 ugly  | `137_777_777 * 729_927 // 10^6`                                             | `100_567_719` | `432_279`                      |
| 1.6 clean | `3_000_000 * 333_333 // 10^6`                                               | `999_999`     | `0`                            |
| 1.6 ugly  | `7_654_321 * 142_857 // 10^6`                                               | `1_093_473`   | `335_097`                      |

### Section 2.1: Shares Minted

| Test       | Expression                                               | Result              |
| ---------- | -------------------------------------------------------- | ------------------- |
| 2.2 ugly   | `33_333_333 * 100_000_000 // 99_999_997`                 | `33_333_334`        |
| 2.3 clean  | `50_000_000 * 100_000_000 // 120_000_000`                | `41_666_666`        |
| 2.3 ugly   | `37_123_456 * 98_765_432 // 113_456_789`                 | `32_316_392`        |
| 2.4 clean  | `50_000_000 * 100_000_000 // 80_000_000`                 | `62_500_000`        |
| 2.4 ugly   | `41_111_111 * 100_000_000 // 73_333_333`                 | `56_060_606`        |
| 2.5 clean  | `100_000_000 * 100_000_000 // 150_000_000`               | `66_666_666`        |
| 2.5 ugly   | `88_888_888 * 100_000_000 // 133_333_333`                | `66_666_666`        |
| 2.6 clean  | `100_000_000 * 100_000_000 // 80_000_000`                | `125_000_000`       |
| 2.6 ugly   | `55_555_555 * 100_000_000 // 66_666_666`                 | `83_333_333`        |
| 2.8 clean  | `1 * 100_000_000 // 1_000_000_000`                       | `0`                 |
| 2.8 ugly   | `999 * 1_000_000 // 1_000_000_001`                       | `0`                 |
| 2.9 clean  | `1_000_000_000_000 * 500_000_000_000 // 500_000_000_000` | `1_000_000_000_000` |
| 2.9 ugly   | `999_999_999_999 * 888_888_888_888 // 777_777_777_777`   | `1_142_857_142_856` |
| 2.10 clean | `1 * 100_000_000 // 100`                                 | `1_000_000`         |
| 2.10 ugly  | `1 * 10_000_000 // 3`                                    | `3_333_333`         |

### Section 3.1: Gross Value (`redeem * equity / total`)

| Test       | Expression                                | Result       | Remainder    |
| ---------- | ----------------------------------------- | ------------ | ------------ |
| 3.1.1 ugly | `77_777_777 * 100_000_003 // 100_000_000` | `77_777_779` | `33_333_331` |
| 3.1.2 ugly | `33_333_333 * 113_456_789 // 98_765_432`  | `38_291_665` | `93_123_457` |
| 3.1.3 ugly | `44_444_444 * 66_666_666 // 100_000_000`  | `29_629_629` | `3_703_704`  |
| 3.1.4 ugly | `7_777_777 * 111_111_111 // 99_999_999`   | `8_641_974`  | `52_222_221` |

### Section 3.2: Cost Basis Redeemed (`total_deposited * redeem / user_shares`)

| Test        | Expression                                | Result       | Remainder     |
| ----------- | ----------------------------------------- | ------------ | ------------- |
| 3.2.1 ugly  | `83_456_789 * 77_777_776 // 77_777_777`   | `83_456_787` | `72_098_765`  |
| 3.2.2 ugly  | `123_456_789 * 33_333_333 // 77_777_777`  | `52_910_052` | `33_333_333`  |
| 3.2.3 ugly  | `109_876_543 * 33_333_333 // 98_765_432`  | `37_083_332` | `91_728_395`  |
| 3.2.4 clean | `150_000_000 * 50_000_000 // 141_666_666` | `52_941_176` | `101_960_784` |
| 3.2.4 ugly  | `137_123_456 * 22_222_222 // 131_765_432` | `23_125_852` | `1_491_168`   |

### Section 3.3: Fee Amount (`profit * feeBp / 10000`)

| Test       | Expression                   | Result       | Remainder |
| ---------- | ---------------------------- | ------------ | --------- |
| 3.3.1 ugly | `14_444_444 * 1000 // 10000` | `1_444_444`  | `4_000`   |
| 3.3.6 ugly | `11_110_111 * 2000 // 10000` | `2_222_022`  | `2_000`   |
| 3.3.7 ugly | `14_444_444 * 9999 // 10000` | `14_442_999` | `5_556`   |
| 3.3.8 ugly | `14_444_444 * 3 // 10000`    | `4_333`      | `3_332`   |
| 3.3.9 ugly | `99_999 * 1 // 10000`        | `9`          | `9_999`   |

### Section 3.4: Fee Shares Minted (`fee * totalShares / equity`)

| Test        | Expression                               | Result       | Remainder     |
| ----------- | ---------------------------------------- | ------------ | ------------- |
| 3.4.1 clean | `1_000_000 * 100_000_000 // 120_000_000` | `833_333`    | `40_000_000`  |
| 3.4.1 ugly  | `1_444_444 * 98_765_432 // 113_456_789`  | `1_257_405`  | `1_887_263`   |
| 3.4.3 ugly  | `7_777_777 * 888_888_888 // 444_444_444` | `15_555_554` | `0`           |
| 3.4.4 ugly  | `99 * 100_000_000 // 999_999_999`        | `9`          | `900_000_009` |

### Section 3.5: Net Payout (`gross - fee`, no rounding)

| Test       | Expression               | Result                                                        |
| ---------- | ------------------------ | ------------------------------------------------------------- |
| 3.5.1 ugly | `57_777_777 - 1_444_444` | `56_333_333`                                                  |
| 3.5.4 ugly | `54_321_098 - 2_222_022` | `52_099_076` (verify: `52_099_076 + 2_222_022 == 54_321_098`) |

### Section 3.7: Owner Min % Check (`ownerSharesAfter * 10000 / totalSharesAfter`)

| Test        | ownerAfter  | totalAfter    | Expression                        | Result | Remainder    |
| ----------- | ----------- | ------------- | --------------------------------- | ------ | ------------ |
| 3.7.1 clean | `6_000_000` | `96_000_000`  | `6M * 10000 // 96M`               | `625`  | `0`          |
| 3.7.1 ugly  | `5_877_777` | `98_099_999`  | `5_877_777 * 10000 // 98_099_999` | `599`  | `15_870_599` |
| 3.7.2 clean | `4_000_000` | `98_000_000`  | `4M * 10000 // 98M`               | `408`  | `16_000_000` |
| 3.7.2 ugly  | `4_499_999` | `99_399_999`  | `4_499_999 * 10000 // 99_399_999` | `452`  | `71_190_452` |
| 3.7.3 ugly  | `5_000_001` | `100_000_000` | `5_000_001 * 10000 // 100M`       | `500`  | `10_000`     |
| 3.7.4 clean | `4_500_000` | `99_500_000`  | `4_500_000 * 10000 // 99_500_000` | `452`  | `26_000_000` |
| 3.7.4 ugly  | `4_277_777` | `88_722_221`  | `4_277_777 * 10000 // 88_722_221` | `482`  | `13_659_478` |

### Section 4.2: Path Independence

| Test        | single_fee  | split_fee   | diff |
| ----------- | ----------- | ----------- | ---- |
| 4.2.1 clean | `2_000_000` | `2_000_000` | `0`  |
| 4.2.1 ugly  | `1_782_667` | `1_782_666` | `1`  |
| 4.2.2 clean | `2_000_000` | `2_000_000` | `0`  |
| 4.2.2 ugly  | `1_546_834` | `1_546_833` | `1`  |

### Section 4.3: Loss Crystallization (`split_fee >= hold_fee`)

| Test        | split_fee   | hold_fee    |
| ----------- | ----------- | ----------- |
| 4.3.1 clean | `3_500_000` | `1_000_000` |
| 4.3.1 ugly  | `3_452_492` | `812_387`   |
| 4.3.2 clean | `5_625_000` | `1_500_000` |
| 4.3.2 ugly  | `5_385_801` | `1_250_000` |

### Section 6: Invariants

| Test | Invariant                           | Clean                  | Ugly                                   |
| ---- | ----------------------------------- | ---------------------- | -------------------------------------- |
| 6.1  | `net + fee == gross`                | `59M + 1M == 60M`      | `56_333_333 + 1_444_444 == 57_777_777` |
| 6.3  | `feeShares * equity / total <= fee` | `999_999 <= 1_000_000` | `1_444_443 <= 1_444_444`               |
| 6.4  | `gross_back <= deposit`             | `50M <= 50M`           | `33_333_332 <= 33_333_333`             |
| 6.7  | `split_shares <= bulk_shares`       | `50M <= 50M`           | `29_962_545 <= 29_962_546`             |

### Section 10: E2E Deposit (sharesMinted, newTotal, newEquity)

| Test      | deposit           | equity            | totalShares       | minted              | newTotal            | newEquity           | Remainder         |
| --------- | ----------------- | ----------------- | ----------------- | ------------------- | ------------------- | ------------------- | ----------------- |
| 10.2 ugly | `37_123_456`      | `113_456_789`     | `98_765_432`      | `32_316_392`        | `131_081_824`       | `150_580_245`       | `100_787_704`     |
| 10.3 ugly | `41_111_111`      | `73_333_333`      | `100_000_000`     | `56_060_606`        | `156_060_606`       | `114_444_444`       | `12_020_202`      |
| 10.4 ugly | `27_654_321`      | `109_876_543`     | `98_765_432`      | `24_857_816`        | `123_623_248`       | `137_530_864`       | `71_621_584`      |
| 10.5 ugly | `88_888_888`      | `133_333_333`     | `100_000_000`     | `66_666_666`        | `166_666_666`       | `222_222_221`       | `22_222_222`      |
| 10.6 ugly | `55_555_555`      | `66_666_666`      | `100_000_000`     | `83_333_333`        | `183_333_333`       | `122_222_221`       | `22_222_222`      |
| 10.7 ugly | `4_987_654_321`   | `99_876_543`      | `100_000_000`     | `4_993_819_540`     | `5_093_819_540`     | ownerPct=`9`        | `78_949_780`      |
| 10.9 ugly | `999_999_999_999` | `777_777_777_773` | `888_888_888_881` | `1_142_857_142_852` | `2_031_746_031_733` | `1_777_777_777_772` | `682_539_682_523` |

### Section 11: E2E Withdrawal (gross, costBasis, fee, feeShares, net, newTotal)

| Test        | gross        | cb           | fee         | feeShares | net          | newTotal             |
| ----------- | ------------ | ------------ | ----------- | --------- | ------------ | -------------------- |
| 11.1 clean  | `60_000_000` | `50_000_000` | `1_000_000` | `833_333` | `59_000_000` | `50_833_333`         |
| 11.1 ugly   | `38_291_665` | `33_333_333` | `495_833`   | `431_628` | `37_795_832` | `65_863_727`         |
| 11.2 ugly   | `29_629_629` | `44_444_444` | `0`         | `0`       | `29_629_629` | `55_555_556`         |
| 11.3 clean  | `30_000_000` | `25_000_000` | `500_000`   | `416_666` | `29_500_000` | `75_416_666`         |
| 11.3 ugly   | `25_527_777` | `22_222_222` | `330_555`   | `287_751` | `25_197_222` | `76_830_961`         |
| 11.4 ugly   | `14_999_999` | `22_222_222` | `0`         | `0`       | `14_999_999` | `76_543_210`         |
| 11.5 ugly   | `22_499_999` | `22_222_222` | `27_777`    | `27_434`  | `22_472_222` | `76_570_644`         |
| 11.6 ugly   | `12_763_888` | `11_111_111` | `0` (owner) | `0`       | `12_763_888` | `87_654_321`         |
| 11.7 ugly   | `8_249_999`  | `11_111_111` | `0`         | `0`       | `8_249_999`  | `87_654_321`         |
| 11.8 ugly   | `11_249_999` | `11_111_111` | `0` (owner) | `0`       | `11_249_999` | `87_654_321`         |
| 11.9 ugly   | `1_977_776`  | —            | —           | —         | —            | ownerPct=`389` < 500 |
| 11.10 clean | `12_000_000` | `10_000_000` | `200_000`   | `166_666` | —            | ownerPct=`683`       |
| 11.10 ugly  | `12_763_888` | `11_111_111` | `165_277`   | `143_875` | —            | ownerPct=`649`       |
