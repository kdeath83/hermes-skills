# Security Hardening Session — 2026-05-29

Session: code review of the AI-DLC Governance Orchestrator prototype for security/performance/logic bugs, followed by remediation.

## Findings

### CRITICAL

1. **JSON.parse without try-catch in Lambda handler**
   - File: `src/lambda.ts`
   - Malformed JSON in `event.body` crashes the Lambda before the error handler is reached
   - Fix: wrap in try-catch, return 400 with "Invalid JSON in request body"

2. **Command injection via execSync in audit module**
   - File: `src/audit/index.ts`
   - `commitHash` passed directly into `execSync(`git log -1 --format=%B ${commitHash}`)`
   - Fix: add `sanitizeCommitHash()` with whitelist `^[a-zA-Z0-9~^._-]+$`; use `--` separator: `git log -1 --format=%B -- ${commitHash}`

3. **process.exit() in library modules**
   - Files: `src/generate/index.ts`, `src/audit/index.ts`, `src/gate/index.ts`
   - `process.exit(1)` on unknown jurisdiction or audit failure kills the Lambda container
   - Fix: replace with `throw Object.assign(new Error(msg), { statusCode: 400 })`; CLI entry point catches and exits

4. **CDK Lambda asset path wrong**
   - File: `cdk/lib/dlc-gov-stack.ts`
   - `lambda.Code.fromAsset('../../dist')` — `cdk synth` runs from `cdk/` directory, so `../../dist` resolves outside the project
   - Fix: `lambda.Code.fromAsset('../dist')` — relative to `cdk/lib/stack.ts`

5. **CDK construct ID collision**
   - File: `cdk/lib/dlc-gov-stack.ts`
   - `CfnOutput` with ID `SteeringBucket` collides with the S3 bucket construct `SteeringBucket`
   - Fix: rename output to `SteeringBucketOutput` and `AuditTableOutput`

### HIGH

6. **Overly permissive CORS**
   - File: `src/lambda.ts`
   - `Access-Control-Allow-Origin: '*'` on all responses
   - Fix: remove blanket CORS header

7. **API Gateway methods don't enforce API key**
   - File: `cdk/lib/dlc-gov-stack.ts`
   - `addMethod('POST', ...)` without `apiKeyRequired: true`
   - Fix: add `apiKeyRequired: true` to all POST methods

8. **Overly broad IAM CloudWatch policy**
   - File: `cdk/lib/dlc-gov-stack.ts`
   - Explicit `iam.PolicyStatement` with `resources: ['*']` for logs
   - Fix: remove — Lambda basic execution role (`AWSLambdaBasicExecutionRole`) already grants this

9. **gate.getPrFiles() ignores prNumber parameter**
   - File: `src/gate/index.ts`
   - Always falls back to `git diff --name-only HEAD~1 HEAD` regardless of PR number
   - Fix: try `gh pr view ${prNumber} --json files --jq '.files[].path'` first, then fallback

10. **classifyFile() crashes on invalid regex patterns**
    - File: `src/gate/index.ts`
    - `new RegExp(pattern)` with unvalidated jurisdiction patterns — bad regex from config crashes the gate
    - Fix: wrap in try-catch, log invalid pattern, continue to next pattern

11. **Error message leakage to client**
    - File: `src/lambda.ts`
    - `err.message` returned in 500 response body
    - Fix: return `err.message` only for 400 status; generic "Internal error" for 500

### MEDIUM

12. **Path traversal in output and steering paths**
    - File: `src/shared/config.ts`
    - `path.resolve(options.output)` allows writing to any filesystem path
    - Fix: add `isSafePath()` guard — only allows cwd, `/tmp`, `/var/tmp`, or system temp dir

13. **.env files copied into Docker image**
    - File: `Dockerfile`
    - `COPY . .` includes `.env` files
    - Fix: create `.dockerignore` with `.env`, `*.pem`, `*.key`, `*.p12`, `*.crt`

### LOW

14. **DynamoDB pointInTimeRecovery deprecated**
    - File: `cdk/lib/dlc-gov-stack.ts`
    - `pointInTimeRecovery: true` triggers deprecation warning
    - Fix: `pointInTimeRecoverySpecification: { pointInTimeRecoveryEnabled: true }`

15. **CDK tsconfig rootDir mismatch**
    - File: `cdk/tsconfig.json`
    - `rootDir: "./lib"` with `include: ["lib/**/*", "bin/**/*"]` — `bin/cdk.ts` is outside rootDir
    - Fix: remove `rootDir` from cdk tsconfig

16. **Missing cdk.json**
    - Directory: `cdk/`
    - `cdk synth` fails with "--app is required"
    - Fix: create `cdk.json` with `{"app": "npx ts-node bin/cdk.ts"}`

## Remediation Verification

- `npm run build` — clean
- `npm test` — 8/8 pass
- `cdk synth` — valid CloudFormation template
- `node dist/cli.js generate --jurisdiction=MAS-SG` — works
- `node dist/cli.js generate --jurisdiction=UNKNOWN` — exits 1 with error message

## Files Modified

- `src/lambda.ts`
- `src/audit/index.ts`
- `src/gate/index.ts`
- `src/generate/index.ts`
- `src/shared/config.ts`
- `src/cli.ts`
- `cdk/lib/dlc-gov-stack.ts`
- `cdk/tsconfig.json`
- `cdk/cdk.json` (new)
- `.dockerignore` (new)
- `tests/generate.test.ts`
