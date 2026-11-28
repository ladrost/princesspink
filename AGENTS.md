# AGENTS.md — PrincessPink Coding & Architecture Guidelines

This file provides authoritative instructions for AI coding agents and contributors working on **PrincessPink**. Every change must align with [`docs/Concept.md`](docs/Concept.md) and the Architecture Decision Records in [`docs/architecture/`](docs/architecture/).

---

## 1. Project Overview & Current Phase

- **What PrincessPink Is:** An open-source, scientific, population-level simulation of human reproduction and generational lineage presented through a pen-and-paper RPG interface.
- **Current Stage:** Phase 0 (Architectural Foundation). Shared libraries under `libs/` and microservices under `services/` are being built incrementally according to the phased roadmap in `docs/Concept.md`.
- **Authoritative Documentation:**
  - [`docs/Concept.md`](docs/Concept.md) — Domain model, lifecycle, genetics/simulation rules, service catalog, storage, and AKS deployment architecture.
  - [`docs/architecture/ADR-0001`](docs/architecture/ADR-0001-minimum-postgresql-version.md) — Minimum PostgreSQL 18+ baseline.
  - [`docs/architecture/ADR-0002`](docs/architecture/ADR-0002-world-chat-microservices-and-server-selection.md) — World Chat microservices & server selection.
  - [`docs/architecture/ADR-0003`](docs/architecture/ADR-0003-shared-logging-library.md) — Shared structured logging (`libs/logging`).
  - [`docs/architecture/ADR-0004`](docs/architecture/ADR-0004-shared-opentelemetry-observability.md) — Shared OpenTelemetry observability (`libs/telemetry`).
  - [`docs/architecture/ADR-0005`](docs/architecture/ADR-0005-shared-grpc-protobuf-contracts.md) — Shared gRPC & Protobuf contracts (`libs/proto`).
  - [`docs/architecture/ADR-0006`](docs/architecture/ADR-0006-shared-configuration-library.md) — Shared configuration (`libs/config`).
  - [`docs/architecture/ADR-0007`](docs/architecture/ADR-0007-shared-uuid-utilities.md) — Shared UUIDv7 utilities (`libs/uuid`).
  - [`docs/architecture/ADR-0008`](docs/architecture/ADR-0008-multi-module-makefile-build-automation.md) — Multi-module `Makefile` build automation.
  - [`docs/architecture/ADR-0009`](docs/architecture/ADR-0009-github-actions-ci-cd.md) — GitHub Actions CI/CD architecture.
  - [`docs/architecture/ADR-0010`](docs/architecture/ADR-0010-user-admin-auth-rbac-and-group-management.md) — `user-admin` auth, RBAC & group management.
  - [`docs/architecture/ADR-0011`](docs/architecture/ADR-0011-go-as-sole-programming-language.md) — Go as the sole programming language (no planned polyglot breaks).
  - [`docs/architecture/ADR-0012`](docs/architecture/ADR-0012-private-subnet-isolation-and-encrypted-cloud-communication.md) — Private subnet isolation per namespace & end-to-end encrypted cloud communication.
  - [`docs/architecture/ADR-0013`](docs/architecture/ADR-0013-static-website-service-and-public-results-presentation.md) — Built-in pure-Go static website service (`frontend-website` & `website-service`), `SYSTEM_ADMIN` editorial portal (Landing Page, Imprint, Privacy Policy), and native public service results presentation without third-party CMS tools.
  - [`docs/architecture/ADR-0014`](docs/architecture/ADR-0014-compulsory-go-and-open-source-source-code-documentation.md) — Compulsory Go & Open-Source source code documentation standards (enforced for all human developers and AI coding agents via `.golangci.yml`, `qodana.yaml`, `buf`, `go doc`, and PR gates).

---

## 2. Non-Negotiable Content & Safety Policy

All code, UI templates, API schemas, seed data, tests, and documentation **must** strictly enforce:

1. **Zero Violence & Zero Gore:** No combat, weapons, injury graphics, gore, or violent narratives. Characters live and pass away strictly through natural biological lifecycles.
2. **Zero Nudity & Zero Explicit Content:** Human reproduction is modeled purely through abstract scientific data, clinical parameters, biological state transitions, and tabletop-style stats/events—never explicit text, imagery, or adult themes.
3. **Safe-by-Design Visuals:** Character art is strictly limited to deterministic, stylized comic-art face portraits (head and shoulders) derived from phenotype and age stage. Do not allow unmoderated free-form image uploads; keep text and attributes schema-driven.

---

## 3. Core Domain Invariants

Respect these domain rules across all services and tests:

