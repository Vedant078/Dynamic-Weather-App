# PRD: Mausam — Multi-Persona Weather App & RMC Logistics Risk Engine

## 1. Executive Summary & SIH Problem Statement

### 1.1 Product Overview

**Mausam** is a multi-persona, AI-assisted weather intelligence application designed to transform raw environmental telemetry into **context-aware operational decisions**.

The application supports six consumer/professional personas while placing the majority of its functional depth on a seventh, primary persona:

> **Commercial / RMC Logistics Manager — Ready-Mix Concrete Transit Loss Prevention**

The prototype is intended for **Smart India Hackathon (SIH)** presentation and demonstration. The RMC module demonstrates how weather, traffic, geospatial, operational, and historical concrete-delivery data can be combined into a real-time risk engine.

Instead of answering only:

> "What is the weather?"

Mausam answers:

> **"Given the weather, traffic, route, concrete batch age, and operational constraints, what should the operator do right now?"**

### 1.2 SIH Problem Statement

Ready-Mix Concrete (RMC) is a time-sensitive construction material whose quality can deteriorate during transit. Environmental temperature, precipitation, traffic congestion, route length, delays, and batch age can collectively increase the probability of slump loss and delivery rejection.

The operational challenge is therefore not simply weather forecasting. It is **predicting the interaction between environmental conditions and logistics execution**.

A conventional dispatch workflow may involve:

1. Batch creation at the plant.
2. Manual route selection.
3. Driver departure.
4. Traffic-related delay.
5. Increasing concrete temperature / hydration progression.
6. Arrival at construction site.
7. Slump verification.
8. Acceptance or rejection.
9. Financial loss if the batch cannot be used.

Mausam introduces a predictive decision layer between dispatch and delivery.

### 1.3 Product Objective

The RMC system shall:

- Ingest live weather, traffic, route, and batch telemetry.
- Predict concrete transit/slump-loss risk.
- Quantify Heat, Travel, and Delivery Risk.
- Continuously update risk during transit.
- Recommend weather-weighted routes.
- Detect potentially unsafe ETAs.
- Present actionable mitigation options.
- Record actual delivery outcomes.
- Calculate avoidable financial loss.
- Feed historical outcomes into an ML retraining pipeline.

### 1.4 Prototype Success Criteria

The SIH prototype should demonstrate a complete lifecycle:

```text
Persona Selection
       ↓
RMC Dashboard
       ↓
Create / Select Batch
       ↓
Select Plant + Project
       ↓
Retrieve Route + Weather + Traffic
       ↓
ML Risk Prediction
       ↓
Live Transit Simulation / Telemetry
       ↓
Risk Escalation
       ↓
Recommended Action
       ↓
Delivery Outcome
       ↓
Loss / Quality Calculation
       ↓
ML Feedback Dataset
```

### 1.5 Primary Demonstration Scenario

A representative demonstration should simulate:

- RMC plant dispatching a concrete batch.
- Ambient temperature increasing along the route.
- Traffic congestion causing ETA degradation.
- AI detecting increasing delivery/slump-loss risk.
- Dashboard changing from **Approved** to **High Risk**.
- Action panel recommending mitigation.
- Operator selecting a mitigation or override.
- Batch reaching site.
- Actual slump being recorded.
- Outcome and financial impact being calculated.
- Delivery record becoming training data.

---

# 2. Multi-Persona Framework & Onboarding Flow

## 2.1 Persona Model

Mausam uses a **persona-first UX architecture**.

On initial launch, the user selects a persona. The selected persona determines:

- Dashboard layout.
- Primary KPIs.
- Alerts.
- Map layers.
- Recommended actions.
- Data refresh frequency.
- AI insights displayed.

The RMC persona receives the deepest functionality.

### Supported Personas

| Persona | Primary Intelligence |
|---|---|
| Health-Conscious Users | AQI, pollen, UV, heat exposure |
| Outdoor Fitness Enthusiasts | Running windows, heat, wind |
| Beachgoers & Surfers | Tides, waves, water temperature |
| Travelers & Commuters | Destinations, route/weather alerts |
| Parents & Families | School commute, rain alerts |
| Agriculture & Gardeners | Soil moisture, frost, crop guidance |
| **Commercial / RMC Logistics Manager** | **Transit risk, slump loss, ETA, route optimization** |

---

## 2.2 Persona Selection UX Workflow

### Launch Screen

The launch screen presents:

```text
┌─────────────────────────────────────┐
│              MAUSAM                 │
│                                     │
│     Weather that understands        │
│          what you do.               │
│                                     │
│  Choose your experience             │
│                                     │
│  [ ❤️ Health ]   [ 🏃 Fitness ]     │
│  [ 🏖 Beach ]    [ ✈ Travel ]       │
│  [ 👨‍👩‍👧 Family ] [ 🌱 Agriculture ] │
│                                     │
│  [ 🚛 RMC Logistics Manager ]       │
│                                     │
└─────────────────────────────────────┘
```

### RMC Selection

Selecting **RMC Logistics Manager** transitions to the operational dashboard rather than a conventional weather homepage.

The header retains a persona toggle:

```text
MAUSAM                     [RMC ▼]
```

The user can switch persona without restarting the application.

---

## 2.3 Persona State

Frontend state:

```text
selectedPersona
├── health
├── fitness
├── beach
├── traveler
├── family
├── agriculture
└── rmc
```

Persisted locally using Flutter secure/local preferences.

Backend requests should include:

```http
X-Mausam-Persona: rmc
```

