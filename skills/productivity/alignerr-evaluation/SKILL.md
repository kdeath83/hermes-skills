---
name: alignerr-evaluation
description: "Use when evaluating AI model responses (A vs B) against coding prompts for Alignerr. Produces structured evaluation forms with strengths, weaknesses, preference rating, and rationale using the official taxonomy."
version: 1.0.0
author: Hermes Agent
metadata:
  hermes:
    tags: [alignerr, evaluation, ai-models, coding, taxonomy]
---

# Alignerr Model Response Evaluation

## Overview
Evaluate two AI model responses (Response A and Response B) against a coding prompt. Determine which response is better overall by analyzing actual tool calls, file edits, and final code quality. Produce a structured evaluation form with strengths, weaknesses, preference rating, and rationale.

## When to Use
- User sends screenshots of prompt + Response A + Response B from another device
- Task requires evaluating AI model coding transcripts using Alignerr taxonomy
- User says "Alignerr", "model evaluation", "response A vs B", or "coding task review"

## Evaluation Process
1. Read prompt carefully — understand what models were asked to do
2. Read Response A fully — note tool calls, file edits, commands, final code
3. Read Response B fully — same analysis, don't let A bias B
4. Compare and fill out evaluation form

## Output Format

```
PROMPT SUMMARY:
[brief description of what the models were asked to do]

RESPONSE A ASSESSMENT:
Strengths: [200+ chars, specific evidence referencing tool calls, file names, code changes]
Weaknesses: [up to 3 most significant, with taxonomy codes and 20+ char justifications]

RESPONSE B ASSESSMENT:
Strengths: [200+ chars, specific evidence referencing tool calls, file names, code changes]
Weaknesses: [up to 3 most significant, with taxonomy codes and 20+ char justifications]

OVERALL PREFERENCE: [0-7]
RATIONALE: [single paragraph, specific evidence, plain direct language]
```

## Rating Scale (0-7)
| Score | Meaning |
|-------|---------|
| 0 | A Highly Preferred |
| 1 | A Preferred |
| 2 | A Slightly Preferred |
| 3 | A Minimally Preferred |
| 4 | B Minimally Preferred |
| 5 | B Slightly Preferred |
| 6 | B Preferred |
| 7 | B Highly Preferred |

## Behavioral Weakness Taxonomy

| Code | Category | Description |
|------|----------|-------------|
| INST | Instruction Following Failures | Model ignored or misunderstood explicit instructions |
| OVERENG | Overengineering | Unnecessarily complex; adds unrequested features |
| TOOL | Tool Use Errors | Incorrect use of tools, APIs, or commands |
| LAZY | Laziness | Incomplete, gave up early, left TODOs/placeholders |
| VERIFY | Verification Failures | Claims without checking repo or reasoning |
| FALSE | False Claims of Success | Said it worked when it didn't |
| ROOT | Fails to Address Root Cause | Fixed symptoms not underlying issue |
| DESTRUCT | Unauthorized Destructive Operations | Unsafe/irreversible actions without justification |
| FILE | File-Related Issues | Wrong paths, wrong files modified, unnecessary files |
| HALLUC | Code Hallucinations | References non-existent functions/files/APIs |
| DOCS | Documentation Issues | Unwanted documentation or bad comments |
| VERBOSE | Verbose Dialogue/Formatting | Excessively long, filler, validation phrases, excessive markdown |

## Key Distinctions
- VERIFY vs FALSE: VERIFY = didn't check. FALSE = claimed it worked when it didn't.
- TOOL vs HALLUC: TOOL = used real tool wrong. HALLUC = invented non-existent function.
- LAZY vs ROOT: LAZY = gave up early. ROOT = finished but fixed symptoms.
- OVERENG vs FILE: OVERENG = added features beyond scope. FILE = wrong files.
- LAZY vs VERIFY: LAZY = incomplete work. VERIFY = complete but not validated.

## Critical Rules
1. **Evaluate final output only** — not chain-of-thought, abandoned approaches, or reasoning process
2. **Do not penalize pre-existing codebase issues** — only what the model changed
3. **Do not penalize for not running tests** when code execution is disabled
4. **Apply weaknesses symmetrically** — flag for both if it applies to both
5. **Correctness > Efficiency** — messy path with better final code beats clean path with worse code
6. **Evidence > Assumptions** — only flag what you can back with transcript evidence
7. **Final Code > Process** — outcome matters more than how they got there

## Quality Checks Before Submitting
- [ ] Strengths fields have 200+ characters each
- [ ] Every checked weakness has 20+ char justification with specific evidence
- [ ] Overall rating direction matches rationale
- [ ] Strengths and weaknesses do not contradict
- [ ] No pre-existing codebase issues flagged as model weaknesses
- [ ] Weaknesses applied symmetrically across both models

## Common Pitfalls
1. **Rating-Rationale Inconsistency** — if you say A is better, rate must favor A
2. **Scope Misunderstanding** — don't penalize for doing what the task required
3. **Confusing Process with Outcome** — efficiency is tiebreaker, not primary criterion
