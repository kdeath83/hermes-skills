# Rationale Templates — Fill + Adapt

## Rationale #1: "Why do you think this is a task that frontier models would struggle with?"

**Structure:** Property → Mechanism → Span → Why it matters

```
<Specific property> makes this hard. <Mechanism> means the model has to <action>. 
The fix spans <files/layers>. This tests <capability frontier>.
```

**Fill table:**

| Element | Your answer |
|---------|-------------|
| **Property** | e.g. idempotency gap, concurrency race, subtle invariant, cross-service coupling |
| **Mechanism** | e.g. retry handler doesn't check uniqueness before insert |
| **What model must do** | e.g. trace end-to-end through 4 files, understand DB isolation level |
| **Span** | e.g. 6 files across webhook handler, DB layer, notification dispatch |
| **Capability frontier** | e.g. on-call debugging under realistic reproduction constraints |

**Weak ❌:** "It has some bugs and the model might not get them."
**Strong ✅:** "The webhook handler isn't idempotent and races on the ledger write under concurrent retries. Reproducing it means simulating concurrent events. The fix spans the retry logic and the DB transaction boundary. This represents on-call debugging a model might struggle with because it requires understanding two-phase commit patterns."

---

## Rationale #2: "What does this codebase do?"

**Structure:** Stack → Size → Purpose → Relevant modules

```
A <language/framework> service (~<N> files) that <purpose>, 
with modules for <modules relevant to your task>.
```

**Fill table:**

| Element | Your answer |
|---------|-------------|
| **Stack** | Python/FastAPI, Go, TypeScript/Next.js, Rust/Axum, etc. |
| **Size** | ~300 files, ~50k LOC |
| **Purpose** | e.g. ingests payment webhooks, manages tenant provisioning, handles real-time chat |
| **Key modules** | e.g. auth, webhook routing, batch processor, DB layer |

**Weak ❌:** "It's a web app."
**Strong ✅:** "A Python/FastAPI service (~300 files) that ingests payment webhooks and writes to a Postgres ledger, with modules for auth, webhook routing, and a nightly reconciliation cron. The task touches the webhook handler and reconciliation modules."

---

## Rationale #3: "What issues or gaps does the codebase have, and how would a developer get started on solving them?"

**Structure:** Gap → Consequence → First step

```
<Concrete gap>. This means <real consequence>. 
A developer would start by <specific action, usually a failing test>.
```

**Fill table:**

| Element | Your answer |
|---------|-------------|
| **Gap** | e.g. no dedup on retry, missing input validation, unhandled edge case |
| **Consequence** | e.g. duplicate DB records, silent data corruption, 5xx cascade |
| **First step** | e.g. writing a failing test that fires duplicate webhooks and asserts exactly one record created |

**Weak ❌:** "The code failed and the developer would look at the docs."
**Strong ✅:** "Events get processed twice on retry because the handler creates a record before checking uniqueness. A developer would start by writing a failing test that fires duplicate webhook payloads and asserts only one Event record is created, then add an idempotency key scoped to (event_id, source) inside the DB transaction."

---

## Anti-patterns — Get These Reviewed Out

| Pattern | Why rejected |
|---------|-------------|
| "It has bugs" | Generic, no mechanism |
| "The model might not understand the code" | Says nothing specific |
| "It's a <framework> app" | Too shallow, no module detail |
| "The developer would debug it" | No concrete first step |
| Bullet lists with no prose | Reads LLM-generated |
| Any answer that could apply to 10 different repos | Not repo-specific |