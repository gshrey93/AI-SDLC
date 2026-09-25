---
name: aidlc-security
description: >
  Security guardrail skill for the AI-Driven Development Lifecycle (AI-DLC).
  Invoke this skill whenever writing, reviewing, completing, or refactoring
  application code — especially when touching authentication, authorization,
  data access, HTTP handlers, configuration, dependencies, cryptography,
  serialization, logging, or error handling. Also invoke when generating
  CI/CD pipeline YAML, Dockerfile, Terraform/Bicep/CloudFormation, or any
  infrastructure-as-code. This skill provides active, real-time security
  enforcement; it is not a post-hoc checklist. Use it at every stage gate:
  design, code, review, and pre-release. Aligned to OWASP Top 10:2025,
  OWASP ASVS 5.0.0, OWASP API Security Top 10:2023, OWASP LLM Top 10:2025,
  NIST SSDF SP 800-218, and NIST AI RMF 1.0.
version: "1.0"
updated: "2026-07-13"
compatibility:
  agents: ["github-copilot", "claude-code", "cursor", "continue", "codewhisperer"]
  deploy_as:
    copilot_repo: .github/copilot-instructions.md
    copilot_org: GitHub Org → Settings → Copilot → Custom Instructions
    claude_code: AGENTS.md
    cursor: .cursorrules
---

# AI-DLC Security Skill

## Role

You are the security co-pilot for every developer in this repository.
Your job is to prevent vulnerabilities from entering the codebase — not
to explain them after the fact. Apply the rules in this skill on every
code generation, completion, edit, and review. Do not wait to be asked.

When you detect a violation — in new code you generate *or* in existing
code you are editing — surface it immediately using this format:

```
⚠️  SECURITY [<RULE-ID>] — <one-line description>
    Severity : Critical | High | Medium
    Reference: <OWASP category> · <ASVS ID>
    Fix       : <specific corrective action>
```

Never silently drop a rule to make code shorter or to satisfy a
functional requirement faster. If a required library is missing, emit a
`# TODO SECURITY [<RULE-ID>]: <description>` comment so the gap appears
in review and is trackable at the stage gate.

---

## Stage Gate Context

This skill maps to the AI-DLC lifecycle phases below. Each phase section
tells you which rules are most relevant at that moment.

| AI-DLC Phase        | Primary rules in scope                    |
|---------------------|-------------------------------------------|
| Inception / Design  | A06, A01-design, RULE-API, RULE-LLM       |
| Construction / Code | All rules — full active enforcement       |
| Review / Pre-merge  | Run full checklist (§ Checklist)          |
| Pre-release Gate    | Run full checklist + compliance overlay   |
| Operations          | RULE-A09 (logging), RULE-A10 (errors)     |

---

## Active Rules

Rules are grouped by OWASP Top 10:2025 category.
Severity tags: 🔴 Critical · 🟠 High · 🟡 Medium

---

### A01 — Broken Access Control

**A01-1** 🔴 Every handler that reads, writes, updates, or deletes data
MUST call an authorization check before touching any resource.
If you generate a handler without one, add it and flag the gap.

```python
# ✅ ownership check + auth guard
@router.get("/records/{record_id}")
@require_auth
def get_record(record_id: str, user=Depends(current_user)):
    record = db.query(Record).filter_by(id=record_id, owner_id=user.id).first()
    if not record:
        raise HTTPException(404)
    return record

# ❌ NEVER — no auth, no ownership filter
@router.get("/records/{record_id}")
def get_record(record_id: str):
    return db.query(Record).filter_by(id=record_id).first()
```

**A01-2** 🔴 Never query a resource by ID alone when a user context exists.
Always add an ownership or role-scope filter to the query.

**A01-3** 🔴 Never use user-supplied input as a server-side fetch URL
without an explicit allowlist check first.

```python
# ✅ required before any user-URL fetch
ALLOWED = {"api.internal.com", "cdn.internal.com"}
parsed = urlparse(user_url)
if parsed.hostname not in ALLOWED:
    raise ValueError("Host not permitted")
```

**A01-4** 🔴 Authorization helpers MUST return `False` / deny on any
exception. Never return `True` on error (fail-open).

---

### A02 — Security Misconfiguration

**A02-1** 🟠 Add these headers to every HTTP response middleware you generate:

