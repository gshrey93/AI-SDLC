---
name: prompt-audit-trail
description: "Capture, store, and query every AI-DLC prompt invocation with metadata (skill, model, tokens, cost, actor, prompt ID, context sources, PII scan result, output hash). This is the base substrate for governance, cost tracking, incident response, and regulator-facing evidence. Every other skill CALLS THIS. Trigger explicitly when the user says 'show prompt audit', 'export prompt log', 'who ran what prompt', or as a mandatory sub-call from every generation skill."
stage_gate: "G1, G2, G4"
priority: High (Governance)
owner: Vishali / DevSecOps
version: 1.0
grounded_in:
  - "NIST AI RMF – Govern, Map, Measure, Manage functions"
  - "EU AI Act – logging & record-keeping requirements (Art. 12)"
  - "AWS Well-Architected – Detective controls, audit trails"
  - "Google Cloud – Cloud Audit Logs, Data access logs"
  - "Anthropic / OpenAI / Google – responsible AI logging patterns"
---

# Prompt Audit Trail Generator

## Purpose
Provide the **immutable, queryable record** of every AI action in the DLC — mandatory to satisfy:
- G1 *"has the prompt been checked for secrets/PII?"*
- G2 *"Are generated artefacts/files logged?"*, *"Is tool/model/prompt/context reference captured?"*
- G4 *"Is prompt audit completed where sensitive or regulated data may be involved?"*
- Regulator requests ("show every AI action on this GxP system in Q2").

This skill is **called by every other skill** in this library.

## When to invoke
- **Programmatically** — start and end of every skill invocation.
- **Interactively** — user says *"show prompt audit"*, *"who ran what prompt"*, *"export audit log"*, *"prompt evidence pack"*.

## Record schema (JSONL — one line per invocation)
```json
{
  "eventId": "uuid-v7",
  "startedAt": "2026-07-03T05:32:11.412Z",
  "endedAt":   "2026-07-03T05:32:19.884Z",
  "actor": {
    "userId": "vishali.barka@drl",
    "role": "Lead Product Manager",
    "sessionId": "vs-code:abc123"
  },
  "skill": { "name": "figma-to-page", "version": "1.0" },
  "model": { "vendor": "anthropic", "name": "claude-opus-4.6", "tier": "high" },
  "tokens": { "input": 12034, "output": 3421, "cachedInput": 8100 },
  "cost": { "amount": 0.19, "currency": "USD" },
  "context": {
    "mcpConnectors": ["mcp-figma", "mcp-plan-md"],
    "files": ["docs/plan.md#T-014", "figma://frame/xxx"],
    "hashInputContext": "sha256:...",
    "piiScan": { "status": "clean", "detectors": ["email","phone","aadhaar","phi-regex"] }
  },
  "output": {
    "artefacts": ["src/pages/RetentionCases.tsx"],
    "hashOutput": "sha256:...",
    "sizeBytes": 18234
  },
  "gate": { "level": "G2", "checklistItems": ["ai-gen-logged","tool-model-captured","mapped-to-plan"] },
  "repo": { "owner": "drl", "name": "talentguard", "branch": "feature/T-014", "commit": "abc1234" },
  "compliance": {
    "gxpRelevant": true,
    "personalData": false,
    "vendorNoTraining": true
  },
  "review": {
    "requiredReviewer": "TL",
    "reviewedBy": null,
    "reviewedAt": null,
    "approved": null
  }
}
```

## Workflow

### Step 1 — Pre-flight scan (BEFORE the LLM call)
Every skill MUST call `prompt-audit.beginInvocation()` which:
1. Computes `hashInputContext`.
2. Runs PII/PHI/secret scan (Presidio + custom DRL regex packs).
3. If a critical detector fires → HALT: reject invocation, return error, do not send prompt to model.
4. Emits `INVOCATION_STARTED` event.

### Step 2 — Model call
Skill performs LLM call. Wrapper captures token counts & cost from provider response.

### Step 3 — Post-call registration
`prompt-audit.endInvocation({ artefacts, ... })` writes the record and:
- Appends JSONL row locally.
- Ships row to central audit sink (SIEM / secure S3 with Object Lock / Azure Blob immutable).
- Signs record chain via HMAC — each row references previous row's hash.
- Updates per-repo `.ai-dlc/prompt-audit.jsonl` for developer visibility (safe fields only).

### Step 4 — Enrichment
Optional: attach summarized system prompt hash (not raw prompt) and diff summary of generated artefacts.

### Step 5 — Query interface
`ai-dlc audit query` CLI supports: `--user`, `--repo`, `--between`, `--skill`, `--gxp`, `--pii-hits`, `--export evidence.zip`.

### Step 6 — Dashboards
Grafana / Power BI:
- Invocations per day/skill/user.
- $ spent per project (feature-build vs runtime).
- Token savings from cached input.
- PII/secret detection rate (should trend to zero).
- G2 reviewer SLA.

## Guardrails (non-negotiable)
1. **Immutable storage.** No update/delete on audit records.
2. **Never store raw prompts** containing sensitive data. Hash only; redact if retained.
3. **Signed chain.** Each record includes previous hash for tamper detection.
4. **Retention** per app classification (GxP 6y, SOX 7y, default 3y).
5. **Read-only access** for developers; break-glass for Infosec.
6. **Kill switch** — Infosec can globally block a skill/model in the registry.
7. **Cost cap.** Per-user daily and per-repo monthly caps.
8. **No PII in indexed fields** — dashboards must not become the leak.

## Outputs
- Central audit sink (SIEM / S3 Object Lock) + local `.ai-dlc/prompt-audit.jsonl` + evidence pack ZIP per query + dashboards.

## Stage-gate mapping
- **G1:** *"Has the prompt/context been checked to ensure no secrets…"* — pre-flight scan is the enforcement.
- **G2:** *"Are generated artefacts/files logged?"*, *"Is tool/model/prompt/context reference captured?"*
- **G4:** *"Is prompt audit completed…"*, *"Are vendor/tool terms checked for no-training, retention?"*

## References
- NIST – *AI RMF 1.0 (Govern & Measure functions)*
- EU AI Act – *Article 12 (record-keeping)*
- AWS Well-Architected – *Security Pillar: detective controls*
- Google Cloud – *Cloud Audit Logs, Data Access logs*
- Microsoft – *Responsible AI Standard*
