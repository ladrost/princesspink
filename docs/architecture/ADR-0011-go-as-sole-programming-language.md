# ADR-0011: Go as the Sole Programming Language (Go 1.27+)

- **Status:** Accepted
- **Date:** 2026-11-27
- **Deciders:** PrincessPink Architecture
- **Related Documents:** [`docs/Concept.md`](../Concept.md), [`README.md`](../../README.md), [`AGENTS.md`](../../AGENTS.md), [`go.work`](../../go.work), [`Makefile`](../../Makefile), [`qodana.yaml`](../../qodana.yaml), [`ADR-0003`](ADR-0003-shared-logging-library.md), [`ADR-0004`](ADR-0004-shared-opentelemetry-observability.md), [`ADR-0005`](ADR-0005-shared-grpc-protobuf-contracts.md), [`ADR-0006`](ADR-0006-shared-configuration-library.md), [`ADR-0007`](ADR-0007-shared-uuid-utilities.md), [`ADR-0008`](ADR-0008-multi-module-makefile-build-automation.md), [`ADR-0009`](ADR-0009-github-actions-ci-cd.md)

---

## Context

PrincessPink is an open-source, scientific, population-level simulation of human reproduction and generational lineage presented through a pen-and-paper RPG interface. Its architecture decomposes the system into **25+ independently versioned microservices** across five functional domains deployed on **Microsoft Azure Kubernetes Service (AKS)** (Concept §3.1, §3.3 & §3.5):

1. **Frontend Microservices:** `frontend-gateway`, `frontend-sheets`, `frontend-gm`, `frontend-chat`, and `portrait-renderer` (HTTP/HTMX and authenticated TLS WebSockets).
2. **User Administration & Security:** `user-admin` (`Argon2id` authentication, Ed25519 JWTs, TOTP/WebAuthn MFA, Player/GM RBAC, Group management, and immutable PostgreSQL 18+ audit logging).
3. **Real-Time Chat & Communication:** `chat-service` and `chat-world-registry` (World of Warcraft-style selectable World Chat Servers, Group Chat, and 1-to-1 Direct Messages over NATS JetStream).
4. **Character Sheet & Attribute Microservices:** `character-registry`, `sheet-aggregator` (high fan-out concurrent aggregation with graceful degradation), and 15+ dedicated `attr-*` calculation services.
5. **Scientific Simulation Microservices:** `sim-clock`, `sim-egg-reserve`, `sim-egg-selection`, `sim-menarche`, `sim-menstruation`, `sim-ejaculation`, `sim-sperm-race`, `sim-gamete-surface`, `sim-conception`, `sim-dna`, `sim-birth-date`, `sim-gestation`, `sim-health`, `sim-mortality`, and `sim-lifecycle` (seeded stochastic biology, gamete meiosis/recombination, and SQLite reference/egg-reserve/ejaculation databases).

In distributed scientific platforms, it is common to consider a **polyglot architecture**—for instance, pairing one language for APIs and networking with **Python** for biological/statistical modeling, **Rust** or **C++** for compute-intensive gamete and DNA simulation loops, or **TypeScript/Node.js** for web frontends. While polyglot stacks can optimize isolated components, introducing multiple programming languages creates **technology breaks** across service boundaries: duplicated shared platform libraries, fragmented build and CI/CD pipelines, CGo/FFI operational friction, heavier runtime container footprints, inconsistent security scanning, and steeper contributor onboarding.

As PrincessPink establishes its **Phase 0 / Architectural Foundation** (with root [`go.work`](../../go.work) pinned to `go 1.27` / `toolchain go1.27.4` and shared platform contracts specified in [ADR-0003](ADR-0003-shared-logging-library.md)–[ADR-0009](ADR-0009-github-actions-ci-cd.md)), we need an explicit architectural record formalizing our programming-language choice and single-language policy.

---

## Decision

PrincessPink adopts **Go (`Go 1.27+`, `toolchain go1.27.4` in [`go.work`](../../go.work))** as the **sole programming language** for the entire project for the foreseeable future. **No technology breaks are planned** by introducing Python, Rust, C++, Java/Kotlin, C#/.NET, Node.js/TypeScript, or other general-purpose programming languages.

### 1. Single-Language Scope Across All Domains

All application, service, shared-library, CLI, and automated test code across the repository is written exclusively in **Go**:

