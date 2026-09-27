# Horizon Fleet Route Tracking Reference

## Reference Type
Route Tracking Interface / Logistics Command Center

## Reference Purpose
This reference informs:
- persistent sidebar navigation structure for a multi-section operational tool
- how a live map can co-exist with a time-series chart at equal visual weight
- per-vehicle status list patterns (route progress, ETA, state)
- secondary operational panels (loading status, order-status summary) that sit below the primary map/chart row

This is NOT a layout to copy.

## Primary Design Lessons

1. **WHAT:** A persistent left navigation rail groups items under a "Main Menu" header (Dashboard, Fleet Management, Shipments & Deliveries, Route Planning, Analytics & Reports) with a separate "Support" section below, and shows count badges on items with pending items (e.g., Route Planning: 3).
   **WHY:** Grouping by function and surfacing count badges lets an operator immediately see where unresolved work is waiting, without opening each section.
   **HOW FOR MAUSAM:** MAUSAM's RMC navigation should group by operational stage (e.g., Command Center, Route Intelligence, Risk Analysis, Delivery Outcomes, ML Feedback) with badge counts for sections needing attention (e.g., "Risk Analysis: 3" for three at-risk batches).

2. **WHAT:** The top bar shows a date-range picker, "Last updated" timestamp, and a prominent primary action ("+ Quick shipment") in the brand accent color, separate from the page title.
   **WHY:** Separating "what time window am I viewing" and "when was this refreshed" from the page title keeps temporal context visible at all times without cluttering section headers, and a single colored primary action stands out against an otherwise neutral top bar.
   **HOW FOR MAUSAM:** A persistent "Last updated: [time]" indicator is especially important for MAUSAM, where telemetry freshness (weather, traffic, concrete state) is itself a trust signal; pair it with a single accent-colored primary action such as "+ New Batch" or "Log Delivery."

3. **WHAT:** Two dual-line/area charts sit side-by-side at equal width: a "Delivered vs. Delayed" time-series with a hover tooltip showing exact values at a point in time, and a live map with a similarly-weighted visual footprint.
   **WHY:** Placing the map and the chart at equal visual weight (rather than one dominating) tells the operator that trend and geography are equally important decision inputs, not one confirming the other.
   **HOW FOR MAUSAM:** For the RMC Route Intelligence screen specifically (as opposed to the summary Command Center), a transit-time/delay trend chart and the live route map deserve equal visual weight, since both are actively used to make a redispatch decision, not just to confirm status.

4. **WHAT:** The hover tooltip on the chart surfaces exact values ("Today • 14:00 PM — Delivered 340 / Delayed 55") anchored to a specific point, with a small marker dot and connecting guide line back to the axis.
   **WHY:** This lets an operator get a precise reading without permanently cluttering the chart with all labels.
   **HOW FOR MAUSAM:** Any MAUSAM trend chart (slump retention over transit time, temperature over route) should support this hover-to-reveal-exact-value pattern rather than showing all data labels at once.

5. **WHAT:** Map markers are differentiated by both shape/icon (hub buildings vs. truck direction arrows) and by color-coded status dots at the bottom legend (in transit, pick-up, stationary, delayed), and truck labels persist on-map rather than requiring a click.
   **WHY:** Always-visible labels plus a color legend let an operator scan the whole map's state in one glance instead of clicking every marker.
   **HOW FOR MAUSAM:** Plant, truck, and project-site markers should be visually distinct by icon shape, and truck markers should carry a persistent status color (on schedule, at risk, delayed, heat-risk) rather than requiring interaction to reveal state.

6. **WHAT:** The "Active fleet" list shows each vehicle as a row with a route progress bar (origin → destination, with a truck icon marking current position along the bar) plus an ETA and a status pill.
   **WHY:** A progress bar with a positioned icon communicates "how far along" more intuitively than a percentage number alone, especially for a physical, linear journey like a delivery route.
   **HOW FOR MAUSAM:** This is highly transferable — an RMC batch-in-transit row could show a plant→site progress bar with a truck icon at current position, ETA, and a status pill (on schedule / at risk / delayed), directly reusable in Live Batch Detail or a batch list view.

7. **WHAT:** "Current loading status" and "Order status" panels use small inline bar-chart clusters and a large center-labeled donut chart respectively, each paired with 2–3 supporting numeric callouts (e.g., "18.2 m³ Total volume today").
   **WHY:** These secondary panels give operational context (capacity, volume, distribution of order states) without requiring their own dedicated page.
   **HOW FOR MAUSAM:** A similar donut could show today's batch distribution by outcome (delivered on-spec, delivered with deviation, rejected, in-transit), and small inline bar clusters could show plant loading/mixing capacity utilization.

