---
name: pattern-based-pages
description: "Generate common page patterns (CRUD list+detail, overview dashboard, master-detail, wizard, data grid, search+filter, approval queue) from a domain entity definition. Trigger when the user says 'create CRUD for X', 'generate overview page for Y', 'wizard for Z', 'approval workflow page', or a plan.md task references pattern:crud|overview|master-detail|wizard|grid|approval."
stage_gate: "G1 → G2"
priority: Medium
owner: Vishali / UI Lead
version: 1.0
grounded_in:
  - "AWS Amplify UI – DataStore + collection components"
  - "Mendix – Page templates and patterns"
  - "Google Material Design – Layout patterns"
  - "Refactoring UI – common list/detail patterns"
---

# Pattern-Based Page Generation

## Purpose
Rapidly scaffold standard UI patterns from an entity contract, so developers do not re-invent CRUD lists / overview screens / wizards each time. Every generated pattern is DRL-compliant (composes with `design-system-compliance`) and audit-friendly.

## Supported patterns
| Pattern key | What it produces |
|---|---|
| `crud` | Data grid + create/edit modal + detail view + delete confirm |
| `overview` | KPI cards + trend chart + drill-down list |
| `master-detail` | Left list, right detail pane |
| `wizard` | Multi-step form with validation and progress indicator |
| `grid` | Data grid only (server-side pagination, sort, filter) |
| `approval-queue` | Task list with bulk approve/reject + case detail drawer |
| `search-filter` | Search bar + faceted filters + result list |

## When to invoke
- User says any of the trigger phrases.
- `plan.md` task has `pattern:<key>` metadata.
- After `brd-to-plan` has classified a task as a standard pattern.

## Inputs (required)
| Input | Details |
|---|---|
| Pattern key | From table above |
| Entity contract | Name + attributes (name, type, required, PII flag) |
| Target stack | `mendix` \| `react-ts` \| `html-tailwind` |
| Actions in scope | `create / read / update / delete / approve / reject / export` |
| Role model | Which roles see/edit which fields |
| Volume expectation | Rows per page, expected total (drives virtualisation) |

## Workflow

### Step 1 — Resolve pattern template
Load `templates/<pattern-key>/<stack>.hbs`.

### Step 2 — Substitute entity fields
- PII-flagged fields get **masked-by-default** cells (`E****`) with role-gated reveal.
- Currency fields use `Intl.NumberFormat`.
- Dates use `Intl.DateTimeFormat` with DRL locale token.

### Step 3 — Wire role-based visibility
- Mendix: security rules on entity + widget visibility.
- React: `<Can I="update" a="Employee">` (`@casl/react`) or feature-flag hook.

### Step 4 — Generate companion files
| Pattern | Companion files |
|---|---|
| `crud` | schema `.ts`, form validation (`zod`), server hooks stub, empty-state |
| `overview` | KPI query stubs, chart config, refresh hook |
| `wizard` | step config, per-step validation, resume-from-draft hook |
| `approval-queue` | server actions (approve, reject, request-changes), audit-log write |

### Step 5 — Emit sample tests (seed for `playwright-e2e`)
- Happy path (create → list → open → edit → save).
- RBAC negative test.

### Step 6 — Self-validate
- All entity attributes rendered or explicitly hidden.
- PII fields masked; every action mapped to a role; empty/loading/error states present; pagination if volume > 500; provenance header on every file.

## Guardrails
1. **PII must be masked by default.** Reveal requires role + audit-log write.
2. **Never generate a "delete" without a confirm dialog.**
3. **Never render an entity-wide `SELECT *`.**
4. **Human review is mandatory.**
5. **Prompt audit:** call `prompt-audit-trail`.

## Outputs
```
src/pages/<entity>/
  ├── <Entity>List.tsx
  ├── <Entity>Detail.tsx
  ├── <Entity>Form.tsx
  ├── <Entity>.schema.ts
  ├── <Entity>.hooks.ts
  └── __tests__/<Entity>.e2e.seed.ts
```

## Stage-gate mapping
- **G1:** *"Are approved reusable skills used…"*
- **G2:** *"Is peer review completed…"*, *"Is security model reviewed — roles, access rules…"*

## References
- AWS Amplify UI – *Collection components*
- Mendix – *Page templates library*
- Refactoring UI – *List/detail patterns*
