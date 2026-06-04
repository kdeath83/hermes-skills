# AIxFSIxGRC Content Series — Signal Categories and Sources

The user maintains a recurring LinkedIn series called **AIxFSIxGRC** (AI × Financial Services × Governance Risk Compliance). Posts synthesize recent regulatory and vendor signals into actionable takeaways for regulated FSI audiences. The standard format is three sections:

1. **Global signals** — EU AI Act enforcement, Singapore MAS guidance, IOSCO/FSB pronouncements
2. **Australia-specific signals** — APRA CPS 230/234, ASIC AI enforcement posture, OAIC guidance
3. **AWS-specific signals** — AWS Security Agent, DevOps Agent, Bedrock, SageMaker, Threat Technique Catalog releases

## Drafting notes

- Lead with a tension statement (e.g., "adoption vs. defensibility gap widening")
- Each section needs 2–4 concrete, dated signals with source attribution
- Close with a "what I'm building" hook that ties back to the AI Governance Toolkit (GitHub repos, CDK constructs, control mappings)
- Tag set: #AI #Governance #Risk #Compliance #APRA #ASIC #EUAIAct #AWS #FinancialServices #ML #GenAI #CPS230 #CPS234
- Tone: factual, evidence-backed, concise. Avoid fluff and generic AI hype.

## Source health

- **APRA** and **ASIC** sites are aggressively bot-blocked. Direct page navigation often returns 404s even for valid URLs. Fallback: use memory of known frameworks (CPS 230, CPS 234, ASIC AI guidance) and official publication dates from prior verified sessions.
- **AWS ML Blog** (`aws.amazon.com/blogs/machine-learning/`) is accessible and reliable for AWS AI product announcements.
- **EU AI Act** and **Singapore MAS** signals are usually accessible via official press releases and regulatory notices.

## Recurring themes to map

| Signal | Toolkit tie-in |
|--------|----------------|
| APRA CPS 230 operational resilience | Service provider management, tolerance statements, impact assessments |
| APRA CPS 234 control testing | AWS Threat Technique Catalog → control mapping, canary tests, ASFF findings |
| ASIC AI enforcement / robo-advice | Algorithmic decision-making risk management, model drift detection |
| AWS Security Agent GA | Continuous pentesting replacing manual cycles, CPS 234.30 satisfaction |
| AWS DevOps Agent | Incident MTTR reduction for board-level operational resilience metrics |
| Bedrock / AgentCore / MCP | Governance constructs for agentic workloads, auth flow, tool-use guardrails |

When the user says "LinkedIn post following the AIxFSIxGRC series", load this skill and use the above structure to draft the post. Prioritize the user's existing memory over live web search if bot blocks are encountered.