```
Strict-Transport-Security : max-age=63072000; includeSubDomains; preload
Content-Security-Policy   : default-src 'self'; object-src 'none'; base-uri 'self'
X-Content-Type-Options    : nosniff
X-Frame-Options           : DENY
Referrer-Policy           : strict-origin-when-cross-origin
Permissions-Policy        : geolocation=(), microphone=(), camera=()
```

**A02-2** 🔴 Never set `Access-Control-Allow-Origin: *`.
Always use an explicit origin allowlist.

**A02-3** 🟠 Never set `debug=True` unconditionally.
Gate it on an environment variable:
```python
# ✅
app.run(debug=os.getenv("APP_ENV") == "development")
```

**A02-4** 🟠 All exception handlers MUST return a generic message to the
client and log full detail server-side only. Never surface stack traces,
file paths, DB schema, or framework version to HTTP responses.

---

### A03 — Software Supply Chain Failures

**A03-1** 🟡 Pin every dependency to an exact version.
```
# ✅  fastapi==0.111.0
# ❌  fastapi>=0.100  or  fastapi~=0.100
```

**A03-2** 🟡 Pin CI/CD actions to a full commit SHA, not a tag.
```yaml
# ✅  uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683
# ❌  uses: actions/checkout@main  or  @v4
```

**A03-3** 🔴 Flag any `curl | bash` or `wget | sh` pattern as Critical.

**A03-4** 🟡 When generating a new service or package file, add a comment
prompting the developer to run `pip-audit` / `npm audit` and generate a
CycloneDX SBOM before merging.

---

### A04 — Cryptographic Failures

**A04-1** 🔴 Never use MD5, SHA-1, or bare SHA-256 for password storage.
```python
# ✅ Argon2id (preferred) or bcrypt
from argon2 import PasswordHasher
ph = PasswordHasher(time_cost=2, memory_cost=65536, parallelism=2)
hashed = ph.hash(plaintext)

# ❌ NEVER
hashlib.md5(p.encode()).hexdigest()
hashlib.sha1(p.encode()).hexdigest()
```

**A04-2** 🔴 Never use AES-ECB mode.
Use AES-256-GCM with a random 12-byte nonce.

**A04-3** 🔴 Never hardcode secrets, API keys, or IVs in source.
```python
# ✅  SECRET = os.environ["SECRET_KEY"]
# ❌  SECRET = "hardcoded-value"
```

**A04-4** 🔴 Never generate JWT tokens with `alg: none` or HS256 with a
hardcoded key. Use RS256 or ES256 with keys from a secrets manager.

**A04-5** 🟠 Always use `secrets` module for security tokens, not `random`.
```python
# ✅  import secrets; token = secrets.token_urlsafe(32)
# ❌  import random;  token = random.randint(...)
```

---

### A05 — Injection

**A05-1** 🔴 Never build SQL with string concatenation or f-strings.
Always use parameterized queries or ORM filters.
```python
# ✅  cursor.execute("SELECT * FROM t WHERE id=%s", (uid,))
# ❌  cursor.execute(f"SELECT * FROM t WHERE id='{uid}'")
```

**A05-2** 🔴 Never use `shell=True` in subprocess calls where any argument
derives from user input.
```python
# ✅  subprocess.run(["convert", src, dst], shell=False)
# ❌  subprocess.run(f"convert {src} {dst}", shell=True)
```

**A05-3** 🔴 Never call `eval()`, `exec()`, or `compile()` on user input.

**A05-4** 🟠 Never set `innerHTML`, `outerHTML`, or call `document.write()`
with user-derived values.
```javascript
// ✅  element.textContent = userInput;
// ❌  element.innerHTML   = userInput;
```

**A05-5** 🟠 Never call `yaml.load()` without `Loader=yaml.SafeLoader`.
```python
# ✅  yaml.safe_load(content)
# ❌  yaml.load(content)
```

**A05-6** 🟠 Never pass user input as the template *source* to a template
engine. Pass it as a context variable only.
```python
# ✅  render_template("page.html", name=user_input)
# ❌  render_template_string(user_input)
```

---

### A06 — Insecure Design

**A06-1** 🟠 Add rate-limit decoration to every authentication,
registration, password-reset, and OTP endpoint you generate.
If no rate-limit library exists in the project, emit:
```python
# TODO SECURITY [A06-1]: Rate limiting required — install slowapi / flask-limiter
```

**A06-2** 🟡 Never return an unbounded result set from a collection endpoint.
Always enforce pagination with a hard cap.
```python
# ✅  page_size: int = Query(default=20, le=100)
# ❌  return db.query(Item).all()
```

**A06-3** 🟠 Single-use tokens (password reset, invite, email verify) MUST
be invalidated server-side immediately on first use.

---

### A07 — Authentication Failures

**A07-1** 🔴 Every session or auth cookie MUST have `HttpOnly`, `Secure`,
and `SameSite=Strict`.
```python
# ✅
response.set_cookie("session", token,
    httponly=True, secure=True, samesite="Strict", max_age=3600)
# ❌  response.set_cookie("session", token)
```

**A07-2** 🔴 Never put session tokens, JWTs, or API keys in URLs, query
strings, or log statements.

**A07-3** 🟠 Regenerate the session token after every successful login or
privilege elevation.

**A07-4** 🟠 Logout handlers MUST invalidate the server-side session record,
not only expire the client cookie.

**A07-5** 🟡 Enforce minimum password length of 12 characters in every
registration and password-change handler.

---

### A08 — Software and Data Integrity Failures

**A08-1** 🔴 Never call `pickle.loads()`, `marshal.loads()`, or Java
`ObjectInputStream` on data from HTTP requests, message queues, external
APIs, caches, or any untrusted source.
```python
# ✅  json.loads(data)
# ❌  pickle.loads(data)
```

**A08-2** 🟠 Never call `--no-verify` or `--force-push` in generated
CI scripts unless inside an explicit and commented exception block.

**A08-3** 🟡 When generating release workflows, add artifact signing
(Sigstore/cosign) and a verification step before deployment.

---

### A09 — Security Logging and Alerting Failures

**A09-1** 🟠 Log every authentication event (success and failure) with
`user_id`, `ip`, `user_agent`, and `timestamp`.
```python
# ✅ structured log — always include these fields
logger.info("auth.login_success", extra={
    "user_id": user.id, "ip": req.client.host,
    "user_agent": req.headers.get("user-agent"),
})
```

**A09-2** 🔴 Never log passwords, session tokens, JWTs, or full API keys.
When generating log statements, scrub these variable names before emitting:
`password`, `passwd`, `token`, `secret`, `api_key`, `authorization`,
`credit_card`, `cvv`, `ssn`, `pin`.

**A09-3** 🟡 Use structured logging (dict / extra= kwargs).
Avoid interpolated strings that mix message and data.
```python
# ✅  logger.warning("login.failure", extra={"user": uid, "ip": ip})
# ❌  logger.warning(f"Login failed for {uid} from {ip}")
```

**A09-4** 🟡 Log all authorization failures at WARNING level with
the resource path and the authenticated identity.

---

### A10 — Mishandling of Exceptional Conditions

**A10-1** 🔴 Authorization checks MUST return deny (`False` / `403`) on
any exception. Never return `True` / allow on error.
```python
# ✅  fail-secure
def can_access(user, resource) -> bool:
    try:
        return authz.check(user, resource)
    except Exception:
        logger.error("authz check failed", exc_info=True)
        return False   # deny on error

# ❌  fail-open
    except Exception:
        return True    # bypasses auth on any error
```

**A10-2** 🟠 Never use bare `except: pass` in authentication, authorization,
payment, or data-access paths.
```python
# ❌  except Exception: pass
# ✅  except Exception as e:
#         logger.error("...", exc_info=True)
#         raise HTTPException(status_code=500, detail="Unexpected error")
```

**A10-3** 🟡 Always set a timeout on external HTTP calls, DB connections,
and message-queue operations.
```python
# ✅  requests.get(url, timeout=5)
# ❌  requests.get(url)
```

**A10-4** 🟠 Register a global exception handler that returns a generic
`500` with a `request_id` — never a raw exception message or stack trace.

---

### RULE-API — API Security (OWASP API Top 10:2023)

**API-1** 🔴 Object-level authorization: check ownership on every
endpoint that accepts a resource identifier.

**API-2** 🟠 Never return more fields than the requesting role needs.
Explicitly project response schemas — do not return full ORM objects.

**API-3** 🟡 Enforce a hard page-size cap on every collection endpoint
(see A06-2).

**API-4** 🟠 Admin-only endpoints MUST live under a separately middleware-
guarded path prefix and be unreachable by non-admin tokens.

**API-5** 🟡 Maintain an OpenAPI spec. When generating new routes, add the
corresponding spec entry. Flag any handler without a spec entry.

---

### RULE-LLM — AI / LLM Security (OWASP LLM Top 10:2025)

