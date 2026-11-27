# PrincessPink — Technical Concept

## 1. Executive Summary & Vision

### 1.1 Core Idea
**PrincessPink** is a scientific, population-level simulation of human reproduction presented through a pen-and-paper role-playing game (RPG) interface inspired by classic tabletop systems (such as AD&D). Rather than focusing on combat or adventure, PrincessPink gamifies human biology, genetics, and generational lineage. Players interact with structured character sheets featuring comic-style face portraits that help them visualize the individuals they guide across generations.

### 1.2 Goals of the Simulation
- **Scientific Modeling:** Model the biological stages of human reproduction—hormonal cycles, gamete production, fertilization, genetic recombination, gestation (including both live birth and natural prenatal loss outcomes), aging, and natural mortality—using parameterized, reproducible scientific logic.
- **Accessible Gamification:** Translate complex biological and genetic states into a familiar pen-and-paper character sheet experience so players and game masters can explore inheritance, family trees, and population dynamics intuitively.
- **Modular & Scalable Engineering:** Decompose the platform into focused Go microservices deployed on Kubernetes (Microsoft Azure AKS), enabling independent development, scaling, and scientific refinement of each biological process and character attribute.

### 1.3 Non-Negotiable Content & Safety Principles
PrincessPink strictly enforces a **zero-violence, zero-nudity** policy:
- **No Violence or Gore:** Unlike adventure or combat RPGs (e.g., AD&D combat modules, World of Warcraft, GTA6), PrincessPink contains no combat mechanics, weapons, injury graphics, or violent narratives. Death occurs strictly through natural biological lifecycles.
- **No Nudity or Explicit Content:** Biological reproduction is represented purely as abstract, scientific data, state transitions, and tabletop-style attributes/events—never through explicit text, imagery, or adult themes.
- **Safe-by-Design Visuals:** Visual character representation is strictly limited to **comic-style face portraits** generated deterministically from genetic and age-related traits. Free-form user image uploads are avoided (or restricted/moderated if ever introduced) so inappropriate content cannot enter the platform.

---

## 2. Domain Model & Core Concepts

### 2.1 Core Entities & Relationships

```mermaid
erDiagram
    USER ||--o{ GROUP_MEMBERSHIP : "belongs to"
    GROUP ||--o{ GROUP_MEMBERSHIP : "contains"
    GROUP_MEMBERSHIP }o--o| CHARACTER : "selects 1 active PC at start"
    GROUP ||--o{ CHARACTER : "origin / hosts as NPC"
    USER |o--o{ CHARACTER : "owns (0..N roster; null while unowned NPC)"
    CHARACTER ||--o| OWNERSHIP_AGREEMENT : "child custody agreement"
    USER ||--o{ CHAT_MESSAGE : "sends"
    USER }o--o| WORLD_CHAT_SERVER : "selects preferred"
    WORLD_CHAT_SERVER ||--o{ CHAT_CHANNEL : "hosts world chat"
    GROUP ||--o| CHAT_CHANNEL : "has group chat"
    CHAT_CHANNEL ||--o{ CHAT_MESSAGE : "contains"
    CHARACTER ||--o| GENOME : "has immutable diploid"
    CHARACTER ||--o{ CHARACTER_PARENT : "child of (mother & father)"
    CHARACTER ||--o{ MENSTRUATION_CYCLE : "female records"
    CHARACTER ||--o| EGG_RESERVE_DB : "female carries SQLite DB from birth"
    EGG_RESERVE_DB ||--|{ EGG_CELL : "stores haploid oocytes"
    CHARACTER ||--o{ EJACULATION_DB : "male generates SQLite DB"
    EJACULATION_DB ||--|{ SPERM_CELL : "contains haploid"
    CHARACTER ||--o{ LIFECYCLE_EVENT : "records"
    CHARACTER ||--o{ WEIGHT_ADJUSTMENT : "records GM role-play changes"
    CHARACTER ||--o| CHARACTER_HEALTH_PROFILE : "tracks lifecycle & RP health indicators"
    CHARACTER ||--o{ HEALTH_ADJUSTMENT : "records RP & GM health/lifestyle changes"
    CHARACTER ||--o| CHARACTER_INTERCOURSE_PROFILE : "tracks intercourse & fertility values"
    CHARACTER ||--o{ CHARACTER_MEDICAL_DRUG : "takes (gender-eligible RP drugs)"
    GROUP ||--o{ PREGNANCY : "records pregnancy outcomes"
    CHARACTER ||--o| PREGNANCY : "gestates as conceived offspring"
    CHARACTER ||--o{ PREGNANCY : "carries as maternal obstetric record"

    USER {
        uuid id PK
        string email UK
        string display_name
        string role "PLAYER | GAME_MASTER"
        timestamp created_at
    }

    GROUP {
        uuid id PK
        string name
        uuid game_master_id FK
        date sim_start_date "mandatory at sim start (dd/MM/YYYY); starts at 0:00 h"
        string sim_clock_state "STOPPED | RUNNING"
        jsonb simulation_config "per-group sim tick rate (default: 1 sim year = 24h real time), weight/health bounds, prenatal loss toggle (default on) & prenatal care tier, etc."
        timestamp created_at
    }

    GROUP_MEMBERSHIP {
        uuid id PK
        uuid group_id FK "unique with user_id"
        uuid user_id FK "unique with group_id"
        uuid selected_character_id FK "1 owned character selected at group start; origin_group_id != group_id"
        timestamp joined_at
    }

    OWNERSHIP_AGREEMENT {
        uuid id PK
        uuid character_id FK "conceived/born child"
        uuid mother_player_id FK
        uuid father_player_id FK
        uuid proposed_owner_user_id FK "mother_player_id or father_player_id"
        string status "PENDING | AGREED | REJECTED | CLOSED_PRENATAL_LOSS"
        timestamp agreed_at "nullable"
    }

    WORLD_CHAT_SERVER {
        uuid id PK
        string slug UK
        string display_name
        string region
        string language
        string category "GENERAL | ROLEPLAY | SCIENCE | NEWCOMER"
        string status "ONLINE | HIGH_LOAD | FULL | MAINTENANCE | DRAINING"
        int max_capacity
        timestamp created_at
    }

    CHAT_CHANNEL {
        uuid id PK
        string channel_type "GLOBAL | GROUP | DIRECT"
        uuid world_server_id FK "nullable, set for GLOBAL (World Chat)"
        uuid group_id FK "nullable, set for GROUP"
        string name
        timestamp created_at
    }

    CHAT_MESSAGE {
        uuid id PK
        uuid channel_id FK
        uuid sender_user_id FK
        uuid recipient_user_id FK "nullable, set for DIRECT"
        text body
        timestamp sent_at
    }

    CHARACTER {
        uuid id PK
        uuid owner_user_id FK "nullable while unowned NPC"
        uuid origin_group_id FK "nullable; group where conceived/born (always NPC here)"
        string name "nullable before birth"
        string gender "FEMALE | MALE"
        string blood_type "A+ | A- | B+ | B- | AB+ | AB- | O+ | O- (immutable, derived from diploid DNA)"
        bool rh_sensitized "female-only; true if Rh- mother became RhD-sensitized after an Rh+ birth or prenatal loss"
        string lifecycle_state "CONCEIVED | GESTATING | ALIVE | DECEASED"
        timestamp conceived_at_sim
        date date_of_birth "nullable before birth; remains null on prenatal loss"
        date date_of_death "nullable while alive; set upon natural mortality or prenatal loss"
        date date_of_first_menstruation "female-only, nullable"
        float height_cm "nullable before birth; height in cm"
        float weight_kg "nullable before birth; weight in kg, GM-adjustable within params"
    }

    WEIGHT_ADJUSTMENT {
        uuid id PK
        uuid character_id FK
        uuid group_id FK
        uuid adjusted_by_gm_id FK
        float previous_weight_kg
        float new_weight_kg
        string reason "role-play rationale"
        timestamp adjusted_at_sim
    }

    CHARACTER_HEALTH_PROFILE {
        uuid id PK
        uuid character_id FK, UK
        string heart_health "ILL | HEALTHY_NOT_SPORTY | HEALTHY_NORMAL | HEALTHY_SPORTY"
        float waking_heart_rate_bpm "resting HR shortly after waking; simulated over lifecycle & RP"
        string muscle_condition "WEAK | NORMAL | SPORTY | BODY_BUILDER"
        int blood_pressure_systolic_mmhg
        int blood_pressure_diastolic_mmhg
        string respiratory_health "IMPAIRED | BELOW_AVERAGE | NORMAL | ATHLETIC"
        float vo2_max_ml_kg_min
        string metabolic_health "IMPAIRED | BORDERLINE | NORMAL | OPTIMAL"
        string immune_health "COMPROMISED | BELOW_AVERAGE | NORMAL | ROBUST"
        string sleep_recovery_quality "POOR | FAIR | GOOD | OPTIMAL"
        string stress_level "LOW | MODERATE | ELEVATED | HIGH"
        string rp_lifestyle_profile "active role-play training, rest & lifestyle inputs"
        timestamp updated_at_sim
    }

    HEALTH_ADJUSTMENT {
        uuid id PK
        uuid character_id FK
        uuid group_id FK
        uuid adjusted_by_user_id FK "Player (RP lifestyle) or GM (bounded health adjustment)"
        string actor_role "PLAYER | GAME_MASTER"
        string indicator_code "HEART_HEALTH | WAKING_HEART_RATE | MUSCLE_CONDITION | VAGINISMUS | ..."
        string previous_value
        string new_value
        string reason "role-play rationale"
        timestamp adjusted_at_sim
    }

    CHARACTER_INTERCOURSE_PROFILE {
        uuid id PK
        uuid character_id FK, UK
        float fertility_score "0..100; shaped by age, gender, health & body composition"
        float erection_quality "male-only, nullable; 0..100"
        float ejaculation_quality "male-only, nullable; 0..100 (reflects short-interval decay)"
        bool vaginismus "female-only, nullable; influences role play & intercourse completion"
        float libido_score "0..100; reproductive drive across age, hormones, health & cycle"
        float lubrication_quality "female-only, nullable; 0..100"
        int refractory_period_minutes "male-only, nullable; post-ejaculation recovery interval"
        float intercourse_stamina "0..100; cardiopulmonary & muscular endurance"
        string climacterium_state "female-only, nullable; PRE_MENARCHE | REPRODUCTIVE | PERIMENOPAUSAL | CLIMACTERIC"
        date date_of_first_ovulation "female-only, nullable; fertility_score = 0 prior"
        date climacterium_date "female-only, nullable; fertility_score = 0 from onset"
        date date_of_first_fertility "male-only, nullable; teenage pubertal fertility onset"
        timestamp updated_at_sim
    }

    CHARACTER_MEDICAL_DRUG {
        uuid id PK
        uuid character_id FK
        string drug_code "VIAGRA | CONTRACEPTION_PILL | ..."
        string eligible_gender "MALE | FEMALE | ALL"
        bool is_active "toggled via character sheet checkbox"
        timestamp started_at_sim
        timestamp stopped_at_sim "nullable while active"
        uuid updated_by_user_id FK
        timestamp updated_at_sim
    }

    MENSTRUATION_CYCLE {
        uuid id PK
        uuid character_id FK
        date start_date
        date end_date
        date ovulation_date
    }

    EGG_RESERVE_DB {
        uuid id PK
        uuid character_uuid UK
        int initial_egg_count
        int remaining_egg_count
        string sqlite_artifact_uri
        timestamp created_at_sim
    }

    EGG_CELL {
        bigint cell_id PK
        blob haploid_dna "22 autosomes + X"
        blob surface_profile "zona pellucida & oolemma receptors"
        float quality_score
        timestamp ovulated_at_sim "nullable"
        string status "DORMANT | SELECTED | VIABLE | FERTILIZED | EXPIRED | ATRESIA"
    }

    EJACULATION_DB {
        uuid id PK
        uuid father_id FK
        timestamp occurred_at_sim
        int sperm_count
        float erection_quality "0..100 at event"
        float ejaculation_quality "0..100 after short-interval decay"
        float quality_factor "decays with repeated short-interval ejaculations"
        string sqlite_artifact_uri
    }

    SPERM_CELL {
        bigint cell_id PK
        string sex_chromosome "X | Y"
        blob haploid_dna "22 autosomes + X/Y"
        blob surface_profile "acrosome & membrane ligands"
        float motility
        float viability
        float morphology
    }

    PREGNANCY {
        uuid id PK
        uuid character_id FK, UK "conceived offspring character UUID"
        uuid mother_id FK
        uuid father_id FK
        uuid group_id FK
        string outcome "ONGOING | LIVE_BIRTH | PRENATAL_LOSS"
        string loss_stage "nullable; PRE_IMPLANTATION_LOSS | EARLY_MISCARRIAGE | LATE_MISCARRIAGE | STILLBIRTH"
        int gestational_age_days "simulated gestational days at resolution or latest checkpoint"
        bool is_clinically_recognized "false for subclinical pre-implantation loss"
        string risk_band "LOW | MODERATE | ELEVATED | HIGH"
        string primary_cause_category "nullable; CHROMOSOMAL_ANOMALY | RH_INCOMPATIBILITY | HYPERTENSIVE_PLACENTAL | ..."
        jsonb contributing_factors "structured clinical risk factors & normalized weights"
        timestamp started_at_sim
        timestamp resolved_at_sim "nullable while ONGOING"
        string service_version "producing sim-prenatal-loss / sim-gestation version"
    }
```

### 2.2 Roles, Character Ownership & Group Participation Rules
- **Player (User):** Authenticated user identified by a unique `UUID`. A Player may own **multiple Characters** in their personal roster, has read/interaction access to the character sheets of their owned characters (including toggling gender-eligible **Medical Drugs** via checkboxes and updating their active character's **Role-Play Lifestyle & Training Profile** that gradually shapes cardiovascular, muscular, and general health indicators), and can communicate via **Global / World Chat**, their assigned **Group Chat(s)**, and private **1-to-1 Direct Messages** with other Players.
- **Game Master (GM):** Authenticated user who manages one or more **Groups** (simulation worlds/campaigns). A Game Master has visibility into all active player characters and NPC children living within their group(s), initializes each Group's simulation by entering a mandatory start date (`dd/MM/YYYY`, always starting at `0:00 h`), controls group-level simulation settings (including adjusting the Group's per-group simulation tick rate—defaulting to **1 simulated year per 24 hours real time**—starting population parameters, role-play weight and health adjustment bounds, and per-group **prenatal loss** settings—enabled by default in `GROUP.simulation_config` with configurable `prenatal_care_tier`, bounded `risk_multiplier`, pre-implantation tracking, or an opt-out toggle for sensitive campaigns), may stop and resume the Group's simulation tick whenever role-play needs it, may adjust a character's `weight_kg` and bounded role-play health and clinical intercourse indicators (such as `heart_health`, `waking_heart_rate_bpm` modifiers, `muscle_condition`, `vaginismus` narrative/therapy progression, or lifestyle/illness recovery arcs) within configured biological/role-play parameters for storytelling (with full audit logging), and participates in and moderates the **Group Chat** for his/her Group(s) alongside Global / World Chat and Direct Messages.
- **One Character per Player per Group:** Although a Player may own multiple Characters across their account, **within any single Group a Player plays only one Character**. At the **start of the Group**, each Player selects that single active Character from the Characters they already own (`GROUP_MEMBERSHIP.selected_character_id`).
- **Children as NPCs & Parental Ownership Agreement:** Every child **conceived or born during a simulation** enters the simulation as an **NPC (Non-Player Character)** with no Player owner (`owner_user_id = null`). The child remains an unowned NPC until the **Players of the mother and the father reach a mutual agreement** (`OWNERSHIP_AGREEMENT`) deciding which of them takes ownership of the child. Once both parents' Players agree, `owner_user_id` is assigned and the child is added to that Player's personal character roster. If a pregnancy ends in **prenatal loss** before birth, any `PENDING` `OWNERSHIP_AGREEMENT` is automatically closed (`CLOSED_PRENATAL_LOSS`) while preserving parent links, any optional reserved name, and the permanent historical lineage record.
- **Future-Group-Only Playability for Children:** Even after parental ownership is agreed and assigned to a Player, **a child can never be played as a Player Character in the Group where the mother and father live** (`origin_group_id`). Within that origin Group, the child continues to live strictly as an NPC; the owning Player may only select and play that child in a **future Group** at the start of that new Group.

### 2.3 Agent / Character Lifecycle
Every Agent in the simulation is a **Character** assigned a globally unique, immutable **UUID** at the moment of conception. That UUID remains the canonical identifier for the character across all phases of existence:

```mermaid
stateDiagram-v2
    [*] --> CONCEIVED : Fertilization (UUID issued)
    CONCEIVED --> GESTATING : Implantation & DNA finalized
    CONCEIVED --> DECEASED : Pre-implantation loss (sim-prenatal-loss, default on, GM-configurable)
    GESTATING --> ALIVE : Birth event
    GESTATING --> DECEASED : Prenatal loss (early/late miscarriage or stillbirth via sim-prenatal-loss, default on, GM-configurable)
    ALIVE --> DECEASED : Natural mortality
    DECEASED --> [*] : Permanent historical record
```

