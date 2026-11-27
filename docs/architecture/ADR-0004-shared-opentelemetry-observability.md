# ADR-0004: Shared OpenTelemetry & Observability Library (`libs/telemetry`)

- **Status:** Accepted
- **Date:** 2026-11-22
- **Deciders:** PrincessPink Architecture
- **Related Documents:** [`docs/Concept.md`](../Concept.md), [`README.md`](../../README.md), [`ADR-0003`](ADR-0003-shared-logging-library.md), [`ADR-0005`](ADR-0005-shared-grpc-protobuf-contracts.md), [`ADR-0006`](ADR-0006-shared-configuration-library.md)

---

## Context

PrincessPink executes both high-fan-out synchronous request trees and multi-stage asynchronous biological pipelines on **Azure Kubernetes Service (AKS)**:

- **Synchronous Fan-Out:** `frontend-sheets` → `sheet-aggregator` → `character-registry` + 15+ parallel `attr-*` microservices over gRPC (Concept §4.3).
- **Real-Time Messaging:** `frontend-chat` (`wss://`) → `chat-world-registry` / `chat-service` → NATS JetStream (`chat.world.<world_server_id>`, `chat.group.<group_id>`, `chat.dm.<pair_id>`) ([ADR-0002](ADR-0002-world-chat-microservices-and-server-selection.md)).
- **Asynchronous Simulation Pipelines:** `sim-clock` → `sim-egg-selection` / `sim-menstruation` → `sim-ejaculation` → `sim-sperm-race` → `sim-gamete-surface` → `sim-conception` → `sim-dna` → `sim-prenatal-loss` / `sim-gestation` → `sim-birth-date` / `sim-egg-reserve` / `sim-menarche` / `sim-mortality`, as well as parentless character generation via `sim-character-generator` → `sim-dna` / `character-registry` / `sim-health` / `sim-lifecycle` / `sim-mortality` / `sim-egg-reserve` / `sim-menarche` / `sim-menstruation` (Concept §2.7 & §4.4).

Without a shared observability bootstrap in `libs/telemetry`, services would diverge in trace context propagation, metric naming, resource metadata, and graceful exporter shutdown—breaking end-to-end distributed traces and HPA/SLO dashboards in the AKS `observability` namespace.

---

## Decision

PrincessPink establishes a shared Go module **`libs/telemetry`** built on the **OpenTelemetry Go SDK (`go.opentelemetry.io/otel`)**, exporting traces via **OTLP/gRPC** to the in-cluster OpenTelemetry Collector and exposing **Prometheus-compatible metrics** alongside standardized instrumentation helpers for Gin, gRPC, PostgreSQL, SQLite, and NATS JetStream.

### 1. Unified Bootstrap & Resource Identity

Every microservice initializes telemetry once in `main()` via `telemetry.Init(ctx, cfg)`:

- **Standard OTel Resource Attributes:** Automatically populates `service.name`, `service.version` (from `services/<service>/VERSION`), `service.namespace` (AKS namespace, e.g., `simulation`, `character-sheet`, `chat`, `frontend`, `user-admin`), `deployment.environment`, and `service.instance.id` (pod name / hostname).
- **Graceful Shutdown Hook:** Returns a `Shutdown(ctx)` function invoked on `SIGTERM`/`SIGINT` with a bounded timeout (e.g., 5 seconds) to flush buffered spans and metric batches before pod termination.
- **No-Op / Local Mode:** When `OTEL_EXPORTER_OTLP_ENDPOINT` is unset (e.g., unit tests or minimal local runs), `libs/telemetry` cleanly falls back to a no-op trace exporter while keeping Prometheus `/metrics` active.

### 2. Distributed Tracing & Context Propagation

- **Propagators:** Globally registers **W3C Trace Context** (`traceparent`, `tracestate`) and **W3C Baggage** (`baggage`) propagators.
- **Transport Instrumentation:**
  - **Gin HTTP (`frontend-*`):** Provides `otelgin` middleware extracting/injecting W3C headers and recording HTTP route templates (preventing high-cardinality URL paths).
  - **gRPC (All Internal Services):** Provides `otelgrpc` stats handlers (the modern OTel Go gRPC instrumentation) paired with `libs/proto` client/server helpers ([ADR-0005](ADR-0005-shared-grpc-protobuf-contracts.md)).
  - **NATS JetStream:** Provides a thin header carrier adapter (`NATSHeaderCarrier`) to inject trace context on publish and extract/link parent spans on async consumption—preserving causal traces across multi-step biological event chains.
- **Sampling Policy:** Parent-based trace sampling (`ParentBased(TraceIDRatioBased)`), defaulting to `1.0` in `dev`/`staging` and configurable (e.g., `0.1`–`0.25`) in `prod`, with errors and slow fan-outs eligible for tail-based sampling in the AKS OpenTelemetry Collector.

### 3. Metrics & Domain Instrumentation

- **Prometheus-Compatible Exposition:** Uses the OpenTelemetry Go `prometheus` exporter bridged to a dedicated `/metrics` HTTP endpoint (bound on an internal management port not exposed through public AKS Ingress) scraped by Prometheus / Azure Monitor Managed Prometheus.
- **Standard Service Metrics:** Automatically registers Go runtime metrics (`runtime`), HTTP/gRPC request counts and latency histograms (p50/p95/p99), and gRPC client fan-out error counters (critical for `sheet-aggregator` graceful degradation visibility).
- **Domain Metric Conventions:** Defines shared metric naming conventions (`princesspink_<domain>_<metric>_<unit>`, e.g., `princesspink_sim_tick_duration_seconds`, `princesspink_sim_characters_generated_total`, `princesspink_sim_reappearances_total`, `princesspink_character_npc_claims_total`, `princesspink_sim_conceptions_total`, `princesspink_sim_prenatal_losses_total`, `princesspink_sheet_attr_degraded_total`, `princesspink_chat_world_sessions_active`) and strictly forbids high-cardinality labels such as `character_uuid`, `user_uuid`, or `ejaculation_id` on Prometheus metrics (those belong on traces and structured logs; use strictly bounded enums like `creation_source`, `simulation_mode`, `participation_role`, or `loss_stage`).

### 4. Health & Readiness Endpoints

`libs/telemetry` (or its companion HTTP admin server helper) standardizes the operational probes required by AKS (Concept §3.5 & §6.3):
- `/healthz` — Liveness probe returning service identity and embedded `service_version`.
- `/readyz` — Readiness probe running registered dependency checks (e.g., PostgreSQL ping, NATS connection, mounted SQLite reference DB check).
- `/metrics` — Internal Prometheus scrape endpoint.

---

## Options Considered

| Option | Description | Evaluation |
| :--- | :--- | :--- |
| **1. OpenTelemetry Go SDK + OTLP Collector + Prometheus Exporter (`libs/telemetry`)** | Vendor-neutral OpenTelemetry SDK exporting traces to the in-cluster OTel Collector and metrics via Prometheus/OTLP. | **Selected.** Cloud- and vendor-neutral, natively integrates with AKS `observability` (Prometheus, Grafana, Azure Monitor), unifies HTTP/gRPC/NATS tracing, and directly implements Concept §6.1 & §7.1. |
| **2. Vendor-Specific Azure Monitor / Application Insights SDK** | Instrument Go services directly with proprietary Azure telemetry SDKs. | **Rejected.** Locks service code to a single cloud vendor, provides weaker Go gRPC/NATS ergonomics, and complicates local Docker Compose / `kind` development. |
| **3. Separate Point Solutions (Direct `prometheus/client_golang` + Jaeger/Zipkin SDKs)** | Wire unrelated tracing and metrics libraries independently in each service. | **Rejected.** Duplicates resource metadata, diverges from W3C standards, and increases maintenance burden across 25+ microservices. |

---

## Rationale & Alignment with PrincessPink Requirements

1. **Visibility into Attribute Fan-Out & Graceful Degradation (Concept §4.3 & §8):**
   Distributed spans across `sheet-aggregator` → `attr-*` immediately pinpoint which specific attribute microservice breached its gRPC deadline or triggered graceful degradation.
2. **End-to-End Biological Pipeline Traceability (Concept §4.4):**
   Propagating W3C trace context through NATS JetStream headers links an entire reproduction chain (`sim-ejaculation` → `sim-sperm-race` → `sim-gamete-surface` → `sim-conception` → `sim-dna`) into a single navigable trace.
3. **Log–Trace Correlation ([ADR-0003](ADR-0003-shared-logging-library.md)):**
   `libs/logging` reads `trace_id` and `span_id` directly from the OpenTelemetry span context initialized by `libs/telemetry`, enabling one-click navigation between logs and traces.
4. **AKS & Azure Monitor Compatibility (Concept §6.1 & §6.2):**
   Exporting OTLP to the `observability` namespace OpenTelemetry Collector decouples microservices from backend storage choices—the Collector can fan out to Azure Monitor, Grafana Tempo, or local Jaeger without recompiling any service.

---

## Consequences

### Positive
- Consistent traces, metrics, and health/readiness probes across all Go microservices with minimal per-service boilerplate.
- Full local-to-AKS parity: developers can inspect traces locally (e.g., Jaeger/Grafana OTLP in Docker Compose) using the exact same instrumentation running on AKS.
- Strict cardinality discipline prevents Prometheus memory exhaustion as simulated populations grow across generations.

### Trade-offs & Operational Notes
- **Collector Dependency in AKS:** Requires deploying and maintaining an OpenTelemetry Collector in the `observability` namespace with appropriate `NetworkPolicy` egress rules from `frontend`, `user-admin`, `chat`, `character-sheet`, and `simulation`.
- **Internal Admin Port Isolation:** `/metrics` must bind to an internal admin port (or be blocked at Ingress) so internal operational telemetry is never publicly exposed.
- **Cardinality Reviews:** Code reviews and CI checks must ensure `character_uuid`, `user_uuid`, and `group_id` are attached to trace span attributes and `slog` logs—never as unbounded Prometheus metric labels.