- **Shared Platform Libraries (`libs/`):** `libs/logging` ([ADR-0003](ADR-0003-shared-logging-library.md)), `libs/telemetry` ([ADR-0004](ADR-0004-shared-opentelemetry-observability.md)), `libs/proto` generated bindings and `grpcutil` ([ADR-0005](ADR-0005-shared-grpc-protobuf-contracts.md)), `libs/config` ([ADR-0006](ADR-0006-shared-configuration-library.md)), and `libs/uuid` ([ADR-0007](ADR-0007-shared-uuid-utilities.md)).
- **Frontend & Edge Services (`services/frontend-*`, `services/portrait-renderer`):** Implemented in Go using the **Gin** HTTP framework, server-rendered HTML templates (`html/template` or `templ`), deterministic SVG/raster portrait generation, lightweight progressive enhancement (HTMX), and Go WebSocket handlers—without a separate Node.js/TypeScript SPA build chain.
- **Core Domain, Auth & Chat Services (`services/user-admin`, `services/character-registry`, `services/sheet-aggregator`, `services/attr-*`, `services/chat-*`):** Implemented in Go using gRPC/Protobuf, `errgroup` concurrent fan-out, `pgx/v5` (PostgreSQL 18+), and NATS JetStream.
- **Scientific Simulation Services (`services/sim-*`):** Implemented in Go using deterministic seeded PRNGs (`math/rand/v2`), compact binary chromosome/surface encodings, embedded SQLite stores, and fixed-seed cohort tests (`//go:build simulation`)—without calling out to Python, Rust, or C++ runtimes.

### 2. Zero Planned Polyglot or FFI Technology Breaks

- **No Polyglot Microservices:** No `sim-*`, `attr-*`, `frontend-*`, or supporting runtime service will be written in Python, Rust, C++, Java, C#, or Node.js/TypeScript.
- **No CGo / Native FFI Bridges by Default:** Services default to pure-Go static compilation (`CGO_ENABLED=0`, `-trimpath`, `-ldflags` version embedding) targeting non-root `distroless/static` containers on `linux/amd64` and `linux/arm64` ([ADR-0008](ADR-0008-multi-module-makefile-build-automation.md), [ADR-0009](ADR-0009-github-actions-ci-cd.md)). SQLite access prefers pure-Go drivers (e.g., `modernc.org/sqlite`) to avoid introducing a C/C++ compiler toolchain break.
- **Unified Quality, Static Analysis & Security Tooling:** Every module shares one workspace (`go.work`), one root `Makefile` ([ADR-0008](ADR-0008-multi-module-makefile-build-automation.md)), one GitHub Actions CI/CD model ([ADR-0009](ADR-0009-github-actions-ci-cd.md)), and one static-analysis/security toolchain: `gofmt -s`, `go vet`, `golangci-lint` v2, **JetBrains Qodana** (`jetbrains/qodana-go` via [`qodana.yaml`](../../qodana.yaml)), `go test -race`, `govulncheck`, CodeQL for Go, and Trivy container scanning.

### 3. Distinction Between Application Code and Declarative / Standard Formats

The Go-only rule governs all **programming languages** used for application, library, simulation, and test implementations. Standard declarative, schema, markup, and infrastructure formats remain expected where appropriate:

- **Database Schemas & Queries:** SQL (PostgreSQL 18+ migrations/queries and SQLite reference/gamete schemas).
- **Interface Contracts:** Protocol Buffers (`.proto` managed with `buf` under `libs/proto`) and OpenAPI specs (`docs/api/`).
- **Browser Presentation:** Server-rendered HTML, CSS, SVG (comic face portraits), and declarative progressive-enhancement attributes (e.g., HTMX).
- **Build & Infrastructure Automation:** GNU `Makefile` with POSIX/Bash glue ([ADR-0008](ADR-0008-multi-module-makefile-build-automation.md)), Dockerfiles, YAML/JSON/HCL (GitHub Actions, Kubernetes/Helm/Kustomize, `qodana.yaml`, Terraform).

### 4. Governance for Any Future Exception

Introducing a second programming language (or a CGo/FFI bridge to C, C++, Rust, or Python) is **disallowed by default**. Any future proposal to revisit this decision must be submitted as a **superseding ADR** that includes:

1. Reproducible benchmarks or hard technical evidence proving pure Go cannot meet a concrete latency, memory, or scientific requirement after idiomatic optimization and `pprof` profiling.
2. A full lifecycle plan covering equivalent implementations of `libs/logging`, `libs/telemetry`, `libs/proto`, `libs/config`, and `libs/uuid`, CI/CD build/test/security pipelines, container hardening, and contributor onboarding.

---

## Options Considered

