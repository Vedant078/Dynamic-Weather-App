# Mausam UI/UX Design Skill System

> Persistent UI/UX design contract for the Mausam project.  
> Use this file whenever AI generates, modifies, reviews, or refactors UI code.
>
> **North Star:** Design the decision, not the dashboard.

---

## 1. Design North Star

Mausam is **not** a generic weather app, and the RMC experience is **not** a generic SaaS dashboard.

The UI must communicate:

- Environmental intelligence
- Operational urgency
- Trustworthy decision support
- Real-time telemetry
- Indian infrastructure context
- Human-in-the-loop AI
- Precision without visual clutter

It should feel like:

> A premium weather-intelligence command system designed for people making decisions under changing environmental conditions.

Avoid:

- Generic Tailwind/admin dashboard aesthetics
- Cryptocurrency/trading-terminal styling
- Excessive glassmorphism
- Cyberpunk/neon AI visuals
- Generic weather-app illustrations
- Card-heavy layouts
- Excessive gradients, shadows, pills, or decorative animation

---

## 2. Mandatory Design Principles

### 2.1 Design Before Components

Before creating UI, identify:

1. What decision is the user making?
2. What information is required?
3. What changes in real time?
4. What is secondary?
5. What action should be available?

Use this hierarchy:

```text
Context
  ↓
Situation
  ↓
Risk / Insight
  ↓
Reason
  ↓
Action
  ↓
Confirmation / Outcome
```

### 2.2 Every Screen Needs One Job

| Screen | Primary Job |
|---|---|
| Persona Selection | Establish user context |
| RMC Dashboard | Understand fleet state immediately |
| Batch Details | Understand one delivery |
| Live Route | Understand spatial + environmental risk |
| Risk Analysis | Understand why risk changed |
| Action Panel | Make an operational decision |
| Outcome | Record what actually happened |
| Analytics | Learn from historical operations |

Do not create screens simply because conventional apps have them.

### 2.3 Avoid Card Soup

Do not place every metric inside an isolated rounded card.

Prefer hierarchy:

```text
ACTIVE DELIVERY

RMC-24081
Plant A → Project 42

          21 min
            ETA

34.8°C              13.4 km
Concrete             Remaining

────────────────────────────

DELIVERY RISK       69
████████████████░░░

Traffic delay is increasing
predicted transit exposure.

[ VIEW ROUTE ]
```

Containers must improve grouping or interaction.

---

# 3. Visual Identity

## 3.1 Dark-First Theme

Centralize all values in a design-token system.

```text
Background       #0B0F14
Primary Surface  #111820
Secondary        #161E27
Elevated         #1C2631
Border           #27323D

Primary Text     #F3F6F8
Secondary Text   #9BA8B5
Muted Text       #667481
```

Do not invent screen-specific near-black shades.

## 3.2 Semantic Colors

```text
SAFE             #35C98B
WATCH            #F2B84B
HIGH RISK        #F06464
CRITICAL         #E5484D
INFO             #5CA9FF
```

Risk colors are functional, not decorative.

**Rule:** If everything is red, nothing is urgent.

Do not color entire screens according to risk. Highlight the affected metric, route segment, or action.

---

# 4. Typography

Use one primary family consistently.

Preferred:

```text
Inter
```

Fallback:

```text
SF Pro / system sans
```

Avoid decorative display fonts.

Recommended scale:

```text
Display XL     32–36 px / 700
Display        28–32 px / 700
Heading XL     24 px / 700
Heading        20 px / 650
Section        16 px / 650
Body           14–16 px / 400–500
Label          12–13 px / 500
Micro          10–11 px / 600
```

Use tabular numerals for telemetry where appropriate.

---

# 5. Spacing & Radius

Use a 4-point spacing grid:

```text
4   micro
8   compact
12  small
16  standard
20  medium
24  section
32  major section
40  large
48  screen-level
```

Avoid arbitrary values unless a real visual constraint requires them.

Recommended radius:

```text
Controls       8px
Buttons        10px
Data surfaces  12px
Large surfaces 16px
Bottom sheets  20px
Modals         24px
```

