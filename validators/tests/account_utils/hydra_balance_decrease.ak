use cardano/assets.{add, from_asset}
use cardano/transaction.{InlineDatum, Input}
use hydra_dex/account_utils.{hydra_balance_decrease}
use hydra_dex/types.{UserSpotAccount}
use mocktail.{mock_script_address, mock_script_output, mock_utxo_ref}
use tests/utils.{mock_account, mock_account_2}

test au_hbd_1() {
  let account = UserSpotAccount { account: mock_account }

  let start_balance =
    from_asset("", "", 1_000_000_000)
      |> add("unit2", "token2", 1_000_000_000)
  let decrease = from_asset("", "", 500_000_000)
  let end_balance =
    from_asset("", "", 500_000_000)
      |> add("unit2", "token2", 1_000_000_000)

  let input =
    Input {
      output_reference: mock_utxo_ref(0, 0),
      output: mock_script_output(
        mock_script_address(0, None),
        start_balance,
        InlineDatum(account),
      ),
    }
  let output =
    mock_script_output(
      mock_script_address(0, None),
      end_balance,
      InlineDatum(account),
    )

  hydra_balance_decrease(input, output, decrease)
}

test au_hbd_2() {
  let account = UserSpotAccount { account: mock_account }
  let start_balance =
    from_asset("", "", 1_000_000_000)
      |> add("unit2", "token2", 1_000_000_000)
  let decrease = from_asset("unit2", "token2", 1_000_000_000)
  let end_balance = from_asset("", "", 1_000_000_000)

  let input =
    Input {
      output_reference: mock_utxo_ref(0, 0),
      output: mock_script_output(
        mock_script_address(0, None),
        start_balance,
        InlineDatum(account),
      ),
    }
  let output =
    mock_script_output(
      mock_script_address(0, None),
      end_balance,
      InlineDatum(account),
    )

  hydra_balance_decrease(input, output, decrease)
}

test au_hbd_fail_diff_account() {
  let account1 = UserSpotAccount { account: mock_account }
  let account2 = UserSpotAccount { account: mock_account_2 }

  let start_balance =
    from_asset("", "", 1_000_000_000)
      |> add("unit2", "token2", 1_000_000_000)
  let decrease = from_asset("unit2", "token2", 1_000_000_000)
  let end_balance = from_asset("", "", 1_000_000_000)

  let input =
    Input {
      output_reference: mock_utxo_ref(0, 0),
      output: mock_script_output(
        mock_script_address(0, None),
        start_balance,
        InlineDatum(account1),
      ),
    }
  let output =
    mock_script_output(
      mock_script_address(0, None),
      end_balance,
      InlineDatum(account2),
    )

  !hydra_balance_decrease(input, output, decrease)
}
