# ADR-0003: Shared Structured Logging Library (`libs/logging`)

- **Status:** Accepted
- **Date:** 2026-11-22
- **Deciders:** PrincessPink Architecture
- **Related Documents:** [`docs/Concept.md`](../Concept.md), [`README.md`](../../README.md), [`ADR-0004`](ADR-0004-shared-opentelemetry-observability.md), [`ADR-0006`](ADR-0006-shared-configuration-library.md), [`ADR-0007`](ADR-0007-shared-uuid-utilities.md)

---

## Context

PrincessPink decomposes its platform into dozens of independently versioned Go (`1.27+`) microservices across five functional domains (`frontend-*`, `user-admin`, `chat-*`, `character-registry`/`sheet-aggregator`/`attr-*`, and `sim-*`) running on **Azure Kubernetes Service (AKS)** and shipping logs to **Azure Monitor & Log Analytics** (Concept §6.2 & §7.1).

Without a shared logging library under `libs/logging`:

1. **Inconsistent Log Schemas:** Different microservices would emit incompatible field names, timestamps, and severity levels, making cross-service queries across `frontend-gateway` → `sheet-aggregator` → `attr-*` or `sim-clock` → `sim-conception` → `sim-dna` brittle.
2. **Missing Trace & Domain Correlation:** Correlating logs with distributed OpenTelemetry traces and PrincessPink's domain identifiers (`service_version`, `trace_id`, `span_id`, `correlation_id`, `user_uuid`, `group_id`, `character_uuid`) would be duplicated and error-prone across services.
3. **Accidental PII or Secret Leakage:** `user-admin` handles email addresses, `Argon2id` hashes, MFA secrets, and JWTs; `chat-service` handles user-authored chat messages. Logging raw request payloads or unredacted PII would violate security and privacy requirements.

---

## Decision

PrincessPink establishes a shared Go module **`libs/logging`** built strictly on Go's standard library **`log/slog`**, providing a uniform structured JSON logger, context-based correlation enrichment, PII/secret redaction, and HTTP/gRPC/event-consumer middleware.

### 1. Logger Construction & Output Format

- **Standard Library Foundation:** `libs/logging` wraps `log/slog` with a `JSONHandler` writing to `os.Stdout` (the Kubernetes container log stream collected by Azure Monitor / Log Analytics). A human-readable `TextHandler` mode is supported strictly for local developer terminals (`LOG_FORMAT=text`).
- **Base Resource Fields:** Every logger instance is initialized at service startup with immutable service identity attributes injected from `libs/config` and `-ldflags` build metadata:
  - `service_name` (e.g., `sim-gamete-surface`, `sheet-aggregator`)
  - `service_version` (from `services/<service>/VERSION`, e.g., `1.2.0`)
  - `git_commit` (short commit SHA)
  - `environment` (`local`, `dev`, `staging`, `prod`)
- **Dynamic Log Level:** Configured via `LOG_LEVEL` (`DEBUG`, `INFO`, `WARN`, `ERROR`, default `INFO`) backed by `slog.LevelVar` so log verbosity can be adjusted safely without leaking debug details in production.

### 2. Context-Driven Correlation & Domain Enrichment

`libs/logging` provides a custom `slog.Handler` wrapper (`ContextHandler`) and typed context accessors so every log record emitted via `logger.InfoContext(ctx, ...)` automatically includes available request and domain context:

| Field | Source | Notes |
| :--- | :--- | :--- |
| `trace_id` / `span_id` | OpenTelemetry `trace.SpanFromContext(ctx)` | Links container logs directly to distributed traces ([ADR-0004](ADR-0004-shared-opentelemetry-observability.md)). |
| `correlation_id` | Request/event context (`libs/uuid`) | End-to-end request or simulation-chain correlation ID (Concept §3.4). |
| `user_uuid` | Authenticated subject context | Non-PII user UUID only; never email, display name, or credentials. |
| `group_id` | Group/campaign context | Scopes simulation ticks, GM actions, and Group Chat diagnostics. |
| `character_uuid` | Character context | Traces lifecycle events from `CONCEIVED` through `DECEASED`. |
| `world_server_id` | Chat context (when applicable) | Traces World Chat Server routing and switches ([ADR-0002](ADR-0002-world-chat-microservices-and-server-selection.md)). |

### 3. Privacy, Secret Redaction & Safety Hygiene

