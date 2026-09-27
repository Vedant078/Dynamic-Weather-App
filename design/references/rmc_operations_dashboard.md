# Fleet Operations Dashboard with Predictive Alert Reference

## Reference Type
Logistics Command Center / RMC Operations Dashboard

## Reference Purpose
This reference informs:
- top-level KPI placement and comparison-to-baseline framing
- alert feed structure and severity/type differentiation
- the pairing of a live map with a structured shipment/telemetry summary
- how a predictive ML recommendation can be surfaced as an action-oriented card rather than a passive insight

This is the closest reference in this set to MAUSAM's primary RMC persona — but it is still inspiration, not a layout to copy.

## Primary Design Lessons

1. **WHAT:** Four KPI cards sit in a single row at the very top, each with a headline metric, a percentage-change chip, and a tiny inline bar sparkline.
   **WHY:** This lets a manager establish overall system state in under two seconds, before drilling into anything — the sparkline adds trend context without requiring a full chart.
   **HOW FOR MAUSAM:** The RMC Command Center should open with a similar KPI row — e.g., Active Batches, Batches At Risk, On-Time Delivery Rate, Avg. Slump Retention Margin — each with a vs.-yesterday or vs.-last-batch comparison chip.

2. **WHAT:** The KPI comparison chip uses color + directional arrow (green up, red down) but the meaning of "up" is metric-dependent (rising cost-per-mile is shown in green, which is actually a designed inconsistency in the source).
   **WHY / CAUTION:** This is actually a flaw worth naming: color-coding "up" as always-green regardless of whether up is good or bad is misleading.
   **HOW FOR MAUSAM:** MAUSAM must bind color semantics to outcome, not direction — a rising "batches at risk" KPI must render in the danger color even though the number went up, and a rising "on-time rate" should render in the success color. Direction and valence must be decoupled explicitly in the component logic.

3. **WHAT:** A central "Key performance indicators" panel uses a bar chart with one bar visually emphasized (hatched/highlighted) to mark the current or selected time period, plus a stacked success/fail percentage legend above the chart.
   **WHY:** Highlighting exactly one bar draws the eye to "now" inside a 12-month trend without needing a separate current-value callout.
   **HOW FOR MAUSAM:** A monthly/seasonal delivery-risk trend chart could use this same single-bar emphasis to show "this month" or "this monsoon week" against a full-year backdrop, with a delivery-success/delivery-failed (or on-time/delayed) stacked legend above it.

4. **WHAT:** "Live tracking" is a small embedded map card, not the dominant visual element, paired directly below with a single shipment's ID and status.
   **WHY:** For a fleet manager, the map is confirmatory context, not the primary decision surface — the real decision-relevant data (KPIs, alerts, recommendation) is text/numeric and given more visual priority than geography.
   **HOW FOR MAUSAM:** RMC Command Center should resist making the map the largest or most dominant element by default; keep it as a supporting panel unless the user has drilled into a specific batch's Route Intelligence screen.

5. **WHAT:** "Shipment by country" uses horizontal progress bars with a country flag icon and percentage, each bar terminating in a colored circular handle.
   **WHY:** This is a compact way to rank categorical distribution without a pie chart, and the circular handle doubles as a potential drag/interactive affordance.
   **HOW FOR MAUSAM:** A similar horizontal-bar ranking could show batch distribution by plant, by route corridor, or by risk category (e.g., "% of today's batches by risk tier") without needing a pie chart.

6. **WHAT:** "Alert feed" is a vertical list of distinct alert types (maintenance, route deviation, SLA breach), each with an icon, a one-line description, and a relative timestamp ("9 min ago").
   **WHY:** Differentiated icons per alert type let a manager triage by category at a glance, and relative timestamps communicate urgency faster than absolute clock time.
   **HOW FOR MAUSAM:** MAUSAM's alert feed should differentiate icons by risk category (heat risk, transit delay, slump-retention breach, weather escalation) and use relative timestamps, matching this pattern directly.

7. **WHAT:** A dedicated card on the right ("On time... 15% increase in delay predicted... Recommend backup driver allocation") pairs a predictive statement with a single explicit recommended action and an "Apply Recommendation" button.
   **WHY:** This is the single most valuable pattern in the reference — it converts a prediction into a decision the user can act on with one click, rather than leaving the user to interpret a number.
   **HOW FOR MAUSAM:** This is the direct template for MAUSAM's DecisionPanel: a risk statement + AI explanation + one explicit recommended action + a single confirming action button. This should be treated as a first-class, reusable pattern across RMC screens.

8. **WHAT:** The recommendation card uses a distinct pastel/soft accent background (pink) to separate it from the neutral white cards around it, and labels itself "Short-term risk detected."
   **WHY:** A differentiated surface color signals "this card needs a decision," distinguishing it from purely informational cards.
   **HOW FOR MAUSAM:** MAUSAM should reserve a dedicated risk/attention surface treatment (using its own semantic warning/danger tokens) exclusively for cards that require a decision, never using it for purely descriptive telemetry.

