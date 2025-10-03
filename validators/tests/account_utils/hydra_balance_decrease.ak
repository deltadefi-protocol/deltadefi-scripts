use cardano/assets.{add, from_asset, zero}
use cardano/transaction.{InlineDatum, Input}
use hydra_dex/account_utils.{hydra_balance_decrease}
use hydra_dex/types.{HydraAccountBalanceDatum, MValue, UserSpotAccount}
use mocktail.{mock_script_address, mock_script_output, mock_utxo_ref}
use tests/utils.{mock_account, mock_account_2, to_mvalue}

test au_hbd_1() {
  let start_balance: MValue =
    from_asset("", "", 1_000_000_000)
      |> add("unit2", "token2", 1_000_000_000)
      |> to_mvalue()
  let decrease = from_asset("", "", 500_000_000)
  let end_balance: MValue =
    from_asset("", "", 500_000_000)
      |> add("unit2", "token2", 1_000_000_000)
      |> to_mvalue()

  let input_datum =
    HydraAccountBalanceDatum {
      account: UserSpotAccount { account: mock_account },
      balance: start_balance,
    }
  let output_datum =
    HydraAccountBalanceDatum {
      account: UserSpotAccount { account: mock_account },
      balance: end_balance,
    }

  let input =
    Input {
      output_reference: mock_utxo_ref(0, 0),
      output: mock_script_output(
        mock_script_address(0, None),
        zero,
        InlineDatum(input_datum),
      ),
    }
  let output =
    mock_script_output(
      mock_script_address(0, None),
      zero,
      InlineDatum(output_datum),
    )

  hydra_balance_decrease(input, output, decrease)
}

test au_hbd_2() {
  let start_balance: MValue =
    from_asset("", "", 1_000_000_000)
      |> add("unit2", "token2", 1_000_000_000)
      |> to_mvalue()
  let decrease = from_asset("unit2", "token2", 1_000_000_000)
  let end_balance: MValue =
    from_asset("", "", 1_000_000_000)
      |> to_mvalue()

  let input_datum =
    HydraAccountBalanceDatum {
      account: UserSpotAccount { account: mock_account },
      balance: start_balance,
    }
  let output_datum =
    HydraAccountBalanceDatum {
      account: UserSpotAccount { account: mock_account },
      balance: end_balance,
    }

  let input =
    Input {
      output_reference: mock_utxo_ref(0, 0),
      output: mock_script_output(
        mock_script_address(0, None),
        zero,
        InlineDatum(input_datum),
      ),
    }
  let output =
    mock_script_output(
      mock_script_address(0, None),
      zero,
      InlineDatum(output_datum),
    )

  hydra_balance_decrease(input, output, decrease)
}

test au_hbd_fail_diff_account() {
  let start_balance: MValue =
    from_asset("", "", 1_000_000_000)
      |> add("unit2", "token2", 1_000_000_000)
      |> to_mvalue()
  let decrease = from_asset("unit2", "token2", 1_000_000_000)
  let end_balance: MValue =
    from_asset("", "", 1_000_000_000)
      |> to_mvalue()

  let input_datum =
    HydraAccountBalanceDatum {
      account: UserSpotAccount { account: mock_account },
      balance: start_balance,
    }
  let output_datum =
    HydraAccountBalanceDatum {
      account: UserSpotAccount { account: mock_account_2 },
      balance: end_balance,
    }

  let input =
    Input {
      output_reference: mock_utxo_ref(0, 0),
      output: mock_script_output(
        mock_script_address(0, None),
        zero,
        InlineDatum(input_datum),
      ),
    }
  let output =
    mock_script_output(
      mock_script_address(0, None),
      zero,
      InlineDatum(output_datum),
    )

  !hydra_balance_decrease(input, output, decrease)
}
