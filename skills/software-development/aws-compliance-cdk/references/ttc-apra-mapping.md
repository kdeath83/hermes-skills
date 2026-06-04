# AWS Threat Technique Catalog to APRA CPS 234/230 Mapping

Reference for the built-in technique catalog data used in the compliance CDK stack.

## Technique Catalog

| ID | Name | Tactic | APRA Controls | Severity | Key CloudTrail Events |
|---|---|---|---|---|---|
| T1562.008 | Disable Cloud Logs | Defense Evasion | CPS234.24, CPS234.27, CPS230.12 | CRITICAL | `cloudtrail:StopLogging`, `DeleteTrail`, `UpdateTrail` |
| T1562.007 | Disable Cloud Firewall | Defense Evasion | CPS234.25, CPS234.27, CPS234.28 | HIGH | `ec2:DeleteSecurityGroup`, `wafv2:DeleteWebACL` |
| T1530.A001 | S3 Object Collection | Collection | CPS234.29, CPS234.27, CPS234.28 | HIGH | `s3:GetObject`, `s3:ListBucket` |
| T1098.001 | Additional Cloud Credentials | Persistence | CPS234.26, CPS234.25, CPS234.27 | HIGH | `iam:CreateAccessKey`, `sts:GetFederationToken` |
| T1484.002 | Trust Modification | Privilege Escalation | CPS234.26, CPS234.25, CPS234.27 | CRITICAL | `iam:CreateOpenIDConnectProvider`, `iam:CreateSAMLProvider` |
| T1531 | Account Access Removal | Impact | CPS234.28, CPS234.24, CPS234.30 | CRITICAL | `iam:DeleteUser`, `iam:DeleteRole` |
| T1496 | Data Destruction | Impact | CPS234.29, CPS234.28, CPS234.30 | CRITICAL | `s3:DeleteBucket`, `rds:DeleteDBInstance`, `ec2:DeleteSnapshot` |
| T1580 | Cloud Storage Discovery | Discovery | CPS234.27, CPS234.29 | MEDIUM | `s3:ListBuckets`, `s3:GetBucketPolicy` |

## Control Coverage

Each technique generates 4 control types:

| Technique | PREVENT | DETECT | RESPOND | CORRECT |
|---|---|---|---|---|
| T1562.008 | SCP deny log tampering | CloudTrail + GuardDuty | EventBridge + Lambda | Config auto-remediation |
| T1530.A001 | S3 Block Public Access | GuardDuty + S3 data events | S3 bucket isolation | Config rule |
| T1484.002 | SCP deny IdP creation | CloudTrail + IAM Access Analyzer | IAM credential revocation | Config rule |
| T1531 | SCP deny IAM deletion | CloudTrail metric filters | IAM access key revocation | Backup to S3 |
| T1496 | S3 Object Lock | CloudTrail + GuardDuty | S3 bucket isolation | RDS snapshot retention |

## Cross-Technique Controls

| Control ID | Name | Techniques | Type |
|---|---|---|---|
| CROSS-LOG-INTEGRITY | Audit Log Integrity Enforcement | T1562.008, T1496 | PREVENTIVE |
| CROSS-DATA-EXFIL | Data Exfiltration Prevention | T1530.A001, T1580 | DETECTIVE |

## APRA Control Requirements

| Code | Name | CPS Section | Covered Techniques |
|---|---|---|---|
| CPS234.24 | Audit Logging | CPS 234 | T1562.008, T1531 |
| CPS234.25 | Access Control | CPS 234 | T1562.007, T1098.001, T1484.002 |
| CPS234.26 | MFA and Credential Management | CPS 234 | T1098.001, T1484.002 |
| CPS234.27 | Monitoring and Detection | CPS 234 | All techniques |
| CPS234.28 | Incident Response | CPS 234 | T1531, T1496, T1562.007 |
| CPS234.29 | Data Protection | CPS 234 | T1530.A001, T1496, T1580 |
| CPS234.30 | Test Control | CPS 234 | All (canary tests) |
| CPS230.12 | Risk Management | CPS 230 | T1562.008 |