or:

```json
{
  "persona": "rmc"
}
```

---

## 2.4 Secondary Persona Feature Matrix

| Feature | Health | Fitness | Beach | Traveler | Family | Agriculture |
|---|---:|---:|---:|---:|---:|---:|
| Current weather | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Temperature | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| AQI | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| UV Index | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Rain alerts | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Wind | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Pollen | ✓ | ✓ | — | — | ✓ | ✓ |
| Running window | — | ✓ | — | — | — | — |
| Heat alerts | ✓ | ✓ | — | ✓ | ✓ | ✓ |
| Tide timings | — | — | ✓ | — | — | — |
| Wave height | — | — | ✓ | — | — | — |
| Water temperature | — | — | ✓ | — | — | — |
| Saved destinations | — | — | — | ✓ | ✓ | — |
| Flight weather | — | — | — | ✓ | — | — |
| School commute | — | — | — | — | ✓ | — |
| Soil moisture | — | — | — | — | — | ✓ |
| Frost alerts | — | — | — | — | — | ✓ |
| Crop guidance | — | — | — | — | — | ✓ |

The secondary personas are intentionally implemented as **thin vertical slices** for the SIH prototype.

---

# 3. RMC Logistics Persona — Deep Dive & Problem Formulation

## 3.1 Persona Definition

### Primary User

**Commercial / RMC Logistics Manager**

Typical responsibilities:

- Monitor active concrete batches.
- Coordinate batching plants and project sites.
- Dispatch transit mixers.
- Monitor ETAs.
- Handle traffic disruptions.
- Prevent rejected batches.
- Coordinate drivers and site teams.
- Minimize material and operational losses.

### Secondary Users

- Plant operator.
- Dispatch controller.
- Site engineer.
- Fleet manager.
- RMC operations head.

---

## 3.2 Core Problem

The operational decision can be modeled as:

\[
DeliveryRisk = f(T_{ambient}, T_{concrete}, Traffic, ETA, Distance, BatchAge, Slump, Precipitation, Route)
\]

The system must estimate whether a batch can reach its destination within operational quality constraints.

A simplified transit-loss relationship is:

\[
SlumpLoss = f(Time, Temperature, TrafficDelay, InitialSlump, MixContext)
\]

The prototype must **not present the ML output as a certified engineering specification**. It is a decision-support score that requires validation against plant-specific concrete data before production deployment.

---

## 3.3 Primary RMC KPIs

### Batch-Level KPIs

- Batch ID.
- Batch age.
- Initial slump.
- Current estimated slump.
- Slump retention percentage.
- Concrete temperature.
- Distance remaining.
- ETA.
- Transit duration.
- Heat Risk.
- Travel Risk.
- Delivery Risk.

### Fleet-Level KPIs

- Active batches.
- Batches at risk.
- Average ETA deviation.
- Rejected batches.
- Estimated loss avoided.
- Current fleet exposure.
- Plant utilization.

### Executive KPIs

```text
Active Deliveries       17
High-Risk Batches        3
Average Transit         54 min
At-Risk Volume         48 m³
Potential Loss        ₹2.41L
Loss Avoided           ₹86K
```

---

## 3.4 Operational Thresholds

The prototype decision engine uses the supplied operational policy.

### Path A — Approved

```text
Transit <= 78 min
AND
Slump >= 92%
AND
ETA = On Time
```

System response:

> **APPROVED — Proceed with standard navigation**

### Path B — High Risk

Triggered by any major unsafe condition such as:

- High temperature.
- Unsafe ETA.
- Severe congestion.
- Predicted slump below threshold.
- Excessive transit duration.

System response:

```text
HIGH RISK

Recommended Actions:

[ Add Retarder Admixture ]
[ Reschedule Batch ]
[ Calculate New Route ]
[ Override & Proceed ]
```

The thresholds are **prototype/business-policy values** and must be configurable rather than hard-coded into the ML model.

---

# 4. End-to-End System Architecture (The 7-Step Pipeline)

## 4.1 High-Level Architecture

```text
                 ┌───────────────────────────┐
                 │      Flutter Mobile App   │
                 │                           │
                 │ Dashboard / Map / Gauges  │
                 └─────────────┬─────────────┘
                               │
                     REST + WebSocket
                               │
                 ┌─────────────▼─────────────┐
                 │       FastAPI Backend     │
                 │                           │
                 │ API / Auth / Orchestrator │
                 └─────────────┬─────────────┘
                               │
          ┌────────────────────┼────────────────────┐
          │                    │                    │
          ▼                    ▼                    ▼
   Weather Adapter      Traffic Adapter       Route Engine
   Open-Meteo            Routing API           Map Provider
          │                    │                    │
          └────────────────────┼────────────────────┘
                               │
                       ┌───────▼────────┐
                       │  Risk Engine   │
                       │  Scikit-learn  │
                       └───────┬────────┘
                               │
                 ┌─────────────┴─────────────┐
                 ▼                           ▼
            PostgreSQL                    Redis
          Historical State            Live Telemetry
                 │                           │
                 └─────────────┬─────────────┘
                               ▼
                       Feedback / Training
```

---

## 4.2 Step 1 — Input & Context Layer

### Weather Telemetry

Weather data is collected for route waypoints rather than solely for the plant or destination.

Required variables:

```text
ambient_temperature
precipitation
relative_humidity
wind_speed
weather_code
forecast_timestamp
latitude
longitude
```

Open-Meteo acts as the primary weather provider.

### Traffic Telemetry

Required fields:

```text
congestion_index
current_speed
free_flow_speed
expected_delay_seconds
road_segment
timestamp
```

### Spatial Location

The route is represented as:

```text
Plant
  ↓
Waypoint 1
  ↓
Waypoint 2
  ↓
...
  ↓
Project Site
```

### Operational Context

```text
batch_id
mix_type
target_slump
initial_slump
batch_volume_m3
dispatch_time
required_arrival_time
maximum_transit_minutes
project_id
plant_id
```

---

# 4.3 Step 2 — AI Risk Model Layer

The risk engine consumes environmental, spatial, traffic, and operational features.

### Output

Three normalized risk scores:

```text
Heat Risk       0–100
Travel Risk     0–100
Delivery Risk   0–100
```

Example:

```text
Heat Risk       ███████████████░ 82
Travel Risk     ███████████░░░░░ 61
Delivery Risk   █████████████░░░ 74
```

### Composite Risk

A configurable weighted score:

\[
R_{total} =
w_hR_h + w_tR_t + w_dR_d
\]

Example prototype weights:

```text
Heat Risk       30%
Travel Risk     30%
Delivery Risk   40%
```

The weights should be configurable from backend configuration rather than embedded in Flutter.

---

# 4.4 Step 3 — RMC Plant & Project Live Telemetry

The active delivery screen receives real-time telemetry.

### Required Live Metrics

```text
Time elapsed
Current slump
Concrete temperature
Distance remaining
ETA
Current location
Traffic state
Risk score
```

Example:

```text
BATCH #RMC-24081

Elapsed       54 min
ETA           21 min
Distance      13.4 km

Concrete      34.8°C
Slump         97%
Target        105 mm

HEAT RISK     72
TRAVEL RISK   64
DELIVERY      69
```

Redis stores the latest state.

WebSocket pushes changes to connected clients.

---

# 4.5 Step 4 — Decision Path Logic

## Path A

Condition:

```python
transit_minutes <= 78
and slump_retention >= 0.92
and eta_status == "on_time"
```

Result:

```text
status = APPROVED
action = STANDARD_NAVIGATION
```

UI:

```text
✓ DELIVERY ON TRACK

Batch is within current operational limits.

[Continue Navigation]
```

---

## Path B

Triggered when:

```text
High Heat
OR
Unsafe ETA
OR
Predicted Slump < threshold
OR
Transit duration approaching maximum
```

UI:

```text
⚠ HIGH DELIVERY RISK

Predicted quality deterioration detected.

Recommended actions:

┌─────────────────────────────┐
│ Add Retarder Admixture      │
└─────────────────────────────┘

┌─────────────────────────────┐
│ Reschedule Batch            │
└─────────────────────────────┘

┌─────────────────────────────┐
│ Calculate New Route         │
└─────────────────────────────┘

┌─────────────────────────────┐
│ Override & Proceed          │
└─────────────────────────────┘
```

Every override must be logged.

---

# 4.6 Step 5 — Outcome & Feedback Tracker

After delivery, the operator records:

```text
Actual arrival time
Actual slump
Concrete temperature
Batch accepted/rejected
Rejection reason
Root cause
Financial loss
Mitigation action
Operator override
```

### Successful Delivery

Example:

```json
{
  "outcome": "accepted",
  "transit_minutes": 71,
  "initial_slump_mm": 115,
  "site_slump_mm": 105,
  "concrete_temperature_c": 33.8,
  "quality_confirmation": true
}
```

### Rejected Batch

Example:

```json
{
  "outcome": "rejected",
  "reason": "Extreme ETA delay",
  "financial_loss_inr": 241000,
  "root_cause": "traffic_and_temperature"
}
```

---

# 4.7 Step 6 — ML Model Retraining Loop

The system stores:

```text
Prediction
+
Input Features
+
Actual Outcome
```

Training dataset:

```text
Temperature
Traffic
Transit Time
Batch Age
Initial Slump
Concrete Temperature
Precipitation
Distance
Predicted ETA
Actual ETA
Actual Slump Loss
Outcome
```

Pipeline:

```text
PostgreSQL
    ↓
Training Dataset Extractor
    ↓
Data Validation
    ↓
Feature Engineering
    ↓
Train/Test Split
    ↓
Scikit-learn Model
    ↓
Evaluation
    ↓
Model Artifact
    ↓
Model Registry
    ↓
Risk Engine
```

Retraining should initially be **offline/manual or scheduled**, rather than automatically replacing the production model after every delivery.

---

# 4.8 Step 7 — Route & Dispatch Recommendation Engine

The route engine evaluates candidate routes using both logistics and concrete-quality risk.

Traditional routing:

\[
RouteScore = ETA
\]

Mausam:

\[
RouteScore =
w_1(ETA)
+
w_2(TrafficRisk)
+
w_3(HeatExposure)
+
w_4(TransitDecayRisk)
\]

Example:

| Route | ETA | Traffic | Heat Exposure | Delivery Risk |
|---|---:|---:|---:|---:|
| Route A | 61m | High | Medium | 72 |
| Route B | 66m | Low | Low | 39 |
| Route C | 58m | Severe | High | 81 |

The recommendation engine should optimize for **operational quality-adjusted travel**, not simply minimum distance.

---

# 5. AI / ML Model Architecture (Scikit-learn Feature Matrix & Risk Scoring)

## 5.1 ML Objective

The prototype's central model predicts:

> **Expected slump retention / slump loss at delivery**

A secondary classification layer converts predicted deterioration into operational risk.

---

