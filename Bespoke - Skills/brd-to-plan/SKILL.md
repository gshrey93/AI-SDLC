---
name: brd-to-plan
description: "Convert an approved Business Requirements Document (BRD/PRD) into a structured, executable plan.md file that downstream AI coding agents (GitHub Copilot, mxcli, Claude Code) can execute step-by-step. Use whenever a developer says 'generate plan from BRD', 'create implementation plan', 'break down BRD', or attaches a BRD/PRD before starting build. Do NOT use for pure requirements clarification (that is a TPM task before G0)."
stage_gate: "G0 → G1"
priority: High
version: 1.0
grounded_in:
  - "AWS Well-Architected Framework – Reliability Pillar (Design Principles)"
  - "AWS Generative AI Lens – Prompt engineering & context grounding"
  - "Google Cloud Architecture Framework – Operational excellence"
  - "Anthropic Claude Code – spec-driven development pattern"
---

# BRD-to-Plan Conversion

## Purpose

Transform a natural-language Business Requirements Document into a machine-executable `plan.md` that is:
- **Traceable** — every task cites the BRD section that justifies it.
- **Deterministic** — steps are ordered by dependency, not by BRD narrative.
- **Reviewable** — Architect can approve/reject at task granularity before code is generated.

This is the **first AI-DLC activity** after G0 sign-off and the primary input for every downstream skill.

## When to invoke
- A file matching `**/BRD*.md`, `**/PRD*.md`, `**/requirements*.docx` is attached.
- The user says: *"generate plan"*, *"break down this BRD"*, *"convert requirements to plan"*.
- G0 checklist is confirmed complete (BRD approved, archetype identified, ARB done).

## Inputs (required)
| Input | Source | Required? |
|---|---|---|
| `BRD.md` or `PRD.md` | User-attached, or `docs/BRD.md` | ✅ Mandatory |
| Application archetype | `Mendix` / `Bespoke` / `RAG-LLM` / `Agentic` / `Data-Eng` / `API-Integration` | ✅ Mandatory |
| Domain model / ER diagram | `docs/domain.md` or Figma link | ⚠️ Recommended |
| NFRs (perf, security, availability) | BRD Section 8 or separate `NFR.md` | ✅ Mandatory |
| Figma / wireframes | Figma URL or exported HTML | ⚠️ If UI in scope |

**HARD STOP if BRD is not provided.** Ask the TPM to attach it; do not fabricate requirements.

## Workflow

### Step 1 — Ingest and classify
1. Read the BRD end-to-end.
2. Classify the application by archetype (from G0 checklist).
3. Extract: user roles, primary entities, integrations, functional scope, NFRs, compliance context (GxP / ITGC / DPIA?).
4. Emit a **Coverage Table** showing which BRD sections mapped to which plan sections. Flag unmapped sections.

### Step 2 — Draft `plan.md` using the standard template

```markdown
# plan.md — <Project Name>

<!-- AI-DLC generated | skill: brd-to-plan v1.0 | model: <model> | prompt-id: <uuid> -->

## 0. Metadata
- Project code / IRIS ID: …
- Archetype: Mendix | Bespoke | RAG-LLM | Agentic | Data-Eng | API-Integration
- TPM: … | Architect: … | Dev Lead: …
- Compliance flags: [GxP] [ITGC] [DPIA required] [PHI] [Sensitive]

## 1. Scope summary
Two-paragraph summary of what will and will NOT be built.

## 2. Domain model
- Entities, relationships (mermaid ER diagram), attributes with types & constraints.

## 3. Architecture decisions (from ARB)
- Pattern, cloud services, model tier per task.

## 4. Task backlog (dependency-ordered)
### T-001 — <Task name>
- **BRD ref:** §3.2, §4.1
- **Skill to invoke:** `figma-to-page` / `api-integration` / …
- **Inputs:** Figma frame `Login-01`, entity `User`
- **Acceptance criteria:** …
- **Owner:** AI + <human reviewer>
- **Gate impact:** contributes to G2 checklist item …

## 5. Cross-cutting concerns
- Security model, audit trail, data classification.

## 6. Test plan seed
- Business scenarios → `playwright-e2e`.
- Coverage target: ≥ <threshold from G3>.

## 7. Out of scope
## 8. Open questions (BLOCKERS)
## 9. Provenance
```

### Step 3 — Validate before emitting
- Every task cites a BRD section number.
- Tasks are dependency-ordered.
- Every archetype-appropriate skill is referenced (Mendix builds must reference `mxcli` context files).
- NFRs are captured as measurable acceptance criteria.
- Open questions block Architect sign-off.
- Provenance block populated.

### Step 4 — Write to `docs/plan.md` and open a PR
- Branch: `feature/plan-<jira-id>`; label: `ai-generated`, `awaits-architect-review`.
- PR body: paste the Coverage Table.

## Guardrails
1. **Redact secrets** before including any BRD section in the prompt. If found, halt and warn.
2. **Never invent requirements.** If BRD is ambiguous, list it under §8 Open Questions.
3. **Model tier:** use Claude Opus 4.6 or GPT-4.1 (Best Practice #4).
4. **Human review is mandatory.**
5. **Prompt audit:** call `prompt-audit-trail`.

## Stage-gate mapping
- **G0:** *"Is initial plan.md generated from BRD?"*
- **G1:** *"Does the context pack include BRD/PRD, domain model, security model, APIs, folder structure…"*
- **G2:** *"Is AI-generated output mapped back to plan.md, story, requirement or design item?"*

## References
- AWS Well-Architected Framework – *Design Principles for Reliability*
- AWS Prescriptive Guidance – *Machine Learning best practices: prompt engineering*
- Google Cloud Architecture Framework – *Operational excellence*
- Anthropic – *Claude Code: spec-driven workflows*
