use cardano/assets.{PolicyId}
use cardano/transaction.{Transaction}
use hydra_dex/types.{HydraAccountIntent, HydraOrderBookIntent}

validator always_succeed(_ai: HydraAccountIntent, _oi: HydraOrderBookIntent) {
  mint(_redeemer: Data, _policy_id: PolicyId, _tx: Transaction) {
    True
  }

  else(_) {
    fail @"unsupported purpose"
  }
}
