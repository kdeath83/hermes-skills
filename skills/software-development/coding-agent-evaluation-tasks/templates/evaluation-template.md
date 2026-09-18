Model Evaluation Template - Project C Sprint

One copy per task. Model A and Model B run in parallel from one identical
snapshot, with the same auto-injected opening prompt.

Task ID: <from Studio Task Setup>
Repo: <github url>
Interaction Mode: Interactive / Async
Date: <date>

Model A name:
Model B name:

Setup Confirmed

init.py run, Okta login done, repo cloned: Yes / No
model_a/claude-dev and model_b/claude-dev both launched: Yes / No
Animal code names confirmed on both, no /login used: Yes / No
logs/model_a and logs/model_b present: Yes / No

Opening Prompt (auto-injected, identical for both)

<paste the opening prompt here for reference>

Important: do not paste the success criteria or the task goal into either
session. Prompt each model as a real user would. What you measure is how the
model gets there, not how well it follows a spec you handed it.

Behavioral Issue Log (fill in real time while both models run)

Copy this block per issue. Aim for accuracy, not volume.

Issue 1
Model: A or B
Issue type: <one of the 13 from the behavioural guide>
Transcript quote: <verbatim>
Description: <what happened, with context>
Severity: Blocking / Major / Minor / Observation

Issue 2
Model: A or B
Issue type:
Transcript quote:
Description:
Severity:

Issue 3
Model: A or B
Issue type:
Transcript quote:
Description:
Severity:

(continue as needed)

Interaction Log

Model A turns:
A1:
A2:
A3:
A4:
A5:

Model B turns:
B1:
B2:
B3:
B4:
B5:

Individual Ratings (do these FIRST, one score per model, no comparing)

Score 1-5. 1 poor, 5 excellent. Give written feedback with each score.

Task Success - how well did the agent complete the task you set out to do?
  A:   B:   feedback:
  (1 Failed completely / 2 Partial with major issues / 3 Completed with notable
   problems / 4 Successful with minor issues / 5 Completely successful)

Instruction Following - followed instructions and intent without missing details?
  A:   B:   feedback:
  (1 Ignored repeatedly / 2 Missed important / 3 Followed most / 4 Followed
   nearly all / 5 Perfect adherence)

Interaction Quality - avoided failure modes, or issues showed up?
  A:   B:   feedback:
  (1 Critical blocker / 2 Major, overcame with prompting / 3 Periodic issues /
   4 Only noticeable on close attention / 5 No behavioral issues)

Code Quality - well written, maintainable, matches codebase style?
  A:   B:   feedback:
  (1 Critically bad / 2 Mediocre, inconsistent / 3 Adequate / 4 Good, in line
   with codebase / 5 Excellent, indistinguishable from codebase)

Thoroughness - understood and implemented with minimal hand-holding?
  A:   B:   feedback:
  (1 Failed most, constant input / 2 Failed many, frequent input / 3 Solved most,
   occasional input / 4 Solved nearly all, minimal input / 5 Complete
   understanding, no input needed)
  For async: judge how well it handled ambiguity and decided autonomously.

Communication Quality - how clearly did it communicate?
  A:   B:   feedback:
  (1 Cannot be understood / 2 Hard to follow / 3 Understandable with effort /
   4 Clear on first read / 5 Clear, exact, to the point)

Head-to-Head Preference (0 to 7)

Model A anchors 0, Model B anchors 7. Write reasoning that cites specific
evidence for each criterion. "A was better than B" is not enough.

Scale: 0 strong A / 1-2 moderate A / 3-4 slight or tie / 5-6 moderate B / 7 strong B

Overall Performance - which output did you prefer?
  score:   reasoning:

Instruction Following - which followed instructions and intent more accurately?
  score:   reasoning:

Time to Resolution - which got to a working solution faster, less rework?
  score:   reasoning:

Vibe - which was more pleasant to work with (tone, pacing, feedback handling)?
  score:   reasoning:

General Behavioral Insights (per model, always say which model)

Model A:
Model B:

Time Spent

Self-reported total (model runs plus feedback). Metadata only.

Total time:

