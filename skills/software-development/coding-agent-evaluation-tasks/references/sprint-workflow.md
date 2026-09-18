# Sprint Workflow — Setup, Launch, Observation, Submission

Sprint work: run two blinded Claude models in parallel on one assigned pre-work task, log behavior live, rate both, record a head-to-head preference, submit through Studio.

## Prerequisites (Phase 0)

- Claude Code installed and current (`claude update`). Model runs happen inside Docker containers — Docker must be installed and running; init.py blocks setup without it.
- GitHub SSH key configured (project Appendix B). Generate it with the Mercor expert email as the comment and register it on the account the sprint clones as. Registration needs the gh admin:public_key scope: `gh auth refresh -h github.com -s admin:public_key` (browser approval), then `gh ssh-key add <key>.pub --title "<label>"`.
- Verify the NEW key standalone: `ssh -i <key> -o IdentitiesOnly=yes -T git@github.com` plus a `git ls-remote` against a public repo. An unregistered key fails even for public repos, while a plain `ssh -T` can succeed via an older registered key — which masks the problem. Write the new key to its own file; never overwrite an existing id_ed25519.
- Pre-launch check, all must pass: Docker daemon running, `claude --version` current, `python3 --version` >= 3.7, ANTHROPIC_API_KEY and ANTHROPIC_AUTH_TOKEN unset and absent from shell profiles, SSH key authenticating standalone.
- Python 3.7+.
- Insightful running for the ENTIRE task, setup through final submission. Do not start before it is active; do not stop it before submitting.
- Slack: #announcements (deadlines), #code-preferences-help (questions, edge cases), #general (payout). Task assignment arrives by DM from the bot.
- Windows: WSL 2 backend required; all work from inside WSL, not PowerShell or Command Prompt.

## Assignment

- Woz (Slack bot) assigns from the approved pre-work pool based on background and sprint need. Buttons only — no conversation, no task requests.
- Usually not your own authored task; matching follows your authored domain.
- No activity for 3 hours = auto-reassigned. Decline a continuation prompt = reassigned.
- After submitting in Studio, Woz can assign another.

## Launch (Phase 2)

1. Studio → Code Preferences Sprint world → open the assigned task; note the Task ID in Task Setup.
2. Put init.py in its own directory. Verify: Claude Code current, Docker running, SSH key set, Python 3.7+.
3. Ensure ANTHROPIC_API_KEY and ANTHROPIC_AUTH_TOKEN are NOT set in the shell — they override the proxy login.
4. Run `python3 init.py`; enter name, Mercor expert email, Task ID as TASK_# (uppercase), local clone SSH link. A browser opens a one-time Okta login that must match the entered email; setup then clones the repo and configures Claude Code.
5. Launch both: `./claude-dev` in model_a/ and `./claude-dev` in model_b/. Confirm each shows an animal code name. Do NOT run /login in either session.
6. The opening prompt injects automatically at session start — the model begins on its own. Do not interrupt, cancel, or paste the prompt yourself.

## During the run

- Log behavioral issues in real time (against the task in Studio, or a local file as backup). End ratings must cite that record.
- Two prompt tracks per task, one per model: single shared opening prompt, then distinct follow-up paths (~5 turns each, at least 4 follow-ups per model). Interactive mode only — async has no follow-ups.
- Interactive: minimum 1 hour per model; if a task exceeds 2.5 hours per model, end the session and rate on what was accomplished. 150 minutes max per task.
- Async: both sessions start from the exact same opening prompt, word for word; no steering.
- Never leak success criteria or the stated high-level goal into a session.

## Submission

1. Run the Python submit script to send execution data.
2. Fill Studio in stages: initial data (repo + opening prompt) → per-model ratings → head-to-head preference.
3. Fetch task metadata (submission time, execution log links).
4. Run automated QC — it must pass before final submit.
5. Submit in Studio.

## Compensation

$85/hour + $200 bonus per accepted task. Quality, throughput, and time logs are monitored for fraud; unapproved GenAI use can lead to removal.

## Where things live

- Project work files: ~/Documents/PROJECT C/
- Full troubleshooting: project Appendix A (setup) and project Appendix B (GitHub SSH key)

## Authoring these artifacts

The user edits spec and prompt-flow files live while you work. Re-read the exact file immediately before any overwrite — a stale copy is refused. Prefer small targeted patches over whole-file rewrites: a large single write can time out mid-stream and lose the content. Files are plain text only: no markdown headers, no pipes, no backticks, no emoji. Do not wrap them either — leave every paragraph as one long line exactly as written, including the Q1-Q4 block and each prompt block; the user reads with soft wrap off.