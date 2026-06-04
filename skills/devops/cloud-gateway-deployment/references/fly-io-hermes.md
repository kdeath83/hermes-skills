# Fly.io Hermes Gateway Deployment — Session Reference

Deployment date: 2026-05-26
App: `hermes-kdeath83`
Region: `syd`
Bot: `@LobbyHermesBot`

## The Volume-Shadow Problem

Initial deploy succeeded (image built, machine started, Telegram connected) but the bot would not reply to messages. Root cause: the Fly persistent volume was mounted at `/root/.hermes`, which completely hid the `config.yaml`, `.env`, and memory files that had been `COPY`'d into the Docker image during build. The volume was effectively empty except for runtime-generated files (`gateway.pid`, `logs/`, `state.db`).

**Symptom:** Gateway log shows `telegram connected`, `Gateway running with 1 platform(s)`, no errors — but incoming messages never trigger agent sessions.

**Fix:** Copy the local `~/.hermes/config.yaml`, `~/.hermes/.env`, and `~/.hermes/memories/` onto the Fly volume, then restart the app.

## Base64 Chunking Script (Working)

The `flyctl ssh console` shell has broken escaping for `&&`, pipes, and subshells. The reliable way to ship files is chunked base64 via stdin:

```python
import subprocess, base64, os

home = os.path.expanduser("~")
files = [".hermes/config.yaml", ".hermes/.env", ".hermes/memories/MEMORY.md", ".hermes/memories/USER.md"]

tar = subprocess.run(["tar", "czf", "-"] + files, cwd=home, capture_output=True).stdout
b64 = base64.b64encode(tar).decode()
chunk_size = 3000
chunks = [b64[i:i+chunk_size] for i in range(0, len(b64), chunk_size)]

remote_cmds = ["cd /root && rm -f /tmp/hermes_seed.b64"]
for chunk in chunks:
    remote_cmds.append(f'echo "{chunk}" >> /tmp/hermes_seed.b64')
remote_cmds.append("base64 -d /tmp/hermes_seed.b64 | tar xzf - && rm -f /tmp/hermes_seed.b64")
remote_cmds.append("exit")

proc = subprocess.Popen(
    ["flyctl", "ssh", "console", "--app", "hermes-kdeath83"],
    stdin=subprocess.PIPE, stdout=subprocess.PIPE,
    stderr=subprocess.PIPE, text=True
)
out, err = proc.communicate(input="\n".join(remote_cmds) + "\n", timeout=120)
```

This was the only method that worked after multiple attempts with `echo "cmd" | flyctl ssh console` all failed due to escaping.

## Volume Naming Rule

Fly volume names **cannot contain hyphens**. The first attempt with `hermes-kdeath83_data` was rejected. The working name was `hermes_kdeath83_data`.

## Dockerfile Used

```dockerfile
FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/root/.local/bin:${PATH}"
ENV HERMES_HOME=/root/.hermes

RUN apt-get update && apt-get install -y git python3 python3-pip python3-venv curl tmux && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["hermes", "gateway", "run"]
```

Note: `COPY` of config files into the image is useless when a volume is mounted at the same path. The entrypoint was intentionally minimal because all config lives on the volume.

## fly.toml Used

```toml
app = 'hermes-kdeath83'
primary_region = 'syd'

[build]

[env]
  HERMES_HOME = "/root/.hermes"

[[mounts]]
  source = "hermes_kdeath83_data"
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

## Cutover Sequence

1. Deployed to Fly.
2. Discovered bot would not reply.
3. Checked remote filesystem — `config.yaml` and `.env` missing on volume.
4. Seeded files via base64 chunking.
5. Restarted app (`flyctl apps restart hermes-kdeath83`).
6. Verified Telegram polling clean (no conflicts after ~2 minutes).
7. Stopped local Mac gateway (`hermes gateway stop`) to prevent polling tug-of-war.
8. Confirmed `@LobbyHermesBot` replies from Fly.

## Key Log Lines (Healthy State)

```
2026-05-26 12:44:03,534 [Telegram] Connected to Telegram (polling mode)
2026-05-26 12:44:03,537 ✓ telegram connected
2026-05-26 12:44:04,642 Cron ticker started (interval=60s)
```
