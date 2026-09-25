---
name: api-integration
description: "Scaffold REST or OData integration modules with production-grade error handling, retry, timeout, circuit breaker, idempotency, secret handling, and observability. Trigger when the user says 'integrate with X API', 'call the REST endpoint', 'consume OData feed', 'add API client', or plan.md has an integration task. Covers both consumer and provider sides."
stage_gate: "G1 → G2"
priority: High
owner: Vishali / Integration Lead
version: 1.0
grounded_in:
  - "AWS Well-Architected Framework – Reliability Pillar (Retry with backoff, circuit breaker, idempotency)"
  - "AWS SDK v3 – Middleware & retry strategies"
  - "Google Cloud Architecture Framework – Reliability principles"
  - "Google SRE workbook – Handling overload, retry budgets"
  - "OData v4 spec / Mendix REST module"
  - "OWASP API Security Top 10 (2023)"
---

# REST / OData API Integration

## Purpose
Generate a **safe, resilient, observable** integration module in one shot — never let a developer write a bare `fetch` in production. Covers HTTP client, retries, circuit breaker, secret loading, request/response schemas, telemetry, and error mapping.

## When to invoke
- User says: *"integrate with"*, *"consume this API"*, *"call the endpoint"*, *"add REST client"*, *"OData integration"*.
- `plan.md` task type is `api-integration`.
- A YAML/JSON OpenAPI or `$metadata` OData contract is attached.

## Inputs (required)
| Input | Details |
|---|---|
| Integration type | `REST` \| `OData` \| `GraphQL` |
| Direction | `consumer` \| `provider` |
| Contract | OpenAPI 3.x YAML, OData `$metadata` XML, or GraphQL SDL |
| Base URL & environment | per env, stored in secret manager, **not** hard-coded |
| Auth mechanism | `OAuth2 client-creds` \| `OAuth2 auth-code` \| `mTLS` \| `API-key-in-header` \| `HMAC` |
| Rate limits | Requests-per-second, if known |
| Idempotency | Which operations must be idempotent |
| Data classification | Does payload contain PII/PHI/GxP data? |
| Target stack | `node-ts` \| `java-spring` \| `python` \| `mendix` |

## Workflow

### Step 1 — Parse the contract
- OpenAPI → TypeScript types via `openapi-typescript`.
- OData → parse `$metadata`, map EDM types, generate entity types + query builders.
- GraphQL → generate typed hooks (`graphql-codegen`).

### Step 2 — Emit the client module
```
src/integrations/<vendor>/
  ├── client.ts          # HTTP client with middleware stack
  ├── types.ts           # generated from contract
  ├── operations/
  ├── errors.ts          # domain error mapping
  ├── config.ts          # env-driven config, secret loader
  ├── telemetry.ts       # logs, metrics, traces
  └── __tests__/
      ├── client.contract.test.ts
      └── client.chaos.test.ts
```

### Step 3 — Apply the AWS/Google reliability stack
Every client MUST include, in order:
1. **Timeout** — connect ≤ 5 s, total ≤ 30 s.
2. **Retry with jittered exponential backoff** — 3 attempts, base 200 ms, cap 5 s, jitter ±30 %. Retry only on `408, 429, 500, 502, 503, 504` + network errors.
3. **Circuit breaker** — open after 5 consecutive failures in 30 s window; half-open after 60 s.
4. **Idempotency key** — auto UUIDv4 for POST/PUT operations flagged idempotent; `Idempotency-Key` header.
5. **Rate limiter** — token bucket from `Inputs.Rate limits`.
6. **Correlation ID propagation** — `traceparent` (W3C) + `X-Correlation-Id`.
7. **Secret loading** — from AWS Secrets Manager / Azure Key Vault / GCP Secret Manager; NEVER `process.env` for API keys.

### Step 4 — Error handling policy
| HTTP | Class | Retry? | Surface to user |
|---|---|---|---|
| 400 | `ValidationError` | No | Field-level messages |
| 401 | `AuthError` | No (refresh once if OAuth) | Redirect to login |
| 403 | `ForbiddenError` | No | Generic "access denied" |
| 404 | `NotFoundError` | No | Domain-specific message |
| 408, 429 | `TransientError` | Yes | "Retrying…" |
| 5xx | `UpstreamError` | Yes (except 501) | "Service unavailable" |
| Network | `NetworkError` | Yes | "Check connection" |

### Step 5 — Telemetry (mandatory)
- **Log:** structured JSON — `{timestamp, correlationId, operation, vendor, status, durationMs, retryCount, breakerState}`
- **Metric:** `integration.<vendor>.<operation>.{count, latency, error_rate}`
- **Trace:** OpenTelemetry span.

Never log request/response bodies containing PII/PHI — mask via `telemetry.ts`.

### Step 6 — Tests
- **Contract test** — validate against OpenAPI/OData contract.
- **Chaos test** — inject 500s, 429s, timeouts; assert retry / breaker.
- **Idempotency test** — same `Idempotency-Key` twice → single downstream side-effect.

### Step 7 — Provider side (if `direction = provider`)
- Route handlers, request validation (JSON schema), standard error envelope `{ code, message, correlationId, details[] }`, rate limit middleware, OpenAPI docs at `/docs`, CORS locked to allow-list.

## Guardrails
1. **No secrets in code, `.env` files committed, or logs.**
2. **No `curl` / `fetch` without middleware.**
3. **Prod calls require TLS 1.2+.**
4. **Idempotency required for money-moving, state-mutating operations.**
5. **Payload masking** for PII/PHI in logs.
6. **Human review mandatory.**
7. **Prompt audit:** call `prompt-audit-trail`.

## Outputs
- Client module + `docs/integrations/<vendor>.md` + OpenAPI/OData types + contract/chaos test suites.

## Stage-gate mapping
- **G1:** *"Does the context pack include APIs and coding standards?"*
- **G2:** *"Were approved reusable skills used — API…?"*
- **G4:** *"Is SAST scan completed?"*, *"Are all critical/high vulnerabilities fixed?"*

## References
- AWS Well-Architected – *Reliability Pillar: Design principles*
- AWS SDK v3 – *Retry strategies (standard/adaptive)*
- Google SRE Workbook – *Handling overload, retry budgets*
- OWASP – *API Security Top 10 (2023)*
- W3C – *traceparent (Trace Context)*
