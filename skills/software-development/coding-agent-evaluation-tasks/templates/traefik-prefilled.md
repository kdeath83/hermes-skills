Mercor Task Spec - Traefik (Prefilled)

Repository and Tags

Repo Name: traefik/traefik
GitHub URL: https://github.com/traefik/traefik
Primary Language: Go
Task Type: Debugging
Domain(s): Backend, DevOps/SRE
Interaction Mode: Interactive

Opening Prompt (Interactive Mode)

We're getting intermittent 503s in staging behind Traefik. Middleware chain is
RateLimit to Retry to CircuitBreaker to Backend.

Under load the backend times out and the circuit breaker trips open. That part
works. But instead of getting the 503 fallback fast, clients hang for 3 to 5
seconds before getting it. Looks like retry is piling attempts onto the open
circuit breaker. Each attempt gets a 503 back, then retry fires again. A retry
storm that delays the response and makes the circuit breaker metrics worse.

Can you trace the chain and figure out why retries keep hitting an open circuit?
Fix should stop retry from hammering the breaker once its open. Clients should
get the 503 fallback without the multi-second buildup.

Chain is on an HTTP router via file provider config.

Rationale 1: Why would frontier models struggle with this?

The middleware chain wraps handlers inside each other using the alice package.
Execution order is Retry then CircuitBreaker then Backend. The retry middleware
in pkg/middlewares/retry/retry.go grabs status codes from whatever comes next
and retries if the code matches. When the circuit breaker in
pkg/middlewares/circuitbreaker/circuit_breaker.go is open, it returns 503
immediately. The retry sees 503, matches it as retryable, and fires again
through the breaker. Which again returns 503. This loops.

The backoff timer (backoff.RetryNotify in retry.go around line 180) adds
exponential delay before each retry, so the storm gets worse as it goes.
The model has to trace through three packages, figure out that the breaker's
503 is a shortcut response not a backend error, then decide whether the fix
is changing middleware order or teaching retry to detect when it's talking
through an open breaker. Those are architecturally different fixes and the
model needs to understand both.

Rationale 2: What does this codebase do?

Traefik is a Go reverse proxy and load balancer people run in K8s and
containers. About 495 source files. The main directories under pkg/ are
middlewares (30 plus middleware types), server (entrypoints, router building,
load balancing), provider (config backends like Docker, K8s CRDs, Consul,
files), and config (dynamic config types). Middleware chains get built with
the containous/alice package where each wrapper calls the next. The files
you want for this task live in pkg/middlewares/retry/,
pkg/middlewares/circuitbreaker/, and pkg/server/router/ which wires the
chain together.

Rationale 3: What issues or gaps does the codebase have, and how would a
developer get started on solving them?

The retry middleware in retry.go around line 156 treats every response from
the next handler the same. It checks the status code and retries if it matches.
It has no clue whether that response came from the actual backend or from a
middleware upstream that intentionally cut the chain short. The circuit breaker
returns a 503 by default, same code a real backend failure would return.

To reproduce: write an integration test that sets up a Retry to CircuitBreaker
to Backend chain where the backend is configured to fail and trip the breaker.
Measure the roundtrip time after the breaker opens. Then trace through
retry.ServeHTTP to r.next.ServeHTTP, watch the breaker return 503, follow it
back to responseWriter.WriteHeader in retry.go around line 248 where shouldRetry
gets set. That confirms the root cause.

Pre-Submit Checklist

Repo is traefik/traefik, public, not on the restricted list
495 Go source files, production code used by thousands of orgs
Scenario is a known production issue with retry and circuit breaker interaction
Done means the client gets the 503 fallback without multi-second delay
Requires changes across retry, circuitbreaker, and possibly router packages
L5 level work since it needs understanding Go middleware chains and handler wrapping
Task type Debugging, matches the investigation work
Prompt is short and slack-like, fits interactive mode
All three rationales reference specific files, functions, and line numbers
AutoQC needs to pass before submit
