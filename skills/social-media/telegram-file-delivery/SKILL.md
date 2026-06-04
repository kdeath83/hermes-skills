---
name: telegram-file-delivery
description: Deliver files to Telegram chats when built-in Hermes tools fail or don't support the file type.
tags: [telegram, messaging, delivery, curl, bot-api]
author: agent
---

# Telegram File Delivery

Deliver files to a Telegram chat when `send_message` with `MEDIA:` fails (e.g., non-media file types like `.md`, `.json`, `.zip` are not delivered natively).

## Quick Reference

**For images/audio/video**: Use `MEDIA:/path/to/file` in a message response.

**For documents/code/archives/markdown**: Use Telegram Bot API `sendDocument` via curl.

## Fallback: Bot API `sendDocument`

When `MEDIA:` does not deliver the file, use the Telegram Bot API directly:

```bash
TG_TOKEN=$(grep "^TELEGRAM_BOT_TOKEN=" ~/.hermes/.env | cut -d= -f2)
CHAT_ID=$(grep -i "chat_id\|user_id" ~/.hermes/channel_directory.json | head -1 | grep -o '[0-9]*' | head -1)
# Or hardcode the known DM chat ID from session context

curl -s -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendDocument" \
  -F "chat_id=${CHAT_ID}" \
  -F "document=@/absolute/path/to/file.md" \
  -F "caption=Optional caption"
```

## Resolving Credentials

1. **Bot token**: Extract from `~/.hermes/.env` with `grep "^TELEGRAM_BOT_TOKEN="` + `cut -d= -f2`.
   - **Do NOT `source ~/.hermes/.env`** — it may contain lines with spaces (e.g., file paths like `Google Chrome.app/...`) that break shell parsing.
2. **Chat ID**: Check `~/.hermes/channel_directory.json` for the Telegram platform entry, or use the `HERMES_SESSION_KEY` env var (format: `agent:main:telegram:dm:<chat_id>`).

## Pitfalls

| Issue | Cause | Fix |
|-------|-------|-----|
| `send_message` says "No home channel set" | `TELEGRAM_HOME_CHANNEL` missing in config | Use Bot API fallback, or set `hermes config set TELEGRAM_HOME_CHANNEL <chat_id>` |
| `MEDIA:` returns "not found" | File not in allowed dirs or not a supported media type | Move to `~/` or `~/.hermes/image_cache/`, or use Bot API fallback |
| `.env` sourcing fails with "No such file or directory" | `.env` has unquoted paths with spaces | Use `grep`/`cut` extraction instead of `source` |
| `sendDocument` returns `chat not found` | Wrong `chat_id` | Verify against `channel_directory.json` or session env |

## Verification

A successful `sendDocument` response contains `"ok":true` and a `document.file_id`. If it fails, the JSON error describes the issue (e.g., `chat not found`, `wrong file identifier`).

## Related

- `send_message` tool — for text and native media delivery
- Telegram Bot API docs: https://core.telegram.org/bots/api#senddocument