## 5.2 Model Options

Primary prototype candidates:

### Gradient Boosting Regressor

Advantages:

- Handles nonlinear relationships.
- Good for tabular data.
- Suitable for small/medium datasets.
- Captures interactions between temperature, traffic, and time.

### Random Forest Regressor

Used as:

- Baseline.
- Robust comparison model.
- Feature-importance reference.

Recommended prototype approach:

```text
Random Forest
      ↓
Baseline
      ↓
Gradient Boosting
      ↓
Validation
      ↓
Selected Model
```

The prototype should avoid claiming that one model is universally superior without validation against actual RMC data.

---

## 5.3 Feature Matrix

| Feature | Type | Example |
|---|---|---:|
| Ambient temperature | float | 39.2°C |
| Concrete temperature | float | 35.4°C |
| Relative humidity | float | 42% |
| Wind speed | float | 18 km/h |
| Precipitation | float | 0 mm |
| Heat index | float | 43°C |
| Traffic congestion | float | 0.72 |
| Expected traffic delay | float | 17 min |
| Distance | float | 28.5 km |
| Initial ETA | float | 54 min |
| Current ETA | float | 71 min |
| Batch age | float | 54 min |
| Initial slump | float | 115 mm |
| Target slump | float | 105 mm |
| Concrete volume | float | 6 m³ |
| Route heat exposure | float | 0.68 |
| Historical segment risk | float | 0.43 |
| Time of day | categorical/derived | 14:30 |
| Day of week | categorical/derived | Monday |

---

## 5.4 Target Variables

### Regression Target

```text
slump_loss_mm
```

or:

```text
slump_retention_ratio
```

Example:

```text
Initial Slump = 115 mm
Site Slump    = 105 mm

Slump Loss = 10 mm
Retention  = 91.3%
```

### Classification Target

```text
delivery_outcome
```

Possible values:

```text
accepted
at_risk
rejected
```

For the initial prototype, regression should remain the primary model.

---

## 5.5 Feature Engineering

### Batch Age

```python
batch_age_minutes = current_time - batch_dispatch_time
```

### ETA Deviation

```python
eta_deviation = current_eta - original_eta
```

### Traffic Ratio

```python
traffic_ratio = current_speed / free_flow_speed
```

### Heat Exposure

For route segments:

\[
HeatExposure =
\frac{\sum_i Temp_i \times SegmentDuration_i}
{\sum_i SegmentDuration_i}
\]

### Weather-Weighted Transit Exposure

\[
Exposure =
\sum_i
Temperature_i
\times
TravelTime_i
\]

This allows route comparison beyond simple distance.

---

## 5.6 Risk Scoring

Model output:

```text
predicted_slump_retention = 0.91
```

Operational mapping:

```text
Retention >= 0.92 → Low/Approved
Retention < 0.92  → Elevated Risk
```

The final risk score should combine model output and operational signals.

Example:

```python
delivery_risk = (
    0.50 * model_risk +
    0.25 * traffic_risk +
    0.25 * heat_risk
)
```

The exact coefficients are configuration values for the prototype and should be validated before production deployment.

---

## 5.7 Explainability

Every risk prediction should expose top contributing factors.

Example:

```text
Why is this batch at risk?

1. +18 risk — ETA increased by 16 minutes
2. +14 risk — Ambient temperature 40.2°C
3. +11 risk — Batch age 63 minutes
4. +7 risk  — High congestion segment ahead
```

For tree models, feature importance and/or permutation importance can support this layer.

---

## 5.8 Model Evaluation

Required metrics:

### Regression

- MAE.
- RMSE.
- R².

### Operational

- High-risk recall.
- False alert rate.
- Rejection prediction accuracy.
- Mean absolute slump prediction error.

Example prototype acceptance targets should be treated as **engineering goals rather than claims**:

```text
MAE: ≤ 10 mm
High-risk recall: ≥ 85%
False alert rate: ≤ 20%
```

Final thresholds must be established from real plant-specific validation data.

---

## 5.9 Model Versioning

Every prediction should store:

```text
model_name
model_version
prediction_timestamp
feature_snapshot
prediction
risk_score
```

Example:

```text
model_name: slump_loss_gbr
model_version: 0.3.0
```

This allows post-event analysis of which model generated a decision.

---

# 6. Technical Stack & Data Flow Diagram

## 6.1 Technology Stack

| Layer | Technology |
|---|---|
| Mobile | Flutter |
| Language | Dart |
| API | Python |
| Backend Framework | FastAPI |
| Async Runtime | Uvicorn |
| ML | Scikit-learn |
| Primary DB | PostgreSQL |
| Cache | Redis |
| Weather | Open-Meteo |
| Air Quality | CPCB API |
| Routing | Mapbox / Google Maps |
| Maps | Flutter Map SDK |
| Realtime | WebSocket |
| Containerization | Docker |
| API Contract | OpenAPI |
| Authentication | JWT/OAuth-compatible architecture |
| Observability | Structured logs + metrics |

---

## 6.2 Logical Data Flow

