---
name: aws-cdk-prototype
description: Build a minimal deployable CLI tool with AWS CDK infrastructure, containerization, and a one-click deploy script. For art-of-the-possible demos, internal tools, and governance utilities.
triggers:
  - "build a prototype"
  - "one click deploy"
  - "art of the possible"
  - "deploy to AWS"
  - "CDK stack"
  - "governance tool prototype"
  - "showcase the art of the possible"
category: software-development
---

# AWS CDK Prototype

Build a minimal deployable CLI tool with AWS CDK infrastructure, containerization, and a one-click deploy script. For art-of-the-possible demos, internal tools, and governance utilities.

## Philosophy

The user asks for prototypes that **showcase the art of the possible**. This means:
- Build the minimal viable thing that demonstrates the concept
- Acknowledge limitations openly — don't pretend a prototype is production
- One-click deploy is the goal: `./deploy.sh` should stand up the full stack
- Tests should pass, but coverage can be shallow — the point is a working demo

## Trigger

Load this skill when the user says any of:
- "build a prototype"
- "one click deploy into AWS"
- "showcase the art of the possible"
- "deploy this to AWS"
- "CDK stack for [tool name]"
- "make this deployable"

## When to Use

- Art-of-the-possible demos for internal stakeholders
- Governance utility prototypes (see `aws-compliance-cdk` for production-grade compliance architectures)
- One-off CLI tools that need AWS infrastructure
- Proof-of-concept deployments

## When NOT to Use

- Production-grade compliance control architectures (use `aws-compliance-cdk` instead)
- Multi-account security fabric deployments
- Regulated environments requiring audit-ready evidence

## Related Skills

- `aws-compliance-cdk` — Production-grade compliance and security control architectures for regulated environments (APRA, MAS, EU AI Act). Use this when the user asks for compliance CDK, threat technique catalog integration, Security Hub, or continuous control validation.
- `aws-cdk-prototype` — This skill. Use for minimal demos, prototypes, and one-click deploy tools.

## Architecture

The standard shape is a monorepo with two parts:

```
project-root/
  src/              # CLI core (TypeScript)
  cdk/              # AWS CDK infrastructure
  tests/            # Jest tests
  Dockerfile        # Container for Lambda or ECS
  deploy.sh         # One-click deploy
  .github/workflows/  # CI template
  examples/         # Sample outputs
```

### CLI Core (`src/`)

- TypeScript, Node >=18
- Commander.js for CLI structure
- Minimal modules: generate, audit, gate, validate
- Each module exports a pure function for testability
- Shared types in `src/shared/types.ts`

### CDK Infrastructure (`cdk/`)

- Separate `package.json` with `aws-cdk-lib` and `constructs`
- Stack includes: Lambda, API Gateway, DynamoDB, S3
- Lambda handler imports the CLI core as a library
- API Gateway with CORS, API key optional

### Containerization

- `node:20-alpine` base
- Multi-stage build: install → build → runtime
- Lambda uses the same image or a separate slim build

### Deploy Script

- `deploy.sh` checks prerequisites (AWS CLI, Node, npx)
- `aws sts get-caller-identity` for auth verification
- `npm install` in both root and `cdk/`
- `cdk bootstrap` if needed
- `cdk deploy --require-approval never`
- Idempotent — safe to run multiple times

## Workflow

### Step 1: Define the tool surface

Ask the user (or infer from context):
- What does the tool do? (generate, audit, gate, classify)
- What jurisdictions or domains? (MAS-SG, EU-AI-ACT, etc.)
- What is the output artifact? (YAML, JSON, report)

### Step 2: Build the CLI core

```bash
mkdir -p src/{generate,audit,gate,shared} tests
cat > package.json << 'EOF'
{
  "name": "prototype-tool",
  "version": "0.1.0",
  "scripts": {
    "build": "tsc",
    "test": "jest",
    "lint": "eslint src/"
  },
  "dependencies": {
    "commander": "^12.0.0",
    "js-yaml": "^4.1.0",
    "chalk": "^5.3.0"
  },
  "devDependencies": {
    "typescript": "^5.4.0",
    "jest": "^29.0.0",
    "ts-jest": "^29.0.0",
    "@types/node": "^20.0.0",
    "@types/jest": "^29.0.0",
    "@types/js-yaml": "^4.0.0",
    "@types/aws-lambda": "^8.10.0"
  }
}
EOF
```

TypeScript config:
```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "CommonJS",
    "outDir": "dist",
    "strict": true,
    "esModuleInterop": true,
    "types": ["node", "jest"]
  }
}
```

### Step 3: Build the CDK stack

```bash
mkdir -p cdk/lib cdk/bin
cat > cdk/package.json << 'EOF'
{
  "dependencies": {
    "aws-cdk-lib": "^2.140.0",
    "constructs": "^10.3.0"
  }
}
EOF
```

