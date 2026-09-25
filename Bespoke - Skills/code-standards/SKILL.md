---
name: code-standards
description: "Enforce DRL coding standards on AI-generated code — anti-pattern detection (nested logic, duplicate entities, cross-dependency, performance risks), naming conventions, role & access completeness, code provenance headers, secrets/credential leak detection, API security validation, and session/RBAC policy adherence. Trigger when user says 'check standards', 'anti-patterns', 'lint compliance', 'add provenance header'."
stage_gate: "G2"
priority: High
owner: Vishali / COE
version: 1.0
grounded_in:
  - "SEI CERT Secure Coding Standards"
  - "OWASP Secure Coding Practices Quick Reference"
  - "AWS Well-Architected – Security & Op-Ex"
  - "Google Style Guides (multi-language)"
  - "Mendix – Best practices & Sigrid quality model"
status: Draft            # Draft → Piloted → Reusable
validated_on: []         # e.g. ["cognito-plus PR#412", "myday-api PR#88"]
success_criteria:
  - "≥95% of seeded anti-patterns detected on the validation fixture set"
  - "0 false-blocker on the approved golden repo"
  - "100% AI-changed files carry a valid provenance header"
  - "All SEC/API/RBAC blockers reproduce deterministically across 2 runs"
reviewers: []            # min 2 names before promotion to Reusable
---

# Coding Standards & Anti-Pattern Detection

## Purpose
Codify DRL coding standards as an executable rule set so AI-generated code never regresses on: anti-patterns, naming, role/access completeness, provenance, secrets, API security, session/RBAC.

## When to invoke
- Any file created/modified.
- User says *"check standards"*, *"anti-patterns"*, *"provenance"*, *"RBAC audit"*.
- Chained from `figma-to-page`, `pattern-based-pages`, `api-integration`, `code-review-report`.

## Inputs
| Input | Details |
|---|---|
| Target | Path (file/folder/repo) |
| Stack | Autodetected |
| DRL standards ruleset | `standards/rules/*.yaml` (versioned) |
| Scope | `full` \| `naming` \| `security` \| `patterns` \| `provenance` |

## Ruleset (illustrative subset)

### Anti-patterns
- **AP-001 Nested-if depth** > 3 → refactor.
- **AP-002 Duplicate entity** — ≥80% attribute overlap → consolidate.
- **AP-003 Duplicate microflow logic** — same call sequence in ≥2 flows → extract sub.
- **AP-004 God module** — module > 40 microflows or file > 800 lines → split.
- **AP-005 Cyclic dependency** between modules → break.
- **AP-006 XPath performance** — non-indexed attribute in ordered retrieve.
- **AP-007 N+1 query** in loops → batch fetch.
- **AP-008 Unbounded iteration** without limit → add cap.

### Naming
- **NM-001** Entities `PascalCase`, singular (`Employee`).
- **NM-002** Microflows verb-first (`Approve_Offer_Sub`), suffix indicates type: `_Sub`, `_Nano`, `_ACT`.
- **NM-003** Booleans start with `Is/Has/Can`.
- **NM-004** No abbreviations except approved dictionary.

### Role & access completeness
- **RA-001** Every entity has ≥1 role with explicit access rules.
- **RA-002** Every microflow has "allowed roles" (never `*`).
- **RA-003** PII/PHI attributes have per-role read/write matrix; PII masked in list views.
- **RA-004** Admin-only actions require MFA context.

### Provenance header (mandatory on AI-generated files)
```ts
/**
 * AI-GENERATED
 * Skill:       <skill name> v<version>
 * Model:       <model>/<tier>
 * Prompt ID:   <uuid>          (see .ai-dlc/prompt-audit.jsonl)
 * Generated:   <ISO timestamp>
 * plan.md ref: T-<task-id>
 *
 * Human review required (G2). Strip only when materially rewritten by human.
 */
```
Missing header on AI-changed file → blocker (G2 *"Are generated files vs manually modified files identifiable?"*).