## Visual Language
- Overall character: clean, light, data-forward SaaS with generous internal card padding and minimal ornamentation.
- Density: medium — enough numbers to feel operational, but each card has clear breathing room.
- Surface hierarchy: flat white cards on a light-gray page background; one card (the recommendation) breaks the flatness with a tinted background to signal importance.
- Icon style: simple line/duotone icons, consistently sized, one per section header.
**For MAUSAM:** this medium-density, mostly-flat-with-one-highlighted-exception model is a good baseline — MAUSAM can push density higher for the RMC persona specifically, since operational users tolerate (and need) more data per screen than typical SaaS users.

## Information Hierarchy
1. Fleet-wide KPI snapshot (top row)
2. Trend context (KPI chart, "now" highlighted)
3. Live/geographic confirmation (map)
4. Categorical breakdown (shipment by country)
5. Event-level alerts (alert feed)
6. Predictive recommendation + action (top-right priority card)

**MAUSAM mapping:**
1. Batch-wide KPI snapshot (active batches, at-risk batches, on-time rate, avg. margin)
2. Risk trend over time (daily/weekly/seasonal)
3. Route/plant map (confirmatory, not dominant)
4. Distribution by plant/route/risk tier
5. Event-level alerts (heat, transit delay, slump breach)
6. AI risk explanation + recommended action + apply button

## Layout & Composition
- Top nav bar with primary sections (Dashboard, Fleet Management, Tracking, Analytics, Inventory, Drivers, Customers, System) plus notification/settings/profile icons.
- Below nav: a 4-column KPI row.
- Below that: an asymmetric two-column zone — a wide chart panel (left, ~65%) and a compact live-tracking panel (right, ~35%).
- Bottom row: three roughly equal panels — shipment breakdown, alert feed, and the highlighted recommendation card.

## Density Strategy
- Dense at the KPI row (four metrics compressed into one row) and the alert feed (multiple events stacked tightly).
- More spacious in the chart and map panels, where visual/spatial reasoning needs room to breathe.
- The recommendation card intentionally uses more whitespace than its neighbors, which reinforces its importance rather than undermining scannability.
**For RMC specifically:** this pattern — dense KPI/alert zones, breathing-room chart/map zones, extra-spacious "decision" cards — maps well onto an RMC operator's actual scanning behavior: check numbers fast, glance at map for confirmation, read the one decision that matters slowly.

## Typography
- KPI numbers are large, bold, and set apart from their labels, which are small and muted gray.
- Section headers are medium-weight, slightly larger than body text, with no unnecessary decoration.
- Alert and shipment rows use consistent two-line text blocks (title + description) at body size.
**Guidance for MAUSAM:** reuse MAUSAM's existing large numeric style for KPIStat headline values, and keep alert-row text at a single consistent body size so a long alert feed doesn't create competing type scales.

## Color Strategy
- Background: light neutral gray, standard SaaS baseline.
- Semantic colors are used sparingly and specifically: green for positive change chips, red for negative, orange/pink accents reserved for warnings and the one predictive card.
- Chart color (magenta/pink bar) is a single accent hue reused consistently rather than a multi-color palette.
**Translate to MAUSAM:** confirm that MAUSAM's semantic tokens (success/warning/danger) are bound to real outcome meaning (see Lesson 2's caution) and use a single consistent accent hue for the primary risk trend chart, matching MAUSAM's existing chart-accent token rather than introducing magenta.

## Components Observed
- **KPI card w/ sparkline** — purpose: at-a-glance system state; visual behavior: large number, change chip, mini bar sparkline; MAUSAM adaptation → KPIStat component, extended with a small trend sparkline slot.
- **Trend bar chart w/ highlighted bar** — purpose: show current period against full-range history; MAUSAM adaptation → RiskTrendChart with a "current period" emphasis state.
- **Compact live map card** — purpose: confirmatory geographic context; MAUSAM adaptation → RouteMap in a small/embedded mode, distinct from its full-screen Route Intelligence mode.
- **Horizontal ranked progress bars** — purpose: categorical distribution; MAUSAM adaptation → a distribution-by-category component (plant, route, risk tier).
- **Alert feed row** — purpose: event-level triage; MAUSAM adaptation → AlertFeed component with per-category icon and relative timestamp.
- **Predictive recommendation card** — purpose: convert prediction into a one-click decision; MAUSAM adaptation → DecisionPanel, MAUSAM's most important reusable component for the RMC persona.

## Data Visualization
- The bar chart's single-bar emphasis and above-chart stacked-percentage legend translate directly to MAUSAM's need to show delivery-success vs. delivery-failed rates, and could be reused for slump-retention pass/fail rates or heat-risk incident rates over a rolling window.
- The KPI sparkline pattern is well suited to transit-time and ETA-accuracy trends shown inline within a KPI card, avoiding the need for a separate chart just to show short-term trend.
- Comparison-to-baseline chips (vs. last week) map directly to "vs. last batch" or "vs. seasonal average" comparisons for concrete temperature and slump metrics.

