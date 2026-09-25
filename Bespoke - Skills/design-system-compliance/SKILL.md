---
name: design-system-compliance
description: "Enforce DRL Design System compliance on AI-generated UI code — colors resolve to tokens, typography uses the DRL scale, components come from the DRL component library, and WCAG 2.2 AA is respected. Trigger after any UI is generated, or when the user asks 'is this DRL-compliant?', 'apply DRL branding', or 'audit my UI'."
stage_gate: "G2"
priority: High
owner: Vishali / UI Lead
version: 1.0
grounded_in:
  - "Google Material Design 3 – Design tokens & theming"
  - "Adobe Spectrum – Design system governance"
  - "W3C WCAG 2.2"
  - "AWS Amplify UI – Theming best practices"
status: Draft            # Draft → Piloted → Reusable
validated_on: []         # e.g. ["cognito-plus PR#412", "myday-api PR#88"]
success_criteria:
  - "≥95% of seeded anti-patterns detected on the validation fixture set"
  - "0 false-blocker on the approved golden repo"
  - "100% AI-changed files carry a valid provenance header"
reviewers: []            # min 2 names before promotion to Reusable
---

# DRL Design System Compliance

## Purpose
Automated design linter that ensures every AI-generated UI matches DRL's brand system: colors, typography, spacing, icons, motion, accessibility. Emits a compliance report with actionable, file+line diagnostics.

## When to invoke
- A UI file is generated or modified.
- User says: *"is this DRL compliant?"*, *"apply DRL branding"*, *"audit UI"*, *"fix the colors"*.
- CI runs the `ui-compliance` job. Chain from `figma-to-page` / `pattern-based-pages` automatically.

## Inputs (required)
| Input | Details |
|---|---|
| Target file(s) or folder | Glob pattern (e.g. `src/pages/**/*.tsx`) |
| DRL design tokens spec | `design-tokens/drl.tokens.json` (W3C token format) |
| DRL component library | `@drl/ui` npm package OR Mendix module `DRL_UI_Library` |
| WCAG target level | Default: AA |
| Scope | `full` \| `colors-only` \| `typography-only` \| `a11y-only` |

## Workflow

### Step 0 — Open audit context (mandatory, chains #15 prompt-audit-trail)
- Emit to `.ai-dlc/prompt-audit.jsonl`: prompt_id (uuid), model/tier,
  context_ref, target glob, token spec version, timestamp.
- Insert provenance header on every AI-changed UI file; its Prompt ID
  MUST equal the prompt_id above.
- If prompt-audit-trail is unreachable → HARD STOP (G2 blocker).

### Step 1 — Load DRL token map
Read `design-tokens/drl.tokens.json`. Extract color roles (`brand.primary`, `semantic.success/warn/error`, `surface.*`, `text.*`), typography scale (display/heading/body/caption), spacing scale (4/8/12/16/24/32/48/64), radius scale, motion tokens.

### Step 2 — Scan targets for violations
| Check | Detection rule | Severity |
|---|---|---|
| Hard-coded color | `#[0-9a-f]{3,6}`, `rgb(`, `hsl(` outside tokens.css | **Blocker** |
| Off-scale spacing | Margin/padding not in 4/8/12/16/24/32/48/64 | Major |
| Off-scale font-size | Not in tokens | Major |
| Non-DRL button | `<button>` without DRL class / `<Button>` component | Major |
| Missing focus ring | `:focus-visible` outline absent on interactive | **Blocker (a11y)** |
| Contrast fail | Foreground/background < 4.5:1 (or 3:1 for large text) | **Blocker (a11y)** |
| Missing `alt` / `aria-label` | Interactive element without accessible name | **Blocker (a11y)** |
| Non-token radius | `border-radius` not on scale | Minor |


### Step 3 — Auto-fix where safe
**Auto-fixable** (commit as `chore(ui): apply DRL tokens`): hex → nearest matching token; spacing → nearest scale value (only if diff ≤ 2px); add `focus-visible` outline.
**NOT auto-fixable** (diagnostic only): contrast failure, missing accessible name, non-DRL component substitution.

### Step 4 — Emit compliance report
`docs/ui-compliance/<yyyy-mm-dd>-<page>.md` with table of blockers by file/line/rule/fix; compliance score (0-100, blockers −20 each, major −5, minor −1; floor 0); sign-off checkboxes for UI Lead / Architect (required if score < 80).

### Step 5 — Fail CI if blockers > 0
Exit code 1 → PR cannot merge until resolved. Compliance score < 80 → require Architect sign-off (G2 checklist).

## Guardrails
1. **Never silently rewrite semantics.** Only swap classes/values.
2. **Never guess a token match.** If a color has no matching token, flag it.
3. **Do not disable a11y rules to pass.**
4. **Log every auto-fix** with before/after.

## Outputs
- `docs/ui-compliance/<date>-<page>.md`
- Auto-fix diffs (`chore(ui): drl tokens`)
- CI status (pass/fail on blocker count)

## Stage-gate mapping
- **G2 – AI Generation Review:** *"Code quality score ≥ 80%"*
- **G2 – Human Code Review:** *"Best practice compliance verified"*

## References
- Google Material Design 3 – *Design tokens: theming architecture*
- W3C – *WCAG 2.2 AA success criteria 1.4.3 (contrast), 2.4.7 (focus visible)*
- Adobe Spectrum – *Design system governance model*
