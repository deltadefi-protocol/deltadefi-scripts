use aiken/crypto.{VerificationKeyHash}
use cardano/script_context.{ScriptContext}
use cocktail.{key_signed}

validator always_succeed(owner: VerificationKeyHash, _msg: Data) {
  else(ctx: ScriptContext) {
    key_signed(ctx.transaction.extra_signatories, owner)
  }
}
