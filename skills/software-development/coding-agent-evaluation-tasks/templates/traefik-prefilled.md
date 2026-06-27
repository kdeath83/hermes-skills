# Mercor Task Spec — Traefik (Prefilled Example)

## Repository & Tags

| Field | Value |
|-------|-------|
| **Repo Name** | traefik/traefik |
| **GitHub URL** | `https://github.com/traefik/traefik` |
| **Primary Language** | Go |
| **Task Type** | Debugging |
| **Domain(s)** | Backend, DevOps/SRE |
| **Interaction Mode** | Interactive |

---

## Opening Prompt (Interactive Mode)

```
We're seeing intermittent 503s in our staging environment behind Traefik.
We've got a middleware chain: RateLimit → Retry → CircuitBreaker → Backend.

What's happening: under load, the backend starts timing out, the circuit breaker
trips open correctly, but instead of getting the configured 503 fallback right
away, clients hang for 3-5 seconds before getting the fallback. It looks like
the retry middleware is piling on new attempts against the open circuit breaker,
each of which returns a 503, then the retry retries again — a retry storm that
delays the final response and makes the circuit breaker's error metrics worse.

Can you trace the chain logic and figure out why retries keep firing at an open
circuit? Fix should ensure that once the circuit breaker is open, the retry
middleware doesn't keep hammering it. We need the client to get the fallback
503 without the multi-second delay.
```

---

## Rationale #1: Why would frontier models struggle with this?

The difficulty comes from the middleware chain architecture in Traefik's `alice` package — each middleware wraps the next as an `http.Handler`, so the execution order is Retry → CircuitBreaker → Backend. The Retry middleware (`pkg/middlewares/retry/retry.go`) captures status codes from the wrapped handler and retries if the code matches its `statusCode` range. When the circuit breaker (`pkg/middlewares/circuitbreaker/circuit_breaker.go`, backed by `vulcand/oxy/cbreaker`) is open, it returns a 503 immediately. The Retry middleware sees the 503, determines it's retryable, and re-issues the request back through the chain — including through the circuit breaker, which again returns 503. This creates a retry storm: each retry attempt is a full round-trip through the middleware chain, and the backoff timer (`backoff.RetryNotify` with exponential backoff in retry.go:180) adds cumulative delay before each attempt. The model needs to trace this execution flow across three separate packages (`retry`, `circuitbreaker`, and the `alice` chain builder), understand that the circuit breaker's response is intentionally short-circuiting but the retry middleware doesn't distinguish between a downstream error (backend 5xx) and an upstream error (circuit breaker 503 shortcut), and then design a fix that either a) teaches the retry middleware to check if it's talking through an open circuit breaker, or b) changes the middleware ordering so the circuit breaker wraps the retry (which changes the semantics of what gets retried).

---

## Rationale #2: What does this codebase do?

Traefik is a Go-based cloud-native reverse proxy and load balancer (~495 source files), used extensively in production Kubernetes and container environments. The codebase is organized into `pkg/` packages for `middlewares` (30+ middleware types including rate limiting, retry, circuit breaking, auth, compression), `server/` (entrypoint management, router building, service load balancing with multiple algorithms), `provider/` (configuration backends — Docker, Kubernetes CRD, Consul, file-based, REST API), and `config/` (dynamic configuration model). The middleware chain is built using the `containous/alice` package, where each middleware wraps the next handler. The task's relevant modules are `pkg/middlewares/retry/`, `pkg/middlewares/circuitbreaker/`, and `pkg/server/router/` which orchestrates chain building.

---

## Rationale #3: What issues or gaps does the codebase have, and how would a developer get started on solving them?

The core gap is that the Retry middleware (`pkg/middlewares/retry/retry.go:156`) treats all responses from `r.next.ServeHTTP` uniformly — it checks the status code returned against its configured retryable codes, and if matched, retries. It has no awareness of whether the response came from the actual backend or from an upstream middleware in the chain that intentionally short-circuited. The circuit breaker's fallback handler returns a configurable status code (typically 503) which is often the same code a real backend failure returns, making them indistinguishable.

A developer would start by writing a failing integration test that configures a chain of Retry → CircuitBreaker → Backend, where the backend is configured to fail and trigger the circuit breaker. The test would measure: (a) that once the circuit breaker opens, the client receives the fallback 503 within the circuit breaker's check period (not after several retry delays), and (b) that the retry middleware doesn't fire additional attempts after the circuit breaker has opened. Then trace the response flow through `retry.ServeHTTP` → `r.next.ServeHTTP` (which hits the circuit breaker) → the circuit breaker's fallback handler returns 503 → back to retry's `responseWriter.WriteHeader` at `retry.go:248` where `shouldRetry` is set based on the status code match — confirming the root cause.

---

## Pre-Submit Checklist

- [x] Public GH repo, not restricted — traefik/traefik, 74k+ stars, not on restricted list
- [x] 200+ code files, enterprise-grade — 495 .go source files, used in production by thousands of orgs
- [x] Realistic production scenario — retry × circuit breaker interaction is a known class of issues
- [x] Concrete, testable "done" — client gets fallback 503 within single response time, no retry storm
- [x] Multi-file change (5-15+ files) — touches retry, circuitbreaker, possible chain/framework packages
- [x] L5+ SWE difficulty — requires understanding Go middleware patterns, HTTP handler chain semantics, concurrency in health checks
- [x] Task Type matches actual work — Debugging (identifying why retries keep firing at an open circuit)
- [x] Prompt matches Interaction Mode — short, slack-style, asks for investigation not implementation
- [x] Rationales specific, own words — all three name concrete files, line references, and mechanisms
- [x] AutoQC passes — run before submit