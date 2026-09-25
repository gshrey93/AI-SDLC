---
name: enterprise-mcp
description: "Configure and use enterprise Model Context Protocol (MCP) connectors that expose DRL context (BRDs, Figma, plan.md, domain models, JIRA, Confluence, ServiceNow, ADO, Dataverse) to AI coding agents. Trigger when the user says 'connect Copilot to Figma', 'add MCP for JIRA', 'expose BRDs to Claude Code', 'set up MCP server', or when a skill needs a specific context source."
metadata:
  stage_gate: "G1"
  priority: "High"
  owner: "Vishali / Platform"
  version: "1.0"
  grounded_in:
    - "Anthropic MCP specification"
    - "Microsoft Copilot Studio – custom connectors"
    - "AWS Well-Architected – Security Pillar (least privilege)"
    - "OWASP – supply chain security"
---

# Enterprise MCP Connectors

## Purpose
Give AI coding agents **structured, authenticated, least-privilege access** to DRL context sources — replacing copy/paste and screenshots with secure API-backed retrieval.

## Supported connectors (DRL catalog)
| Connector | Purpose | Auth |
|---|---|---|
| `mcp-figma` | Fetch frames, tokens, assets by node-id | Figma OAuth (per-user) |
| `mcp-confluence` | BRDs, TDDs, ARB minutes | Confluence PAT (per-user) |
| `mcp-jira` | Stories, ACs; write comments (opt-in) | Jira PAT |
| `mcp-ado` | Azure DevOps work items & repos | ADO PAT / OAuth |
| `mcp-sharepoint` | Approved documents & templates | Microsoft Graph delegated |
| `mcp-servicenow` | Change requests, CMDB | SN OAuth |
| `mcp-dataverse` | Copilot Studio agent data (TalentGuard, etc.) | Dataverse OAuth |
| `mcp-plan-md` | Read/write `plan.md` in active repo | Git PAT |
| `mcp-domain` | Query shared domain model / ERD | Read-only DB user |

## When to invoke
- User says *"connect Copilot to X"*, *"add MCP server for X"*, *"expose Y to Claude Code"*.
- A downstream skill requires an unconfigured connector.
- New joiner setup on a repo.

## Inputs
| Input | Details |
|---|---|
| Connector key | From catalog |
| Client / IDE | `github-copilot`, `claude-code`, `cursor`, `copilot-studio` |
| Scope | Read-only vs read/write, per-project |
| Data classification | Redact PII/PHI? Log requests? |

## Workflow

### Step 1 — Verify approval
Each connector requires **Infosec + Data Protection sign-off**. HALT if requested connector not in approved catalog. Do not "just try" arbitrary MCP servers from internet — supply-chain risk.

### Step 2 — Provision credentials
- Prefer **OAuth with PKCE** (per-user).
- If PAT required, store in OS keychain / VS Code SecretStorage.
- Emit `.mcp/config.example.json` (no secrets) and `.mcp/config.local.json` in `.gitignore`.

### Step 3 — Emit MCP client config
For VS Code (`.vscode/mcp.json`):
```json
{
  "servers": {
    "figma": {
      "command": "npx",
      "args": ["-y", "@drl-mcp/figma"],
      "env": { "FIGMA_TOKEN": "${keychain:FIGMA_TOKEN}" }
    },
    "confluence": {
      "command": "npx",
      "args": ["-y", "@drl-mcp/confluence"],
      "env": { "CONFLUENCE_BASE": "https://drl.atlassian.net", "CONFLUENCE_PAT": "${keychain:CONF_PAT}" }
    }
  }
}
```

For Claude Code: same block in `.claude/settings.local.json`.
For Copilot Studio: import connector as a **custom tool** on each agent.

### Step 4 — Least-privilege scope
- **Read-only by default.**
- Redact PII in responses — connector-side filter.
- Rate-limit per user (default 60 req/min).

### Step 5 — Observability
Every MCP connector emits: `mcp.request.count{connector, tool, status}`, `mcp.request.latency_ms`, structured log with `userId, tool, argsHash`.

### Step 6 — Testing
- Auth handshake succeeds.
- One read call returns expected shape.
- One denied call returns 403 (not 500).
- PII redaction removes SSNs/PHI patterns.

## Guardrails
1. **Only whitelisted connectors.**
2. **Per-user credentials.** No shared service accounts.
3. **No PII in model context.**
4. **Kill switch.** Infosec can revoke centrally.
5. **Audit every write** with interactive confirmation.

## Outputs
- `.vscode/mcp.json` / `.claude/settings.local.json` / Copilot Studio tool import + `.mcp/README.md` + secret entries in keychain + SIEM logs.

## Stage-gate mapping
- **G1:** *"Does the context pack include BRD/PRD, domain model, security model, APIs…"*
- **G4:** *"Are vendor/tool terms checked for no-training, retention…"*

## References
- Anthropic – *Model Context Protocol specification*
- Microsoft Copilot Studio – *Custom connectors, security guidance*
- AWS Well-Architected – *Security Pillar: least privilege, IAM patterns*
- OWASP – *Top 10 CI/CD security risks*