- **Permanent Identity & Lifecycle:** Assign a globally unique, immutable `UUIDv7` at conception (`CONCEIVED` → `GESTATING` → `ALIVE` → `DECEASED`, including natural prenatal loss `CONCEIVED`/`GESTATING` → `DECEASED` via `sim-prenatal-loss`, enabled by default and GM-configurable in `GROUP.simulation_config`) or at parentless character generation (`sim-character-generator` entering directly in `ALIVE` with `mother_uuid = null`, `father_uuid = null`, `conceived_at_sim = null`, immutable `creation_source` [`SYSTEM_SEED` | `GM_NPC` | `PLAYER_NEW_FAMILY` | `PLAYER_GROUP_JOIN`], age-consistent biological bootstrapping, and conditional natural mortality `date_of_death > T_sim`). On prenatal loss, keep `date_of_birth` null, record `date_of_death` and `PREGNANCY` outcome metadata, close any `PENDING` `OWNERSHIP_AGREEMENT` (`CLOSED_PRENATAL_LOSS`), skip newborn-only services (`sim-egg-reserve`, `sim-menarche`, `sim-mortality`), and trigger maternal recovery. Deceased character records remain queryable; parent references are immutable (`null` for parentless generated founders).
- **Immutable Life History & Reappearance (`CHARACTER_ATTRIBUTE_HISTORY`, `REPLAY_IMMUTABLE`):**
  - Store **all dynamic attribute changes within a character's life** in append-only `character_registry.character_attribute_history` (`REVOKE UPDATE, DELETE`, advancing `simulated_until_sim`, with at most one active `LIVE_PRIMARY` Group per character) so the character can reappear at any point-in-time `T_sim` in a new Group running during `[date_of_birth, date_of_death)`.
  - Stored attribute changes are **permanently immutable once they have happened** (`T_sim <= simulated_until_sim`), and once the character's life has been simulated once (`life_simulation_status == COMPLETED`), no attribute, lifestyle, medication, GM `weight_kg`/`health` adjustment, or `date_of_death` may ever be modified again.
  - The **only** actions permitted for an already-simulated (`REPLAY_IMMUTABLE`) character are **participating in new simulations** (replaying immutable attributes as of `T_sim`) and **having additional children** (creating new child `CHARACTER` + `PREGNANCY` records in the new Group without mutating any stored parent history).
  - **Female Biological Windows:** An already-simulated female may conceive additional children **strictly within periods allowed biologically by her finished life simulation**—enforced under per-mother `FOR UPDATE` locking via `character-registry.ValidateFemaleBiologicalWindow`: (1) alive at `T_sim` with projected delivery `< date_of_death`, (2) `date_of_first_ovulation <= T_sim < climacterium_date` with stored `fertility_score(T_sim) > 0`, (3) consistent with immutable stored `MENSTRUATION_CYCLE`, `CONTRACEPTION_PILL`, and physiological state at `T_sim`, (4) no overlap with any recorded `PREGNANCY` or its postpartum/post-loss `recovery_end_sim`, (5) forward-lookahead non-overlap ensuring projected gestation + recovery does not collide with any subsequent recorded `PREGNANCY.started_at_sim`, and (6) an unfertilized oocyte available in her **retained/archived** `EGG_RESERVE_DB` (never permanently delete a female's Egg-Reserve DB on menopause/death; hydrate on demand and mark fertilized oocytes atomically).
- **Genetics vs. Phenotype:** The 23-pair diploid genome, biological gender (`FEMALE`/`MALE`), and Mendelian ABO + RhD `blood_type` are determined permanently at conception—or synthesized from Hardy-Weinberg population allele-frequency tables during parentless founder generation (`sim-dna`)—and are **immutable**. Appearance (`eye_color`, `hair_color`, `skin_color`), physical metrics (`height_cm`, `weight_kg`, BMI, body composition), health indicators, and fertility/intercourse values evolve dynamically across life stages and role-play during `LIVE_PRIMARY` simulation (and are persisted immutably in `CHARACTER_ATTRIBUTE_HISTORY`).
- **Gender-Specific Biology:**
  - Female characters receive a dedicated UUID-linked Egg-Reserve SQLite database at birth (or at parentless generation with age-adjusted follicular atresia), retained/archived for potential `REPLAY_IMMUTABLE` reappearances; fertility is strictly `0` before first ovulation and upon climacterium.
  - Male characters have fertility strictly `0` before puberty, rising from teenage onset to a peak around age 21 and declining gradually; each ejaculation produces an event-specific sperm-cohort SQLite database whose quality degrades on short-interval consecutive ejaculations.
- **Determinism & Traceability:** All stochastic simulation steps—including parentless founder generation—must use explicit seeded PRNGs derived from `(group_id, sim_tick, event_id)` (or explicit bootstrap seeds for `SYSTEM_SEED`). Never hardcode magic biological constants in code or environment variables—store scientific parameters in versioned read-only SQLite reference datasets or versioned `GROUP.simulation_config` JSONB, and record the producing `service_version` on simulation outputs/events.
- **Players, Game Masters & Groups:**
  - A Player may own multiple characters but plays **only one already-owned character per group**, locked at group start and verified by **point-in-time era liveness** as **alive during the time period the Group simulates** (`date_of_birth IS NOT NULL AND date_of_birth <= T_sim AND (date_of_death IS NULL OR T_sim < date_of_death)`, `NOT (creation_source == CONCEPTION AND origin_group_id == group_id)`—explicitly covering both currently live-simulating owned characters and already-simulated owned characters reappearing in `REPLAY_IMMUTABLE` mode, while excluding prenatal losses, unborn characters, and characters deceased at or before `T_sim`).
  - **Activation Decision Authority:** Only the **owning Player** (`owner_user_id IS NOT NULL`) decides whether an owned character becomes active again in a new Group; no GM may activate a Player-owned character as an NPC. If a character has **no owner** (`owner_user_id IS NULL`), a **Game Master** managing a Group running during its living lifetime may activate and use the character as an NPC (`GROUP_CHARACTER_PARTICIPATION`), audited in `user_admin.audit_logs`.
  - **Mandatory Two-Path Fallback When Lacking an Era-Alive Character:** If a Player has no owned character alive during the Group's simulated time period `T_sim`, the Player **must** either (1) **generate a new parentless founder character** (`PLAYER_GROUP_JOIN` anchored to `T_sim`, alongside `PLAYER_NEW_FAMILY` for starting new bloodlines, with `owner_user_id = player_id`, `origin_group_id = null`, server-side seeded stat rolling, and roster quotas/cooldowns), **or** (2) **take permanent ownership of an eligible unowned NPC in the system** via atomic `NPC_OWNERSHIP_CLAIM` (`UPDATE ... WHERE owner_user_id IS NULL RETURNING OLD, NEW`, verifying zero era-alive owned PCs, no `PENDING` parental `OWNERSHIP_AGREEMENT`, non-child-in-origin-group, non-`LIVE_PRIMARY` conflict, and preserving immutable history if the NPC was already simulated).
  - Children conceived or born in a group start as unowned NPCs, require parental ownership agreement (mutual between both parents' Players, or PC-parent claim per `GROUP.simulation_config` when the other parent is an unowned NPC), and remain NPCs in their origin group (playable only in a future group whose sim clock falls within their living lifespan).
  - Game Masters oversee only their own groups, may generate bounded parentless role-play NPCs (`GM_NPC`, `owner_user_id = null`, `origin_group_id = group_id`) or activate existing unowned NPCs (`owner_user_id = null`) alive at `T_sim`, hold **exclusive authority to initiate GM-only Role-Play Elements** via `sim-roleplay`—specifically **Accidental / Premature Ejaculation** (`ACCIDENTAL_PREMATURE_EJACULATION`, starts simulation), **Broken Condom** (`BROKEN_CONDOM`, starts simulation), **Forgotten Contraception Pill** (`FORGOTTEN_CONTRACEPTION_PILL`, `LIVE_PRIMARY` + active pill only, starts simulation), **Female Orgasm** (`FEMALE_ORGASM`, strictly GM-only—Players denied via RBAC—mandating explicit GM choice of `CLITORAL` vs. `VAGINAL`, where `VAGINAL` improves conception probability via cervicouterine sperm-transport/receptive synergy and `CLITORAL` remains conception-neutral with bounded `LIVE_PRIMARY` stress/sleep/lubrication/`vaginismus` relief), plus extended biologically grounded events (`EMERGENCY_CONTRACEPTION`, `OVULATION_SHIFT`, `HYPEROVULATION_EVENT`, `POST_COITAL_REST_MODIFIER`, `ACUTE_LIFE_EVENT`, `CLINICAL_SUPPORT_EVENT`, `ENVIRONMENTAL_SEASON_EVENT`)—and all GM adjustments/generations/events must be bounded, rationale-backed/audited, respect `REPLAY_IMMUTABLE` immutability and hard biological laws (`fertility_score == 0`, ovulation, `sim-gamete-surface`, `ValidateFemaleBiologicalWindow`), and be recorded in immutable audit logs. System bootstrap seeding (`SYSTEM_SEED`) is strictly internal-only and never exposed on public Player/GM routes.
  - **Tabletop Mechanics & Scientific Gamification (`sim-roleplay`, `gamification-service`):** Layered AD&D `d20` checks, `GROUP.simulation_config.discovery_mode` (`REALISTIC_FOG` vs. `CLINICAL_TRANSPARENT`), non-explicit `PARTNER_BOND` synchrony, multi-generational Lineage Chronicles, Genetic Discovery Codex (`GENETIC_CODEX_ENTRY`), cosmetic `CHARACTER_MILESTONE` badges, `GROUP_CHALLENGE` objectives, and Dynasty Almanacs must strictly uphold the zero-violence/zero-nudity policy and **never** override biological laws or grant pay-to-win/unrealistic stat buffs.
  - Each group has an independent simulation clock initialized with a mandatory `dd/MM/YYYY` start date at `0:00 h` (default speed: 1 simulated year = 24 real hours).
- **Built-In Static Website Service & `SYSTEM_ADMIN` Separation of Duties (`frontend-website`, `website-service`, [ADR-0013](docs/architecture/ADR-0013-static-website-service-and-public-results-presentation.md)):**
  - The platform provides its own pure-Go **Static Website Service** (`frontend-website` in `frontend`/`snet-frontend` + `website-service` in `website`/`snet-website`, owning `website.*` in PostgreSQL 18+)—never introduce third-party website generators or CMS stacks (such as Ghost, WordPress, or Drupal).
  - Protected core system pages (**Landing Page** `/`, **Imprint** `/imprint`, **Privacy Policy** `/privacy`, `is_system_page = true`) can be edited, previewed, versioned, published, and rolled back exclusively by an MFA-verified **`SYSTEM_ADMIN`** via `/admin/website/*` (strictly denied for `PLAYER` and `GAME_MASTER`, synchronously authorized via `user-admin`, audit-logged in `user_admin.audit_logs`, with append-only `website.page_revisions` and deletion/unpublish protection).
  - Compile Markdown strictly server-side in Go with allow-list HTML sanitization, zero-violence/zero-nudity content validation, strict CSP (zero `unsafe-inline` scripts), and zero unmoderated image uploads.
  - Render **public services' results** natively (World Chat Server directory from `chat-world-registry`, anonymized population/scientific stats from `character-registry`/`sim-clock`, strictly opt-in `GROUP.simulation_config.public_visibility` [default `false`] Dynasty Almanacs / Lineage Chronicles / Codex stats from `gamification-service`) via bounded `errgroup` fan-out buffered in `website.public_result_snapshots` with graceful degradation—never exposing PII, private Group Chats, private character sheets, or `GM_SECRET` events.
  - Under strict **separation of duties**, `SYSTEM_ADMIN` does **not** grant implicit Game Master powers, private character sheet access, GM-only role-play triggers, or private chat visibility; public registration always assigns `PLAYER`.

---

## 4. Repository Layout & Multi-Module Workspace

- **Workspace:** Go **1.27+** is the sole programming language for the project ([ADR-0011](docs/architecture/ADR-0011-go-as-sole-programming-language.md); no planned polyglot splits with Python, Rust, C++, or other languages), organized in a multi-module workspace defined in root `go.work` (`toolchain go1.27.4`; no root module). Register every new module under `libs/<module>` or `services/<service>` with `make work-use` and `make work-sync`.
- **Shared Packages (`libs/`):** Reusable platform libraries (`libs/logging`, `libs/telemetry`, `libs/proto`, `libs/config`, `libs/uuid`). Keep them small, well-tested, free of service-specific business logic, and equipped with `README.md`, package `doc.go`, and runnable `Example*` tests ([ADR-0014](docs/architecture/ADR-0014-compulsory-go-and-open-source-source-code-documentation.md)).
- **Microservices (`services/<service-name>/`):** Independently buildable, deployable, and semantically versioned services:
  - Must contain `go.mod`, a `VERSION` file (SemVer, e.g. `0.1.0`), `README.md`, `cmd/<service-name>/main.go` (or `cmd/server/main.go`), and `internal/` packages (with `doc.go` for multi-file packages) for private domain/adapter code.
  - Release tags follow `<service-name>/v<VERSION>`.
  - Embed `Version`, `Commit`, and `BuildDate` via `-ldflags` (handled automatically by `make build`).
- **Communication Boundaries & Cloud Network Isolation ([ADR-0012](docs/architecture/ADR-0012-private-subnet-isolation-and-encrypted-cloud-communication.md)):**
  - Browser-facing edge (`frontend-*` in `snet-frontend`, behind dedicated `snet-ingress` / Azure Front Door): Go + **Gin** HTTP/HTMX and authenticated TLS WebSockets (`wss://`), with end-to-end TLS 1.3 / mTLS re-encryption from ingress to `frontend-*`.
  - Internal synchronous RPC: **gRPC / Protocol Buffers** (`libs/proto`) over mandatory **mTLS (TLS 1.3)** for all intra-subnet and cross-subnet calls in cloud environments.
  - Internal asynchronous events & chat fan-out: **NATS JetStream** (`snet-messaging`, mandatory TLS 1.3 / mTLS on client, cluster, leaf-node, and replication links) or Azure Service Bus over Private Endpoint (with transactional outbox for PostgreSQL writes and idempotent consumers for at-least-once delivery).
  - Subnet isolation: All backend services (and PostgreSQL, as well as `frontend` pods behind edge ingress) reside exclusively in **private / non-public subnets** mapped 1:1 per Kubernetes namespace (same namespace = same subnet; different namespaces = different subnets).

---

## 5. Go Best Practices & Project Standards

### 5.1 Idiomatic Go & Code Structure

- Follow [Effective Go](https://go.dev/doc/effective_go) and [Go Code Review Comments](https://go.dev/wiki/CodeReviewComments).
- Format all Go code with `gofmt -s` (`make fmt`). Keep imports grouped cleanly (standard library, third-party, internal/workspace packages).
- Keep packages cohesive and avoid package-level mutable globals; pass dependencies explicitly via constructors (`New...`).
- Define small, focused interfaces **at the consumer side**, not preemptively in the implementation package.
- Keep `internal/` packages unexported to other modules; expose only intentional APIs under `libs/`.
- Prefer simple, readable control flow with early returns over deep nesting. Avoid unnecessary reflection or premature abstraction.
- Treat Go and Open-Source source code documentation as **compulsory** on every change (see §5.2 and [ADR-0014](docs/architecture/ADR-0014-compulsory-go-and-open-source-source-code-documentation.md)).

### 5.2 Source Code Documentation (Compulsory — ADR-0014)

Every human developer and AI coding agent **must** follow official [Go Doc Comments](https://go.dev/doc/comment) and open-source source code documentation best practices ([ADR-0014](docs/architecture/ADR-0014-compulsory-go-and-open-source-source-code-documentation.md)), machine-enforced by root [`.golangci.yml`](.golangci.yml), [`qodana.yaml`](qodana.yaml), `gofmt -s`, `go test`, and `buf lint`:

- **SPDX License Header (Mandatory):** Start every authored, non-generated Go source file on line 1 with `// SPDX-License-Identifier: BSD-3-Clause` (matching root [`LICENSE`](LICENSE)), separated by a blank line from any `//go:build` tag and from the `// Package <name>` doc comment so license headers never appear in `go doc` / `pkg.go.dev` output. Never edit generated files; ensure generators emit Go's canonical `^// Code generated .* DO NOT EDIT\.$` marker.
- **Package Documentation (`doc.go`):** Every Go package (`libs/*`, exported packages, and `internal/*` packages) must have **exactly one** package doc comment starting with `// Package <name> ...` (and `cmd/<service>/main.go` entry points must carry a concise command overview comment). Multi-file packages must place the package doc comment in a dedicated `doc.go`.
- **Exported Declarations:** Document every exported `type`, `func`, method, `const` (or grouped `const`/`var` block), and `var` with a complete-sentence Go doc comment directly above the declaration starting with the **exact exported identifier** and ending with a **period (`.`)**. Also document exported struct fields and interface methods with non-obvious units (`_cm`, `_kg`, `_bpm`, `_minutes`), bounds, zero-value/nil behavior, concurrency safety, and sentinel/typed error conditions (`errors.Is` / `errors.As`).
- **Go 1.19+ Doc Comment Syntax & Deprecations:** Use canonical `go/doc/comment` formatting (`# Headings`, lists, indented code blocks, `[Symbol]` / `[pkg.Symbol]` doc links, and `[Label]: URL` link definitions with zero unused links) formatted by `gofmt -s`—never raw HTML or unsupported Markdown (`**bold**`, triple-backtick fences). Mark deprecations with a dedicated `Deprecated: Use [Replacement] instead.` paragraph.
- **Runnable `Example` Functions (`*_test.go`):** Every shared library package under `libs/` (and any reusable exported Go API) must provide executable `Example*` tests with verified `// Output:` (or `// Unordered output:`) comments so documentation is continuously validated by `go test` and rendered by `make doc` / `pkg.go.dev`.
- **Per-Module & Per-Service `README.md`:** Maintain a concise `README.md` in every `libs/<module>/` and `services/<service>/` documenting purpose, owned PostgreSQL schemas or SQLite artifacts, gRPC/HTTP/NATS interfaces, `libs/config` keys, local commands (`make check SERVICE=<name>`, `make doc SERVICE=<name>`), and related ADRs.
- **High-Signal "Why" Comments (Zero AI Comment Bloat):** Inline comments and comments on non-trivial unexported symbols must explain **why**—biological/scientific formulas and SQLite reference provenance, PRNG seed derivation `(group_id, sim_tick, event_id)`, locking/concurrency ownership (`FOR UPDATE`, goroutine cancellation, channel ownership), `REPLAY_IMMUTABLE` temporal guards, RBAC/TLS boundaries, and ADR links. **Never** narrate obvious Go syntax (`// increment i`), never commit commented-out code, and only write tracked `// TODO(#<issue>): <action>` or `// FIXME(#<issue>): <action>` comments (never deferring security or safety invariants).
- **Non-Go Source Contracts & Schemas:** Document every `.proto` service, RPC, message, field, enum, enum value, and oneof with leading comments (`buf` `COMMENTS` category, ADR-0005); document OpenAPI endpoints/schemas (`docs/api/`), SQL migrations and PostgreSQL `COMMENT ON TABLE`/`COLUMN` metadata, `Makefile` `##` target descriptions, Dockerfiles, and IaC/Helm values.
- **Safety, Privacy & Atomic Updates:** All comments, docstrings, `Example*` outputs, and module READMEs must strictly comply with the **zero-violence, zero-nudity** policy and contain zero real credentials, DSNs, or PII. Always update doc comments, `doc.go`, `Example*` tests, and `README.md` atomically in the same change whenever code behavior or contracts change. Never silence documentation linters with bare `//nolint`, `//revive:disable`, or `//noinspection` directives.

### 5.3 Context, Concurrency & Resource Management

- Pass `context.Context` as the first parameter of every function performing I/O, RPC, database access, messaging, or structured logging. Never store `context.Context` inside structs.
- Enforce deadlines/timeouts on all outbound gRPC, HTTP, database, and NATS calls.
- Use `golang.org/x/sync/errgroup` (`errgroup.WithContext`) for bounded parallel fan-out (e.g., `sheet-aggregator`), implementing graceful degradation for non-critical attributes.
- Ensure every goroutine has a clear cancellation path and lifetime; close channels from the sender side only.
- Bound CPU/memory-intensive operations (such as Argon2id password hashing) with explicit semaphores or worker pools to prevent OOM/DoS.
- Always close resources (`rows.Close()`, `resp.Body.Close()`, SQLite handles, file descriptors) and handle close errors on write paths.

### 5.4 Error Handling

- Never silently discard errors (`_ = ...` is forbidden unless explicitly justified with a comment for benign cleanup).
- Wrap errors with operation context using `fmt.Errorf("operation: %w", err)` so callers can inspect chains with `errors.Is` and `errors.As`.
- Map domain errors cleanly to gRPC status codes (`codes.InvalidArgument`, `codes.NotFound`, `codes.PermissionDenied`, etc.) or HTTP status codes at service boundaries.
- Never leak secrets, raw SQL/DSN details, or internal stack traces in external API responses or error messages.

### 5.5 Mandatory Shared Platform Libraries (ADRs)

- **Logging (`libs/logging`, ADR-0003):**
  - Use stdlib `log/slog` via `libs/logging` only (do **not** introduce Zap or Zerolog).
  - Always use context-aware methods (`InfoContext`, `WarnContext`, `ErrorContext`) so `trace_id`, `span_id`, `correlation_id`, `user_uuid`, `group_id`, and `character_uuid` are automatically attached.
  - Output JSON to stdout by default; never log PII (emails, passwords, MFA secrets, raw JWTs, DSNs, or raw chat message bodies). Log non-PII `user_uuid`.
- **Observability (`libs/telemetry`, ADR-0004):**
  - Initialize OpenTelemetry once in `main()` via `telemetry.Init(ctx, cfg)` and invoke bounded-timeout `Shutdown(ctx)` on `SIGTERM`/`SIGINT`.
  - Propagate W3C Trace Context and Baggage across Gin (`otelgin`), gRPC (`otelgrpc`), and NATS JetStream headers.
  - Follow metric naming `princesspink_<domain>_<metric>_<unit>`. **Never** use unbounded identifiers (`character_uuid`, `user_uuid`, `group_id`, `ejaculation_id`) as Prometheus labels.
  - Expose `/healthz`, `/readyz`, and internal-only `/metrics` (never exposed through public ingress); export OTLP/gRPC telemetry and serve `/metrics` over **TLS 1.3 / mTLS** in all cloud environments (never `otlptracegrpc.WithInsecure()` in cloud deployments, ADR-0012).
- **gRPC & Protobuf (`libs/proto`, ADR-0005):**
  - Define all internal RPC and NATS event schemas under `libs/proto/` governed by `buf` (`make proto-lint`, `make proto-breaking`, `make proto-gen`).
  - Commit generated Go code under `libs/proto/gen/go/` so standard `go build`/`go test` work without `buf`/`protoc`.
  - Evolve `v1` contracts additively only; reserve removed field names/numbers; introduce `v2` for breaking changes.
  - Use `libs/proto/grpcutil` server/client factories with mandatory **mTLS (TLS 1.3)** in all cloud environments (never `insecure.NewCredentials()` outside explicit `local` dev/test mode, ADR-0012) and register `grpc.health.v1.Health` on every gRPC server.
- **Configuration (`libs/config`, ADR-0006):**
  - Load operational settings via typed `config.Load[T](ctx)` with fail-fast validation before opening listeners—rejecting plaintext/insecure HTTP, gRPC, PostgreSQL (`sslmode != verify-full`), NATS, or OTLP transport settings in all cloud environments (`dev`, `staging`, `prod`, ADR-0012). Do **not** use Viper or scattered `os.Getenv` calls, and do **not** silently load `.env` files in containers.
  - Support `*_FILE` secret indirection (Azure Key Vault CSI / Docker secrets) and wrap sensitive fields in `config.Secret` so `String()`, `MarshalJSON()`, and `LogValue()` always emit `[REDACTED]`.
- **UUIDs (`libs/uuid`, ADR-0007):**
  - Generate all domain, event, outbox, and correlation IDs as RFC 9562 **UUIDv7** via `libs/uuid` (do **not** call `github.com/google/uuid` directly or use UUIDv4).
  - Validate and reject nil/malformed UUIDs at all API/event boundaries.
  - Construct SQLite artifact filenames strictly from validated canonical lowercase UUIDs (`egg_reserve_<uuid>.sqlite`, `ejaculation_<uuid>.sqlite`) to prevent path traversal.
  - **Never** use UUIDs as security secrets (sessions, refresh/reset/CSRF tokens); use `crypto/rand` tokens of at least 256 bits.

### 5.6 Data Storage, Security & Containers

- **Cloud Networking, Private Subnets & End-to-End Encryption (ADR-0012):**
  - **Private / Non-Public Subnets:** All PrincessPink backend services (`website`, `user-admin`, `chat`, `character-sheet`, `simulation`, `messaging`, `observability`)—just like Azure Database for PostgreSQL (`snet-postgresql`), as well as `frontend` pods behind edge ingress—must be deployed exclusively in **private / non-public Azure VNet subnets** with zero public IP addresses and no public `LoadBalancer`/`NodePort` exposure. Only the public edge (`Azure Front Door` / `snet-ingress`) accepts external browser traffic.
  - **1:1 Namespace-to-Subnet Isolation:** Services in the **same Kubernetes namespace** (per `docs/Concept.md` §3.2 High-Level Architecture Diagram) must reside in the **same private subnet** (`snet-frontend`, `snet-website`, `snet-user-admin`, `snet-chat`, `snet-character-sheet`, `snet-simulation`, `snet-messaging`, `snet-observability`), whereas services in **different namespaces** must reside in **different private subnets**—enforced via Azure CNI per-namespace node pools/pod subnets, node taints/placement policies, per-subnet Azure NSGs, and default-deny Kubernetes `NetworkPolicy`. Keep `snet-frontend` strictly isolated from `snet-postgresql`.
  - **Encrypted Cloud Communication Everywhere:** **All communication—external and within the cloud—must be encrypted** (TLS 1.3 / mTLS across ingress-to-frontend, intra- and cross-subnet gRPC, NATS JetStream / Azure Service Bus, PostgreSQL `sslmode=verify-full`, OTLP/Prometheus observability, and Azure Key Vault / ACR / Blob Storage Private Endpoints). Zero plaintext internal hops in `dev`, `staging`, or `prod`.
- **PostgreSQL 18+ (ADR-0001, ADR-0010, ADR-0012):**
  - Use `pgx/v5`, native `uuidv7()`, PostgreSQL 18 `RETURNING OLD, NEW` for atomic audit capture, per-service schemas, and least-privilege DB roles.
  - Deploy in its dedicated delegated private / non-public subnet (`snet-postgresql`) and enforce `sslmode=verify-full` (TLS 1.3) / Microsoft Entra ID in all cloud environments (`dev`, `staging`, `prod`). Do **not** enable `io_uring` on Azure Database for PostgreSQL Flexible Server.
  - Use parameterized queries exclusively (zero SQL string concatenation) and versioned SQL migrations.
  - Pair PostgreSQL state mutations with NATS event publishing via a transactional outbox table.
- **SQLite (Concept, ADR-0008):**
  - Prefer pure-Go SQLite (`modernc.org/sqlite`) to preserve `CGO_ENABLED=0` static builds unless CGo is explicitly justified.
  - Keep scientific reference DBs read-only for stateless horizontal scaling; use WAL + single-writer `StatefulSet` or read-only artifact storage for per-female egg reserves and per-ejaculation cohorts.
- **Authentication & Authorization (ADR-0010):**
  - Hash passwords with `golang.org/x/crypto/argon2` (Argon2id: ≥64 MiB memory, time 3, parallelism ≥2, 16-byte `crypto/rand` salt, 32-byte key), constant-time verification, and dummy hashing on unknown accounts.
  - Issue short-lived (10–15 min) Ed25519 (`EdDSA`) JWTs without PII; deliver refresh tokens in `HttpOnly`, `Secure`, `SameSite=Strict` cookies with rotation and reuse detection.
  - Enforce RBAC (`PLAYER`, `GAME_MASTER`, `SYSTEM_ADMIN`—with mandatory cloud MFA for `SYSTEM_ADMIN` and strict separation of duties from campaign gameplay) and resource/group ownership checks at both gateway and backend services.
- **Containers:** Build static `CGO_ENABLED=0` `-trimpath` binaries targeting non-root `distroless/static` images with read-only root filesystems and dropped Linux capabilities.

---

## 6. Linting, Static Analysis (Including Qodana) & Quality Gates

Always use the root `Makefile` (ADR-0008) to build, lint, scan, and test so local workflows match CI (ADR-0009). Scope any module target to a single service with `SERVICE=<service-name>`.

### 6.1 Required Linters & Analyzers

1. **`gofmt -s`** (`make fmt`, `make fmt-check`) — Enforces canonical Go formatting, simplification, and Go 1.19+ doc comment formatting.
2. **`go vet`** (`make vet`) — Catches suspicious constructs, `printf` mismatches, and lock copying.
3. **`golangci-lint` v2** (`make lint`) — Primary Go meta-linter suite configured in root [`.golangci.yml`](.golangci.yml), enforcing compulsory source code documentation ([ADR-0014](docs/architecture/ADR-0014-compulsory-go-and-open-source-source-code-documentation.md): `godoclint`, `revive` `exported`/`package-comments`/`comment-spacings`, `staticcheck` including `ST1000`/`ST1020`–`ST1022`, `godot`, `testableexamples`, `goheader` SPDX BSD-3-Clause check, `misspell`, `dupword`, and `nolintlint` requiring specific linter + justification) alongside `errcheck`, `govet`, `gosec`, `sloglint`, `spancheck`, `promlinter`, `protogetter`, and `containedctx`.
4. **JetBrains Qodana (`jetbrains/qodana-go`)** (`make qodana`) — **Additional static analysis linter** configured in root [`qodana.yaml`](qodana.yaml) using the `qodana.recommended` Go inspection profile with explicit compulsory Go doc inspections (`GoExportedElementShouldHaveComment`, `GoCommentStart`, `GoCommentLeadingSpace`):
   - Run locally via `make qodana` (or `qodana scan --fail-threshold 0`) when the Qodana CLI is installed, or via JetBrains GoLand (`Tools | Qodana`).
   - Complements `golangci-lint` with deep cross-file GoLand/IDE dataflow, nil-dereference, unused-symbol, concurrency, error-handling, documentation, and dependency-health inspections.
   - Generated Protobuf bindings (`libs/proto/gen`), build binaries (`bin`), and coverage output (`.coverage`) are excluded in `qodana.yaml`.
   - Fix reported Qodana warnings at the root cause; do not suppress inspections with `//noinspection` unless there is a documented, unavoidable false positive.
5. **`go doc`** (`make doc`) — Renders package documentation and verified executable examples (`go doc -all -ex`) across workspace modules (or `SERVICE=<name>`).
6. **`govulncheck`** (`make vuln`) — Scans Go dependencies for reachable known vulnerabilities.
7. **`buf`** (`make proto-lint`, `make proto-breaking`) — Enforces Protobuf `STANDARD` + `COMMENTS` lint rules ([ADR-0005](docs/architecture/ADR-0005-shared-grpc-protobuf-contracts.md), [ADR-0014](docs/architecture/ADR-0014-compulsory-go-and-open-source-source-code-documentation.md)) and backward compatibility against `main`.
8. **`trivy`** (`make docker-scan`) — Scans built container images for `HIGH` and `CRITICAL` vulnerabilities.

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

# Render Go package documentation and executable examples
make doc
make doc SERVICE=user-admin

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
- Keep source code documentation (SPDX headers, `doc.go`, exported Go doc comments, runnable `Example*` tests, module/service `README.md`, `.proto` `COMMENTS`, OpenAPI descriptions, and SQL comments per [ADR-0014](docs/architecture/ADR-0014-compulsory-go-and-open-source-source-code-documentation.md)) synchronized atomically with code changes—never bypass documentation linters with bare `//nolint` or `//noinspection` directives.
- When modifying architecture, contracts, or developer workflows, update the corresponding ADR in `docs/architecture/` or `docs/Concept.md` in the same change.
