# AI-DLC Governance Orchestrator — Session Reference

Session date: 2026-05-29
User: kdeath83
Project: `/Users/kdeath83/Desktop/ai-dlc-governance-orchestrator/`

## Context

User analyzed an AWS blog post "AI-Driven Development Lifecycle for Financial Services" (Silvia Prieto, Jean-Francois Landreau, Richard Caven, 26 May 2026). The user asked for three build ideas, then a combined prototype, then pressure-tested assumptions, then built and deployed.

## Prototype Architecture

### CLI Modules

1. **generate** (`src/generate/index.ts`) — Creates jurisdiction-specific steering files (YAML)
   - Supports MAS-SG, EU-AI-ACT, AU-APRA
   - Outputs to `.dlc/steering/default.yaml`
   - Config includes: security rules, allowed regions, AI agent limits, human review gates

2. **audit** (`src/audit/index.ts`) — Validates commit traceability
   - Checks commit messages for requirement ticket references
   - Heuristic AI code detection (regex on diff content)
   - Verifies steering file presence in repo
   - Reports: commitCount, linkedCommits, aiDetected, unlinkedCommits

3. **gate** (`src/gate/index.ts`) — Classifies changes as material or routine
   - Regex patterns per jurisdiction for material files (api, auth, encryption, risk, etc.)
   - Routine patterns: CSS, markdown, tests, docs
   - Returns: `status: 'PASS' | 'BLOCK'`, materialFiles, routineFiles
   - `classifyFile()` exported for unit testing

### CDK Stack (`cdk/lib/dlc-gov-stack.ts`)

- S3 bucket: `dlc-gov-steering-${account}-${region}`, versioned, encrypted
- DynamoDB: `DlcGovAuditTrail`, on-demand, GSI by timestamp
- Lambda: `DlcGovHandler`, Node 20, 1024MB, 30s timeout
- API Gateway: `dlc-gov-api`, REST, CORS, `/generate`, `/audit`, `/gate`

### Containerization

- `Dockerfile`: `node:20-alpine`, multi-stage build
- Entrypoint: `node dist/cli.js`

### Deploy Script

- `deploy.sh`: checks prerequisites, AWS auth, installs, bootstraps, deploys
- GitHub Actions workflow: `.github/workflows/dlc-gov.yml`

### Test Results

- 8 tests passed across 2 suites (generate, gate)
- `npm run build`: 0 tsc errors
- CLI smoke test: `generate` produces valid YAML

## Known Limitations (Acknowledged)

- Steering file schema is not standardized
- AI code detection is regex-based, easily gamed
- Materiality classification lacks semantic understanding
- Jurisdiction rules are principle-based, not algorithmic
- Audit module requires git context (unavailable in Lambda)
- "Audit-ready" reports are meta-evidence, not real audit trails
- The 6-engineer Amazon result doesn't generalize

## Key Decisions

- TypeScript CLI with separate CDK subproject
- Jurisdictions stored as TypeScript objects for type safety
- `classifyFile()` exported specifically for testing
- Monorepo structure: root CLI + `cdk/` subdirectory
