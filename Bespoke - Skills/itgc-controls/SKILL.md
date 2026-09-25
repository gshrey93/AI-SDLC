---
name: itgc-controls
description: "Generate the ITGC (IT General Controls) module: User Access Management (provision/deprovision/recert), segregation of duties, audit trail on all state-changing actions, change management traceability, and evidence packs for SOX/GxP audits. Trigger when user says 'add ITGC', 'audit trail for X', 'user access management', 'access recert', 'evidence pack'."
stage_gate: "G4"
priority: High
owner: Vishali / DevSecOps
version: 1.0
grounded_in:
  - "COBIT 2019 – IT general controls"
  - "SOX ITGC – common control framework"
  - "GAMP 5 (2nd ed.) – GxP computerized system validation"
  - "AWS Well-Architected – Security Pillar (identity & access, detective controls)"
  - "Google Cloud Architecture Framework – Security (audit logging, IAM)"
---

# ITGC Controls Module

## Purpose
Ensure every AI-DLC-built app ships with the **four ITGC pillars**: (1) Access Management, (2) Change Management traceability, (3) Operations (audit logging & monitoring), (4) Backup/Recovery evidence.

## When to invoke
- User says *"ITGC"*, *"audit trail"*, *"user access management"*, *"access recert"*, *"evidence pack"*, *"GxP controls"*, *"SOX controls"*.
- Any app targeting production, especially GxP-classified.
- Pre-G4 deployment checklist.

## Inputs (required)
| Input | Details |
|---|---|
| App classification | `GxP` \| `SOX` \| `Both` \| `None` |
| Identity provider | Entra ID / Okta / on-prem AD |
| Role model | Roles + entitlements + SoD matrix |
| Data classification | PII / PHI / financial / GxP |
| Retention policy | Min 6y for GxP, 7y for SOX |
| Recertification cadence | Quarterly (default) |

## Workflow

### Step 1 — Access Management module
1. **Provisioning** — SCIM 2.0 or Entra ID JIT via SSO; role from HR attribute.
2. **De-provisioning** — nightly HR reconciliation; disable within 24h of exit.
3. **Access request workflow** — request → manager → app owner → provisioning; logged.
4. **Access recertification** — quarterly; non-response = revoke; evidence 7y.
5. **Emergency (break-glass)** — separate role, MFA-hardened, auto-expires 4h, segregated log.
6. **Segregation of Duties (SoD)** — declarative rules; violations block role grant.

Emit as: `modules/itgc/access/` (UI, backend, DB tables: `user`, `role`, `entitlement`, `access_request`, `recert_campaign`, `sod_rule`).

### Step 2 — Audit trail
Every state-changing action MUST write immutable audit event:
```json
{
  "eventId": "uuid-v7",
  "timestamp": "ISO-8601 UTC",
  "actor": { "userId": "...", "role": "...", "sessionId": "..." },
  "action": "case.approve",
  "resource": { "type": "RetentionCase", "id": "TG-2026-4731" },
  "before": { "status": "PENDING" },
  "after":  { "status": "APPROVED", "reason": "Meets policy" },
  "ip": "10.x.x.x",
  "correlationId": "trace-id",
  "signature": "hmac-sha256(...)"
}
```

Requirements: **immutable storage** (S3 Object Lock / Azure Blob immutability); **tamper evidence** (HMAC per record chained); **retention** (GxP 6y, SOX 7y); **PII masking** (hashed identifiers only); **server time via NTP**.

### Step 3 — Change management traceability
Per release: commit SHA, PR approvers, CAB/eCAB ticket, test evidence (G3), security evidence (G4), rollback plan, signed-off deployment record. Store as `evidence/releases/<version>.json`.

### Step 4 — Backup / recovery evidence
- Nightly backup (encrypted, cross-region for prod).
- Monthly restore-test (isolated env, automated verification).
- RPO/RTO documented in TDD.

### Step 5 — Evidence pack generator
`scripts/itgc-evidence.ts <period>` outputs zip: access recert results, access change log, break-glass usage log, audit log integrity report, backup + restore-test results, change/release records, SoD violations.

### Step 6 — Self-validate before G4
`scripts/itgc-preflight.ts` passes if: all privileged actions have `auditLog.write` calls; audit table append-only grants; SSO enforced; SoD rules defined; backup + last restore ≤ 30 days old.

## Guardrails
1. **Never log plaintext PII/PHI** in audit trail.
2. **Never allow app service account to modify audit records.**
3. **Never disable ITGC in non-prod** — dev/qa mirror controls.
4. **Break-glass must be alertable.**
5. **Evidence packs are read-only and signed.**

## Outputs
- `modules/itgc/` (access + audit + change + backup) + admin UI + `evidence/` + `docs/itgc-matrix.md`.

## Stage-gate mapping
- **G4 – Deployment Approval:** *"ITGC controls verified (UAM, audit trail)"*, *"Compliance checks passed"*.
- **G5 – Post-Deploy:** *"Support handover completed"*.

## References
- COBIT 2019 – *ITGC domains*
- ISACA – *ITGC audit guide for SOX*
- ISPE / GAMP 5 – *GxP data integrity (ALCOA+)*
- AWS Well-Architected – *Security Pillar: detective controls, IAM*
- Google Cloud – *Audit Logs, IAM best practices*