Avoid 999px pills except for statuses and compact categories.

---

# 6. Iconography

Use one icon family consistently.

Recommended:

```text
Lucide
```

Rules:

- Consistent outlined style
- Approximately 1.5–2px visual stroke
- Icons support comprehension
- Do not replace every label with an icon
- No production emoji icons

RMC examples:

```text
Temperature → thermometer
Traffic     → traffic/navigation
ETA         → clock
Slump       → activity/gauge
Risk        → alert triangle
Route       → navigation
Batch       → layers/package
Plant       → factory
Project     → construction
```

---

# 7. Weather Visual Language

Weather should feel like **data**, not clip art.

Prefer:

- Temperature fields
- Wind vectors
- Rain intensity
- Atmospheric gradients
- Route exposure
- Time-series patterns
- Subtle environmental textures

Avoid relying on cartoon weather icons as the primary visual language.

---

# 8. RMC Product Visual Language

The RMC product revolves around:

```text
BATCH
ROUTE
TELEMETRY
RISK
DECISION
OUTCOME
```

These concepts should recur throughout the experience.

RMC screens should feel like a modern logistics control system.

---

# 9. RMC Dashboard

The dashboard must answer within roughly three seconds:

1. How many deliveries are active?
2. How many are at risk?
3. Which delivery needs attention?
4. Why is it at risk?
5. What can I do?

Preferred hierarchy:

```text
Global operational summary
        ↓
Most important active batch
        ↓
Live route / fleet context
        ↓
At-risk queue
        ↓
Recent outcomes
```

Do not prioritize decorative charts over active operational problems.

---

# 10. Risk Gauge

Every risk gauge uses:

```text
Label
Numeric value
Scale
Status
Optional trend
```

Example:

```text
DELIVERY RISK

       69

━━━━━━━━━━━━━━━━

HIGH
↑ +8 in 10 min
```

Do not use:

- 3D speedometers
- Decorative gauge graphics
- Meaningless gradients
- Continuous animation
- Excessive glow

Animate only when the risk materially changes.

---

# 11. Telemetry

Live telemetry should feel alive but controlled.

Use:

- Numeric values
- Small trends
- Sparklines
- Thin lines
- Subtle transitions

Example:

```text
CONCRETE TEMP

34.8°C     ↑ 1.4°

╱╲___╱╲____╱
```

Do not use a giant chart for a simple metric.

---

# 12. Map Rules

The map is a primary product surface.

Priority:

```text
1. Active vehicle
2. Route
3. Destination
4. Risk segments
5. Traffic
6. Weather
7. Secondary POIs
```

Do not let overlays overpower the active batch.

Route risk should be communicated through controlled semantic styling:

```text
SAFE      ━━━━━━━━━
WATCH     ━━━━━━━━━
HIGH      ━━━━━━━━━
```

Use a custom vector vehicle marker rather than emoji.

---

# 13. Route Comparison

Route comparison is a decision surface.

Every route option should expose:

```text
ETA
Distance
Traffic exposure
Heat exposure
Delivery risk
Trade-off
```

Example:

```text
ROUTE B · RECOMMENDED

66 min
30.1 km

Traffic      Low
Heat         Low
Risk         39

+5 min
−33 risk

[ SELECT ROUTE ]
```

The trade-off must be understandable without interpreting a complex chart.

---

# 14. AI UX Rules

AI is **decision support**, not decoration.

Do not use marketing language such as:

```text
✨ AI MAGIC
🤖 SMART AI
AI POWERED
```

Prefer:

```text
Predicted delivery risk
Model confidence
Primary risk factors
Recommended action
Prediction updated 20 sec ago
```

## 14.1 Explain Predictions

Whenever AI affects a decision, show the important factors.

Example:

```text
WHY RISK INCREASED

+18  ETA increased by 16 min
+14  Ambient temperature 40.2°C
+11  Batch age 63 min
+07  Congestion ahead
```

## 14.2 Confidence

Only show confidence when actually supplied by the model.

Example:

```text
Prediction confidence
High · 87%
```