- **Attribute Sanitizer (`ReplaceAttr`):** `libs/logging` registers a mandatory `ReplaceAttr` hook that redacts sensitive key patterns (`password`, `secret`, `token`, `authorization`, `cookie`, `mfa_secret`, `dsn`, `email`) to `"[REDACTED]"`.
- **Non-PII Discipline:** Services must log `user_uuid` rather than email addresses or raw JWTs, and must never log raw chat message bodies at `INFO`/`WARN`/`ERROR` levels (moderation audit trails are persisted separately in PostgreSQL `chat.*` with strict access controls).
- **Testing Support:** `libs/logging` exports a `NewTestLogger(t)` helper (capturing structured records in memory or routing to `t.Log`) so unit and deterministic simulation tests can assert expected log events without noisy stdout output.

### 4. Transport & Framework Integration

- **Gin HTTP Middleware:** Logs request method, route template (never raw query tokens), status code, latency, and client request ID for all `frontend-*` services while skipping noisy `/healthz` and `/readyz` probes unless they fail.
- **gRPC Interceptors:** Unary and stream interceptors enrich `context.Context` from incoming gRPC metadata (`correlation_id`, OpenTelemetry span context) and log RPC method, gRPC status code, and duration.
- **NATS JetStream Consumer Wrapper:** Extracts `correlation_id`, `group_id`, `character_uuid`, and W3C trace headers from message headers into `context.Context` before invoking event handlers.

---

## Options Considered

| Option | Description | Evaluation |
| :--- | :--- | :--- |
| **1. Go Standard `log/slog` Wrapped in `libs/logging`** | Zero-dependency core using `log/slog` with a thin `ContextHandler`, redaction hook, and Gin/gRPC/NATS adapters. | **Selected.** Idiomatic in Go 1.27+, zero third-party logging dependency lock-in, high performance, native `context.Context` support, and directly aligned with Concept §7.1. |
| **2. `go.uber.org/zap`** | High-throughput third-party structured logger with custom field constructors. | **Rejected.** Adds external dependency and custom API surface across 25+ microservices; `log/slog` already meets PrincessPink's throughput and allocation targets without extra dependencies. |
| **3. `github.com/rs/zerolog`** | Zero-allocation JSON logger with fluent chaining API. | **Rejected.** Non-standard API diverges from Go ecosystem libraries that natively accept `*slog.Logger` / `slog.Handler`. |
| **4. Per-Service Ad-Hoc Logging** | Each microservice configures `log` or `slog` independently. | **Rejected.** Guarantees schema drift, inconsistent field names, missing `trace_id`/`service_version` enrichment, and higher risk of accidental PII/secret logging. |

---

## Rationale & Alignment with PrincessPink Requirements

1. **Direct Alignment with Technical Concept (Concept §3.5 & §7.1):**
   Concept §7.1 explicitly mandates Go's standard `log/slog` emitting JSON logs enriched with `service_version`, `trace_id`, `user_uuid` (non-PII), `group_id`, and `character_uuid`. Centralizing this in `libs/logging` guarantees uniform compliance across every service.
2. **Independent Microservice Versioning Traceability (Concept §3.5):**
   Embedding `service_version` on every log line ensures that during rolling updates or scientific model iterations, operators can immediately distinguish log behavior between `sim-gamete-surface` v1.1.0 and v1.2.0.
3. **Security & Defense in Depth (Concept §4.2):**
   Built-in attribute redaction prevents accidental credential or PII exposure in Azure Log Analytics, complementing `user-admin`'s separate immutable PostgreSQL audit trail.
4. **Minimal Dependency Footprint:**
   Keeping `libs/logging` centered on the Go standard library minimizes supply-chain exposure (`govulncheck`) and keeps static `distroless/static` binaries small.

---

## Consequences

### Positive
- Uniform, machine-parseable JSON logs across all AKS namespaces (`frontend`, `user-admin`, `chat`, `character-sheet`, `simulation`).
- Automatic correlation between logs, OpenTelemetry traces, and PrincessPink domain entities (`character_uuid`, `group_id`, `user_uuid`).
- Zero third-party logging framework lock-in; seamless interoperability with Go 1.27+ libraries.

### Trade-offs & Operational Notes
- **Discipline on Context Propagation:** Automatic enrichment works only when service code calls `*Context` logging methods (`InfoContext`, `WarnContext`, `ErrorContext`). `golangci-lint` rules (`sloglint` / custom linter config) should enforce context-aware logging and consistent key naming.
- **Not a Replacement for Audit Logging:** Application logs in `libs/logging` are operational diagnostics shipped to Azure Monitor; security and compliance audit trails (`user_admin.*`, `chat.*`) remain durably stored in PostgreSQL 18+ (Concept §4.2 & [ADR-0001](ADR-0001-minimum-postgresql-version.md)).
