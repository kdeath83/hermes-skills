Task: Traefik - Retry storm against open circuit breaker
Repo: traefik/traefik (Go, 495 files)
Max time: 150 minutes per model

Q1: Task Goal

The high level goal for this task is for the coding model to debug a moderately complex codebase that serves as a http reverse proxy and load balancer. The context here is there is an observed retry storm under rate limit / retry condition, which indicates some form of chain logic error. The models are expected to understand the codebase and context, then trace the logic and ultimately resolve the observed errors. The primary success criteria would be the timely resolution of error (sub 150min), effective resolution of observed 503 errors with minimal delay (sub 1000ms) and avoidance of retry storm (binary yes/no).

Q2: Why would frontier models struggle with this?

This task involves a complex logic chain between frontend/backend/middleware. The resolution needs to be contextual to the repo's goals under strict performance requirements.
The difficulty comes from the middleware chain architecture in Traefik's alice package where each middleware wraps the next as an http.Handler. The execution order is Retry to CircuitBreaker to Backend. The Retry middleware (in pkg/middlewares/retry/retry.go) captures status codes from the wrapped handler and retries if the code matches its statusCode range. When the circuit breaker (in pkg/middlewares/circuitbreaker/circuit_breaker.go, backed by vulcand/oxy/cbreaker) is open, it returns a 503 immediately. The Retry middleware sees the 503, determines it's retryable, and re-issues the request back through the chain including  the circuit breaker, which again returns 503. This creates a retry storm. Each retry attempt is a full round-trip through the middleware chain, and the backoff timer (backoff.RetryNotify with exponential backoff in retry.go line 180) adds cumulative delay before each attempt.
The models need to trace this execution flow across three separate packages (retry, circuitbreaker, and the alice chain builder) then understand that the circuit breaker's response is intentionally short-circuiting but the retry middleware doesn't distinguish between a downstream error (backend 5xx) and an upstream error (circuit breaker 503 shortcut), and then design a fix that either teaches the retry middleware to check if it's talking through an open circuit breaker, or changes the middleware ordering so the circuit breaker wraps the retry.

Q3: What does this codebase do?

Traefik is a Go-based cloud-native reverse proxy and load balancer. Traefik is an enterprise solution that is used wthin production Kubernetes and container environments. The codebase consists of ~490 files and is organized into pkg/ packages for middlewares (30+ middleware types including rate limiting, retry, circuit breaking, auth, compression), server/ (entrypoint management, router building, service load balancing with multiple algorithms), provider/ (configuration backends - Docker, Kubernetes CRD, Consul, file-based, REST API), and config/ (dynamic configuration model). The middleware chain is built using the containous/alice package, where each middleware wraps the next handler. The task's relevant modules are pkg/middlewares/retry/, pkg/middlewares/circuitbreaker/, and pkg/server/router/ which orchestrates chain building.

Q4: What issues or gaps does the codebase have, and how would a developer get started on solving them?

The core gap is that the Retry middleware (pkg/middlewares/retry/retry.go line 156) treats all responses from r.next.ServeHTTP uniformly. It checks the status code returned against its configured retryable codes, and if matched it retries. The Retry middleware has no awareness of whether the response came from the actual backend or from an upstream middleware in the chain that has short-circuited. The circuit breaker's fallback handler returns a configurable status code  (503) which is often the same code a real backend failure returns, which can confuse.
A L4/5 SWE  should start by writing a failing integration test that configures a chain of Retry to CircuitBreaker to Backend, where the backend is configured to intentionally fail and trigger the circuit breaker. The test would measure
1\ the circuit breaker opens, the client receives the fallback 503 within the circuit breaker's check period and
2\ the retry middleware doesn't fire additional attempts after the circuit breaker has opened.
SWE should then trace the response flow through retry.ServeHTTP to r.next.ServeHTTP to the circuit breaker's fallback handler returning 503 and back to retry's responseWriter.WriteHeader at retry.go line 248 where shouldRetry is set based on the status code match which confirms the root cause.

--- Model A

Model Name:
Start:
End:
Total:

Prompt A1 - Opening (auto-injected, identical for both)

We're seeing intermittent 503s in our staging environment behind Traefik. We've got a middleware chain: RateLimit to Retry to CircuitBreaker to Backend. Under load, the backend starts timing out.... the circuit breaker trips open correctly, but instead of getting the configured 503 fallback right away, clients hang for 3-5 seconds before getting the fallback. It looks like the retry middleware is piling on new attempts against the open circuit breaker, each of which returns a 503, then the retry retries again. This is causing a retry storm delays the final response and makes the circuit breaker's error metrics worse.
Can you trace the chain logic and figure out why retries keep firing at an open circuit? The fix should ensure that once the circuit breaker is open, the retry middleware doesn't keep hammering it. We need the client to get the fallback 503 without a multi-second delay.
The chain is configured on an HTTP router in Traefik config, using standard dynamic config through a file provider.