## Visual Language
- Overall character: calm, professional SaaS with a green/teal brand accent used sparingly against a mostly white/light-gray surface.
- Density: medium-high — more panels per screen than the previous reference, but each panel keeps clear internal padding.
- Surface hierarchy: flat white cards with thin borders (not shadows) separating panels; sidebar and top bar are the only persistently colored elements (sidebar promo card uses a green gradient).
- Icon style: simple line icons, consistent stroke weight, one per nav item and per panel header.
**For MAUSAM:** the thin-border-over-shadow surface treatment and sparing accent usage suit an operational tool meant to be viewed for long stretches — apply the same restraint using MAUSAM's own accent color, reserving it for primary actions and key status indicators only.

## Information Hierarchy
1. Operations overview (top KPI row: shipments, active trucks, avg delivery time, on-time rate)
2. Trend context (delivery performance chart)
3. Geographic context (live map, equal weight to chart)
4. Per-vehicle status list (active fleet)
5. Capacity/loading detail
6. Aggregate order-state summary

**MAUSAM mapping:**
1. Batch operations overview (batches today, active trucks, avg transit time, on-time rate)
2. Transit/risk trend chart
3. Route map (plant → truck → site), equal weight for the Route Intelligence screen
4. Per-batch progress list (plant → site bar, ETA, status)
5. Plant loading/mixing capacity
6. Aggregate delivery-outcome summary (on-spec, deviation, rejected)

## Layout & Composition
- Fixed left sidebar (nav + promo card at bottom) spanning full height.
- Top bar with search, date range, notification/settings icons, avatar, and primary CTA.
- Main content: top KPI row (4 metrics), then a two-column row (chart | map) at roughly equal width, then a three-column row (active fleet | loading status | order status).

## Density Strategy
- KPI row and active-fleet list are the densest zones — many discrete facts per row.
- Chart and map row is visually calmer despite occupying the most screen space, since each conveys one continuous story rather than discrete facts.
- Bottom row balances a text-heavy list (active fleet) against two more visual, chart-based summaries (loading, order status).
**For RMC:** this three-tier density gradient (dense KPIs → calmer map/chart → mixed dense/visual bottom row) matches how an RMC dispatcher actually works: scan numbers, check the map/trend for context, then review individual batch rows before acting.

## Typography
- KPI values use a large, bold numeral with a small muted label beneath and a colored percentage-change chip beside it.
- Section headers are consistent weight/size across all panels, with a kebab menu or link (e.g., "Search for fleet") aligned to the right of each header.
- List rows (active fleet) use a two-line pattern: bold route code + ETA on one line, origin/destination labels on the next.
**Guidance for MAUSAM:** reuse this two-line list-row pattern for batch rows (Batch ID + ETA, then Plant → Site labels), and keep the KPI numeral/label/chip structure consistent with the previous reference's KPI treatment so MAUSAM's own KPIStat component behaves identically across screens.

## Color Strategy
- Background: white/very light gray; sidebar and CTA button carry the only saturated brand green.
- Status colors are used consistently across the chart legend, map legend, and status pills: a consistent color always means the same state everywhere on screen (in transit, delayed, stationary, pick-up).
- Chart uses two hues only (delivered vs. delayed) — restrained, not multi-color.
**Translate to MAUSAM:** this is an important lesson — commit to one color meaning one state (e.g., amber = at-risk) and enforce that mapping identically across every chart, map, and pill in MAUSAM, using MAUSAM's existing semantic tokens rather than this reference's green/teal palette.

## Components Observed
- **Sidebar nav with count badges** — purpose: persistent wayfinding + unresolved-work indicator; MAUSAM adaptation → primary nav rail with badges for at-risk batch counts.
- **KPI row w/ change chip** — purpose: system snapshot; MAUSAM adaptation → KPIStat, consistent with the other dashboard reference.
- **Dual-line trend chart w/ hover tooltip** — purpose: precise trend inspection; MAUSAM adaptation → RiskTrendChart / TransitTimeChart with hover-to-reveal values.
- **Live map w/ status-coded markers and legend** — purpose: geographic fleet state; MAUSAM adaptation → RouteMap, full-detail mode for Route Intelligence.
- **Progress-bar fleet row** — purpose: linear journey completion; MAUSAM adaptation → BatchCard / route-progress row, highly reusable.
- **Loading status mini-bars** — purpose: capacity visualization; MAUSAM adaptation → plant capacity/utilization widget.
- **Order status donut** — purpose: aggregate state distribution; MAUSAM adaptation → delivery-outcome distribution donut.

## Data Visualization
- The dual-line chart with hover tooltips is directly reusable for transit-time or slump-retention-margin trends.
- The status-color legend beneath the map (in transit / pick-up / stationary / delayed) should be mirrored in MAUSAM using its own semantic states (on schedule / loading / at risk / delayed).
- The donut with a large centered total ("1,284 Total shipments") is a good pattern for an "Active Batches" summary with segments for on-the-way, delivered, delayed, canceled.

## Map / Route / Telemetry Treatment
- Map shows hub markers (DC Hub, NY Hub, MIA Hub) and multiple truck markers with directional arrows and status-colored circles, all labeled persistently.
- Translate to MAUSAM's RMC context:
  Plant (hub-equivalent) → Truck (directional, status-colored) → Route → Risk Zone (a state not present in this reference, to be added) → Project Site (destination-equivalent).
  MAUSAM should add a risk-zone overlay (e.g., a shaded corridor segment where heat or weather risk is elevated) that this reference does not show — this is a genuine RMC-specific extension, not something to copy from the source.

