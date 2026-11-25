# ADR-0006: Shared Configuration Library (`libs/config`)

- **Status:** Accepted
- **Date:** 2026-11-22
- **Deciders:** PrincessPink Architecture
- **Related Documents:** [`docs/Concept.md`](../Concept.md), [`README.md`](../../README.md), [`ADR-0001`](ADR-0001-minimum-postgresql-version.md), [`ADR-0003`](ADR-0003-shared-logging-library.md), [`ADR-0004`](ADR-0004-shared-opentelemetry-observability.md)

---

## Context

Every PrincessPink microservice runs across multiple environments—local developer machines, Docker Compose / `kind`, GitHub Actions CI, and **Azure Kubernetes Service (AKS)** (`dev`, `staging`, `prod`)—and integrates with shared platform infrastructure:

- **Azure Database for PostgreSQL Flexible Server (18+)** with Microsoft Entra ID / `SCRAM-SHA-256` authentication and default `worker` I/O ([ADR-0001](ADR-0001-minimum-postgresql-version.md)).
- **Azure Key Vault + Secrets Store CSI Driver**, which mounts database credentials, JWT signing keys, and TLS certificates as **files** inside AKS pods (Concept §6.2).
- **NATS JetStream**, **OpenTelemetry Collector**, **SQLite** database paths (read-only reference DBs, writable `StatefulSet` PVCs, Egg-Reserve and Ejaculation artifact storage), and build-time service versions (`VERSION`, `Commit`, `BuildDate`).

At the same time, Concept §4.4 requires a strict separation between **operational runtime configuration** (ports, timeouts, endpoints, secrets) and **versioned scientific simulation parameters** (e.g., luteal phase distributions, mutation rates, receptor-binding thresholds).

---

## Decision

PrincessPink establishes a shared Go module **`libs/config`** implementing a **12-Factor, environment-variable-first, strongly typed configuration loader** with native support for **file-mounted secrets** (Azure Key Vault CSI Driver), **fail-fast startup validation**, and reusable infrastructure config structs.

### 1. Configuration Loading & Precedence

- **Typed Struct Binding:** Each microservice defines a Go `Config` struct embedding relevant shared blocks from `libs/config` (e.g., `ServiceInfo`, `ServerConfig`, `PostgresConfig`, `NATSConfig`, `TelemetryConfig`, `LogConfig`, `SQLiteConfig`) annotated with explicit struct tags (`env:"..."`, `default:"..."`, `required:"true"`).
- **Environment-First with `*_FILE` Secret Indirection:** For any secret field (e.g., `DB_PASSWORD`, `JWT_SIGNING_KEY`, `NATS_TOKEN`), `libs/config` supports a paired `*_FILE` variable (e.g., `DB_PASSWORD_FILE=/mnt/secrets-store/db-password`). When `*_FILE` is set, `libs/config` reads and trims the mounted secret file from the AKS **Secrets Store CSI Driver** (or Docker secret) so secrets are never passed as plaintext Kubernetes environment variables.
- **No Implicit `.env` Loading in Production:** Local development may opt into a local `.env` file via `Makefile` / Docker Compose, but `libs/config` never silently reads workspace files in container builds.

### 2. Fail-Fast Validation & Safe Redaction

- **Startup Validation:** `config.Load[T](ctx)` validates all required fields, port ranges, URLs, positive timeouts, and enum values (`ENVIRONMENT`, `LOG_LEVEL`) before the service opens network listeners. Invalid configuration exits immediately with a clear, non-secret error message so Kubernetes surfaces misconfigurations during rollout.
- **PostgreSQL 18+ Guardrails ([ADR-0001](ADR-0001-minimum-postgresql-version.md)):** `PostgresConfig` enforces TLS (`sslmode=verify-full` in `staging`/`prod`), supports Microsoft Entra ID token auth alongside DSN credentials, and explicitly avoids `io_uring` settings incompatible with Azure Flexible Server.
- **Secret-Safe `slog.LogValuer`:** Sensitive fields use a `config.Secret` wrapper type whose `String()`, `MarshalJSON()`, and `LogValue()` methods always return `"[REDACTED]"`, preventing accidental secret leakage in startup logs or panic dumps.

