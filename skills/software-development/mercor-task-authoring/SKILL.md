---
name: mercor-task-authoring
description: Author coding-task specs for Mercor Project C — code model evaluation pre-work. Covers repo selection, prompt writing, rationales, QC, and Studio submission.
---

# Mercor Project C — Task Authoring Workflow

## Setup
- Slack via Okta, display name as real name
- Insightful time tracking (X11/Xorg only)
- Workramp assessment from mail@workramp.com — gates Mercor Studio provisioning
- Watch tutorial videos: Accessing Studio, Creating Tasks, Using AutoQC

## Repo Selection
- Public GitHub, 200+ code files, enterprise-grade (not tutorial)
- NOT on restricted list: GCP k8s-config-connector, AWS CLI, Netflix TLS Cert Creation
- Personal projects OK if public, 200+ files, extended commit history, not AI-generated, consent to LLM training

## Classification

### Interaction Mode
| Mode | Turns | Prompt Style | Duration |
|------|-------|-------------|----------|
| Interactive/Pairing | 5+ meaningful turns | Short, realistic, coworker tone | ~2.5h |
| Async/Autonomous | Runs unattended | Self-contained, AC+verification upfront | 15+ min |

### Domain (Tag all that apply)
| Domain | Target Mix |
|--------|-----------|
| Backend | 45% |
| Frontend | 15% |
| DevOps/SRE | 15% |
| MLE/Data | 10% |
| Other | 15% |

### Task Type (Pick ONE primary)
| Type | Target Mix |
|------|-----------|
| Debugging | 18% |
| Deployment/DevOps | 18% |
| Code Review | 15% |
| Feature Development | 9% |
| Product Interaction | 9% |
| Refactoring | 6% |
| Testing | 6% |
| System Design | 5% |
| Requirement Scoping | 3% |
| Migration | 2% |
| Other | 9% |

## Writing the Opening Prompt
- **Interactive**: realistic request a dev would send a coworker. Short. No spec-sheet lists or code blocks. Difficulty from codebase context and ambiguity.
- **Async**: self-contained with goal, AC, verification steps. Not step-by-step. Model runs alone.
- **Must include**: high-level task goal defining what "done" looks like for reviewer.
- **Avoid**: over-prescriptive (bad for interactive), under-specified (bad for async), copying examples (rejected as duplicative).

## Three Rationale Questions (Be specific — generic = rejected)

1. **"Why would frontier models struggle?"** — Name concrete mechanism: race condition, cross-file fix, subtle invariant, idempotency gap, etc.
2. **"What does this codebase do?"** — Stack, size (~300 files), key modules. Prove you know it.
3. **"What issues/gaps and how would a dev start?"** — Concrete gap + realistic first step (usually a failing test).

## Quality Bar
- Commercial realism, 200+ files, L5+ SWE difficulty
- Multi-file change (~5-15+ files), not single-file or tutorial
- Non-obvious: not solvable in one turn, not already solved in repo
- Clear testable "done"

## Studio Submission Flow
1. **+ Create Task** (top right of Tasks view)
2. **Repository & Tags card**: repo name + public GH URL, primary language, task type (1), domain(s), interaction mode
3. **Opening Prompt card**: write per Phase 3 rules
4. **Three Rationale answers**: write per Phase 4 rules
5. **Run AutoQC**: fix failures, re-run until pass
6. **Submit for Review** (Writer Actions card) → inputs lock → Awaiting Review
7. If submit fails: error toast at top, check all required fields

## Checklist Before Submit
- [ ] Public GH repo, not restricted, 200+ files, enterprise-grade
- [ ] Realistic scenario, concrete goal, multi-file, non-obvious
- [ ] L5+ difficulty, testable "done"
- [ ] All tags set correctly
- [ ] Prompt matches interaction mode
- [ ] Three rationales specific, own words
- [ ] AutoQC passes

## If Bounced
- Read Writer Feedback
- Fix issues, re-run AutoQC, resubmit

## Compensation
- $85/hr, ~1hr per task
- Insightful tracking mandatory
- No GenAI for authoring — fraud monitored
