---
name: cloud-gateway-deployment
description: Deploy Hermes gateway and other long-running agent services to cloud platforms (Fly.io, Render, Railway, etc.). Covers image builds, persistent volume pitfalls, secret injection, config seeding, and remote debugging.
triggers:
  - "deploy hermes gateway"
  - "host hermes gateway"
  - "fly.io deployment"
  - "cloud hosting for hermes"
  - "gateway on fly"
  - "deploy to render"
  - "deploy to railway"
  - "persistent volume config"
  - "remote agent gateway"
category: devops
---
# Cloud Gateway Deployment

Deploy long-running agent gateways (Hermes, custom bots, MCP servers) to managed cloud platforms with persistent state.

## Prerequisites

- `flyctl` (Fly), or platform CLI installed and authenticated
- Local gateway config in `~/.hermes/` (or equivalent for the service)
- Bot token / API keys exported in `.env` or set as platform secrets

## Fly.io Deployment

### 1. Scaffold app and volume

```bash
APP_NAME="hermes-$USER"
REGION="syd"

flyctl apps create "$APP_NAME" --org personal
# Volume names CANNOT contain hyphens — use underscores
flyctl volumes create "${APP_NAME}_data" --app "$APP_NAME" --region "$REGION" --size 1 --yes
```

### 2. Write `fly.toml`

Key points:
- Mount the volume at the data directory, NOT at a path that also receives baked-in Docker `COPY` layers.
- If the service expects config files at the same path as the mount, you MUST seed them onto the volume after creation — the mount shadows image contents.

```toml
app = 'hermes-example'
primary_region = 'syd'

[build]

[env]
  HERMES_HOME = "/root/.hermes"

[[mounts]]
  source = "hermes_example_data"
  destination = "/root/.hermes"

[[services]]
  protocol = "tcp"
  internal_port = 8080
  auto_stop_machines = "off"
  auto_start_machines = false
  [[services.ports]]
    port = 8080
    handlers = ["http"]

[http_service]
  internal_port = 8080
  force_https = false
  auto_stop_machines = "off"
  auto_start_machines = false

[[vm]]
  memory = "512mb"
  cpu_kind = "shared"
  cpus = 1
```

### 3. Build and push

```bash
flyctl deploy --app "$APP_NAME"
```

### 4. Seed config onto the volume (CRITICAL)

If the mount shadows baked-in config, the service will start with an empty directory. See **Shipping Files to Remote Machines** below for the reliable transfer method.

Files to seed for Hermes:
- `~/.hermes/config.yaml` — model provider, personality, toolsets
- `~/.hermes/.env` — API keys and tokens
- `~/.hermes/memories/MEMORY.md` and `USER.md` — persistent memory

### 5. Restart to pick up seeded files

```bash
flyctl apps restart "$APP_NAME"
```

### 6. Verify

```bash
flyctl status --app "$APP_NAME"
flyctl logs --app "$APP_NAME"
```

## Critical Pitfalls

### Volume mount shadows image contents
On Fly.io (and Docker in general), a `[[mounts]]` or `VOLUME` at path `/root/.hermes` completely replaces whatever was `COPY`'d into the image at that path. The container sees ONLY the volume contents, not the image layers. **Never rely on `COPY config.yaml /root/.hermes/config.yaml` when a volume is mounted at the same path.**

Fixes:
- Seed config onto the volume after deployment (recommended).
- Or mount the volume at a subdirectory (e.g., `/root/.hermes/data`) and keep configs in the image.

### `flyctl ssh console` escaping is broken
Complex shell commands with `&&`, `|`, `()`, or `$()` fail silently or produce garbled output when piped via `echo "cmd" | flyctl ssh console`. **Always use simple one-liners**, or ship a script file and execute it.

### Bot username mismatch
If the gateway connects but never replies, verify the actual bot username against what the user thinks it is. Query the Telegram API directly from the remote machine:

```bash
curl -s https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getMe | jq -r '.result.username'
```

The user may be messaging the wrong bot. Only one bot can poll per token — if a local gateway is also running, it will win the polling session and the Fly instance will never see messages.

### Persona (SOUL.md) not active on remote gateway
If the gateway replies but with the wrong personality, the remote volume likely lacks `SOUL.md`. The persona file must be seeded onto the volume alongside `config.yaml` and `.env`:

```bash
# Local: write SOUL.md
write_file("~/.hermes/SOUL.md", "...")

# Then seed it to the remote volume using the same base64 chunking method
# as config files. Restart the app after seeding.
```

See `references/persona-deployment.md` for the full session transcript.

### Volume naming
Fly.io volume names reject hyphens. Use underscores: `hermes_kdeath83_data` ✓, `hermes-kdeath83-data` ✗.

### Polling conflicts for Telegram bots
Only one process can hold the `getUpdates` polling session for a given bot token. Starting a new instance before the old one releases its session causes `409 Conflict: terminated by other getUpdates request`. The gateway handles this with retry logic, but expect ~1–2 minutes of turbulence during cutover. For zero-downtime, switch to webhooks (more complex) or accept the brief retry window.

## Shipping Files to Remote Machines

When `scp`/`rsync` is unavailable and `flyctl ssh console` chokes on complex commands, use chunked base64 via stdin:

```python
import subprocess, base64, os

files = [".hermes/config.yaml", ".hermes/.env"]
home = os.path.expanduser("~")

tar = subprocess.run(
    ["tar", "czf", "-"] + files,
    cwd=home, capture_output=True
).stdout

b64 = base64.b64encode(tar).decode()
chunk_size = 3000
chunks = [b64[i:i+chunk_size] for i in range(0, len(b64), chunk_size)]

remote_cmds = ["cd /root && rm -f /tmp/seed.b64"]
for chunk in chunks:
    remote_cmds.append(f'echo "{chunk}" >> /tmp/seed.b64')
remote_cmds.append("base64 -d /tmp/seed.b64 | tar xzf - && rm -f /tmp/seed.b64")
remote_cmds.append("exit")

proc = subprocess.Popen(
    ["flyctl", "ssh", "console", "--app", "APP_NAME"],
    stdin=subprocess.PIPE, stdout=subprocess.PIPE,
    stderr=subprocess.PIPE, text=True
)
out, err = proc.communicate(input="\n".join(remote_cmds) + "\n", timeout=120)
```

This avoids all shell-escaping issues because each command is a simple `echo` or `base64` call.

## Enabling the API Server for Web UI Access

The Hermes gateway includes an `api_server` platform adapter that exposes an OpenAI-compatible HTTP API. This is the backend for any web browser interface (e.g., a custom HTML chat page, Open WebUI, or the built-in React web UI in the Hermes repo).

### Enable the API server

Set environment variables via `fly secrets` or `fly.toml` `[env]`:

```bash
fly secrets set -a APP_NAME \
  API_SERVER_PORT=8080 \
  API_SERVER_HOST=0.0.0.0 \
  API_SERVER_KEY="$(openssl rand -hex 32)"
```

- `API_SERVER_PORT` — Must match `fly.toml` `internal_port` (usually 8080).
- `API_SERVER_HOST` — Must be `0.0.0.0` for Fly proxy to reach it.
- `API_SERVER_KEY` — **Required** for any network-accessible host. The adapter refuses to start without a real secret (≥8 chars, non-placeholder). The key is used in `Authorization: Bearer <key>` headers.
- Optional: `API_SERVER_CORS_ORIGINS=*` if the web UI is hosted elsewhere.

After setting secrets, restart the machine. The gateway log should show:
```
[Api_Server] API server listening on http://0.0.0.0:8080 (model: hermes-agent)
```

### Serving a web UI at the root URL

The API server only exposes API endpoints (`/health`, `/v1/chat/completions`, etc.). It does not serve a built-in HTML interface. To serve a web UI at the root URL (`/`), you have two options:

**Option A: Custom startup script (persistent)**

The source code at `/usr/local/lib/hermes-agent/` is baked into the Docker image — modifications are lost on machine restart. Use a startup script on the persistent volume (`/root/.hermes/`) that patches the API server before launching the gateway:

1. Create `startup.sh` on the volume:
   ```bash
   #!/usr/bin/env bash
   set -e
   python3 -c "
   import os
   api_server_path = '/usr/local/lib/hermes-agent/gateway/platforms/api_server.py'
   with open(api_server_path, 'r') as f:
       content = f.read()
   if '_handle_index' not in content:
       old = 'self._app.router.add_post(\"/v1/chat/completions\", self._handle_chat_completions)'
       new = 'self._app.router.add_get(\"/\", self._handle_index)\\n            self._app.router.add_post(\"/v1/chat/completions\", self._handle_chat_completions)'
       content = content.replace(old, new)
       handler = '''\\n    async def _handle_index(self, request: web.Request) -> web.Response:\\n        return web.FileResponse(\"/root/.hermes/web/index.html\")\\n'''
       marker = '    async def _handle_health(self, request: web.Request) -> web.Response:'
       content = content.replace(marker, handler + marker)
       with open(api_server_path, 'w') as f:
           f.write(content)
   "
   exec /entrypoint.sh hermes gateway run
   ```

2. Create `web/index.html` on the volume (a single-page HTML chat app that connects to the API server via `fetch` with `Authorization: Bearer <key>`).

3. Update `fly.toml` to use the startup script:
   ```toml
   [processes]
     app = "/root/.hermes/startup.sh"
   ```
   Convert `http_service` to a `[[services]]` block with `processes = ["app"]`.

4. Deploy. The script patches the API server in-memory on every start, and the HTML file is served from the persistent volume.

**Option B: External web UI (no source patching)**

Host the web UI elsewhere (e.g., a static site on Vercel/Netlify) and have it connect to `https://APP_NAME.fly.dev/v1/chat/completions`. Set `API_SERVER_CORS_ORIGINS` to allow the external domain.

### API server vs built-in React web UI

The Hermes repo includes a React web UI at `web/` (Vite + React, ~8KB source), but it is **not pre-built** in the Docker image. The Fly machine has no Node.js, so building it there is not possible. If you want the official React UI, build it locally (`npm run build`) and deploy the `dist/` folder alongside the gateway (e.g., via a static file server or by merging it into the Docker image).

### Source code persistence on Fly machines

- `/root/.hermes/` — Persistent volume. Survives restarts. Use for configs, startup scripts, web UI HTML files.
- `/usr/local/lib/hermes-agent/` — Docker image contents. Reset on every restart. Never rely on changes here unless you rebuild the image.

## Troubleshooting: 502 Bad Gateway on Fly.io

If the app machine shows `started` but the Fly URL returns 502:

1. **Check if the app actually listens on the expected port.** `hermes gateway run` starts messaging adapters (Telegram polling, Discord, etc.) — it does NOT start an HTTP server by default. If `fly.toml` has `http_service` or `services` pointing to port 8080, the Fly proxy will 502 because nothing is listening.

   Verify on the machine:
   ```bash
   fly ssh console -a APP_NAME -C "cat /proc/net/tcp"
   # If empty, nothing is listening on any TCP port
   ```

   Note: `ss` and `netstat` are often stripped from container images. Use `/proc/net/tcp` instead.

2. **Check the gateway logs** for the real state:
   ```bash
   fly logs -a APP_NAME
   ```
   Look for `telegram connected`, `Cron ticker started`, `Gateway running` — these confirm the gateway is healthy. The 502 is just a proxy→app mismatch, not a crash.

3. **Remediation options:**
   - **Option A** — Remove the `http_service` block from `fly.toml` if the gateway is messaging-only (no web UI). The URL will still exist but won't be expected to serve HTTP.
   - **Option B** — Enable the `api_server` platform adapter (see "Enabling the API Server" above) so the gateway listens on port 8080.
   - **Option C** — Do nothing. For a Telegram-only bot, the Fly URL is irrelevant; the bot works via polling.

4. **Common pitfall:** Gateway was running fine for days (uptime 400k+ seconds), then a machine restart or a user visiting the URL triggered a 502. This is not a crash — the gateway never served HTTP.

## Verification Checklist

- [ ] App shows `deployed` in `flyctl apps list`
- [ ] Machine state is `started`
- [ ] Gateway log shows `telegram connected` (or platform equivalent)
- [ ] No `polling conflict` warnings persisting beyond 2 minutes
- [ ] Sending a test message to the bot produces a reply
- [ ] `config.yaml` and `.env` are present on the remote volume (`ls -la /root/.hermes/`)

## Session-Specific Reference

See `references/fly-io-hermes.md` for the complete transcript of the Hermes gateway deployment to Fly.io including the volume-shadow fix, base64 seeding script, and `fly.toml`/`Dockerfile` used.

See `references/fly-io-502-diagnosis.md` for the full diagnostic walkthrough of a 502 error where the gateway was running but not listening on port 8080.