```text
              EXTERNAL DATA
┌──────────────┬───────────────┬───────────────┐
│ Open-Meteo   │ CPCB          │ Traffic API   │
└──────┬───────┴───────┬───────┴───────┬───────┘
       │               │               │
       └───────────────┼───────────────┘
                       ▼
              ┌────────────────┐
              │ Data Adapters  │
              └───────┬────────┘
                      ▼
              ┌────────────────┐
              │ Context Engine │
              └───────┬────────┘
                      ▼
              ┌────────────────┐
              │ Risk / ML      │
              │ Engine         │
              └───────┬────────┘
                      ▼
              ┌────────────────┐
              │ Decision Engine│
              └───────┬────────┘
                      │
             ┌────────┴─────────┐
             ▼                  ▼
         PostgreSQL           Redis
         Historical           Live State
             │                  │
             └────────┬─────────┘
                      ▼
                 FastAPI
                      │
                REST/WebSocket
                      │
                      ▼
                  Flutter
                      │
                      ▼
                RMC Operator
```

---

## 6.3 Backend Service Boundaries

For the prototype, a modular monolith is preferred over premature microservices.

```text
app/
├── api/
│   ├── routes/
│   ├── websocket/
│   └── dependencies/
├── domain/
│   ├── batches/
│   ├── routes/
│   ├── projects/
│   └── telemetry/
├── services/
│   ├── weather/
│   ├── traffic/
│   ├── routing/
│   ├── risk/
│   └── dispatch/
├── ml/
│   ├── features/
│   ├── training/
│   ├── inference/
│   └── artifacts/
├── repositories/
├── models/
├── schemas/
├── workers/
└── main.py
```

---

# 7. Data Schemas & API Contracts (FastAPI & PostgreSQL)

## 7.1 Core PostgreSQL Entities

### `users`

```sql
CREATE TABLE users (
    id UUID PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT UNIQUE,
    created_at TIMESTAMPTZ NOT NULL
);
```

### `user_personas`

```sql
CREATE TABLE user_personas (
    user_id UUID REFERENCES users(id),
    persona VARCHAR(50) NOT NULL,
    is_default BOOLEAN DEFAULT FALSE,
    PRIMARY KEY (user_id, persona)
);
```

### `plants`

```sql
CREATE TABLE plants (
    id UUID PRIMARY KEY,
    name TEXT NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL
);
```

### `projects`

```sql
CREATE TABLE projects (
    id UUID PRIMARY KEY,
    name TEXT NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    target_arrival TIMESTAMPTZ
);
```

### `batches`

```sql
CREATE TABLE batches (
    id UUID PRIMARY KEY,
    plant_id UUID REFERENCES plants(id),
    project_id UUID REFERENCES projects(id),
    batch_code TEXT UNIQUE NOT NULL,
    volume_m3 NUMERIC NOT NULL,
    target_slump_mm NUMERIC NOT NULL,
    initial_slump_mm NUMERIC,
    dispatch_time TIMESTAMPTZ,
    status VARCHAR(30) NOT NULL
);
```

### `routes`

```sql
CREATE TABLE routes (
    id UUID PRIMARY KEY,
    batch_id UUID REFERENCES batches(id),
    distance_km NUMERIC,
    estimated_minutes NUMERIC,
    actual_minutes NUMERIC,
    route_geometry JSONB,
    created_at TIMESTAMPTZ
);
```

### `telemetry_events`

```sql
CREATE TABLE telemetry_events (
    id BIGSERIAL PRIMARY KEY,
    batch_id UUID REFERENCES batches(id),
    timestamp TIMESTAMPTZ NOT NULL,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    ambient_temp_c NUMERIC,
    concrete_temp_c NUMERIC,
    precipitation_mm NUMERIC,
    wind_speed_kmh NUMERIC,
    traffic_index NUMERIC,
    eta_minutes NUMERIC,
    distance_remaining_km NUMERIC,
    predicted_slump_mm NUMERIC,
    heat_risk NUMERIC,
    travel_risk NUMERIC,
    delivery_risk NUMERIC
);
```

### `delivery_outcomes`

```sql
CREATE TABLE delivery_outcomes (
    id UUID PRIMARY KEY,
    batch_id UUID REFERENCES batches(id),
    outcome VARCHAR(30) NOT NULL,
    site_slump_mm NUMERIC,
    rejection_reason TEXT,
    root_cause VARCHAR(100),
    financial_loss_inr NUMERIC,
    recorded_at TIMESTAMPTZ NOT NULL
);
```

### `model_predictions`

```sql
CREATE TABLE model_predictions (
    id BIGSERIAL PRIMARY KEY,
    batch_id UUID REFERENCES batches(id),
    model_name TEXT NOT NULL,
    model_version TEXT NOT NULL,
    predicted_slump_mm NUMERIC,
    heat_risk NUMERIC,
    travel_risk NUMERIC,
    delivery_risk NUMERIC,
    features JSONB,
    created_at TIMESTAMPTZ NOT NULL
);
```

---

## 7.2 Redis Data Model

Live batch state:

```text
rmc:batch:{batch_id}:telemetry
```

Example:

```json
{
  "lat": 23.0225,
  "lng": 72.5714,
  "elapsed_min": 54,
  "eta_min": 21,
  "distance_remaining_km": 13.4,
  "concrete_temp_c": 34.8,
  "predicted_slump_mm": 101,
  "heat_risk": 72,
  "travel_risk": 64,
  "delivery_risk": 69,
  "status": "HIGH_RISK"
}
```

Redis TTL should be configured so stale batches do not remain indefinitely.

---

# 7.3 FastAPI API Contracts

## Get Persona

```http
GET /api/v1/personas
```

Response:

```json
{
  "personas": [
    {
      "id": "rmc",
      "name": "RMC Logistics Manager"
    }
  ]
}
```

---

## Create Batch

```http
POST /api/v1/rmc/batches
```

Request:

```json
{
  "plant_id": "plant-001",
  "project_id": "project-042",
  "volume_m3": 6,
  "target_slump_mm": 105,
  "initial_slump_mm": 115
}
```

Response:

```json
{
  "batch_id": "batch-1001",
  "status": "CREATED"
}
```

---

## Analyze Route

```http
POST /api/v1/rmc/routes/analyze
```

Request:

```json
{
  "batch_id": "batch-1001",
  "origin": {
    "lat": 23.02,
    "lng": 72.57
  },
  "destination": {
    "lat": 23.04,
    "lng": 72.59
  }
}
```

Response:

```json
{
  "recommended_route_id": "route-02",
  "eta_minutes": 66,
  "delivery_risk": 39,
  "alternatives": [
    {
      "route_id": "route-01",
      "eta_minutes": 61,
      "delivery_risk": 72
    },
    {
      "route_id": "route-02",
      "eta_minutes": 66,
      "delivery_risk": 39
    }
  ]
}
```

---

## Risk Prediction

```http
POST /api/v1/rmc/risk/predict
```

Request:

```json
{
  "batch_id": "batch-1001",
  "ambient_temp_c": 39.2,
  "traffic_index": 0.72,
  "eta_minutes": 71,
  "elapsed_minutes": 54,
  "initial_slump_mm": 115,
  "concrete_temp_c": 35.4
}
```

Response:

```json
{
  "predicted_slump_mm": 101,
  "slump_retention": 0.878,
  "heat_risk": 72,
  "travel_risk": 64,
  "delivery_risk": 74,
  "decision": "HIGH_RISK",
  "contributors": [
    "Elevated ambient temperature",
    "Traffic delay",
    "High batch age"
  ]
}
```

---

## Record Outcome

```http
POST /api/v1/rmc/batches/{batch_id}/outcome
```

Request:

```json
{
  "outcome": "rejected",
  "site_slump_mm": 82,
  "rejection_reason": "Extreme ETA delay",
  "root_cause": "traffic",
  "financial_loss_inr": 241000
}
```

---

## Live Telemetry WebSocket

```text
/ws/v1/rmc/batches/{batch_id}
```

Server push:

```json
{
  "type": "telemetry_update",
  "timestamp": "2026-09-25T10:20:00Z",
  "eta_minutes": 22,
  "concrete_temp_c": 35.1,
  "delivery_risk": 77,
  "status": "HIGH_RISK"
}
```

---

# 8. Flutter Mobile UI / UX Specifications (Dark Theme, Gauges, Map Overlays)

## 8.1 Design Principles

The RMC interface must feel like an **operations control system**, not a consumer weather app.

Priorities:

1. Fast comprehension.
2. High visual signal-to-noise ratio.
3. Large actionable controls.
4. Persistent risk visibility.
5. Map-first situational awareness.
6. Minimal typing.
7. Real-time updates.

---

## 8.2 Dark Theme

Base palette:

```text
Background:     #0B0F14
Surface:        #121820
Elevated:       #19212B
Primary Text:   #F4F7FA
Secondary Text: #94A3B8
```

Risk colors should be semantically consistent:

```text
Low      → Green
Moderate → Amber
High     → Red
```

These colors should be implemented through centralized theme tokens.

---

# 8.3 RMC Dashboard

### Header

```text
┌─────────────────────────────────────────┐
│ MAUSAM             RMC Manager ▼   🔔   │
└─────────────────────────────────────────┘
```

### Fleet Summary

```text
┌──────────┬──────────┬──────────┬─────────┐
│ Active   │ At Risk  │ On Time  │ Loss    │
│ 17       │ 3        │ 14       │ ₹2.41L  │
└──────────┴──────────┴──────────┴─────────┘
```

### Active Batch Cards

```text
BATCH #RMC-24081

Plant A → Project 42

ETA 21m       13.4 km
Temp 34.8°C   Slump 97%

Heat       72
Travel     64
Delivery   69

⚠ HIGH RISK
```

---

# 8.4 Risk Gauge

Each risk dimension receives a radial or semicircular gauge.

```text
             72
         ┌───────┐
      ┌──┘ HEAT  └──┐
     ╱               ╲
    ╱                 ╲
   └───────────────────┘
```

The gauge must update from WebSocket telemetry without requiring a page refresh.

---

# 8.5 Live Route Map

Map layers:

### Base

- Roads.
- Plant.
- Project site.
- Active mixer location.

### Weather Overlay

- Temperature gradient.
- Rain cells.
- Wind indicators.

### Traffic Overlay

- Green: normal.
- Amber: moderate.
- Red: congestion.

### Risk Overlay

Route segments should be visually differentiated by estimated delivery risk.

```text
Plant
  │
  │ LOW
  │
  ├──────────────
  │              │ HIGH
  │              │
  └──────────────▼
              Site
```

---

# 8.6 Route Comparison UI

When route recalculation is triggered:

```text
ROUTE OPTIONS

Route A
61 min · 28.2 km
Delivery Risk: 72

Route B ★
66 min · 30.1 km
Delivery Risk: 39

Route C
58 min · 27.5 km
Delivery Risk: 81
```

The recommendation should clearly explain the trade-off:

> "Route B adds approximately 5 minutes but reduces predicted delivery risk."

---

# 8.7 High-Risk Action Sheet

A bottom sheet should appear automatically when the batch crosses the operational risk boundary.

```text
⚠ DELIVERY RISK DETECTED

ETA increased to 84 minutes.
Ambient temperature: 40.2°C.

Recommended action:
Calculate a lower-risk route.

[ Calculate New Route ]

Other actions:
[ Add Retarder ]
[ Reschedule ]
[ Override ]
```

