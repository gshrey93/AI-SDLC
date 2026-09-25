---
name: playwright-e2e
description: "Generate Playwright end-to-end tests from a page/component, plan.md acceptance criteria, or user story. Produces page-object-model tests with data-testid selectors, network stubbing, accessibility checks, and CI-ready config. Trigger when the user says 'generate E2E test', 'Playwright for this page', 'add UI test', 'test the login flow', or after any UI is generated."
stage_gate: "G3"
priority: High
owner: Vishali / QA Lead
version: 1.0
grounded_in:
  - "Playwright official docs – Best practices, POM pattern"
  - "AWS Well-Architected – Reliability Pillar (Test recovery procedures)"
  - "Google Testing Blog – Software testing anti-patterns"
  - "Deque axe-core – automated a11y testing"
---

# Playwright E2E Test Generation

## Purpose
Auto-generate maintainable, deterministic E2E tests that survive UI refactors, produce actionable failure output, and gate deployment at G3.

## When to invoke
- User attaches a page/component and says *"add E2E"*, *"generate test"*, *"Playwright"*.
- A `plan.md` task has acceptance criteria requiring UI verification.
- Chained after `figma-to-page` / `pattern-based-pages`.

## Inputs (required)
| Input | Details |
|---|---|
| Target page / route | URL or component path |
| Acceptance criteria | Gherkin, BDD, or free text from `plan.md` |
| Data setup approach | `api-seed` (preferred) \| `db-seed` \| `ui-seed` |
| Auth mode | `session-storage` \| `login-per-test` \| `storageState` |
| Environments to run in | `dev`, `qa`, `preview` |
| Accessibility scan? | Default: yes (axe-core) |

## Workflow

### Step 1 — Extract selectors and stable IDs
Scan target UI for `data-testid`. If missing on any interactive element, **emit WARN diagnostic and open a companion PR** — do NOT fall back to fragile `text=`/`nth-child`.

### Step 2 — Generate Page Object Model
```
tests/e2e/
  ├── pages/            # LoginPage.ts, DashboardPage.ts
  ├── fixtures/         # auth.ts (storageState per role), seed.ts
  ├── specs/            # login.spec.ts, dashboard.spec.ts
  ├── utils/            # a11y.ts (axe helper)
  └── playwright.config.ts
```

Page Objects expose semantic methods, use `getByRole` / `getByTestId` / `getByLabel`.

### Step 3 — Write specs from acceptance criteria
```ts
import { test, expect } from '../fixtures/auth';
import { DashboardPage } from '../pages/DashboardPage';
import { checkA11y } from '../utils/a11y';

test.describe('Dashboard – approver role', () => {
  test.use({ storageState: 'auth/approver.json' });

  test('AC-1: approver can bulk-approve pending cases', async ({ page }) => {
    const dash = new DashboardPage(page);
    await dash.goto();
    await dash.selectCases(['TG-2026-4731']);
    await dash.bulkApprove('Meets policy');
    await expect(dash.toast).toHaveText(/approved/i);
  });

  test('AC-2: WCAG 2.2 AA compliant', async ({ page }) => {
    await new DashboardPage(page).goto();
    await checkA11y(page);
  });
});
```

### Step 4 — Reliability rules
Every test MUST: have no `waitForTimeout`; be independent (data seeded/torn down per test); retry on infra flake (`retries: 2` in CI, `0` local); include trace, video, screenshot on failure; be tagged `@smoke` / `@regression` / `@a11y`.

### Step 5 — Emit `playwright.config.ts`
- Projects: chromium, firefox, webkit, edge, mobile-chromium.
- `use.baseURL` from env.
- Reporter: `html` + `junit` + `blob`.
- `expect.timeout`: 5s; `test.timeout`: 60s.

### Step 6 — Emit CI job (`.github/workflows/e2e.yml`)
- Matrix over browsers, sharding for parallelism.
- Upload traces on failure; publish HTML report.
- Gate PR merge if `@smoke` fails; nightly for `@regression`.

### Step 7 — Coverage report
`docs/test-coverage.md` mapping AC → skill → spec → status.

## Guardrails
1. **No hard-coded waits.** Reject `page.waitForTimeout(...)`.
2. **No live-prod calls.** Tests run against dev/qa/preview only.
3. **No PII in seed data.** Faker with fixed seed.
4. **Do not disable failing a11y checks** to make tests green.
5. **Prompt audit:** call `prompt-audit-trail`.

## Outputs
- Page objects + specs + fixtures + `playwright.config.ts` + CI workflow + coverage doc + provenance header.

## Stage-gate mapping
- **G3 – QA Validation:**
  - *"Test coverage ≥ defined threshold"*
  - *"E2E test results passed"*
  - *"Security testing passed"* (partial — a11y + auth-check specs)
  - *"Regression test suite green"*

## References
- Playwright – *Best practices for testing*, *Page Object Model*
- Deque – *axe-core: automated a11y testing*
- Google Testing Blog – *Small/medium/large tests*
