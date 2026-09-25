---
name: figma-to-page
description: "Generate production-ready UI pages (Mendix pages, React components, or HTML) from a Figma design context via the Figma MCP connector. Trigger when a Figma URL or exported Figma HTML is attached and the user asks to 'generate the page', 'build this screen', 'implement this Figma', or a plan.md task references a Figma frame. Achieves ~70–90% first-pass accuracy per DRL POC."
stage_gate: "G1 → G2"
priority: High
owner: Vishali / UI Lead
version: 1.0
grounded_in:
  - "Figma – Dev Mode & MCP server documentation"
  - "AWS Amplify UI Studio – Figma-to-code pattern"
  - "Google Material Design – Design tokens"
  - "W3C – Web Content Accessibility Guidelines 2.2"
---

# Figma-to-Page Generation

## Purpose
Convert a Figma frame into a **DRL-compliant, accessible, responsive** page (Mendix, React/TSX, or HTML) in a single AI generation pass, ready for human refinement.

## When to invoke
- User attaches a Figma URL: `https://www.figma.com/design/<file-id>/…?node-id=<frame>`
- User attaches a Figma-exported HTML/CSS zip.
- A `plan.md` task references `Figma:<frame-id>`.
- User says: *"build this screen"*, *"generate page from Figma"*, *"implement design"*.

Do NOT invoke when: no Figma reference is provided; design-system compliance alone is required (use `design-system-compliance`).

## Inputs (required)
| Input | Details |
|---|---|
| Figma frame ref | URL with `node-id` **or** exported HTML |
| Target stack | `mendix` \| `react-ts` \| `html-tailwind` |
| Target framework version | e.g. Mendix Studio Pro 11.6, React 18, Tailwind 3 |
| Data binding contract | Entity name(s) + attribute list from `plan.md` §2 |
| Design system reference | Path to DRL design tokens |
| Accessibility target | WCAG level (default: AA) |

**HARD STOP** if Figma frame or exported HTML is unavailable.

## Workflow

### Step 1 — Retrieve design context via MCP
Use the **Figma MCP connector** (from `enterprise-mcp` skill) to fetch:
- Frame node tree (JSON)
- Component metadata (auto-layout, constraints, variants)
- Design tokens (colors, typography, spacing) — resolve to DRL tokens where matched
- Asset URLs (images, icons)

Never paste raw pixel screenshots — always use the structured node tree; it prevents ~40% of layout drift.

### Step 2 — Map Figma to target stack
| Figma concept | Mendix | React/TSX | HTML/Tailwind |
|---|---|---|---|
| Frame + Auto Layout (vertical) | `<container>` vertical flex | `<div className="flex flex-col">` | `<div class="flex flex-col">` |
| Text style H1 | Page title widget, H1 | `<h1 className="text-3xl font-bold">` | `<h1>` with token class |
| Button (Primary variant) | Button widget, `btn-primary` | `<Button variant="primary">` | `<button class="btn btn-primary">` |
| Data grid frame | Data grid 2 widget | `<Table>` (react-table) | semantic `<table>` |

### Step 3 — Generate the page
Emit:
1. Component/page file with clean structure, semantic HTML, ARIA roles.
2. Data binding stubs — TODO comments for entity wiring.
3. Storybook / preview file (React only).
4. **Provenance header** (see `code-standards`).

### Step 4 — Self-validate
- All Figma text nodes rendered; colors → DRL tokens; interactive elements have `aria-label`/`role`; images have `alt` and `loading="lazy"`; responsive breakpoints at ≥768px/≥1024px; forms have `<label htmlFor>`.

### Step 5 — Emit diff summary
- Files created/modified.
- Estimated accuracy (Figma coverage %).
- Known gaps.

## Guardrails
1. **No pixel-perfect promises.** Target 70–90% first-pass; humans finalise.
2. **DRL design system first.** Flag unresolvable tokens rather than hard-coding.
3. **WCAG 2.2 AA.** Contrast ≥ 4.5:1 text, keyboard-navigable, focus-visible.
4. **Per-user Figma OAuth** for MCP — never shared service account.
5. **Human review is mandatory.**
6. **Prompt audit:** call `prompt-audit-trail`.

## Outputs
| Stack | File(s) |
|---|---|
| Mendix | `.mpr` fragment / Studio-Pro-importable XML |
| React | `src/pages/<Name>.tsx` + `<Name>.stories.tsx` + `<Name>.module.css` |
| HTML | `<name>.html` + `<name>.css` |

Plus: `docs/figma-generation-log.md` appended with node-id, frame, timestamp, accuracy score.

## Stage-gate mapping
- **G1:** *"Is Figma/wireframe available where UI generation is expected?"*
- **G2:** *"Were approved reusable skills/agents used — UI, API, Test, Security..."*
- **G3:** feeds `playwright-e2e`.

## References
- Figma – *Dev Mode: extracting design tokens*
- AWS Amplify UI – *Figma-to-code with Amplify Studio*
- Google Material Design 3 – *Design tokens*
- W3C – *WCAG 2.2 AA success criteria*
