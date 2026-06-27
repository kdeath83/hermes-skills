# Mercor Task Spec — Fillable Template

Keep this open alongside Studio. Copy-paste fields as you go.

---

## Repository & Tags

| Field | Value |
|-------|-------|
| **Repo Name** | |
| **GitHub URL** | `https://github.com/<owner>/<repo>` |
| **Primary Language** | e.g. Python, Go, TypeScript, Rust, Java |
| **Task Type** *(one)* | Debugging / Deployment / CodeReview / Feature / ProductInteraction / Refactoring / Testing / SystemDesign / Scoping / Migration / Other |
| **Domain(s)** *(all that apply)* | Backend / Frontend / DevOps / MLE-Data / Other |
| **Interaction Mode** | Interactive / Async |

---

## Opening Prompt

> *Write in first-person, like a Slack message or ticket. Match style to mode below.*

**Mode: Interactive** — short, realistic, coworker tone. No spec sheets.

```
<your prompt here — 3-8 sentences, high-level goal, realistic ambiguity>
```

**Mode: Async** — self-contained. Goal + acceptance criteria + verification stated upfront.

```
<your prompt here — includes AC, verification steps, constraints>
```

---

## Rationale #1: Why would frontier models struggle with this?

```
<Name the specific mechanism. Race condition? Cross-file invariant? Subtle edge case?>
```

---

## Rationale #2: What does this codebase do?

```
<Stack + file count + key modules. 2-3 sentences.>
```

---

## Rationale #3: What issues/gaps and how would a developer start solving them?

```
<Concrete gap + realistic first step (failing test, trace the flow, etc.).>
```

---

## Pre-Submit Checklist

- [ ] Public GH repo, not restricted
- [ ] 200+ code files, enterprise-grade
- [ ] Realistic production scenario
- [ ] Concrete, testable "done"
- [ ] Multi-file change (5-15+ files)
- [ ] L5+ SWE difficulty
- [ ] Task Type matches actual work
- [ ] Prompt matches Interaction Mode
- [ ] Rationales specific, own words
- [ ] AutoQC passes