### 3. Build Metadata & Scientific Parameter Boundary

- **Build-Time Version Metadata (`config.BuildInfo`):** Standardizes the `-ldflags`-injected variables (`Version`, `Commit`, `BuildDate`) populated by `Makefile` ([ADR-0008](ADR-0008-multi-module-makefile-build-automation.md)) and propagates them automatically to `libs/logging`, `libs/telemetry`, `/healthz`, and gRPC `service_version` fields.
- **Strict Separation from Scientific Parameters:** `libs/config` is strictly for **operational/deployment settings**. Biological and genetic model constants (e.g., crossover rates, menarche distributions, actuarial life tables, receptor-binding matrices) are **not** stored as environment variables; they live as versioned scientific reference datasets (read-only SQLite reference DBs or versioned `GROUP.simulation_config` JSONB payloads in PostgreSQL 18+) so simulation runs remain scientifically reproducible and auditable (Concept §4.4).

---

## Options Considered

| Option | Description | Evaluation |
| :--- | :--- | :--- |
| **1. Typed Struct-Tag Env + File-Secret Loader (`libs/config`)** | Lightweight Go generic `config.Load[T]()` using typed structs, `*_FILE` secret resolution, `config.Secret` redaction, and fail-fast validation (built on stdlib or a minimal zero-bloat parser like `caarlos0/env`). | **Selected.** Minimal dependency footprint, idiomatic Kubernetes/12-Factor workflow, native Azure Key Vault CSI file support, compile-time type safety, and zero hidden global state. |
| **2. `github.com/spf13/viper`** | Feature-rich configuration framework supporting YAML/TOML/JSON files, flags, env vars, and remote watchers. | **Rejected.** Pulls a large transitive dependency tree into every `distroless/static` microservice, encourages mutable global state (`viper.Get*`), and adds unnecessary file-format complexity for Kubernetes workloads. |
| **3. Raw `os.Getenv` in Each Microservice** | Parse and validate environment variables manually in every service's `main.go`. | **Rejected.** Duplicates parsing, default handling, secret file loading, and validation across 25+ microservices; leads to inconsistent variable names and silent misconfigurations. |
| **4. Centralized Dynamic Config Server (Consul / etcd)** | Fetch runtime configuration over the network from a dedicated config service. | **Rejected.** Adds an extra stateful failure domain on AKS when Kubernetes ConfigMaps, Azure Key Vault CSI Driver, and immutable rolling deployments already solve operational configuration cleanly. |

---

## Rationale & Alignment with PrincessPink Requirements

1. **Azure Key Vault & Zero-Trust Alignment (Concept §6.2 & §6.3):**
   First-class `*_FILE` secret loading integrates cleanly with AKS's Azure Key Vault Secrets Store CSI Driver and read-only root filesystems without exposing secrets in `kubectl describe pod` or process environment dumps.
2. **Low Boilerplate Across 25+ Microservices (Concept §8):**
   Reusable embedded config blocks (`ServerConfig`, `PostgresConfig`, `NATSConfig`, `TelemetryConfig`, `SQLiteConfig`) keep new `attr-*` and `sim-*` services concise and uniformly configurable.
3. **Scientific Reproducibility (Concept §4.4):**
   Drawing an explicit boundary between operational config (`libs/config`) and versioned scientific datasets ensures that deployment tuning (e.g., timeouts, log levels) cannot silently alter biological simulation outcomes.

---

## Consequences

### Positive
- Every microservice shares identical environment variable naming conventions, startup validation behavior, and build-version metadata.
- Secrets loaded from Azure Key Vault CSI volumes are protected from accidental logging via `config.Secret`.
- Minimal dependency footprint keeps `govulncheck` clean and container images small.

### Trade-offs & Operational Notes
- **Restart-on-Config-Change Model:** Operational configuration is loaded once at startup (immutable for the pod's lifetime); changing a Kubernetes ConfigMap or rotated secret triggers a standard rolling pod restart (or, for short-lived Entra ID DB tokens / TLS certs, uses dedicated credential refresh hooks rather than mutating global config).
- **Documentation Discipline:** Each service should document its accepted environment variables (or support a `--print-config-schema` / generated reference) so Helm/Kustomize manifests stay synchronized with struct tags.