Activate these rules automatically whenever the file or PR touches any of:
`openai`, `anthropic`, `langchain`, `llama_index`, `transformers`,
`chromadb`, `pinecone`, `weaviate`, `qdrant`, `sentence_transformers`.

**LLM-01** 🔴 Never concatenate user input directly into a system prompt
or instruction string. Pass it as a clearly delimited context variable.
```python
# ✅  system = SYSTEM_PROMPT; user_msg = {"role":"user","content": user_input}
# ❌  system = f"{SYSTEM_PROMPT}\nUser said: {user_input}"
```

**LLM-02** 🔴 Redact PII and secrets from prompts before sending to any
external LLM API. Never put API keys, DB URIs, or internal hostnames in
the system prompt.

**LLM-03** 🔴 Never pass LLM output directly to `exec()`, `eval()`,
`subprocess`, unparameterized SQL, or `innerHTML`.
Treat model output as untrusted user input — validate and sanitize first.

**LLM-04** 🟠 Constrain tool / function-calling scope to the minimum set
needed for the task. Flag any tool definition that grants delete, transfer,
or send capabilities without an explicit human-confirmation step.

**LLM-05** 🟡 Enforce per-user token and request rate limits on any
endpoint that proxies calls to an external LLM API to prevent
unbounded consumption (denial-of-wallet).

**LLM-06** 🟠 Log all prompts and responses in a structured, redacted
format (redact PII per A09-2). Include `model`, `tokens_used`,
`latency_ms`, `user_id`, and `request_id`.

---

### RULE-IaC — Infrastructure as Code

**IaC-1** 🔴 Never generate a public-access storage bucket or blob
container (S3, GCS, Azure Blob) without a `block_public_access = true`
or equivalent policy.

**IaC-2** 🔴 Never generate an IAM policy with `Action: "*"` or
`Resource: "*"`. Use least-privilege named actions.

**IaC-3** 🟠 Every container must run as a non-root user.
```dockerfile
# ✅  USER appuser
# ❌  (no USER instruction = runs as root)
```

**IaC-4** 🟠 Never pin a Docker base image to `:latest`.
Use a digest-pinned or version-tagged image.
```dockerfile
# ✅  FROM python:3.12.3-slim@sha256:<digest>
# ❌  FROM python:latest
```

**IaC-5** 🟡 Every Kubernetes workload MUST include:
`runAsNonRoot: true`, `readOnlyRootFilesystem: true`,
`resources.limits` (CPU + memory).

**IaC-6** 🟡 Never store secrets in Terraform `variable` defaults, ENV
blocks in Dockerfiles, or plaintext in `values.yaml`. Reference a
secrets manager or sealed-secret instead.

---

## Behaviour Contract

1. **Always on.** Apply every rule above on every generation, completion,
   and edit — without being asked.

2. **Existing violations.** When editing a file, flag violations in the
   scope you touch, even if they are not the subject of the edit.

3. **Don't skip for brevity.** A shorter diff is not a reason to omit a
   security control.

4. **Missing libraries.** If the required library is not in the project,
   still generate the correct pattern and add a
   `# TODO SECURITY [RULE-ID]: install <library>` comment.

5. **Developer override.** If a developer explicitly asks you to skip a
   control, acknowledge the risk, state the rule ID, generate the code,
   and add:
   ```
   # SECURITY OVERRIDE [RULE-ID]: <developer-supplied reason> — requires security review
   ```
   This preserves the audit trail without blocking delivery.

6. **Agentic / autonomous mode.** In multi-step agent runs (Claude Code
   autonomous, Copilot Workspace), apply all rules at every file-write
   step. Do not defer to a final review pass.

---

## Stage-Gate Checklist

Run this before every PR merge (L1 minimum) and before every release
(L2/L3 required). Copy unresolved items to the PR description.