- **Before Birth (`CONCEIVED`, `GESTATING`):** The character already exists in the system with a UUID, immutable diploid DNA, determined biological `gender` (`FEMALE` or `MALE`), immutable `blood_type` (`A+`, `A-`, `B+`, `B-`, `AB+`, `AB-`, `O+`, or `O-`), `origin_group_id`, mother/father references, and a linked `PREGNANCY` record (`outcome = ONGOING`). `date_of_birth` and `date_of_death` are `null`. Newly conceived children start as **NPCs** (`owner_user_id = null`) until the mother's and father's Players reach an ownership agreement. Players may optionally assign or reserve a name prior to or at birth. While prenatal loss is enabled for the Group (default in `GROUP.simulation_config`), `sim-prenatal-loss` evaluates biological loss risk across implantation and gestation; if a prenatal loss occurs before birth, the character transitions directly from `CONCEIVED` or `GESTATING` to `DECEASED` (`date_of_birth` remains `null`, `date_of_death` records the simulated date of loss, `PREGNANCY.outcome = PRENATAL_LOSS`, any `PENDING` `OWNERSHIP_AGREEMENT` is closed as `CLOSED_PRENATAL_LOSS`, newborn-only services are not triggered, and maternal health and menstrual cycles enter stage-proportional physiological recovery; see [§2.6](#26-prenatal-loss--pregnancy-outcome-model)).
- **During Life (`ALIVE`):** Upon live birth, `date_of_birth` is recorded permanently and `PREGNANCY.outcome` transitions to `LIVE_BIRTH`. The character participates in the simulation, ages with simulation time, exposes full core and gender-specific character sheet attributes, and can reproduce according to biological rules. Children born in a Group live in that Group strictly as **NPCs** (even after parental ownership is agreed) and can only be selected as a playable character by their owning Player in a **future Group**.
- **After Death (`DECEASED`):** Upon natural post-birth mortality (`ALIVE` → `DECEASED`) or prenatal loss (`CONCEIVED`/`GESTATING` → `DECEASED`), `date_of_death` is recorded permanently (with `date_of_birth` remaining `null` for prenatal losses). The character record, UUID, lineage links, and `PREGNANCY` outcome metadata remain permanently queryable for genealogy, family trees, obstetric history, and genetic heritage analysis.

### 2.4 Core & Gender-Specific Character Attributes
Every character carries both universal lifecycle attributes and biologically grounded **gender-specific attributes**:
- **Universal Core Attributes:**
  - `uuid`: Globally unique, permanent identifier from conception onward.
  - `name`: Player-assigned name (optional prior to birth).
  - `gender`: Biological sex (`FEMALE` or `MALE`), determined at conception by the sex chromosome pair (`XX` → `FEMALE`, `XY` → `MALE`).
  - `blood_type`: Immutable human ABO + RhD blood group (`A+`, `A-`, `B+`, `B-`, `AB+`, `AB-`, `O+`, `O-`), determined permanently at conception by `sim-dna` via Mendelian inheritance from maternal and paternal haploid alleles (ABO locus on chromosome 9: codominant `I^A`/`I^B`, recessive `i`; RhD locus on chromosome 1: dominant `D`, recessive `d`). Displayed on every character sheet and used across gestation, health, and mortality simulations.
  - `date_of_birth`: Simulated calendar date of birth (populated upon transition to `ALIVE`; remains `null` if prenatal loss occurs before birth).
  - `date_of_death`: Simulated calendar date of natural death or prenatal loss (nullable while living or gestating; populated upon transition to `DECEASED`).
  - `mother_uuid` / `father_uuid`: Immutable lineage references to both biological parents (null only for initial founder population).
- **Visible Appearance Attributes (Shown on All Character Sheets):**
  - `eye_color`: Current expressed iris pigmentation (e.g., blue, gray, hazel, green, amber, brown).
  - `hair_color`: Current expressed hair pigmentation (e.g., blonde, red, light/dark brown, black, silver/gray, white).
  - `skin_color`: Current expressed skin pigmentation tone.
  - **Dynamic Changes After Birth & During Life:** While each character's pigmentation baseline is anchored in their immutable diploid DNA, `eye_color`, `hair_color`, and `skin_color` are **not static**—they may change after birth and throughout life based on developmental stage, aging, hormonal shifts, and environmental/biological factors (for example, newborn eye color darkening during infancy, childhood hair darkening or graying/whitening with age, and gradual age- or environment-driven skin tone shifts).
- **Physical Measurements & Medical Body Composition Attributes (Shown on All Character Sheets):**
  Every living character carries anthropometric measurements together with derived clinical values equivalent to those calculated by a medical body-composition scale, recalculated dynamically as age, growth, gestation, or role-play weight changes occur:
  - **Core Measurements:**
    - `height_cm`: Current height in **centimeters (`cm`)**, anchored in polygenic DNA and evolving naturally across developmental stages (birth length, infancy/childhood growth, pubertal growth spurt, adult plateau, and subtle late-life decline).
    - `weight_kg`: Current body mass in **kilograms (`kg`)**, evolving naturally with age, growth, and pregnancy (`sim-gestation`).
    - **Game Master Role-Play Weight Adjustment:** For tabletop role-play storytelling (e.g., lifestyle, nutrition, or narrative arcs), a **Game Master** may adjust `weight_kg` for any character (PC or NPC) within their managed Group(s), strictly constrained by **bounded parameters** configured in `GROUP.simulation_config` and enforced by `character-registry`:
      - Age- and height-scaled **minimum and maximum physiological weight bounds** (e.g., safe BMI/pediatric percentile limits so impossible or harmful extremes cannot be entered, preserving the zero-violence/natural-lifecycle policy).
      - Configurable **maximum change per adjustment (`max_delta_kg` / `max_delta_pct`)** and optional cooldown period to keep weight transitions realistic for role-play.
      - Mandatory **role-play reason** and immutable audit recording (`WEIGHT_ADJUSTMENT`), emitting `character.weight.updated` so all derived medical body-composition metrics recalculate automatically.
  - **Derived Medical Body-Composition Values (Calculated from `height_cm`, `weight_kg`, `gender`, Age & Lifecycle State):**
    - `bmi`: **Body Mass Index (`kg/m²`)** (`weight_kg / (height_cm / 100)²`) with WHO adult classification band or age/sex-adjusted pediatric percentile band, interpreted alongside `muscle_condition` so athletic or body-builder lean mass is distinguished from excess adiposity.
    - `body_fat_percentage` & `body_fat_index`: **Body Fat Percentage (`%`) & Body Fat Index** (sex- and age-adjusted anthropometric estimate modulated by genotype, hormonal state, and `muscle_condition`, plus Fat Mass Index `fat_mass_kg / (height_cm / 100)²`).
    - `lean_body_mass_kg`: **Lean Body Mass / Fat-Free Mass (`kg`)** (non-adipose body mass derived from height, weight, sex, `muscle_condition`, and body fat percentage).
    - `muscle_mass_kg` & `muscle_mass_pct`: **Skeletal Muscle Mass (`kg` & `%`)** (estimated lean skeletal muscle share adjusted for sex, age stage, and `muscle_condition`).
    - `total_body_water_pct` & `total_body_water_l`: **Total Body Water (`%` & `L`)** (hydration volume and percentage estimated via sex-, age-, height-, and weight-adjusted clinical formulas such as Watson).
    - `bone_mass_kg`: **Estimated Bone Mass (`kg`)** (skeletal mineral mass reflecting pubertal bone accrual, resistance-training stimulus from `muscle_condition`, and age-related density shifts).
    - `visceral_fat_rating`: **Visceral Fat Rating (index)** (clinical scale indicator of abdominal/visceral adipose level, feeding into `heart_health` and `metabolic_health`).
    - `bmr_kcal`: **Basal Metabolic Rate (`kcal/day`)** (resting daily energy expenditure via Mifflin-St Jeor adjusted for lean mass / `muscle_condition`, `weight_kg`, `height_cm`, age, and `gender`).
    - `bsa_m2`: **Body Surface Area (`m²`)** (clinical body surface area via Mosteller/Du Bois formula from `height_cm` and `weight_kg`).
    - `ideal_weight_range_kg`: **Ideal / Healthy Weight Range (`kg`)** (reference weight band for the character's current `height_cm`, `gender`, and age stage).
- **Health & Fitness Indicators (Shown on All Character Sheets):**
  Every living character carries dynamic clinical health and physical conditioning indicators that are anchored in genetic predispositions, simulated continuously across the character's lifecycle by `sim-health`, and influenced by **Role Play** (Player lifestyle/training choices and bounded Game Master narrative adjustments):
  - **Heart Health (`heart_health`):** Categorical cardiovascular health classification with four states:
    - `ILL` *(ill)* — compromised or burdened cardiovascular function (e.g., genetic predisposition, chronic strain, or natural illness arc).
    - `HEALTHY_NOT_SPORTY` *(healthy not sporty)* — clinically healthy heart without regular aerobic conditioning.
    - `HEALTHY_NORMAL` *(healthy normal)* — balanced, everyday healthy cardiovascular function.
    - `HEALTHY_SPORTY` *(healthy sporty)* — well-conditioned aerobic cardiovascular fitness with high cardiac efficiency.
  - **Waking Heart Rate (`waking_heart_rate_bpm`):** Resting heart rate in beats per minute (`bpm`) measured **shortly after waking up**, **simulated continuously over the entire lifecycle of the character and influenced by Role Play**:
    - *Lifecycle Trajectory:* Follows realistic human physiological curves—higher in newborns and infants (~110–140 bpm), gradually declining through childhood (~80–110 bpm) and adolescence (~65–85 bpm), stabilizing in adulthood according to `heart_health` (e.g., ~45–59 bpm for `HEALTHY_SPORTY`, ~60–74 bpm for `HEALTHY_NORMAL`, ~75–90 bpm for `HEALTHY_NOT_SPORTY`, and elevated or unstable baselines for `ILL`), exhibiting physiological elevation during pregnancy (`sim-gestation`, typically +10–20 bpm due to increased blood volume and cardiac output), and shifting naturally in advanced age.
    - *Role-Play Influence:* Responds dynamically to Player role-play training/lifestyle routines (e.g., sustained endurance training progressively lowers waking heart rate; sedentary periods, poor sleep, or high stress elevate it), bounded GM health/lifestyle adjustments, `weight_kg` shifts, and active pharmacological interactions.
  - **Muscles / Muscular Conditioning (`muscle_condition`):** Qualitative musculoskeletal strength and conditioning tier with four states:
    - `WEAK` *(weak)* — low muscular tone/strength (e.g., deconditioning, recovery, or advanced-age sarcopenia).
    - `NORMAL` *(normal)* — everyday functional muscular development.
    - `SPORTY` *(sporty)* — athletic, well-toned musculature with strong functional endurance and lean mass.
    - `BODY_BUILDER` *(body builder)* — heavily developed skeletal muscle mass and strength, significantly increasing `muscle_mass_kg`, `lean_body_mass_kg`, and `bmr_kcal` while distinguishing muscular weight from excess adiposity in `BMI`.
  - **Blood Pressure (`blood_pressure_systolic_mmhg` / `blood_pressure_diastolic_mmhg` & band `LOW | NORMAL | ELEVATED | HIGH`):** Vascular hemodynamic indicator coupled to `heart_health`, `waking_heart_rate_bpm`, `blood_type` (modest non-O vascular/thrombotic predisposition), `visceral_fat_rating`, `BMI`, age, `stress_level`, and pregnancy (`sim-gestation`).
  - **Respiratory / Aerobic Health (`respiratory_health`: `IMPAIRED | BELOW_AVERAGE | NORMAL | ATHLETIC` & `vo2_max_ml_kg_min`):** Cardiopulmonary oxygenation and endurance capacity evolving across growth, role-play aerobic conditioning, and aging.
  - **Metabolic Health (`metabolic_health`: `IMPAIRED | BORDERLINE | NORMAL | OPTIMAL`):** Glycemic and endocrine-metabolic efficiency shaped by genetics, `visceral_fat_rating`, `BMI`, `muscle_condition`, age, and role-play nutrition/activity.
  - **Immune Health (`immune_health`: `COMPROMISED | BELOW_AVERAGE | NORMAL | ROBUST`):** Natural physiological defense and recovery resilience maturing in childhood, peaking in adulthood, and gradually declining with immunosenescence, with subtle baseline diversity shaped by `blood_type` surface-antigen expression.
  - **Sleep & Recovery Quality (`sleep_recovery_quality`: `POOR | FAIR | GOOD | OPTIMAL`):** Restorative sleep indicator shaped by role-play habits, age, pregnancy, and `stress_level`; directly modulates `waking_heart_rate_bpm`, endocrine alignment (`HOR`), and recovery speed.
  - **Stress & Allostatic Load (`stress_level`: `LOW | MODERATE | ELEVATED | HIGH`):** Physiological stress burden driven by role-play events and lifestyle; elevates `waking_heart_rate_bpm` and `blood_pressure` and modulates hormonal/reproductive regularity.
  - **Role-Play Influence & Bounded GM Adjustments (`HEALTH_ADJUSTMENT`):** Players may update their active character's role-play lifestyle and training profile (cardio training, strength training, sleep/rest habits, stress/recovery context) on the character sheet, causing `sim-health` to adapt `waking_heart_rate_bpm`, `heart_health`, `muscle_condition`, and related indicators gradually over simulated ticks. Game Masters may also apply bounded role-play health adjustments within `GROUP.simulation_config` physiological guardrails (preserving the zero-violence, natural-lifecycle policy) with mandatory rationale and immutable audit logging (`HEALTH_ADJUSTMENT`), emitting `character.health.updated` so all derived attributes and simulation services recalculate automatically.
- **Core Reproduction Attributes (AD&D-Style RPG Stats, Shown on All Character Sheets):**
  Inspired by classic AD&D ability scores (e.g., Strength, Constitution), every character sheet displays **6 tabletop-style numeric attributes** (such as a `3–18` scale with derived positive/negative modifiers) specifically tailored to human reproduction. Derived from genotype, age, **health & fitness indicators** (`heart_health`, `waking_heart_rate_bpm`, `muscle_condition`, `blood_pressure`, `respiratory_health`, `metabolic_health`, `immune_health`, `sleep_recovery_quality`, `stress_level`), and lifecycle state, **these attributes directly modify the probability and mechanics of every reproduction try**:
  1. **Fertility (`FER`):** Baseline gamete production capacity and reproductive reserve (follicular/ovarian quality in females; spermatogenesis output in males), modulated by `metabolic_health`, `heart_health`, `sleep_recovery_quality`, and `stress_level`. Modifies gamete availability and base conception chance on each attempt.
  2. **Constitution (`CON`):** Overall physiological resilience and bodily health, directly shaped by `heart_health`, `blood_pressure`, `immune_health`, and `muscle_condition`. Modifies gamete viability, implantation stability, and gestation resilience during and after a reproduction try.
  3. **Vitality (`VIT`):** Cellular energy and metabolic vigor, directly shaped by `waking_heart_rate_bpm`, `respiratory_health` (`VO2 max`), `muscle_condition`, and `sleep_recovery_quality`. Modifies sperm motility/endurance during the race to the egg and oocyte vigor during the fertile window.
  4. **Hormonal Balance (`HOR`):** Endocrine regularity and cycle synchronization, directly shaped by `metabolic_health`, `stress_level`, `sleep_recovery_quality`, and extreme energy/muscular states. Modifies ovulation regularity, fertile-window clarity, cervical mucus permeability, and reproductive readiness on each try.
  5. **Receptivity (`REC`):** Biological readiness and synchronization of the reproductive environment (e.g., optimal fertile-window alignment, capacitation support, and implantation receptivity), influenced by `immune_health`, `metabolic_health`, and `stress_level`. Applies timing and environment modifiers to each reproduction attempt.
  6. **Compatibility (`COM`):** Molecular and surface-receptor affinity between gametes (zona pellucida / oolemma receptor and sperm ligand alignment). Modifies the gamete surface-fit check and fertilization fusion chance on each reproduction try.
- **Intercourse & Fertility Values (Shown on Character Sheets, Gender-Filtered Where Applicable):**
  Represented strictly as abstract, scientific, clinical/biological parameters in full compliance with the **zero-violence, zero-nudity** policy, every character carries dynamic intercourse and fertility values (`CHARACTER_INTERCOURSE_PROFILE`) that evolve across the lifecycle and directly influence both **Role Play** and the **reproduction simulation**:
  - **Fertility (`fertility_score`, numeric value `0–100`, All Characters):**
    A concrete, lifecycle-dynamic biological fertility index bounded strictly between **`0` and `100`** (complementing the tabletop `3–18` `FER` ability score, which models innate reproductive aptitude). `fertility_score` is calculated continuously from **age**, **`gender`**, **health indicators** (`heart_health`, `waking_heart_rate_bpm`, `muscle_condition`, `blood_pressure`, `respiratory_health`, `metabolic_health`, `immune_health`, `sleep_recovery_quality`, `stress_level`), and **body-composition values** (`height_cm`, `weight_kg`, `BMI`, `body_fat_percentage`, `visceral_fat_rating`, `lean_body_mass_kg`—e.g., severe underweight/low body fat or high visceral fat/obesity depresses fertility):
    - *Female (`gender == FEMALE`):* Strictly **`0`** before the character's **first ovulation** (`date_of_first_ovulation`) and strictly **`0`** upon entering **climacterium** (`climacterium_state == CLIMACTERIC` / `climacterium_date`). After first ovulation, fertility rises rapidly into peak young-adult levels—**young women are significantly more fertile than older women**—and then declines progressively with advancing age and diminishing ovarian reserve (`EGG_RESERVE_DB.remaining_egg_count`) through perimenopause until reaching `0` at climacterium.
    - *Male (`gender == MALE`):* Strictly **`0`** during childhood. Young boys become fertile (`fertility_score > 0`) at a character-specific pubertal onset point during their **teenage years** (`date_of_first_fertility`, driven by genotype, health, and body composition). From that onset, `fertility_score` **rises steadily until peaking around age 21**, and from ~21 onward **declines slowly downwards** across adulthood and advanced age (without an abrupt climacteric cliff, though still strongly modulated by health and body values).
  - **Quality of Erection (`erection_quality`, numeric value `0–100`, `gender == MALE`):**
    Clinical vascular-hemodynamic readiness score (`0` pre-pubertal/absent to `100` optimal) shaped by age (pubertal onset, young-adult peak, gradual age-related vascular decline), `heart_health`, `blood_pressure`, `waking_heart_rate_bpm`, `respiratory_health`, `metabolic_health`, `BMI` / `visceral_fat_rating`, `sleep_recovery_quality`, `stress_level`, `HOR`/`VIT`, and active **Viagra** (`VIAGRA`, which elevates `erection_quality` within safe cardiovascular bounds). Directly governs penetrative intercourse completion probability, daily ejaculation propensity, and intravaginal semen delivery efficiency in `sim-ejaculation` and `sim-sperm-race`.
  - **Quality of Ejaculation (`ejaculation_quality`, numeric value `0–100`, `gender == MALE`):**
    Clinical semen and gamete cohort quality score (`0–100`) shaped by age, `fertility_score`, `FER`/`CON`/`VIT`/`HOR`, health and body-composition indicators (`metabolic_health`, `heart_health`, `sleep_recovery_quality`, `stress_level`, `BMI`, `visceral_fat_rating`), and **short-interval ejaculation quality decay** (`quality_factor` decreasing with consecutive ejaculations within a short window and recovering across the refractory/replenishment interval). Directly scales simulated sperm count, motility, morphology, and viability in `sim-ejaculation` and the resulting per-ejaculation SQLite database (`EJACULATION_DB`).
  - **Vaginismus (`vaginismus`, boolean `true` / `false`, `gender == FEMALE`):**
    A clinical boolean flag indicating involuntary pelvic-floor muscle contraction impeding penetrative intercourse. **Influences Role Play** (guiding non-explicit tabletop storytelling, partner communication, comfort, and medical/therapeutic progression arcs; adjustable via audited Player/GM role-play updates in `HEALTH_ADJUSTMENT`) and **Simulation**: when `true`, standard penetrative reproduction attempts face a high physiological impediment probability—substantially reducing successful intravaginal insemination completion (`sim-ejaculation` / `sim-sperm-race` / `sim-conception`) until resolved or mitigated through role play, while leaving ovarian cycles and egg reserve unaffected.
  - **Additional Relevant Intercourse Values:**
    - **Libido / Reproductive Drive (`libido_score`, `0–100`, All Post-Pubertal Characters):** Endocrine and vitality-driven biological interest in reproductive interaction, modulated by age, `gender`, `HOR`, `VIT`, `sleep_recovery_quality`, `stress_level`, `heart_health`, `metabolic_health`, `body_fat_percentage`, female menstrual cycle phase (periovulatory elevation), and active medical drugs (`CONTRACEPTION_PILL`). Guides role-play initiative and modulates baseline reproductive-attempt / daily ejaculation propensity.
    - **Lubrication / Mucosal Readiness (`lubrication_quality`, `0–100`, `gender == FEMALE`):** Vaginal and cervical mucosal hydration/readiness shaped by age (declining toward/during climacterium), menstrual cycle phase (peaking near ovulation alongside permeable cervical mucus), `HOR`, `REC`, `total_body_water_pct`, `stress_level`, `sleep_recovery_quality`, and active `CONTRACEPTION_PILL`. Influences role-play comfort and modulates sperm survival and cervical mucus permeability in `sim-sperm-race` (interacting with `vaginismus`).
    - **Refractory / Recovery Period (`refractory_period_minutes`, `gender == MALE`):** Physiological recovery interval following ejaculation before subsequent erection/ejaculation readiness, shaped by age (shorter in young adults, lengthening with age), `heart_health`, `waking_heart_rate_bpm`, `respiratory_health` (`VO2 max`), `sleep_recovery_quality`, `stress_level`, and `VIAGRA`. Governs minimum spacing between consecutive ejaculations in `sim-ejaculation` and drives the short-interval `ejaculation_quality` decay curve (`quality_factor`).
    - **Intercourse Stamina (`intercourse_stamina`, `0–100`, All Characters):** Cardiopulmonary and musculoskeletal endurance during reproductive activity, derived directly from `heart_health`, `waking_heart_rate_bpm`, `respiratory_health` (`VO2 max`), `muscle_condition`, `BMI`, `sleep_recovery_quality`, `stress_level`, and age. Influences role-play pacing/fatigue and modulates attempt completion stability and ejaculatory reliability in `sim-ejaculation`.
    - **Climacterium State (`climacterium_state`, `gender == FEMALE`):** Reproductive lifespan stage (`PRE_MENARCHE`, `REPRODUCTIVE`, `PERIMENOPAUSAL`, `CLIMACTERIC`) tracked alongside `date_of_first_ovulation` and `climacterium_date` (derived from `EGG_RESERVE_DB.remaining_egg_count`, age, genotype, `HOR`, `metabolic_health`, and `stress_level`). Transitions female `fertility_score` smoothly to `0` at climacterium and halts ovulation/menstruation.
- **Female-Specific Attributes (`gender == FEMALE`):**
  - `date_of_first_menstruation`: Simulated calendar date of menarche (onset of the first menstrual cycle during puberty), calculated for a young female character by `sim-menarche`.
  - `egg_reserve_db`: Reference to the dedicated ovarian **Egg-Cell SQLite database** linked to the female character's `UUID`, generated at birth by `sim-egg-reserve` and queried each cycle by `sim-egg-selection` to choose the next ovulated egg cell.
  - `menstruation_dates`: Historical and current record of menstruation dates (cycle start/end dates, cycle length, and ovulation dates), influenced by active hormonal medication such as the **Contraception Pill**.
  - `ovarian_cycle_state` & `climacterium_state`: Current cycle phase (pre-menarche, menstrual, follicular, ovulation, luteal, pregnant, perimenopausal, climacteric/post-menopausal), `date_of_first_ovulation`, `climacterium_date`, and reference to any currently viable **egg cell (oocyte)** selected from her Egg-Cell SQLite database and its haploid DNA (or suppressed ovulation state when on hormonal contraception).
  - `vaginismus` & `lubrication_quality`: Female intercourse values (`vaginismus` boolean influencing role play and penetrative completion; `lubrication_quality` `0–100` influencing role-play comfort and sperm transport permeability).
  - `rh_sensitized`: Maternal RhD alloimmunization flag (`false` by default; applicable to `Rh-` females). Transitions to `true` if an `Rh-` mother becomes sensitized after an `Rh+` live birth or prenatal loss without RhIg prophylaxis, influencing maternal-fetal compatibility and prenatal-loss risk in subsequent `Rh+` pregnancies (`sim-prenatal-loss` / `sim-gestation` / `sim-birth-date`).
- **Male-Specific Attributes (`gender == MALE`):**
  - `spermatogenesis_state` & `date_of_first_fertility`: Teenage pubertal fertility onset (`date_of_first_fertility`), sperm production baseline, motility/morphology distributions, `erection_quality` (`0–100`), `ejaculation_quality` (`0–100`), `refractory_period_minutes`, and reproductive readiness.
  - `ejaculation_history`: References to recent ejaculation events, their timestamps (used to calculate short-interval `ejaculation_quality` decay), and their generated sperm-cell SQLite databases.
- **Medical Drugs (Role-Play Modifiers, Gender-Filtered Checkboxes on Character Sheet):**
  To support realistic medical and lifestyle role-play while strictly upholding the zero-violence, zero-nudity policy, characters can take **medical drugs** that directly influence biological simulation processes. On the character sheet (`frontend-sheets`), the **Player** controls whether and which medical drugs their character is currently taking by **clicking the checkbox in front of each medical drug available for the character's biological `gender`** (`CHARACTER_MEDICAL_DRUG`):
  - **Gender-Filtered Availability & Extensibility:** Only drugs eligible for the character's `gender` (`MALE`, `FEMALE`, or `ALL` for future universal drugs) are presented as selectable checkboxes on the sheet and accepted by `character-registry`. Toggling a checkbox immediately persists the change and emits `character.medication.updated` so simulation services and character sheet attributes recalculate.
  - **Viagra (`VIAGRA`, `gender == MALE`):**
    - Increases the male character's **`erection_quality`** score/modifier.
    - Increases the probability of **one or more ejaculations occurring within a single simulated day**.
    - Interacts with physiological **short-interval ejaculation quality decay**: with each consecutive ejaculation occurring within a short period of time, the **quality of the ejaculation decreases** (progressive reduction in sperm count/concentration, motility, morphology, and viability recorded in `EJACULATION_DB.quality_factor` and the generated sperm-cell SQLite cohort).
  - **Contraception Pill (`CONTRACEPTION_PILL`, `gender == FEMALE`):**
    - Influences the female character's **menstruation period** (modulating cycle cadence, regularity, duration, and withdrawal-bleed timing in `sim-menstruation`, including physiological transition behavior when starting or stopping the pill).
    - Strongly influences (reduces) the **chance of conceiving a baby** by suppressing or inhibiting ovulation (`sim-egg-selection`), lowering cervical mucus permeability (`sim-sperm-race`), and reducing implantation receptivity (`sim-conception`) according to versioned scientific efficacy parameters; if a rare breakthrough conception occurs while the pill remains active, altered endometrial/hormonal support also elevates early prenatal-loss hazard in `sim-prenatal-loss`.

### 2.5 Genetics, Gamete DNA & Phenotype Model
- **Diploid Character Genotype (Immutable):** Stored as a structured representation of 23 chromosome pairs (22 autosomal pairs + 1 sex chromosome pair, `XX` or `XY`), carrying allele definitions for modeled Mendelian and polygenic traits (e.g., facial geometry, eye/hair/skin pigmentation, ABO blood group alleles `I^A`/`I^B`/`i` on chromosome 9 and RhD factor alleles `D`/`d` on chromosome 1, baseline biological predispositions).
- **Egg Cell (Oocyte) Haploid DNA, Surface Profile & Ovarian Egg-Reserve SQLite Database:** Mirroring human biology, a female character carries her lifetime supply of egg cells from birth. When a girl is born (`gender == FEMALE`), `sim-egg-reserve` generates all egg cells she carries with her and stores them in a **dedicated SQLite database explicitly linked to the girl's `character_uuid`**. Each stored egg cell carries its own **haploid DNA** (22 single autosomes + 1 `X` chromosome, calculated via simulated meiosis with homologous crossover/recombination, independent assortment, and rare point mutations from her diploid DNA), an egg **surface profile** (zona pellucida and oolemma binding receptors), and baseline viability/quality traits. During each menstrual cycle after menarche, `sim-egg-selection` queries the girl's linked Egg-Cell SQLite database to determine **which specific egg cell drops (ovulates) during her next cycle**.
- **Sperm Cell Haploid DNA, Surface Profile & Ejaculation SQLite Database:** Each ejaculation event by a male character builds a **dedicated SQLite database** containing all simulated sperm cells included in that ejaculation. Every sperm cell record is individually calculated from the father's diploid DNA via simulated meiosis—yielding its own unique **haploid DNA** (22 single autosomes + either an `X` or `Y` sex chromosome) alongside cell-level physical traits (motility, morphology, viability) and a **surface profile** (acrosome/membrane binding ligands).
- **Offspring DNA Calculation from Mother and Father:** Fertilization requires not only that a sperm cell reaches the egg, but also that its surface profile **fits the egg cell's surface**—just as in biology, the fastest sperm cell does not always win. When a surface-compatible winning sperm cell fertilizes a specific egg cell, the new character's immutable diploid DNA (23 chromosome pairs) is calculated directly by pairing the **egg cell's haploid DNA** (from the mother) with the **winning sperm cell's haploid DNA** (from the father's ejaculation SQLite database). This guarantees true gamete-level Mendelian and polygenic inheritance and naturally determines the offspring's `gender` (`XX` or `XY`) and immutable `blood_type` (combining one maternal and one paternal allele at both the ABO and RhD loci).
- **Phenotype (Derived):** Computed dynamically by Character Sheet Attribute Microservices from the character's immutable genotype combined with current simulation state (age derived from `date_of_birth` / `date_of_death`, gender, `height_cm`, `weight_kg`, hormonal phase, health & fitness indicators, intercourse & fertility profile, and role-play lifestyle state). This includes `eye_color`, `hair_color`, and `skin_color`, which can evolve after birth and across life stages, derived medical body-composition metrics (`BMI`, Body Fat Index, Lean Body Mass, Muscle Mass, Total Body Water, Bone Mass, Visceral Fat, BMR, BSA, Ideal Weight Range), dynamic health & fitness indicators (`heart_health`, lifecycle-simulated `waking_heart_rate_bpm`, `muscle_condition`, `blood_pressure`, `respiratory_health`, `metabolic_health`, `immune_health`, `sleep_recovery_quality`, `stress_level`), intercourse & fertility values (`fertility_score` `0–100`, `erection_quality`, `ejaculation_quality`, `vaginismus`, `libido_score`, `lubrication_quality`, `refractory_period_minutes`, `intercourse_stamina`, `climacterium_state`), as well as the character's 6 AD&D-style reproduction attributes.
- **Comic Face Portrait:** Derived deterministically from facial phenotype traits (including current `eye_color`, `hair_color`, and `skin_color`), gender, and current age stage, producing a stylized comic-art portrait (head/shoulders only) displayed on the character sheet.

### 2.6 Prenatal Loss & Pregnancy Outcome Model
In real human reproduction, not every conception progresses to live birth. PrincessPink models **prenatal loss** (natural embryo or fetal loss prior to birth) as a first-class, scientifically grounded pregnancy outcome evaluated by a dedicated microservice (**`sim-prenatal-loss`**) and persisted via the `PREGNANCY` entity, in strict compliance with the **zero-violence, zero-nudity** policy:

- **Clinical, Non-Graphic Framing:** Prenatal loss occurs exclusively through natural biological and clinical mechanisms (genetic/chromosomal viability, placental/hemodynamic insufficiency, endocrine/metabolic imbalance, maternal-fetal Rh incompatibility, etc.)—never through violence, trauma, injury, or graphic prose. Character sheets and event logs expose strictly structured clinical metadata (`outcome`, `loss_stage`, `gestational_age_days`, `risk_band`, and structured `primary_cause_category` / `contributing_factors`).
- **Gestational Loss Stages & Lifecycle Transitions:**
  1. **Pre-Implantation / Early Embryonic Loss (`PRE_IMPLANTATION_LOSS`, `CONCEIVED` → `DECEASED`, ~0–14 days post-fertilization):** Fertilization succeeds and diploid DNA is synthesized, but embryonic cleavage arrests or implantation fails before sustained clinical gestation begins (`is_clinically_recognized = false`). Evaluated right after `sim-dna` finalizes diploid DNA (toggleable via `prenatal_loss.track_pre_implantation_loss`).
  2. **Early Pregnancy Loss / First-Trimester Miscarriage (`EARLY_MISCARRIAGE`, `GESTATING` → `DECEASED`, ~weeks 5–12 of gestation):** Clinically recognized first-trimester loss (`is_clinically_recognized = true`), representing the largest share of recognized prenatal losses and predominantly driven by embryonic chromosomal/genetic viability, oocyte/sperm quality, maternal age, and luteal/hormonal support.
  3. **Second-Trimester / Late Miscarriage (`LATE_MISCARRIAGE`, `GESTATING` → `DECEASED`, ~weeks 13–19 of gestation):** Clinically recognized mid-gestation loss (`is_clinically_recognized = true`), progressively influenced by maternal hemodynamic/placental perfusion, maternal-fetal RhD alloimmunization, immune/metabolic health, and extreme body composition.
  4. **Late Fetal Demise / Stillbirth (`STILLBIRTH`, `GESTATING` → `DECEASED`, ≥20 weeks of gestation up to scheduled delivery):** Rare late-gestation prenatal loss prior to live birth (`is_clinically_recognized = true`), driven by hypertensive/placental insufficiency, sensitized RhD incompatibility, severe metabolic/respiratory/cardiovascular burden, extreme maternal BMI/visceral fat, and post-term gestational overshoot.
- **Available Simulation Data & Biological Reasons Feeding `sim-prenatal-loss`:**
  Rather than using a flat random roll, `sim-prenatal-loss` synthesizes every relevant biological, genetic, health, and clinical signal already modeled in PrincessPink using versioned read-only SQLite baseline hazard curves and risk-factor odds ratios:

  | Data Source in PrincessPink | Biological Reasons & Modeled Risk Mechanisms | Structured Cause Categories |
  | :--- | :--- | :--- |
  | **Diploid `GENOME`, `EGG_CELL`, `SPERM_CELL`, `EJACULATION_DB` (`sim-dna`, `sim-egg-reserve`, `sim-ejaculation`)** | Meiotic nondisjunction / chromosomal aneuploidy correlated with maternal oocyte age and selected `EGG_CELL.quality_score`; paternal gamete DNA integrity reflected by winning `SPERM_CELL.morphology` & `viability`, `EJACULATION_DB.ejaculation_quality`, and short-interval decay `quality_factor`; lethal homozygous recessive allele combinations or rare deleterious de novo mutations in diploid `GENOME` (naturally reflecting close pedigree relatedness from `CHARACTER_PARENT` lineage). | `CHROMOSOMAL_ANOMALY`, `LETHAL_GENETIC_LOAD` |
  | **Maternal & Paternal Age and Reproductive Stage (`CHARACTER.date_of_birth`, `CHARACTER_INTERCOURSE_PROFILE`, `EGG_RESERVE_DB`)** | U-shaped maternal age hazard curve (mildly elevated risk in early post-menarche adolescence, lowest baseline risk in prime young adulthood ~20–29, progressive increase ≥30, steep rise ≥35–40 through `climacterium_state == PERIMENOPAUSAL` and depleted `remaining_egg_count` / low `fertility_score`); modest independent paternal age increase in early chromosomal loss (>40–45). | `MATERNAL_AGE_FACTOR`, `PATERNAL_AGE_FACTOR` |
  | **Maternal-Fetal Blood Type & RhD Status (`CHARACTER.blood_type`, `CHARACTER.rh_sensitized`)** | Sensitized `Rh-` mother (`rh_sensitized == true`) carrying an `Rh+` fetus carries substantially elevated second-trimester and late fetal loss hazard (hemolytic disease / hydrops), modulated by `prenatal_care_tier` and RhIg prophylaxis; modest maternal non-`O` (`A`, `B`, `AB`) vascular/thrombotic predisposition subtly raises placental perfusion risk when combined with elevated blood pressure or cardiovascular strain. | `RH_INCOMPATIBILITY`, `PLACENTAL_VASCULAR_FACTOR` |
  | **Maternal Health & Fitness Indicators (`CHARACTER_HEALTH_PROFILE`, `sim-health`)** | `heart_health == ILL` and excessive gestational `waking_heart_rate_bpm` strain (placental hypoperfusion); `blood_pressure` (`HIGH` / gestational hypertension); `metabolic_health` (`IMPAIRED` / `BORDERLINE` glycemic-endocrine instability); `immune_health` (`COMPROMISED` / `BELOW_AVERAGE` natural infectious/immunological vulnerability); `respiratory_health` (`IMPAIRED` / low `vo2_max_ml_kg_min` oxygenation limit); `sleep_recovery_quality == POOR` & chronic `stress_level` (`ELEVATED` / `HIGH` endocrine/allostatic disruption); extreme `muscle_condition` (`WEAK` frailty or severe athletic energy deficit with very low body fat). Healthy indicators (`HEALTHY_SPORTY`/`HEALTHY_NORMAL`, `OPTIMAL` metabolic/sleep, `ROBUST` immune) act protectively. | `CARDIOVASCULAR_PLACENTAL`, `HYPERTENSIVE_PLACENTAL`, `METABOLIC_ENDOCRINE`, `IMMUNE_INFECTIOUS`, `OXYGENATION_LIMITATION`, `ALLOSTATIC_STRESS` |
  | **Maternal Anthropometrics & Body Composition (`height_cm`, `weight_kg`, `BMI`, `body_fat_percentage`, `visceral_fat_rating`, `WEIGHT_ADJUSTMENT`)** | Severe maternal underweight / critically low `body_fat_percentage` (nutritional/endocrine insufficiency) and severe obesity / high `BMI` & elevated `visceral_fat_rating` (pro-inflammatory, metabolic, and hypertensive placental burden), plus abrupt negative gestational weight shifts recorded in bounded GM `WEIGHT_ADJUSTMENT` history. | `BODY_COMPOSITION_FACTOR` |
  | **6 AD&D-Style Reproduction Attributes (`CON`, `HOR`, `REC`, `VIT`, `FER`)** | Maternal `CON` (gestation physiological resilience), `HOR` (luteal progesterone & endocrine pregnancy maintenance), `REC` (endometrial implantation receptivity), and parental `VIT` / `FER` (gamete and cellular vigor) directly scale stage-specific survival probabilities. | `HORMONAL_INSUFFICIENCY`, `IMPLANTATION_FAILURE` |
  | **Obstetric History, Medications & Gestational Timing (`PREGNANCY`, `CHARACTER_MEDICAL_DRUG`, `sim-birth-date`)** | Prior consecutive `PRENATAL_LOSS` outcomes in maternal `PREGNANCY` history modestly raise recurrent-loss baseline hazard; short inter-pregnancy intervals following a recent live birth or late loss reflect incomplete maternal recovery; rare breakthrough conceptions occurring while `CONTRACEPTION_PILL` remains active experience elevated early implantation/hormonal instability; post-term gestational duration overshoot (`>41–42` weeks from `sim-birth-date`) modestly raises late placental-aging hazard. | `RECURRENT_LOSS_HISTORY`, `SHORT_INTERPREGNANCY_INTERVAL`, `MEDICATION_IMPLANTATION_FACTOR`, `POST_TERM_PLACENTAL_AGING` |

- **Per-Group Configuration (`GROUP.simulation_config` — Default On, GM-Configurable):**
  Recognizing both scientific realism and tabletop campaign sensitivity, prenatal loss is **enabled by default** and configurable per Group by the Group's Game Master (with immutable audit logging in `user_admin.audit_logs`):
  - `prenatal_loss.enabled` (`bool`, default `true`): Enables or disables prenatal loss evaluation for the Group. When set to `false`, all conceptions proceed from `CONCEIVED` → `GESTATING` → `ALIVE` with zero prenatal loss.
  - `prenatal_loss.prenatal_care_tier` (`HISTORICAL | STANDARD | ADVANCED`, default `STANDARD`): Models population-level clinical prenatal care—scaling preventable hypertensive, metabolic, infectious, post-term, and RhD alloimmunization hazards (including RhIg prophylaxis coverage that prevents maternal `rh_sensitized` conversion after an `Rh+` birth or prenatal loss).
  - `prenatal_loss.risk_multiplier` (bounded float, e.g., `0.25–2.0`, default `1.0`): Bounded scientific calibration scalar allowing Game Masters to soften or intensify baseline hazards within physiological guardrails.
  - `prenatal_loss.track_pre_implantation_loss` (`bool`, default `true`): Controls whether subclinical `CONCEIVED` → `DECEASED` pre-implantation losses are evaluated and logged separately or only clinically recognized `GESTATING` → `DECEASED` losses are simulated.
- **Downstream Simulation & Maternal Recovery Effects on Prenatal Loss:**
  1. **Character Record & Ownership Cleanup (`character-registry`):** Transitions the unborn character to `lifecycle_state = DECEASED`, records `date_of_death` (leaving `date_of_birth = null`), finalizes `PREGNANCY` (`outcome = PRENATAL_LOSS`, `loss_stage`, `gestational_age_days`, `primary_cause_category`, `contributing_factors`, `service_version`), and automatically closes any `PENDING` `OWNERSHIP_AGREEMENT` as `CLOSED_PRENATAL_LOSS`.
  2. **No Newborn Initialization:** `sim.character.born` is **not** emitted; newborn-only pipelines (`sim-egg-reserve`, `sim-menarche`, newborn `sim-health`, and `sim-mortality`) are never invoked for a prenatal loss.
  3. **Gestation Termination & RhD Sensitization (`sim-gestation`):** Halts active gestation tracking, cancels the scheduled `date_of_birth`, and evaluates whether an unsensitized `Rh-` mother carrying an `Rh+` fetus beyond pre-implantation becomes `rh_sensitized = true` (governed by `prenatal_care_tier` / RhIg prophylaxis).
  4. **Maternal Physiological Recovery (`sim-health`, `sim-menstruation`, `sim-lifecycle`):** Gradually reverts pregnancy hemodynamic shifts (`waking_heart_rate_bpm`, blood pressure, pregnancy weight trajectory) and applies a bounded stage-proportional physiological recovery period (`stress_level`, `sleep_recovery_quality`) in `sim-health`; transitions the mother out of the `pregnant` ovarian cycle state in `sim-menstruation` so follicular recruitment and ovulation resume after a stage-appropriate recovery interval; and restores non-pregnant `fertility_score` and `CHARACTER_INTERCOURSE_PROFILE` baselines in `sim-lifecycle`.

---

## 3. System Architecture Overview

### 3.1 Architectural Style
PrincessPink follows a **distributed microservices architecture** written exclusively in **Go** (see [ADR-0011](architecture/ADR-0011-go-as-sole-programming-language.md)) and deployed on **Kubernetes** via **Microsoft Azure Kubernetes Service (AKS)**. Services are organized into five primary functional domains:
1. **Frontend Microservices (Go + Gin)** — UI rendering, BFF aggregation, auth/session handling, real-time chat UI/WebSocket edge, and user experience.
2. **User Administration Service** — Identity, authentication, RBAC/group authorization, backed by central **PostgreSQL**.
3. **Character Sheet & Attribute Microservices** — Composable character sheet aggregation with one dedicated microservice per calculated attribute/value.
4. **Scientific Simulation Microservices** — Discrete biological process services coordinated via synchronous RPCs and asynchronous domain events, using **local SQLite** databases where appropriate.
5. **Real-Time Chat & Communication Microservices** — Global Chat (World of Warcraft-style), Group Chat (Game Master and Group members), and 1-to-1 Direct Messaging between Players.

### 3.2 High-Level Architecture Diagram

```mermaid
flowchart TB
    Client[Web Browser / Player & GM] --> Ingress[Azure Front Door / AKS Ingress + TLS]

    subgraph AKS["Azure Kubernetes Service (AKS)"]
        subgraph FrontendNS["Namespace: frontend (Go + Gin)"]
            AuthGW[Auth / Session Gateway]
            SheetUI[Character Sheet Web Service]
            GMUI[Game Master Dashboard Service]
            PortraitUI[Comic Portrait Service]
            ChatUI[Chat UI / WebSocket Gateway]
        end

        subgraph AuthNS["Namespace: user-admin"]
            UserAdmin[User & Group Admin Service]
        end

        subgraph ChatNS["Namespace: chat"]
            ChatSvc[Chat Service\nWorld / Group / 1-to-1 DM]
            ChatWorldReg[World Chat Server Registry]
        end

        subgraph SheetNS["Namespace: character-sheet"]
            SheetAgg[Character Sheet Aggregator]
            CharReg[Character Registry Service]
            AttrAge[Attr: Biological Age]
            AttrFert[Attr: Fertility Index]
            AttrGen[Attr: Genetic Traits]
            AttrHorm[Attr: Hormonal State]
            AttrLineage[Attr: Lineage & Pedigree]
            AttrN[Attr: ... N Attribute Services]
        end

        subgraph SimNS["Namespace: simulation"]
            SimClock[Simulation Clock Service]
            EggReserve[Egg-Cell Reserve Service]
            EggSelect[Egg-Cell Selection Service]
            Menarche[First Menstruation Service]
            Menstruation[Menstruation Cycle Service]
            Ejaculation[Ejaculation Service]
            SpermRace[Race-to-the-Egg Service]
            GameteSurface[Gamete Surface Compatibility Service]
            Conception[Conception Service]
            DNACalc[DNA Calculation Service]
            PrenatalLoss[Prenatal Loss Service]
            BirthDate[Birth Date Calculation Service]
            Gestation[Gestation Service]
            HealthSim[Health & Fitness Simulation Service]
            Mortality[Date of Death Service]
            Lifecycle[Lifecycle Service]
        end

        EventBus[(Event Bus / Message Broker\nNATS JetStream or Azure Service Bus)]
    end

    PG[(Central PostgreSQL\nAzure Database for PostgreSQL)]

    Ingress --> AuthGW
    AuthGW --> SheetUI
    AuthGW --> GMUI
    AuthGW --> PortraitUI
    AuthGW --> ChatUI

    AuthGW --> UserAdmin
    ChatUI --> ChatSvc
    ChatUI --> ChatWorldReg
    ChatSvc --> ChatWorldReg
    ChatSvc --> UserAdmin
    ChatSvc --> PG
    ChatWorldReg --> PG
    EventBus <--> ChatSvc
    EventBus <--> ChatWorldReg
    UserAdmin --> PG
    CharReg --> PG

    SheetUI --> SheetAgg
    SheetAgg --> CharReg
    SheetAgg --> AttrAge
    SheetAgg --> AttrFert
    SheetAgg --> AttrGen
    SheetAgg --> AttrHorm
    SheetAgg --> AttrLineage
    SheetAgg --> AttrN

    SimClock --> EventBus
    EventBus <--> EggReserve
    EventBus <--> EggSelect
    EventBus <--> Menarche
    EventBus <--> Menstruation
    EventBus <--> Ejaculation
    EventBus <--> SpermRace
    EventBus <--> GameteSurface
    EventBus <--> Conception
    EventBus <--> DNACalc
    EventBus <--> PrenatalLoss
    EventBus <--> BirthDate
    EventBus <--> Gestation
    EventBus <--> HealthSim
    EventBus <--> Mortality
    EventBus <--> Lifecycle
    EventBus <--> CharReg
```

### 3.3 Repository & Go Workspace Layout
The repository is structured as a Go multi-module workspace (`go.work`) to keep shared contracts and service implementations cleanly separated:

```text
princesspink/
├── go.work                  # Go workspace coordinating shared libs and services
├── Makefile                 # Common build, test, lint, and container targets
├── libs/                    # Shared Go libraries (proto/gRPC contracts, auth middleware,
│                            #   UUID helpers, telemetry, common errors, config)
├── services/                # Independently deployable Go microservices
│   ├── frontend-gateway/
│   ├── frontend-sheets/
│   ├── frontend-gm/
│   ├── frontend-chat/       # In-app chat UI, World Server selector & WebSocket edge gateway
│   ├── chat-service/        # World, Group (GM + Players), and 1-to-1 DM chat service
│   ├── chat-world-registry/ # World Chat Server directory, live occupancy & server selection
│   ├── user-admin/
│   ├── character-registry/
│   ├── sheet-aggregator/
│   ├── attr-*/              # Dedicated attribute calculation microservices
│   ├── portrait-renderer/
│   ├── sim-clock/
│   ├── sim-egg-reserve/     # Generates & stores newborn girl's egg cells in UUID-linked SQLite DB
│   ├── sim-egg-selection/   # Determines which egg cell drops during the girl's next cycle
│   ├── sim-menarche/        # Calculates date of first menstruation for a young girl
│   ├── sim-menstruation/
│   ├── sim-ejaculation/
│   ├── sim-sperm-race/
│   ├── sim-gamete-surface/
│   ├── sim-conception/
│   ├── sim-dna/
│   ├── sim-prenatal-loss/   # Evaluates prenatal pregnancy loss risk & outcomes across implantation & gestation
│   ├── sim-birth-date/      # Calculates date of birth from mother's last menstruation or conception date
│   ├── sim-gestation/
│   ├── sim-health/          # Simulates heart health, lifecycle waking HR, muscle condition & clinical health indicators
│   ├── sim-mortality/       # Calculates natural date of death for each character
│   └── sim-lifecycle/
├── docs/
│   ├── Concept.md           # This technical concept
│   ├── api/                 # OpenAPI & Protobuf API specifications
│   ├── architecture/        # ADRs, sequence diagrams, infrastructure specs
│   └── runbooks/            # Operational & incident response runbooks
└── .github/workflows/       # CI/CD pipelines (lint, test, build, deploy)
```

### 3.4 Inter-Service Communication Patterns
- **External / Frontend HTTP & WebSockets:** REST/HTML over HTTPS using the **Gin** framework, plus authenticated **WebSockets** over TLS (`wss://`) in `frontend-chat` for real-time bi-directional Global, Group, and 1-to-1 Direct Message chat delivery.
- **Internal Synchronous RPC:** **gRPC with Protocol Buffers** (`libs/proto`, see [ADR-0005](architecture/ADR-0005-shared-grpc-protobuf-contracts.md)) for low-latency, strongly typed internal calls (especially the high fan-out from `sheet-aggregator` to individual `attr-*` services, authorization/group-membership checks against `user-admin`, and direct calculation queries to `sim-prenatal-loss`, `sim-birth-date`, `sim-egg-selection`, `sim-menarche`, `sim-health`, and `sim-mortality`).
- **Internal Asynchronous Events:** An event broker (**NATS JetStream** inside AKS or **Azure Service Bus**) for decoupled, reliable propagation of simulation ticks, clock lifecycle changes, chat pub/sub fan-out across pods, and biological/character lifecycle events (e.g., `sim.clock.started`, `sim.clock.stopped`, `sim.clock.resumed`, `sim.clock.config.updated`, `sim.tick.advanced`, `sim.egg_reserve.created`, `sim.menarche.calculated`, `sim.egg.selected`, `sim.ovulation.triggered`, `sim.climacterium.reached`, `sim.conception.occurred`, `sim.dna.calculated`, `sim.prenatal_loss.evaluated`, `sim.prenatal_loss.occurred`, `sim.birthdate.calculated`, `sim.character.born`, `character.weight.updated`, `character.health.updated`, `character.intercourse.updated`, `sim.health.updated`, `sim.fertility.updated`, `character.medication.updated`, `sim.deathdate.calculated`, `sim.character.deceased`).
- **Correlation & Idempotency:** Every request and event carries a `correlation_id`, `group_id`, and `character_uuid` (standardized on RFC 9562 UUIDv7 via `libs/uuid`, see [ADR-0007](architecture/ADR-0007-shared-uuid-utilities.md)). Event consumers must be idempotent to safely handle at-least-once delivery.

### 3.5 Independent Microservice Versioning
Every microservice in PrincessPink has **its own independent version number** (following **Semantic Versioning**, `MAJOR.MINOR.PATCH`, e.g., `1.3.0`) rather than sharing a single monolithic platform release version:
- **Per-Service Ownership & Release Cadence:** Each service directory under `services/<service-name>/` maintains its own version metadata (e.g., a `VERSION` file and scoped Git release tags such as `sim-gamete-surface/v1.2.0` or `attr-eye-color/v0.4.1`). This lets scientific models, attribute calculators, and frontend services evolve, test, and deploy independently.
- **Runtime Introspection & Contracts:** Each service embeds its version at build time (`-ldflags`) and exposes it via `/healthz` / `/version` endpoints, gRPC response payloads/metadata (e.g., `service_version`), OpenTelemetry `service.version` resource attributes, and structured log entries.
- **Scientific Reproducibility & Deployment Traceability:** Container images pushed to Azure Container Registry (ACR) and deployed to AKS are tagged with each microservice's own version number. Simulation events and character sheet calculations record the producing microservice version so historical outcomes remain fully auditable even as individual biological models are refined.

---

## 4. Subsystem Specifications

### 4.1 Frontend Microservices (Go + Gin)
The frontend is composed of multiple Go microservices built with the **Gin** HTTP framework, following a Backend-for-Frontend (BFF) / micro-frontend architecture:

| Service | Responsibilities |
| :--- | :--- |
| `frontend-gateway` | Edge routing, authentication/session management (interacting with `user-admin`), CSRF protection, rate limiting, and authorization context injection. |
| `frontend-sheets` | Renders the pen-and-paper character sheet UI, displays the Player's multi-character roster, handles single-character selection at Group start, character naming, parental child-ownership agreements, gender-filtered **Medical Drugs (Role Play)** checkboxes, **Role-Play Lifestyle & Training Profile** controls (influencing health indicators such as waking heart rate, heart health, and muscles), gender-filtered **Intercourse & Fertility Values** (`fertility_score` `0–100`, `erection_quality`, `ejaculation_quality`, `vaginismus`, `libido_score`, `lubrication_quality`, `refractory_period_minutes`, `intercourse_stamina`, `climacterium_state`), clinical **Pregnancy Status & Outcome History** (gestation progress, abstract risk band, and non-graphic historical live-birth/prenatal-loss outcomes, plus clean historical sheets for `DECEASED` prenatal-loss records), and allowed player actions. |
| `frontend-gm` | Game Master portal for managing groups, inviting/assigning players, verifying group-start character selections, inspecting all group player characters and NPC children, applying bounded role-play `weight_kg`, health-indicator, and clinical intercourse-state (e.g., `vaginismus`) adjustments, entering the mandatory simulation start date (`dd/MM/YYYY`, starting at `0:00 h`), adjusting the per-group simulation tick rate (default: 1 simulated year = 24 hours real time), stopping/resuming the simulation tick for role-play, configuring per-group **prenatal loss** settings in `GROUP.simulation_config` (enabled by default, `prenatal_care_tier`, bounded `risk_multiplier`, pre-implantation tracking, or opt-out toggle for sensitive campaigns), viewing group population/pregnancy analytics, and configuring group parameters. |
| `frontend-chat` | Renders the in-app chat interface (Global / World Chat with World Chat Server selector, Group Chat, and 1-to-1 Direct Messages) and manages authenticated WebSocket connections to `chat-service` and `chat-world-registry`. |
| `portrait-renderer` | Generates and serves comic-style face portraits (SVG or rasterized PNG/WebP) from a character's phenotypic facial traits and age stage. |

**UI/UX Design Principles:**
- **Pen-and-Paper Character Sheet Aesthetic:** Structured layout inspired by classic tabletop RPG sheets—Header (Player-assigned Name, Character UUID, Gender, immutable **Blood Type** [`A+`..`O-`], Lifecycle Status including clinical `DECEASED (Prenatal Loss)` indicator when applicable, Comic Face Portrait for born characters), Visible Appearance (`eye_color`, `hair_color`, `skin_color` reflecting current life-stage pigmentation), Physical & Medical Body Composition (`height_cm`, `weight_kg`, `BMI`, Body Fat Index/Percentage, Lean Body Mass, Skeletal Muscle Mass, Total Body Water, Bone Mass, Visceral Fat Rating, BMR, BSA, Ideal Weight Range), **Health & Fitness Indicators** (`heart_health`, lifecycle-simulated & role-play-influenced `waking_heart_rate_bpm`, `muscle_condition`, `blood_pressure`, `respiratory_health` / `VO2 max`, `metabolic_health`, `immune_health`, `sleep_recovery_quality`, `stress_level`, plus Role-Play Lifestyle & Training controls), **Intercourse & Fertility Values** (universal `fertility_score` `0–100`, `libido_score`, and `intercourse_stamina`, plus gender-filtered male `erection_quality`, `ejaculation_quality`, `refractory_period_minutes` or female `vaginismus`, `lubrication_quality`, `climacterium_state`), Core AD&D-Style Reproduction Attributes (`FER`, `CON`, `VIT`, `HOR`, `REC`, `COM` with scores and modifiers), **Medical Drugs (Role Play)** (gender-filtered checkboxes allowing the Player to toggle active medical drugs such as Viagra for males or the Contraception Pill for females), Core Biological Stats, Genetic & Hereditary Summary (including ABO/RhD allele breakdown and female `rh_sensitized` status when applicable), Reproductive Cycle & Clinical Pregnancy Status Indicators (gestational progress, abstract `risk_band`, and non-graphic obstetric outcome history), and Lineage/Event History.
- **Rendering Strategy:** Server-rendered HTML templates (Go `html/template` or `templ`) enhanced with lightweight progressive interactivity (e.g., HTMX) or a clean JSON API served by Gin—keeping the entire frontend stack Go-native and fast.

---

### 4.2 User Administration & Security Service
The `user-admin` microservice is the authoritative source of identity, group membership, and access control, backed by a **central PostgreSQL database** (see [ADR-0010](architecture/ADR-0010-user-admin-auth-rbac-and-group-management.md)).

#### Core Responsibilities
- User registration, login, logout, password reset, and profile management.
- Issuing and validating authentication credentials (UUID-keyed user identities).
- Managing Groups (campaigns), Game Master / Player memberships, and enforcing the **one-character-per-player-per-group** selection rule at Group start.
- Answering authorization queries (e.g., *"Can User `U` view/act on Character `C`?"*, *"Can User `U` select Character `C` for Group `G`?"*).

#### State-of-the-Art Security Measures
- **Password Hashing:** `Argon2id` with per-user cryptographically random salts and tuned memory/iteration parameters.
- **Authentication & Sessions:** OAuth 2.0 / OpenID Connect (OIDC) compatible token flow or secure, `HttpOnly`, `Secure`, `SameSite=Strict` session cookies paired with short-lived signed JWTs (Ed25519 / RS256) and rotating refresh tokens with reuse detection.
- **Multi-Factor Authentication (MFA):** Support for TOTP (RFC 6238) and optional WebAuthn/Passkeys, strongly recommended for Game Masters.
- **Authorization Model (RBAC + Ownership/Group Scoping):**
  - `PLAYER`: Read/roster access to all characters where `character.owner_user_id == current_user.id`; within any Group `G`, active play access is restricted to the single Character selected by the Player at the start of Group `G` (`GROUP_MEMBERSHIP.selected_character_id`), which must be already owned by the Player and **must not** have been conceived/born in Group `G` (`character.origin_group_id != G`). For their active/owned living character, a Player may also toggle gender-eligible **Medical Drugs** via checkboxes on the character sheet (validated against `character.gender` and lifecycle state) and update their character's **Role-Play Lifestyle & Training Profile** (validated against lifecycle state). Players of a child's biological mother and father may also initiate and confirm the child's `OWNERSHIP_AGREEMENT` while the child is an unowned NPC (`owner_user_id == null`).
  - `GAME_MASTER`: Read/supervisory access to all active player characters and NPC children living in `managed_groups(current_user.id)`, permission to initialize the Group's simulation start date (`dd/MM/YYYY` at `0:00 h`), adjust the Group's per-group simulation tick configuration and prenatal-loss settings (`prenatal_loss.enabled`, `prenatal_care_tier`, bounded `risk_multiplier`, `track_pre_implantation_loss`), stop and resume the Group's simulation tick for role-play, and adjust character `weight_kg` and bounded role-play health indicators (`heart_health`, `waking_heart_rate_bpm` modifiers, `muscle_condition`, etc.) within the Group's configured biological/role-play parameters (`GROUP.simulation_config`).
  - Enforcement occurs at both `frontend-gateway` (coarse-grained) and backend services such as `sheet-aggregator` / `character-registry` (fine-grained defense in depth).
- **Transport & Service Security:** TLS 1.3 externally; mTLS internally between Kubernetes pods.
- **Audit Logging:** Immutable audit trail in PostgreSQL recording authentication events, role/group changes, GM access to player character sheets, GM simulation clock and `GROUP.simulation_config` operations (start-date initialization, per-group sim tick rate adjustments, stop/resume actions, and prenatal-loss configuration changes), GM role-play `weight_kg` adjustments (capturing old/new values and rationale), Player role-play lifestyle/training and GM bounded health-indicator adjustments (`HEALTH_ADJUSTMENT`), and Player role-play medical drug checkbox changes.

---

### 4.3 Character Sheet & Attribute Microservices
To maximize modularity, independent scaling, and scientific maintainability, **each attribute or derived value displayed on a character sheet is computed by a dedicated Go microservice**.

#### Components
1. **Character Registry (`character-registry`):** Owns the canonical character record (`UUID`, nullable `owner_user_id`, `origin_group_id`, player-assigned `name`, `gender`, immutable `blood_type`, female `rh_sensitized` status, `lifecycle_state`, `date_of_birth`, `date_of_death`, `height_cm`, `weight_kg`, `mother_uuid`, `father_uuid`, and immutable diploid genome reference), pregnancy & prenatal-loss outcome records (`PREGNANCY`), parental child-ownership agreements (`OWNERSHIP_AGREEMENT`), GM role-play weight adjustment history (`WEIGHT_ADJUSTMENT`), current character health & fitness profiles (`CHARACTER_HEALTH_PROFILE`), current intercourse & fertility profiles (`CHARACTER_INTERCOURSE_PROFILE`), role-play lifestyle and GM health/intercourse adjustment history (`HEALTH_ADJUSTMENT`), and active/historical character medical drug selections (`CHARACTER_MEDICAL_DRUG`) in PostgreSQL. Enforces that conceived/born children start as unowned NPCs, transitions ownership only upon mutual agreement between the mother's and father's Players (and automatically closes `PENDING` agreements as `CLOSED_PRENATAL_LOSS` upon `sim.prenatal_loss.occurred` while setting `lifecycle_state = DECEASED`, recording `date_of_death`, and preserving `date_of_birth = null`), prevents a child from being selected as a playable character in its `origin_group_id`, validates any GM `weight_kg` or bounded health/intercourse-indicator adjustment against the Group's configured biological/role-play parameter bounds before persisting and publishing `character.weight.updated` / `character.health.updated` / `character.intercourse.updated`, and validates Player lifestyle/training updates and medical drug checkbox toggles against character ownership, `gender` eligibility, and lifecycle state before persisting and publishing `character.health.updated` / `character.medication.updated`.
2. **Character Sheet Aggregator (`sheet-aggregator`):**
   - Receives a sheet request for `character_uuid` (after verifying Player/GM authorization).
   - Fetches canonical metadata (including `gender`, `blood_type`, female `rh_sensitized`, `date_of_birth`, `date_of_death`, `lifecycle_state`, `height_cm`, `weight_kg`, `PREGNANCY` status/history, current `CHARACTER_HEALTH_PROFILE`, current `CHARACTER_INTERCOURSE_PROFILE`, and active medical drugs) from `character-registry` and executes a **concurrent parallel fan-out** (via Go `errgroup` + gRPC with strict per-call deadlines) to all applicable universal and **gender-specific** Attribute Microservices.
   - Aggregates results into a unified `CharacterSheet` response.
   - Supports **graceful degradation**: if a non-critical attribute service is temporarily unavailable, the sheet still renders with a clearly marked `"unavailable"` field rather than failing the entire page.
   - Caches short-lived attribute results keyed by `(character_uuid, sim_tick)` (invalidated immediately upon `character.weight.updated`, `character.health.updated`, `character.intercourse.updated`, `sim.health.updated`, `sim.fertility.updated`, `character.medication.updated`, `sim.prenatal_loss.evaluated`, and `sim.prenatal_loss.occurred` events) to avoid redundant recomputation when simulation time has not advanced.
3. **Standardized Attribute Microservice Contract:**
   Every `attr-*` microservice implements a shared gRPC interface defined in `libs/proto/attribute/v1`:
   ```protobuf
   service AttributeCalculator {
     rpc Calculate(CalculateRequest) returns (CalculateResponse);
   }
   ```
   - `CalculateRequest`: `character_uuid`, `sim_tick`, optional context snapshot (`gender`, `blood_type`, `rh_sensitized`, `date_of_birth`, `date_of_death`, `height_cm`, `weight_kg`, health & fitness profile snapshot, intercourse & fertility profile snapshot, active medical drugs, genome digest, lifecycle state).
   - `CalculateResponse`: `attribute_key`, `display_name`, `value`, `unit`, `confidence_or_range`, `computed_at_tick`, `schema_version`, `service_version`.
   - Examples of Attribute Microservices:
     - `attr-biological-age` (chronological & developmental stage derived from `date_of_birth` and `date_of_death` / current `sim_tick`)
     - `attr-blood-type` (immutable ABO + RhD **Blood Type** [`A+`, `A-`, `B+`, `B-`, `AB+`, `AB-`, `O+`, `O-`] derived from diploid DNA, Mendelian allele summary [`I^A`/`I^B`/`i`, `D`/`d`], maternal `rh_sensitized` status for `Rh-` females, and blood/maternal-fetal compatibility indicators)
     - `attr-height` (current `height_cm` derived from polygenic genotype, age, and developmental growth trajectory)
     - `attr-weight` (current `weight_kg` reflecting developmental/gestational trajectory and any bounded GM role-play weight adjustments)
     - `attr-bmi` (**Body Mass Index (`kg/m²`)** and WHO/age-adjusted classification band derived from `height_cm`, `weight_kg`, `gender`, and age)
     - `attr-body-fat-index` (**Body Fat Percentage (`%`) & Body Fat Index** estimated from `height_cm`, `weight_kg`, `gender`, age, `muscle_condition`, and genotype/hormonal modifiers)
     - `attr-lean-body-mass` (**Lean Body Mass / Fat-Free Mass (`kg`)** derived from `height_cm`, `weight_kg`, `gender`, `muscle_condition`, and body fat composition)
     - `attr-muscle-mass` (**Skeletal Muscle Mass (`kg` & `%`)** estimated for the character's sex, age, `muscle_condition`, and body composition)
     - `attr-body-water` (**Total Body Water (`%` & `L`)** estimated hydration share and volume)
     - `attr-bone-mass` (**Estimated Bone Mass (`kg`)** reflecting skeletal mineral mass across growth, muscular loading, and aging)
     - `attr-visceral-fat` (**Visceral Fat Rating (index)** estimating abdominal adipose level)
     - `attr-bmr` (**Basal Metabolic Rate (`kcal/day`)** resting daily energy expenditure via Mifflin-St Jeor adjusted for `muscle_condition` / lean mass)
     - `attr-body-surface-area` (**Body Surface Area (`m²`)** clinical BSA via Mosteller/Du Bois)
     - `attr-ideal-weight` (**Ideal / Healthy Weight Range (`kg`)** reference band for current height, sex, and age)
     - `attr-heart-health` (**Heart Health** classification: `ILL`, `HEALTHY_NOT_SPORTY`, `HEALTHY_NORMAL`, `HEALTHY_SPORTY`, derived from `sim-health`, genotype, body composition, and role-play lifestyle)
     - `attr-waking-heart-rate` (**Waking Heart Rate (`bpm`)** resting heart rate shortly after waking up, simulated across the character's lifecycle and influenced by role-play, with age-stage reference band)
     - `attr-muscle-condition` (**Muscles / Muscular Conditioning** tier: `WEAK`, `NORMAL`, `SPORTY`, `BODY_BUILDER`, reflecting lifecycle progression and role-play training/lifestyle)
     - `attr-blood-pressure` (**Blood Pressure (`mmHg`)** systolic/diastolic values and clinical band: `LOW`, `NORMAL`, `ELEVATED`, `HIGH`)
     - `attr-respiratory-health` (**Respiratory / Aerobic Health** tier: `IMPAIRED`, `BELOW_AVERAGE`, `NORMAL`, `ATHLETIC` and estimated `VO2 max`)
     - `attr-metabolic-health` (**Metabolic Health** tier: `IMPAIRED`, `BORDERLINE`, `NORMAL`, `OPTIMAL` reflecting glycemic and endocrine-metabolic stability)
     - `attr-immune-health` (**Immune Health** tier: `COMPROMISED`, `BELOW_AVERAGE`, `NORMAL`, `ROBUST` reflecting lifecycle defense and recovery resilience)
     - `attr-sleep-recovery` (**Sleep & Recovery Quality** tier: `POOR`, `FAIR`, `GOOD`, `OPTIMAL` reflecting role-play rest habits, stress, and pregnancy load)
     - `attr-stress-level` (**Stress & Allostatic Load** tier: `LOW`, `MODERATE`, `ELEVATED`, `HIGH` driven by role-play events and lifestyle)
     - `attr-eye-color` (current expressed eye color derived from genotype and age/developmental stage, accounting for post-birth and lifetime color changes)
     - `attr-hair-color` (current expressed hair color derived from genotype, age, and lifecycle state, accounting for post-birth darkening and age-related graying/whitening)
     - `attr-skin-color` (current expressed skin color derived from genotype, age, hormonal state, and environmental/seasonal modifiers)
     - `attr-repro-fertility` (AD&D-style **Fertility (`FER`)** score & modifier applied to reproduction tries)
     - `attr-repro-constitution` (AD&D-style **Constitution (`CON`)** score & modifier applied to reproduction tries and gestation stability)
     - `attr-repro-vitality` (AD&D-style **Vitality (`VIT`)** score & modifier influencing gamete vigor and endurance)
     - `attr-repro-hormonal-balance` (AD&D-style **Hormonal Balance (`HOR`)** score & modifier influencing cycle regularity and readiness)
     - `attr-repro-receptivity` (AD&D-style **Receptivity (`REC`)** score & modifier influencing fertile-window and implantation mechanics)
     - `attr-repro-compatibility` (AD&D-style **Compatibility (`COM`)** score & modifier influencing gamete surface-fit and fusion rolls)
     - `attr-menstruation-history` *(female-specific)* (`date_of_first_menstruation` / menarche, `date_of_first_ovulation`, `climacterium_state`, `climacterium_date`, historical `menstruation_dates`, current cycle phase & next predicted cycle, reflecting any active **Contraception Pill** cycle modulation and post-loss recovery intervals)
     - `attr-pregnancy-status` *(female-specific)* (active gestation progress/trimester, scheduled `date_of_birth`, abstract clinical `risk_band` [`LOW`, `MODERATE`, `ELEVATED`, `HIGH`] synthesized from `sim-prenatal-loss` without exposing raw RNG draws, and non-graphic obstetric outcome history of live births and clinically recognized prenatal losses)
     - `attr-spermatogenesis-profile` *(male-specific)* (`date_of_first_fertility`, baseline sperm count/motility/viability parameters, daily ejaculation frequency propensity, and short-interval ejaculation quality decay)
     - `attr-fertility-index` (**Fertility (`fertility_score`, `0–100`)** derived from age, `gender`, health indicators, and body-composition values: strictly `0` for females before first ovulation and at/after climacterium with young women more fertile than older women; strictly `0` for pre-pubertal boys, becoming fertile during teenage years, rising until ~age 21, and declining slowly thereafter)
     - `attr-erection-quality` *(male-specific)* (**Quality of Erection (`erection_quality`, `0–100`)** derived from age, cardiovascular/health/body-composition indicators, and active **Viagra** within safe hemodynamic bounds)
     - `attr-ejaculation-quality` *(male-specific)* (**Quality of Ejaculation (`ejaculation_quality`, `0–100`)** derived from age, `fertility_score`, health/body values, and short-interval decay `quality_factor`)
     - `attr-vaginismus` *(female-specific)* (**Vaginismus (`vaginismus`, boolean)** role-play and physiological penetrative-completion indicator, supporting audited Player/GM role-play progression)
     - `attr-libido` (**Libido / Reproductive Drive (`libido_score`, `0–100`)** derived from age, `gender`, hormones, health indicators, menstrual cycle phase, and active medications)
     - `attr-lubrication-quality` *(female-specific)* (**Lubrication / Mucosal Readiness (`lubrication_quality`, `0–100`)** derived from cycle phase, age/`climacterium_state`, hydration, hormones, stress, and active **Contraception Pill**)
     - `attr-refractory-period` *(male-specific)* (**Refractory / Recovery Period (`refractory_period_minutes`)** post-ejaculation recovery interval driven by age, cardiovascular/sleep/stress health, and **Viagra**)
     - `attr-intercourse-stamina` (**Intercourse Stamina (`intercourse_stamina`, `0–100`)** cardiopulmonary and muscular endurance derived from `heart_health`, `waking_heart_rate_bpm`, `VO2 max`, `muscle_condition`, `BMI`, sleep, and stress)
     - `attr-medical-drugs` (active gender-eligible medical drugs toggled by the Player and their derived pharmacological/reproductive modifiers)
     - `attr-hormonal-profile` (gender-specific abstracted endocrine indicators)
     - `attr-genetic-traits` (expressed Mendelian/polygenic phenotypic traits)
     - `attr-health-vitality` (overall biological vitality score synthesized from `heart_health`, `waking_heart_rate_bpm`, `muscle_condition`, `blood_pressure`, `respiratory_health`, `metabolic_health`, `immune_health`, `sleep_recovery_quality`, and `stress_level`)
     - `attr-lineage-depth` (generation number, mother/father, ancestors, live-born descendants, and permanent historical prenatal-loss lineage records)
     - `attr-portrait-traits` (structured facial feature vector—including current eye, hair, and skin colors—consumed by `portrait-renderer`)

---

### 4.4 Scientific Simulation Engine Microservices
The simulation engine decomposes human reproduction and life cycles into independent Go microservices. Each service encapsulates a specific biological subsystem and its scientific parameters.

#### Simulation Microservices Catalog

| Microservice | Biological Scope & Responsibilities | Storage |
| :--- | :--- | :--- |
| `sim-clock` | Manages independent per-group simulation time (discrete ticks / calendar dates) and publishes `sim.tick.advanced` events. Defaults to **1 simulated year per 24 hours real time**, allows each Group's Game Master to adjust the Group's sim tick rate and stop/resume ticks whenever role-play requires it, and requires a Game Master-entered start date (`dd/MM/YYYY`) starting strictly at `0:00 h` when launching a simulation. | PostgreSQL / State store |
| `sim-egg-reserve` | Triggered at the birth of every female character (`gender == FEMALE`). Generates all **egg cells (oocytes)** the girl carries with her at birth—each with its unique haploid DNA (22 autosomes + `X` via simulated meiosis from her diploid DNA), surface receptor profile, and baseline quality/viability traits—and stores them in a **dedicated SQLite database explicitly linked to the girl's `character_uuid`**. | Local SQLite (meiosis & receptor reference tables) + **Per-Female-Character Egg-Reserve SQLite DB** (linked to `character_uuid`) |
| `sim-egg-selection` | Opens the **Egg-Cell SQLite database linked to a post-menarche female character's `character_uuid`** and determines **which specific egg cell drops (ovulates) during her next cycle** (modeling follicular recruitment, atresia, and dominant follicle selection modulated by age, `fertility_score`, `FER`, `HOR`, `REC`, subtle versioned ABO blood-type ovarian-reserve variance, maternal health & body-composition indicators such as `metabolic_health`, `immune_health`, `heart_health`, `BMI`, `body_fat_percentage`, and `stress_level`, and active medical drugs such as the **Contraception Pill**, which suppresses or strongly inhibits ovulation). Halts ovulation once `climacterium_state == CLIMACTERIC` (`fertility_score == 0`) or `remaining_egg_count == 0`. Marks the chosen egg cell as selected/ovulated and supplies its haploid DNA and surface profile to `sim-menstruation`, `sim-gamete-surface`, and `sim-conception`. | Local SQLite (follicular selection & atresia curves) + reads/updates **Per-Female-Character Egg-Reserve SQLite DB** |
| `sim-menarche` | Calculates for a young female character (**Girl**) when her **first menstruation (menarche)** will occur (`date_of_first_menstruation`), based on her `date_of_birth`, genotype, developmental trajectory, hormonal/health attributes (`HOR`, `CON`, `VIT`), and health/body indicators (`metabolic_health`, `heart_health`, `BMI`, `body_fat_percentage`, `muscle_condition` / athletic energy balance, and `stress_level`). Publishes `sim.menarche.calculated` to `character-registry` and `sim-menstruation`. | Local SQLite (pubertal onset & menarche statistical distributions) |
| `sim-menstruation` | Tracks female-specific reproductive milestones (`date_of_first_menstruation` from `sim-menarche`, `date_of_first_ovulation`, `menstruation_dates`, `climacterium_state`, and `climacterium_date`), simulates ovarian/menstrual cycles (menstrual, follicular, ovulation, luteal phases) modulated by the mother's `fertility_score` (`0` prior to first ovulation and `0` upon climacterium), reproduction attributes (`FER`, `HOR`, `REC`), health & body indicators (`metabolic_health`, `stress_level`, `sleep_recovery_quality`, `heart_health`, `BMI`, `body_fat_percentage`, and extreme `muscle_condition` / energy balance affecting cycle regularity and anovulatory risk), subtle ABO blood-type hemostatic variance (Type `O` vs. non-`O` bleeding-duration variance), and active medical drugs (e.g., **Contraception Pill**, which influences the menstruation period cadence, duration, and hormonal withdrawal-bleed timing while suppressing natural ovulation—also factoring non-`O` vascular risk modifiers into `sim-health`). Evaluates perimenopause and **climacterium** transition (emitting `sim.climacterium.reached` and zeroing female `fertility_score`), computes cycle-phase `lubrication_quality` and `libido_score` modifiers, handles stage-proportional post-loss cycle resumption upon `sim.prenatal_loss.occurred`, and coordinates with `sim-egg-selection` each cycle to retrieve the selected ovulated **egg cell (oocyte)**, its **haploid DNA**, and its **surface receptor profile**. | Local SQLite (cycle state, climacterium & hormone lookup tables) + consumes `sim-egg-selection` |
| `sim-ejaculation` | Models male spermatogenesis, **`erection_quality` (`0–100`)**, **`ejaculation_quality` (`0–100`)**, **`refractory_period_minutes`**, and ejaculation events modulated by age (strictly `0` fertility pre-puberty, teenage onset at `date_of_first_fertility`, rising to peak around age 21, and slowly declining thereafter), `fertility_score`, `libido_score`, `intercourse_stamina`, the father's reproduction attributes (`FER`, `CON`, `VIT`, `HOR`), cardiovascular, body-composition & general health indicators (`heart_health` and `blood_pressure` directly affecting vascular `erection_quality` and safe **Viagra** response bounds, `waking_heart_rate_bpm`, `respiratory_health`, `muscle_condition`, `BMI`, `visceral_fat_rating`, `metabolic_health`, `sleep_recovery_quality`, and `stress_level` influencing sperm output and short-interval recovery), and active medical drugs (e.g., **Viagra**, which increases `erection_quality`, modestly shortens functional `refractory_period_minutes`, and raises the probability of **one or more ejaculations within a single day**). Evaluates intercourse completion readiness (factoring `erection_quality`, `intercourse_stamina`, and partner `vaginismus` impediment) and tracks recent ejaculation timestamps so that **with each ejaculation within a short period of time, the quality of the ejaculation decreases** (`quality_factor` lowering `ejaculation_quality` and reducing sperm count, motility, morphology, and viability). For each completed ejaculation, reads the male character's diploid DNA, performs meiosis for the simulated sperm cohort, and **builds a dedicated per-ejaculation SQLite database** containing all simulated **sperm cells** (each with its unique haploid DNA, sex chromosome `X`/`Y`, **surface ligand profile**, motility, morphology, and viability). | Local SQLite (reference distributions, fertility/erection curves & ejaculation-interval decay curves) + **Per-Ejaculation SQLite DB artifact** |
| `sim-sperm-race` | Opens/reads the per-ejaculation SQLite database of sperm cells, simulates sperm transport ("race to the egg"): semen deposition efficiency (`erection_quality`, `ejaculation_quality`, and partner `vaginismus` impediment), vaginal/cervical mucosal friendliness (`lubrication_quality` and cervical mucus permeability coupled to cycle phase, active **Contraception Pill** effects, health-modulated `metabolic_health`/`immune_health`/`stress_level`, and parental `HOR`/`REC`/`VIT` modifiers), capacitation, attrition curves, and chemotaxis, and produces an **arrival-ordered shortlist of viable candidate sperm cells** reaching the egg (since the fastest cell does not automatically win if its surface does not fit). | Local SQLite (reference physics/biology curves) + reads Ejaculation SQLite DB |
| `sim-gamete-surface` | Evaluates molecular **surface compatibility between each arriving sperm cell and the viable egg cell** (modeling zona pellucida glycoprotein and oolemma receptor–ligand binding, modulated by parental `COM` and `REC` attributes). Iterates through arriving candidates from `sim-sperm-race`: if the fastest sperm cell's surface does not fit the egg cell, it is rejected and subsequent arriving candidates are tested until a surface-compatible sperm cell binds—or no candidate fits, resulting in non-fertilization. | Local SQLite (receptor–ligand compatibility matrices) + reads Ejaculation SQLite DB & selected Egg surface profile |
| `sim-conception` | Pairs the surface-compatible winning sperm cell (confirmed by `sim-gamete-surface`) with the viable egg cell (selected by `sim-egg-selection` / tracked by `sim-menstruation`), evaluates oocyte availability window, maternal & paternal `fertility_score` (requiring both `> 0`; zeroing conception if female is pre-ovulatory or climacteric, or male is pre-pubertal), `vaginismus` penetrative-impediment gating, membrane fusion, polyspermy block, active **Contraception Pill** efficacy/implantation modifiers (strongly reducing the chance of conceiving a baby), and parental `CON`/`REC` plus health-indicator implantation modifiers (`heart_health`, `metabolic_health`, `immune_health`, `stress_level`). Allocates a new **Character UUID** upon successful fertilization and emits `sim.conception.occurred` with mother UUID, father UUID, egg-cell DNA, and winning sperm-cell DNA. | Local SQLite / Event-driven |
| `sim-dna` | Provides meiosis/gamete-DNA synthesis utilities (for egg cells and sperm cells) and performs fertilization DNA combination: merges the **egg cell's haploid DNA** (mother) and the **winning sperm cell's haploid DNA** (father) into the new character's immutable 23-pair diploid **DNA**, determines biological `gender` (`XX` → `FEMALE`, `XY` → `MALE`), derives the character's immutable **`blood_type`** (`A+`, `A-`, `B+`, `B-`, `AB+`, `AB-`, `O+`, `O-`) from the Mendelian ABO (chromosome 9) and RhD (chromosome 1) loci, and computes structured embryonic genetic-viability markers (chromosomal aneuploidy & lethal recessive homozygosity load) consumed by `sim-prenatal-loss`. | Local SQLite (gene loci, ABO/RhD allele frequency & reference DB) + immutable genome store |
| `sim-prenatal-loss` | Independently versioned service evaluating **prenatal pregnancy loss** as a natural biological outcome across implantation (`PRE_IMPLANTATION_LOSS`, `CONCEIVED` → `DECEASED`) and gestation (`EARLY_MISCARRIAGE`, `LATE_MISCARRIAGE`, `STILLBIRTH`, `GESTATING` → `DECEASED`), governed by `GROUP.simulation_config` (**enabled by default**, with GM-configurable `prenatal_loss.enabled`, `prenatal_care_tier` [`HISTORICAL` \| `STANDARD` \| `ADVANCED`], bounded `risk_multiplier`, and `track_pre_implantation_loss`). Synthesizes all available PrincessPink domain signals using explicit seeded PRNGs (`group_id + sim_tick + event_id`): diploid genetic/chromosomal viability (`GENOME`, `EGG_CELL.quality_score`, `SPERM_CELL.morphology`/`viability`, `EJACULATION_DB.ejaculation_quality` & short-interval decay `quality_factor`, pedigree relatedness), maternal & paternal age and `climacterium_state` / ovarian reserve (`remaining_egg_count`, `fertility_score`), maternal-fetal blood-type compatibility (`rh_sensitized` + `Rh+` fetus and modest non-`O` vascular predisposition), maternal `CHARACTER_HEALTH_PROFILE` indicators (`heart_health`, `waking_heart_rate_bpm`, `blood_pressure`, `metabolic_health`, `immune_health`, `respiratory_health`, `sleep_recovery_quality`, `stress_level`, `muscle_condition`), maternal anthropometrics & body composition (`BMI`, `body_fat_percentage`, `visceral_fat_rating`, `WEIGHT_ADJUSTMENT`), 6 AD&D reproduction attributes (`CON`, `HOR`, `REC`, `VIT`, `FER`), maternal obstetric history (prior consecutive `PRENATAL_LOSS` records & short inter-pregnancy intervals), active breakthrough `CONTRACEPTION_PILL` exposure, and post-term gestational timing from `sim-birth-date`. Exposes synchronous gRPC evaluation (`EvaluateImplantationViability`, `EvaluateGestationRisk`), updates abstract clinical `risk_band` (`sim.prenatal_loss.evaluated`), and emits `sim.prenatal_loss.occurred` with stage, gestational age, `primary_cause_category`, structured `contributing_factors`, and `service_version` upon loss. | Local SQLite (read-only gestational baseline hazard curves, age/aneuploidy tables, health/BMI/Rh/attribute odds ratios & prenatal-care modifiers) |
| `sim-birth-date` | Calculates a character's **date of birth (`date_of_birth`)** from **either the mother's last menstruation date (LMP — Naegele's rule / gestational age model) or the exact date of conception** (gestation duration modulated by maternal `CON`, `heart_health`, `blood_pressure`, `metabolic_health`, `stress_level`, maternal-fetal Rh incompatibility in sensitized `Rh-` mothers carrying an `Rh+` fetus, non-`O` gestational hemodynamic predisposition, and biological variance). Exposes synchronous gRPC calculation and emits `sim.birthdate.calculated` for `sim-gestation`, `sim-prenatal-loss` (post-term timing evaluation), and `character-registry`. | Local SQLite (gestational duration & LMP-to-delivery reference curves) |
| `sim-gestation` | Tracks prenatal milestones from implantation through trimesters to birth, queries `sim-birth-date` to determine the scheduled `date_of_birth`, coordinates with **`sim-prenatal-loss`** at gestational milestones and upon mid-pregnancy maternal health/weight/medication updates (`sim.health.updated`, `character.weight.updated`, `character.medication.updated`), models maternal physiological pregnancy shifts (elevated `waking_heart_rate_bpm` and hemodynamic load coordinated with `sim-health`, including modest non-`O` gestational hypertension predisposition), evaluates **maternal-fetal blood-type compatibility**—specifically **Rh incompatibility** (`Rh-` mother carrying an `Rh+` fetus: models RhD sensitization probability at delivery **or after a post-implantation prenatal loss** configurable via `GROUP.simulation_config` `prenatal_care_tier` / RhIg prophylaxis settings, updating `CHARACTER.rh_sensitized`, and feeding elevated risk into `sim-prenatal-loss` for subsequent `Rh+` pregnancies) and **ABO incompatibility** (Type `O` mother carrying an `A` or `B` fetus: mild neonatal bilirubin/recovery adjustment)—alongside maternal `heart_health`, `blood_pressure`, `muscle_condition`, `respiratory_health`, `metabolic_health`, `immune_health`, and `sleep_recovery_quality`. If `sim-prenatal-loss` emits `sim.prenatal_loss.occurred`, `sim-gestation` terminates gestation tracking, cancels the scheduled `date_of_birth`, evaluates maternal RhD sensitization, and triggers maternal recovery in `sim-health` and `sim-menstruation`; otherwise upon reaching delivery it emits `sim.character.born` (triggering `sim-egg-reserve`, `sim-menarche` for newborn girls, `sim-health`, and `sim-mortality` for all live-born characters). | Local SQLite (prenatal & Rh/ABO incompatibility risk tables) / Event-driven |
| `sim-health` | Continuously simulates each living character's **Health & Fitness Indicators** across their entire lifecycle—including `heart_health` (`ILL`, `HEALTHY_NOT_SPORTY`, `HEALTHY_NORMAL`, `HEALTHY_SPORTY`), **waking heart rate (`waking_heart_rate_bpm`)** (pediatric-to-geriatric resting morning HR curves, pregnancy elevation, and dynamic adaptation to role-play training, rest, stress, weight, and medications), `muscle_condition` (`WEAK`, `NORMAL`, `SPORTY`, `BODY_BUILDER`), `blood_pressure`, `respiratory_health` (`VO2 max`), `metabolic_health`, `immune_health`, `sleep_recovery_quality`, and `stress_level`. Incorporates subtle `blood_type`-linked biological baselines (modest non-`O` [`A`, `B`, `AB`] cardiovascular/vascular and contraceptive-interaction predisposition vs. Type `O` lower thrombotic risk, ABO-linked `immune_health` baseline diversity, and transient newborn recovery adjustments following maternal-fetal Rh or ABO incompatibility). Consumes `sim.tick.advanced`, `sim.character.born`, `sim.prenatal_loss.occurred` (reverting gestational maternal hemodynamic shifts and applying a bounded stage-proportional physiological recovery interval for maternal `waking_heart_rate_bpm`, `stress_level`, and `sleep_recovery_quality`), `character.weight.updated`, `character.medication.updated`, `character.health.updated` (Player role-play lifestyle/training & bounded GM adjustments), and pregnancy state events, persisting snapshots and publishing `sim.health.updated` to `character-registry`, `sim-prenatal-loss`, `sim-mortality`, and downstream services. | Local SQLite (lifecycle waking HR, cardiovascular/muscular adaptation, ABO/Rh clinical baseline & hemodynamic reference curves) |
| `sim-mortality` | Calculates and dynamically reassesses the natural **date of death (`date_of_death`)** for each live-born Character based on `date_of_birth`, gender, genetic predispositions, `blood_type` (modest actuarial cardiovascular/thrombotic hazard modifiers distinguishing Type `O` vs. non-`O` groups), actuarial life tables, biological health/vitality modifiers (`CON`, `VIT`), and longitudinal health indicators (`heart_health`, `waking_heart_rate_bpm` trajectory, `muscle_condition` frailty protection, `blood_pressure`, `respiratory_health` / `VO2 max`, `metabolic_health`, `immune_health`, `sleep_recovery_quality`, and chronic `stress_level`)—strictly natural mortality in compliance with the zero-violence policy. Emits `sim.deathdate.calculated` for `sim-lifecycle`. *(Prenatal losses before birth are evaluated separately by `sim-prenatal-loss` and never invoke `sim-mortality`.)* | Local SQLite (actuarial & biological mortality life tables) |
| `sim-lifecycle` | Advances character age (from `date_of_birth`), updates natural developmental `height_cm` and baseline `weight_kg` trajectories (while respecting bounded GM role-play weight adjustments and `muscle_condition` lean-mass coupling from `sim-health`), coordinates developmental milestones (female menarche from `sim-menarche`, first ovulation, female climacterium transition, and male teenage fertility onset `date_of_first_fertility`), continuously updates lifecycle-driven `CHARACTER_INTERCOURSE_PROFILE` baselines (`fertility_score` `0–100`, `libido_score`, `intercourse_stamina`, `erection_quality`, `ejaculation_quality`, `refractory_period_minutes`, `lubrication_quality`, publishing `sim.fertility.updated`, including restoring non-pregnant maternal baselines after post-loss recovery following `sim.prenatal_loss.occurred`), tracks health trajectories with `sim-health`, and transitions live-born characters to `DECEASED` upon reaching the `date_of_death` calculated by `sim-mortality`, emitting `sim.character.deceased`. | Local SQLite (developmental, growth, fertility-age & aging reference tables) |

#### Per-Group Simulation Tick Configuration & Clock Controls
Simulation time in PrincessPink is governed by `sim-clock` on a strictly **per-group** basis:
- **Default Sim Tick Rate:** By default, **1 year within the simulation takes 24 hours in real time** (`1 simulated year = 24 hours real time`).
- **Group-Specific Configuration:** Every Group owns its own independent sim tick configuration stored in PostgreSQL (`GROUP.simulation_config` / `sim-clock` state); changing one Group's clock settings never affects any other Group.
- **Game Master Adjustments:** The Group's Game Master can adjust the Group's sim tick rate at any time (emitting `sim.clock.config.updated`) to accelerate or slow down simulated time for their campaign.
- **Role-Play Stop & Resume:** The Game Master may **stop** (`sim.clock.stopped`) and **resume** (`sim.clock.resumed`) the Group's sim tick whenever role-play needs it. While stopped, no `sim.tick.advanced` events are emitted for that Group and biological/aging progression freezes cleanly; upon resuming, the clock continues from the exact stopped simulation timestamp.
- **Mandatory Start Date & Fixed `0:00 h` Start Time:** At the start of a Group's simulation, the Game Master **must enter a start date in `dd/MM/YYYY` format**. The simulation start time is **always `0:00 h`** (`00:00`) on that date, from which the sim tick begins to run (`sim.clock.started`).

#### End-to-End Reproduction, Birth & Lifecycle Initialization Flow

```mermaid
sequenceDiagram
    participant Clock as sim-clock
    participant EggSel as sim-egg-selection
    participant EggDB as Egg-Reserve SQLite DB
    participant Mens as sim-menstruation
    participant Ejac as sim-ejaculation
    participant EjacDB as Ejaculation SQLite DB
    participant Race as sim-sperm-race
    participant Surf as sim-gamete-surface
    participant Conc as sim-conception
    participant DNA as sim-dna
    participant PLoss as sim-prenatal-loss
    participant BDate as sim-birth-date
    participant Reg as character-registry
    participant Gest as sim-gestation
    participant Health as sim-health
    participant EggRes as sim-egg-reserve
    participant Menar as sim-menarche
    participant Mort as sim-mortality

    Clock->>Mens: sim.tick.advanced (calendar date - applies active Contraception Pill cycle modulation)
    Mens->>EggSel: Select egg cell for mother's next cycle (mother_uuid - suppressed if Contraception Pill blocks ovulation)
    EggSel->>EggDB: Query UUID-linked Egg-Reserve SQLite DB & mark selected egg cell
    EggSel-->>Mens: Selected egg cell (cell_id, haploid DNA, surface profile) or suppressed ovulation
    Mens-->>Race: Fertile window, lubrication_quality, mucus state & maternal fertility / vaginismus / medication modifiers
    Note over Ejac,Surf: Reproductive try initiated (modulated by intercourse & fertility values, 6 AD&D stats, health & active drugs)
    Ejac->>Reg: Fetch father diploid DNA, intercourse profile (fertility_score, erection/ejaculation quality, refractory period), health, active Viagra & mother vaginismus state
    Ejac->>EjacDB: Build per-ejaculation SQLite DB of sperm cells (if penetrative attempt completes - haploid DNA + surface profile + quality-decayed motility/viability)
    Ejac->>Race: Ejaculation event + SQLite DB reference
    Race->>EjacDB: Query & simulate sperm cell cohort race
    Race->>Surf: Arrival-ordered candidate sperm cells (fastest first)
    Surf->>Mens: Fetch selected viable egg cell surface profile
    Surf->>EjacDB: Read candidate sperm surface profiles
    Surf-->>Surf: Check surface fit in arrival order (fastest may fail fit then next fitting candidate wins)
    Surf->>Conc: Surface-compatible winning sperm cell (cell_id + haploid DNA) or no-fit outcome
    Conc->>Mens: Verify viable egg cell & retrieve egg haploid DNA
    alt Fertilization Succeeds
        Conc->>DNA: Combine egg haploid DNA (mother) + sperm haploid DNA (father)
        DNA-->>DNA: Compute diploid 23-pair DNA, gender (XX/XY), blood_type (ABO + RhD) & genetic-viability markers
        Conc->>Reg: Allocate Character UUID (state = CONCEIVED, gender, blood_type, mother_uuid, father_uuid, owner = NULL [NPC], origin_group_id)
        DNA->>PLoss: Evaluate implantation & early embryonic viability (if prenatal_loss.enabled & track_pre_implantation_loss)
        alt Pre-Implantation Loss Occurs
            PLoss->>Reg: sim.prenatal_loss.occurred (state = DECEASED, date_of_death = loss_date, date_of_birth = NULL, PREGNANCY = PRENATAL_LOSS, close pending OWNERSHIP_AGREEMENT)
            PLoss->>Mens: Resume normal post-loss menstrual cycle tracking
        else Implantation Succeeds
            DNA-->>Reg: Persist immutable diploid DNA, PREGNANCY (ONGOING) & update state = GESTATING
            DNA->>Gest: sim.dna.calculated (start gestation tracking & evaluate maternal-fetal Rh/ABO compatibility)
            Gest->>BDate: Calculate date_of_birth (from mother's last menstruation OR conception date, factoring Rh compatibility)
            BDate-->>Gest: Scheduled date_of_birth (sim.birthdate.calculated)
            Gest->>Health: Apply maternal pregnancy hemodynamic shifts (elevated waking heart rate)
            Gest->>PLoss: Evaluate gestational prenatal-loss risk across trimesters & maternal health/weight/medication updates
            alt Prenatal Loss Occurs Before Birth
                PLoss->>Reg: sim.prenatal_loss.occurred (state = DECEASED, date_of_death = loss_date, date_of_birth = NULL, loss_stage, cause category, close pending OWNERSHIP_AGREEMENT)
                PLoss->>Gest: Terminate gestation tracking, cancel scheduled date_of_birth & evaluate maternal RhD sensitization (rh_sensitized)
                Gest->>Health: Revert pregnancy hemodynamic shifts & apply stage-proportional maternal recovery
                Gest->>Mens: Exit pregnant state & schedule post-loss cycle resumption
            else Live Birth Reached
                Gest->>Reg: sim.character.born (state = ALIVE, set date_of_birth, PREGNANCY = LIVE_BIRTH - update mother rh_sensitized if Rh- / Rh+ sensitized)
                Gest->>Health: Initialize newborn health profile, blood-type baselines & lifecycle waking HR (character_uuid)
                Health-->>Reg: Persist initial CHARACTER_HEALTH_PROFILE (sim.health.updated)
                Gest->>Mort: Calculate natural date_of_death for newborn Character
                Mort-->>Reg: Record scheduled natural mortality (sim.deathdate.calculated)
                opt Newborn is FEMALE (Girl)
                    Gest->>EggRes: Generate all birth egg cells for girl (character_uuid, diploid DNA)
                    EggRes->>EggDB: Create & link Egg-Reserve SQLite DB to girl's character_uuid
                    EggRes-->>Reg: Persist Egg-Reserve DB link for character_uuid
                    Gest->>Menar: Calculate date_of_first_menstruation for young girl
                    Menar-->>Reg: Persist date_of_first_menstruation (sim.menarche.calculated)
                end
            end
        end
    else Fertilization Does Not Occur
        Conc-->>Clock: Log non-conception outcome
    end
```

#### Scientific Modeling Standards
- **Reproducible Stochasticity:** All probabilistic biological processes use seeded pseudorandom number generators (`math/rand/v2` with explicit seeds derived from `group_id + sim_tick + event_id`) so simulation runs are auditable and reproducible in tests.
- **Versioned Scientific Parameters & Service Versions:** Biological constants (e.g., mean luteal phase length, mutation rates, crossover probabilities, ABO/RhD allele frequencies, maternal-fetal Rh sensitization and prophylaxis probabilities, ABO cardiovascular/hemostatic modifiers, receptor-binding thresholds, lifecycle waking heart rate curves, cardiovascular and muscular training/detraining adaptation rates, pregnancy hemodynamic shifts, gestational-week prenatal-loss baseline hazard curves, chromosomal/age/gamete/health/BMI/Rh/attribute prenatal-loss odds ratios, `prenatal_care_tier` modifiers, health-adjusted mortality hazard ratios, gender- and age-specific `fertility_score` (`0–100`) curves including female pre-ovulation/climacterium zeroing and male teenage onset to age-21 peak and slow decline, health and body-composition fertility modifiers, `erection_quality` and `ejaculation_quality` age/vascular curves, `refractory_period_minutes` curves, `vaginismus` penetrative-impediment probabilities, `lubrication_quality` and `intercourse_stamina` models, Viagra erection/frequency modifiers, short-interval ejaculation quality decay curves, and contraception pill cycle/efficacy curves) are versioned configuration data rather than hardcoded magic numbers, and every simulation event records the emitting microservice's own version number.

---

### 4.5 Real-Time Chat & Communication Microservices
PrincessPink provides an integrated, real-time **Chat** system (`frontend-chat` + `chat-service` + `chat-world-registry`) designed for tabletop RPG coordination and community interaction across the simulation.

#### Supported Chat Channels
1. **Global / World Chat (World of Warcraft-Style with Player-Selectable Servers):**
   - Realized through **logical World Chat Servers** managed by `chat-world-registry` (see [ADR-0002](architecture/ADR-0002-world-chat-microservices-and-server-selection.md)), modeled on the classic World of Warcraft realm/world chat experience (familiar channel tabs, slash-command routing such as `/world`, `/global`, `/1`, `/servers`, `/world join <slug>`, timestamps, and user display names).
   - Players and Game Masters browse available World Chat Servers filtered by **language**, **region**, **category** (`GENERAL`, `ROLEPLAY`, `SCIENCE`, `NEWCOMER`), **status**, and live **population band** (`LOW`, `MEDIUM`, `HIGH`, `FULL`), and select or switch their preferred World Chat Server at any time without disconnecting their WebSocket session or interrupting Group Chat and Direct Messages.
   - Enables players across different groups to discuss simulation mechanics, genetics, lineage milestones, and community topics without turning global chat into an unpartitioned firehose.
2. **Group Chat (Game Master & Group Members):**
   - A private channel scoped strictly to a single **Group**, connecting the **Game Master** and all **Players** belonging to his/her Group (e.g., `/group` or `/g`).
   - Supports in-campaign coordination, GM announcements, simulation-clock notifications, and collaborative tabletop storytelling. Membership is enforced on every connection and message via `user-admin`.
3. **Direct Message Chat (1-to-1 Player Messaging):**
   - Private **1-to-1 messaging** between any two Players (e.g., `/whisper <player>` or `/w <player>`), allowing bilateral negotiation (such as agreeing on ownership of a conceived or born child), lineage planning, or private conversation without exposing messages to Global / World or Group channels.
   - Strict participant-only read/write authorization ensures only the sender and recipient can view direct message threads.

#### Chat Architecture, Delivery & Safety
- **Transport, Server Discovery & Fan-Out:** `frontend-chat` terminates a single authenticated WebSocket (`wss://`) connection per client (validated via `frontend-gateway` / `user-admin`), queries `chat-world-registry` for live World Chat Server discovery/occupancy, and streams messages and `SwitchWorldServer` requests to `chat-service` over gRPC. `chat-service` publishes incoming messages to partitioned NATS JetStream subjects (`chat.world.<world_server_id>`, `chat.group.<group_id>`, `chat.dm.<pair_id>`) so horizontally scaled pods deliver messages in real time and live World Chat Server switches occur atomically without dropping the WebSocket or disrupting Group/DM streams.
- **Persistence:** World Chat Server definitions (`chat.world_servers`), per-user selected server preferences (`chat.user_world_preferences`), channel definitions, `uuidv7()`-keyed message history, read markers, and user mute/block lists are stored in central PostgreSQL 18+ under the `chat.*` schema with cursor-based pagination.
- **Content Policy & Moderation:** In strict alignment with PrincessPink's **zero-violence, zero-nudity** policy, `chat-service` enforces automated content filtering, per-user message and server-switch rate limiting (anti-spam / anti-hopping), globally enforced player mute/block/report actions across all World Chat Servers, and Game Master moderation capabilities within their own Group Chat.

---

## 5. Data Architecture & Persistence Strategy

PrincessPink uses a **polyglot persistence strategy** aligned with service ownership:

### 5.1 Central PostgreSQL (Authoritative Transactional Data)
Hosted on **Azure Database for PostgreSQL (Flexible Server)** running **PostgreSQL 18+** (minimum supported version; see [ADR-0001](architecture/ADR-0001-minimum-postgresql-version.md)) with automated backups, point-in-time recovery (PITR), and high availability.
- **Minimum Version Rationale (`PostgreSQL 18+`):** Generally Available across all Azure public regions with upstream security support through November 2030, providing native `uuidv7()` for PrincessPink's UUID-everywhere primary keys and cursor-paginated chat/audit/outbox tables, `RETURNING OLD/NEW` for atomic audit trails, SQL/JSON functions for `jsonb` (`simulation_config`), B-tree skip scans, Asynchronous I/O (`worker` mode on Azure), and hardened security (`SCRAM-SHA-256`, TLS 1.3, OAuth 2.0 / Microsoft Entra ID).
- **Owned Domains:**
  - `user-admin`: Users, credentials (Argon2id hashes), MFA secrets, sessions/refresh tokens, groups, memberships (including each Player's single `selected_character_id` chosen at Group start), RBAC policies, and audit logs (see [ADR-0010](architecture/ADR-0010-user-admin-auth-rbac-and-group-management.md)).
  - `character-registry`: Character UUIDs, nullable player ownership (`owner_user_id`), `origin_group_id`, pregnancy & prenatal-loss outcome records (`PREGNANCY`), parental child-ownership agreements (`OWNERSHIP_AGREEMENT`, including `CLOSED_PRENATAL_LOSS` resolution), player-given names, `gender`, immutable `blood_type` (`A+`..`O-`), female `rh_sensitized` status, `date_of_birth`, `date_of_death`, `height_cm`, `weight_kg`, GM role-play weight adjustment history (`WEIGHT_ADJUSTMENT`), current health & fitness profiles (`CHARACTER_HEALTH_PROFILE`), current intercourse & fertility profiles (`CHARACTER_INTERCOURSE_PROFILE`), role-play lifestyle and GM health/intercourse adjustment history (`HEALTH_ADJUSTMENT`), active and historical role-play medical drug selections (`CHARACTER_MEDICAL_DRUG`), `lifecycle_state`, gender-specific milestone history (such as `date_of_first_menstruation`, `date_of_first_ovulation`, `climacterium_date`, `date_of_first_fertility`, and `menstruation_dates`), ovarian Egg-Reserve SQLite DB links (mapped to female `character_uuid`), mother/father lineage links, and immutable diploid genome records (or references).
  - `chat-service` & `chat-world-registry`: World Chat Server catalog, per-user server preferences, chat channels (`GLOBAL`, `GROUP`, `DIRECT`), message history, participant metadata, mute/block lists, and moderation audit logs (see [ADR-0002](architecture/ADR-0002-world-chat-microservices-and-server-selection.md)).
  - `sim-clock`: Per-group simulation clock state (`STOPPED` / `RUNNING`), mandatory simulation start date (`dd/MM/YYYY`, starting at `0:00 h`), current simulation timestamp/tick, and per-group sim tick rate configuration (defaulting to `1 simulated year = 24 hours real time`, GM-adjustable).
- **Schema Isolation:** Logical separation via dedicated PostgreSQL schemas (e.g., `user_admin.*`, `character_registry.*`, `chat.*`, `sim_clock.*`) with per-service database credentials and least-privilege grants.

### 5.2 Local SQLite in Simulation Microservices
Selected simulation microservices use embedded **SQLite** databases for low-latency, zero-network-hop data access. Because SQLite is file-based and single-writer, PrincessPink distinguishes four explicit deployment patterns on Kubernetes:

1. **Read-Only Reference SQLite Databases (Preferred for Stateless Scaling):**
   - Used for scientific lookup tables (e.g., human gene loci, ABO/RhD allele frequencies, trait dominance maps, Rh/ABO maternal-fetal incompatibility risk tables, gestational prenatal-loss hazard and risk-factor odds-ratio tables, hormone reference curves, gender/age fertility and climacterium curves, erection/ejaculation/refractory reference curves, lifecycle waking heart rate and cardiovascular/muscular adaptation curves, gestational duration curves, menarche distributions, actuarial mortality tables).
   - Built as immutable `.sqlite` artifacts baked into the container image or mounted as read-only volumes (`mode=ro&immutable=1`).
   - Allows unlimited horizontal pod autoscaling (`Deployment` + HPA) with zero lock contention.

2. **Writable Local SQLite Databases (Stateful Services):**
   - Used only where a simulation service maintains local ephemeral state, intermediate cycle tracking, or local calculation caches.
   - Deployed as a Kubernetes **`StatefulSet`** backed by an **Azure Managed Disk PVC** (one writer pod per shard/partition, WAL mode enabled: `PRAGMA journal_mode=WAL; PRAGMA busy_timeout=5000;`).
   - Canonical outcomes (new Character UUIDs, finalized DNA, `date_of_birth`, `date_of_death`, `date_of_first_menstruation`, `menstruation_dates`) are always published as events and durably persisted to PostgreSQL/Event Store so local SQLite state can be rebuilt or backed up cleanly.

3. **Per-Female-Character Egg-Reserve SQLite Databases (Lifetime Gamete Store Linked to `character_uuid`):**
   - When a female character (**Girl**) is born (`sim.character.born` with `gender == FEMALE`), `sim-egg-reserve` generates all egg cells she carries with her at birth and persists them in a **dedicated SQLite database explicitly linked to her `character_uuid`** (e.g., `egg_reserve_<character_uuid>.sqlite`), registering the `character_uuid` → SQLite DB link in `character-registry`.
   - **Logical Schema:**
     - `egg_reserve_meta` (`character_uuid` PK, `group_id`, `born_at_sim`, `prng_seed`, `initial_egg_count`, `remaining_egg_count`, `service_version`, `created_at`)
     - `egg_cells` (`cell_id` PK, `haploid_dna` [compact binary 22 autosomes + `X`], `surface_profile` [compact binary zona pellucida & oolemma receptor signature], `quality_score`, `atresia_risk`, `status` [`DORMANT` | `SELECTED` | `VIABLE` | `FERTILIZED` | `EXPIRED` | `ATRESIA`], `selected_cycle_id`, `ovulated_at_sim`)
   - **Lifecycle & Access in Kubernetes:** Built in a single batched transaction at birth and stored on durable shared/partitioned storage (e.g., **Azure Managed Disk PVC** per shard or **Azure Blob Storage** with per-`character_uuid` lease locking). On every menstrual cycle after menarche, `sim-egg-selection` opens the girl's UUID-linked SQLite database to determine which egg cell drops during her next cycle and updates its `status` (`DORMANT` → `SELECTED` → `VIABLE` → `FERTILIZED`/`EXPIRED`). The database is retained across the character's reproductive lifespan and archived or garbage-collected after menopause or death according to the group's retention policy.

4. **Per-Ejaculation SQLite Databases (Event-Scoped Gamete Artifacts):**
   - Each ejaculation event triggers `sim-ejaculation` to construct a self-contained SQLite database file (e.g., `ejaculation_<event_uuid>.sqlite`) populated with the individual simulated **sperm cells** calculated via meiosis from the male character's diploid DNA.
   - **Logical Schema:**
     - `ejaculation_meta` (`ejaculation_id`, `father_uuid`, `group_id`, `sim_tick`, `prng_seed`, `cell_count`, `erection_quality`, `ejaculation_quality`, `quality_factor`, `recent_ejaculation_count`, `created_at`)
     - `sperm_cells` (`cell_id`, `sex_chromosome` [`X` | `Y`], `haploid_dna` [compact binary chromosome encoding], `surface_profile` [compact binary receptor/ligand signature], `motility_score`, `morphology_score`, `viability_score`, `status`)
   - **Build & Lifecycle in Kubernetes:** Written in a single batched transaction on local ephemeral NVMe/tmpfs storage (with `PRAGMA journal_mode=OFF; PRAGMA synchronous=OFF;` during creation), then sealed read-only and published to shared artifact storage (e.g., **Azure Blob Storage** or a shared ReadWriteMany volume) for consumption by `sim-sperm-race`, `sim-gamete-surface`, and `sim-conception`. Once the race, surface-compatibility check, and conception evaluation complete, the winning sperm cell's DNA is preserved in the child's conception record and the temporary SQLite artifact is garbage-collected or archived according to the group's retention policy.

### 5.3 Data Consistency
- **Transactional Outbox Pattern:** Services writing to PostgreSQL and publishing domain events use an outbox table to guarantee atomicity between database commits and event publication.
- **Eventual Consistency for Derived Views:** Character sheet attributes and lineage projections converge asynchronously on simulation events, tagged with `sim_tick` so clients always know the simulation timestamp of displayed values.

---

## 6. Cloud Infrastructure & Deployment (Microsoft Azure AKS)

### 6.1 Kubernetes Cluster Topology
PrincessPink runs on **Azure Kubernetes Service (AKS)** with workload isolation via Kubernetes Namespaces:
- `ingress` — Ingress controller (e.g., NGINX or Azure Application Gateway for Containers) and TLS termination (cert-manager / Azure Key Vault).
- `frontend` — Gin web microservices (`frontend-gateway`, `frontend-sheets`, `frontend-gm`, `frontend-chat`, `portrait-renderer`).
- `user-admin` — Authentication, user, and group administration services (see [ADR-0010](architecture/ADR-0010-user-admin-auth-rbac-and-group-management.md)).
- `chat` — Real-time messaging services (`chat-service` and `chat-world-registry`) handling player-selectable World Chat Servers, Group Chat, and 1-to-1 Direct Messages (see [ADR-0002](architecture/ADR-0002-world-chat-microservices-and-server-selection.md)).
- `character-sheet` — `character-registry`, `sheet-aggregator`, and all `attr-*` microservices.
- `simulation` — Biological simulation microservices (`sim-clock`, `sim-egg-reserve`, `sim-egg-selection`, `sim-menarche`, `sim-menstruation`, `sim-ejaculation`, `sim-sperm-race`, `sim-gamete-surface`, `sim-conception`, `sim-dna`, `sim-prenatal-loss`, `sim-birth-date`, `sim-gestation`, `sim-health`, `sim-mortality`, `sim-lifecycle`).
- `messaging` — Event broker (if running NATS JetStream in-cluster).
- `observability` — OpenTelemetry Collector, Prometheus, Grafana/Azure Monitor agents.

### 6.2 Azure Managed Services Integration
- **Azure Kubernetes Service (AKS):** Managed control plane, separate system and user node pools, cluster autoscaler.
- **Azure Container Registry (ACR):** Private registry for signed Go distroless/scratch container images.
- **Azure Database for PostgreSQL Flexible Server (PostgreSQL 18+):** Managed central relational database (minimum version PostgreSQL 18 per [ADR-0001](architecture/ADR-0001-minimum-postgresql-version.md)) with private VNet integration and Microsoft Entra ID authentication.
- **Azure Key Vault + Secrets Store CSI Driver:** Centralized storage and automatic rotation of database credentials, JWT signing keys, and TLS certificates.
- **Azure Monitor & Log Analytics:** Unified metrics, logs, and alerting.

### 6.3 Networking, Security & Resilience
- **Zero-Trust Pod Networking:** Default-deny Kubernetes `NetworkPolicy` per namespace, explicitly allowing only required service-to-service paths (e.g., `sheet-aggregator` → `attr-*`; `user-admin` → PostgreSQL).
- **Container Hardening:** Multi-stage Go builds producing minimal non-root images (`distroless/static`), read-only root filesystems (except mounted SQLite PVC paths where required), dropped Linux capabilities.
- **Resilience & Scaling:**
  - Horizontal Pod Autoscaler (HPA) on CPU/RPS for stateless frontend, attribute, and read-only simulation services.
  - `PodDisruptionBudgets` (PDB), readiness/liveness/startup probes (`/healthz`, `/readyz`), gRPC deadlines, circuit breakers, and bounded retries.

---

## 7. Observability, Testing & Operations

### 7.1 Observability (OpenTelemetry)
- **Distributed Tracing:** End-to-end OpenTelemetry traces (`libs/telemetry`, see [ADR-0004](architecture/ADR-0004-shared-opentelemetry-observability.md)) across Gin HTTP handlers, gRPC fan-out (`sheet-aggregator` → `attr-*`), and async simulation event chains.
- **Structured Logging:** Go standard `log/slog` (`libs/logging`, see [ADR-0003](architecture/ADR-0003-shared-logging-library.md)) outputting JSON logs enriched with `service_version`, `trace_id`, `user_uuid` (non-PII), `group_id`, and `character_uuid`.
- **Metrics:** Prometheus-compatible metrics ([ADR-0004](architecture/ADR-0004-shared-opentelemetry-observability.md)) tracking request latency (p50/p95/p99), attribute fan-out error rates, simulation tick duration, active characters, and conception/birth/prenatal-loss rates (strictly low-cardinality labels such as `loss_stage` and `primary_cause_category`—never `character_uuid`, `user_uuid`, or `group_id`).

### 7.2 Testing Strategy
- **Unit Tests:** Pure Go tests for biological formulas, genetic crossover/recombination math, prenatal-loss hazard aggregation, hormonal curves, and RBAC rules.
- **Deterministic Simulation Tests:** Fixed-seed end-to-end reproduction and lifecycle scenarios verifying statistical invariants (e.g., Mendelian ratios including ABO & RhD blood-type inheritance, expected sex-chromosome distribution ~50/50 over large cohorts, maternal-fetal Rh incompatibility and sensitization transitions across consecutive pregnancies including after post-implantation prenatal loss, prenatal-loss cohort invariants—0% loss when `prenatal_loss.enabled == false`, realistic gestational-stage concentration highest in pre-implantation/first trimester and lowest in late stillbirth, monotonic maternal-age & perimenopausal risk elevation, gamete-quality/short-interval-ejaculation and lethal-genetic-load risk effects, sensitized `Rh-`/`Rh+` elevation mitigated by `prenatal_care_tier`, maternal health/body-composition/reproduction-attribute/breakthrough-contraception/recurrent-loss hazard modulation, post-loss invariants confirming `date_of_birth == null`, `date_of_death` recorded, `PENDING` `OWNERSHIP_AGREEMENT` closed, zero newborn Egg-Reserve/menarche/mortality creation, and maternal cycle/health recovery—cycle duration bounds, female `fertility_score == 0` prior to first ovulation and upon climacterium with higher fertility in younger vs. older women, male `fertility_score == 0` pre-puberty followed by teenage onset, rise to peak around age 21, and gradual decline thereafter, health and body-composition modulation of `fertility_score`, `erection_quality`, `ejaculation_quality`, `lubrication_quality`, and `intercourse_stamina`, `vaginismus == true` impeding penetrative attempt completion while preserving ovarian cycles, pediatric-to-geriatric `waking_heart_rate_bpm` trajectories and pregnancy elevation, role-play cardiovascular/muscular adaptation effects on `heart_health`, `muscle_condition`, `erection_quality`, gestation stability, and natural mortality curves, Viagra erection-quality and multi-ejaculation daily frequency increases alongside short-interval ejaculation quality decay, and contraception pill menstruation-period modulation and conception-chance reduction).
- **Contract Tests:** Protobuf schema compatibility checks (`buf breaking`) and OpenAPI validation stored under `docs/api/`.
- **Integration Tests:** Containerized tests (e.g., Testcontainers with PostgreSQL 18+ and NATS) verifying authentication flows, authorization boundaries (Player vs. GM), and event pipelines.
- **Load & Resilience Tests:** Verifying `sheet-aggregator` fan-out latency and graceful degradation when individual `attr-*` services experience latency or failure.

### 7.3 CI/CD & Developer Experience
- **Local Development:** `Makefile` targets (see [ADR-0008](architecture/ADR-0008-multi-module-makefile-build-automation.md)), typed 12-Factor environment/file-secret configuration (`libs/config`, see [ADR-0006](architecture/ADR-0006-shared-configuration-library.md)), and local Kubernetes (`kind` / `k3d`) or Docker Compose stack for running core services locally without Azure dependencies.
- **CI/CD (`.github/workflows/`):** Automated `golangci-lint`, unit/integration tests, vulnerability scanning (`govulncheck`, Trivy), independent per-service versioned multi-arch container builds to ACR (tagged with each microservice's own semantic version), and GitOps/Helm deployments to AKS (dev → staging → prod) (see [ADR-0009](architecture/ADR-0009-github-actions-ci-cd.md)).
- **Operational Documentation:** API contracts in `docs/api/`, Architecture Decision Records (ADRs) in `docs/architecture/` ([ADR-0001](architecture/ADR-0001-minimum-postgresql-version.md)–[ADR-0011](architecture/ADR-0011-go-as-sole-programming-language.md)), and incident/backup runbooks in `docs/runbooks/`.

---

## 8. Key Architectural Risks & Mitigations

| Risk / Trade-off | Impact | Mitigation |
| :--- | :--- | :--- |
| **High service count (attribute-per-microservice)** | Network fan-out latency, boilerplate duplication, operational overhead. | Shared Go microservice scaffold in `libs/`, binary gRPC over HTTP/2, parallel fan-out with strict timeouts, tick-based caching, and graceful degradation. |
| **Local SQLite concurrency & scaling in Kubernetes** | Write-lock contention or data loss if deployed naively across multiple replicas. | Restrict horizontal `Deployment` scaling to immutable read-only SQLite reference DBs; use single-writer `StatefulSet` + PVC (or migrate mutable state to PostgreSQL) for writable stores. |
| **Per-female Egg-Reserve SQLite DB size & lifecycle management** | Generating and retaining a dedicated SQLite database of all birth egg cells linked to each female character's `UUID` can grow storage across large multi-generational populations. | Use compact binary chromosome encoding, configurable biological cohort scaling per group, indexed `status` queries for `sim-egg-selection`, per-`character_uuid` locking, and archival/TTL cleanup after menopause or `DECEASED`. |
| **Per-ejaculation SQLite DB size & storage growth** | Simulating millions of individual sperm cells with haploid DNA per ejaculation can create large files and high I/O. | Use compact binary chromosome encoding, configurable statistical cohort scaling per group, batched single-transaction writes on ephemeral storage, and automated TTL cleanup/archival to Azure Blob Storage once `sim-sperm-race` finishes. |
| **Chat moderation, cross-group leakage & world-server hot-spotting** | Real-time World, Group, and 1-to-1 Direct Message chat could expose inappropriate content, leak private group messages, or overload a single global channel. | Partition World Chat into player-selectable logical World Chat Servers (`chat-world-registry` + `chat.world.<world_server_id>` per [ADR-0002](architecture/ADR-0002-world-chat-microservices-and-server-selection.md)), enforce RBAC/group checks via `user-admin`, apply automated zero-violence/zero-nudity filters, message & server-switch rate limiting, globally scoped mute/block/report tools, and GM moderation controls in Group Chat. |
| **Authorization leaks between Players and Groups** | Unauthorized access to another player's character sheet. | Enforce UUID-based ownership and group checks in both `frontend-gateway` and backend services, backed by automated authorization integration tests. |
| **Content policy violations** | Accidental introduction of inappropriate visuals or descriptions. | Deterministic face-only comic portrait generator (no arbitrary image uploads) and strict schema-driven text/attribute rendering. |
| **Scientific complexity vs. playability** | Overly opaque simulation parameters reducing RPG enjoyment. | Decouple scientific simulation models (`sim-*`) from gamified presentation (`attr-*` and `frontend-*`), exposing clear RPG-style summaries with optional scientific drill-down. |

---

## 9. Phased Implementation Roadmap

1. **Phase 1 — Platform Foundation**
   - Establish shared `libs/` libraries (logging per [ADR-0003](architecture/ADR-0003-shared-logging-library.md), OpenTelemetry per [ADR-0004](architecture/ADR-0004-shared-opentelemetry-observability.md), gRPC contracts per [ADR-0005](architecture/ADR-0005-shared-grpc-protobuf-contracts.md), config per [ADR-0006](architecture/ADR-0006-shared-configuration-library.md), UUID utilities per [ADR-0007](architecture/ADR-0007-shared-uuid-utilities.md)), `Makefile` ([ADR-0008](architecture/ADR-0008-multi-module-makefile-build-automation.md)), and GitHub Actions CI ([ADR-0009](architecture/ADR-0009-github-actions-ci-cd.md)).
   - Implement `user-admin` with PostgreSQL, Argon2id auth, Player/GM roles, and Group management (see [ADR-0010](architecture/ADR-0010-user-admin-auth-rbac-and-group-management.md)).
2. **Phase 2 — Character Sheet, Chat & Frontend MVP**
   - Implement `frontend-gateway`, `frontend-sheets`, `frontend-gm`, `frontend-chat` (Go + Gin), `chat-service`, and `chat-world-registry` (World of Warcraft-style player-selectable World Chat Servers, GM/Group Chat, and 1-to-1 Player Direct Messages per [ADR-0002](architecture/ADR-0002-world-chat-microservices-and-server-selection.md)).
   - Implement `character-registry`, `sheet-aggregator`, initial set of `attr-*` microservices, and the deterministic `portrait-renderer`.
3. **Phase 3 — Core Reproduction Simulation Pipeline**
   - Implement `sim-clock`, `sim-egg-reserve` (UUID-linked birth Egg-Cell SQLite DB), `sim-egg-selection` (next-cycle egg selection), `sim-menarche` (first menstruation calculation), `sim-menstruation`, `sim-ejaculation`, `sim-sperm-race`, `sim-gamete-surface`, `sim-conception`, and `sim-dna` with local SQLite reference databases and event bus integration.
   - Validate biological and genetic invariants with seeded cohort tests (including reproduction attribute modifiers and surface-compatibility selection).
4. **Phase 4 — Full Lifecycle & Population Features**
   - Implement `sim-prenatal-loss` (prenatal pregnancy loss risk and outcome evaluation across implantation and gestation), `sim-birth-date` (from mother's last menstruation or conception date), `sim-gestation`, `sim-health` (lifecycle waking heart rate, heart health, muscular conditioning, and clinical health indicators influenced by role-play), `sim-mortality` (health-adjusted natural date of death calculation), `sim-lifecycle` (aging and lifecycle transitions), multi-generational family trees, and Game Master population analytics.
5. **Phase 5 — Production Hardening on Azure AKS**
   - Deploy full Helm/Kustomize manifests to AKS with Azure PostgreSQL, Key Vault, NetworkPolicies, HPA, observability dashboards, security audit, and operational runbooks.

---

## 10. Glossary

- **Agent / Character:** An individual simulated human within PrincessPink. Every agent in the simulation is a character, similar to a character in a pen-and-paper RPG. Each character has a globally unique, permanent **UUID** that identifies it before birth (from conception), during life, and after death, along with core attributes (`gender`, immutable `blood_type`, `date_of_birth`, `date_of_death`) and gender-specific biological attributes. Characters may be owned by a Player (who can own multiple characters) or exist as an unowned **NPC** (such as a child conceived or born during a simulation before parental ownership is agreed).
- **Blood Type (ABO & RhD):** An immutable genetic attribute (`A+`, `A-`, `B+`, `B-`, `AB+`, `AB-`, `O+`, `O-`) determined at conception by `sim-dna` via Mendelian inheritance of ABO (`I^A`, `I^B`, `i`) and RhD (`D`, `d`) alleles from maternal and paternal gametes. Displayed on every character sheet (`attr-blood-type`) and modeled across the simulation for maternal-fetal Rh alloimmunization (`rh_sensitized`, including after `Rh+` births or prenatal losses) and ABO incompatibility in `sim-prenatal-loss` / `sim-gestation` / `sim-birth-date`, cardiovascular and immune baselines in `sim-health`, hemostatic variance in `sim-menstruation`, and modest actuarial cardiovascular hazard modifiers in `sim-mortality`.
- **Body Composition & Medical Weight Metrics:** Clinical physical metrics calculated for every character from `height_cm`, `weight_kg`, `gender`, age, and lifecycle state—mirroring a medical body-composition scale—including **BMI (Body Mass Index)**, **Body Fat Index / Percentage**, **Lean Body Mass**, **Skeletal Muscle Mass**, **Total Body Water**, **Bone Mass**, **Visceral Fat Rating**, **Basal Metabolic Rate (BMR)**, **Body Surface Area (BSA)**, and **Ideal Weight Range**. Each metric is computed by a dedicated `attr-*` microservice and recalculates automatically whenever age, growth, gestation, or bounded Game Master role-play adjustments change `weight_kg`.
- **Character Sheet:** The gamified, tabletop-RPG-inspired view of a character's identity (name, UUID, gender, immutable `blood_type`, date of birth, date of death), comic face portrait, dynamic appearance traits (`eye_color`, `hair_color`, `skin_color`), physical measurements (`height_cm`, `weight_kg`) and derived medical body-composition metrics (`BMI`, Body Fat Index, Lean Body Mass, BMR, etc.), dynamic **Health & Fitness Indicators** (`heart_health`, lifecycle-simulated `waking_heart_rate_bpm`, `muscle_condition`, `blood_pressure`, `respiratory_health`, `metabolic_health`, `immune_health`, `sleep_recovery_quality`, `stress_level`), **Intercourse & Fertility Values** (`fertility_score` `0–100`, `erection_quality`, `ejaculation_quality`, `vaginismus`, `libido_score`, `lubrication_quality`, `refractory_period_minutes`, `intercourse_stamina`, `climacterium_state`), 6 AD&D-style reproduction attributes, and universal plus gender-specific biological/genetic attributes. Each displayed attribute is calculated by a dedicated microservice.
- **Chat Channels (Global / World, Group, Direct Message):** Real-time communication channels powered by `chat-service`, `chat-world-registry`, and `frontend-chat`: **Global / World Chat** (World of Warcraft-style community channels partitioned into player-selectable **World Chat Servers**), **Group Chat** (private channel for a Game Master and his/her Group), and **Direct Message Chat** (private 1-to-1 messaging between Players).
- **Climacterium (Menopause):** The natural female reproductive transition (`climacterium_state`: `PERIMENOPAUSAL` → `CLIMACTERIC`) tracked by `sim-menstruation` and `sim-lifecycle` as ovarian egg reserve depletes with age. Upon reaching `climacterium_date`, ovulation and menstrual cycles cease and female `fertility_score` becomes strictly `0`.
- **Conception:** The biological fertilization event in which a surface-compatible winning sperm cell (confirmed by `sim-gamete-surface`, with its haploid DNA) fuses with a viable egg cell (selected from the mother's Egg-Reserve SQLite database by `sim-egg-selection`, with its haploid DNA), triggering allocation of a new Character UUID and diploid DNA calculation.
- **DNA (Genome):** The immutable diploid genetic blueprint (23 chromosome pairs) calculated for each newly conceived character by combining the haploid DNA of the mother's egg cell and the haploid DNA of the father's winning sperm cell.
- **Egg Cell (Oocyte):** A female gamete generated at birth by `sim-egg-reserve` and stored inside the female character's UUID-linked **Egg-Reserve SQLite database**, carrying its own **haploid DNA** (22 autosomes + `X`) calculated via meiosis from her diploid DNA, along with a **surface receptor profile** checked during fertilization. During each post-menarche cycle, `sim-egg-selection` determines which egg cell drops for ovulation.
- **Egg-Reserve Database:** A dedicated **SQLite database** created at birth by `sim-egg-reserve` and explicitly linked to a female character's `UUID`, storing all simulated egg cells she carries with her at birth and queried each cycle by `sim-egg-selection` to determine which egg cell drops during her next cycle.
- **Ejaculation Database:** A dedicated, event-scoped **SQLite database** built by `sim-ejaculation` for a male character's ejaculation event, storing all simulated sperm cells in that ejaculation along with their individual haploid DNA (derived from the father's DNA), surface ligand profile, `erection_quality`, `ejaculation_quality`, short-interval `quality_factor`, and motility/viability attributes.
- **Fertility (`fertility_score`, `0–100`):** A lifecycle-dynamic biological fertility value (`0` to `100`) shaped by age, `gender`, health indicators, and body-composition metrics (`attr-fertility-index`). Female characters have `0` prior to first ovulation and `0` upon climacterium, with young women more fertile than older women; male characters have `0` in childhood, become fertile during their teenage years (`date_of_first_fertility`), rise to a peak around age 21, and decline slowly thereafter.
- **Game Master (GM):** A user role responsible for managing a simulation Group (campaign). Game Masters can view all character sheets of players and NPCs within their group(s), initialize the Group's simulation with a mandatory start date (`dd/MM/YYYY`, always starting at `0:00 h`), control group-level simulation settings including per-group simulation tick speed (default: `1 simulated year = 24 hours real time`), stop and resume the Group's simulation tick whenever role-play needs it, adjust character `weight_kg` and bounded role-play health indicators within configured biological/role-play parameters (with full audit logging), and participate in and moderate their Group Chat.
- **Group:** A logical simulation world or campaign managed by a Game Master, grouping Players and their Characters together under a dedicated Group Chat and an independent per-group simulation clock (initialized from a mandatory GM-entered `dd/MM/YYYY` start date at `0:00 h`, defaulting to `1 simulated year = 24 hours real time`, GM-adjustable and stoppable/resumable for role-play). Within a Group, each Player plays **only one Character**, selected at the start of the Group from the Characters they already own; children conceived or born in the Group live there as NPCs and can only be played in a future Group.
- **Health & Fitness Indicators:** Dynamic physiological indicators simulated over each character's lifecycle by `sim-health` and influenced by role-play (Player lifestyle/training routines and bounded GM adjustments), including **Heart Health** (`ILL`, `HEALTHY_NOT_SPORTY`, `HEALTHY_NORMAL`, `HEALTHY_SPORTY`), **Waking Heart Rate (`waking_heart_rate_bpm`)** (resting heart rate shortly after waking up), **Muscles / Muscular Conditioning** (`WEAK`, `NORMAL`, `SPORTY`, `BODY_BUILDER`), **Blood Pressure**, **Respiratory / Aerobic Health (`VO2 max`)**, **Metabolic Health**, **Immune Health**, **Sleep & Recovery Quality**, and **Stress & Allostatic Load**. These indicators feed into body-composition metrics, intercourse & fertility values, the 6 AD&D-style reproduction attributes, and biological simulation processes (`sim-menarche`, `sim-menstruation`, `sim-egg-selection`, `sim-ejaculation`, `sim-conception`, `sim-prenatal-loss`, `sim-gestation`, `sim-mortality`, and `sim-lifecycle`).
- **Intercourse Values:** Abstract, clinical/biological parameters (`CHARACTER_INTERCOURSE_PROFILE`) modeled in compliance with the zero-violence, zero-nudity policy that shape both role-play and reproduction simulation—including universal **Fertility (`fertility_score`, `0–100`)**, **Libido (`libido_score`, `0–100`)**, and **Intercourse Stamina (`intercourse_stamina`, `0–100`)**, male **Quality of Erection (`erection_quality`, `0–100`)**, **Quality of Ejaculation (`ejaculation_quality`, `0–100`)**, and **Refractory Period (`refractory_period_minutes`)**, and female **Vaginismus (`vaginismus`, boolean)**, **Lubrication Quality (`lubrication_quality`, `0–100`)**, and **Climacterium State (`climacterium_state`)**.
- **Medical Drugs (Role Play):** Gender-eligible pharmacological modifiers (such as **Viagra** for `MALE` characters and the **Contraception Pill** for `FEMALE` characters) that a Player can enable or disable for their character by clicking the checkbox in front of each eligible drug on the character sheet. Active medical drugs influence the simulation deterministically—Viagra increases erection quality and the chance of one or more ejaculations within a day (interacting with progressive ejaculation quality decrease when multiple ejaculations occur within a short period of time), while the contraception pill influences the female menstruation period and substantially reduces the chance of conceiving a baby.
- **Menarche (Date of First Menstruation):** A female-specific biological milestone calculated for a young female character by `sim-menarche`, recording the simulated calendar date of her first menstruation, followed by ongoing recorded `menstruation_dates`.
- **NPC (Non-Player Character) & Child Ownership Agreement:** Children conceived or born during a simulation start as unowned **NPCs** (`owner_user_id = null`) until the Players of the mother and the father reach a mutual **Ownership Agreement** deciding who takes ownership of the child. Even after ownership is assigned, the child remains an NPC in the Group where its mother and father live and can only be selected as a playable character in a **future Group**.
- **Phenotype:** The observable biological and visual traits of a character (such as facial features, `eye_color`, `hair_color`, `skin_color`, and vitality scores), derived from the character's DNA combined with gender, age, and lifecycle state—including traits that naturally shift after birth and during life.
- **Player / User:** An authenticated user in PrincessPink identified by a unique **UUID**. A Player may own multiple Characters in their personal roster, selects **one owned Character** to play at the start of each Group, and has access to the character sheets of their owned characters.
- **Prenatal Loss (`sim-prenatal-loss`):** Natural, clinical embryo or fetal loss prior to live birth (`PRE_IMPLANTATION_LOSS`, `EARLY_MISCARRIAGE`, `LATE_MISCARRIAGE`, or `STILLBIRTH`), modeled in compliance with the zero-violence, zero-nudity policy by the independently versioned `sim-prenatal-loss` microservice and persisted in `PREGNANCY`. Enabled by default and GM-configurable per Group in `GROUP.simulation_config` (`prenatal_loss.enabled`, `prenatal_care_tier`, bounded `risk_multiplier`, `track_pre_implantation_loss`), prenatal loss synthesizes available genetic/gamete quality, maternal and paternal age, maternal-fetal Rh/blood-type compatibility, maternal health and body-composition indicators, reproduction attributes (`CON`, `HOR`, `REC`, `VIT`, `FER`), obstetric history, breakthrough contraception, and post-term timing. When a prenatal loss occurs, the conceived character transitions to `DECEASED` with `date_of_birth = null` and `date_of_death` recorded permanently, pending `OWNERSHIP_AGREEMENT` records close (`CLOSED_PRENATAL_LOSS`), newborn pipelines are skipped, and maternal health and menstrual cycles undergo stage-proportional recovery.
- **Reproduction Attributes:** Six AD&D-style numeric tabletop stats displayed on every character sheet—**Fertility (`FER`)**, **Constitution (`CON`)**, **Vitality (`VIT`)**, **Hormonal Balance (`HOR`)**, **Receptivity (`REC`)**, and **Compatibility (`COM`)**—whose derived modifiers affect the probability and mechanics of every reproduction try.
- **Simulation Tick:** A discrete unit of simulated time broadcast per Group by the Simulation Clock Service (`sim-clock`) to advance biological cycles, gestation, and aging deterministically. Each Group has its own sim tick configuration—defaulting to **1 simulated year per 24 hours in real time**—which the Group's Game Master may adjust, stop, and resume whenever role-play requires it, starting from `0:00 h` on the mandatory `dd/MM/YYYY` start date entered by the Game Master at the start of the simulation.
- **Sperm Cell (Spermatozoon):** A male gamete simulated inside a per-ejaculation SQLite database, carrying its own **haploid DNA** (22 autosomes + `X` or `Y`) calculated via meiosis from the father's diploid DNA, together with motility, morphology, viability, and **surface ligand profile** traits used by `sim-sperm-race` and `sim-gamete-surface`.
- **Vaginismus (`vaginismus`):** A female-specific clinical boolean intercourse value (`true` / `false`) indicating involuntary pelvic-floor muscle contraction impeding penetrative intercourse (`attr-vaginismus`). Influences non-explicit tabletop role-play (narrative comfort, communication, and medical/therapeutic progression audited via `HEALTH_ADJUSTMENT`) and reduces penetrative attempt completion probability in `sim-ejaculation` / `sim-sperm-race` / `sim-conception` without affecting ovarian cycles or egg reserve.
- **World Chat Server:** A logical, player-selectable World of Warcraft-style public chat server managed by `chat-world-registry` and partitioned onto its own NATS JetStream subject (`chat.world.<world_server_id>`). Players choose or switch their World Chat Server by language, region, category, and population band without dropping their WebSocket session or interrupting Group Chat and Direct Messages (see [ADR-0002](architecture/ADR-0002-world-chat-microservices-and-server-selection.md)).