# AGENTS.md — PrincessPink Coding & Architecture Guidelines

This file provides authoritative instructions for AI coding agents and contributors working on **PrincessPink**. Every change must align with [`docs/Concept.md`](docs/Concept.md) and the Architecture Decision Records in [`docs/architecture/`](docs/architecture/).

---

## 1. Project Overview & Current Phase

- **What PrincessPink Is:** An open-source, scientific, population-level simulation of human reproduction and generational lineage presented through a pen-and-paper RPG interface.
- **Current Stage:** Phase 0 (Architectural Foundation). Shared libraries under `pkg/` and microservices under `services/` are being built incrementally according to the phased roadmap in `docs/Concept.md`.
- **Authoritative Documentation:**
  - [`docs/Concept.md`](docs/Concept.md) — Domain model, lifecycle, genetics/simulation rules, service catalog, storage, and AKS deployment architecture.
  - [`docs/architecture/ADR-0001`](docs/architecture/ADR-0001-minimum-postgresql-version.md) — Minimum PostgreSQL 18+ baseline.
  - [`docs/architecture/ADR-0002`](docs/architecture/ADR-0002-world-chat-microservices-and-server-selection.md) — World Chat microservices & server selection.
  - [`docs/architecture/ADR-0003`](docs/architecture/ADR-0003-shared-logging-library.md) — Shared structured logging (`pkg/logging`).
  - [`docs/architecture/ADR-0004`](docs/architecture/ADR-0004-shared-opentelemetry-observability.md) — Shared OpenTelemetry observability (`pkg/telemetry`).
  - [`docs/architecture/ADR-0005`](docs/architecture/ADR-0005-shared-grpc-protobuf-contracts.md) — Shared gRPC & Protobuf contracts (`pkg/proto`).
  - [`docs/architecture/ADR-0006`](docs/architecture/ADR-0006-shared-configuration-library.md) — Shared configuration (`pkg/config`).
  - [`docs/architecture/ADR-0007`](docs/architecture/ADR-0007-shared-uuid-utilities.md) — Shared UUIDv7 utilities (`pkg/uuid`).
  - [`docs/architecture/ADR-0008`](docs/architecture/ADR-0008-multi-module-makefile-build-automation.md) — Multi-module `Makefile` build automation.
  - [`docs/architecture/ADR-0009`](docs/architecture/ADR-0009-github-actions-ci-cd.md) — GitHub Actions CI/CD architecture.
  - [`docs/architecture/ADR-0010`](docs/architecture/ADR-0010-user-admin-auth-rbac-and-group-management.md) — `user-admin` auth, RBAC & group management.

---

## 2. Non-Negotiable Content & Safety Policy

All code, UI templates, API schemas, seed data, tests, and documentation **must** strictly enforce:

1. **Zero Violence & Zero Gore:** No combat, weapons, injury graphics, gore, or violent narratives. Characters live and pass away strictly through natural biological lifecycles.
2. **Zero Nudity & Zero Explicit Content:** Human reproduction is modeled purely through abstract scientific data, clinical parameters, biological state transitions, and tabletop-style stats/events—never explicit text, imagery, or adult themes.
3. **Safe-by-Design Visuals:** Character art is strictly limited to deterministic, stylized comic-art face portraits (head and shoulders) derived from phenotype and age stage. Do not allow unmoderated free-form image uploads; keep text and attributes schema-driven.

---

## 3. Core Domain Invariants

Respect these domain rules across all services and tests:

- **Permanent Identity & Lifecycle:** Assign a globally unique, immutable `UUIDv7` at conception and preserve it across `CONCEIVED` → `GESTATING` → `ALIVE` → `DECEASED`. Deceased character records remain queryable; parent references are immutable (except founder characters).
- **Genetics vs. Phenotype:** The 23-pair diploid genome, biological gender (`FEMALE`/`MALE`), and Mendelian ABO + RhD `blood_type` are determined at conception and are **immutable**. Appearance (`eye_color`, `hair_color`, `skin_color`), physical metrics (`height_cm`, `weight_kg`, BMI, body composition), health indicators, and fertility/intercourse values evolve dynamically across life stages and role-play.
- **Gender-Specific Biology:**
  - Female characters receive a dedicated UUID-linked Egg-Reserve SQLite database at birth; fertility is strictly `0` before first ovulation and upon climacterium.
  - Male characters have fertility strictly `0` before puberty, rising from teenage onset to a peak around age 21 and declining gradually; each ejaculation produces an event-specific sperm-cohort SQLite database whose quality degrades on short-interval consecutive ejaculations.