The system should require confirmation before consequential actions.

---

# 8.8 Outcome Screen

After delivery:

```text
DELIVERY COMPLETE

Batch #RMC-24081

Plant Slump     115 mm
Site Slump      105 mm
Transit         71 min

✓ ACCEPTED

Quality:
HIGH

[ Confirm Delivery ]
```

Rejected:

```text
BATCH REJECTED

Site Slump      82 mm
Expected        101 mm

Root Cause:
Traffic + Elevated Temperature

Estimated Loss:
₹2,41,000

[ Submit Outcome ]
```

---

# 8.9 Prototype Navigation

```text
Bottom Navigation

[Dashboard] [Map] [Batches] [Analytics] [Profile]
```

RMC-specific screens:

```text
Dashboard
   ↓
Batch Details
   ↓
Live Route
   ↓
Risk Analysis
   ↓
Action Panel
   ↓
Outcome
   ↓
Analytics
```

---

# 8.10 Flutter Architecture

Recommended structure:

```text
lib/
├── core/
│   ├── theme/
│   ├── networking/
│   ├── websocket/
│   └── routing/
├── features/
│   ├── onboarding/
│   ├── personas/
│   ├── weather/
│   └── rmc/
│       ├── dashboard/
│       ├── batches/
│       ├── telemetry/
│       ├── routes/
│       ├── risk/
│       └── outcomes/
├── models/
├── services/
├── repositories/
└── main.dart
```

State management may use Riverpod, Bloc, or an equivalent production-grade reactive architecture. The prototype should standardize on one pattern rather than mixing approaches.

---

# 8.11 WebSocket State Management

Flutter should maintain:

```text
Connection State
├── Connecting
├── Connected
├── Reconnecting
└── Disconnected
```

On reconnect:

1. Re-establish WebSocket.
2. Fetch current REST snapshot.
3. Resume real-time stream.
4. Discard stale telemetry.

The REST endpoint is the source of truth for state recovery; WebSocket is the low-latency update channel.

---

# 8.12 Failure Handling

### Weather API unavailable

Display:

```text
Weather data temporarily unavailable.
Using last valid observation.
```

### Traffic API unavailable

Risk confidence decreases.

```text
Traffic telemetry unavailable.
Travel Risk confidence: LOW
```

### ML service unavailable

Fallback:

```text
AI prediction unavailable.
Using rule-based operational thresholds.
```

This is critical for production resilience.

---

# 8.13 Security & Reliability

### API

- HTTPS.
- JWT/session authentication.
- Role-based authorization.
- Request validation through Pydantic.
- Rate limiting.
- Structured error responses.

### Database

- Parameterized queries.
- Connection pooling.
- PostgreSQL migrations.
- Foreign-key integrity.

### Redis

- TTL for live telemetry.
- No Redis-only persistence for critical delivery outcomes.

### ML

- Model artifact checksum.
- Versioned model metadata.
- Input validation.
- Prediction confidence / data-quality indicators.

---

# 8.14 Observability

Backend metrics:

```text
api_request_latency
api_error_rate
weather_api_latency
traffic_api_latency
ml_prediction_latency
websocket_connections
active_batches
risk_escalations
accepted_batches
rejected_batches
estimated_financial_loss
```

Logs should include:

```text
request_id
batch_id
user_id
timestamp
endpoint
latency
error_code
model_version
```

---

# 8.15 Dockerized Deployment

Prototype deployment:

```text
docker-compose.yml

services:

  api:
    FastAPI

  postgres:
    PostgreSQL

  redis:
    Redis

  worker:
    ML/background jobs
```

External services remain API integrations.

---

# 8.16 SIH Demonstration Data Mode

Because live third-party APIs can fail during a judging/demo session, Mausam should provide a **Demo Simulation Mode**.

```text
LIVE MODE
DEMO MODE
```

Demo mode generates deterministic telemetry:

```text
T+00  Normal
T+20  Temperature rising
T+35  Traffic increases
T+45  ETA crosses threshold
T+50  Risk escalation
T+55  Operator action
T+70  Delivery
T+72  Outcome
```

The UI should visibly indicate simulation mode.

This ensures the complete AI → decision → outcome workflow can be demonstrated even without external API availability.

---

# 8.17 Acceptance Criteria

## Persona

- [ ] Persona selector appears on first launch.
- [ ] Seven personas are represented.
- [ ] Persona can be changed from the header.
- [ ] RMC persona opens the operational dashboard.

## RMC

- [ ] Plant/project can be selected.
- [ ] Batch can be created.
- [ ] Route can be generated.
- [ ] Weather telemetry is associated with route.
- [ ] Traffic telemetry is associated with route.
- [ ] ML risk prediction is returned.
- [ ] Three risk scores are displayed.
- [ ] Live telemetry updates without page refresh.
- [ ] Path A can be demonstrated.
- [ ] Path B can be demonstrated.
- [ ] Action panel is interactive.
- [ ] Alternative routes can be displayed.
- [ ] Delivery outcome can be recorded.
- [ ] Financial loss can be calculated.
- [ ] Outcome is persisted.
- [ ] Historical outcome appears in ML training dataset.

## Resilience

- [ ] External API failure does not crash the application.
- [ ] Redis loss does not permanently lose historical outcomes.
- [ ] WebSocket reconnect is supported.
- [ ] Demo mode can operate without external telemetry.

---

# 9. Out of Scope for Prototype

