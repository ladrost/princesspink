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
- **Permanent Character Lifecycle & Immutable Life History (`CHARACTER_ATTRIBUTE_HISTORY`):** Every character receives a globally unique, immutable `UUID` at conception—or at parentless character generation—and is tracked across its entire existence (`CONCEIVED` → `GESTATING` → `ALIVE` → `DECEASED`, including natural prenatal loss `CONCEIVED`/`GESTATING` → `DECEASED` when enabled, or direct `ALIVE` → `DECEASED` for parentless founders) with `creation_source`, `gender`, immutable `blood_type`, `date_of_birth`, `date_of_death`, and parental lineage (null for generation-`0` founders). **All dynamic attribute changes across a character's life are stored immutably** so the character may **reappear in any new Group running during their living lifetime (`[date_of_birth, date_of_death)`)**. Once a character's attribute changes have happened and their life has been simulated once (`life_simulation_status == COMPLETED`), stored attributes can never change again—the **only** things an already-simulated character (`REPLAY_IMMUTABLE`) may do are participate in new simulations and have **additional children**, with **female characters strictly restricted to periods allowed biologically by their finished life simulation** (alive with projected birth `< date_of_death`, post-ovulation and pre-climacterium, stored `fertility_score > 0`, non-overlapping with any recorded pregnancy or recovery period including forward lookahead, consistent with stored cycle/contraception state, and with an unfertilized oocyte available in her retained Egg-Reserve DB).
- **Parentless Character Generation (`sim-character-generator`) & NPC Ownership Takeover (`NPC_OWNERSHIP_CLAIM`):** Generates biologically complete, genetically valid generation-`0` characters without parents in the system (`mother_uuid = null`, `father_uuid = null`)—with synthesized immutable diploid DNA (`sim-dna`), `gender`, Mendelian ABO + RhD `blood_type`, age-consistent health/body-composition/intercourse baselines, age-adjusted female Egg-Reserve SQLite databases & menstrual/climacterium state, and conditional natural mortality (`date_of_death > T_sim`)—across four audited pathways: **system bootstrap seeding** (`SYSTEM_SEED`), **Game Master role-play NPC generation** (`GM_NPC`), and **Player character generation** either to **start a new family** (`PLAYER_NEW_FAMILY`) or to **join a Group when they do not own an eligible character alive in the time period shown by the Group's simulation clock** (`PLAYER_GROUP_JOIN`). Alternatively, when a Player has no owned character alive during a Group's simulated period, they may **take permanent ownership of an eligible unowned NPC within the system** (`NPC_OWNERSHIP_CLAIM`).
- **Prenatal Loss & Pregnancy Outcomes (`sim-prenatal-loss`):** Models natural, non-graphic prenatal pregnancy loss before birth (`PRE_IMPLANTATION_LOSS`, `EARLY_MISCARRIAGE`, `LATE_MISCARRIAGE`, `STILLBIRTH`) in a dedicated, independently versioned microservice using available PrincessPink data—diploid genetic/chromosomal viability, egg & sperm quality (including short-interval ejaculation decay), maternal & paternal age and perimenopausal reserve, maternal-fetal RhD sensitization (`rh_sensitized`) & non-`O` vascular predisposition, maternal health & body-composition indicators, reproduction attributes (`CON`, `HOR`, `REC`, `VIT`, `FER`), prior obstetric history, breakthrough contraception, and post-term timing—strictly upholding the zero-violence, zero-nudity policy. Enabled by default and configurable per Group in `GROUP.simulation_config` (`prenatal_loss.enabled`, `prenatal_care_tier` / RhIg prophylaxis, bounded `risk_multiplier`, and `track_pre_implantation_loss`), with automatic pending `OWNERSHIP_AGREEMENT` closure (`CLOSED_PRENATAL_LOSS`) and stage-proportional maternal health and cycle recovery.
- **Gender-Specific Biological & Gamete Simulation:**
  - *Female characters:* At birth (or upon parentless female character generation with age-adjusted atresia), `sim-egg-reserve` generates the character's supply of oocytes into a dedicated **per-female Egg-Reserve SQLite database** linked to her `character_uuid` (retained/archived rather than permanently deleted on menopause or death so already-simulated females can still supply unfertilized oocytes during valid reappearance windows). After menarche (`sim-menarche`), `sim-egg-selection` selects the ovulated egg cell each cycle alongside full `menstruation_dates` tracking.
  - *Male characters:* Models spermatogenesis and builds a dedicated **per-ejaculation SQLite database** (`sim-ejaculation`) of simulated sperm cells, each with its own haploid DNA, motility, morphology, viability, and surface ligand profile.
