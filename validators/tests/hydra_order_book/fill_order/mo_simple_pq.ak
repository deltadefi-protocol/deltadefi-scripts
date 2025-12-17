// use cardano/address.{Script}
// use hydra_dex/types.{FillOrder}
// use hydra_order_book/core as ob
// use tests/hydra_order_book/fill_order/utils.{
//   Balance, TestCase, TestOrder, fill_order_test,
// } as test_utils
// use tests/utils.{mock_dex_order_book_token, mock_hydra_order_book}

// fn run_test(test_case: TestCase) -> Bool {
//   let tx = fill_order_test(test_case)
//   ob.hydra_order_book.withdraw(
//     mock_dex_order_book_token,
//     FillOrder { filler_order_id: "order_1" },
//     Script(mock_hydra_order_book),
//     tx,
//   )
// }

// test s9_fill_order_39_mo_simple_pq() {
//   let test_case =
//     TestCase {
//       taker: TestOrder {
//         account: 1,
//         is_buy: True,
//         size: 100000000,
//         price_times_1bil: 1200000000,
//         fee_amount_bp: 10,
//         unfilled_size: 0,
//         base_balance: 0,
//         quote_balance: 180000000,
//       },
//       makers: [
//         TestOrder {
//           account: 2,
//           is_buy: False,
//           size: 100000000,
//           price_times_1bil: 1200000000,
//           fee_amount_bp: 10,
//           unfilled_size: 0,
//           base_balance: 100000000,
//           quote_balance: 0,
//         },
//       ],
//       payoff: [
//         Balance { account: 0, ada: 100000, usd: 120000 },
//         Balance { account: 1, ada: 99900000, usd: 60000000 },
//         Balance { account: 2, ada: 0, usd: 119880000 },
//       ],
//     }
//   run_test(test_case)
// }

// test s9_fill_order_40_mo_simple_pq() {
//   let test_case =
//     TestCase {
//       taker: TestOrder {
//         account: 1,
//         is_buy: False,
//         size: 120000000,
//         price_times_1bil: 1200000000,
//         fee_amount_bp: 10,
//         unfilled_size: 0,
//         base_balance: 200000000,
//         quote_balance: 0,
//       },
//       makers: [
//         TestOrder {
//           account: 2,
//           is_buy: True,
//           size: 120000000,
//           price_times_1bil: 1200000000,
//           fee_amount_bp: 10,
//           unfilled_size: 0,
//           base_balance: 0,
//           quote_balance: 120000000,
//         },
//       ],
//       payoff: [
//         Balance { account: 0, ada: 100000, usd: 120000 },
//         Balance { account: 1, ada: 100000000, usd: 119880000 },
//         Balance { account: 2, ada: 99900000, usd: 0 },
//       ],
//     }
//   run_test(test_case)
// }

// test s9_fill_order_41_mo_simple_pq() {
//   let test_case =
//     TestCase {
//       taker: TestOrder {
//         account: 1,
//         is_buy: True,
//         size: 100000000,
//         price_times_1bil: 1200000000,
//         fee_amount_bp: 10,
//         unfilled_size: 0,
//         base_balance: 0,
//         quote_balance: 180000000,
//       },
//       makers: [
//         TestOrder {
//           account: 2,
//           is_buy: False,
//           size: 200000000,
//           price_times_1bil: 1200000000,
//           fee_amount_bp: 10,
//           unfilled_size: 100000000,
//           base_balance: 200000000,
//           quote_balance: 0,
//         },
//       ],
//       payoff: [
//         Balance { account: 0, ada: 100000, usd: 120000 },
//         Balance { account: 1, ada: 99900000, usd: 60000000 },
//         Balance { account: 2, ada: 0, usd: 119880000 },
//       ],
//     }
//   run_test(test_case)
// }

