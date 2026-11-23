# PrincessPink

[![License: BSD-3-Clause](https://img.shields.io/badge/License-BSD_3--Clause-blue.svg)](LICENSE)
[![Go Version](https://img.shields.io/badge/Go-1.27.4+-00ADD8?logo=go&logoColor=white)](go.work)
[![Status](https://img.shields.io/badge/Status-Concept%20%26%20Architecture-informational)](docs/Concept.md)
[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-2.0-4baaaa.svg)](CODE_OF_CONDUCT.md)

**PrincessPink** is an open-source, scientific, population-level simulation of human reproduction and generational lineage presented through a pen-and-paper role-playing game (RPG) interface. Inspired by classic tabletop character sheets (such as AD&D), it gamifies human biology, genetics, and family trees while visualizing each character with a deterministically generated comic-style face portrait.

---

## Table of Contents

- [Content & Safety Policy](#content--safety-policy)
- [Key Features](#key-features)
- [Architecture at a Glance](#architecture-at-a-glance)
- [Repository Structure](#repository-structure)
- [Getting Started](#getting-started)
- [Project Status & Roadmap](#project-status--roadmap)
- [Documentation](#documentation)
- [Contributing](#contributing)
- [Code of Conduct](#code-of-conduct)
- [Security](#security)
- [License](#license)

---

## Content & Safety Policy

PrincessPink enforces a strict, non-negotiable **zero-violence, zero-nudity** policy:

- **No violence or gore:** Unlike combat-oriented RPGs, there are no weapons, battles, injury graphics, or violent mechanics. Characters live and pass away strictly through natural biological lifecycles.
- **No nudity or explicit content:** Human reproduction is modeled purely through abstract scientific data, biological state transitions, and tabletop-style attributes and events—never through explicit text, imagery, or adult themes.
- **Safe-by-design visuals:** Visual representation is strictly limited to stylized **comic-art face portraits** (head and shoulders) derived deterministically from a character's phenotypic traits and age stage, with no free-form image uploads.

---

## Key Features

- **Pen-and-Paper Character Sheets, Physical & Medical Body Composition:** Tabletop-inspired sheets displaying identity, lineage, immutable Mendelian **Blood Type** (`A+`, `A-`, `B+`, `B-`, `AB+`, `AB-`, `O+`, `O-`), a comic-style face portrait, visible appearance traits (`eye_color`, `hair_color`, `skin_color`) anchored in DNA that evolve naturally after birth and across life stages, and physical measurements (`height_cm`, `weight_kg`) together with derived medical body-composition metrics (**BMI**, Body Fat Index/Percentage, Lean Body Mass, Skeletal Muscle Mass, Total Body Water, Bone Mass, Visceral Fat Rating, Basal Metabolic Rate, Body Surface Area, and Ideal Weight Range).
- **Lifecycle & Role-Play Health Indicators:** Dynamic clinical health and fitness indicators simulated across every character's lifecycle (`sim-health`) and influenced by role-play (Player lifestyle/training routines and bounded Game Master adjustments)—including **Heart Health** (`ILL`, `HEALTHY_NOT_SPORTY`, `HEALTHY_NORMAL`, `HEALTHY_SPORTY`), **Waking Heart Rate** (`waking_heart_rate_bpm`, resting morning heart rate shortly after waking up across infancy, adulthood, pregnancy, and old age), **Muscles / Muscular Conditioning** (`WEAK`, `NORMAL`, `SPORTY`, `BODY_BUILDER`), **Blood Pressure**, **Respiratory / Aerobic Health (`VO2 max`)**, **Metabolic Health**, **Immune Health**, **Sleep & Recovery Quality**, and **Stress & Allostatic Load**—directly influencing body composition, intercourse & fertility values, reproduction attributes, fertility/menstruation, spermatogenesis/erection quality, gestation resilience, and natural mortality.
- **Intercourse & Fertility Values:** Abstract, clinical, zero-nudity reproductive parameters (`CHARACTER_INTERCOURSE_PROFILE`) tracked across every character's lifecycle and reflected on gender-filtered character sheets (`attr-*`) and throughout the simulation—including **Fertility (`fertility_score`, `0–100`)** shaped by age, gender, health, and body composition (strictly `0` for females before first ovulation and upon climacterium with young women more fertile than older women; strictly `0` for pre-pubertal boys, rising from teenage onset to a peak around age 21 and declining slowly thereafter), male **Quality of Erection (`erection_quality`)**, **Quality of Ejaculation (`ejaculation_quality`)**, and **Refractory Period (`refractory_period_minutes`)**, female **Vaginismus (`vaginismus`, boolean)** influencing role-play and penetrative attempt completion, **Lubrication Quality (`lubrication_quality`)**, and **Climacterium State (`climacterium_state`)**, plus universal **Libido (`libido_score`)** and **Intercourse Stamina (`intercourse_stamina`)**.
- **6 AD&D-Style Reproduction Attributes:** Every character sheet features six numeric tabletop stats (e.g., `3–18` scale with derived modifiers) that directly influence reproduction attempts: **Fertility (`FER`)**, **Constitution (`CON`)**, **Vitality (`VIT`)**, **Hormonal Balance (`HOR`)**, **Receptivity (`REC`)**, and **Compatibility (`COM`)**.
- **Permanent Character Lifecycle:** Every character receives a globally unique, immutable `UUID` at conception and is tracked across its entire existence (`CONCEIVED` → `GESTATING` → `ALIVE` → `DECEASED`) with `gender`, immutable `blood_type`, `date_of_birth`, `date_of_death`, and parental lineage.
- **Gender-Specific Biological & Gamete Simulation:**
  - *Female characters:* At birth, `sim-egg-reserve` generates the character's lifetime supply of oocytes into a dedicated **per-female Egg-Reserve SQLite database** linked to her `character_uuid`. After menarche (`sim-menarche`), `sim-egg-selection` selects the ovulated egg cell each cycle alongside full `menstruation_dates` tracking.
  - *Male characters:* Models spermatogenesis and builds a dedicated **per-ejaculation SQLite database** (`sim-ejaculation`) of simulated sperm cells, each with its own haploid DNA, motility, morphology, viability, and surface ligand profile.
- **Role-Play Medical Drugs (Gender-Filtered Checkboxes):** Players can toggle gender-eligible medical drugs directly on their character sheet by clicking the checkbox in front of each available drug—**Viagra** (male) increases erection quality and the chance of one or more ejaculations within a day (with progressive ejaculation quality decrease for consecutive ejaculations within a short period of time), while the **Contraception Pill** (female) influences the menstruation period and substantially reduces the chance of conceiving a baby.
- **Gamete-Level DNA & Surface-Compatibility Fertilization:** Both egg cells and sperm cells carry individual haploid DNA derived via simulated meiosis (crossover, recombination, independent assortment, and rare mutations). During fertilization, `sim-sperm-race` and `sim-gamete-surface` evaluate both arrival order and molecular receptor–ligand fit—the fastest sperm cell does not automatically win if its surface does not fit. Upon fusion, `sim-dna` combines maternal and paternal haploid DNA into the child's immutable 23-pair diploid genome (`XX` or `XY`) and Mendelian ABO + RhD `blood_type` (which further informs maternal-fetal Rh/ABO compatibility in `sim-gestation` / `sim-birth-date`, cardiovascular and immune baselines in `sim-health`, and natural mortality curves in `sim-mortality`).
- **Real-Time RPG Chat:** Built-in WebSocket chat (`frontend-chat` + `chat-service` + `chat-world-registry`) supporting World of Warcraft-style **Global / World Chat** with player-selectable World Chat Servers (by language, region, category, and population), private **Group Chat** (Game Master and Group members), and **1-to-1 Direct Messages** between Players, with moderation and zero-violence/zero-nudity content filtering (see [ADR-0002](docs/architecture/ADR-0002-world-chat-microservices-and-server-selection.md)).
- **Players, Game Masters, Groups & Child Ownership:** Role-based access control where **Players** may own multiple characters in their personal roster, but play **only one character per group**—selected from the characters they already own at the start of the group. Children conceived or born during a simulation start as **NPCs** until the players of the mother and father reach an agreement on who takes ownership; even once owned, children remain NPCs in their parents' group and can only be played in a **future group**. **Game Masters** oversee simulation groups, initialize each group's simulation with a mandatory start date (`dd/MM/YYYY`, starting at `0:00 h`), adjust the per-group simulation tick speed (default: **1 simulated year = 24 hours real time**), stop and resume the simulation tick whenever role-play needs it, inspect group characters and NPCs, adjust character `weight_kg` within configured role-play/biological bounds (with audit logging), and moderate Group Chat.
- **Modular Microservices with Independent Versioning:** Each character sheet attribute (`attr-*`) and biological subsystem (`sim-*`) is designed as an independently versioned Go microservice (`VERSION` file, scoped Git tags, and versioned event traceability) for scientific clarity and reproducibility.

---

## Architecture at a Glance

| Layer | Technology / Approach |
| :--- | :--- |
| **Language & Workspace** | Go 1.27+ (`go.work` multi-module workspace, `toolchain go1.27.4`, independent semantic versioning per service) |
| **Frontend Microservices** | Go + **Gin** HTTP framework (`frontend-gateway`, `frontend-sheets`, `frontend-gm`, `frontend-chat`, `portrait-renderer`) with server-rendered HTML/HTMX and authenticated WebSockets (`wss://`) |
| **Internal Communication** | **gRPC / Protocol Buffers** (`pkg/proto`, [ADR-0005](docs/architecture/ADR-0005-shared-grpc-protobuf-contracts.md)) for synchronous RPC & parallel attribute fan-out; **NATS JetStream** (or Azure Service Bus) for simulation ticks, lifecycle events, and chat pub/sub |
| **User Administration & Security** | `user-admin` backed by **PostgreSQL 18+** with `Argon2id` password hashing, MFA (TOTP / WebAuthn), RBAC (`PLAYER` / `GAME_MASTER`), TLS 1.3 / mTLS, and immutable audit logging ([ADR-0010](docs/architecture/ADR-0010-user-admin-auth-rbac-and-group-management.md)) |
| **Character Sheet & Attributes** | `character-registry`, `sheet-aggregator` (concurrent `errgroup` fan-out with graceful degradation and tick-based caching), and dedicated `attr-*` microservices |
| **Simulation & Genetics Engine** | Event-driven Go microservices (`sim-clock`, `sim-egg-reserve`, `sim-egg-selection`, `sim-menarche`, `sim-menstruation`, `sim-ejaculation`, `sim-sperm-race`, `sim-gamete-surface`, `sim-conception`, `sim-dna`, `sim-birth-date`, `sim-gestation`, `sim-health`, `sim-mortality`, `sim-lifecycle`) using **SQLite** for scientific reference data, per-female egg-reserve databases, and per-ejaculation sperm-cell artifacts |
| **Real-Time Chat** | `frontend-chat` + `chat-service` + `chat-world-registry` with player-selectable World Chat Servers (`chat.world.<world_server_id>`), PostgreSQL 18+ persistence (`chat.*` schema), NATS JetStream fan-out, rate limiting, and content-policy moderation ([ADR-0002](docs/architecture/ADR-0002-world-chat-microservices-and-server-selection.md)) |
| **Observability & Quality** | **OpenTelemetry** tracing ([ADR-0004](docs/architecture/ADR-0004-shared-opentelemetry-observability.md)), `log/slog` structured JSON logging ([ADR-0003](docs/architecture/ADR-0003-shared-logging-library.md)), Prometheus metrics, deterministic fixed-seed simulation tests, `golangci-lint`, `govulncheck`, and Trivy container scanning (`Makefile` [ADR-0008](docs/architecture/ADR-0008-multi-module-makefile-build-automation.md) & GitHub Actions [ADR-0009](docs/architecture/ADR-0009-github-actions-ci-cd.md)) |
| **Deployment Target** | Hardened non-root `distroless/static` containers on **Microsoft Azure Kubernetes Service (AKS)** with Azure Database for PostgreSQL Flexible Server (18+), ACR, and Key Vault |

For full entity-relationship models, architecture diagrams, SQLite deployment patterns, and service catalogs, see the [Technical Concept](docs/Concept.md).

---

## Repository Structure

```text
princesspink/
├── .github/
│   └── workflows/          # CI/CD pipelines (lint, test, security scan, container build & deploy)
├── docs/
│   ├── Concept.md          # Comprehensive technical concept & architecture specification
│   ├── api/                # OpenAPI & Protobuf API specifications
│   ├── architecture/       # Architecture Decision Records (ADRs) & infrastructure specs
│   └── runbooks/           # Operational & incident response runbooks
├── pkg/                    # Shared Go libraries (gRPC/Protobuf contracts, auth middleware, telemetry, helpers)
├── services/               # Independently deployable and versioned Go microservices
├── CODE_OF_CONDUCT.md      # Contributor Covenant Code of Conduct (v2.0)
├── LICENSE                 # BSD 3-Clause License
├── Makefile                # Multi-module build, test, lint, Protobuf, versioning, and container targets
├── README.md               # Project overview and developer entry point
└── go.work                 # Go multi-module workspace definition
```

---

## Getting Started

### Prerequisites

- [Go](https://go.dev/) 1.27+ (`toolchain go1.27.4` in `go.work`)
- [Git](https://git-scm.com/)
- GNU `make`
- *(Optional / for upcoming service builds and local stacks)* [Docker](https://www.docker.com/) (with Compose), [PostgreSQL](https://www.postgresql.org/) 18+ (see [ADR-0001](docs/architecture/ADR-0001-minimum-postgresql-version.md)), `kubectl`, and [Trivy](https://trivy.dev/)

### Clone the Repository

```bash
git clone https://github.com/ladrost/princesspink.git
cd princesspink
```

### Developer Workflow (`Makefile`)

The repository provides a multi-module `Makefile` (see [ADR-0008](docs/architecture/ADR-0008-multi-module-makefile-build-automation.md)) supporting workspace-wide commands as well as single-service scoping via `SERVICE=<service-name>`:

```bash
# List all available targets and examples
make help

# Install Go developer tooling (golangci-lint, govulncheck, buf)
make tools

# Run the full CI quality gate (fmt-check, vet, lint, test-race, vuln)
make check

# Build, test, or version a single microservice (once services are added under services/)
make build SERVICE=sim-gamete-surface
make test-race SERVICE=user-admin
make test-sim
make versions
```

> **Note:** PrincessPink is currently in the **concept and architectural foundation** stage—no microservice implementations have been committed under `pkg/` or `services/` yet. Start by reading [`docs/Concept.md`](docs/Concept.md) to explore the domain model, service boundaries, and implementation plan.

---

## Project Status & Roadmap

PrincessPink is currently in **Phase 0 / Architectural Foundation**. Planned implementation phases (detailed in [docs/Concept.md](docs/Concept.md#9-phased-implementation-roadmap)):

1. **Phase 1 — Platform Foundation:** Shared `pkg/` libraries (logging [ADR-0003](docs/architecture/ADR-0003-shared-logging-library.md), OpenTelemetry [ADR-0004](docs/architecture/ADR-0004-shared-opentelemetry-observability.md), gRPC contracts [ADR-0005](docs/architecture/ADR-0005-shared-grpc-protobuf-contracts.md), config [ADR-0006](docs/architecture/ADR-0006-shared-configuration-library.md), UUID utilities [ADR-0007](docs/architecture/ADR-0007-shared-uuid-utilities.md)), `Makefile` ([ADR-0008](docs/architecture/ADR-0008-multi-module-makefile-build-automation.md)), GitHub Actions CI ([ADR-0009](docs/architecture/ADR-0009-github-actions-ci-cd.md)), and `user-admin` with PostgreSQL, Argon2id auth, RBAC, and Group management ([ADR-0010](docs/architecture/ADR-0010-user-admin-auth-rbac-and-group-management.md)).
2. **Phase 2 — Character Sheet, Chat & Frontend MVP:** `frontend-gateway`, `frontend-sheets`, `frontend-gm`, `frontend-chat`, `chat-service`, `chat-world-registry` (player-selectable World Chat Servers, Group Chat, and 1-to-1 Direct Messages), `character-registry`, `sheet-aggregator`, initial `attr-*` microservices, and `portrait-renderer`.
3. **Phase 3 — Core Reproduction Simulation Pipeline:** `sim-clock`, `sim-egg-reserve`, `sim-egg-selection`, `sim-menarche`, `sim-menstruation`, `sim-ejaculation`, `sim-sperm-race`, `sim-gamete-surface`, `sim-conception`, and `sim-dna` with SQLite stores, event bus integration, and fixed-seed cohort tests.
4. **Phase 4 — Full Lifecycle & Population Features:** `sim-birth-date`, `sim-gestation`, `sim-health`, `sim-mortality`, `sim-lifecycle`, multi-generational family trees, and Game Master population analytics.
5. **Phase 5 — Production Hardening on Azure AKS:** Full Helm/Kustomize manifests, Azure PostgreSQL, Key Vault, `NetworkPolicy`, HPA, observability dashboards, security audit, and operational runbooks.

---

## Documentation

- **[Technical Concept (`docs/Concept.md`)](docs/Concept.md)** — Full domain model, ER & sequence diagrams, character lifecycle, gamete DNA & SQLite architecture, microservice catalog, chat design, Azure AKS topology, and glossary.
- **[API Specifications (`docs/api/`)](docs/api/)** — OpenAPI and Protobuf contract documentation (planned).
- **[Architecture Docs (`docs/architecture/`)](docs/architecture/)** — Architecture Decision Records (ADRs) and infrastructure specifications:
  - [ADR-0001: Minimum PostgreSQL Version (PostgreSQL 18+)](docs/architecture/ADR-0001-minimum-postgresql-version.md)
  - [ADR-0002: World Chat in a Microservice Environment & Player World Chat Server Selection](docs/architecture/ADR-0002-world-chat-microservices-and-server-selection.md)
  - [ADR-0003: Shared Structured Logging Library (`pkg/logging`)](docs/architecture/ADR-0003-shared-logging-library.md)
  - [ADR-0004: Shared OpenTelemetry & Observability Library (`pkg/telemetry`)](docs/architecture/ADR-0004-shared-opentelemetry-observability.md)
  - [ADR-0005: Shared gRPC & Protocol Buffers Contracts (`pkg/proto`)](docs/architecture/ADR-0005-shared-grpc-protobuf-contracts.md)
  - [ADR-0006: Shared Configuration Library (`pkg/config`)](docs/architecture/ADR-0006-shared-configuration-library.md)
  - [ADR-0007: Shared UUID Utilities Library (`pkg/uuid`)](docs/architecture/ADR-0007-shared-uuid-utilities.md)
  - [ADR-0008: Multi-Module Developer Workflow & Build Automation (`Makefile`)](docs/architecture/ADR-0008-multi-module-makefile-build-automation.md)
  - [ADR-0009: GitHub Actions CI/CD Architecture (`.github/workflows/`)](docs/architecture/ADR-0009-github-actions-ci-cd.md)
  - [ADR-0010: User Administration Service (`user-admin`) — PostgreSQL 18+, Argon2id Auth, Player/GM RBAC & Group Management](docs/architecture/ADR-0010-user-admin-auth-rbac-and-group-management.md)
- **[Operational Runbooks (`docs/runbooks/`)](docs/runbooks/)** — Deployment, backup, and incident response runbooks (planned).

---

## Contributing

Contributions, architectural feedback, and scientific modeling discussions are welcome!

1. Read the [Technical Concept](docs/Concept.md), the [Content & Safety Policy](#content--safety-policy), and our [Code of Conduct](CODE_OF_CONDUCT.md).
2. Open an issue to discuss bugs, scientific modeling proposals, or architectural changes before submitting large pull requests.
3. Fork the repository, create a feature branch, and ensure `make check` passes for any Go changes.
4. Submit a pull request with a clear description, rationale, and relevant unit or deterministic simulation tests.

All contributions must strictly respect the project's **zero-violence, zero-nudity** principles.

---

## Code of Conduct

This project adheres to the Contributor Covenant Code of Conduct (version 2.0). By participating, you are expected to uphold this code. Please see [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) for details.

---

## Security

PrincessPink is designed with security in mind (`Argon2id`, MFA, RBAC, TLS 1.3/mTLS, `govulncheck`, and Trivy image scanning—see [docs/Concept.md](docs/Concept.md#42-user-administration--security-service) and [ADR-0010](docs/architecture/ADR-0010-user-admin-auth-rbac-and-group-management.md)).

If you discover a security vulnerability, please **do not** open a public issue. Instead, report it privately to the project maintainers (e.g., via GitHub Security Advisories) with sufficient detail to reproduce and assess the issue.

---

## License

This project is licensed under the **BSD 3-Clause License** — see the [LICENSE](LICENSE) file for details.