If telemetry is incomplete:

```text
LOW CONFIDENCE

Traffic telemetry is incomplete.
Risk estimate may change.
```

Never fabricate confidence.

---

# 15. Decision Panel

The action panel should communicate:

```text
Problem
↓
Evidence
↓
Recommended action
↓
Alternatives
↓
Consequences
```

Example:

```text
DELIVERY RISK DETECTED

ETA has crossed the current operational
limit because of congestion.

Predicted slump retention
91%

Recommended:
Calculate lower-risk route

[ Calculate Route ]

[ Add Retarder ]
[ Reschedule ]
[ Override ]
```

The recommended action must have clear primary emphasis.

---

# 16. High-Consequence Actions

Require confirmation for:

- Override & Proceed
- Reject batch
- Cancel dispatch
- Reschedule

Confirmation must state the consequence.

Example:

```text
OVERRIDE DELIVERY RISK?

The current prediction indicates
elevated delivery risk.

ETA: 84 min
Predicted retention: 89%

Proceeding will record an operator override.

[ Cancel ]
[ Confirm Override ]
```

---

# 17. Motion

Animation communicates state; it is not decoration.

Recommended:

```text
Micro transition     150–250ms
Panel transition     250–400ms
```

Use:

- Smooth vehicle movement
- Number interpolation
- Risk gauge interpolation
- One-time risk escalation feedback

Avoid:

- Constant pulsing
- Floating cards
- Parallax
- Particle systems
- "AI scanning" animations
- Long transitions

---

# 18. Loading / Empty / Error States

Never rely on generic full-screen spinners for data-heavy screens.

Use layout-matching skeletons.

Telemetry example:

```text
ETA       -- min
Temp      --.-°C
Risk      --
```

Empty state:

```text
NO ACTIVE DELIVERIES

Create a batch to begin monitoring
weather, traffic, ETA and delivery risk.

[ Create Batch ]
```

Error state:

```text
TRAFFIC DATA TEMPORARILY UNAVAILABLE

Live traffic could not be refreshed.
Weather and route geometry remain available.

Risk confidence has been reduced.

[ Retry ]
```

Never expose raw exceptions or stack traces.

---

# 19. Real-Time Data

Indicate freshness when relevant:

```text
Updated 8 sec ago
```

or:

```text
LIVE
```

When stale:

```text
STALE · 2 min ago
```

Never present stale telemetry as live.

---

# 20. Data Density

RMC requires high information density, but it must remain structured.

Preferred:

```text
ETA
21 min
+4 min from baseline
```

Avoid repeating the same information in multiple labels.

---

# 21. Mobile Interaction

Design for one-handed use where practical.

Prefer:

- Bottom sheets
- Bottom action bars
- Large touch targets
- Swipeable detail panels

Minimum touch target:

```text
44 × 44 px
```

Prefer 48 × 48 px for important actions.

---

# 22. Responsive Design

Support:

```text
Small phone
Large phone
Tablet
Desktop/web dashboard if introduced
```

Do not simply stretch mobile UI onto desktop.

At larger widths, intentionally increase information density:

```text
Fleet | Map | Active Batch | Risk | Outcomes
```

---

# 23. Persona Visual Adaptation

The Mausam brand remains consistent while information hierarchy changes.

### Health

```text
AQI
UV
Heat
Exposure
```

### Fitness

```text
Running window
Temperature
Wind
Heat
```

### Beach

```text
Tide
Wave
Wind
Water temperature
```

### Traveler

```text
Destination
Weather
Delay
Route
```

### Family

```text
School commute
Rain
Heat
Sudden weather
```

### Agriculture

```text
Soil
Rain
Temperature
Frost
Crop conditions
```

### RMC

```text
Batch
ETA
Slump
Concrete temperature
Traffic
Risk
Action
```

---

# 24. Component System

Build reusable primitives before complete screens.

Required components:

```text
MausamAppBar
PersonaSwitcher
StatusBadge
RiskGauge
RiskScore
TelemetryMetric
TrendMetric
BatchCard
ActiveBatchCard
RouteCard
RouteComparison
MapRiskOverlay
WeatherStrip
TrafficIndicator
DecisionPanel
ActionButton
OutcomeCard
MetricSparkline
Timeline
EmptyState
ErrorState
LoadingSkeleton
BottomActionBar
ConfirmationSheet
```

Before creating a new component, search the project for an equivalent.

Never create:

```text
RiskCard
RiskCard2
NewRiskCard
ModernRiskCard
RiskCardFinal
```

---

# 25. Component API Philosophy

Components should encode semantics, not styling hacks.

Bad:

```dart
Container(
  decoration: BoxDecoration(
    color: Colors.red,
    borderRadius: BorderRadius.circular(20),
  ),
)
```

Better:

```dart
RiskScore(
  label: 'Delivery Risk',
  value: 74,
  severity: RiskSeverity.high,
)
```

The component owns its visual treatment.

---

# 26. Centralized Design Tokens

Example:

```dart
class MausamColors {
  static const background = Color(0xFF0B0F14);
  static const surface = Color(0xFF111820);
  static const surfaceElevated = Color(0xFF1C2631);

  static const textPrimary = Color(0xFFF3F6F8);
  static const textSecondary = Color(0xFF9BA8B5);
  static const textMuted = Color(0xFF667481);

  static const safe = Color(0xFF35C98B);
  static const watch = Color(0xFFF2B84B);
  static const highRisk = Color(0xFFF06464);
  static const critical = Color(0xFFE5484D);
  static const info = Color(0xFF5CA9FF);
}
```

Do not hard-code design tokens throughout the application.

---

# 27. Microcopy

Use concise operational language.

Prefer:

```text
Delivery risk increased
```

over:

```text
Our advanced AI has detected a potentially
concerning situation with your delivery.
```

Prefer:

```text
Traffic delay +16 min
```

over verbose explanations.

Prefer:

```text
Calculate lower-risk route
```

over:

```text
Let AI find the best possible route for you
```

---

# 28. Indian Context

The UI should naturally support Indian operational environments.

Use:

- INR: `₹2.41L`, `₹24,100`
- Celsius
- Kilometres
- Minutes
- IST where relevant
- Indian traffic context
- Indian construction/RMC terminology

Avoid unnecessary defaults such as:

```text
°F
miles
USD
```

---

# 29. RMC Terminology

Use these consistently:

```text
RMC
Batch
Transit Mixer
Batching Plant
Project Site
Slump
Slump Retention
Concrete Temperature
Transit Time
ETA
Admixture
Dispatch
Delivery
Rejected Batch
Accepted Batch
Root Cause
```

Do not randomly replace "batch" with package, cargo, shipment, order, etc.

---

# 30. Financial Visualization

Clearly distinguish:

```text
Actual loss
Estimated loss
Potential exposure
Avoided loss
```

Example:

```text
Potential Exposure
₹2.41L
```

or:

```text
Estimated exposure     ₹2.41L
Avoided loss             ₹86K
```

Do not make estimated financial values look like confirmed results.

---

# 31. Analytics

Analytics should answer operational questions.

Useful:

```text
Which conditions cause rejected batches?

Traffic       ███████████ 42%
Temperature   ████████    31%
Route         ████        16%
Other         ███         11%
```

Useful:

```text
Slump Loss vs Transit Time
```

Avoid vanity metrics unless they support a real decision.

---

# 32. Model Feedback UI

When prediction quality is displayed:

```text
MODEL PERFORMANCE

Predicted slump
101 mm

Actual slump
98 mm

Error
3 mm

Model
GBR v0.3
```

This establishes trust through measurable feedback.

---

# 33. Accessibility

Minimum requirements:

- Never communicate risk through color alone.
- Include explicit labels such as HIGH RISK.
- Maintain sufficient contrast.
- Support dynamic text where feasible.
- Touch targets ≥44px.
- Avoid tiny secondary text.
- Provide accessible semantics for gauges and maps.
- Do not rely solely on animation.

---

# 34. UX Safety

Mausam is a decision-support system.

Do not imply that ML predictions are absolute engineering guarantees.