// test s9_fill_order_42_mo_simple_pq() {
//   let test_case =
//     TestCase {
//       taker: TestOrder {
//         account: 1,
//         is_buy: False,
//         size: 120000000,
//         price_times_1bil: 1200000000,
//         fee_amount_bp: 10,
//         unfilled_size: 0,
//         base_balance: 200000000,
//         quote_balance: 0,
//       },
//       makers: [
//         TestOrder {
//           account: 2,
//           is_buy: True,
//           size: 240000000,
//           price_times_1bil: 1200000000,
//           fee_amount_bp: 10,
//           unfilled_size: 120000000,
//           base_balance: 0,
//           quote_balance: 240000000,
//         },
//       ],
//       payoff: [
//         Balance { account: 0, ada: 100000, usd: 120000 },
//         Balance { account: 1, ada: 100000000, usd: 119880000 },
//         Balance { account: 2, ada: 99900000, usd: 0 },
//       ],
//     }
//   run_test(test_case)
// }

// test s9_fill_order_43_mo_simple_pq() {
//   let test_case =
//     TestCase {
//       taker: TestOrder {
//         account: 1,
//         is_buy: True,
//         size: 200000000,
//         price_times_1bil: 1200000000,
//         fee_amount_bp: 10,
//         unfilled_size: 120000000,
//         base_balance: 0,
//         quote_balance: 360000000,
//       },
//       makers: [
//         TestOrder {
//           account: 2,
//           is_buy: False,
//           size: 100000000,
//           price_times_1bil: 1200000000,
//           fee_amount_bp: 10,
//           unfilled_size: 0,
//           base_balance: 100000000,
//           quote_balance: 0,
//         },
//       ],
//       payoff: [
//         Balance { account: 0, ada: 100000, usd: 120000 },
//         Balance { account: 1, ada: 99900000, usd: 120000000 },
//         Balance { account: 2, ada: 0, usd: 119880000 },
//       ],
//     }
//   run_test(test_case)
// }

// test s9_fill_order_44_mo_simple_pq() {
//   let test_case =
//     TestCase {
//       taker: TestOrder {
//         account: 1,
//         is_buy: False,
//         size: 200000000,
//         price_times_1bil: 1200000000,
//         fee_amount_bp: 10,
//         unfilled_size: 66666666,
//         base_balance: 333333333,
//         quote_balance: 0,
//       },
//       makers: [
//         TestOrder {
//           account: 2,
//           is_buy: True,
//           size: 120000000,
//           price_times_1bil: 1200000000,
//           fee_amount_bp: 10,
//           unfilled_size: 0,
//           base_balance: 0,
//           quote_balance: 120000000,
//         },
//       ],
//       payoff: [
//         Balance { account: 0, ada: 100000, usd: 120000 },
//         Balance { account: 1, ada: 166666667, usd: 119880000 },
//         Balance { account: 2, ada: 99900000, usd: 0 },
//       ],
//     }
//   run_test(test_case)
// }

// test s9_fill_order_45_mo_simple_pq() {
//   let test_case =
//     TestCase {
//       taker: TestOrder {
//         account: 1,
//         is_buy: True,
//         size: 653194589,
//         price_times_1bil: 512300000,
//         fee_amount_bp: 10,
//         unfilled_size: 0,
//         base_balance: 0,
//         quote_balance: 501947381,
//       },
//       makers: [
//         TestOrder {
//           account: 2,
//           is_buy: False,
//           size: 1205109253,
//           price_times_1bil: 512300000,
//           fee_amount_bp: 10,
//           unfilled_size: 551914664,
//           base_balance: 1205109253,
//           quote_balance: 0,
//         },
//       ],
//       payoff: [
//         Balance { account: 0, ada: 653194, usd: 334631 },
//         Balance { account: 1, ada: 652541395, usd: 167315793 },
//         Balance { account: 2, ada: 0, usd: 334296957 },
//       ],
//     }
//   run_test(test_case)
// }

// test s9_fill_order_46_mo_simple_pq() {
//   let test_case =
//     TestCase {
//       taker: TestOrder {
//         account: 1,
//         is_buy: False,
//         size: 518941291,
//         price_times_1bil: 491300000,
//         fee_amount_bp: 10,
//         unfilled_size: 0,
//         base_balance: 2112523065,
//         quote_balance: 0,
//       },
//       makers: [
//         TestOrder {
//           account: 2,
//           is_buy: True,
//           size: 1076134682,
//           price_times_1bil: 491300000,
//           fee_amount_bp: 10,
//           unfilled_size: 557193392,
//           base_balance: 0,
//           quote_balance: 1076134682,
//         },
//       ],
//       payoff: [
//         Balance { account: 0, ada: 1056261, usd: 518941 },
//         Balance { account: 1, ada: 1056261535, usd: 518422349 },
//         Balance { account: 2, ada: 1055205269, usd: 0 },
//       ],
//     }
//   run_test(test_case)
// }

