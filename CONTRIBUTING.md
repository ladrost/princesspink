# Contributing to PrincessPink

Thank you for your interest in contributing to **PrincessPink**! PrincessPink is an open-source, scientific, population-level simulation of human reproduction and generational lineage presented through a pen-and-paper RPG interface, written exclusively in **Go**.

Whether you are proposing a scientific model refinement, writing a shared library or microservice, improving documentation, or reporting a bug, this guide explains how to propose changes, set up your local Go environment, run tests and linters, and adhere to our code review standards.

---

## Table of Contents

- [Code of Conduct & Content Safety Policy](#code-of-conduct--content-safety-policy)
- [Before You Start](#before-you-start)
- [How to Propose Changes](#how-to-propose-changes)
  - [Reporting Bugs](#reporting-bugs)
  - [Reporting Security Vulnerabilities](#reporting-security-vulnerabilities)
  - [Proposing Features & Scientific Models](#proposing-features--scientific-models)
  - [Proposing Architectural Changes (ADRs)](#proposing-architectural-changes-adrs)
- [Setting Up Your Local Development Environment](#setting-up-your-local-development-environment)
  - [Prerequisites](#prerequisites)
  - [Clone & Fork Workflow](#clone--fork-workflow)
  - [Installing Developer Tooling](#installing-developer-tooling)
  - [Working with the Go Multi-Module Workspace (`go.work`)](#working-with-the-go-multi-module-workspace-gowork)
  - [Scaffolding a New Microservice](#scaffolding-a-new-microservice)
  - [Local Configuration & Secrets](#local-configuration--secrets)
- [Running Tests, Linters & Quality Gates](#running-tests-linters--quality-gates)
  - [Quick Reference (`Makefile`)](#quick-reference-makefile)
  - [Layered Testing Strategy](#layered-testing-strategy)
  - [Protobuf Contracts (`libs/proto`)](#protobuf-contracts-libsproto)
  - [Static Analysis & Security Scans](#static-analysis--security-scans)
- [Go Coding Standards & Architectural Guidelines](#go-coding-standards--architectural-guidelines)
  - [Idiomatic Go & Pure-Go Discipline](#idiomatic-go--pure-go-discipline)
  - [Context, Concurrency & Error Handling](#context-concurrency--error-handling)
  - [Mandatory Shared Platform Libraries (`libs/`)](#mandatory-shared-platform-libraries-libs)
  - [Domain & Scientific Modeling Invariants](#domain--scientific-modeling-invariants)
  - [AI-Assisted Contributions](#ai-assisted-contributions)
- [Pull Request & Code Review Standards](#pull-request--code-review-standards)
  - [Commit & Branch Guidelines](#commit--branch-guidelines)
  - [Pull Request Checklist](#pull-request-checklist)
  - [What Reviewers Look For](#what-reviewers-look-for)
  - [Review Etiquette](#review-etiquette)
- [Independent Microservice Versioning & Releases](#independent-microservice-versioning--releases)
- [License](#license)

---

## Code of Conduct & Content Safety Policy

1. **Code of Conduct:** All contributors and participants must uphold our [Contributor Covenant Code of Conduct (v2.0)](CODE_OF_CONDUCT.md) in all project spaces.
2. **Non-Negotiable Content & Safety Policy:** Every contribution—code, templates, API schemas, seed data, tests, and documentation—must strictly enforce PrincessPink's **zero-violence, zero-nudity** principles (see [`docs/Concept.md`](docs/Concept.md#13-non-negotiable-content--safety-principles)):
   - **Zero violence & zero gore:** No combat mechanics, weapons, injury graphics, or violent narratives. Characters live and pass away strictly through natural biological lifecycles.
   - **Zero nudity & zero explicit content:** Human reproduction is modeled purely through abstract scientific data, clinical parameters, biological state transitions, and tabletop-style stats/events—never explicit text, imagery, or adult themes.
   - **Safe-by-design visuals:** Character visuals are strictly limited to deterministic, stylized comic-art face portraits (head and shoulders). Do not introduce unmoderated free-form image uploads; keep text and attributes schema-driven.

---

## Before You Start

PrincessPink is currently in **Phase 0 (Architectural Foundation)**, transitioning into **Phase 1 (Platform Foundation)** as described in [`docs/Concept.md`](docs/Concept.md#9-phased-implementation-roadmap). Before opening a pull request, familiarize yourself with the project's authoritative documentation:

- **[`README.md`](README.md)** — Project overview, architecture summary, and roadmap.
- **[`docs/Concept.md`](docs/Concept.md)** — Domain model, character lifecycle, genetics/simulation rules, microservice catalog, persistence strategy, and AKS deployment design.
- **[`docs/architecture/`](docs/architecture/)** — Architecture Decision Records ([ADR-0001](docs/architecture/ADR-0001-minimum-postgresql-version.md) through [ADR-0011](docs/architecture/ADR-0011-go-as-sole-programming-language.md)).
- **[`AGENTS.md`](AGENTS.md)** — Coding standards, domain invariants, linter policies, and shared library rules (applies to both human contributors and AI coding agents).

---

## How to Propose Changes

Before starting substantial work, search existing [GitHub Issues](https://github.com/ladrost/princesspink/issues) and [Pull Requests](https://github.com/ladrost/princesspink/pulls) to avoid duplicate effort and align on design early.

### Reporting Bugs

Open a GitHub issue with:

- A clear, concise title and description of the problem.
- Minimal steps to reproduce, including expected vs. actual behavior.
- Affected module/service name and its `VERSION` (or Git commit SHA).
- Environment details (`go version`, OS/architecture, Docker/PostgreSQL versions if applicable).
- Relevant logs, stack traces, or failing test output—**redacted of any secrets, tokens, or PII**.

### Reporting Security Vulnerabilities

**Do not open a public issue or pull request for security vulnerabilities.** Follow the private reporting process in [`SECURITY.md`](SECURITY.md) using GitHub Private Vulnerability Reporting.

### Proposing Features & Scientific Models

Open a GitHub issue before submitting large pull requests. Please describe:

- The motivation and how the proposal aligns with [`docs/Concept.md`](docs/Concept.md) and the phased roadmap.
- Confirmation of compliance with the **zero-violence, zero-nudity** policy.
- For biological or statistical models: scientific rationale, expected statistical invariants (to be verified with fixed-seed `//go:build simulation` tests), and how parameters are stored in versioned read-only SQLite reference datasets or `GROUP.simulation_config` JSONB rather than hardcoded magic numbers.
- Impact on internal gRPC/Protobuf contracts (`libs/proto`) or database schemas.

### Proposing Architectural Changes (ADRs)

Significant architectural decisions—such as introducing a new shared library, changing infrastructure baselines, altering inter-service communication patterns, or proposing an exception to an existing decision (including the Go-only policy in [ADR-0011](docs/architecture/ADR-0011-go-as-sole-programming-language.md))—must be discussed in an issue and documented as an **Architecture Decision Record (ADR)** under `docs/architecture/`:

1. Follow the existing sequential naming convention: `docs/architecture/ADR-XXXX-<short-kebab-title>.md`.
2. Mirror the structure of existing ADRs (`Status`, `Date`, `Deciders`, `Related Documents`, `Context`, `Decision`, `Options Considered`, `Rationale & Alignment with PrincessPink Requirements`, `Consequences`).
3. Update cross-references in [`README.md`](README.md), [`docs/Concept.md`](docs/Concept.md), and [`AGENTS.md`](AGENTS.md) in the same pull request.

---

## Setting Up Your Local Development Environment

### Prerequisites

#### Required

- **[Go](https://go.dev/) 1.27+** — Root [`go.work`](go.work) targets `go 1.27` with `toolchain go1.27.4`. Go's toolchain management will automatically honor the declared toolchain version. Per [ADR-0011](docs/architecture/ADR-0011-go-as-sole-programming-language.md), Go is the **sole programming language** for PrincessPink.
- **[Git](https://git-scm.com/)**
- **GNU `make` & Bash** — The root [`Makefile`](Makefile) uses `bash` (`-euo pipefail`). Windows contributors should use **WSL2** or a Linux Dev Container ([ADR-0008](docs/architecture/ADR-0008-multi-module-makefile-build-automation.md)).

#### Optional (Needed for Phase 1+ Integration, Containers & Extended Static Analysis)

- **[Docker](https://www.docker.com/) (with Docker Compose)** — Required for Testcontainers integration tests (`make test-integration`), container image builds (`make docker-build`), and local stacks (`make dev-up` / `make dev-down`).
- **[PostgreSQL](https://www.postgresql.org/) 18+** — Minimum supported major version ([ADR-0001](docs/architecture/ADR-0001-minimum-postgresql-version.md)), required for native `uuidv7()` and `RETURNING OLD, NEW`. Using Docker (`postgres:18-alpine`) is recommended for local/CI parity. Do not enable `io_uring` in PostgreSQL configuration (unsupported on Azure Database for PostgreSQL Flexible Server).
- **[JetBrains Qodana CLI](https://www.jetbrains.com/help/qodana/qodana-cli.html)** (or JetBrains GoLand `Tools | Qodana`) — Runs `jetbrains/qodana-go` using root [`qodana.yaml`](qodana.yaml) via `make qodana`.
- **[Trivy](https://trivy.dev/)** — Container vulnerability scanning (`make docker-scan`).
- **`kubectl` / `kind` / `k3d`** — Local Kubernetes cluster validation for AKS manifests.

### Clone & Fork Workflow

1. Fork [`ladrost/princesspink`](https://github.com/ladrost/princesspink) on GitHub.
2. Clone your fork and configure the `upstream` remote:

   ```bash
   git clone https://github.com/<your-username>/princesspink.git
   cd princesspink
   git remote add upstream https://github.com/ladrost/princesspink.git
   ```

3. Keep your local `main` branch synchronized before creating a feature branch:

   ```bash
   git fetch upstream
   git checkout main
   git merge --ff-only upstream/main
   git checkout -b <issue-number>-<short-description>
   ```

### Installing Developer Tooling

Inspect all available build, test, lint, and release targets:

```bash
make help
```

Install the core Go developer tools (`govulncheck`, `golangci-lint` v2, and `buf`):

```bash
make tools
```

Ensure `$(go env GOPATH)/bin` is on your `PATH` so `golangci-lint`, `govulncheck`, and `buf` are discoverable by `make`.

### Working with the Go Multi-Module Workspace (`go.work`)

PrincessPink uses a **Go multi-module workspace** defined in root [`go.work`](go.work) with **no root `go.mod`**:

- `libs/<module>/` — Shared platform libraries (`logging`, `telemetry`, `proto`, `config`, `uuid`). Keep them small, well-tested, and free of service-specific business logic.
- `services/<service-name>/` — Independently buildable, deployable, and semantically versioned Go microservices.

Whenever you add a new module or change dependencies across modules:

```bash
# Register all libs/ and services/ modules in go.work
make work-use

# Synchronize workspace build list
make work-sync

# Download and verify module checksums
make deps

# Tidy go.mod and go.sum across all modules (or one service)
make tidy
make tidy SERVICE=user-admin
```

> **Tip (`SERVICE=<name>` scoping):** Most `Makefile` targets run across all workspace modules by default and accept `SERVICE=<service-name>` to scope execution to a single microservice for fast inner-loop development (for example, `make test-race SERVICE=user-admin` or `make build SERVICE=sim-gamete-surface`).

### Scaffolding a New Microservice

Every new microservice under `services/<service-name>/` must follow the workspace layout so it automatically integrates with the root [`Makefile`](Makefile) and CI workflows ([ADR-0008](docs/architecture/ADR-0008-multi-module-makefile-build-automation.md), [ADR-0009](docs/architecture/ADR-0009-github-actions-ci-cd.md)):

```text
services/<service-name>/
├── go.mod                      # Standalone Go module (go 1.27)
├── VERSION                     # Independent SemVer file (e.g., 0.1.0)
├── Dockerfile                  # Multi-stage CGO_ENABLED=0 build -> non-root distroless/static
├── cmd/<service-name>/main.go  # Entry point (or cmd/server/main.go) embedding Version/Commit/BuildDate
└── internal/                   # Service-private domain, handler, storage, and adapter packages
```

After creating the module, run `make work-use && make work-sync` to register it in `go.work`.

### Local Configuration & Secrets

- Microservices load operational settings through `libs/config` (`config.Load[T](ctx)`) with fail-fast validation and `*_FILE` secret indirection ([ADR-0006](docs/architecture/ADR-0006-shared-configuration-library.md)).
- Never commit `.env` files (already ignored in [`.gitignore`](.gitignore)), private keys, certificates, or real credentials.
- Use synthetic test credentials and dummy data in unit and integration tests.

---

## Running Tests, Linters & Quality Gates

Always use the root [`Makefile`](Makefile) targets so your local validation matches GitHub Actions CI ([ADR-0008](docs/architecture/ADR-0008-multi-module-makefile-build-automation.md), [ADR-0009](docs/architecture/ADR-0009-github-actions-ci-cd.md)).

### Quick Reference (`Makefile`)

| Command | Description |
| :--- | :--- |
| `make check` | Full CI quality gate: `fmt-check`, `vet`, `lint`, `test-race`, and `vuln`. |
| `make check SERVICE=<name>` | Run the full CI quality gate scoped to a single microservice. |
| `make fmt` / `make fmt-check` | Format Go files with `gofmt -s -w` / verify formatting without modifying files. |
| `make vet` | Run `go vet ./...` across target modules. |
| `make lint` | Run `golangci-lint` (v2) across target modules. |
| `make qodana` | Run JetBrains Qodana Go static analysis (`qodana.yaml`, `--fail-threshold 0`). |
| `make vuln` | Run `govulncheck ./...` to detect reachable known Go vulnerabilities. |
| `make test` | Run standard Go unit tests (`go test ./...`). |
| `make test-race` | Run tests with the race detector and caching disabled (`go test -race -count=1 ./...`). |
| `make test-cover` | Generate atomic coverage profiles and HTML reports in `.coverage/`. |
| `make test-sim` | Run deterministic fixed-seed simulation cohort tests (`-race -count=1 -tags=simulation`). |
| `make test-integration` | Run containerized Testcontainers integration tests (`-race -count=1 -tags=integration`). |
| `make bench` | Run Go benchmarks with allocation metrics (`-bench=. -benchmem`). |
| `make build` / `make build-linux` | Build binaries into `bin/` (`CGO_ENABLED=0`, `-trimpath`, embedded `-ldflags` version metadata). |
| `make proto-lint` / `make proto-breaking` / `make proto-gen` | Validate and generate gRPC/Protobuf code under `libs/proto/` using `buf`. |
| `make docker-build` / `make docker-scan` | Build versioned service images and scan for `HIGH`/`CRITICAL` CVEs with Trivy. |
| `make clean` | Remove build binaries (`bin/`) and coverage artifacts (`.coverage/`). |

*(During Phase 0—while no Go modules exist under `libs/` or `services/`—workspace `Makefile` targets exit cleanly with an informational message.)*

### Layered Testing Strategy

PrincessPink uses a layered testing model ([`docs/Concept.md`](docs/Concept.md#72-testing-strategy)):

1. **Unit Tests (`make test`, `make test-race`):**
   - Write idiomatic, table-driven Go tests (`t.Run`) covering core logic, biological formulas, validation, RBAC authorization, and negative/edge cases.
   - Always run with the race detector (`make test-race`) before opening a PR.
   - Use `t.Parallel()` where tests are independent, and avoid sleeping on wall-clock timers (inject clocks/tickers where needed).
2. **Deterministic Simulation Tests (`make test-sim`):**
   - Guard statistical and cohort tests with `//go:build simulation`.
   - Use explicit fixed PRNG seeds (`math/rand/v2`) derived deterministically so Mendelian inheritance ratios (ABO/RhD, ~50/50 sex ratio), fertility bounds, health trajectories, and medication modifiers are 100% reproducible in CI.
3. **Integration Tests (`make test-integration`):**
   - Guard database and broker tests with `//go:build integration`.
   - Use Testcontainers with **`postgres:18-alpine`** ([ADR-0001](docs/architecture/ADR-0001-minimum-postgresql-version.md)) and **NATS JetStream** to verify migrations, `uuidv7()`, `RETURNING OLD, NEW` audit trails, RBAC boundaries, and transactional outbox event flows.
4. **Benchmarks (`make bench`):**
   - Add benchmarks for allocation-sensitive paths such as gamete generation (`sim-egg-reserve`, `sim-ejaculation`), sperm-race scoring (`sim-sperm-race`), and high-fan-out sheet aggregation (`sheet-aggregator`).

**Test Integrity Policy:** Never disable, skip, or weaken assertions on failing tests, and never introduce fake stubs to bypass failures. Investigate and fix the root cause.

### Protobuf Contracts (`libs/proto`)

All internal synchronous gRPC RPCs and NATS JetStream event schemas live under `libs/proto/` and are governed by `buf` ([ADR-0005](docs/architecture/ADR-0005-shared-grpc-protobuf-contracts.md)):

- Evolve `v1` contracts **additively only**. Never renumber, retype, or remove existing fields without reserving names/numbers; introduce `v2` for breaking changes.
- Whenever you modify `.proto` files, run:

  ```bash
  make proto-lint
  make proto-breaking
  make proto-gen
  ```

- Commit the regenerated Go files under `libs/proto/gen/go/`. CI rejects pull requests with uncommitted or stale generated bindings.

### Static Analysis & Security Scans

Before requesting review, run:

```bash
make check
```

If you have the Qodana CLI or JetBrains GoLand installed, also run:

```bash
make qodana
```

Fix warnings reported by `golangci-lint`, `go vet`, and Qodana at their root cause. Do not add `//nolint` or `//noinspection` directives unless there is a documented, unavoidable false positive.

---

## Go Coding Standards & Architectural Guidelines

### Idiomatic Go & Pure-Go Discipline

- Follow [Effective Go](https://go.dev/doc/effective_go) and [Go Code Review Comments](https://go.dev/wiki/CodeReviewComments).
- Format all Go source files with `gofmt -s` (`make fmt`). Group imports cleanly: standard library, third-party packages, and workspace/internal packages.
- Document every exported type, function, method, and constant with a Go doc comment starting with the symbol name.
- Prefer simple, readable control flow with early returns over deep nesting; avoid premature abstraction and unnecessary reflection.
- Define small, focused interfaces **at the consumer side** rather than preemptively in implementation packages.
- Avoid package-level mutable globals; inject dependencies explicitly through `New...` constructors.
- Keep `internal/` packages private to their owning module.
- **Pure-Go Builds (`CGO_ENABLED=0`):** Per [ADR-0011](docs/architecture/ADR-0011-go-as-sole-programming-language.md), avoid dependencies that require CGo (for SQLite, prefer pure-Go `modernc.org/sqlite`) so every service cross-compiles cleanly to static `linux/amd64` and `linux/arm64` binaries for `distroless/static` containers.

### Context, Concurrency & Error Handling

- Pass `context.Context` as the first parameter of every function performing I/O, RPC, database access, messaging, or logging. Never store `context.Context` in structs.
- Enforce explicit timeouts/deadlines on all outbound HTTP, gRPC, database, and NATS calls.
- Use `golang.org/x/sync/errgroup` (`errgroup.WithContext`) for bounded parallel fan-out (such as `sheet-aggregator`), with graceful degradation for non-critical attributes.
- Bound CPU/memory-intensive operations (e.g., `Argon2id` password hashing) with explicit semaphores or worker pools.
- Ensure every goroutine has a deterministic cancellation path and close channels from the sender side only.
- Always close resources (`rows.Close()`, `resp.Body.Close()`, SQLite handles, files) and check close errors on write paths.
- Never silently discard errors (`_ = ...` is disallowed unless justified with a comment for benign cleanup).
- Wrap errors with operation context via `fmt.Errorf("operation: %w", err)` so callers can inspect chains with `errors.Is` and `errors.As`.
- Map domain errors cleanly to gRPC status codes or HTTP status codes at service boundaries without exposing internal SQL details, DSNs, secrets, or stack traces.

### Mandatory Shared Platform Libraries (`libs/`)

Use the shared platform libraries defined in our ADRs rather than introducing competing third-party frameworks:

| Library | ADR | Key Requirements |
| :--- | :--- | :--- |
| **`libs/logging`** | [ADR-0003](docs/architecture/ADR-0003-shared-logging-library.md) | Stdlib `log/slog` JSON logging only (no Zap/Zerolog). Always call `*Context` methods (`InfoContext`, `WarnContext`, `ErrorContext`). Never log PII, emails, credentials, tokens, DSNs, or raw chat bodies—log non-PII `user_uuid`. |
| **`libs/telemetry`** | [ADR-0004](docs/architecture/ADR-0004-shared-opentelemetry-observability.md) | Initialize once in `main()` via `telemetry.Init(ctx, cfg)` with bounded `Shutdown(ctx)`. Propagate W3C Trace Context across Gin, gRPC, and NATS. Name metrics `princesspink_<domain>_<metric>_<unit>` and **never** use unbounded IDs (`character_uuid`, `user_uuid`, `group_id`, `ejaculation_id`) as Prometheus labels. Expose `/healthz`, `/readyz`, and internal-only `/metrics`. |
| **`libs/proto`** | [ADR-0005](docs/architecture/ADR-0005-shared-grpc-protobuf-contracts.md) | `buf`-governed contracts, committed generated Go code, `grpcutil` factories, and `grpc.health.v1.Health` on every gRPC server. |
| **`libs/config`** | [ADR-0006](docs/architecture/ADR-0006-shared-configuration-library.md) | Typed `config.Load[T](ctx)` with fail-fast validation, `*_FILE` secret indirection, and `config.Secret` redaction (no Viper or scattered `os.Getenv`). Never store scientific constants in env vars. |
| **`libs/uuid`** | [ADR-0007](docs/architecture/ADR-0007-shared-uuid-utilities.md) | RFC 9562 **UUIDv7** for all domain, event, outbox, and correlation IDs. Reject nil/malformed UUIDs at boundaries; build SQLite filenames strictly from validated canonical UUIDs. **Never** use UUIDs as security secrets—use `crypto/rand` (≥ 256 bits). |

### Domain & Scientific Modeling Invariants

- **Immutable Identity, Life History & Reappearance:** Characters receive an immutable `UUIDv7` at conception (`CONCEIVED` → `GESTATING` → `ALIVE` → `DECEASED`, including natural prenatal loss `CONCEIVED`/`GESTATING` → `DECEASED` via `sim-prenatal-loss`, with `date_of_birth` remaining null and `date_of_death` recorded) or at parentless character generation (`sim-character-generator` entering directly in `ALIVE` with `mother_uuid = null`, `father_uuid = null`, immutable `creation_source`, age-consistent biological bootstrapping, and conditional mortality `date_of_death > T_sim`). Diploid genome, biological `gender`, Mendelian ABO + RhD `blood_type`, and parent links are immutable. All dynamic attribute changes across a character's life are stored immutably in append-only `CHARACTER_ATTRIBUTE_HISTORY` (`REVOKE UPDATE, DELETE`) so characters can reappear in new Groups running during `[date_of_birth, date_of_death)`. Once a character's life has been simulated (`life_simulation_status == COMPLETED`), stored attributes can never change—already-simulated (`REPLAY_IMMUTABLE`) characters may only participate in new simulations and have additional children, with females strictly gated by biological-window validation (living & projected birth `< date_of_death`, post-ovulation / pre-climacterium, non-overlapping with recorded pregnancies & recovery periods including forward lookahead, stored cycle/contraception state, and an unfertilized oocyte in her retained Egg-Reserve DB).
- **Deterministic Stochasticity:** Seed every probabilistic biological step explicitly from `(group_id, sim_tick, event_id)` using `math/rand/v2`, store scientific parameters in versioned read-only SQLite reference datasets or versioned `GROUP.simulation_config` JSONB, and stamp `service_version` on outputs and events.
- **Database & Event Atomicity:** Use parameterized queries exclusively with `pgx/v5` (zero SQL string concatenation), versioned SQL migrations, PostgreSQL 18 `RETURNING OLD, NEW` for atomic audit logs and race-free `NPC_OWNERSHIP_CLAIM` transfers, per-mother locking / temporal non-overlap checks for reappearance pregnancies, and a transactional outbox paired with idempotent NATS JetStream consumers.
- **Authorization, Activation Authority & Auditability:** Enforce RBAC (`PLAYER` / `GAME_MASTER`) and resource/group ownership checks at both gateway and backend services ([ADR-0010](docs/architecture/ADR-0010-user-admin-auth-rbac-and-group-management.md)). Only the owning Player decides whether an owned character becomes active again; GMs may activate only unowned characters (`owner_user_id IS NULL`) as NPCs; Players may only enter a Group with a character alive during the Group's simulated period (`date_of_birth <= T_sim < date_of_death`), and when lacking one must either generate a new character (`PLAYER_GROUP_JOIN`) or claim ownership of an eligible unowned NPC (`NPC_OWNERSHIP_CLAIM`). Bound and audit-log all `LIVE_PRIMARY` GM adjustments and strictly reject mutations on `REPLAY_IMMUTABLE` characters.

### AI-Assisted Contributions

Contributors who use AI coding assistants (such as Junie, GitHub Copilot, or similar tools) are welcome, provided they:

1. Direct the assistant to follow [`AGENTS.md`](AGENTS.md) and the project's ADRs.
2. Thoroughly review, understand, and verify every line of generated code, documentation, and tests before opening a PR.
3. Run all relevant quality gates (`make check`, `make test-sim`, `make proto-lint`, etc.) locally and take full responsibility for the accuracy, security, and licensing compliance of the submitted changes.

---

## Pull Request & Code Review Standards

### Commit & Branch Guidelines

- Use clear, descriptive branch names (e.g., `42-add-user-admin-auth`, `feat/libs-logging`, `fix/sim-clock-pause`, `docs/adr-0012`).
- Write concise, meaningful commit messages in the imperative mood explaining *what* changed and *why*. Reference related issues (e.g., `Closes #42` or `Refs #42`).
- Keep pull requests focused on a single logical change; split unrelated refactors into separate PRs.

### Pull Request Checklist

Before marking a PR ready for review, confirm that:

- [ ] The PR links to the relevant GitHub issue(s) or ADR(s) and clearly explains the motivation, approach, and verification performed.
- [ ] All changes strictly uphold the **zero-violence, zero-nudity** Content & Safety Policy.
- [ ] `make check` passes cleanly (formatting, `go vet`, `golangci-lint`, `-race` unit tests, and `govulncheck`).
- [ ] Additional applicable checks pass (`make test-sim`, `make test-integration`, `make proto-lint`, `make proto-breaking`, `make qodana`, `make docker-scan`).
- [ ] Regenerated files under `libs/proto/gen/go/` are committed if `.proto` definitions changed.
- [ ] Unit, edge-case, deterministic simulation, or integration tests are added/updated proportionally to the change.
- [ ] Documentation (`docs/Concept.md`, relevant ADRs in `docs/architecture/`, or `README.md`) is updated if architecture, contracts, or developer workflows changed.
- [ ] No secrets, `.env` files, build binaries (`bin/`), or coverage reports (`.coverage/`) are committed.

### What Reviewers Look For

Pull requests are reviewed against the following criteria:

1. **Domain & Policy Alignment:** Adherence to [`docs/Concept.md`](docs/Concept.md), ADRs, biological/RPG domain invariants, and the Content & Safety Policy.
2. **Go Quality & Maintainability:** Idiomatic Go style, clean API boundaries, proper error wrapping, race-free concurrency, context propagation, and bounded resource usage.
3. **Security & Privacy:** Parameterized SQL, defense-in-depth RBAC/group ownership enforcement, safe UUID validation (especially for SQLite artifact paths), zero PII/secret leakage in logs/errors/metrics, and pure-Go static container compatibility.
4. **Contract & Observability Hygiene:** Backward-compatible Protobuf evolution, structured `slog` context logging, OpenTelemetry trace propagation, and low-cardinality Prometheus metric labels.
5. **Testing & Reproducibility:** Meaningful table-driven tests covering negative/edge cases, deterministic fixed-seed simulation tests where applicable, and zero flaky tests.

### Review Etiquette

- **For Authors:** Keep PRs reviewable in size, provide context for non-obvious design choices, respond constructively to every review comment, and push follow-up commits clearly during review.
- **For Reviewers:** Critique the code, not the author. Explain *why* a change is requested, distinguish blocking issues (correctness, security, policy, breaking contracts) from optional suggestions (`nit:`), and acknowledge good work.

---

## Independent Microservice Versioning & Releases

Each microservice under `services/<service-name>/` maintains its own Semantic Version (`MAJOR.MINOR.PATCH`) in `services/<service-name>/VERSION` rather than sharing a single platform version ([`docs/Concept.md`](docs/Concept.md#35-independent-microservice-versioning), [ADR-0009](docs/architecture/ADR-0009-github-actions-ci-cd.md)):

- Do not create release Git tags (`<service>/v<VERSION>`) in feature PRs—maintainers create annotated scoped tags via `make tag SERVICE=<service-name>` after merge, which triggers `.github/workflows/release-service.yml` to build, Trivy-scan, and publish multi-arch container images to ACR.
- Inspect current service versions anytime with `make versions`.

---

## License

By contributing to PrincessPink, you agree that your contributions will be licensed under the project's **[BSD 3-Clause License](LICENSE)**.
