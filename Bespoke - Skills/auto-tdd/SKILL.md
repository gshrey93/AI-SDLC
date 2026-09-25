---
name: auto-tdd
description: "Auto-generate a Technical Design Document (TDD) from an AI-built application: architecture diagrams, domain model, sequence diagrams for key flows, security model, integrations, NFRs, data classification, deployment view, and traceability back to the BRD/plan.md. Trigger when the user says 'generate TDD', 'create technical design doc', 'document the architecture', 'handover doc', during G2 generation, or at G7 operate handover."
metadata:
  stage_gate: "G2 -> G7"
  priority: "High"
  owner: "Vishali / Architect"
  version: "1.0"
  grounded_in:
    - "arc42 template - standard architecture documentation"
    - "C4 model - Simon Brown, software architecture diagrams"
    - "AWS Well-Architected - documentation as code"
    - "Google Cloud - Architecture documentation best practices"
---

# Auto-Generated Technical Design Document (TDD)

## Purpose
Eliminate hand-written TDDs by generating them **from the source of truth** — plan.md, code, IaC, OpenAPI specs — so the document never lies about what shipped. Auditable, versioned, re-generated on every release.

## When to invoke
- User says *"generate TDD"*, *"technical design document"*, *"architecture doc"*, *"handover pack"*.
- G2 checklist item for architecture baseline and implementation traceability.
- G7 checklist item *"TDD and documentation archived"*.
- On every release tag (CI job).

## Inputs (required)
| Input | Details |
|---|---|
| Repo root | Path |
| plan.md | `docs/plan.md` |
| Contracts | `contracts/*.yaml` (OpenAPI/OData/GraphQL) |
| IaC | `infra/**/*.tf` or Bicep |
| Threat model | `docs/threat-model.md` |
| Security score report | `docs/security/report-<latest>.md` |
| Release tag | Semver |

## Structure (arc42 + C4)

`docs/TDD-v<semver>.md`:
1. **Introduction & Goals** — from plan.md §1.
2. **Constraints** — from plan.md §3 + NFRs.
3. **Context (C4 Level 1)** — Mermaid: system + external actors + integrations.
4. **Container view (C4 Level 2)** — Mermaid of deployable units.
5. **Component view (C4 Level 3)** — per container, key modules.
6. **Runtime scenarios** — sequence diagrams for top 3–5 flows.
7. **Domain model** — ER diagram from schema.
8. **Data classification** — entities × sensitivity.
9. **Security architecture** — from `sso-integration` + `itgc-controls` + threat model.
10. **Integrations** — table from `api-integration` outputs.
11. **Deployment view** — from IaC.
12. **Operations** — SLOs, dashboards, runbooks, on-call.
13. **NFRs & how they are met**.
14. **Testing & quality evidence** — G3 report, coverage, Playwright report.
15. **Compliance evidence** — ITGC, DPIA, prompt-audit summary.
16. **Traceability matrix** — BRD § → plan.md task → PR → test case.
17. **Provenance** — skills, models, prompt-ids used.

## Workflow

### Step 1 — Extract
- Parse plan.md front-matter + sections.
- Parse `contracts/` for integrations.
- Parse IaC for infra topology.
- Parse code annotations (`@component`, `@integration`, `@security`) to build C4 views.
- Read latest security-score report and threat model.

### Step 2 — Synthesise diagrams (Mermaid)
Context (C4-1), runtime sequences, ER model, container view, deployment view.

### Step 3 — Fill sections from source of truth
Never restate — always link and quote. If a section has no source, mark `TODO: architect to fill (blocks G5)`.

### Step 4 — Traceability matrix
| BRD § | plan.md task | PR(s) | Test case(s) | Skill(s) used |
|---|---|---|---|---|
| 3.2 | T-014 | #245 | AC-1 in `dashboard.spec.ts` | figma-to-page, playwright-e2e |

### Step 5 — Diff from previous TDD
`docs/TDD-diff-vX-vY.md`: new components, changed integrations, new NFR risks, resolved TODOs.

### Step 6 — Archive & sign
Store in Confluence + `docs/`; sign with build attestation (cosign / in-toto); reference from release notes.

## Guardrails
1. **Facts only.** Never fabricate; if unknown, TODO.
2. **Sensitive tenant-specific details** referenced by ID, not by value.
3. **Regenerate on every release** — TDD age > release age is a G5 finding.
4. **PII/PHI never appear** even in examples.
5. **Human sign-off required** — Architect approves before archive.
6. **Prompt audit is mandatory** — call `prompt-audit-trail` for each generation/update.

## Outputs
- `docs/TDD-v<semver>.md` + `docs/TDD-diff-vX-vY.md` + Mermaid sources under `docs/diagrams/` + attestation signature.

## Stage-gate mapping
- **G2 – AI Generation:** define and update architecture intent while code is being generated; maintain plan.md-to-code traceability.
- **G3 – Human Review:** provide reviewable architecture context for `code-review-report` and standards checks.
- **G6 – Deployment:** provide release and rollback architecture context in the deployment sign-off pack.
- **G7 – Operate:** archive TDD and handover evidence; capture operational changes and lessons learned.

## References
- arc42 – *Template for software architecture documentation*
- C4 model – *Levels 1–4*
- AWS Well-Architected – *Documentation as code*
- Google Cloud Architecture Framework – *Documentation practices*
