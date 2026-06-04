---
name: aixgrcxfsi-linkedin-posts
description: Format guide for the 'AI×GRC×FSI Signals' LinkedIn series. Punchy, emoji-heavy, 3-signal posts with sources in a numbered comment.
triggers:
  - "AIxGRCxFSI Signals"
  - "LinkedIn post AI GRC FSI"
  - "AI governance signals post"
  - "APRA ASIC AI LinkedIn"
category: productivity
---

# AI×GRC×FSI Signals — LinkedIn Post Format

## Header

```
📡 AI×GRC×FSI Signals [Date]
```

## Structure

**Default:** Exactly 3 signals. Each signal gets:

1. **Emoji cluster + headline** — one line
2. **Body paragraph** — 2-3 sentences max, punchy, no fluff

### Bonus signal

When the user asks to add an extra signal (e.g. "add a bonus signal"), insert a **4th signal** marked as `BONUS` in the headline. Use the same emoji cluster + headline + body format, but label it clearly:

```
✝️ ☁️ BONUS: [Headline] (Date)
```

The bonus signal is typically from a non-regulatory but authoritative source (e.g., Vatican encyclical on AI governance, G7 communiqué, major academic report) that adds a moral, philosophical, or geopolitical lens to the compliance conversation.

### Signal types and emoji patterns

| Signal | Emoji | Tone |
|--------|-------|------|
| Global/threat | 🎯 🌐 or 🌐 | Serious, urgent, pull-quote |
| Australia/APRA/ASIC | 🇦🇺 | Regulatory, call-to-action |
| AWS/product drop | 💸 🤖 or ☁️ 💪🏽 📈 | Enthusiastic, capability-focused |
| Bonus/moral authority | ✝️ ☁️ or 🌍 | Philosophical, fiduciary framing |

### Closing

Always end with:
```
☁️ 💪🏽 📈
```

## Style Rules

- **One strong takeaway per signal** — a pull quote, stat, or implication
- **No long paragraphs** — max 2-3 sentences
- **Conversational but authoritative** — e.g. "What is refreshing is...", "Super exciting capability!"
- **No hashtags in the post body** — hashtags go in the first comment if at all
- **Sources in a numbered comment** — not the main post body

## Style Rules

- **One strong takeaway per signal** — a pull quote, stat, or implication
- **No long paragraphs** — max 2-3 sentences
- **Conversational but authoritative** — e.g. "What is refreshing is...", "Super exciting capability!"
- **No hashtags in the post body** — hashtags go in the first comment if at all
- **Sources in a numbered comment** — not the main post body

## Signal Freshness Filter

**Before writing, verify the signals are from the current month.** The user explicitly rejected dated signals and demanded "late May and June 2026" items.

- **Global**: Check IMF blog, EU AI Act updates (European Commission AI Office), IOSCO/FSB pronouncements, G7 AI governance communiques, White House EO (whitehouse.gov/presidential-actions)
- **Australia/APRA**: Check APRA System Risk Outlook, APRA media releases, ASIC newsroom, ASIC Chair speeches (Tech Council of Australia panels), RBA pronouncements
- **AWS**: Check AWS ML blog for announcements in the current month, AWS Security Agent/DevOps Agent updates, Bedrock AgentCore releases, Amazon Q updates. **Tip:** For recent announcements, also browse `aboutamazon.com/news/aws` — it is more navigable than the AWS ML blog for finding the latest drops.
- **Red flags**: If a signal is from >3 months ago, it's too stale for this series unless it's a major regulation just coming into force (e.g., CPS 230 effective date)

## Source Quality & Verification

**Primary sources only — not secondary news articles.** The user explicitly demands "more direct sources" for signals and rejects paraphrased news coverage.

### When the user says "find more direct sources"

This is a **workflow trigger**. Immediately:
1. Search for the primary source URL (regulator, AWS, White House, Vatican)
2. Verify the URL resolves (not a 404 or placeholder)
3. Extract direct pull-quotes from the primary source
4. Update the post with the verified URLs and quotes
5. **Never leave `[link]` placeholders in the sources comment**

### Source categories (in priority order)

| Category | Where to look | Examples |
|----------|-------------|----------|
| Government regulators | Official media releases, letters, speeches | APRA.gov.au, ASIC.gov.au, whitehouse.gov |
| AWS official | `aboutamazon.com/news/aws` or `aws.amazon.com/blogs/machine-learning` | Bedrock announcements, AgentCore updates |
| International bodies | IMF blog, IOSCO, FSB, G7 communiqués | Systemic risk pronouncements |
| **Moral/philosophical authority** | **Vatican encyclicals, academic reports, major ethics boards** | **Papal encyclicals on AI, MIT AI governance reports** |
| Secondary (last resort) | Reuters, Financial Standard, InvestorDaily | Only if primary is unavailable; explicitly note it |

**APRA.gov.au URL slug hunting technique:** APRA's CMS encodes special characters in URL slugs (e.g., apostrophes become `%E2%80%99`). The link from the news listing page may 404. If this happens, click the link in the browser, then use `window.location.href` in the browser console to retrieve the actual resolved URL. The working slug often differs from the displayed href.

**Example:** The APRA System Risk Outlook release dated 21 May 2026 appeared as a broken link in the listing, but the resolved URL was:
`https://www.apra.gov.au/news-and-publications/apra%E2%80%99s-latest-system-risk-outlook-highlights-resilience-as-geopolitical-and-0`

**AWS announcements:** `aboutamazon.com/news/aws` is more browseable than the AWS ML blog for finding the latest drops. Use the browser to scroll the listing and click the relevant headline.

**Vatican sources:** Vatican encyclicals are published at `vatican.va/content/<pope>/en/encyclicals/documents/`. They are primary sources with direct moral authority on AI governance. Extract pull-quotes from the table of contents sections (e.g., "Artificial intelligence", "Responsibility, transparency and the governance of AI"). The full text is often very long; focus on the section headers and opening paragraphs of each relevant section.

## References

- `references/example-posts.md` — Full example posts from the 27 May 2026 reference and the 4 June 2026 session post
- `references/signal-freshness-checklist.md` — Checklist for verifying signals are fresh before writing
- `references/june-2026-sources.md` — Verified primary sources with URLs and pull-quotes for the 4 June 2026 post (White House EO, APRA SRO + AI letter, OpenAI on Bedrock)