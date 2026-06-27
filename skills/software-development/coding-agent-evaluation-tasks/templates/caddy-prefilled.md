Mercor Task Spec - Caddy (Prefilled)

Repository and Tags

Repo Name: caddyserver/caddy
GitHub URL: https://github.com/caddyserver/caddy
Primary Language: Go
Task Type: Debugging
Domain(s): Backend, DevOps/SRE
Interaction Mode: Interactive

Opening Prompt (Interactive Mode)

We hit a regression in Caddy reverse proxy after upgrading to v2.6.1. Running
this command:

caddy reverse-proxy --from https://public.example.com --to https://backend.internal:8443

Backend responds 400 Bad Request. Client sent an HTTP request to an HTTPS
server. Ran tcpdump and Caddy is sending plain HTTP to the backend even though
--to says https://. Worked fine in v2.5.x.

I looked at command.go and the scheme gets parsed correctly from the --to flag.
But something downstream in the transport config is not picking it up. TLS
field on HTTPTransport stays nil.

Trace the path from CLI flag to upstream dial. Find where the https scheme gets
dropped. Fix should be small - scheme extraction works, something after it in
the pipeline loses the plot.

Rationale 1: Why would frontier models struggle with this?

The bug sits between Caddy's CLI command builder and its reverse proxy
transport. The command handler in modules/caddyhttp/reverseproxy/command.go
parses --to addresses, pulls out the scheme using parseUpstreamDialAddress in
addresses.go, and builds the HTTPTransport config. A multi-upstream refactor
moved where scheme gets checked against TLS init. The condition that sets
Transport.TLS when toScheme equals https now fires against the wrong variable
or after a copy, so it always evaluates to false.

The model needs to trace the config pipeline across command.go, addresses.go,
httptransport.go, reverseproxy.go, and upstreams.go. Thats six files to
reconstruct the broken data flow. The actual fix is a conditional change in
one spot but figuring out which condition and what it should say means
understanding how addresses get parsed, copied, and consumed across the
builder and transport layers.

Rationale 2: What does this codebase do?

Caddy is a Go web server with automatic HTTPS built on a module system. About
217 source files. The core package handles config lifecycle and module
registration. modules/caddyhttp has the HTTP server, auto-HTTPS logic, routing,
and the reverse proxy subsystem which is about 14 files spread across the core
handler, HTTP transport config, upstream management, health checks, and load
balancing. modules/caddytls handles certificates via ACME. Config gets written
in Caddyfile format and parsed through caddyconfig/caddyfile into JSON via
caddyconfig/httpcaddyfile.

Rationale 3: What issues or gaps does the codebase have, and how would a
developer get started on solving them?

The scheme from --to flags is correctly extracted but the transport TLS config
is never set. parseUpstreamDialAddress in addresses.go gets "https" from the
URL. Then the if toScheme equals "https" check in command.go that should
initialize Transport.TLS either hits a nil or points to the wrong variable,
so shouldUseTLS in httptransport.go returns false and all upstream traffic
goes over plain HTTP regardless of --to.

Start by writing a test that runs the reverse-proxy command with
--to https://something:8443 and checks that HTTPTransport.TLS got populated.
Then trace through cmdReverseProxy looking at where toScheme gets set versus
where its checked. The fix is one conditional but finding it means reading
the address copy logic carefully.

Pre-Submit Checklist

Repo is caddyserver/caddy, public, not restricted
217 Go source files, used in production by thousands
Regression is real - reverse proxy sent HTTP to an HTTPS backend
Done means --to https:// enables TLS upstream
6 files affected across command, addresses, transport, proxy
L5 level - needs understanding Go transport internals and config builders
Debugging type matches investigation work
Prompt reads like a real ticket, fits interactive mode
Rationales name specific files and functions
Run AutoQC before submit
