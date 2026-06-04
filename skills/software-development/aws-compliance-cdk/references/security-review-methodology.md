# Security Review Methodology for CDK Compliance Projects

Structured security review checklist and remediation workflow for AWS CDK compliance and security control architectures.

## When to Run

Run this review before every project delivery, after any major construct change, and when the user asks for a "code review" or "security review."

## Review Process

1. Read every Lambda handler in `assets/lambda/`
2. Read every CDK construct in `src/constructs/`
3. Check IAM policy scope
4. Check error handling patterns
5. Check pagination on all API calls
6. Check CORS configuration
7. Check anomaly detection on common events
8. Check canary test implementations
9. Check VPC/Security Group batching
10. Check Security Hub product ARN format
11. Check session revocation implementation

## Finding Categories

### CRITICAL

Account lockout, data loss, or security control bypass.

| Check | File Pattern | Signal | Fix |
|-------|-------------|--------|-----|
| S3 isolation blocks owner | `s3-isolate.ts` | `Deny` without `aws:PrincipalAccount` | Add `aws:PrincipalAccount` to condition |
| Lambda throws on failure | `asff-publisher.ts` | `throw error` inside try/catch | Return `{ success: false, error }` |
| Invalid product ARN | `SecurityHubEventBridge.ts` | `arn:aws:securityhub:${region}::product` | Use `:${region}:${account}:product` |
| Missing session revocation | `iam-revoke.ts` | No `UpdateAssumeRolePolicy` | Add `UpdateAssumeRolePolicy` to deny AssumeRole |
| CORS wildcard | `dashboard-api.ts` | `Access-Control-Allow-Origin: '*'` | Use `process.env.DASHBOARD_ORIGIN` |

### HIGH

Performance degradation, data truncation, or missed security events.

| Check | File Pattern | Signal | Fix |
|-------|-------------|--------|-----|
| Unpaginated scans | `dashboard-api.ts` | `ScanCommand` without `Limit` or `NextToken` | Add `Limit: 1000` or use `Query` with GSI |
| Unpaginated findings | `incident-classifier.ts` | `GetFindingsCommand` without `NextToken` | Add `do...while` loop with `NextToken` |
| Stub canary tests | `canary-runner.ts` | `return true` without API call | Implement actual AWS API check |
| Sequential VPC revokes | `vpc-isolate.ts` | `RevokeSecurityGroupIngressCommand` in loop | Collect all rules, batch revoke |
| Broad IAM policies | `IncidentResponsePlaybook.ts` | `resources: ['*']` for S3/IAM/EC2 | Scope to specific ARNs or add conditions |
| Common event noise | `cloudtrail-processor.ts` | Alert on `GetObject`/`ListBuckets` without anomaly check | Add `detectAnomaly()` for external IP/root/cross-account |

### MEDIUM

Operational issues or accepted risks that need documentation.

| Check | File Pattern | Signal | Fix |
|-------|-------------|--------|-----|
| Fragile buildspec | `one-click-deploy.yaml` | Inline buildspec without error handling | Add `set -euo pipefail` and bootstrap check |
| Sequential test loop | `canary-runner.ts` | For loop over controls | Document as intentional; parallelize later |
| Auto-delete bucket | `ExecutiveDashboard.ts` | `autoDeleteObjects: true` | Document or use `RETAIN` for production |

## Remediation Output

Create `SECURITY_REVIEW.md` in the project root:

```markdown
# Security Review

## CRITICAL
1. [file] — [finding] — [fix] — [status]

## HIGH
2. [file] — [finding] — [fix] — [status]

## MEDIUM
3. [file] — [finding] — [fix] — [status]
```

Apply all critical fixes before delivery. Document accepted risks with justification.

## Quick Fixes (Copy-Paste)

### S3 isolation with account exemption
```typescript
const denyStatement = {
  Effect: 'Deny',
  Principal: '*',
  Action: ['s3:GetObject', 's3:PutObject', 's3:DeleteObject', 's3:ListBucket'],
  Resource: [`arn:aws:s3:::${bucketName}`, `arn:aws:s3:::${bucketName}/*`],
  Condition: {
    StringNotEquals: {
      'aws:PrincipalTag/apra-emergency-access': 'true',
      'aws:PrincipalAccount': accountId,
    },
  },
};
```

### Graceful error return
```typescript
try {
  await client.send(command);
  return { success: true };
} catch (error) {
  return { success: false, error: (error as Error).message };
}
```

### Security Hub pagination
```typescript
const allFindings: any[] = [];
let nextToken: string | undefined;
do {
  const response = await client.send(new GetFindingsCommand({
    Filters: { ... },
    MaxResults: 50,
    NextToken: nextToken,
  }));
  allFindings.push(...response.Findings || []);
  nextToken = response.NextToken;
} while (nextToken);
```

### Anomaly detection
```typescript
function detectAnomaly(event: any): boolean {
  const sourceIP = event.detail?.sourceIPAddress || '';
  const isExternalIP = !sourceIP.startsWith('10.') && !sourceIP.startsWith('192.168.') && !sourceIP.startsWith('172.');
  const isRoot = event.detail?.userIdentity?.type === 'Root';
  const isCrossAccount = event.detail?.userIdentity?.accountId !== event.account;
  return isExternalIP || isRoot || isCrossAccount;
}
```
