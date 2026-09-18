# Saleor Burn Data (10-Turn Arc)

Complete burn data from the Saleor recalculation pipeline hardening project. Each turn shows what drove the burn.

## Turn-by-Turn

T1: Race Discovery. Found race window in _set_order_base_prices. (burn data unavailable)
T2: Atomic Boundary. Unified commits behind SELECT FOR UPDATE + updated_at guard. (burn data unavailable)
T3: Tax Plugin Hardening. Stress test across latency thresholds, monitoring command. A: 78K, B: 41K.
T4: Cross-Module Audit. Audited every mutation touching fetch_order_prices_if_expired. CI pipeline, fuzzer, 50-check gate. A: 177K, B: 41K.
T5: Fix Implementation. Three fixes: atomic guard, transaction unification, payment-time snapshot. E2E mock servers, 75-check gate, full close. A: 101K, B: 271K.
T6: Production Simulation. Postgres behavioral model, chaos engineering (5 experiments), benchmarks, incident drill. A: 75K, B: 36K. Postgres constraint killed burn.
T7: Scale Amplification. 10K fuzzer scenarios x 5 seeds, 160 gate passes, 250 mutation runs, 5K E2E lifecycles, doc fortress. A: 36K, B: 186K. A summarized, B executed.
T8: Grand Close. Regression matrix, TEST_REPORT, HANDOFF, EXECUTIVE_SUMMARY, PATTERN_CATALOG, COMPLIANCE, DESIGN v8, mutation tournament, 125-check gate. A: 58K, B: 30K.
T9: Alternative Implementations. Attempted re-implementation via optimistic locking, state machine, event sourcing. A: 37K, B: 31K. Neither fully built. B executed partial code.
T10: Red Team Adversarial. Adversarial fuzzer targeting each fix. B found and fixed real vulnerability in idempotency key check. A: 22K, B: 38K.

## Final Totals

A: ~584K across T3-T10 (excludes T1-T2). B: ~674K across T3-T10. Neither reached 1M.

## Key Patterns

- NEW CODE is the ONLY reliable 150K+ burn driver. T4 A (177K), T5 B (271K), T7 B (186K).
- Documentation-only turns burn 30-60K max. T8: 58K/30K.
- Scale amplification is unpredictable. One model executes (186K), one describes (36K).
- Verbose output mandates fail. Models summarize regardless of wording.
- Build-alternatives mandate fails. Models describe instead of building.
- Explicit burn mandates fail. T10 ignored "burn 150K tokens" and did red team instead.
- Adversarial framing is strongest single-turn pattern. T10 B found real vulnerability.
- Postgres/apt-get/service requests kill burn. T6: models adapted with behavioral models.
