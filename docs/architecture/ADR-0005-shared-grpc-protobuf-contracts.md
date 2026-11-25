# ADR-0005: Shared gRPC & Protocol Buffers Contracts (`libs/proto`)

- **Status:** Accepted
- **Date:** 2026-11-22
- **Deciders:** PrincessPink Architecture
- **Related Documents:** [`docs/Concept.md`](../Concept.md), [`README.md`](../../README.md), [`Makefile`](../../Makefile), [`ADR-0002`](ADR-0002-world-chat-microservices-and-server-selection.md), [`ADR-0004`](ADR-0004-shared-opentelemetry-observability.md), [`ADR-0008`](ADR-0008-multi-module-makefile-build-automation.md)

---

## Context

PrincessPink's microservices rely heavily on low-latency, strongly typed synchronous internal RPCs (Concept §3.4 & §4.3):

- **High Fan-Out Character Sheet Aggregation:** `sheet-aggregator` invokes `character-registry` and 15+ dedicated `attr-*` microservices concurrently via Go `errgroup` with strict per-call deadlines.
- **Authorization & Group Rules:** `frontend-gateway`, `sheet-aggregator`, `character-registry`, and `chat-service` query `user-admin` to verify Player/Game Master roles, single-character-per-group selections, and child ownership rules.
- **Real-Time Chat Control & Streaming:** `frontend-chat`, `chat-service`, and `chat-world-registry` exchange World Chat Server listings, occupancy heartbeats, `SwitchWorldServer` commands, and message streams ([ADR-0002](ADR-0002-world-chat-microservices-and-server-selection.md)).
- **Direct Simulation Queries:** Synchronous calculation RPCs to `sim-birth-date`, `sim-egg-selection`, `sim-menarche`, and `sim-mortality`.

Because every microservice is independently versioned and deployed (Concept §3.5), internal API contracts must enforce strict backward compatibility, prevent accidental breaking changes, and minimize boilerplate across 25+ Go services.

---

## Decision

PrincessPink centralizes all internal gRPC and Protocol Buffers schemas, generated Go bindings, and shared gRPC transport helpers in a dedicated Go module **`libs/proto`**, managed and validated with **`buf`**.

### 1. Schema Layout & Package Versioning

Protobuf source definitions live under `libs/proto/` organized by bounded domain and explicit major API version (`v1`, `v2`, ...):

```text
libs/proto/
├── go.mod
├── buf.yaml
├── buf.gen.yaml
├── princesspink/
│   ├── common/v1/          # Shared types: UUID, SimTick, ServiceVersion, ErrorDetail, PaginationCursor
│   ├── attribute/v1/       # Standardized AttributeCalculator (CalculateRequest / CalculateResponse)
│   ├── useradmin/v1/       # Auth validation, RBAC & Group membership checks
│   ├── character/v1/       # character-registry & sheet-aggregator contracts
│   ├── chat/v1/            # chat-service & chat-world-registry (ListWorldServers, SwitchWorldServer, SendMessage)
│   └── simulation/v1/      # Synchronous sim-* RPCs & shared domain event envelope schemas
├── gen/go/                 # Generated Go Protobuf & gRPC stubs (committed and verified in CI)
└── grpcutil/               # Shared gRPC server/client builders, interceptors, health & deadline helpers
```

- **Standardized Attribute Contract (`princesspink.attribute.v1`):** Implements the uniform `AttributeCalculator.Calculate(CalculateRequest) returns (CalculateResponse)` RPC defined in Concept §4.3, carrying `schema_version` and `service_version` on every response.
- **Domain Event Payloads:** Canonical asynchronous event payloads published on NATS JetStream (e.g., `sim.tick.advanced`, `sim.conception.occurred`, `sim.dna.calculated`) are also defined in `libs/proto` as Protobuf messages (serialized as Protobuf binary or ProtoJSON) so async schemas benefit from the same linting and breaking-change guarantees.

### 2. Code Generation & Compatibility Governance (`buf`)

- **Tooling:** Managed via `buf` (`make proto-lint`, `make proto-breaking`, `make proto-gen` in `Makefile`; [ADR-0008](ADR-0008-multi-module-makefile-build-automation.md)).
- **Linting (`buf lint`):** Enforces `STANDARD` lint rules (package directory matching, `PascalCase` messages/RPCs, `snake_case` fields, versioned packages, `Request`/`Response` suffixes).
- **Breaking Change Detection (`buf breaking`):** CI runs `buf breaking --against '.git#branch=main'` on every pull request so fields are never renumbered, retyped, or removed within a major version (`v1`). Breaking contract changes require introducing a new major package version (`v2`) with a deprecation window.
- **Committed Generated Code:** Generated Go code under `libs/proto/gen/go/` is committed to the repository so `go build` and `go test` work out of the box without requiring `protoc`/`buf` on every build machine; CI verifies that `make proto-gen` produces a clean git diff.