- **Role-Play Medical Drugs (Gender-Filtered Checkboxes):** Players can toggle gender-eligible medical drugs directly on their character sheet by clicking the checkbox in front of each available drug—**Viagra** (male) increases erection quality and the chance of one or more ejaculations within a day (with progressive ejaculation quality decrease for consecutive ejaculations within a short period of time), while the **Contraception Pill** (female) influences the menstruation period and substantially reduces the chance of conceiving a baby.
- **Gamete-Level DNA & Surface-Compatibility Fertilization:** Both egg cells and sperm cells carry individual haploid DNA derived via simulated meiosis (crossover, recombination, independent assortment, and rare mutations). During fertilization, `sim-sperm-race` and `sim-gamete-surface` evaluate both arrival order and molecular receptor–ligand fit—the fastest sperm cell does not automatically win if its surface does not fit. Upon fusion, `sim-dna` combines maternal and paternal haploid DNA into the child's immutable 23-pair diploid genome (`XX` or `XY`) and Mendelian ABO + RhD `blood_type` (which further informs maternal-fetal Rh/ABO compatibility in `sim-gestation` / `sim-birth-date`, cardiovascular and immune baselines in `sim-health`, and natural mortality curves in `sim-mortality`).
- **Real-Time RPG Chat:** Built-in WebSocket chat (`frontend-chat` + `chat-service` + `chat-world-registry`) supporting World of Warcraft-style **Global / World Chat** with player-selectable World Chat Servers (by language, region, category, and population), private **Group Chat** (Game Master and Group members), and **1-to-1 Direct Messages** between Players, with moderation and zero-violence/zero-nudity content filtering (see [ADR-0002](docs/architecture/ADR-0002-world-chat-microservices-and-server-selection.md)).
- **Players, Game Masters, Groups, Reappearance Activation & Child/NPC Ownership:** Role-based access control where **Players** may own multiple characters in their personal roster, decide exclusively whether any of their owned characters becomes active again in a new Group, and play **only one character per group**—strictly selected from owned characters **alive during the time period the Group simulates** (`date_of_birth IS NOT NULL`, `date_of_birth <= T_sim`, `date_of_death IS NULL OR T_sim < date_of_death`, non-child-in-origin-group—including already-simulated owned characters reappearing in `REPLAY_IMMUTABLE` mode). If a Player has **no owned character alive during that Group's simulated time period**, the Player must either **generate a new parentless founder character** (`PLAYER_GROUP_JOIN`) or **take ownership of an eligible unowned NPC within the system** (`NPC_OWNERSHIP_CLAIM`). Children conceived or born during a simulation start as **NPCs** until parental ownership is agreed (and even once owned, remain NPCs in their origin group, playable only in a **future group**). **Game Masters** oversee simulation groups, generate bounded parentless **role-play NPCs** (`GM_NPC`) or **activate existing unowned characters (`owner_user_id = null`, alive at `T_sim`) as NPCs** in their managed group(s) (never Player-owned characters), initialize each group's simulation with a mandatory start date (`dd/MM/YYYY`, starting at `0:00 h`), adjust the per-group simulation tick speed (default: **1 simulated year = 24 hours real time**), stop and resume the simulation tick whenever role-play needs it, inspect group characters and NPCs, adjust character `weight_kg` and health indicators strictly for `LIVE_PRIMARY` characters within configured bounds (never for already-simulated `REPLAY_IMMUTABLE` characters; with audit logging), and moderate Group Chat.
- **Modular Microservices with Independent Versioning:** Each character sheet attribute (`attr-*`) and biological subsystem (`sim-*`) is designed as an independently versioned Go microservice (`VERSION` file, scoped Git tags, and versioned event traceability) for scientific clarity and reproducibility.