Stack essentials:
- S3 bucket with versioning and encryption
- DynamoDB table with on-demand billing
- Lambda function (Node 20, 1024MB, 30s timeout)
- API Gateway REST API with `/generate`, `/audit`, `/gate` endpoints
- IAM roles with least privilege

### Step 4: Write the Dockerfile

```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build
ENTRYPOINT ["node", "dist/cli.js"]
```

### Deploy Script (Enhanced)

The basic template is sufficient for demos. For production-like prototypes, use the enhanced version with:
- `--region` and `--profile` CLI options
- Pre-flight prerequisite checks with clear error messages
- AWS account validation
- Banner with target region
- Stack outputs written to `cdk-outputs.json` for downstream scripts
- Post-deploy summary and teardown instructions

```bash
#!/usr/bin/env bash
set -euo pipefail

# Parse options
REGION="${CDK_DEFAULT_REGION:-ap-southeast-1}"
AWS_PROFILE="${AWS_PROFILE:-}"
while [[ $# -gt 0 ]]; do
  case "$1" in --region) REGION="$2"; shift 2;; --profile) AWS_PROFILE="$2"; shift 2;; *) echo "Unknown option: $1"; exit 1;; esac
done

AWS_OPTS=""
[[ -n "$AWS_PROFILE" ]] && AWS_OPTS="--profile $AWS_PROFILE"
export CDK_DEFAULT_REGION="$REGION"

# Banner
echo ""
echo "=========================================="
echo "AI-DLC Governance Orchestrator — AWS Deploy"
echo "Target: $REGION"
echo "=========================================="
echo ""

# Prerequisites
echo "→ Checking prerequisites..."
for cmd in aws node npx; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "  ✗ Missing: $cmd"; exit 1; }
  echo "  ✓ $cmd"
done

# Auth check
aws sts get-caller-identity $AWS_OPTS >/dev/null 2>&1 || { echo "  ✗ AWS credentials not configured. Run: aws configure"; exit 1; }
ACCOUNT=$(aws sts get-caller-identity $AWS_OPTS --query Account --output text)
echo "  ✓ AWS authenticated (account: $ACCOUNT)"

# Install & Build
echo "→ Installing dependencies..."
npm install
cd cdk && npm install && cd ..
echo "→ Building TypeScript..."
npm run build

# Bootstrap
echo "→ Bootstrapping CDK in $REGION..."
cd cdk
npx cdk bootstrap --region "$REGION" $AWS_OPTS --require-approval never

# Deploy
echo "→ Deploying stack..."
npx cdk deploy --region "$REGION" $AWS_OPTS --require-approval never --outputs-file ../cdk-outputs.json
cd ..

# Summary
echo ""
echo "✓ Deploy complete"
echo "Stack outputs written to: cdk-outputs.json"
echo ""
echo "Next steps:"
echo "  1. Retrieve API key value from API Gateway console"
echo "  2. Test: curl -X POST <ApiUrl>/generate -H 'x-api-key: <key>'"
echo "  3. Delete: npx cdk destroy --force (from cdk/ directory)"
echo ""
```

### Post-Deploy: API Testing

After deploy, retrieve the API key from `cdk-outputs.json` and test endpoints:

```bash
API_URL=$(cat cdk-outputs.json | python3 -c "import json,sys; d=json.load(sys.stdin); print(list(d.values())[0]['ApiUrl'])")
API_KEY=$(aws apigateway get-api-key --api-key-id $(cat cdk-outputs.json | python3 -c "import json,sys; d=json.load(sys.stdin); print(list(d.values())[0]['ApiKeyId'])") --include-value --query value --output text)

curl -X POST "$API_URL/generate" \
  -H "x-api-key: $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"jurisdiction":"MAS-SG","output":"/tmp/steering"}'
```

### Stack Outputs

The `cdk deploy --outputs-file cdk-outputs.json` pattern captures:
- `ApiUrl` — the API Gateway endpoint
- `ApiKeyId` — the API key ID (retrieve value via `aws apigateway get-api-key`)
- `SteeringBucketOutput` — S3 bucket name
- `AuditTableOutput` — DynamoDB table name

### Step 6: Write tests

- `tests/generate.test.ts` — steering file generation
- `tests/gate.test.ts` — materiality classification
- `tests/audit.test.ts` — commit traceability (if git context available)
- Export internal functions for unit testing

### Step 7: Verify locally

```bash
npm install
npm run build
npm test
node dist/cli.js <command> --help
```

## Security Hardening

Prototypes accumulate security debt quickly because the focus is "does it work?" rather than "is it safe?". After the core builds, run a systematic security/performance/logic review before any deployment.

### Review Workflow

