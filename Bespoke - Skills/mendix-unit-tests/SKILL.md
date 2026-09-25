---
name: mendix-unit-tests
description: "Generate unit tests for Mendix microflows and nanoflows using the Unit Testing module in Studio Pro. Trigger when the user says 'unit tests for microflow', 'test this microflow', 'nanoflow test', or a Mendix build is delivered. Applicable ONLY to Mendix."
stage_gate: "G3"
priority: Medium
owner: Vishali / Mendix Lead
version: 1.0
grounded_in:
  - "Mendix Marketplace – Unit Testing module documentation"
  - "Mendix – Testing best practices"
  - "AWS Well-Architected – Test small, test often"
---

# Mendix Unit Test Generation

## Purpose
Generate microflow/nanoflow unit tests via the **Mendix Unit Testing module**, ensuring every business rule and decision path is covered before code goes to G3 QA validation.

## When to invoke
- Attached artefact is a `.mpr` or a specific microflow export (JSON).
- User says *"unit tests for microflow"*, *"test my nanoflow"*, *"Mendix test coverage"*.
- Archetype in `plan.md` is `Mendix`.

Do NOT invoke for bespoke stacks.

## Inputs (required)
| Input | Details |
|---|---|
| Microflow / nanoflow name | Fully-qualified: `MyModule.DoSomething_Sub` |
| Input contract | Parameters + types |
| Expected output contract | Return type / entities affected |
| Business rules | Decision matrix or referenced BRD section |
| Test data strategy | `factory` (recommended) \| `snapshot` |
| Coverage target | Default: 80 % path coverage |

## Workflow

### Step 1 — Ensure Unit Testing module is installed
Check `App/modules/UnitTesting` exists. If missing, emit install instructions (Marketplace).

### Step 2 — Analyse the microflow
Identify: decision nodes (each requires ≥ 1 test per branch); loop/iterator nodes (0, 1, N iterations); sub-microflow calls (mock via `MockUp` pattern); database access (in-memory objects, rollback); external API calls (must be mocked).

### Step 3 — Generate tests
Naming: `Test_<MicroflowName>_<PathDescription>_<ExpectedOutcome>`
Example: `Test_ApproveOffer_BandCeilingExceeded_ReturnsError`.

Structure: Arrange (factory sub-microflow) → Act (call microflow) → Assert (`AssertTrue`, `AssertEqual`, `AssertNotEmpty`) → Cleanup (rollback).

### Step 4 — Cover critical rule types
| Rule type | Minimum tests |
|---|---|
| Decision (if/else) | 1 per branch + 1 boundary |
| Loop | empty, single, many |
| Sub-call | happy + failure of sub |
| Aggregation | empty + non-empty |
| Date/time | past, today, future, timezone edge |
| Numeric threshold (e.g. band ceiling 20%) | just-below, equal, just-above |

### Step 5 — Emit configuration
Add tests to `Testing` module; register in `UnitTestingSuite` for CI; configure Mendix Buildpack to run suite on every commit.

### Step 6 — Coverage & report
`docs/mendix-test-coverage.md`:
| Microflow | Paths | Tested | Coverage % | Owner |
|---|---|---|---|---|
| ApproveOffer | 6 | 6 | 100% | AI + TL |

Any microflow < 80% → block PR merge (G3).

## Guardrails
1. **No external calls** in unit tests — mock via sub-microflows.
2. **Deterministic data** — no `now()`; inject via parameter.
3. **Isolated** — every test rolls back its own objects.
4. **Naming discipline** — critical for TL review.
5. **Never test framework code** — test *your* rules.
6. **Prompt audit:** call `prompt-audit-trail`.

## Outputs
- Test microflows in `Testing` module + coverage report + CI config + provenance in each test's documentation field.

## Stage-gate mapping
- **G3 – QA Validation:** *"Test coverage ≥ threshold"*, *"Business scenario testing complete"*, *"Regression test suite green"*.

## References
- Mendix Marketplace – *Unit Testing module*
- Mendix Docs – *Testing microflows*
- AWS Well-Architected – *Operational Excellence: pre-deployment tests*