- **Determinism & Traceability:** All stochastic simulation steps must use explicit seeded PRNGs derived from `(group_id, sim_tick, event_id)`. Never hardcode magic biological constants in code or environment variables—store scientific parameters in versioned read-only SQLite reference datasets or versioned `GROUP.simulation_config` JSONB, and record the producing `service_version` on simulation outputs/events.
- **Players, Game Masters & Groups:**
  - A Player may own multiple characters but plays **only one already-owned character per group**, locked at group start.
  - Children conceived or born in a group start as unowned NPCs, require mutual agreement between both parents' Players for ownership, and remain NPCs in their origin group (playable only in a future group).
  - Game Masters oversee only their own groups; all GM adjustments (e.g., bounded `weight_kg` changes, simulation speed/pause) must be bounded, rationale-backed, and recorded in immutable audit logs.
  - Each group has an independent simulation clock initialized with a mandatory `dd/MM/YYYY` start date at `0:00 h` (default speed: 1 simulated year = 24 real hours).

---

## 4. Repository Layout & Multi-Module Workspace

- **Workspace:** Go **1.27+** multi-module workspace defined in root `go.work` (`toolchain go1.27.4`; no root module). Register every new module under `pkg/<module>` or `services/<service>` with `make work-use` and `make work-sync`.
- **Shared Packages (`pkg/`):** Reusable platform libraries (`pkg/logging`, `pkg/telemetry`, `pkg/proto`, `pkg/config`, `pkg/uuid`). Keep them small, well-tested, and free of service-specific business logic.
- **Microservices (`services/<service-name>/`):** Independently buildable, deployable, and semantically versioned services:
  - Must contain `go.mod`, a `VERSION` file (SemVer, e.g. `0.1.0`), `cmd/<service-name>/main.go` (or `cmd/server/main.go`), and `internal/` packages for private domain/adapter code.
  - Release tags follow `<service-name>/v<VERSION>`.
  - Embed `Version`, `Commit`, and `BuildDate` via `-ldflags` (handled automatically by `make build`).
- **Communication Boundaries:**
  - Browser-facing edge (`frontend-*`): Go + **Gin** HTTP/HTMX and authenticated TLS WebSockets (`wss://`).
  - Internal synchronous RPC: **gRPC / Protocol Buffers** (`pkg/proto`).
  - Internal asynchronous events & chat fan-out: **NATS JetStream** (with transactional outbox for PostgreSQL writes and idempotent consumers for at-least-once delivery).

---

## 5. Go Best Practices & Project Standards

### 5.1 Idiomatic Go & Code Structure