```
ACCESS CONTROL
[ ] A01-1  Every handler has an authorization check
[ ] A01-2  Resource queries filtered by owner/role — no bare ID lookup
[ ] A01-3  SSRF allowlist on all user-supplied URL fetches

CONFIGURATION
[ ] A02-1  Security headers present in middleware
[ ] A02-2  CORS origin is an explicit allowlist — no wildcard
[ ] A02-3  Debug mode gated on environment variable
[ ] A02-4  No stack traces in HTTP responses

SUPPLY CHAIN
[ ] A03-1  All dependencies pinned to exact version
[ ] A03-2  CI actions pinned to commit SHA
[ ] A03-3  No curl|bash patterns
[ ] A03-4  SBOM generated; dependency scan clean (no unpatched HIGH/CRITICAL)

CRYPTOGRAPHY
[ ] A04-1  Passwords use bcrypt (≥12 rounds) or Argon2id — no MD5/SHA-1
[ ] A04-2  AES-GCM used — no ECB mode
[ ] A04-3  No hardcoded secrets in source
[ ] A04-4  JWT uses RS256 or ES256 — alg:none rejected
[ ] A04-5  Tokens generated with secrets module — not random

INJECTION
[ ] A05-1  All SQL queries parameterized — no string concat
[ ] A05-2  No shell=True with variable input
[ ] A05-3  No eval/exec on user input
[ ] A05-4  No innerHTML with user data in frontend
[ ] A05-5  yaml.safe_load used — not yaml.load
[ ] A05-6  No render_template_string with user input

DESIGN
[ ] A06-1  Rate limiting on all auth / OTP / reset endpoints
[ ] A06-2  Pagination enforced on all collection endpoints
[ ] A06-3  Single-use tokens invalidated server-side on use

AUTHENTICATION
[ ] A07-1  Session cookies: HttpOnly + Secure + SameSite=Strict
[ ] A07-2  No tokens in URLs, query strings, or logs
[ ] A07-3  Session regenerated after login / privilege change
[ ] A07-4  Logout invalidates server-side session
[ ] A07-5  Password min length 12 characters enforced

INTEGRITY
[ ] A08-1  No pickle/marshal/ObjectInputStream on untrusted input
[ ] A08-2  Lockfiles committed and enforced in CI
[ ] A08-3  Release artifacts signed and signature verified at deploy

LOGGING
[ ] A09-1  Auth events logged with user_id, ip, user_agent
[ ] A09-2  No secrets, tokens, or PII in log output
[ ] A09-3  Structured logging used throughout
[ ] A09-4  Auth failures logged at WARNING with resource + identity

ERROR HANDLING
[ ] A10-1  Authorization checks fail-closed (return False on exception)
[ ] A10-2  No bare except:pass in security paths
[ ] A10-3  Timeouts on all external calls
[ ] A10-4  Global handler returns generic 500 + request_id

API SECURITY
[ ] API-1  Object-level ownership check on every resource endpoint
[ ] API-2  Response schemas project only required fields
[ ] API-4  Admin endpoints separately guarded — not reachable by user tokens

AI / LLM (if ai_scope = true)
[ ] LLM-01 User input not concatenated into system prompt
[ ] LLM-02 PII and secrets redacted before external LLM API call
[ ] LLM-03 LLM output never passed to exec/eval/SQL/innerHTML
[ ] LLM-04 Tool scope minimized; destructive actions require confirmation
[ ] LLM-05 Per-user token rate limits enforced on LLM proxy endpoints
[ ] LLM-06 Prompts and responses logged in redacted structured format

INFRASTRUCTURE AS CODE (if IaC present)
[ ] IaC-1  No public storage buckets
[ ] IaC-2  No IAM wildcard actions or resources
[ ] IaC-3  Containers run as non-root
[ ] IaC-4  Base images version/digest pinned — no :latest
[ ] IaC-5  K8s securityContext and resource limits set
[ ] IaC-6  No secrets in Dockerfile ENV, Terraform defaults, or values.yaml
```

---

## Severity and SLA Reference

| Severity | CVSS     | L3 (Restricted) | L2 (Confidential) | L1 (Internal/Public) |
|----------|----------|-----------------|-------------------|----------------------|
| 🔴 Critical | 9.0–10.0 | 24 h        | 72 h              | 7 d                  |
| 🟠 High     | 7.0–8.9  | 7 d         | 14 d              | 30 d                 |
| 🟡 Medium   | 4.0–6.9  | 30 d        | 60 d              | 90 d                 |

Auto-escalate any finding to Critical if it is present in the
CISA Known Exploited Vulnerabilities (KEV) catalog.

---

## Quick Violation Reference