## Interaction Patterns
- Chart hover reveals a tooltip with exact values (Observed).
- "Search for fleet" input on the map panel implies filtering markers by vehicle ID (Inferred).
- Active-fleet row click likely opens a vehicle/shipment detail view (Inferred / Recommended).
- Sidebar item expand/collapse (chevron on Fleet Management, Shipments & Deliveries) suggests nested sub-navigation (Observed icon, Inferred behavior).
- Dark mode toggle at bottom of sidebar (Observed control, behavior inferred).

## Motion & Animation
Inferred / Recommended: truck markers could animate smoothly along their route path as position updates arrive (rather than snapping), and the progress bar in each fleet row could animate its fill on data refresh. Chart tooltip should appear/disappear with a fast, non-distracting transition. Avoid animating KPI numbers on every refresh, which would be distracting in a screen meant for continuous monitoring.

## MAUSAM Adaptation
Reference: "Active fleet" progress bar row → MAUSAM: batch-in-transit row with Plant → Site progress bar, truck-position icon, ETA, and risk-aware status pill.
Reference: hub markers (DC Hub, NY Hub, MIA Hub) → MAUSAM: plant markers.
Reference: delivered vs. delayed chart → MAUSAM: on-spec vs. at-risk (or on-time vs. delayed) trend chart.
Reference: "Order status" donut → MAUSAM: batch-outcome distribution donut (on-the-way, delivered on-spec, delivered with deviation, rejected).
Reference: loading status mini-bars → MAUSAM: plant mixing/loading capacity widget.

## Relevant MAUSAM Screens
- Route Intelligence (primary influence)
- RMC Command Center (secondary — KPI row and sidebar nav pattern)
- Live Batch Detail
- Route Comparison

## Relevant MAUSAM Components
- RouteMap (full-detail mode)
- BatchCard (progress-bar row)
- TelemetryMetric
- KPIStat
- StatusPill
- Timeline (for the progress-bar-as-timeline concept)

## What MAUSAM SHOULD ADOPT
- Persistent sidebar navigation with attention-count badges.
- Equal visual weight between the primary trend chart and the live map on a route-focused screen.
- Hover-to-reveal exact chart values rather than always-on labels.
- Progress-bar fleet/batch rows with a positioned "current location" icon.
- Consistent, single-meaning status-color legend reused identically across chart, map, and list.

## What MAUSAM SHOULD NOT COPY
- The green/teal brand palette and sidebar promo card styling.
- Generic logistics KPI set (shipments, trucks, cost) without RMC-specific reinterpretation.
- Exact panel proportions or card counts — adapt to MAUSAM's own grid and content needs.

## Anti-Pattern Warnings
Do not let the map and chart compete for dominance without a clear reason — on this screen they are equally weighted because both are genuinely decision-relevant; on MAUSAM's summary Command Center (see the other dashboard reference), the map should instead be subordinate. Choosing the right weighting per screen matters more than copying either pattern uniformly. Also avoid introducing a status color that isn't used identically everywhere it appears — inconsistent status-color mapping across map, chart, and pills will erode operator trust quickly.

## AI Coding Instructions
- Use this reference specifically for the Route Intelligence screen's chart/map pairing and the batch progress-row pattern.
- Reuse MAUSAM's sidebar nav structure and extend it with attention-count badges for at-risk batches.
- Add a risk-zone overlay to the route map that does not exist in this reference — this is a required RMC-specific extension.
- Enforce one consistent status-color mapping across every chart, map legend, and pill on this screen and reuse MAUSAM's existing semantic tokens throughout.
- Do not introduce the source's green/teal palette.

## Design Tokens / Values
**Observed:** fixed sidebar width with grouped nav sections and badges; equal-width two-column chart/map row; three-column bottom row; progress-bar list rows with icon-at-position; donut with centered total.
**Recommended for MAUSAM:** reuse this structural layout with MAUSAM's existing spacing, color, and typography tokens; extend the map legend with a risk-zone state not present in the source.

## Confidence & Inference
- OBSERVED: sidebar structure with badges, KPI row, dual chart/map layout, hover tooltip, progress-bar fleet rows, loading/order-status panels.
- INFERRED: fleet search filtering behavior, row-click drill-down, nested sidebar sub-navigation, dark-mode toggle behavior.
- RECOMMENDED: add a risk-zone map overlay (RMC-specific, not present in source); bind status colors identically across all visual elements.

## Final Design Principle
1. Give the map equal weight to the trend chart only when both are genuinely needed to make the same decision.
2. A progress bar with a positioned icon communicates journey state better than a percentage alone.
3. One status color must mean the same thing everywhere it appears on screen — chart, map, and list included.
4. Persistent navigation with attention badges turns a static menu into an at-a-glance work queue.