---

## Architecture at a Glance

| Layer | Technology / Approach |
| :--- | :--- |
| **Language & Workspace** | Go 1.27+ as sole programming language (`go.work` multi-module workspace, `toolchain go1.27.4`, independent semantic versioning per service; [ADR-0011](docs/architecture/ADR-0011-go-as-sole-programming-language.md)) |
| **Frontend Microservices** | Go + **Gin** HTTP framework (`frontend-gateway`, `frontend-sheets`, `frontend-gm`, `frontend-chat`, `portrait-renderer`) with server-rendered HTML/HTMX and authenticated WebSockets (`wss://`) |
| **Internal Communication** | **gRPC / Protocol Buffers** (`libs/proto`, [ADR-0005](docs/architecture/ADR-0005-shared-grpc-protobuf-contracts.md)) over mandatory **mTLS (TLS 1.3)** for synchronous RPC & parallel attribute fan-out; encrypted **NATS JetStream** (TLS 1.3 / mTLS) or Azure Service Bus (Private Endpoint) for simulation ticks, lifecycle events, and chat pub/sub — **all cloud communication happens encrypted** ([ADR-0012](docs/architecture/ADR-0012-private-subnet-isolation-and-encrypted-cloud-communication.md)) |
| **User Administration & Security** | `user-admin` backed by **PostgreSQL 18+** with `Argon2id` password hashing, MFA (TOTP / WebAuthn), RBAC (`PLAYER` / `GAME_MASTER`), TLS 1.3 / mTLS, and immutable audit logging ([ADR-0010](docs/architecture/ADR-0010-user-admin-auth-rbac-and-group-management.md)) |
| **Character Sheet & Attributes** | `character-registry`, `sheet-aggregator` (concurrent `errgroup` fan-out with graceful degradation and tick-based caching), and dedicated `attr-*` microservices |
| **Simulation & Genetics Engine** | Event-driven Go microservices (`sim-clock`, `sim-character-generator`, `sim-egg-reserve`, `sim-egg-selection`, `sim-menarche`, `sim-menstruation`, `sim-ejaculation`, `sim-sperm-race`, `sim-gamete-surface`, `sim-conception`, `sim-dna`, `sim-prenatal-loss`, `sim-birth-date`, `sim-gestation`, `sim-health`, `sim-mortality`, `sim-lifecycle`) using **SQLite** for scientific reference data, per-female egg-reserve databases, and per-ejaculation sperm-cell artifacts |
| **Real-Time Chat** | `frontend-chat` + `chat-service` + `chat-world-registry` with player-selectable World Chat Servers (`chat.world.<world_server_id>`), PostgreSQL 18+ persistence (`chat.*` schema), NATS JetStream fan-out, rate limiting, and content-policy moderation ([ADR-0002](docs/architecture/ADR-0002-world-chat-microservices-and-server-selection.md)) |
| **Observability & Quality** | **OpenTelemetry** tracing ([ADR-0004](docs/architecture/ADR-0004-shared-opentelemetry-observability.md)), `log/slog` structured JSON logging ([ADR-0003](docs/architecture/ADR-0003-shared-logging-library.md)), Prometheus metrics, deterministic fixed-seed simulation tests, `golangci-lint`, `govulncheck`, and Trivy container scanning (`Makefile` [ADR-0008](docs/architecture/ADR-0008-multi-module-makefile-build-automation.md) & GitHub Actions [ADR-0009](docs/architecture/ADR-0009-github-actions-ci-cd.md)) |
| **Deployment Target** | Hardened non-root `distroless/static` containers on private **Microsoft Azure Kubernetes Service (AKS)** with all backend services (and PostgreSQL 18+) in **private / non-public subnets** isolated **1:1 by Kubernetes namespace** (same namespace = same subnet; different namespaces = different subnets), per-subnet NSGs + `NetworkPolicy`, end-to-end encrypted cloud traffic (TLS 1.3 / mTLS), Private Endpoints for ACR/Key Vault/Blob Storage ([ADR-0012](docs/architecture/ADR-0012-private-subnet-isolation-and-encrypted-cloud-communication.md)) |

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
├── libs/                   # Shared Go libraries (gRPC/Protobuf contracts, auth middleware, telemetry, helpers)
├── services/               # Independently deployable and versioned Go microservices
├── CODE_OF_CONDUCT.md      # Contributor Covenant Code of Conduct (v2.0)
├── CONTRIBUTING.md         # Contribution workflow, local setup, testing & code review standards
├── LICENSE                 # BSD 3-Clause License
├── Makefile                # Multi-module build, test, lint, Protobuf, versioning, and container targets
├── README.md               # Project overview and developer entry point
├── SECURITY.md             # Vulnerability reporting & security policy
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