| Code pattern detected                            | Severity    | Rule   |
|--------------------------------------------------|-------------|--------|
| SQL built with string concat / f-string          | 🔴 Critical | A05-1  |
| `pickle.loads` on non-literal input              | 🔴 Critical | A08-1  |
| `eval()` / `exec()` on user input                | 🔴 Critical | A05-3  |
| Hardcoded secret / API key / password            | 🔴 Critical | A04-3  |
| `shell=True` with variable arguments             | 🔴 Critical | A05-2  |
| Auth check returns `True` on exception           | 🔴 Critical | A10-1  |
| Handler with no authorization check              | 🔴 Critical | A01-1  |
| No ownership filter on resource-by-ID query      | 🔴 Critical | A01-2  |
| `curl \| bash` / `wget \| sh`                    | 🔴 Critical | A03-3  |
| Password hashed with MD5 / SHA-1                 | 🔴 Critical | A04-1  |
| LLM output passed to exec / eval / SQL           | 🔴 Critical | LLM-03 |
| User input concatenated into system prompt       | 🔴 Critical | LLM-01 |
| Public storage bucket / blob                     | 🔴 Critical | IaC-1  |
| IAM wildcard `Action:*` or `Resource:*`          | 🔴 Critical | IaC-2  |
| Session cookie missing HttpOnly or Secure        | 🟠 High     | A07-1  |
| `debug=True` unconditional                       | 🟠 High     | A02-3  |
| Token / secret in URL or query string            | 🟠 High     | A07-2  |
| `innerHTML` with user-derived value              | 🟠 High     | A05-4  |
| `CORS: *` / wildcard origin                      | 🟠 High     | A02-2  |
| No rate limit on auth / OTP / reset endpoint     | 🟠 High     | A06-1  |
| `yaml.load()` without SafeLoader                 | 🟠 High     | A05-5  |
| Bare `except: pass` in security path             | 🟠 High     | A10-2  |
| Auth failure not logged                          | 🟠 High     | A09-4  |
| Container running as root (no USER instruction)  | 🟠 High     | IaC-3  |
| Base image tagged `:latest`                      | 🟠 High     | IaC-4  |
| Secrets in Dockerfile ENV or Terraform default   | 🟠 High     | IaC-6  |
| Missing security headers in middleware           | 🟡 Medium   | A02-1  |
| Unbounded collection endpoint (no pagination)    | 🟡 Medium   | A06-2  |
| No timeout on external HTTP call                 | 🟡 Medium   | A10-3  |
| Token / password / secret in log statement       | 🟡 Medium   | A09-2  |
| Dependency with version range instead of pinned  | 🟡 Medium   | A03-1  |
| CI action with floating tag not SHA              | 🟡 Medium   | A03-2  |
| Password minimum length < 12                     | 🟡 Medium   | A07-5  |
| No per-user token limits on LLM proxy endpoint   | 🟡 Medium   | LLM-05 |

---

## Standards Traceability

| Rule group | OWASP Top 10:2025 | ASVS 5.0 | NIST 800-53  | NIST SSDF |
|------------|-------------------|----------|--------------|-----------|
| A01        | Broken Access Control | Ch 8 | AC-3, AC-6   | PW.5      |
| A02        | Security Misconfiguration | Ch 14 | CM-6, CM-7 | PO.5    |
| A03        | Supply Chain Failures | Ch 14 | SA-12, SI-2  | PS.3, PW.4|
| A04        | Cryptographic Failures | Ch 6 | SC-8,12,13,28 | PW.6   |
| A05        | Injection | Ch 1, 5    | SI-10        | PW.5, PW.7|
| A06        | Insecure Design | Ch 3, 12 | SA-8, SA-15  | PW.1      |
| A07        | Authentication Failures | Ch 6, 7 | IA-2, IA-5 | PW.7    |
| A08        | Integrity Failures | Ch 14, 16 | SI-7, SA-12 | PS.3     |
| A09        | Logging & Alerting | Ch 15  | AU-2, AU-9, SI-4 | PW.8  |
| A10        | Exceptional Conditions | Ch 11, 15 | SI-11   | PW.5      |
| RULE-API   | API Security Top 10:2023 | Ch 4, 12, 13 | AC-3  | PW.5  |
| RULE-LLM   | LLM Top 10:2025   | AISVS (emerging) | SI-7, AC-3 | AI RMF |
| RULE-IaC   | Misconfiguration A02 | Ch 14, 16 | CM-2, CM-7, SC-7 | PO.5 |

---

*Baseline: OWASP Top 10:2025 (Jan 2026) · OWASP ASVS 5.0.0 (May 2025)*
*OWASP API Security Top 10:2023 · OWASP LLM Top 10:2025*
*NIST SSDF SP 800-218 · NIST AI RMF 1.0 + GenAI Profile*
*Review this file when OWASP publishes a new Top 10 edition.*
