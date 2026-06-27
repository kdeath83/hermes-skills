Mercor Task Spec - Caddy (Prefilled)

Repository and Tags

Repo Name: caddyserver/caddy
GitHub URL: https://github.com/caddyserver/caddy
Primary Language: Go
Task Type: Debugging
Domain(s): Backend, DevOps/SRE
Interaction Mode: Interactive

Opening Prompt (Interactive Mode)

We've got a regression in our Caddy reverse proxy setup after upgrading to
v2.6.1. We're using caddy reverse-proxy to route traffic to an internal HTTPS
backend:

caddy reverse-proxy --from https://public.example.com --to https://backend.internal:8443

The backend is responding with 400 Bad Request / Client sent an HTTP request to
an HTTPS server. Running tcpdump confirms Caddy is sending plain HTTP to the
backend even though --to specifies https://. This was working fine in v2.5.x.

I traced the initial flag parsing in command.go and it seems like the scheme is
extracted correctly from --to, but something downstream in the transport config
isn't picking it up. The TLS field on HTTPTransport stays nil.

Can you trace the full path from CLI flag to upstream dial and find where the
https scheme gets lost? Fix it so --to https:// actually enables TLS to the
upstream. The fix should be minimal - the scheme extraction works, something
after it in the pipeline drops the ball.

Rationale 1: Why would frontier models struggle with this?

The bug spans the boundary between Caddy's CLI command builder and the reverse
proxy transport layer. The CLI command in modules/caddyhttp/reverseproxy/command.go
parses --to addresses, extracts schemes via parseUpstreamDialAddress() in
addresses.go, and sets up the HTTPTransport config. A recent refactor for
multi-upstream support moved the scheme-to-TLS initialization logic, and a
conditional check (if toScheme == "https") that initializes Transport.TLS
now evaluates to false because the scheme variable is captured from the wrong
scope or after the address has been copied. The model needs to trace data flow
across command.go (config builder), addresses.go (scheme extraction),
httptransport.go (TLS field population and shouldUseTLS()), reverseproxy.go
(actual request cloning which strips URL.Scheme), and upstreams.go (dial
address resolution). This is a classic regression debugging scenario where
the model must reconstruct the intended data flow from the refactored code
and spot the single condition that lost its way.

Rationale 2: What does this codebase do?

Caddy is a Go web server (217 source files) with automatic HTTPS, built on a
module system where every feature is a plugin. The core library (root package)
handles the config lifecycle, admin API, and module registration. The HTTP app
in modules/caddyhttp/ provides the HTTP server, auto-HTTPS, routing, and the
reverse proxy subsystem (14 files). The TLS app in modules/caddytls/ handles
certificate automation via ACME. Config is authored in Caddyfile format and
parsed through caddyconfig/caddyfile/ (lexer, parser, AST) then adapted to JSON
via caddyconfig/httpcaddyfile/. The reverse proxy subsystem is in
modules/caddyhttp/reverseproxy/ containing the core handler, HTTP transport
config, upstream management, health checks, and load balancing policies.

Rationale 3: What issues or gaps does the codebase have, and how would a
developer get started on solving them?

The gap is that the scheme extracted from the --to flag in command.go is not
reliably propagated to the HTTPTransport.TLS field. parseUpstreamDialAddress()
in addresses.go correctly extracts "https" from the URL, but the condition
checking toScheme to initialize TLS fires against the wrong reference - the
result is that TLS is never populated and shouldUseTLS() in httptransport.go
returns false, causing all upstream requests to use plain HTTP regardless
of the --to scheme.

A developer would start by writing a failing test that runs the reverse-proxy
command with --to https://some-backend:8443 and asserts that the generated
config has HTTPTransport.TLS populated. Then trace through command.go from
cmdReverseProxy() through the for loop over --to addresses, examining where
toScheme is set and where it's checked. The fix is a single-line conditional
change but identifying which condition and what it should say requires
understanding how addresses are parsed, copied, and consumed across the command
builder and transport config.

Pre-Submit Checklist

Public GH repo, not restricted - caddyserver/caddy, 74k+ stars, not on restricted list
200+ code files, enterprise-grade - 217 .go source files, used in production globally
Realistic production scenario - reverse proxy silently downgrades to HTTP is a real
security/functionality regression
Concrete, testable done - --to https:// results in TLS-enabled upstream requests
Multi-file change (5-15+ files) - 6 files across command, addresses, transport, proxy handler
L5+ SWE difficulty - requires understanding Go interface patterns, middleware wrapping,
config builder pipeline, and HTTP transport internals
Task Type matches actual work - Debugging (trace regression in upstream scheme handling)
Prompt matches Interaction Mode - short, Slack-style, describes symptom and starting point
Rationales specific, own words - all three name concrete files, functions, and mechanism
AutoQC passes - run before submit