- Follow [Effective Go](https://go.dev/doc/effective_go) and [Go Code Review Comments](https://go.dev/wiki/CodeReviewComments).
- Format all Go code with `gofmt -s` (`make fmt`). Keep imports grouped cleanly (standard library, third-party, internal/workspace packages).
- Keep packages cohesive and avoid package-level mutable globals; pass dependencies explicitly via constructors (`New...`).
- Define small, focused interfaces **at the consumer side**, not preemptively in the implementation package.
- Keep `internal/` packages unexported to other modules; expose only intentional APIs under `pkg/`.
- Prefer simple, readable control flow with early returns over deep nesting. Avoid unnecessary reflection or premature abstraction.
- Always document exported types, functions, methods, and constants with clear Go doc comments starting with the symbol name.

### 5.2 Context, Concurrency & Resource Management

- Pass `context.Context` as the first parameter of every function performing I/O, RPC, database access, messaging, or structured logging. Never store `context.Context` inside structs.
- Enforce deadlines/timeouts on all outbound gRPC, HTTP, database, and NATS calls.
- Use `golang.org/x/sync/errgroup` (`errgroup.WithContext`) for bounded parallel fan-out (e.g., `sheet-aggregator`), implementing graceful degradation for non-critical attributes.
- Ensure every goroutine has a clear cancellation path and lifetime; close channels from the sender side only.
- Bound CPU/memory-intensive operations (such as Argon2id password hashing) with explicit semaphores or worker pools to prevent OOM/DoS.
- Always close resources (`rows.Close()`, `resp.Body.Close()`, SQLite handles, file descriptors) and handle close errors on write paths.

### 5.3 Error Handling

- Never silently discard errors (`_ = ...` is forbidden unless explicitly justified with a comment for benign cleanup).
- Wrap errors with operation context using `fmt.Errorf("operation: %w", err)` so callers can inspect chains with `errors.Is` and `errors.As`.
- Map domain errors cleanly to gRPC status codes (`codes.InvalidArgument`, `codes.NotFound`, `codes.PermissionDenied`, etc.) or HTTP status codes at service boundaries.
- Never leak secrets, raw SQL/DSN details, or internal stack traces in external API responses or error messages.

### 5.4 Mandatory Shared Platform Libraries (ADRs)

- **Logging (`pkg/logging`, ADR-0003):**
  - Use stdlib `log/slog` via `pkg/logging` only (do **not** introduce Zap or Zerolog).
  - Always use context-aware methods (`InfoContext`, `WarnContext`, `ErrorContext`) so `trace_id`, `span_id`, `correlation_id`, `user_uuid`, `group_id`, and `character_uuid` are automatically attached.
  - Output JSON to stdout by default; never log PII (emails, passwords, MFA secrets, raw JWTs, DSNs, or raw chat message bodies). Log non-PII `user_uuid`.
- **Observability (`pkg/telemetry`, ADR-0004):**
  - Initialize OpenTelemetry once in `main()` via `telemetry.Init(ctx, cfg)` and invoke bounded-timeout `Shutdown(ctx)` on `SIGTERM`/`SIGINT`.
  - Propagate W3C Trace Context and Baggage across Gin (`otelgin`), gRPC (`otelgrpc`), and NATS JetStream headers.
  - Follow metric naming `princesspink_<domain>_<metric>_<unit>`. **Never** use unbounded identifiers (`character_uuid`, `user_uuid`, `group_id`, `ejaculation_id`) as Prometheus labels.
  - Expose `/healthz`, `/readyz`, and internal-only `/metrics` (never exposed through public ingress).
- **gRPC & Protobuf (`pkg/proto`, ADR-0005):**
  - Define all internal RPC and NATS event schemas under `pkg/proto/` governed by `buf` (`make proto-lint`, `make proto-breaking`, `make proto-gen`).
  - Commit generated Go code under `pkg/proto/gen/go/` so standard `go build`/`go test` work without `buf`/`protoc`.
  - Evolve `v1` contracts additively only; reserve removed field names/numbers; introduce `v2` for breaking changes.
  - Use `pkg/proto/grpcutil` server/client factories and register `grpc.health.v1.Health` on every gRPC server.
- **Configuration (`pkg/config`, ADR-0006):**
  - Load operational settings via typed `config.Load[T](ctx)` with fail-fast validation before opening listeners. Do **not** use Viper or scattered `os.Getenv` calls, and do **not** silently load `.env` files in containers.
  - Support `*_FILE` secret indirection (Azure Key Vault CSI / Docker secrets) and wrap sensitive fields in `config.Secret` so `String()`, `MarshalJSON()`, and `LogValue()` always emit `[REDACTED]`.
- **UUIDs (`pkg/uuid`, ADR-0007):**
  - Generate all domain, event, outbox, and correlation IDs as RFC 9562 **UUIDv7** via `pkg/uuid` (do **not** call `github.com/google/uuid` directly or use UUIDv4).
  - Validate and reject nil/malformed UUIDs at all API/event boundaries.
  - Construct SQLite artifact filenames strictly from validated canonical lowercase UUIDs (`egg_reserve_<uuid>.sqlite`, `ejaculation_<uuid>.sqlite`) to prevent path traversal.
  - **Never** use UUIDs as security secrets (sessions, refresh/reset/CSRF tokens); use `crypto/rand` tokens of at least 256 bits.

### 5.5 Data Storage, Security & Containers

- **PostgreSQL 18+ (ADR-0001, ADR-0010):**
  - Use `pgx/v5`, native `uuidv7()`, PostgreSQL 18 `RETURNING OLD, NEW` for atomic audit capture, per-service schemas, and least-privilege DB roles.
  - Enforce `sslmode=verify-full` / Microsoft Entra ID in staging/production. Do **not** enable `io_uring` on Azure Database for PostgreSQL Flexible Server.
  - Use parameterized queries exclusively (zero SQL string concatenation) and versioned SQL migrations.
  - Pair PostgreSQL state mutations with NATS event publishing via a transactional outbox table.
- **SQLite (Concept, ADR-0008):**
  - Prefer pure-Go SQLite (`modernc.org/sqlite`) to preserve `CGO_ENABLED=0` static builds unless CGo is explicitly justified.
  - Keep scientific reference DBs read-only for stateless horizontal scaling; use WAL + single-writer `StatefulSet` or read-only artifact storage for per-female egg reserves and per-ejaculation cohorts.
- **Authentication & Authorization (ADR-0010):**
  - Hash passwords with `golang.org/x/crypto/argon2` (Argon2id: ≥64 MiB memory, time 3, parallelism ≥2, 16-byte `crypto/rand` salt, 32-byte key), constant-time verification, and dummy hashing on unknown accounts.
  - Issue short-lived (10–15 min) Ed25519 (`EdDSA`) JWTs without PII; deliver refresh tokens in `HttpOnly`, `Secure`, `SameSite=Strict` cookies with rotation and reuse detection.
  - Enforce RBAC (`PLAYER`, `GAME_MASTER`) and resource/group ownership checks at both gateway and backend services.
- **Containers:** Build static `CGO_ENABLED=0` `-trimpath` binaries targeting non-root `distroless/static` images with read-only root filesystems and dropped Linux capabilities.

---

## 6. Linting, Static Analysis (Including Qodana) & Quality Gates

Always use the root `Makefile` (ADR-0008) to build, lint, scan, and test so local workflows match CI (ADR-0009). Scope any module target to a single service with `SERVICE=<service-name>`.

### 6.1 Required Linters & Analyzers

1. **`gofmt -s`** (`make fmt`, `make fmt-check`) — Enforces canonical Go formatting and simplification.
2. **`go vet`** (`make vet`) — Catches suspicious constructs, `printf` mismatches, and lock copying.
3. **`golangci-lint` v2** (`make lint`) — Primary Go meta-linter suite (staticcheck, errcheck, govet, revive, sloglint, etc.).
4. **JetBrains Qodana (`jetbrains/qodana-go`)** (`make qodana`) — **Additional static analysis linter** configured in root [`qodana.yaml`](qodana.yaml) using the `qodana.recommended` Go inspection profile:
   - Run locally via `make qodana` (or `qodana scan --fail-threshold 0`) when the Qodana CLI is installed, or via JetBrains GoLand (`Tools | Qodana`).
   - Complements `golangci-lint` with deep cross-file GoLand/IDE dataflow, nil-dereference, unused-symbol, concurrency, error-handling, and dependency-health inspections.
   - Generated Protobuf bindings (`pkg/proto/gen`), build binaries (`bin`), and coverage output (`.coverage`) are excluded in `qodana.yaml`.
   - Fix reported Qodana warnings at the root cause; do not suppress inspections with `//noinspection` unless there is a documented, unavoidable false positive.
5. **`govulncheck`** (`make vuln`) — Scans Go dependencies for reachable known vulnerabilities.
6. **`buf`** (`make proto-lint`, `make proto-breaking`) — Enforces Protobuf style and backward compatibility against `main`.
7. **`trivy`** (`make docker-scan`) — Scans built container images for `HIGH` and `CRITICAL` vulnerabilities.

### 6.2 Common Commands

```bash
# List all targets
make help

# Install core Go tools (golangci-lint v2, govulncheck, buf)
make tools

# Full standard CI quality gate (fmt-check, vet, lint, test-race, vuln)
make check

# Scoped quality gate for one microservice
make check SERVICE=user-admin

# Run JetBrains Qodana Go static analysis linter (uses root qodana.yaml)
make qodana

# Deterministic fixed-seed simulation cohort tests
make test-sim

# Containerized integration tests (PostgreSQL 18+ & NATS JetStream)
make test-integration

# Protobuf contract validation & code generation
make proto-lint
make proto-breaking
make proto-gen
```

---

## 7. Testing Strategy

- **Unit Tests (`make test`, `make test-race`):** Write table-driven Go unit tests covering biological formulas, genetics/recombination, validation, RBAC, and negative/edge cases. Always run with `-race -count=1`.
- **Deterministic Simulation Tests (`make test-sim`):** Guard statistical/cohort simulation tests with `//go:build simulation` and fixed PRNG seeds to verify Mendelian ratios, fertility bounds, health modifiers, and medication effects reproducibly.
- **Integration Tests (`make test-integration`):** Guard DB/broker tests with `//go:build integration` using Testcontainers (`postgres:18-alpine` and NATS JetStream).
- **Test Integrity:** Never weaken assertions, skip failing tests, or add fake stubs to make failing checks pass.

---

## 8. CI/CD & Documentation Hygiene

- Keep GitHub Actions workflows (`.github/workflows/`) aligned with `Makefile` targets, using least-privilege permissions, SHA-pinned third-party Actions, and Azure OIDC Workload Identity Federation (ADR-0009).
- When modifying architecture, contracts, or developer workflows, update the corresponding ADR in `docs/architecture/` or `docs/Concept.md` in the same change.