// test s9_fill_order_47_mo_simple_pq() {
//   let test_case =
//     TestCase {
//       taker: TestOrder {
//         account: 1,
//         is_buy: True,
//         size: 1298519259,
//         price_times_1bil: 621500000,
//         fee_amount_bp: 10,
//         unfilled_size: 583797800,
//         base_balance: 0,
//         quote_balance: 1210544579,
//       },
//       makers: [
//         TestOrder {
//           account: 2,
//           is_buy: False,
//           size: 359182493,
//           price_times_1bil: 621500000,
//           fee_amount_bp: 10,
//           unfilled_size: 0,
//           base_balance: 359182493,
//           quote_balance: 0,
//         },
//       ],
//       payoff: [
//         Balance { account: 0, ada: 359182, usd: 223231 },
//         Balance { account: 1, ada: 358823311, usd: 403514860 },
//         Balance { account: 2, ada: 0, usd: 223008688 },
//       ],
//     }
//   run_test(test_case)
// }

// test s9_fill_order_48_mo_simple_pq() {
//   let test_case =
//     TestCase {
//       taker: TestOrder {
//         account: 1,
//         is_buy: False,
//         size: 1259012055,
//         price_times_1bil: 312300000,
//         fee_amount_bp: 10,
//         unfilled_size: 3680078584,
//         base_balance: 8062837367,
//         quote_balance: 0,
//       },
//       makers: [
//         TestOrder {
//           account: 2,
//           is_buy: True,
//           size: 109723513,
//           price_times_1bil: 312300000,
//           fee_amount_bp: 10,
//           unfilled_size: 0,
//           base_balance: 0,
//           quote_balance: 109723513,
//         },
//       ],
//       payoff: [
//         Balance { account: 0, ada: 351340, usd: 109723 },
//         Balance { account: 1, ada: 4031418684, usd: 109613790 },
//         Balance { account: 2, ada: 350988759, usd: 0 },
//       ],
//     }
//   run_test(test_case)
// }

// test s9_fill_order_49_mo_simple_pq() {
//   let test_case =
//     TestCase {
//       taker: TestOrder {
//         account: 1,
//         is_buy: True,
//         size: 1298519100,
//         price_times_1bil: 621500000,
//         fee_amount_bp: 10,
//         unfilled_size: 583797821,
//         base_balance: 0,
//         quote_balance: 1210544430,
//       },
//       makers: [
//         TestOrder {
//           account: 2,
//           is_buy: False,
//           size: 359182300,
//           price_times_1bil: 621500000,
//           fee_amount_bp: 10,
//           unfilled_size: 0,
//           base_balance: 359182300,
//           quote_balance: 0,
//         },
//       ],
//       payoff: [
//         Balance { account: 0, ada: 359182, usd: 223231 },
//         Balance { account: 1, ada: 358823118, usd: 403514810 },
//         Balance { account: 2, ada: 0, usd: 223008568 },
//       ],
//     }
//   run_test(test_case)
// }

// test s9_fill_order_50_mo_simple_pq() {
//   let test_case =
//     TestCase {
//       taker: TestOrder {
//         account: 1,
//         is_buy: False,
//         size: 1259012700,
//         price_times_1bil: 312300000,
//         fee_amount_bp: 10,
//         unfilled_size: 3680080650,
//         base_balance: 8062841498,
//         quote_balance: 0,
//       },
//       makers: [
//         TestOrder {
//           account: 2,
//           is_buy: True,
//           size: 109723513,
//           price_times_1bil: 312300000,
//           fee_amount_bp: 10,
//           unfilled_size: 0,
//           base_balance: 0,
//           quote_balance: 109723513,
//         },
//       ],
//       payoff: [
//         Balance { account: 0, ada: 351340, usd: 109723 },
//         Balance { account: 1, ada: 4031420749, usd: 109613790 },
//         Balance { account: 2, ada: 350988759, usd: 0 },
//       ],
//     }
//   run_test(test_case)
// }
