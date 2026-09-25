---
name: code-review-report
description: "Run an AI-assisted code review on a PR or set of files and emit a scoring-based review report covering quality, maintainability, security, performance, testability, and DRL coding-standards compliance. Trigger when user says 'review this PR', 'code review report', 'assess code quality', 'give me a review score', or as part of G2 gate."
metadata:
  stage_gate: "G2"
  priority: "High"
  owner: "Vishali / Viswa / COE"
  version: "1.1"
  grounded_in:
    - "Google Engineering Practices – Code review guide"
    - "SonarQube / Sigrid – code quality metrics"
    - "AWS Well-Architected – Operational Excellence"
    - "IEEE 1028 – Software reviews & audits"
---

# Code Review & Assessment Report

## Purpose
Pre-screen every PR with an AI reviewer so human reviewers spend time on **judgement calls**, not catching obvious defects. Produces numeric quality score (0–100) + prioritized comment list, and gates PR at G2 based on threshold.

## When to invoke
- User says *"review this PR"*, *"code review report"*, *"assess code"*, *"quality score"*.
- New PR opened. Before requesting human architect review.

## Inputs (required)
| Input | Details |
|---|---|
| PR reference | `owner/repo#PR` or diff patch |
| Base branch | For accurate diff |
| Stack | Autodetected |
| DRL coding standards | `.standards/coding-standards.md` (if missing → skip Standards dim, mark report **partial**) |
| Previous review comments | For consistency |
| plan.md | `docs/plan.md` — if missing, **HALT** and run `brd-to-plan` skill first |

## Scoring model (0–100)
| Dimension | Weight | What it measures |
|---|---|---|
| Correctness | 25 | Bugs, off-by-one, null handling, races |
| Security | 15 | PR-scope only |
| Maintainability | 15 | Complexity, size, duplication, naming |
| Readability | 10 | Comments, structure, names |
| Testability | 10 | Tests exist? Coverage delta? |
| Standards | 10 | Lint, formatter, DRL conventions, provenance |
| Performance | 10 | N+1 queries, unbounded loops, indexes |
| Documentation | 5 | JSDoc / KDoc / docstrings on public API |

Score < 80 → **PR cannot merge without Architect sign-off** (per G2).

### Scoring rubric — per-finding deductions

| Severity | Deduction per finding | Cap |
|---|---|---|
| Blocker | −(dim weight × 0.40) each | Floor at 0 for that dimension |
| Major | −(dim weight × 0.15) each | — |
| Minor | −(dim weight × 0.05) each | — |
| Nit | 0 | — |

**Special rules:**
- Score cannot exceed **95** if any blocker is present (regardless of other dimensions).
- If score ∈ [78, 80) with **zero blockers** → round up to 80; annotate *"borderline — TL discretion required"*.
- Exactly 80 = **PASS**.
- Rounding: floor to nearest integer before applying special rules.

## Workflow

### Step 1 — Build context
Fetch diff.  
Load `docs/plan.md`; check each changed file maps to a task in §4.
- If `docs/plan.md` is **missing** → **HALT**: instruct user to run `brd-to-plan` skill first before this review can proceed.

Load `.standards/coding-standards.md`.
- If **missing** → skip the Standards dimension (cap its score at 0); mark report as **partial review — standards not verified**.

### Step 2 — Run linters / formatters (deterministic)

| Stack | Required tools | Optional |
|---|---|---|
| Node / TypeScript | `eslint`, `stylelint`, `prettier` | `oxlint` |
| Kotlin / Java | `ktlint`, `spotless` | `checkstyle` |
| Python | `ruff`, `black` | `mypy` |
| .NET / C# | `dotnet-format`, `StyleCop.Analyzers` | `Roslynator` |
| Go | `gofmt`, `golangci-lint` | `staticcheck` |
| Mendix | Studio Pro consistency errors + Sigrid | — |
| Terraform / IaC | `tflint`, `checkov` | `tfsec` |

If a required tool is unavailable → mark that dimension **partial** (max score = weight × 0.5 for that dimension) and record in the report.

