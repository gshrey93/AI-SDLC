---
name: security-scoring
description: "Run an AI-assisted security assessment on generated code and produce a numeric security score (0-100) plus a prioritized remediation list. Covers SAST, dependency (SCA), secret scanning, IaC misconfig, container scan, and LLM-specific risks (OWASP LLM Top 10). Trigger when the user says 'security scan', 'security score', 'is this secure?', 'pre-release security check', or before G4."
stage_gate: "G4"
priority: High
owner: Vishali / DevSecOps
version: 1.0
grounded_in:
  - "OWASP Top 10 (2021)"
  - "OWASP LLM Top 10 (2025)"
  - "OWASP API Security Top 10 (2023)"
  - "NIST SSDF (SP 800-218) & NIST AI RMF"
  - "AWS Well-Architected – Security Pillar"
  - "Google Cloud Architecture Framework – Security"
  - "CIS Benchmarks (Docker, Kubernetes)"
---

# Security Scoring & Validation

## Purpose
Produce a **repeatable, evidence-backed security score** for any AI-DLC deliverable. Score is derived from six weighted dimensions, each backed by open-source scanners; the skill orchestrates them and interprets findings.

## When to invoke
- User says *"security scan"*, *"security score"*, *"is this secure?"*, *"pre-release security"*, *"OWASP check"*.
- Before G4 gates. On every PR to `main` (as CI job).

## Inputs (required)
| Input | Details |
|---|---|
| Target | Repo root or specific module |
| Stack | `node-ts`, `java`, `python`, `mendix`, `dotnet`, `terraform`, `docker` |
| App classification | `GxP` \| `SOX` \| `PII/PHI` \| `Public` |
| LLM used at runtime? | Yes/No |
| Baseline threshold | Default: 80 |

## Scoring model (0–100)
| Dimension | Weight | Toolchain | Blocker rule |
|---|---|---|---|
| Static analysis (SAST) | 25 | Semgrep, CodeQL, SonarQube CE | any Critical → blocker |
| Dependency (SCA) | 20 | OSV-Scanner, Trivy, `npm audit`, OWASP Dep-Check | Critical CVE w/ fix → blocker |
| Secret scanning | 15 | Gitleaks, TruffleHog | verified secret or detector confidence >= 0.9 → blocker |
| IaC misconfig | 10 | Checkov, tfsec, kube-linter | any Critical → blocker |
| Container scan | 10 | Trivy image, Grype | Critical fixable → blocker |
| LLM-specific | 20 | Custom rules for OWASP LLM Top 10 | any Critical → blocker |

For non-LLM apps, redistribute the LLM weight proportionally.

Scoring formula:
- Compute per-dimension deduction ratio: `R = min(1, 0.10 x (1.0 x Critical + 0.5 x High + 0.2 x Medium + 0.05 x Low))`.
- Compute per-dimension score: `DimensionScore = Weight x (1 - R)`.
- Compute total score: `Score = sum(DimensionScore across all dimensions)`.

Severity factors: Critical=1.0, High=0.5, Medium=0.2, Low=0.05.

## Workflow

### Step 1 — Discover the toolchain
Detect stack from lockfiles / `pom.xml` / `Dockerfile` / `.tf`. Install missing scanners via `.security/tools.lock`.

### Step 2 — Run scans in parallel
Each scanner writes normalized SARIF to `.security/reports/`.

### Step 3 — LLM Top 10 checks (if runtime uses LLM)
Custom Semgrep + audit rules for:
- **LLM01 Prompt Injection** — user input concatenated into system prompts.
- **LLM02 Sensitive Info Disclosure** — logs/output with PII/PHI.
- **LLM03 Supply Chain** — model source not pinned/verified.
- **LLM04 Data & Model Poisoning** — RAG store writeable by users without moderation.
- **LLM05 Improper Output Handling** — LLM output rendered as HTML without sanitisation.
- **LLM06 Excessive Agency** — agents with write/delete tool permissions w/o human confirmation.
- **LLM07 System Prompt Leakage** — system prompt in error messages.
- **LLM08 Vector/Embedding weakness** — embeddings not filtered by tenant.
- **LLM09 Misinformation** — no confidence gating on critical outputs.
- **LLM10 Unbounded Consumption** — no token / rate limiting per user.

### Step 4 — Threat model diff
If AI-generated code introduces a new trust boundary → require updated `docs/threat-model.md`. Missing → blocker.

### Step 5 — Compute score and emit report
`docs/security/report-<yyyy-mm-dd>.md` with dimension scores, prioritized findings, exception requests.

### Step 6 — Auto-open remediation tickets
Each finding → Jira ticket labelled `security-<severity>` with file+line ref, suggested fix, owner (from CODEOWNERS).

### Step 7 — Gate outcome
Score ≥ threshold AND blockers == 0 → G4 PASS. Else FAIL.

## Guardrails
1. **No silent suppression.** Any `# nosec` / `nosemgrep` must have Jira ID with expiry.
2. **Do NOT run scanners against production data.**
3. **False positives require justification** in `.security/suppressions.md`.
4. **Exceptions expire.** Default 90 days.
5. **Vendor terms verified** — external AI tools must satisfy no-training + retention.

## Outputs
- `.security/reports/*.sarif` + `docs/security/report-<date>.md` + Jira tickets + CI status + `.security/suppressions.md`.

## Stage-gate mapping
- **G4 – Security, Privacy & Compliance:** every checklist item — SAST, SCA, secret, container, critical/high, prompt audit, AI threat model, DPIA, DAST, exceptions.
- **G4 – Deployment Approval:** *"Security scoring ≥ threshold"*.

## References
- OWASP – *Top 10 (2021), API Top 10 (2023), LLM Top 10 (2025)*
- NIST – *SP 800-218 SSDF*, *AI RMF 1.0*
- AWS Well-Architected – *Security Pillar: detection, incident response*
- CIS Benchmarks – *Docker, Kubernetes*
