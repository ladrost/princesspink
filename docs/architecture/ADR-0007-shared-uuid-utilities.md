# ADR-0007: Shared UUID Utilities Library (`libs/uuid`)

- **Status:** Accepted
- **Date:** 2026-11-22
- **Deciders:** PrincessPink Architecture
- **Related Documents:** [`docs/Concept.md`](../Concept.md), [`README.md`](../../README.md), [`ADR-0001`](ADR-0001-minimum-postgresql-version.md), [`ADR-0002`](ADR-0002-world-chat-microservices-and-server-selection.md), [`ADR-0003`](ADR-0003-shared-logging-library.md)

---

## Context

PrincessPink uses a **UUID-everywhere** identity model across all microservices, databases, and events (Concept §2.1, §2.3, §3.4 & [ADR-0001](ADR-0001-minimum-postgresql-version.md)):

- **Characters:** Every Character receives a globally unique, immutable `UUID` either at conception (`CONCEIVED` → `GESTATING` → `ALIVE` → `DECEASED`) or at parentless character generation via `sim-character-generator` (direct `ALIVE` → `DECEASED` with `mother_uuid = null`, `father_uuid = null`), linking retained/archived per-female Egg-Reserve SQLite databases (`egg_reserve_<character_uuid>.sqlite` hydrated on demand during `REPLAY_IMMUTABLE` reappearances), immutable attribute-change history rows (`CHARACTER_ATTRIBUTE_HISTORY`), `CHARACTER_GENERATION_RECORD` audit rows, and lineage graphs (`mother_uuid`, `father_uuid`).
- **Users, Groups, Ownership, Role-Play & Gamification:** `USER`, `GROUP`, `GROUP_MEMBERSHIP`, `GROUP_CHARACTER_PARTICIPATION`, `CHARACTER_GENERATION_RECORD`, `NPC_OWNERSHIP_CLAIM`, `OWNERSHIP_AGREEMENT`, `PREGNANCY.gestation_cohort_id`, `ROLEPLAY_EVENT`, `PARTNER_BOND`, `CHARACTER_MILESTONE`, `GENETIC_CODEX_ENTRY`, and `GROUP_CHALLENGE` records are keyed by UUID.
- **Chat & Events:** `WORLD_CHAT_SERVER`, `CHAT_CHANNEL`, `CHAT_MESSAGE`, `EJACULATION_DB`, `LIFECYCLE_EVENT`, transactional outbox rows, audit logs, and request `correlation_id` values are UUID-keyed.
- **PostgreSQL 18+ Alignment:** [ADR-0001](ADR-0001-minimum-postgresql-version.md) adopted PostgreSQL 18+ specifically for native RFC 9562 **`uuidv7()`** time-ordered primary keys, improving B-tree index locality and enabling cursor-based pagination on append-heavy tables (`chat.messages`, audit logs, outbox).

If microservices generate UUIDs ad hoc (mixing UUIDv4, UUIDv7, string formatting, or inconsistent validation), services risk fragmented B-tree indexes, broken cursor ordering, accidental nil-UUID persistence, and confusion between public entity IDs and cryptographic secrets.

---

## Decision

PrincessPink establishes a shared Go module **`libs/uuid`** that standardizes on **RFC 9562 UUIDv7** as the default application-generated identifier across all Go microservices, wraps `github.com/google/uuid` with strict validation and serialization helpers, and enforces clear separation between entity UUIDs and cryptographic secrets.

### 1. UUID Version Policy

| Use Case | Standard | Rationale |
| :--- | :--- | :--- |
| **All Domain Entities & Events** (`Character`, `User`, `Group`, `ChatMessage`, `WorldChatServer`, `EjaculationDB`, `RoleplayEvent`, `PartnerBond`, `Milestone`, `CodexEntry`, `GroupChallenge`, `Outbox`, `CorrelationID`) | **RFC 9562 UUIDv7** (`uuid.NewV7()`) | Time-ordered (millisecond timestamp + monotonic/random bits), matches PostgreSQL 18+ native `uuidv7()`, eliminates random B-tree index fragmentation, and supports natural cursor pagination. |
| **Security Secrets, Session Tokens, Refresh Tokens, CSRF Tokens, Password Reset Codes** | **Never UUID** (use `crypto/rand` ≥ 256-bit tokens) | UUIDv7 embeds a millisecond creation timestamp and is not a cryptographic bearer secret. `libs/uuid` explicitly documents this boundary. |
| **Deterministic Tests** | **Seeded / Fixed Test Helpers** (`uuid.MustParse`, `uuid.Deterministic(seed)`) | Supports reproducible fixed-seed simulation cohort tests (`make test-sim`) without flakiness. |

### 2. Library API & Capabilities

`libs/uuid` provides a small, idiomatic Go API backed by `github.com/google/uuid`:

- **Generation:** `New()` / `NewV7()` returning an RFC 9562 UUIDv7 (with monotonic sub-millisecond ordering where supported) and explicit error handling (plus `MustNew()` for initialization/tests only).
- **Strict Parsing & Validation:** `Parse(s string)` and `ParseNonNil(s string)` rejecting malformed strings and rejecting the nil UUID (`00000000-0000-0000-0000-000000000000`) for required entity keys at HTTP/gRPC/NATS boundaries.
- **Typed Domain Identifiers (Optional/Lightweight Helpers):** Provides canonical helper types or validation wrappers (`CharacterID`, `UserID`, `GroupID`, `WorldServerID`, `CorrelationID`) that prevent accidentally swapping a `group_id` and a `user_id` across service boundaries while remaining trivially convertible to `string`, `[16]byte`, `pgtype.UUID`, and Protobuf representations.
- **Persistence & Wire Interoperability:** Implements `database/sql` (`driver.Valuer` / `sql.Scanner`), `pgx` (`pgtype.UUID`), `encoding.TextMarshaler` / `JSON`, SQLite `TEXT`/`BLOB` bindings, and `log/slog.LogValuer` (canonical lowercase hyphenated string).
- **Artifact Filename Safety:** Provides a canonical formatter for SQLite artifact paths (e.g., `egg_reserve_<uuid>.sqlite`, `ejaculation_<uuid>.sqlite`) guaranteeing only validated lowercase RFC 9562 hex/hyphen strings ever enter filesystem or Azure Blob Storage keys (preventing path traversal).

---

## Options Considered

| Option | Description | Evaluation |
| :--- | :--- | :--- |
| **1. Shared `libs/uuid` Standardizing on RFC 9562 UUIDv7 (wrapping `google/uuid`)** | Thin shared module enforcing UUIDv7, non-nil validation, SQL/Protobuf/SQLite adapters, and safe artifact naming. | **Selected.** Full parity with PostgreSQL 18+ native `uuidv7()` ([ADR-0001](ADR-0001-minimum-postgresql-version.md)), standard 128-bit `uuid` column type, minimal dependency footprint, and zero path-traversal risk for SQLite artifact files. |
| **2. UUIDv4 Everywhere** | Generate purely random RFC 4122 UUIDv4 values in Go services. | **Rejected.** Causes B-tree index fragmentation and page splits in append-heavy PostgreSQL tables (`chat.messages`, audit logs, outbox) and breaks time-ordered cursor pagination. |
| **3. ULID / KSUID** | Use non-UUID 128-bit or 160-bit time-ordered identifiers. | **Rejected.** Not natively supported by PostgreSQL's `uuid` type without custom encoding/extensions; diverges from PrincessPink's UUID-everywhere domain specification (Concept §2.1 & §2.3). |
| **4. Direct Ad-Hoc `google/uuid` Usage Without `libs/uuid`** | Let each microservice import and call `google/uuid` directly. | **Rejected.** Risks inconsistent UUIDv4 vs. UUIDv7 usage across 25+ services, duplicated nil-UUID validation, and inconsistent SQLite/Protobuf/PostgreSQL marshaling. |

---

## Rationale & Alignment with PrincessPink Requirements

1. **PostgreSQL 18+ Parity ([ADR-0001](ADR-0001-minimum-postgresql-version.md)):**
   Whether an ID is generated in Go (e.g., `sim-conception` or `sim-character-generator` allocating a new `character_uuid` before persisting to `character-registry`, or `sim-ejaculation` naming an ejaculation SQLite artifact) or in PostgreSQL (`DEFAULT uuidv7()`), every identifier conforms to the exact same RFC 9562 UUIDv7 format.
2. **Safe Per-Character & Per-Ejaculation SQLite Artifact Naming (Concept §5.2):**
   Validating UUIDs through `libs/uuid` before constructing `egg_reserve_<character_uuid>.sqlite` or `ejaculation_<event_uuid>.sqlite` eliminates path-injection vulnerabilities in `sim-egg-reserve`, `sim-egg-selection`, `sim-ejaculation`, and `sim-sperm-race`.
3. **Deterministic Simulation Testing (Concept §4.4 & §7.2):**
   Providing deterministic test UUID helpers lets fixed-seed simulation tests assert exact lineage trees and event sequences reproducibly.

---

## Consequences

### Positive
- Seamless compatibility between Go-generated IDs and PostgreSQL 18+ `uuidv7()` columns, indexes, and cursor pagination.
- Eliminates nil-UUID bugs and parameter-swapping mistakes across 25+ microservices.
- Safe, canonical UUID formatting for SQLite artifact filenames, NATS subjects/headers, and structured logs.

### Trade-offs & Operational Notes
- **Timestamp Visibility:** UUIDv7 encodes a millisecond-precision creation timestamp in its top 48 bits. This is desirable for internal ordering and acceptable for domain entities (`Character`, `ChatMessage`, `Group`), but UUIDv7 must **never** be used as a secret bearer token, session ID, or unguessable invite code.
- **Clock Skew Considerations:** Across horizontally scaled AKS pods, minor wall-clock skew means UUIDv7 provides *approximate* global chronological ordering; strict causal ordering within a simulation group still relies on `sim_tick` from `sim-clock`.
