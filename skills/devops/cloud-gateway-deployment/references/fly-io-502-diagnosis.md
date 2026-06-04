# Fly.io 502 Diagnosis: Gateway Running But Not Listening

Date: 2026-06-01
App: hermes-kdeath83 (syd)

## Problem

URL `https://hermes-kdeath83.fly.dev` returns 502. User reported the gateway was not loading.

## Initial State

- `fly status` showed machine `2862024ce5d6d8` as `started`
- App had been running since 2026-05-26 (deployed ~5 days prior)
- `fly logs` showed repeated proxy errors:
  ```
  error.message="instance refused connection. is your app listening on 0.0.0.0:8080?"
  ```
- Gateway itself had been running for ~5.5 days (uptime 478,921s) before the user triggered a restart

## Diagnosis Steps

1. **Check process state** — `ps aux` showed `hermes gateway run` running as PID 646, consuming ~33% RAM (155MB of 512MB). Process was alive.

2. **Check listening sockets** — `ss` and `netstat` were not available in the container. `cat /proc/net/tcp` returned only the header row with no entries. Confirmed: **zero TCP sockets open**.

3. **Check gateway logs** — `tail -n 50 /root/.hermes/logs/gateway.log` showed:
   - `telegram connected` (2026-06-01 02:07:38)
   - `Cron ticker started` (2026-06-01 02:07:40)
   - `Gateway running with 1 platform(s)` (2026-06-01 02:07:38)
   - Memory monitor showing stable ~244MB RSS
   - The previous shutdown was clean (SIGINT, 2.94s teardown) — not a crash

4. **Check Fly config** — `fly config show` had:
   ```json
   "http_service": {
     "internal_port": 8080,
     "force_https": true,
     "auto_stop_machines": false,
     "auto_start_machines": true,
     "min_machines_running": 1
   }
   ```
   The proxy expects port 8080. `hermes gateway run` does not bind to 8080.

## Root Cause

`hermes gateway run` is a messaging-only service (Telegram polling, Discord, etc.). It does not start an HTTP server. The `fly.toml` was configured with `http_service` expecting port 8080, so the Fly proxy returned 502 because nothing was listening on that port.

The gateway itself was healthy. The 502 was a proxy-to-app mismatch, not a crash or failure.

## Remediation Options Presented

- **A.** Remove the `http_service` block from `fly.toml` (messaging-only gateway, no web UI needed)
- **B.** Add a health check endpoint or enable API Server platform adapter
- **C.** Do nothing — for a Telegram-only bot, the Fly URL is irrelevant

## Key Takeaways

- Always verify what the app is actually supposed to listen on before treating 502 as a crash
- `hermes gateway run` ≠ HTTP server; it is a messaging gateway
- Container images often lack `ss`/`netstat` — use `/proc/net/tcp` as a fallback
- Check gateway logs for `connected`, `ticker started`, `running` — these confirm health
- Proxy error messages about `0.0.0.0:8080` are definitive: the app is not listening on the configured port