The following are intentionally excluded from the SIH prototype unless required for demonstration.

## 9.1 Advanced Concrete Chemistry Simulation

Out of scope:

- Full cement hydration chemistry simulation.
- Chemical admixture reaction simulation.
- Cement-specific rheology modeling.
- Laboratory-grade concrete quality certification.

The prototype predicts operational risk from observed data; it is not a replacement for laboratory testing or engineering standards.

---

## 9.2 Autonomous Dispatch

The prototype will **recommend** actions but will not autonomously:

- Dispatch trucks.
- Cancel batches.
- Change concrete formulations.
- Add admixtures.
- Modify plant controls.

Human approval remains mandatory.

---

## 9.3 Autonomous Vehicle/Fleet Control

Out of scope:

- Vehicle ECU integration.
- Autonomous driving.
- Automatic speed control.
- Vehicle braking/control.
- Driver monitoring.

---

## 9.4 Full ERP Integration

Not included in the prototype:

- SAP integration.
- Oracle ERP.
- Existing RMC plant ERP.
- Automated invoicing.
- Purchase orders.
- Enterprise accounting.

These can be added through an integration layer later.

---

## 9.5 National-Scale Weather Infrastructure

Mausam consumes external weather APIs.

It does not initially operate:

- Its own weather satellites.
- Radar infrastructure.
- Weather stations.
- Numerical weather prediction models.

---

## 9.6 Production-Grade ML Training at National Scale

The prototype does not attempt:

- Distributed ML training.
- Deep learning.
- GPU inference.
- Federated learning.
- Automatic model promotion without validation.

The initial ML architecture deliberately uses interpretable tabular models suitable for structured operational data.

---

## 9.7 Fully Automated Model Retraining

Historical outcomes are captured and made available to the training pipeline, but production model promotion requires validation.

Recommended lifecycle:

```text
New Data
   ↓
Training
   ↓
Evaluation
   ↓
Human Review
   ↓
Model Version
   ↓
Staging
   ↓
Production
```

---

## 9.8 Consumer Persona Depth

The six secondary personas are intentionally limited to demonstration-grade functionality.

They should establish the broader Mausam vision while keeping engineering effort concentrated on the RMC use case.

---

# Appendix A — Reference RMC Decision Algorithm

```python
def evaluate_batch(batch, telemetry, prediction):

    heat_risk = calculate_heat_risk(
        ambient_temp=telemetry.ambient_temp_c,
        concrete_temp=telemetry.concrete_temp_c
    )

    travel_risk = calculate_travel_risk(
        congestion=telemetry.traffic_index,
        eta=telemetry.eta_minutes,
        baseline_eta=batch.original_eta_minutes
    )

    delivery_risk = calculate_delivery_risk(
        predicted_slump=prediction.predicted_slump_mm,
        target_slump=batch.target_slump_mm,
        elapsed=telemetry.elapsed_minutes
    )

    if (
        telemetry.elapsed_minutes <= 78
        and prediction.slump_retention >= 0.92
        and telemetry.eta_status == "on_time"
    ):
        return {
            "decision": "APPROVED",
            "heat_risk": heat_risk,
            "travel_risk": travel_risk,
            "delivery_risk": delivery_risk
        }

    return {
        "decision": "HIGH_RISK",
        "heat_risk": heat_risk,
        "travel_risk": travel_risk,
        "delivery_risk": delivery_risk,
        "actions": [
            "ADD_RETARDER",
            "RESCHEDULE_BATCH",
            "CALCULATE_NEW_ROUTE",
            "OVERRIDE_PROCEED"
        ]
    }
```

---

# Appendix B — Recommended Repository Structure

```text
mausam/
│
├── apps/
│   └── mobile/
│       └── Flutter application
│
├── backend/
│   ├── app/
│   │   ├── api/
│   │   ├── domain/
│   │   ├── services/
│   │   ├── repositories/
│   │   ├── schemas/
│   │   ├── ml/
│   │   └── main.py
│   │
│   ├── tests/
│   ├── migrations/
│   └── Dockerfile
│
├── ml/
│   ├── datasets/
│   ├── notebooks/
│   ├── training/
│   ├── evaluation/
│   └── artifacts/
│
├── infrastructure/
│   ├── docker-compose.yml
│   └── configs/
│
├── docs/
│   └── PRD.md
│
└── README.md
```

---

# Appendix C — SIH Prototype Demo Narrative

The recommended judging demonstration should follow one batch from creation to outcome:

```text
01  Select "RMC Logistics Manager"
             ↓
02  Select Plant + Project
             ↓
03  Create 6 m³ Batch
             ↓
04  Retrieve Route + Weather + Traffic
             ↓
05  AI predicts initial low risk
             ↓
06  Truck begins transit
             ↓
07  Live telemetry starts streaming
             ↓
08  Temperature rises
             ↓
09  Traffic congestion appears
             ↓
10  ETA increases
             ↓
11  Delivery Risk crosses threshold
             ↓
12  Interactive Action Panel opens
             ↓
13  Operator requests alternative route
             ↓
14  Mausam recommends lower-risk route
             ↓
15  Truck continues
             ↓
16  Batch arrives
             ↓
17  Site slump entered
             ↓
18  Delivery accepted/rejected
             ↓
19  Financial impact calculated
             ↓
20  Outcome becomes ML feedback
```

The central product proposition is therefore:

> **Mausam converts weather and environmental intelligence into operational decisions, with RMC logistics as the flagship application where every minute of transit can become a measurable quality and financial risk.**