### 3. Shared gRPC Runtime Helpers (`libs/proto/grpcutil`)

To keep individual microservices concise and consistent, `libs/proto/grpcutil` provides:
- **Standard Server & Client Factories:** Pre-wired with OpenTelemetry stats handlers ([ADR-0004](ADR-0004-shared-opentelemetry-observability.md)), structured `slog` interceptors ([ADR-0003](ADR-0003-shared-logging-library.md)), panic recovery, and mTLS/TLS transport credentials for AKS.
- **Mandatory Deadlines & Metadata Propagation:** Client helpers enforce a default per-call timeout if the caller omits a deadline (preventing goroutine leaks during `sheet-aggregator` fan-out) and automatically propagate `correlation_id`, `user_uuid`, `group_id`, and `service_version` in gRPC metadata.
- **Standard Health & Reflection:** Registers `grpc.health.v1.Health` on every gRPC server and enables gRPC Server Reflection in `local`/`dev` environments only (disabled in `prod`).

---

## Options Considered

| Option | Description | Evaluation |
| :--- | :--- | :--- |
| **1. Centralized `libs/proto` Module with `buf` + gRPC** | Single versioned contract module in `go.work`, linted and breaking-checked by `buf`, with shared `grpcutil` interceptors. | **Selected.** Strong typing, binary HTTP/2 performance for parallel `attr-*` fan-out, automated breaking-change prevention across independently versioned services, and zero `protoc` plugin version drift. |
| **2. Raw `protoc` Shell Scripts** | Invoke `protoc` with manually installed `protoc-gen-go` / `protoc-gen-go-grpc` binaries. | **Rejected.** Fragile across developer machines and CI runners; lacks built-in lint and git-branch breaking-change verification. |
| **3. Separate Proto Repositories per Microservice** | Publish each service's `.proto` files in its own repository or Go module. | **Rejected.** Creates heavy cross-repo release ceremony during early multi-service iteration while `go.work` already manages modular boundaries cleanly within the monorepo. |
| **4. Internal REST / JSON over HTTP/1.1** | Use JSON/HTTP between `sheet-aggregator`, `attr-*`, `chat-*`, and `sim-*`. | **Rejected.** Higher serialization overhead and latency for 15+ parallel attribute calls, weaker compile-time contract enforcement, and no native bi-directional streaming for `frontend-chat` ↔ `chat-service`. |

---

## Rationale & Alignment with PrincessPink Requirements

1. **Low-Latency Attribute Fan-Out (Concept §4.3 & §8):**
   Binary Protobuf over multiplexed HTTP/2 gRPC connections directly mitigates the high service-count latency risk of PrincessPink's attribute-per-microservice architecture.
2. **Independent Microservice Versioning Safety (Concept §3.5):**
   Because `sheet-aggregator` v1.4.0 may call `attr-eye-color` v1.1.0 and `attr-repro-fertility` v1.3.2 simultaneously, `buf breaking` guarantees wire-level backward compatibility across independent deployment cadences.
3. **Contract Testing & Documentation (Concept §7.2):**
   `buf lint` and `buf breaking` provide automated contract tests in CI, while `.proto` files serve as authoritative, versioned API documentation alongside `docs/api/`.

---

## Consequences

### Positive
- Strongly typed, versioned internal APIs with automated breaking-change protection on every pull request.
- Minimal boilerplate when adding new `attr-*` or `sim-*` microservices thanks to `AttributeCalculator` and `grpcutil`.
- Unified schema language for both synchronous gRPC RPCs and asynchronous NATS JetStream event payloads.

### Trade-offs & Operational Notes
- **Generated Diff Discipline:** Contributors modifying `.proto` files must run `make proto-gen` and commit updated files under `libs/proto/gen/go/`; CI will reject stale generated code.
- **Additive-Only Evolution Within `v1`:** Removing or changing the semantics of existing fields requires reserving field numbers/names and adding new fields—or bumping to `v2`—which requires careful initial schema design.
- **External Browser APIs Remain HTTP/WebSocket:** `libs/proto` governs internal service-to-service contracts; external browser endpoints remain Go + Gin HTML/HTMX/JSON and `wss://` (documented with OpenAPI in `docs/api/` where applicable).
