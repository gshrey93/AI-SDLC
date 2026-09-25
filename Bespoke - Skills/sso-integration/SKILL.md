---
name: sso-integration
description: "Add Single Sign-On (Entra ID / Azure AD via OIDC or SAML 2.0) to an AI-generated app, with MFA, group-to-role mapping, session hardening, and secure logout. Trigger when user says 'add SSO', 'Entra ID login', 'OIDC', 'SAML', 'enable MFA', or when the app moves toward G4 deployment approval."
stage_gate: "G4"
priority: High
owner: Vishali / DevSecOps
version: 1.0
grounded_in:
  - "OpenID Connect Core 1.0 spec"
  - "OAuth 2.1 draft & RFC 9700 (BCP OAuth security)"
  - "SAML 2.0 spec"
  - "Microsoft Entra ID docs – App registration & OIDC"
  - "OWASP – Session management cheat sheet"
  - "AWS Well-Architected – Security Pillar (identity foundation)"
status: Draft            # Draft → Piloted → Reusable
validated_on: []         # e.g. ["cognito-plus PR#412", "myday-api PR#88"]
success_criteria:
  - "≥95% of seeded anti-patterns detected on the validation fixture set"
  - "0 false-blocker on the approved golden repo"
  - "100% AI-changed files carry a valid provenance header"
reviewers: []            # min 2 names before promotion to Reusable
---

# SSO Integration

## Purpose
Provide secure, standards-compliant SSO in a single skill invocation — no bespoke crypto, no rolled-your-own session logic, no missing MFA claim checks.

## When to invoke
- User says *"SSO"*, *"Entra ID login"*, *"Azure AD auth"*, *"OIDC"*, *"SAML"*, *"MFA"*.
- New app moving toward G4.
- Migration from local username/password.

## Inputs (required)
| Input | Details |
|---|---|
| Protocol | `OIDC` (preferred) \| `SAML 2.0` |
| IdP | Entra ID (default) / Okta / Ping |
| Target stack | `node-ts` \| `java-spring` \| `python` \| `mendix` |
| App type | `web-server-side` \| `spa` \| `mobile` \| `api` |
| Group-to-role map | Entra group object-id → app role |
| MFA required? | Default: yes |

## Workflow

### Step 0 — Open audit context (mandatory, chains #15 prompt-audit-trail)
- Emit to `.ai-dlc/prompt-audit.jsonl`: prompt_id (uuid), model/tier,
  context_ref, target stack, protocol, timestamp.
- Insert provenance header on every AI-changed auth file / IaC snippet;
  its Prompt ID MUST equal the prompt_id above.
- If prompt-audit-trail is unreachable → HARD STOP.

### Step 1 — Choose the correct OAuth flow
| App type | Recommended flow |
|---|---|
| Server-rendered web | **OIDC Auth Code with PKCE** |
| SPA + API | Auth Code + PKCE from SPA, opaque session cookie to backend |
| Mobile | Auth Code + PKCE, refresh in secure storage |
| M2M API | **Client Credentials** |
| SAML web app | SAML 2.0 SP-init, HTTP-POST binding |

**Never** use implicit or resource-owner-password flows.

### Step 2 — Register app (IaC snippet)
Terraform/Bicep for: app registration with redirect URIs per env; scopes `openid profile email offline_access` + min API scopes; **app roles** in manifest (mapped from `plan.md`); **group claim** enabled; certificate + secret rotation policy documented.

### Step 3 — Backend implementation
Use maintained library — never roll your own:
- Node: `openid-client` (certified) or Passport.
- Spring: `spring-security-oauth2-client` + `oauth2-resource-server`.
- Python: `authlib` or `msal`.
- Mendix: **MxIDProvider / SAML** module from Marketplace.

Enforce in code: verify `iss`, `aud`, `exp`, `nbf`, `nonce`, signature; validate `acr` / `amr` claim to confirm MFA; reject tokens missing `roles`/`groups`; HTTPS-only, TLS 1.2+, HSTS; session cookie `Secure; HttpOnly; SameSite=Lax; __Host-`; idle 30min / max 8h; CSRF protection.

### Step 4 — Claims contract & group-id convention (integration scope only)
- SCOPE: this skill wires SSO and CONSUMES the identity claim. It does NOT
  create or manage group→user or group→role assignment (IdP admin owns that).
- App-side contract the integration MUST enforce:
  - Prefer Entra **App Roles** → read the `roles` claim for authorization.
  - If `groups` is used, treat the claim as READ-ONLY input; never hardcode
    a group→role map in source — externalise to per-env config owned by admin.
- Group-id naming standard (enforced by this skill as a lint check):
  - Group object-ids/display names must follow the DRL convention
    `DRL-<app>-<env>-<role>` (e.g. `DRL-myday-prod-approver`).
  - Flag any consumed group claim that does not match the convention → Major.
- Overage awareness (integration guardrail, not admin fix):
  - If the `groups` claim is absent with an overage indicator
    (`groups.link` / `_claim_names`), the app MUST NOT infer "no access".
    Fail safe → surface "role source unavailable", do not hard-403 silently.

### Step 5 — Secure logout
- Local logout: clear session cookie.
- IdP logout: `end_session_endpoint` with `id_token_hint`.
- Back-channel logout: implement `/logout/back-channel` per OIDC BCL spec.

### Step 6 — Just-in-time provisioning (optional)
On first login, create user record with `sub` (immutable); do NOT rely on email as key.

### Step 7 — Tests
Golden path; missing MFA rejected; expired token → 401; replay (nonce reuse) fails; group not in map → 403; logout invalidates cross-app.

### Step 8 — Evidence for G4
`docs/sso.md`: protocol, IdP, flow rationale, redirect URIs per env, roles + group map, session config, MFA claim enforcement code pointer, screenshot of MFA challenge.

## Guardrails
1. **No implicit flow.** No resource-owner-password.
2. **Verify tokens locally** with cached JWKS.
3. **Enforce MFA claim** in code (defence in depth).
4. **No `id_token` in URL** after redirect.
5. **Rotate signing secrets** via KeyVault/Secrets Manager.
6. **Never accept `email` as user identity** — use `sub`/`oid`.

## Outputs
- Backend auth module + IaC snippet + role-mapping config + test suite + `docs/sso.md`.

## Stage-gate mapping
- **G4/G5 – Security, Privacy & Compliance (evidence only):**
  - AI-specific threat model; DAST/VAPT planned; token/session config captured.
  - The skill PRODUCES evidence; it NEVER self-certifies auth.
- **Mandatory human validation (blocker, per Playbook §9.2):**
  - InfoSec/DevSecOps + Architect MUST review SSO flow, token lifecycle,
    session/logout invalidation, and group/role→privilege mapping before merge.
  - ITGC/UAM control is signed off by InfoSec — not asserted by this skill.
- **G6 – Deployment Approval:** ITGC evidence pack attached + InfoSec sign-off.

## References
- OpenID Connect Core 1.0
- RFC 9700 – *OAuth 2.0 security best current practice*
- Microsoft Entra ID – *OIDC app registration guide*
- OWASP – *Session management*, *Authentication cheat sheets*
