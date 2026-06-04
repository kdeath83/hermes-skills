---
title: Video Clip Extraction
name: video-clipping
version: 1.0
author: user
description: Extract 20-second video clips from Desktop/DD Videos using ffmpeg when user says 'DD clips'. Terse workflow, stream-copy, no re-encode.
---

# Video Clip Extraction

Trigger phrase: `DD clips` — user provides a video filename from `Desktop/DD Videos`.

## Workflow

1. **Ask for timestamps** if not provided. Respond tersely: `Timestamps?`
2. For each timestamp, extract a **20-second clip** (10s before + 10s after).
3. **Save as** `filename_timestamp` in the same `Desktop/DD Videos` folder.
4. Confirm extraction with a terse file listing.

## ffmpeg Parameters

```bash
ffmpeg -ss <start_time> -t 20 -i "Desktop/DD Videos/<filename>" -c copy -avoid_negative_ts make_zero "Desktop/DD Videos/<filename>_<timestamp_label>.mp4"
```

- `-ss` at `timestamp - 10s` (e.g., `9m` → `00:08:50`)
- `-t 20` for exactly 20 seconds
- `-c copy` stream copy, no re-encode
- `-avoid_negative_ts make_zero` for clean output

## Timestamp Parsing

| Input | ffmpeg `-ss` |
|-------|-------------|
| `25s` | `00:00:15` |
| `2m25` | `00:02:15` |
| `5m30` | `00:05:20` |
| `7m45` | `00:07:35` |
| `9m` | `00:08:50` |
| `9m20` | `00:09:10` |
| `10m` | `00:09:50` |
| `13m25` | `00:13:15` |
| `14m30` | `00:14:20` |
| `19m` | `00:18:50` |
| `19m55` | `00:19:45` |
| `20m30` | `00:20:20` |

Rule: subtract 10s from the center timestamp. If result is negative, clamp to `00:00:00`.

## Style

- Terse responses. No fluff. `Timestamps?` is the correct prompt.
- Confirm with file listing, not a paragraph.
- Do not explain ffmpeg flags unless asked.