Prompt A2 - Reproduce first

Before changing anything, reproduce it. What is the smallest test that sets up the Retry to CircuitBreaker to Backend chain, trips the breaker, and shows the retry storm? If you cannot reproduce it deterministically, say so and explain exactly what you would need to observe it.

Prompt A3 - Trace the path

Now trace what happens to the response once the circuit breaker opens. Follow it from the breaker's fallback handler back through the retry middleware. Why does retry treat the breaker's 503 as retryable, and what does it do with it?

Prompt A4 - Implement

Implement the minimal fix now that you have traced the path.

Prompt A5 - Code review

Please review the code generated for logic, performance and security bugs. produce a report in MD format with findings rated by critical, high and low. make sure each finding explicitly states the filename, filepath and line number and the suggested fix.

Prompt A6 - Verify

Write the test that proves it:
- with Retry before CircuitBreaker, once the breaker is open the client receives the fallback 503 within the breaker's check period, with no retry storm
- the retry middleware does not fire additional attempts once the breaker has opened
- when the breaker is closed and the backend returns a real retryable status, retry still works as before
Also confirm the middleware chain order and the circuit breaker's behaviour are unchanged. Run the retry and circuit breaker suites.

Prompt A7

Please compile the code and produce a compilation report as an MD

--- Model B

Model Name:
Start:
End:
Total:

Prompt B1 - Opening (auto-injected, identical for both)

We're seeing intermittent 503s in our staging environment behind Traefik. We've got a middleware chain: RateLimit to Retry to CircuitBreaker to Backend. Under load, the backend starts timing out.... the circuit breaker trips open correctly, but instead of getting the configured 503 fallback right away, clients hang for 3-5 seconds before getting the fallback. It looks like the retry middleware is piling on new attempts against the open circuit breaker, each of which returns a 503, then the retry retries again. This is causing a retry storm delays the final response and makes the circuit breaker's error metrics worse.
Can you trace the chain logic and figure out why retries keep firing at an open circuit? The fix should ensure that once the circuit breaker is open, the retry middleware doesn't keep hammering it. We need the client to get the fallback 503 without a multi-second delay.
The chain is configured on an HTTP router in Traefik config, using standard dynamic config through a file provider.

Prompt B2 - Point at the exact place

Start in pkg/middlewares/retry/retry.go around line 156 where ServeHTTP calls r.next.ServeHTTP, and look at how the statusCode range drives the retry decision. Then look at pkg/middlewares/circuitbreaker/circuit_breaker.go to see what the breaker returns when it is open - a configurable status code, 503 by default. The retry middleware has no way to tell that 503 apart from a real backend 503, so it retries on it. The shouldRetry flag is set in responseWriter.WriteHeader around retry.go line 248.

Prompt B3 - Confirm the mechanism, reproduce

Before implementing, confirm you can reproduce it. Build the Retry to CircuitBreaker to Backend chain with a backend that fails hard enough to trip the breaker, then measure the client-visible delay and count how many attempts the retry middleware fires after the breaker opens. Then walk me through why the breaker's 503 satisfies the retry status range.

Prompt B4 - Implement the specific fix

Add a mechanism so the retry middleware can detect that the response came from an upstream middleware that intentionally short-circuited the chain. One approach: have the circuit breaker's fallback set a marker (a context value or header) that retry checks before deciding to retry, and skip the retry when that marker is present. Keep the middleware chain order the same and do not change the breaker's status code or response format.

Prompt B5 - Code review

Please review the code generated for logic, performance and security bugs. produce a report in MD format with findings rated by critical, high and low. make sure each finding explicitly states the filename, filepath and line number and the suggested fix.

Prompt B6 - Verify

Write the test that proves it:
- with Retry before CircuitBreaker, once the breaker is open the client receives the fallback 503 within the breaker's check period, with no retry storm
- the retry middleware does not fire additional attempts once the breaker has opened
- when the breaker is closed and the backend returns a real retryable status, retry still works as before
Also confirm the middleware chain order and the circuit breaker's behaviour are unchanged. Run the retry and circuit breaker suites.

Prompt B7

Please compile the code and produce a compilation report as an MD