### Step 3 — Semantic AI review
For each hunk, produce comments only if issue is real (not stylistic) and confidence ≥ 0.75.

**Confidence definition:**
- Rule-based findings (linter, SAST output) = confidence **1.0** (always emit).
- Semantic AI findings: self-assessed as **high (0.90)**, **medium (0.75)**, or **low (0.50)**.
- If confidence < 0.75 or cannot be determined → downgrade severity to `question` regardless of original classification; never emit as `blocker` or `major`.

Comment shape:
```markdown
### [blocker | major | minor | question | nit] – <one-line summary>

**File:** src/api/user.ts:42
**Rule:** correctness / null-safety
**Why:** `userRepo.find(id)` may return null; next line dereferences → NPE.
**Suggested fix:** [code]
```

### Step 4 — G2 checklist verification
Verify per-PR:

| # | Checklist item | Evidence path / signal | Result |
|---|---|---|---|
| 1 | Generated artefacts logged (prompt history present) | `.ai-dlc/prompt-audit.jsonl` — entry with matching `prompt_id` | PASS / FAIL |
| 2 | Code quality score ≥ 80% | `.review/reports/PR-<num>.md` → `score` field | PASS / FAIL |
| 3 | AI output mapped back to plan.md | PR description contains `docs/plan.md` task ID(s) (format: `T-<n>`) | PASS / FAIL |
| 4 | AI-assisted flag in PR / change log | PR label `ai-generated` present | PASS / FAIL |
| 5 | Approved reusable skills used | Provenance header `Skill:` field references a path under `skills/` | PASS / FAIL |
| 6 | Tests / docs generated where useful | PR diff includes files under `tests/` and/or `docs/` | PASS / FAIL |
| 7 | Tool / model / prompt / context reference captured | Provenance header present in every new AI-generated file | PASS / FAIL |

Any **FAIL** → **blocker**; PR cannot proceed until resolved or a G2 exception is raised with Architect sign-off.

### Step 5 — Emit report
`.review/reports/PR-<num>.md`:
```markdown
---
pr: 245
score: 84
gate: PASS
blockers: 0
majors: 2
minors: 5
partial_dims: []
stack: node-ts
skill_version: 1.1
generated: 2026-08-10T14:32:00Z
model: claude-sonnet-4.6
---
# Code Review Report — PR #245
Score: 84 / 100  → PASS
## Score breakdown [table]
## G2 checklist [table]
## Comments (blockers, majors, minors)
## Positive callouts
```

Post as PR comment via GitHub / ADO API.

### Step 6 — Track productivity metric
Append one record to `.review/metrics.jsonl` for PMO dashboard:
```json
{
  "pr": 245,
  "repo": "owner/repo",
  "score": 84,
  "gate": "PASS",
  "blockers": 0,
  "majors": 2,
  "minors": 5,
  "partial_dims": [],
  "stack": "node-ts",
  "skill_version": "1.1",
  "model": "claude-sonnet-4.6",
  "generated": "2026-08-10T14:32:00Z",
  "reviewer": "github-copilot"
}
```

## Guardrails
1. **Never rubber-stamp AI-generated code.** Even score 100 needs human Approve.
2. **Avoid nit-storms.** Cap `nit` comments at 5 per PR.
3. **Do not fetch external code** into context.
4. **No PII in review comments.**
5. **Prompt audit:** call `prompt-audit-trail`.

## Outputs
- `.review/reports/PR-<num>.md` + PR-scoped inline comments + G2 checklist status + `.review/metrics.jsonl`.

## Stage-gate mapping
- **G2 – AI Generation Review:** *"Code quality score ≥ 80%"*, *"Has TL reviewed the AI-generated output?"*
- **G2 – Human Code Review:** *"Best practice compliance verified"*, *"AI-assisted code review / quality assessment report generated"*

## References
- Google – *Engineering practices: code review developer guide*
- IEEE 1028 – *Software reviews and audits*
- SonarSource – *Sonar Way rules*
- AWS Well-Architected – *Op-Ex: post-release reviews*