## Map / Route / Telemetry Treatment
- Map is treated as a confirmatory, secondary element paired with a single shipment ID and a live status pill ("On time").
- Translate to MAUSAM's RMC context:
  Plant → Truck → Route → Risk Zone → Project Site
  The compact map card should show the truck's current position and one status pill (on schedule / at risk / delayed), leaving detailed route-and-risk-zone visualization for the dedicated Route Intelligence screen rather than this summary card.

## Interaction Patterns
- "See All" link on the live-tracking card implies drill-down into a full tracking view (Observed link, Inferred destination).
- Clicking an alert row likely opens shipment/vehicle detail (Inferred / Recommended).
- "Apply Recommendation" button implies a confirmable, possibly reversible, action (Observed button, Inferred confirmation flow).
- Kebab menus (⋮) on cards suggest per-card configuration or export options (Observed, Inferred behavior).

## Motion & Animation
Inferred / Recommended: KPI sparkline and chart bars could animate in on load or on data refresh to signal "this is live," and the recommendation card could use a brief, restrained entrance animation the first time a new risk is detected — never a persistent pulsing/looping animation, which would fatigue an operator monitoring the screen for hours.

## MAUSAM Adaptation
Reference: fleet KPI row (active vehicles, deliveries, on-time rate, cost per mile) → MAUSAM: RMC KPI row (active batches, at-risk batches, on-time delivery rate, avg. slump-retention margin).
Reference: "Route deviation" alert → MAUSAM: "Transit delay → slump loss risk" alert.
Reference: "15% increase in delay predicted... Recommend backup driver allocation" → MAUSAM: "X% increase in slump-loss risk predicted for Batch #___ due to heat/transit delay — Recommend expedited routing / redispatch."
Reference: shipment-by-country distribution → MAUSAM: batch distribution by plant or by risk tier.

## Relevant MAUSAM Screens
- RMC Command Center (primary influence)
- Live Batch Detail
- Risk Analysis
- Decision Panel

## Relevant MAUSAM Components
- KPIStat
- RiskGauge / RiskBadge
- AlertFeed
- RecommendationCard / DecisionPanel
- RouteMap (compact mode)
- TelemetryMetric

## What MAUSAM SHOULD ADOPT
- A top KPI row establishing system-wide state before any drill-down.
- Single-bar emphasis on trend charts to mark "now."
- A compact, confirmatory map rather than a map-dominant layout on the summary screen.
- Category-differentiated alert icons with relative timestamps.
- A distinctly-surfaced predictive recommendation card with one explicit action button — this is the single most transferable pattern in the reference.

## What MAUSAM SHOULD NOT COPY
- The exact KPI metrics (deliveries, cost per mile) — these are fleet-logistics specific, not RMC-specific.
- Binding "change chip color" to direction rather than outcome valence (see Lesson 2) — this is a flaw, not a pattern to inherit.
- The magenta/pink chart accent and pastel recommendation-card tint — restyle with MAUSAM's own semantic tokens.
- Generic SaaS iconography style if it conflicts with MAUSAM's existing icon set.

## Anti-Pattern Warnings
Do not reproduce the color-coding flaw where "up" always renders green regardless of whether the metric increasing is good or bad — for RMC, a rising "batches at risk" number must be visually alarming, not visually positive. Also avoid letting the map card grow to dominate the summary screen; that visual real estate is better spent on KPIs, alerts, and the decision panel for this persona.

## AI Coding Instructions
- Use this reference to structure the RMC Command Center's top-of-screen KPI row, trend chart, compact map, distribution panel, alert feed, and decision card.
- Reuse MAUSAM's existing semantic color tokens; explicitly bind color to outcome valence, not numeric direction.
- Implement the recommendation/decision card as a reusable DecisionPanel component appearing wherever a predicted risk has an actionable response.
- Keep the map compact and confirmatory on the summary screen; reserve full route/telemetry detail for a dedicated Route Intelligence screen.
- Do not introduce new colors; adapt this reference's structure using MAUSAM's design system.

## Design Tokens / Values
**Observed:** 4-column KPI row; 65/35 chart-to-map split; 3-column bottom row (distribution, alerts, decision card); single accent chart color; pastel highlight for the decision card.
**Recommended for MAUSAM:** reuse this structural ratio (KPI row → chart+map row → distribution/alerts/decision row) with MAUSAM's existing spacing, radius, and color tokens; no new tokens needed.

## Confidence & Inference
- OBSERVED: KPI row, chart with highlighted bar, compact map, distribution bars, alert feed, recommendation card with action button.
- INFERRED: drill-down navigation on "See All" and alert rows, kebab-menu functionality, confirmation flow on "Apply Recommendation."
- RECOMMENDED: bind KPI change-chip color to outcome valence rather than raw direction; treat the recommendation card pattern as MAUSAM's core DecisionPanel component.

## Final Design Principle
1. Lead with a KPI snapshot; let geography confirm, not dominate.
2. One highlighted data point (a bar, a card) does more work than five equally-weighted ones.
3. A prediction is only useful to an operator when it ends in one clear, clickable action.
4. Color must mean outcome, not direction — get this binding right before anything else in the system.
