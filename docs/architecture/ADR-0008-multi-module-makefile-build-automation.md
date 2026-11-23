# ADR-0008: Multi-Module Developer Workflow & Build Automation (`Makefile`)

- **Status:** Accepted
- **Date:** 2026-11-22
- **Deciders:** PrincessPink Architecture
- **Related Documents:** [`docs/Concept.md`](../Concept.md), [`README.md`](../../README.md), [`Makefile`](../../Makefile), [`go.work`](../../go.work), [`ADR-0005`](ADR-0005-shared-grpc-protobuf-contracts.md), [`ADR-0006`](ADR-0006-shared-configuration-library.md), [`ADR-0009`](ADR-0009-github-actions-ci-cd.md)

---

## Context

PrincessPink is organized as a **Go 1.27+ multi-module workspace (`go.work`, `toolchain go1.27.4`)** containing shared libraries under `pkg/` and 25+ independently versioned microservices under `services/` (Concept §3.3 & §3.5). Developers and CI pipelines need a single, discoverable, reproducible interface to:

1. Manage Go workspace modules (`go work use`, `go work sync`, `go mod tidy`, `go mod verify`) across `pkg/` and `services/`.
2. Build static Linux binaries (`CGO_ENABLED=0`) with per-service semantic versions read from `services/<service>/VERSION` and injected via `-ldflags`.
3. Run layered test suites: unit tests, race-detector tests, coverage reports, deterministic fixed-seed simulation tests (`-tags=simulation`), containerized integration tests (`-tags=integration`), and benchmarks.
4. Enforce code quality, Protobuf contract checks (`buf`), and vulnerability scanning (`golangci-lint`, `govulncheck`, Trivy).
5. Support both **workspace-wide execution** and **fast single-service scoping** (`SERVICE=<service-name>`) without forcing contributors to install bespoke build frameworks.

---

## Decision

PrincessPink adopts a single root **GNU `Makefile`** as the canonical developer and CI build-automation entry point for the entire Go multi-module workspace.

### 1. Workspace Discovery & Single-Service Scoping

- **Automatic Module Discovery:** The `Makefile` dynamically discovers all Go modules under `pkg/*/go.mod` (`PKG_MODULES`) and `services/*/go.mod` (`SERVICE_MODULES`), gracefully handling the Phase 0 state when no modules exist yet.
- **Optional Scoping via `SERVICE=<name>`:** Every build, test, lint, version, and container target runs across the full workspace by default, or narrows to a single microservice when `SERVICE=<service-name>` is supplied (e.g., `make test-race SERVICE=user-admin`, `make build SERVICE=sim-gamete-surface`).
- **Strict Shell Execution:** Uses `SHELL := /usr/bin/env bash` with `.SHELLFLAGS := -euo pipefail -c` so subshell errors and unset variables fail immediately rather than silently continuing.
- **Self-Documenting CLI:** Defaults to `make help`, parsing `##@` section headers and `##` target descriptions to display usage and concrete examples.

### 2. Standardized Target Categories

| Category | Targets | Purpose |
| :--- | :--- | :--- |
| **Workspace & Dependencies** | `work-use`, `work-sync`, `deps`, `tidy` | Synchronize `go.work`, download/verify module checksums, and tidy `go.mod` files. |
| **Build** | `build`, `build-linux` | Compile binaries into `bin/` with `-trimpath`, `CGO_ENABLED=0`, and `-ldflags` embedding `Version` (from `services/<svc>/VERSION`), `Commit`, and `BuildDate`. |
| **Testing** | `test`, `test-race`, `test-cover`, `test-sim`, `test-integration`, `bench` | Execute unit tests, race detection (`-race -count=1`), atomic coverage HTML reports, fixed-seed simulation cohorts (`-tags=simulation`), Testcontainers integration suites (`-tags=integration`), and benchmarks. |
| **Code Quality & Security** | `fmt`, `fmt-check`, `vet`, `lint`, `vuln`, `check` | Format with `gofmt -s`, run `go vet`, `golangci-lint`, `govulncheck`, and aggregate them into a single local/CI quality gate (`make check`). |
| **Contracts & Generation** | `generate`, `proto-lint`, `proto-breaking`, `proto-gen` | Run `go generate` and `buf` Protobuf lint, breaking-change detection against `main`, and Go code generation ([ADR-0005](ADR-0005-shared-grpc-protobuf-contracts.md)). |
| **Independent Versioning** | `versions`, `tag` | Display all services and their `VERSION` files; create annotated scoped Git tags (`<service>/v<VERSION>`) per Concept §3.5. |
| **Containers & Local Stack** | `docker-build`, `docker-buildx`, `docker-push`, `docker-scan`, `dev-up`, `dev-down` | Build version-tagged images for ACR (`princesspink.azurecr.io`), multi-arch `linux/amd64,linux/arm64` builds, Trivy `HIGH,CRITICAL` scans, and local Docker Compose stacks. |
| **Tooling & Cleanup** | `tools`, `clean` | Install `govulncheck`, `golangci-lint` (v2), and `buf`; clean `bin/` and `.coverage/`. |

