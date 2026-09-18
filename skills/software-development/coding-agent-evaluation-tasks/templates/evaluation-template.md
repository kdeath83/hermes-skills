Model Evaluation Template - Project C Sprint

One copy per task. Model A and Model B run in parallel from one identical snapshot, with the same auto-injected opening prompt. One task at a time.

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

Important: do not paste the success criteria or the high-level task goal into either session, in full or in part. Prompt each model as a real user would and work toward the goal through the session. What is measured is how the model gets there, not how well it executes a specification you handed it.

Behavioral Issue Log (fill in real time while both models run)

Accuracy first, volume second. No minimum. Flag what you genuinely observe and nothing you do not. Note: multiple submissions with 0 flags get pulled for Quality audits.

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
A6:
A7:

Model B turns:
B1:
B2:
B3:
B4:
B5:
B6:
B7:

Individual Ratings (do these FIRST, one score per model, no comparing)

Score 1-5. 1 poor, 5 excellent. Every score needs written feedback that supports it. Score high where earned and low where not.

Task Success - how well did the agent complete the task you set out to do?
  A:   B:   feedback:
  1 Failed completely / 2 Partial success with major issues / 3 Completed but with notable problems / 4 Successful with minor issues / 5 Completely successful

Instruction Following - did it follow your instructions and intent without missing important details?
  A:   B:   feedback:
  1 Repeatedly ignored instructions / 2 Missed important instructions / 3 Followed most / 4 Followed nearly all / 5 Perfect adherence to instructions and user intent

Interaction Quality - did it avoid behavioral failure modes, or did issues show up?
  A:   B:   feedback:
  1 Critical blocker / 2 Major issue, overcame with prompting / 3 Periodic issues, not a major impediment / 4 Only noticeable when paying close attention / 5 No behavioral issues

Code Quality - is the code well written, maintainable, and consistent with the codebase style?
  A:   B:   feedback:
  1 Critically bad, unacceptable deviation / 2 Mediocre, noticeably inconsistent / 3 Adequate / 4 Good, in line with codebase / 5 Excellent, indistinguishable from codebase

Thoroughness - could it understand and implement requests with minimal hand-holding?
  A:   B:   feedback:
  1 Failed most of the task, constant user input / 2 Failed many tasks, frequent user input / 3 Solved most tasks, occasional user input / 4 Solved nearly all, minimal user input / 5 Complete understanding, no user input needed
  Async tasks: judge how well it handled ambiguity and made reasonable autonomous decisions. Lower scores reflect poor judgement calls, ignored edge cases, or outcomes that would force the user to re-run the task.

Communication Quality - how clearly did the model communicate with you?
  A:   B:   feedback:
  1 Cannot be understood at all / 2 Hard to follow; wrong words, jargon, or messy structure / 3 Understandable with effort; vague or wordy in places / 4 Clear on first read; minor wording or length issues / 5 Clear, exact, and to the point

Head-to-Head Preference (0 to 7)

Model A anchors 0, Model B anchors 7. Each criterion is a direct comparison, not two separate scores. Score plus written reasoning citing specific evidence - a quote, a decision it made, a failure you hit. "Model A was better than Model B" is not enough.

Scale: 0 strong preference A / 1-2 moderate A / 3-4 slight preference or tie / 5-6 moderate B / 7 strong preference B

Overall Performance - taking everything together, which output did you prefer?
  score:   reasoning:

Instruction Following - which followed your instructions and intent more accurately?
  score:   reasoning:

Time to Resolution - which got to a working solution faster, with less rework?
  Judge which side reached a working solution sooner, measured in agent working time. If one session sat idle while you were busy with the other, that idle time does not count against it. Judge from the agent's point of view, not the wall clock.
  score:   reasoning:

Vibe - which was more pleasant to work with (tone, pacing, how it handled feedback)?
  score:   reasoning:

General Behavioral Insights (per model, always say which model)

Per-model observations on how each agent behaved across the task: how it responds to feedback, how verbose or overconfident it is, and any notable quirks.

Model A:
Model B:

Time Spent

Self-report how long the task took - model runs plus feedback. Metadata only: does not affect compensation or whether the task is accepted.

Total time:
