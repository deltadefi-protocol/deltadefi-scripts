use cardano/assets.{from_asset}
use cardano/transaction.{Transaction}
use hydra_dex/types.{
  BurnAtCombineOrderBook, BurnAtHydraClose, BurnAtWithdrawal, CombineOrderMerkle,
  FullTree, MPFInsert, MintAtCancelWithdrawal, MintAtHydraOpen,
  MintAtInitOrderBook, ProcessCancelWithdrawal, ProcessCombineUtxosAtClose,
  ProcessSplitUtxosAtOpen, ProcessWithdrawal, SplitOrderMerkle, TreeBranch,
  TreeOrProofsWithTokenMap,
}
use hydra_tokens as ht
use mocktail.{
  complete, mock_tx_hash, mocktail_tx, ref_tx_in, ref_tx_in_inline_datum,
  script_withdrawal, withdrawal_redeemer_value,
}
use tests/utils.{
  mock_dex_order_book_address, mock_dex_order_book_datum,
  mock_dex_order_book_token, mock_hydra_account, mock_hydra_order_book,
  mock_hydra_token_policy_id, mock_token_map,
}

const tree =
  TreeOrProofsWithTokenMap {
    proof: FullTree { tree: TreeBranch { nibble: #"", nodes: [] } },
    token_map: mock_token_map,
  }

type TestCase {
  hydra_head_open: Bool,
  hydra_head_close: Bool,
  withdrawal: Bool,
  cancel_withdrawal: Bool,
  init_order_book: Bool,
  combine_order_book: Bool,
}

fn mock_tx(test_case: TestCase) -> Transaction {
  let TestCase {
    hydra_head_open,
    hydra_head_close,
    withdrawal,
    cancel_withdrawal,
    init_order_book,
    combine_order_book,
  } = test_case

  mocktail_tx()
    |> ref_tx_in(
        True,
        mock_tx_hash(0),
        0,
        from_asset(mock_dex_order_book_token, "", 1),
        mock_dex_order_book_address,
      )
    |> ref_tx_in_inline_datum(True, mock_dex_order_book_datum)
    |> script_withdrawal(
        hydra_head_open || hydra_head_close || withdrawal || cancel_withdrawal,
        mock_hydra_account,
        0,
      )
    |> withdrawal_redeemer_value(
        hydra_head_open,
        ProcessSplitUtxosAtOpen { tree_or_proofs_with_token_map: tree },
      )
    |> withdrawal_redeemer_value(
        hydra_head_close,
        ProcessCombineUtxosAtClose { tree_or_proofs_with_token_map: tree },
      )
    |> withdrawal_redeemer_value(
        withdrawal,
        ProcessWithdrawal { mpf_action: MPFInsert { proof: [] } },
      )
    |> withdrawal_redeemer_value(
        cancel_withdrawal,
        ProcessCancelWithdrawal { mpf_action: MPFInsert { proof: [] } },
      )
    |> script_withdrawal(
        init_order_book || combine_order_book,
        mock_hydra_order_book,
        0,
      )
    |> withdrawal_redeemer_value(
        init_order_book,
        SplitOrderMerkle { tree_or_proofs_with_token_map: tree },
      )
    |> withdrawal_redeemer_value(
        combine_order_book,
        CombineOrderMerkle { tree_or_proofs_with_token_map: tree },
      )
    |> complete()
}

test s10_hydra_tokens_mint_at_hydra_open() {
  let tx =
    mock_tx(
      TestCase {
        hydra_head_open: True,
        hydra_head_close: False,
        withdrawal: False,
        cancel_withdrawal: False,
        init_order_book: False,
        combine_order_book: False,
      },
    )

  ht.hydra_tokens.mint(
    mock_dex_order_book_token,
    MintAtHydraOpen,
    mock_hydra_token_policy_id,
    tx,
  )
}

test s10_hydra_tokens_burn_at_hydra_close() {
  let tx =
    mock_tx(
      TestCase {
        hydra_head_open: False,
        hydra_head_close: True,
        withdrawal: False,
        cancel_withdrawal: False,
        init_order_book: False,
        combine_order_book: False,
      },
    )

  ht.hydra_tokens.mint(
    mock_dex_order_book_token,
    BurnAtHydraClose,
    mock_hydra_token_policy_id,
    tx,
  )
}

test s10_hydra_tokens_mint_at_cancel_withdrawal() {
  let tx =
    mock_tx(
      TestCase {
        hydra_head_open: False,
        hydra_head_close: False,
        withdrawal: False,
        cancel_withdrawal: True,
        init_order_book: False,
        combine_order_book: False,
      },
    )

  ht.hydra_tokens.mint(
    mock_dex_order_book_token,
    MintAtCancelWithdrawal,
    mock_hydra_token_policy_id,
    tx,
  )
}

test s10_hydra_tokens_burn_at_withdrawal() {
  let tx =
    mock_tx(
      TestCase {
        hydra_head_open: False,
        hydra_head_close: False,
        withdrawal: True,
        cancel_withdrawal: False,
        init_order_book: False,
        combine_order_book: False,
      },
    )

  ht.hydra_tokens.mint(
    mock_dex_order_book_token,
    BurnAtWithdrawal,
    mock_hydra_token_policy_id,
    tx,
  )
}

test s10_hydra_tokens_mint_at_init_order_book() {
  let tx =
    mock_tx(
      TestCase {
        hydra_head_open: False,
        hydra_head_close: False,
        withdrawal: False,
        cancel_withdrawal: False,
        init_order_book: True,
        combine_order_book: False,
      },
    )

  ht.hydra_tokens.mint(
    mock_dex_order_book_token,
    MintAtInitOrderBook,
    mock_hydra_token_policy_id,
    tx,
  )
}

test s10_hydra_tokens_burn_at_combine_order_book() {
  let tx =
    mock_tx(
      TestCase {
        hydra_head_open: False,
        hydra_head_close: False,
        withdrawal: False,
        cancel_withdrawal: False,
        init_order_book: False,
        combine_order_book: True,
      },
    )

  ht.hydra_tokens.mint(
    mock_dex_order_book_token,
    BurnAtCombineOrderBook,
    mock_hydra_token_policy_id,
    tx,
  )
}
