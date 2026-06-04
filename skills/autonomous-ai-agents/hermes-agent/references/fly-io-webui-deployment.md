# Fly.io Web UI Deployment Reference

Session-derived playbook for deploying a Hermes gateway web UI on Fly.io when the app uses a pre-built Docker image (no Dockerfile or buildpacks).

## Prerequisites

- Fly.io app running with `http_service.internal_port = 8080`
- Persistent volume mounted at `/root/.hermes`
- API server env vars set: `API_SERVER_PORT=8080`, `API_SERVER_HOST=0.0.0.0`, `API_SERVER_KEY`

## Deployment Steps

### 1. Build the HTML chat interface locally

Create a single-file HTML chat interface. The file can be generated with `execute_code` or written manually. Save it to `/tmp/hermes-chat.html` locally.

### 2. Transfer to the persistent volume

Use `fly ssh sftp` for reliable file transfer. `fly ssh console -C` has shell parsing quirks:

```bash
# Upload
fly ssh sftp -a <app> --machine <machine-id> put /tmp/hermes-chat.html /root/.hermes/web/index.html

# Verify (download back and check)
rm -f /tmp/verify.html
fly ssh sftp -a <app> --machine <machine-id> get /root/.hermes/web/index.html /tmp/verify.html
head /tmp/verify.html
```

**Quirks of `fly ssh console -C`:**
- `&&` is treated literally (not as a command separator)
- `2>/dev/null` fails with `find` due to expression ordering
- `bash -c '...'` may be blocked by user consent
- `ps aux` is not supported in the container (use `ps` instead)
- Prefer single-quoted Python one-liners for complex remote operations

### 3. Create the startup script

Create `/root/.hermes/startup.sh` with the following content. The script patches `api_server.py` on each boot before starting the gateway.

```bash
#!/usr/bin/env bash
set -e

python3 << 'PYEOF'
import os

path = '/usr/local/lib/hermes-agent/gateway/platforms/api_server.py'
with open(path) as f:
    c = f.read()

if '_handle_index' not in c:
    c = c.replace(
        'self._app.router.add_post("/v1/chat/completions", self._handle_chat_completions)',
        'self._app.router.add_get("/", self._handle_index)\n            self._app.router.add_post("/v1/chat/completions", self._handle_chat_completions)')
    idx = c.find('    async def _handle_health(self, request:')
    handler = '    async def _handle_index(self, request: "web.Request") -> "web.Response":\n        return web.FileResponse("/root/.hermes/web/index.html")\n\n'
    c = c[:idx] + handler + c[idx:]
    with open(path, 'w') as f:
        f.write(c)
    print('API server patched')
else:
    print('API server already patched')
PYEOF

exec /entrypoint.sh hermes gateway run
```

Upload with `fly ssh sftp` and make executable:
```bash
fly ssh sftp -a <app> --machine <machine-id> put /tmp/startup.sh /root/.hermes/startup.sh
fly ssh console -a <app> --machine <machine-id> -C "chmod +x /root/.hermes/startup.sh"
```

### 4. Update the machine entrypoint

The `fly.toml` `[processes]` approach often fails on pre-built image apps:

```
Error: app does not have a Dockerfile or buildpacks configured
```

Instead, use `fly machine update`:

```bash
fly machine update <machine-id> -a <app> --entrypoint '/root/.hermes/startup.sh' --yes
fly machine restart <machine-id> -a <app>
```

### 5. Verify deployment

```bash
# Wait for startup
curl -s -o /dev/null -w "%{http_code}" https://<app>.fly.dev/
# Should return 200

# Check the HTML content
curl -s https://<app>.fly.dev/ | head -5

# Verify API endpoints still work
curl -s https://<app>.fly.dev/health
# {"status": "ok", "platform": "hermes-agent"}

# Verify API key authentication
curl -s -H "Authorization: Bearer <key>" https://<app>.fly.dev/v1/models
```

### 6. Recovery from crash loop

If the startup script is broken and the machine crashes on boot:

```bash
# Stop the machine
fly machine stop <machine-id> -a <app>

# Reset entrypoint to default
fly machine update <machine-id> -a <app> --entrypoint '' --yes
fly machine start <machine-id> -a <app>

# Fix the startup script locally, then re-upload and re-apply
```

## Key Architecture Facts

- **Persistent volume**: `/root/.hermes/` — survives restarts
- **Ephemeral image**: `/usr/local/lib/hermes-agent/` — reset on every restart
- **Machine ID**: Found via `fly machine list -a <app>` or `fly status -a <app>`
- **Image reference**: `fly machine status <machine-id> -a <app>` shows `Image`
- **Logs**: `fly logs -a <app> --machine <machine-id> -n` (note: `-n` not `--tail`)

## Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| `502 Bad Gateway` | API server not listening on port | Set `API_SERVER_PORT` and `API_SERVER_HOST` env vars |
| `404 Not Found` on `/` | `api_server.py` patch not applied | Check startup script is running and patch is correct |
| `app does not have a Dockerfile` | `fly.toml` with `[processes]` on pre-built image | Use `fly machine update --entrypoint` instead |
| `instance refused connection` | Gateway not listening on `0.0.0.0:8080` | Check `API_SERVER_HOST=0.0.0.0` |
| Crash loop | Bad startup script | Stop, reset entrypoint, fix script, restart |

## Verification Checklist

- [ ] HTML file exists at `/root/.hermes/web/index.html`
- [ ] Startup script exists at `/root/.hermes/startup.sh` and is executable
- [ ] Machine entrypoint points to `/root/.hermes/startup.sh`
- [ ] Root URL returns 200 with HTML content
- [ ] `/health` returns JSON
- [ ] `/v1/models` works with API key
- [ ] Telegram platform still connected