| Option | Description | Evaluation |
| :--- | :--- | :--- |
| **1. Go (`Go 1.27+`) as the Sole Programming Language** | Use Go uniformly across `libs/` and all 25+ microservices (`frontend-*`, `user-admin`, `chat-*`, `character-sheet`, `sim-*`) in a single `go.work` workspace with `CGO_ENABLED=0` static builds. | **Selected.** Eliminates polyglot technology breaks, maximizes shared library reuse (`libs/*`), delivers native concurrency and compiled simulation speed, yields tiny hardened `distroless/static` AKS containers, and keeps open-source onboarding simple. |
| **2. Polyglot: Go + Python (for `sim-*` Scientific Services)** | Write API/web/auth/chat services in Go while implementing biological and statistical simulation services (`sim-*`) in Python (NumPy/SciPy). | **Rejected.** Creates a costly technology break: requires re-implementing `libs/logging`, `libs/telemetry`, `libs/config`, `libs/uuid`, gRPC interceptors, and NATS JetStream consumers in Python; introduces GIL/concurrency friction, interpreter memory overhead across 15+ `sim-*` pods, heavier non-distroless images, slower tight gamete/meiosis loops unless wrapped in C extensions, and a second packaging/lint/CVE toolchain (`pip`/`uv`, `ruff`, `mypy`). |
| **3. Polyglot: Go + Rust or C++ (for `sim-*` Gamete/DNA Loops or via CGo/FFI)** | Implement compute-heavy simulation services (`sim-egg-reserve`, `sim-ejaculation`, `sim-sperm-race`, `sim-dna`) in Rust or C++, either as standalone microservices or CGo-linked libraries. | **Rejected.** Premature complexity with no benchmarked need: manual memory management / borrow-checker complexity raises the contributor barrier; CGo breaks `CGO_ENABLED=0` static cross-compilation (`linux/amd64,linux/arm64`) and `distroless/static` simplicity; separate Rust/C++ microservices duplicate shared platform libraries and slow CI build times. Idiomatic pure Go with compact binary representations and bounded concurrency provides ample throughput. |
| **4. Polyglot: Go Backend + TypeScript / Node.js SPA Frontend** | Build `frontend-*` as a Node.js/TypeScript SPA (React/Next.js/Vue) while keeping backend services in Go. | **Rejected.** Introduces a second runtime, package ecosystem (`npm`/`pnpm`), bundler pipeline, client-side state duplication, and expanded supply-chain audit surface—unnecessary for PrincessPink's structured pen-and-paper RPG character sheets, GM portals, and WebSocket chat, which Go + Gin + server-rendered HTML/HTMX handle cleanly (Concept §4.1). |
| **5. Alternative Single-Language Platform (Python-only, Rust-only, Java/Kotlin, or C#/.NET)** | Standardize the entire platform on a different single language instead of Go. | **Rejected.** *Python-only* lacks static binary compilation, strong compile-time contracts across 25+ services, lightweight concurrency for `sheet-aggregator`/WebSockets, and minimal AKS pod footprints. *Rust-only* imposes steeper learning curves and slower compile cycles across 25+ CRUD, UI, RBAC, and attribute services where GC-free memory control is unnecessary. *Java/Kotlin (JVM)* and *C#/.NET* incur significantly higher per-pod baseline RAM and image footprints across 25+ fine-grained microservices on AKS. |

---

## Rationale & Alignment with PrincessPink Requirements

1. **Zero Technology Breaks Across 25+ Independently Versioned Microservices (Concept §3.3 & §3.5):**
   PrincessPink intentionally decomposes character sheet attributes (`attr-*`) and biological subsystems (`sim-*`) into many small, independently versioned services. Using Go exclusively ensures that every cross-cutting platform concern—structured non-PII logging (`libs/logging`, [ADR-0003](ADR-0003-shared-logging-library.md)), OpenTelemetry tracing/metrics (`libs/telemetry`, [ADR-0004](ADR-0004-shared-opentelemetry-observability.md)), gRPC/Protobuf contracts and interceptors (`libs/proto`, [ADR-0005](ADR-0005-shared-grpc-protobuf-contracts.md)), typed 12-Factor + Key Vault CSI config (`libs/config`, [ADR-0006](ADR-0006-shared-configuration-library.md)), and RFC 9562 UUIDv7 generation/validation (`libs/uuid`, [ADR-0007](ADR-0007-shared-uuid-utilities.md))—is implemented, hardened, and maintained **once**.
2. **First-Class Concurrency for Fan-Out & Real-Time Chat (Concept §4.3 & §4.5):**
   Go's goroutines, `context.Context` deadlines/cancellation, and `golang.org/x/sync/errgroup` map directly onto `sheet-aggregator`'s parallel gRPC fan-out across 15+ `attr-*` services (with strict per-call timeouts and graceful degradation) as well as `frontend-chat`/`chat-service`'s concurrent WebSocket and NATS JetStream fan-out for World, Group, and Direct Message chat ([ADR-0002](ADR-0002-world-chat-microservices-and-server-selection.md)). Built-in race detection (`go test -race`) verifies concurrent correctness directly in CI.
3. **Compiled Speed & Deterministic Scientific Modeling (Concept §4.4 & §7.2):**
   Compiled Go executes gamete meiosis, crossover/recombination, Mendelian ABO/RhD blood-type inheritance, receptor–ligand surface compatibility (`sim-gamete-surface`), sperm-race cohort scoring (`sim-sperm-race`), and batched SQLite writes (`sim-egg-reserve`, `sim-ejaculation`) efficiently in native machine code. Standard-library `math/rand/v2` with explicit seeds derived from `(group_id, sim_tick, event_id)` and `//go:build simulation` tests provide reproducible scientific verification without external runtimes.
4. **Cloud-Native AKS Pod Density & Security Hardening (Concept §6.2 & §6.3):**
   Running 25+ microservices across isolated AKS namespaces (`frontend`, `user-admin`, `chat`, `character-sheet`, `simulation`) requires low memory overhead and fast startup for Horizontal Pod Autoscaling (HPA). Pure-Go `CGO_ENABLED=0` static binaries packaged in non-root `distroless/static` containers contain no shell, interpreter, or OS package manager—minimizing both RAM cost and CVE attack surface (`govulncheck` + Trivy).
5. **Complete Standard Library & Mature Ecosystem Fit:**
   Go natively covers every layer of PrincessPink with minimal dependency sprawl: `log/slog`, `html/template`, `math/rand/v2`, `crypto/ed25519`, `crypto/subtle`, `golang.org/x/crypto/argon2`, Gin, gRPC/Protobuf, `pgx/v5` (PostgreSQL 18+), pure-Go SQLite (`modernc.org/sqlite`), NATS JetStream, OpenTelemetry, and Testcontainers.
6. **Low-Friction Open-Source Contributor Experience (Concept §7.3, [ADR-0008](ADR-0008-multi-module-makefile-build-automation.md), [ADR-0009](ADR-0009-github-actions-ci-cd.md)):**
   Go's small specification, canonical formatting (`gofmt -s`), fast compilation, built-in testing/benchmarking/profiling (`pprof`), root `Makefile`, and unified IDE/CI static analysis (`golangci-lint`, JetBrains Qodana) allow any contributor to move fluidly between `frontend-sheets`, `user-admin`, `chat-service`, `attr-*`, and `sim-*` without switching languages or toolchains.

---

## Consequences

### Positive
- **Zero Polyglot Fragmentation:** One language, one workspace (`go.work`), one set of shared `libs/` platform modules, one `Makefile`, and one CI/CD quality and security pipeline across the entire repository.
- **Lower Operational & Cloud Cost on AKS:** Small static `distroless/static` images (`linux/amd64,linux/arm64`) with low baseline RAM and fast cold starts keep a 25+ microservice topology economical and resilient.
- **Consistent Security & Observability Guarantees:** PII redaction, Ed25519 JWT/RBAC checks, UUIDv7 validation, W3C trace propagation, and `govulncheck` reachability analysis apply uniformly to every service without per-language drift.
- **High Contributor Mobility:** Contributors only need Go 1.27+ (`toolchain go1.27.4`), Git, and GNU `make` to understand, build, and test any part of PrincessPink.

### Trade-offs & Operational Notes
- **No Direct Python Scientific Ecosystem at Runtime:** Biological probability distributions, physiological curves, and population analytics cannot import SciPy/NumPy/pandas directly at runtime; they must be expressed cleanly in pure Go and parameterized via versioned read-only SQLite reference datasets and `GROUP.simulation_config` JSONB (Concept §4.4 & §5.2).
- **GC Awareness in Allocation-Heavy Gamete Loops:** Unlike Rust or C++, Go is garbage-collected. High-volume gamete generation and scoring paths (`sim-egg-reserve`, `sim-ejaculation`, `sim-sperm-race`) should use pre-allocated slices, compact binary chromosome/surface encodings, batched SQLite transactions, and `make bench` / `pprof` profiling to keep allocations and GC overhead low.
- **Pure-Go Dependency Discipline (`CGO_ENABLED=0`):** Contributors must avoid introducing Go dependencies that silently require CGo (C/C++/Rust bindings) so static cross-compilation and `distroless/static` container builds remain intact across all services.
- **Progressive Web Interactivity Bounds:** Keeping `frontend-*` Go-native (Gin + server-rendered HTML/HTMX + deterministic SVG portraits) avoids Node.js/TypeScript build complexity; future interactive visualizations (such as zoomable multi-generational lineage graphs) should favor server-generated SVG or minimal, zero-build progressive enhancement unless formally revisited via ADR.
- **Explicit Escape Hatch via Superseding ADR:** While no technology breaks are planned, this decision is documented rather than irreversible—if a future phase uncovers a verified, benchmarked workload that pure Go cannot meet, introducing another language remains possible through a dedicated superseding ADR.
