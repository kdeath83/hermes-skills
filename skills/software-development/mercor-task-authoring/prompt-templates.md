# Opening Prompt Templates — Interactive vs Async

## Interactive Mode (Pairing)

**Vibe:** Slack message to a senior teammate. High-level goal, realistic ambiguity, open-ended enough to need 5+ turns to nail down.

### Template — Debugging
```
We're seeing <symptom> in <environment/production> when <trigger>. 
Logs are showing <specific error/pattern>. 
I've traced it to <module/area> but not sure why <key behavior> happens.
Can you dig in? The fix should <constraint>.
```

**Filled example:**
```
We're seeing intermittent 503s on the /checkout endpoint in prod — spikes right 
after the daily deal flip at midnight UTC. Traced it to the inventory cache 
invalidation but I'm not sure why it's cascade-failing instead of just a slow 
page. Can you dig in? We need to keep the existing Redis key schema.
```

### Template — Feature Development
```
I need <capability> added to <module>. It should <core behavior>.
We'll need to handle <edge case>. Keep it consistent with how <existing pattern> 
works in the codebase. Let's iterate on this.
```

**Filled example:**
```
I need a utility for the migration progress tracker — it should log each batch 
size and ETA per shard. We'll need to handle the case where a shard is already 
locked by another migration. Keep it consistent with the existing logger pattern 
in lib/migration/. Let's iterate on this.
```

### Template — Code Review
```
Here's a PR adding <feature>. I'm especially worried about <area>.
Can you review the whole thing? Focus on correctness and <concern>.
```

**Filled example:**
```
Here's a PR adding SSO login via OIDC. I'm especially worried about session 
replay and token refresh race conditions. Can you review the whole thing? 
Focus on correctness and the auth middleware boundary.
```

---

## Async Mode (Autonomous)

**Vibe:** Self-contained ticket. Goal + acceptance criteria + constraints + verification upfront. No hand-holding.

### Template — Debugging
```
**Problem:** <symptom> occurs when <trigger>. Root cause is <area> but <complication>.

**Scope:**
- Investigate <component A> and <component B> end to end
- Implement a production-ready fix that <requirement>

**Constraints:**
- Must support <existing behavior> still working
- Backward compatible with <older clients / existing data>
- No broad refactors outside the affected area

**Verification:**
- <test 1: proves retries don't duplicate>
- <test 2: proves normal flow unaffected>
- Run the existing test suite in <module>
```

**Filled example:**
```
**Problem:** Webhook deliveries are not idempotent — when the HTTP client retries 
on timeout, the server creates duplicate Event records and fires duplicate 
notifications. Root cause is the handler creates before checking uniqueness.

**Scope:**
- Trace the full webhook delivery path: ingress → handler → notification dispatch
- Add an idempotency key on (event_id, source) at the DB transaction boundary
- Return the existing record on retry instead of creating a new one

**Constraints:**
- Existing webhook payload contract must not change
- No broad refactors outside webhook handler + DB layer
- Must support both clean first-attempt submissions and retries

**Verification:**
- Test that firing the same webhook payload twice produces one Event record
- Test that downstream notification is sent exactly once per unique event
- Test that genuinely different events still work independently
- Run the webhooks test suite + lint
```

### Template — Refactoring
```
**Goal:** Migrate <old pattern> to <new pattern> across the codebase.

**Scope:**
All files in <module> and <module> — full audit of usage patterns.

**Requirements:**
- <key transformation>
- <edge cases>
- Maintain public API surface unchanged

**Verification:**
- Existing test suite passes
- Visual/functional parity check for <component>
- No regressions in <benchmark/metric>
```

---

## Quick Reference: Mode Selection

| Signal | Interactive | Async |
|--------|-------------|-------|
| Prompt length | 3-8 sentences | Dense, covers all AC |
| Spec detail | High-level, let model ask | Full AC + constraints upfront |
| Ambiguity | Realistic, intentional | Minimal — self-contained |
| You interrupt? | Yes, steer as needed | No, model runs alone |
| Turns expected | 5+ | 1 (then review output) |