Prefer:

```text
Predicted delivery risk: High
```

not:

```text
Batch will fail.
```

Prefer:

```text
Recommended action
```

not:

```text
AI says you must do this.
```

The operator remains responsible for operational decisions.

---

# 35. Demo Mode

The SIH demo should show the actual product UI using deterministic simulated telemetry.

Story:

```text
NORMAL
  ↓
RISK BUILD-UP
  ↓
HIGH RISK
  ↓
ACTION
  ↓
ROUTE CHANGE
  ↓
DELIVERY
  ↓
OUTCOME
  ↓
LEARNING
```

Use a small persistent indicator:

```text
DEMO SIMULATION
```

Do not create a fake-looking demo-only interface.

---

# 36. AI Coding Guardrails

When generating UI code:

### Never generate generic defaults

Do not automatically produce:

```text
Scaffold
AppBar
Card
GridView
Card
Card
Card
FloatingActionButton
```

without first considering information hierarchy.

### Never invent tokens

Before adding a color, font size, radius, shadow, spacing, or icon style:

1. Search existing design tokens.
2. Reuse them.
3. If a new token is genuinely required, add it centrally.

### Never duplicate components

Search before creating.

Reuse or extend existing components.

### Preserve existing visual language

When modifying a screen:

- Do not redesign unrelated areas.
- Do not change global theme.
- Do not arbitrarily replace icons.
- Do not alter global spacing.
- Do not introduce a new button style.
- Make the smallest coherent change.

---

# 37. Visual QA Gate

Before accepting a screen:

### Brand

- [ ] Does it look like Mausam?
- [ ] Could it be mistaken for a generic SaaS template?
- [ ] Is there an environmental/operational identity?

### Hierarchy

- [ ] One obvious primary metric/action?
- [ ] User understands screen quickly?
- [ ] Secondary information is subordinate?

### Consistency

- [ ] Existing components reused?
- [ ] Existing tokens reused?
- [ ] Existing typography reused?
- [ ] Existing icon family reused?
- [ ] Existing spacing respected?

### RMC

- [ ] Batch terminology correct?
- [ ] Risk semantics correct?
- [ ] ETA/slump/temperature relationships clear?
- [ ] Operational action visible where required?

### AI

- [ ] Prediction explainable?
- [ ] No unsupported certainty?
- [ ] Freshness visible where relevant?
- [ ] Confidence not fabricated?

### Interaction

- [ ] Primary action reachable?
- [ ] Destructive actions confirmed?
- [ ] Loading state?
- [ ] Error state?
- [ ] Empty state?
- [ ] Real-time state handled?

---

# 38. Screenshot Test

Ask:

> If the Mausam logo were removed, would this screenshot look like a generic AI-generated dashboard?

If yes, redesign.

Ask:

> What is the single most important thing on this screen?

If there is no obvious answer, redesign.

Ask:

> Is every visual element earning its space?

If not, remove it.

Ask:

> Does the interface communicate operational state without requiring the user to read everything?

If not, improve hierarchy.

---

# 39. Required RMC Screen Inventory

```text
01 Persona Selection
02 RMC Dashboard
03 Batch Creation
04 Batch Details
05 Live Route
06 Risk Analysis
07 High-Risk Action Panel
08 Route Comparison
09 Delivery Outcome
10 Rejection / Loss Detail
11 Fleet Analytics
12 Model Feedback / Prediction History
13 Settings / Persona Switcher
```

---

# 40. RMC Dashboard Reference

```text
┌─────────────────────────────────────────┐
│ MAUSAM          RMC Manager       🔔    │
├─────────────────────────────────────────┤
│                                         │
│ 17 ACTIVE     3 AT RISK     ₹2.41L      │
│                                         │
├─────────────────────────────────────────┤
│                                         │
│ ACTIVE DELIVERY                          │
│                                         │
│ RMC-24081                                │
│ Plant A → Project 42                     │
│                                         │
│                 21                       │
│                 min                      │
│                                         │
│ 34.8°C        13.4 km                    │
│ Concrete      Remaining                  │
│                                         │
│ DELIVERY RISK                            │
│             69                          │
│      ━━━━━━━━━━━━━━━                     │
│                                         │
│ Traffic delay +16 min                    │
│ Temperature 40.2°C                       │
│                                         │
│ [ VIEW LIVE ROUTE ]                      │
│                                         │
├─────────────────────────────────────────┤
│ OTHER AT-RISK DELIVERIES                 │
│                                         │
│ RMC-24076   ETA 11m   Risk 82           │
│ RMC-24079   ETA 29m   Risk 74           │
└─────────────────────────────────────────┘
```