### Secrets / credential leak
- **SEC-001** Regex on high-entropy + known formats (AWS AKIA, GCP `AIza`, JWTs, PEM keys).
- **SEC-002** Config keys `*secret*`, `*password*`, `*token*`, `*apiKey*` with non-empty literal → blocker.
- **SEC-003** `.env*` in git history → escalate to Infosec.
- **SEC-004** Log statements printing whole request/response → require redaction.

### API security validator
- **API-001** Every endpoint has auth middleware; anonymous on allow-list.
- **API-002** Request body validated against schema (Zod/JSON-Schema).
- **API-003** Security headers present (CSP, HSTS, X-Content-Type-Options).
- **API-004** CORS not `*` in prod.
- **API-005** Bulk endpoints paginate.

### Session & RBAC
- **RBAC-001** Server-side permission check on every mutation.
- **RBAC-002** Session cookie: `HttpOnly; Secure; SameSite`.
- **RBAC-003** Idle timeout ≤ 30 min; absolute ≤ 8 h.
- **RBAC-004** Impersonation audited.

## Workflow

### Step 0 — Open audit context (mandatory, chains #15 prompt-audit-trail)
- Emit an entry to `.ai-dlc/prompt-audit.jsonl` capturing:
  prompt_id (uuid), model/tier, context_ref, target path, ruleset version, timestamp.
- This prompt_id is the SAME id written into every provenance header (below).
- If prompt-audit-trail cannot be reached → HARD STOP (G2 blocker:
  "Is tool/model/prompt/context reference captured?").

### Step 1 — Load ruleset (version-pinned)
`standards/rules/<stack>-v1.yaml`. Ruleset changes go through PR review.

### Step 2 — Run analyzers
Language-native: eslint plugins, spotbugs, pmd, semgrep custom rules. Mendix: Sigrid + custom rules. Custom regex/AST for provenance & secrets.

### Step 3 — Classify findings
Per rule: `blocker` / `major` / `minor`.

### Step 4 — Fixes
- **Safe auto-apply (non-semantic, non-security) ONLY:**
  - Insert missing provenance header.
- **Propose-only (require human diff review) — never auto-apply:**
  - Security fixes (cookie flags HttpOnly/Secure/SameSite, CORS, headers, auth).
  - Off-standard naming (semantic risk).
- Rationale: honours Guardrail #3 "Never auto-fix a security issue without human diff review."

### Step 5 — Report
`.standards/reports/<pr-or-date>.md`:
```markdown
Blockers: 2 | Major: 5 | Minor: 11
Compliance score: 78% (< 80 → Architect sign-off required)
## Blockers
- [SEC-002] `src/config/prod.ts:18` – literal 'AKIA…' – load from Secrets Manager
- [RA-001] entity `AuditEvent` – no security rules
## Auto-fixes applied
- 12 provenance headers inserted
- 3 cookies hardened
```

### Step 6 — Emit PR comments and CI gate

## Guardrails
1. **Rules are code.** Every rule has ID, description, tests, owner.
2. **Deprecate, don't delete.** Removing needs COE sign-off.
3. **Never auto-fix a security issue** without human diff review.
4. **Redact findings themselves** — report shows *"secret detected"*, not the value.

## Outputs
- `.standards/reports/*.md` + auto-fix commits + provenance headers inserted + CI gate status.

## Stage-gate mapping
- **G2 – AI Generation & Developer Self-Review (automated):**
  - "Is tool/model/prompt/context reference captured?" → Step 0 audit entry
  - "Are generated vs manually modified files identifiable?" → provenance headers
  - Automated compliance score + CI gate run here.
- **G3 – Human Review & Code Provenance (human):**
  - Compliance score < 80% OR any security blocker → **Architect sign-off required (G3)**.
  - Reviewer closes findings; architect validates security model (roles, access, audit).
  - The skill NEVER self-certifies sign-off — it only produces evidence for G3.

## References
- SEI CERT – *Secure Coding Standards*
- OWASP – *Secure Coding Practices*
- Google – *Style Guides*
- Mendix – *Best practices, Sigrid*
