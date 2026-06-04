# AWS Incident Response Playbooks Integration

Session reference for integrating AWS Incident Response Playbooks into the compliance control fabric.

## Source

- Repository: `https://github.com/aws-samples/aws-incident-response-playbooks`
- Playbooks: `IRP-CredCompromise.md`, `IRP-DataAccess.md`, `IRP-Ransomware.md`
- AI Playbooks: `ai-playbooks/README.md` (steering files for AI incident response)

## NIST 800-61 Mapping

Each playbook follows the NIST 800-61 incident response lifecycle:

1. **Preparation** — Verify the Threat Control Fabric is deployed, services are enabled
2. **Detection & Analysis** — Confirm IoCs, identify compromised resources, classify data
3. **Containment, Eradication, and Recovery** — Isolate resources, revoke credentials, restore from backups
4. **Post-Incident Activity** — Post-mortem, playbook update, Game Day test

## Playbook JSON Schema

```json
{
  "name": "IRP-CredCompromise",
  "incidentType": "Credential Leakage/Compromise",
  "techniqueIds": ["T1098.001", "T1484.002", "T1531"],
  "nistPhases": ["Detection and Analysis", "Containment, Eradication, and Recovery", "Post-Incident Activity"],
  "awsServices": ["IAM", "CloudTrail", "GuardDuty", "Detective", "Athena", "SecurityHub"],
  "aiEnabled": true,
  "references": [
    "https://github.com/aws-samples/aws-incident-response-playbooks/blob/master/playbooks/IRP-CredCompromise.md"
  ],
  "phases": [
    {
      "name": "Acquire, Preserve, Document Evidence",
      "nistPhase": "Detection and Analysis",
      "steps": [
        {
          "stepNumber": 1,
          "description": "Confirm IoCs from GuardDuty, Security Hub, or CloudWatch alarms",
          "services": ["GuardDuty", "SecurityHub", "CloudWatch"],
          "automated": true,
          "lambdaFunction": "cloudtrail-processor",
          "evidence": ["GuardDuty finding", "Security Hub finding"]
        }
      ]
    }
  ]
}
```

## Required Step Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `stepNumber` | integer | Yes | Unique within phase, 1-indexed |
| `description` | string | Yes | Human-readable action |
| `services` | string[] | Yes | AWS services involved |
| `automated` | boolean | Yes | Whether a Lambda handles this step |
| `lambdaFunction` | string | Conditional | Which Lambda if `automated: true` |
| `evidence` | string[] | Yes | Artifacts to collect for audit |

## Playbook Coverage

| Playbook | TTC Techniques | Key Services | NIST Phases |
|----------|---------------|--------------|-------------|
| IRP-CredCompromise | T1098.001, T1484.002, T1531 | GuardDuty, Detective, Athena, IAM | Detection, Containment, Eradication, Recovery, Post-Incident |
| IRP-DataAccess | T1530.A001, T1580 | Macie, Access Analyzer, S3, Athena | Detection, Containment, Eradication, Recovery, Post-Incident |
| IRP-Ransomware | T1496 | Detective, EBS, Backup, GuardDuty | Detection, Containment, Eradication, Recovery, Post-Incident |

## Service Integration Notes

### Amazon Detective
- Used for relationship analysis and baseline deviation detection
- Requires enabling in the target region before incident response
- Provides time-based analysis for IoC confirmation

### Amazon Macie
- Used for S3 data classification and public bucket discovery
- Requires enabling in the target region
- Generates summary reports across the Organization

### IAM Access Analyzer
- Used for external access findings (S3 bucket policies, IAM role trust policies)
- External access analyzer must be created per region
- Findings feed into the Detection & Analysis phase

### CloudTrail Insights
- Enables anomaly detection on API call rates
- Must be enabled on the CloudTrail trail
- Detects unusual patterns like `cloudtrail:StopLogging` spikes

## AI Steering File

The Hermes agent skill should include:
- Keyword-based incident classification mapping to TTC techniques
- Technique-specific response steps from the playbooks
- Evidence preservation rules (KMS, Object Lock, 7-year retention)
- Communication and escalation matrix (P0-P2)
- Tool references (Dashboard URL, API endpoint, Athena workgroup, Security Hub)

Copy to skills directory:
```bash
mkdir -p ~/.hermes/skills/apra-incident-response
cp skills/incident-response/SKILL.md ~/.hermes/skills/apra-incident-response/
```

## Integration Steps

1. Browse the AWS IR Playbooks repository
2. Extract the NIST 800-61 phases and ordered steps from each playbook
3. Map each step to TTC technique IDs and AWS services
4. Add automation flags and `lambdaFunction` references
5. Store as structured JSON in `src/lib/data/playbooks.json`
6. Add `IncidentResponsePlaybook` type to `src/lib/types.ts`
7. Update the CDK construct to reference the playbook data
8. Add the AI steering file as a project deliverable
