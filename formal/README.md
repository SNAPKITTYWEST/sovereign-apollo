# Formal Verification — Sovereign Apollo

See `docs/FORMAL_VERIFICATION.md` for property table.

Run:

```bash
cd formal && lake build
```

All modules separate **historical fact** (comments citing LUM099 pages) from **reconstructed model** (definitions) and **formal theorem** (theorems).

Current stubs use `sorry` where physical constants need full modeling; at least `State.lean`, `CommState.lean`, `ReplayDeterminism.lean` build sorry-free.

CI: `npm run verify:formal` checks `lake build` exit code.