Reference hierarchy, not a rigid pixel specification.

---

# 41. RMC Batch Detail Reference

```text
BATCH #RMC-24081

Plant A
      ↓
Project 42

STATUS
HIGH RISK

────────────────────

TRANSIT
54 min elapsed
21 min ETA
13.4 km remaining

────────────────────

CONCRETE
Initial Slump     115 mm
Predicted Slump   101 mm
Retention          88%

Concrete Temp      34.8°C

────────────────────

RISK

Heat              72
Travel            64
Delivery          74

────────────────────

WHY

ETA +16 min
Ambient +4.2°C
Batch age 63 min

────────────────────

ACTION

[ Calculate New Route ]
[ Add Retarder ]
[ Reschedule ]
[ Override ]
```

---

# 42. Consistency Matrix

| Element | Rule |
|---|---|
| App header | Same structure |
| Persona switcher | Same component |
| Risk scores | Same gauge language |
| Status badges | Same semantics |
| Buttons | Same hierarchy |
| Maps | Same route/risk treatment |
| Typography | Same scale |
| Spacing | Same 4pt system |
| Icons | Same family |
| Error states | Same structure |
| Bottom sheets | Same interaction language |
| AI explanations | Same visual grammar |
| Data freshness | Same indicators |

---

# 43. What Makes Mausam Non-Generic

Every major RMC screen should contain at least **two domain-specific signals** that a generic dashboard would not normally have.

Examples:

```text
Concrete temperature
Slump retention
Transit mixer
Batch age
Hydration exposure
Weather-weighted route
Delivery risk
Site slump
```

A screen containing only generic business metrics is not a Mausam screen.

---

# 44. Implementation Priority

```text
P0
Design tokens
Core navigation
Persona selection
RMC dashboard
Risk gauge
Batch detail
Map
Live telemetry
Action panel

P1
Route comparison
Outcome flow
Analytics
Secondary persona screens

P2
Advanced animations
Advanced charts
Deep personalization
Additional visual polish
```

Do not spend P2 effort while P0 components remain inconsistent.

---

# 45. Final AI Agent Instruction

When working on Mausam UI/UX, follow:

```text
1. Existing project architecture
        ↓
2. Existing Mausam design tokens
        ↓
3. Existing reusable components
        ↓
4. This skills.md
        ↓
5. PRD.md
        ↓
6. New implementation
```

If an implementation conflicts with an existing component/token:

> Reuse the existing system unless there is a documented product reason to change it.

If an equivalent component exists:

> Do not create another one.

If a screen looks like a generic AI-generated dashboard:

> Stop and redesign the information hierarchy before writing more UI code.

If AI affects a decision:

> Explain the prediction and expose relevant operational factors.

If an action affects a delivery:

> Keep the human operator in control and make the consequence explicit.

When uncertain:

> Prefer clarity, consistency, and operational usefulness over visual novelty.

---

# Definition of Done

```text
[ ] Solves a clearly identified user task.
[ ] Follows Mausam visual language.
[ ] Uses existing design tokens.
[ ] Reuses existing components.
[ ] Has responsive behavior.
[ ] Has loading/empty/error states where applicable.
[ ] Handles real-time state correctly where applicable.
[ ] Uses domain-specific terminology.
[ ] Does not imply unsupported AI certainty.
[ ] Does not look generic or template-generated.
[ ] Passes visual consistency review.
[ ] Works for the SIH demo without excessive explanation.
```

## Mausam Principle

> **Design the decision, not the dashboard.**
