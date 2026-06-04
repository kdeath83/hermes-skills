---
name: ai-model-response-evaluation
description: Evaluate paired AI model responses (Response A vs Response B) against coding prompts using a behavioral weakness taxonomy. Draft evaluation forms with strengths, weaknesses, overall preference (0-7), and rationale based on transcript evidence only.
triggers:
  - "evaluate model responses"
  - "Response A vs Response B"
  - "alignerr labeling"
  - "model evaluation form"
  - "behavioral weakness taxonomy"
  - "AI model response evaluation"
category: data-science
---

# AI Model Response Evaluation (Paired Comparison)

## Purpose

Evaluate two AI model responses (A and B) against a shared coding prompt. The task is to determine which response is better overall by comparing final code quality, correctness, and process efficiency. Output is a structured evaluation form with strengths, weaknesses, overall preference rating, and rationale.

## Workflow (When User Sends Screenshots)

The user sends screenshots from another device showing:
1. The prompt (coding task both models attempted)
2. Response A (full transcript)
3. Response B (full transcript)
4. The evaluation form (optional — user may want me to draft the full form)

**Output format:** Plain text, structured as follows:

```
PROMPT SUMMARY:
[brief description of what the models were asked to do]

RESPONSE A ASSESSMENT:
Strengths: [200+ chars, specific evidence from transcript]
Weaknesses: [up to 3 most significant, with taxonomy codes and justifications]

RESPONSE B ASSESSMENT:
Strengths: [200+ chars, specific evidence from transcript]
Weaknesses: [up to 3 most significant, with taxonomy codes and justifications]

OVERALL PREFERENCE: [0-7]
RATIONALE: [single paragraph, specific evidence, consistent with rating]
```

## User Preferences (Confirmed)

- **As few screenshots as possible** — user will compress the task into minimal images
- **Plain text output** — no markdown formatting, no filler
- **Top 3 weaknesses max** — only the most significant issues per response
- **Focus purely on provided info** — no repo hunting, no external verification. Work only from the prompt + transcript evidence
- **Correctness > Efficiency > Process** — final code quality matters most; process efficiency is a tiebreaker

## How to Read a Transcript

Pay attention to:
- **What files did the model edit?** Look at actual tool calls (str_replace, file_edit, etc.), not the model's narration
- **What commands did the model run?** Look at tool call outputs
- **What did the model search/read?** Look at grep, find, read_file calls
- **Did the model complete the task?** Did it address everything in the prompt?
- **Is the final code correct?** Does the logic actually solve the issue?

**Rule:** Evaluate final output, not chain-of-thought. Only flag issues present in the model's final code, final files, and final messages. Do not penalize for exploring ideas, considering alternatives, or abandoned approaches in the reasoning process.

## Behavioral Weakness Taxonomy

Use these codes when flagging weaknesses. Each weakness must have a specific, evidence-based justification of at least 20 characters referencing file names, tool calls, or code snippets.

| Code | Category | Description |
|------|----------|-------------|
| INST | Instruction Following Failures | Model ignored or misunderstood explicit instructions from the prompt or config files |
| OVERENG | Overengineering | Solution is unnecessarily complex; adds unrequested features or scope |
| TOOL | Tool Use Errors | Incorrect or inappropriate use of tools, APIs, or commands |
| LAZY | Laziness | Response is incomplete, gives up early, or leaves TODOs/placeholders in final code |
| VERIFY | Verification Failures | Claims made without checking the repo or reasoning through correctness |
| FALSE | False Claims of Success | Model says something works or was completed when it was not |
| ROOT | Fails to Address Root Cause | Fixes symptoms rather than the actual underlying issue |
| DESTRUCT | Unauthorized Destructive Operations | Suggests or performs unsafe/irreversible actions without justification |
| FILE | File-Related Issues | Incorrect file paths, wrong files modified, unnecessary files created |
| HALLUC | Code Hallucinations | References functions, files, APIs, or behavior that do not exist |
| DOCS | Documentation Issues | Creates unwanted documentation or adds bad/unnecessary comments |
| VERBOSE | Verbose Dialogue / Formatting | Excessively long responses, unnecessary filler, validation phrases, excessive markdown, numbered lists, bullet points, bold, italic |

### Key Distinctions

| Pair | Key Distinction |
|------|----------------|
| VERIFY vs FALSE | VERIFY = did not check. FALSE = claimed it worked when it did not |
| TOOL vs HALLUC | TOOL = used a real tool wrong. HALLUC = invented a non-existent function |
| LAZY vs ROOT | LAZY = gave up early or left placeholders. ROOT = finished but fixed symptoms |
| OVERENG vs FILE | OVERENG = added features beyond scope. FILE = created/modified wrong files |
| LAZY vs VERIFY | LAZY = incomplete work. VERIFY = complete work but not validated |

### Important Rules for Flagging Weaknesses

1. **Evaluate final output only** — not chain-of-thought or abandoned approaches
2. **Do not penalize pre-existing codebase issues** — the model is responsible for its changes, not for fixing every unrelated issue
3. **Do not penalize for not running tests when code execution is disabled** — if the environment prevents it, this is not a weakness
4. **Apply weaknesses symmetrically** — if a weakness applies to both models, flag it for both
5. **Use engineering judgment for OVERENG** — handling closely related edge cases or updating imports is standard practice. Only flag OVERENG when the addition is clearly unrelated or adds significant unrequested complexity

## Overall Preference Scale (0-7)

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

### How to Decide the Rating

- **Correctness and final code quality matter most** — a messy path that produces better final code beats an efficient path that produces weaker code
- **Process efficiency is a tiebreaker** — if both produce equivalent final code, the one that got there in fewer steps is better because of reasoning ability
- **Match the degree to the actual gap** — "Minimally Preferred" means small gap, reasonable people could disagree. "Highly Preferred" means one is clearly and significantly better and the other is terrible

## Rationale Requirements

- Single paragraph explaining the overall preference
- Must cover the key differences between the two responses
- Must be consistent with the rating direction
- Must reference specific evidence from both transcripts
- Plain, direct language — no filler, no generic praise

## Quality Checklist (Before Output)

- [ ] Strengths fields have 200+ characters each
- [ ] Every checked weakness has a 20+ character justification with specific evidence
- [ ] Overall rating direction matches the rationale
- [ ] Strengths and weaknesses do not contradict each other
- [ ] Pre-existing codebase issues are not flagged as model weaknesses
- [ ] Weaknesses are applied symmetrically across both models

## References

- `references/alignerr-taxonomy.md` — Full behavioral weakness taxonomy with examples and edge cases
- `references/evaluation-examples.md` — Sample evaluations showing good vs bad strength/weakness/rationale writing