# ADR-0001: Minimum PostgreSQL Version (PostgreSQL 18+)

- **Status:** Accepted
- **Date:** 2026-11-21
- **Deciders:** PrincessPink Architecture
- **Related Documents:** [`docs/Concept.md`](../Concept.md), [`README.md`](../../README.md)

---

## Context

PrincessPink uses a polyglot persistence architecture in which **Azure Database for PostgreSQL (Flexible Server)** serves as the authoritative central transactional store for:

- `user-admin` (`user_admin.*` schema): Users, `Argon2id` password hashes, MFA secrets, sessions/refresh tokens, groups, RBAC policies, and immutable audit logs.
- `character-registry` (`character_registry.*` schema): Canonical character records (`UUID`, ownership, group scoping, `gender`, `lifecycle_state`, `date_of_birth`, `date_of_death`, `height_cm`, `weight_kg`, GM role-play weight adjustment audit history, `date_of_first_menstruation`, `menstruation_dates`, Egg-Reserve SQLite DB links, parental lineage, and immutable diploid genome references).
- `chat-service` (`chat.*` schema): Global, Group, and 1-to-1 Direct Message channels, cursor-paginated message history, read markers, mute/block lists, and moderation audit logs.
- `sim-clock` and transactional outbox tables used to guarantee atomic state commits and event bus publication.

PrincessPink is currently a greenfield project (**Phase 0 / Architectural Foundation**) already targeting a modern toolchain (**Go 1.27+**). We need to establish a clear **minimum PostgreSQL major version** that:

1. Is **Generally Available (GA)** across all public regions on **Azure Database for PostgreSQL Flexible Server**.
2. Provides a multi-year upstream community security support runway so Phase 1–5 development and production operation do not face an immediate forced major-version upgrade.
3. Directly supports PrincessPink's domain, performance, and security requirements without unnecessary third-party extensions.

---

## Decision

The minimum required PostgreSQL version for PrincessPink is **PostgreSQL 18 (`18+`)** across all environments:

- **Production & Staging:** Azure Database for PostgreSQL Flexible Server running **PostgreSQL 18** (or a newer GA major version).
- **Local Development & CI:** Docker Compose stacks and Testcontainers integration tests targeting **PostgreSQL 18** (e.g., `postgres:18` / `postgres:18-alpine`).

---

## Options Considered

Status verified as of **November 2026** against the PostgreSQL community versioning policy and Azure Database for PostgreSQL Flexible Server supported versions:

| Major Version | Community EOL | Azure Flexible Server Status | Evaluation |
| :--- | :--- | :--- | :--- |
| **PostgreSQL 14** (and older) | 12 Nov 2026 *(EOL)* | Legacy / Extended Support | **Rejected.** Already end-of-life upstream; unsuitable for a new project. |
| **PostgreSQL 15** | 11 Nov 2027 | GA | **Rejected.** Less than 1 year of community support remaining; would force an upgrade before or shortly after production launch. |
| **PostgreSQL 16** | 9 Nov 2028 | GA | **Rejected.** Only ~2 years of runway; lacks PG 17 SQL/JSON (`JSON_TABLE`) and PG 18 native `uuidv7()`, `RETURNING OLD/NEW`, B-tree skip scans, AIO, and OAuth 2.0. |
| **PostgreSQL 17** | 8 Nov 2029 | GA | **Viable fallback, not chosen.** Mature and GA on Azure with ~3 years of runway and strong JSON/vacuum improvements, but lacks PG 18's native `uuidv7()`, `RETURNING OLD/NEW`, B-tree skip scans, asynchronous I/O, and OAuth 2.0 support—with no legacy constraint preventing adoption of PG 18. |
| **PostgreSQL 18** | **14 Nov 2030** | **GA (all public regions)** | **Selected.** Mature release (18.6+), GA across all Azure public regions with Major Version Upgrade (MVU), Microsoft Entra ID authentication, and Terraform support, ~4 years of community support runway, and strong feature alignment. |
| **PostgreSQL 19** | ~Nov 2031 | Preview *(East Asia only, launched 19 Nov 2026)* | **Not yet eligible as minimum.** Just released upstream and only available in single-region Preview on Azure Flexible Server; cannot be required for production yet. |

---

## Rationale & Alignment with PrincessPink Requirements

1. **UUID-Everywhere Data Model & Cursor Pagination (`uuidv7()`):**
   Every core entity (`USER`, `GROUP`, `CHARACTER`, `CHAT_CHANNEL`, `CHAT_MESSAGE`, `MENSTRUATION_CYCLE`, `LIFECYCLE_EVENT`, outbox entries, and audit logs) uses `UUID` primary keys. PostgreSQL 18 introduces native RFC 9562 **`uuidv7()`** in core without requiring external extensions. Time-ordered UUIDv7 keys dramatically improve B-tree index locality, reduce page splits on append-heavy tables (`chat.*` messages, audit logs, outbox), and simplify cursor-based pagination.
2. **State-of-the-Art Security Posture (Concept §4.2 & §6.2):**
   PostgreSQL 18 aligns with PrincessPink's security requirements: MD5 authentication is deprecated in favor of `SCRAM-SHA-256`, native OAuth 2.0 authentication is supported, TLS 1.3 cipher handling is hardened, and data checksums are enabled by default. On Azure Flexible Server, PostgreSQL 18 has full GA support for Microsoft Entra ID authentication and private VNet integration.
3. **Audit Logging, Outbox & Composite Query Performance:**
   - `OLD` / `NEW` support in `RETURNING` clauses enables atomic before/after capture for immutable audit trails (`user_admin.*`, `chat.*`) in a single round trip.
   - **B-tree skip scans** improve query efficiency on composite indexes (e.g., `(group_id, sent_at)` or `(channel_id, id)`).
   - **Asynchronous I/O (`AIO`)** improves read, bitmap scan, and `VACUUM` throughput for growing population and chat histories.
4. **JSONB & Simulation Configuration (`GROUP.simulation_config`):**
   Retains and builds upon PostgreSQL 17's standard SQL/JSON functions (`JSON_TABLE`, `JSON_VALUE`, `JSON_QUERY`, `JSON_EXISTS`) for querying and validating structured `jsonb` configuration and event payloads.
5. **Long Support Runway on Azure:**
   With community support through **14 November 2030** and GA availability across all Azure public regions, PostgreSQL 18 avoids early upgrade churn while keeping a clean Major Version Upgrade (MVU) path to PostgreSQL 19+ once it reaches GA.

---

## Consequences

### Positive
- Single modern baseline (`PostgreSQL 18+`) aligned with `Go 1.27+` across local dev, CI, and Azure AKS production.
- Zero reliance on third-party extensions for time-ordered UUIDs (`uuidv7()`).
- Nearly four years of upstream security support before the next mandatory major-version upgrade.

### Trade-offs & Operational Notes
- **Azure Flexible Server AIO Limitation:** On Azure Database for PostgreSQL Flexible Server, `io_method = io_uring` is not available; services must rely on the default `worker` I/O method and must not hardcode `io_uring` in database configuration or migrations.
- **Developer Environment Alignment:** Contributors running PostgreSQL locally without Docker must install **PostgreSQL 18+** (Docker Compose with `postgres:18-alpine` is recommended to guarantee parity).
- **Future Upgrades:** Once PostgreSQL 19 (or later) reaches General Availability on Azure Database for PostgreSQL Flexible Server across target regions, the minimum or recommended target version may be revisited in a superseding ADR using Azure's in-place Major Version Upgrade (MVU).
