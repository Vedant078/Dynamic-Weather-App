# MAUSAM (मौसम)
### Multi-Persona Weather Intelligence & RMC Logistics Risk Engine

MAUSAM is an environmental decision-support system designed to prevent batch rejection, quality degradation, and financial loss in Indian infrastructure logistics (focused 80% on **Ready-Mix Concrete / RMC** transit), paired with reusable microclimate intelligence across **7 distinct personas**.

---

## 🏗️ Core Architecture

```
                  ┌──────────────────────────────────────────────┐
                  │          MAUSAM Flutter Application          │
                  │   Mobile-First Native UI (360px - 430px)     │
                  └──────┬────────────────────────────────┬──────┘
                         │ REST / WebSocket               │
                         ▼                                ▼
       ┌──────────────────────────────────┐     ┌───────────────────────┐
       │     FastAPI Decision Engine      │     │ Deterministic Demo    │
       │   (Python 3.13 / Async REST)     │     │ Simulation Engine     │
       └─────────────────┬────────────────┘     └───────────────────────┘
                         │
        ┌────────────────┴────────────────┐
        ▼                                 ▼
┌───────────────────────────────┐ ┌───────────────────────────────────────┐
│ Scikit-Learn Machine Learning │ │ Closed-Loop Retraining Architecture   │
│ • Gradient Boosting Regressor │ │ • Site delivery slump verification    │
│ • Random Forest Regressor     │ │ • Avoided loss logging (₹1.68L)       │
│ • Multi-factor Decomposition  │ │ • Retraining dataset ingestion pipeline│
└───────────────────────────────┘ └───────────────────────────────────────┘
```

---

## 🎯 7 Supported Personas

1. **RMC Logistics Manager (Primary Flagship Slice)**
   - Slump retention prediction, safe transit window (≤ 78 min, ≥ 92% slump retention), concrete hydration telemetry, alternative route recommendations.
2. **Health-Conscious Users**
   - Hyperlocal AQI, PM2.5/PM10 concentration, UV index, and heat stress exposure windows.
3. **Outdoor Fitness Enthusiasts**
   - Optimal running/cycling hours, wet-bulb globe temperature, wind shear, and sudden rain advisories.
4. **Beachgoers & Surfers**
   - Tide high/low schedules, swell heights, water temperature, and offshore safety warnings.
5. **Travelers & Commuters**
   - Highway corridor microclimates, monsoon waterlogging alerts, fog visibility drops, and airport flight impacts.
6. **Parents & Families**
   - School commute risk scores, sudden thunderstorm warnings, and afternoon heat peak tracking.
7. **Agriculture & Gardeners**
   - Root-zone soil moisture %, unseasonal frost probabilities, dew points, and irrigation advisories.

---

## ⚡ The Golden Demo Journey (Batch RMC-204)

- **Origin**: Ahmedabad Plant 01 (Naroda)
- **Destination**: Project Site 07 (Gift City Expansion)
- **Initial Nominal State (Step 0)**:
  - Elapsed: 22 min | ETA: 32 min (Total: 54 min ≤ 78 min safe window)
  - Concrete Temp: 32.4°C | Slump: 106 mm (96.4% retention ≥ 92%)
  - **Status: APPROVED / SAFE**
- **Traffic Congestion (Step 1)**:
  - SP Ring Road delay (+7 min) | Concrete temp rose to 33.6°C
  - **Status: WATCH**
- **Adverse Weather & Heat Surge (Step 2)**:
  - Projected transit: 82 min (> 78 min limit)
  - Ambient: 40.2°C | Concrete: 34.8°C | Rain cloud approaching route
  - Predicted slump retention drops to 89.1% (< 92% threshold)
  - **Status: HIGH DELIVERY RISK**
  - **AI Recommendation**: `CALCULATE_NEW_ROUTE` (Expressway Route B saves 9 minutes)
- **Human-in-the-Loop Action (Step 3)**:
  - Operator applies Route B (Airport Bypass Expressway)
  - Transit normalized to 66 min | Slump retention stabilized at 92.7%
  - **Status: Restored to SAFE**
- **Verified Site Delivery & ML Retrain Loop (Step 4)**:
  - Truck arrives at Project Site 07
  - Verified site slump: 101.5 mm (Target: 105 mm)
  - **Avoided Financial Loss: ₹1.68 Lakhs recorded**
  - Outcome logged into retraining pipeline for continuous model improvement

---

## 🚀 Running the Project

### 1. Backend (FastAPI + Scikit-Learn)
```bash
cd backend
python3 -m uvicorn app.main:app --port 8000
```
- API Docs: `http://localhost:8000/docs`
- Health check: `http://localhost:8000/health`
- Batch telemetry: `http://localhost:8000/api/v1/rmc/batches`
- Simulation state: `http://localhost:8000/api/v1/rmc/simulation/state`

### 2. Frontend (Flutter Mobile / Desktop / Web)
```bash
cd frontend
flutter test                  # Run full automated test suite (13 tests)
flutter run -d chrome         # Launch in Chrome
flutter run -d macos          # Launch native desktop app
```

---

## 🧪 Testing & Verification

- **Backend Pytest**:
  - `tests/test_risk_logic.py` (Approved safe path, High-risk breach on delay & heat, 5-step deterministic simulation)
  - Result: **All 4 tests PASSED**
- **Flutter Widget & Unit Tests**:
  - `test/responsive_widths_test.dart` (360px, 375px, 390px, 412px, 430px viewports rendered with **0 overflow**)
  - `test/rmc_golden_workflow_test.dart` (Deterministic scenario, transit thresholds, reroute action, avoided loss)
  - `test/persona_switching_test.dart` (All 7 personas verified)
  - Result: **All 13 tests PASSED**
