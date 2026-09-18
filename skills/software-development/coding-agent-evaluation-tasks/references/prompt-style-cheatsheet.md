# Prompt Style Cheatsheet (Project T / Taiga)

Rules enforced by user across multiple sessions. Apply these to every prompt.

## Prose rules

1. No em dashes. No en dashes. No hyphens used as punctuation.
2. No backticks around filenames, function names, or code references.
3. No tables. No pipes, no dash separators. Tables become narrative sentences.
4. No bullet points or numbered lists. Everything flows as prose.
5. Natural conversational framing. "What do you think?" over "Deliverable 1: do X."
6. Full-line paragraphs, no manual line breaks. Each paragraph is one long line. Let the rendering engine wrap.
7. No line numbers in prompts. Never reference specific source code line numbers. Describe behavior architecturally.
8. No model-specific field names or references. Never mention "Model A" or "Model B." The prompt goes to a single model.

## Structure

- Open with the mechanism. What is actually happening in the code.
- State a proposed fix direction. "I think the fix is X. But you know this code better."
- Ask whether the fix is correct. Let the model challenge the premise.
- Ask the model to reproduce before fixing.
- Ask for residuals. "What does this fix not cover?"
- Use "OK, you know this code..." and "Let's also..." as transition phrases.
- Token runway at bottom: "Token runway: A [count], B [count]."
- For final turn: "Burn what it takes" or "Burn everything you have left."
- Less prescriptive is better. The model should choose its own approach.

## Burn techniques (proven)

- New code is the ONLY reliable 150K+ burn driver. Documentation-only turns burn 30-60K max.
- Adversarial framing ("try to break your own fixes") is strongest single-turn pattern.
- Full file reproductions with checksums after every write (wc -l, md5sum, od).
- cat output after deliverables: force model to print files in full.
- Mutation proofs with independent runs (each mutation run separately with timestamp).
- Multi-arm regression: 5 arms x 3 runs with timestamps.
- Verification gates: 50-75 check gates with source, logic, and integration checks.
- Fuzzers with mandatory milestone output: "Print violation count after every 1,000 scenarios."

## What NOT to ask for

- Postgres, apt-get, systemd, Docker, external network access. The sandbox lacks them.
- "Burn 150K tokens" as an explicit goal. Models ignore it and infer the task from context.
- Verbose output mandates ("print every check, no summaries"). Models summarize regardless.
- "Build alternative implementations." Models describe alternatives instead of building them.
- Scale amplification as primary driver. Unpredictable (one model executes, one describes).

## Verification

- Every function name, line number, and behavioral claim must be grepped against the source before dispatch.
- If a core mechanism is fabricated, discard the prompt. Do not patch around it.
- Pressure test assertions against BOTH model transcripts when available.
