SPRINT STAGE (MODEL COMPARISON) - Project C

Source: Mercor Code Preferences sprint guidance doc, multi-tab Google Doc.
Fetch one tab at a time:
  https://docs.google.com/document/d/<docid>/export?format=txt&tab=<tabid>
(Plain export returns only the first tab; the tab param is required for others.)

OVERVIEW
- Blind A/B: two anonymized Claude models, Model A and Model B.
- Each is a separate Claude Code session started from an identical snapshot
  of the codebase. Both receive the exact same opening prompt.
- Run in parallel, at the same time.
- Document behavior in real time; rate each model; record a head-to-head
  preference at the end, grounded in that record.
- Tasks come from approved pre-work only. No sprint-created tasks.
- "Woz" Slack bot assigns tasks by background/need. Not conversational,
  buttons only, cannot request a task. Declining a continuation = reassigned.
  3h inactivity = auto-reassigned. After a submission, Woz can assign another.

PHASE 0 SETUP (already onboarded in pre-work: skip to Step 5)
- Slack channels: #announcements, #code-preferences-help, #general (payout).
- Insightful: run for the entire duration, setup through submission.
- Workramp assessment; Mercor Studio onboarding.
- Install Claude Code (`claude update`) and Docker. Model runs happen inside
  Docker containers; init blocks setup if Docker is missing.
- GitHub SSH key (Appendix B). Windows requires WSL 2 with Docker backend.

PHASE 2 LAUNCH
- Put init.py in its own directory.
- Ensure ANTHROPIC_API_KEY and ANTHROPIC_AUTH_TOKEN are NOT set in the shell
  (they override the proxy login).
- `python3 init.py`: enter name, Mercor expert email, Task ID as TASK_#
  (uppercase), local clone SSH link. One-time Okta login must match the email.
- Launch `./claude-dev` in model_a/ and model_b/. Confirm each shows an animal
  code name. Do NOT run /login in either.
- The opening prompt is auto-injected as each session starts; let it run.

PHASE 3 RUN
- Opening prompt is the only prompt identical between models.
- Interactive: follow-ups diverge naturally per each model's responses.
- Interactive: 5+ meaningful turns, at least 1h per model, hard stop at 2.5h.
- Async: single prompt, uninterrupted, 15+ min per model.
- Push for complete solutions; do not accept partial work.
- Track which window is which model so ratings map correctly.
- Exit each session with /exit BEFORE closing the terminal. Closing first
  loses metadata and the task cannot be used. Exit can take minutes.

BEHAVIORAL ISSUE LOGGING (real time, while agents run)
Per issue record: model (A/B), issue type, direct transcript quote,
description with context, severity.
Severity: Blocking / Major / Minor / Observation.
Accuracy over volume. Expect 3+ on complex tasks. Zero flags gets reviewed.
Full issue-type taxonomy is in Appendix C.

PHASE 4 RATING
Individual ratings, 1-5, per model, scored separately (do not compare):
  Task Success, Instruction Following, Interaction Quality, Code Quality,
  Thoroughness, Communication Quality.
Head-to-head, 0-7, across four criteria (direct comparison):
  Overall Performance, Instruction Following, Time to Resolution, Vibe.
Scale: 0-1 strong Model A, 2 moderate A, 3-4 slight/tie, 5-6 moderate B,
  7 strong Model B.
Every head-to-head criterion needs written reasoning citing specific evidence
(a quote, a decision, a failure). "A was better than B" is not enough.
Also: General Behavioral Insights (per model) and self-reported Time Spent
(metadata only, does not affect acceptance).

HARD RULES
- Do NOT paste success criteria or the high-level task goal into a session.
  Doing so removes what the comparison measures.
- Prompt as a real user would; the criteria are for evaluation only.
- Task difficulty is settled in pre-work and is no longer audited; reviewers
  audit accuracy of feedback and whether ratings line up with it.

PAY
- Sprint: $85/hr plus $200 bonus per accepted task. Insightful required.
- Fraud monitored (quality, throughput, time logs). No GenAI authoring.