1. Read every module that touches: user input, file system, child processes, network, environment variables
2. Check for the common patterns below
3. Remediate and verify: `npm run build` → `npm test` → `cdk synth` → local smoke test
4. Document findings in the session reference

### Common TypeScript/Node.js Security Patterns

| Pattern | Risk | Remediation |
|---|---|---|
| `JSON.parse(event.body)` without try-catch | Lambda crash on malformed JSON | Wrap in try-catch, return 400 |
| `execSync(command + userInput)` | Command injection | Sanitize input with regex whitelist, use `--` separator |
| `process.exit()` in library modules | Kills Lambda container, breaks error handling | Replace with `throw` + attach `{statusCode}` for HTTP mapping |
| `fs.writeFile(path.resolve(userInput), ...)` | Path traversal | Add `isSafePath()` guard — only allow cwd, `/tmp`, system temp |
| `new RegExp(userPattern)` | Crash on invalid regex | Wrap in try-catch, log invalid pattern, continue classification |
| `Access-Control-Allow-Origin: '*'` | Overly permissive CORS | Remove or restrict to known origins |
| `console.error(err.message)` to client | Error message leakage | Return generic "Internal error" for 500, specific message only for 400 |

### CDK-Specific Security Patterns

| Pattern | Risk | Remediation |
|---|---|---|
| `apiKeyRequired: false` on API Gateway methods | Open API without authentication | Set `apiKeyRequired: true` on all non-OPTIONS methods |
| IAM policy `resources: ['*']` | Overly broad permissions | Remove explicit CloudWatch Logs policy — Lambda execution role handles it automatically |
| Missing `cdk.json` | `cdk synth` fails with "--app is required" | Create `cdk.json` with `app: "npx ts-node bin/cdk.ts"` |
| `CfnOutput` ID same as resource ID | Construct name collision, synth fails | Append `Output` to output IDs (e.g., `SteeringBucketOutput`) |
| `pointInTimeRecovery: true` | Deprecated API warning | Use `pointInTimeRecoverySpecification: { pointInTimeRecoveryEnabled: true }` |
| `rootDir` in `cdk/tsconfig.json` with `include: ["bin/**/*", "lib/**/*"]` | `tsc` error: file not under rootDir | Remove `rootDir` from cdk tsconfig |
| Lambda asset path wrong | `Cannot find asset` error | `lambda.Code.fromAsset('../dist')` when `cdk/lib/stack.ts` is two levels below root |
| `.env` in Docker build | Secrets leak into image | Create `.dockerignore` with `.env`, `*.pem`, `*.key` |

### After Remediation

- `npm run build` — clean compile
- `npm test` — all suites pass
- `cdk synth` — valid CloudFormation template
- `node dist/cli.js <command>` — smoke test
- `cdk/cdk.json` — exists and points to correct entry point

## Pitfalls

### Missing `@types/aws-lambda`

If the Lambda handler uses `APIGatewayProxyEvent`, tsc will fail with `Cannot find name 'APIGatewayProxyEvent'`. Install `@types/aws-lambda` as a devDependency:

```bash
npm install -D @types/aws-lambda
```

### CDK bootstrap not done

First-time deploy fails with `Environment needs to be bootstrapped`. The deploy script must run `cdk bootstrap` before `cdk deploy`.

### Volume mount shadows image contents

If deploying the container to a platform with persistent volumes (Fly.io, ECS with EFS), a mount at the same path as `COPY` in the Dockerfile hides the copied files. Seed config onto the volume after deployment, or mount at a subdirectory.

### tsc strict mode catches prototype shortcuts

The user wants minimal code, but `strict: true` in tsconfig will reject implicit any, unchecked nulls, and missing return types. Fix these inline rather than disabling strict mode — the type safety is worth the extra lines.

### Git context not available in Lambda

The `audit` module may need git history. In Lambda, the function only sees the deployed code, not the repo. Either:
- Pass the repo as a Lambda layer (impractical for large repos)
- Run `audit` only in CI/CD where git context exists
- Stub the audit module in Lambda and run it locally or in CI

### One-click deploy needs AWS credentials

`deploy.sh` calls `aws sts get-caller-identity`. If the user hasn't configured AWS credentials, this fails. The script should print a clear error and suggest `aws configure`.

## Verification Checklist

- [ ] `npm run build` compiles with zero errors
- [ ] `npm test` passes all suites
- [ ] `node dist/cli.js <command>` produces expected output
- [ ] `cdk synth` produces a valid CloudFormation template
- [ ] `./deploy.sh` completes without prompts
- [ ] Deployed API Gateway endpoints respond with 200
- [ ] README includes architecture diagram, CLI usage, and known limitations

## Session-Specific References

- `references/ai-dlc-orchestrator.md` — Full AI-DLC Governance Orchestrator prototype session
- `references/security-hardening-session.md` — Code review findings and remediation for the prototype above