> **Note:** PrincessPink is currently in the **concept and architectural foundation** stage—no microservice implementations have been committed under `libs/` or `services/` yet. Start by reading [`docs/Concept.md`](docs/Concept.md) to explore the domain model, service boundaries, and implementation plan.

---

## Project Status & Roadmap

PrincessPink is currently in **Phase 0 / Architectural Foundation**. Planned implementation phases (detailed in [docs/Concept.md](docs/Concept.md#9-phased-implementation-roadmap)):

1. **Phase 1 — Platform Foundation:** Shared `libs/` libraries (logging [ADR-0003](docs/architecture/ADR-0003-shared-logging-library.md), OpenTelemetry [ADR-0004](docs/architecture/ADR-0004-shared-opentelemetry-observability.md), gRPC contracts [ADR-0005](docs/architecture/ADR-0005-shared-grpc-protobuf-contracts.md), config [ADR-0006](docs/architecture/ADR-0006-shared-configuration-library.md), UUID utilities [ADR-0007](docs/architecture/ADR-0007-shared-uuid-utilities.md)), `Makefile` ([ADR-0008](docs/architecture/ADR-0008-multi-module-makefile-build-automation.md)), GitHub Actions CI ([ADR-0009](docs/architecture/ADR-0009-github-actions-ci-cd.md)), and `user-admin` with PostgreSQL, Argon2id auth, RBAC, and Group management ([ADR-0010](docs/architecture/ADR-0010-user-admin-auth-rbac-and-group-management.md)).
2. **Phase 2 — Character Sheet, Chat & Frontend MVP:** `frontend-gateway`, `frontend-sheets`, `frontend-gm`, `frontend-chat`, `chat-service`, `chat-world-registry` (player-selectable World Chat Servers, Group Chat, and 1-to-1 Direct Messages), `character-registry`, `sheet-aggregator`, initial `attr-*` microservices, and `portrait-renderer`.
3. **Phase 3 — Core Reproduction Simulation Pipeline:** `sim-clock`, `sim-character-generator`, `sim-egg-reserve`, `sim-egg-selection`, `sim-menarche`, `sim-menstruation`, `sim-ejaculation`, `sim-sperm-race`, `sim-gamete-surface`, `sim-conception`, and `sim-dna` with SQLite stores, event bus integration, and fixed-seed cohort tests.
4. **Phase 4 — Full Lifecycle & Population Features:** `sim-prenatal-loss`, `sim-birth-date`, `sim-gestation`, `sim-health`, `sim-mortality`, `sim-lifecycle`, multi-generational family trees, and Game Master population analytics.
5. **Phase 5 — Production Hardening on Azure AKS:** Full Infrastructure-as-Code and Helm/Kustomize manifests, private / non-public per-namespace VNet subnets and NSGs, Azure PostgreSQL 18+, Key Vault / ACR / Blob Private Endpoints, `NetworkPolicy`, mandatory end-to-end TLS 1.3 / mTLS for all cloud communication ([ADR-0012](docs/architecture/ADR-0012-private-subnet-isolation-and-encrypted-cloud-communication.md)), HPA, observability dashboards, security audit, and operational runbooks.

---

## Documentation

- **[Technical Concept (`docs/Concept.md`)](docs/Concept.md)** — Full domain model, ER & sequence diagrams, character lifecycle, gamete DNA & SQLite architecture, microservice catalog, chat design, Azure AKS topology, and glossary.
- **[API Specifications (`docs/api/`)](docs/api/)** — OpenAPI and Protobuf contract documentation (planned).
- **[Architecture Docs (`docs/architecture/`)](docs/architecture/)** — Architecture Decision Records (ADRs) and infrastructure specifications:
  - [ADR-0001: Minimum PostgreSQL Version (PostgreSQL 18+)](docs/architecture/ADR-0001-minimum-postgresql-version.md)
  - [ADR-0002: World Chat in a Microservice Environment & Player World Chat Server Selection](docs/architecture/ADR-0002-world-chat-microservices-and-server-selection.md)
  - [ADR-0003: Shared Structured Logging Library (`libs/logging`)](docs/architecture/ADR-0003-shared-logging-library.md)
  - [ADR-0004: Shared OpenTelemetry & Observability Library (`libs/telemetry`)](docs/architecture/ADR-0004-shared-opentelemetry-observability.md)
  - [ADR-0005: Shared gRPC & Protocol Buffers Contracts (`libs/proto`)](docs/architecture/ADR-0005-shared-grpc-protobuf-contracts.md)
  - [ADR-0006: Shared Configuration Library (`libs/config`)](docs/architecture/ADR-0006-shared-configuration-library.md)
  - [ADR-0007: Shared UUID Utilities Library (`libs/uuid`)](docs/architecture/ADR-0007-shared-uuid-utilities.md)
  - [ADR-0008: Multi-Module Developer Workflow & Build Automation (`Makefile`)](docs/architecture/ADR-0008-multi-module-makefile-build-automation.md)
  - [ADR-0009: GitHub Actions CI/CD Architecture (`.github/workflows/`)](docs/architecture/ADR-0009-github-actions-ci-cd.md)
  - [ADR-0010: User Administration Service (`user-admin`) — PostgreSQL 18+, Argon2id Auth, Player/GM RBAC & Group Management](docs/architecture/ADR-0010-user-admin-auth-rbac-and-group-management.md)
  - [ADR-0011: Go as the Sole Programming Language (Go 1.27+)](docs/architecture/ADR-0011-go-as-sole-programming-language.md)
  - [ADR-0012: Private Subnet Isolation per Namespace & End-to-End Encrypted Cloud Communication](docs/architecture/ADR-0012-private-subnet-isolation-and-encrypted-cloud-communication.md)
- **[Operational Runbooks (`docs/runbooks/`)](docs/runbooks/)** — Deployment, backup, and incident response runbooks (planned).

---

## Contributing

Contributions, architectural feedback, and scientific modeling discussions are welcome!

1. Read the [Technical Concept](docs/Concept.md), the [Content & Safety Policy](#content--safety-policy), and our [Code of Conduct](CODE_OF_CONDUCT.md).
2. Open an issue to discuss bugs, scientific modeling proposals, or architectural changes before submitting large pull requests.
3. Fork the repository, create a feature branch, and ensure `make check` passes for any Go changes.
4. Submit a pull request with a clear description, rationale, and relevant unit or deterministic simulation tests.

All contributions must strictly respect the project's **zero-violence, zero-nudity** principles. Please see [CONTRIBUTING.md](CONTRIBUTING.md) for the full contributor guide, local setup, testing commands, and code review standards.

---

## Code of Conduct

This project adheres to the Contributor Covenant Code of Conduct (version 2.0). By participating, you are expected to uphold this code. Please see [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) for details.

---

## Security

PrincessPink is designed with security in mind (`Argon2id`, MFA, RBAC, private / non-public per-namespace subnets, end-to-end TLS 1.3 / mTLS for all external and cloud-internal communication, `govulncheck`, and Trivy image scanning—see [docs/Concept.md](docs/Concept.md#42-user-administration--security-service), [ADR-0010](docs/architecture/ADR-0010-user-admin-auth-rbac-and-group-management.md), and [ADR-0012](docs/architecture/ADR-0012-private-subnet-isolation-and-encrypted-cloud-communication.md)).

If you discover a security vulnerability, please **do not** open a public issue. Instead, report it privately to the project maintainers via GitHub Security Advisories as detailed in [SECURITY.md](SECURITY.md).

---

## License

This project is licensed under the **BSD 3-Clause License** — see the [LICENSE](LICENSE) file for details.