### 3. Local-to-CI Parity

GitHub Actions workflows ([ADR-0009](ADR-0009-github-actions-ci-cd.md)) invoke the exact same `Makefile` targets (`make fmt-check`, `make vet`, `make lint`, `make test-race`, `make test-sim`, `make test-integration`, `make vuln`, `make proto-lint`, `make proto-breaking`, `make docker-scan`) rather than duplicating shell logic in YAML. This guarantees that a contributor running `make check` locally reproduces CI behavior faithfully.

---

## Options Considered

| Option | Description | Evaluation |
| :--- | :--- | :--- |
| **1. Root GNU `Makefile`** | Standard, pre-installed POSIX/GNU `make` coordinating all `pkg/` and `services/` modules with `SERVICE=` scoping. | **Selected.** Ubiquitous on Linux, macOS, and GitHub Actions runners with zero extra bootstrap tool required; simple, transparent, and already established in the repository. |
| **2. `Taskfile` (`go-task`) or `just`** | Modern YAML or custom-DSL task runners. | **Rejected.** Requires every contributor and CI image to install an additional non-standard task runner before running basic repository commands. |
| **3. Bazel / Buck2** | Hermetic polyglot build system with remote caching. | **Rejected.** Heavy configuration overhead (`BUILD.bazel` maintenance) disproportionate for a pure-Go workspace where `go.work` and Go's built-in build cache are already fast. |
| **4. Per-Service Independent Makefiles / Shell Scripts** | Maintain separate scripts inside each `services/<svc>/` directory. | **Rejected.** Leads to drift across 25+ microservices whenever compiler flags (`-trimpath`, `-ldflags`), linters, or security scans are updated. |

---

## Rationale & Alignment with PrincessPink Requirements

1. **Zero-Friction Contributor Onboarding (Concept §7.3 & README):**
   Contributors only need Go 1.27+ (`toolchain go1.27.4`), Git, and GNU `make` to discover every workflow command via `make help` and validate changes with `make check`.
2. **Independent Microservice Versioning Enforcement (Concept §3.5):**
   Reading `services/<svc>/VERSION` centrally in `build`, `versions`, `tag`, `docker-build`, `docker-buildx`, `docker-push`, and `docker-scan` guarantees consistent semantic version propagation from binary `-ldflags` to Git tags and ACR container tags.
3. **Hardened Static Container Builds (Concept §6.3):**
   Defaulting to `CGO_ENABLED=0`, `-trimpath`, and `-s -w` produces reproducible static binaries ready for non-root `distroless/static` AKS containers.

---

## Consequences

### Positive
- Single source of truth for build, test, lint, Protobuf, versioning, and container commands across local machines and GitHub Actions CI.
- Adding a new microservice under `services/<new-service>/` with a `go.mod` and `VERSION` file automatically integrates it into all `Makefile` targets with zero edits to the `Makefile`.
- Fast inner-loop development via `SERVICE=<name>` scoping.

### Trade-offs & Operational Notes
- **GNU `make` & Bash Requirement:** Targets rely on Bash (`-euo pipefail`) and standard GNU utilities; Windows contributors should use WSL2 or Dev Containers.
- **Sequential Loop Performance at Scale:** Iterating sequentially over `ALL_MODULES` is simple and clear for Phase 1–3; if workspace size grows significantly, GitHub Actions CI ([ADR-0009](ADR-0009-github-actions-ci-cd.md)) parallelizes per-module jobs using `SERVICE=<name>` while local `Makefile` remains simple and predictable.
- **SQLite Pure-Go Driver Alignment:** Because `build-linux` defaults to `CGO_ENABLED=0` for `distroless/static` images, simulation microservices using SQLite should prefer pure-Go SQLite drivers (e.g., `modernc.org/sqlite`) or explicitly override `CGO_ENABLED=1` only if a service genuinely requires CGo.
