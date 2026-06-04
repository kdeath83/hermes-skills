# Persona Deployment to Remote Gateway

Session: Deploying the Lobby persona to a Fly.io-hosted Hermes gateway.

## Problem

The gateway on Fly.io was running but replying with the default/generic personality instead of the user's desired terse Lobby persona. The local Mac had `SOUL.md` but the remote volume did not.

## Solution

1. Write `SOUL.md` locally:

```bash
# ~/.hermes/SOUL.md
---
name: Lobby
persona: terse, direct, no fluff
---
Here. What do you need?
```

2. Seed it to the remote volume using the same base64-chunked tar method used for config files. The file must land at `/root/.hermes/SOUL.md` on the remote machine.

3. Restart the app:

```bash
flyctl apps restart hermes-kdeath83
```

4. Verify via Telegram:

```
User: hello lobby, are you there
Bot: Here. What do you need?
```

## Key Points

- `SOUL.md` is NOT baked into the Docker image for the same reason `config.yaml` isn't: the volume mount at `/root/.hermes` hides image contents.
- The file must be explicitly seeded onto the volume after every deploy.
- Changes to `SOUL.md` on the local Mac do NOT propagate to the remote gateway automatically. You must re-seed.

## Related

See `references/fly-io-hermes.md` for the base64 chunking script and volume-shadow fix.
