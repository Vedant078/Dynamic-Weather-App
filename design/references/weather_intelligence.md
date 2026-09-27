# Multi-Panel Weather Data Dashboard Reference

## Reference Type
Weather Intelligence Dashboard

## Reference Purpose
This reference informs:
- how raw meteorological telemetry (temperature, humidity, wind, pressure, precipitation) can be organized into scannable panels
- hourly-forecast card composition
- precipitation/humidity time-series charting with dual overlaid metrics
- wind representation via compass dials

This directly informs MAUSAM's weather-telemetry layer, which feeds both the RMC risk engine and the other personas' dashboards. It is NOT a layout to copy.

## Primary Design Lessons

1. **WHAT:** A "now" summary card in the top-left shows current condition icon, temperature, a day/night high-low pair, sunrise/sunset times, and a UV index gradient slider — all in one compact, self-contained card.
   **WHY:** Consolidating "everything you need to know right now" into one card lets a user get a complete current-conditions answer without scanning the rest of the screen.
   **HOW FOR MAUSAM:** Every MAUSAM persona dashboard (RMC, agriculture, commuter) should open with an equivalent "now" card, but the fields inside it should be persona-specific — e.g., RMC's "now" card should show ambient temperature, humidity, and a heat-risk indicator instead of UV index and sunrise/sunset, which matter more to outdoor/health personas.

2. **WHAT:** An hourly forecast row uses identical repeated cards (time, temp, icon, precipitation probability) in a horizontal scroll, each card structurally identical to the others.
   **WHY:** Strict repetition of the same card structure across the row lets a user compare hours instantly by pattern-matching position, without re-reading labels each time.
   **HOW FOR MAUSAM:** An hourly transit-risk-window row for RMC could reuse this exact repeated-card structure — time, projected temperature, precipitation probability, and a small risk-tier indicator — letting a dispatcher scan the next several hours for the safest dispatch window at a glance.

3. **WHAT:** A vertical metric list (Temperature, Humidity, Wind, Dew Point, Pressure, Visibility, Precipitation) uses a consistent icon + label + right-aligned value pattern, with the currently-selected metric (Humidity) highlighted with a tinted row background that also drives the adjacent chart.
   **WHY:** Using row-selection to control which metric is charted lets one chart panel serve many metrics without needing a chart-per-metric, and the tinted-row-selected-state makes the linkage between list and chart obvious.
   **HOW FOR MAUSAM:** This selectable-metric-list-driving-a-shared-chart pattern is highly reusable for a telemetry detail panel — e.g., letting an RMC user click between "Concrete Temperature," "Slump," and "Ambient Humidity" to drive the same trend chart, rather than building a separate chart per metric.

4. **WHAT:** The main time-series chart overlays two distinct metrics (a smooth precipitation-amount line and a smoother relative-humidity line) on shared axes, plus discrete event markers (colored squares/dots for "conventional precipitation occurrence") along the baseline, with day-boundary labels beneath the x-axis.
   **WHY:** Overlaying a continuous trend with discrete event markers lets a user see both the smooth pattern and the specific moments that crossed a threshold, without two separate charts.
   **HOW FOR MAUSAM:** This exact overlay technique — a continuous risk-score line plus discrete markers for threshold-crossing events (e.g., "heat threshold exceeded," "rain onset") — is directly transferable to an RMC transit-risk chart, and day-boundary labels beneath the axis help orient a multi-day route plan.

5. **WHAT:** "Chance of precipitation" is shown as a simple ranked list of horizontal bars per hour, separate from the more complex overlay chart above it — a simpler, redundant-but-more-scannable view of similar information.
   **WHY:** Not every user needs the complex multi-metric chart; a simple bar-per-hour view serves a quick-glance need the detailed chart doesn't serve as well.
   **HOW FOR MAUSAM:** A simplified "risk by hour" bar list (redundant with the more detailed trend chart) is a good pattern for less technical personas (commuters, families) who want one quick number per hour, without the technical depth an RMC dispatcher would use.

6. **WHAT:** Wind is shown via two compass-dial widgets side-by-side labeled "Now" and "Tomorrow," each with a needle indicating direction and a speed value beneath.
   **WHY:** A compass dial communicates wind direction more intuitively than a numeric degree value, and showing "now" vs. "tomorrow" side-by-side supports simple day-over-day planning at a glance.
   **HOW FOR MAUSAM:** Wind-direction compass dials are directly reusable wherever wind matters to a persona's risk (e.g., dust/spray risk for RMC pours, or flight/travel risk for the travel persona) — keep the now-vs-next-period side-by-side comparison pattern.

7. **WHAT:** A geographic map panel sits independently in the lower-left, showing regional terrain/political boundaries rather than a route or weather overlay — it appears to serve general locational context rather than a specific telemetry layer.
   **WHY:** Even a general reference map, without a data overlay, helps a user orient the current-conditions numbers to a place before drilling into radar or route-specific views.
   **HOW FOR MAUSAM:** A small locational context map showing plant/region positioning could serve the same orienting purpose in MAUSAM's persona dashboards, but should be considered a lower priority than the risk-overlay maps in the other logistics references, since it currently carries no data layer of its own.

## Visual Language
- Overall character: clinical, data-dense, utilitarian — closer to a scientific instrument panel than a consumer weather app, despite serving what appears to be a general/consumer audience.
- Density: high — nearly every card is packed with numeric detail, minimal decorative whitespace.
- Icon style: simple flat weather icons (sun, cloud) consistent across summary and hourly cards.
- Illustration usage: none — purely numeric/iconographic and chart-based.
**For MAUSAM:** this clinical, high-density telemetry style is well-suited to the RMC persona and to a "detailed weather" drill-down view for any persona, but MAUSAM's top-level persona dashboards (especially health/family/beachgoer) likely need a lower-density, more narrative framing than this reference provides — reserve this density level for technical/operational views.

## Information Hierarchy
1. Current conditions summary (now card)
2. Near-term hourly outlook (hourly row)
3. Detailed current metrics (selectable metric list)
4. Multi-day/multi-metric trend (main chart)
5. Simplified precipitation-by-hour (redundant simple view)
6. Wind detail (now vs. tomorrow)
7. General locational map (lowest priority, no data overlay)

**MAUSAM mapping:** for RMC specifically, replace "UV index" and generic current-conditions framing with heat-risk and slump-relevant fields at the top, keep the selectable-metric-driven chart pattern for the detailed telemetry view, and treat the simplified bar-list as the version shown to less technical personas.

## Layout & Composition
- Asymmetric grid: a narrow left column (now-card stacked above a locational map) beside a wider right region split into an hourly row (full width), then a three-column row (metric list | chart | — wait, actually two columns: metric list + chart), then a two-column bottom row (precipitation bars | wind detail).
- No persistent top navigation is visible in this crop — suggests this may be an embedded widget or a single-purpose weather page rather than part of a larger multi-section app shell.

## Density Strategy
- Uniformly high density throughout — there is no clear "calm" zone in this reference, unlike the logistics dashboards which alternated dense and spacious zones.
**Relation to MAUSAM:** MAUSAM should be more deliberate than this reference about creating at least one calm, low-density zone per screen (e.g., the "now" summary or the DecisionPanel) so that dense telemetry doesn't overwhelm the moment a user actually needs to decide something.

## Typography
- Large bold numerals for the current temperature and hourly temperatures; smaller, muted labels for units and secondary text (localized labels in Polish, e.g., "Wilgotność," "Ciśnienie").
- Chart axis labels and legend text are notably small relative to the data density, which is acceptable here because the audience is treated as technically engaged.
**Guidance for MAUSAM:** keep MAUSAM's large-numeral-for-primary-metric convention consistent with the other dashboard references' KPI treatment, so temperature/humidity/slump numbers read with the same visual weight as fleet KPIs elsewhere in the product.

## Color Strategy
- Background: very light lavender/blue-tinted neutral, distinguishing it subtly from pure white/gray without adding much saturation.
- Chart uses two distinct hues (blue for one metric, purple/magenta for another) plus red/pink discrete event markers — three total hues, each meaning a specific metric or event type.
- UV index uses a full-spectrum gradient slider (green→yellow→purple) — a specialized, standardized meteorological color convention.
**Translate to MAUSAM:** reuse MAUSAM's existing chart-accent tokens for the two overlaid trend lines rather than blue/magenta, but preserve the "each hue means one specific metric everywhere" discipline, and preserve any standardized meteorological color convention (like the UV gradient) since users may already recognize it from other weather sources.

## Components Observed
- **Now-summary card** — purpose: complete current-conditions answer in one glance; MAUSAM adaptation → persona-specific "now" card (WeatherMetric cluster).
- **Repeated hourly card row** — purpose: scannable near-term outlook; MAUSAM adaptation → hourly risk-window row for RMC, or hourly comfort-index row for other personas.
- **Selectable metric list driving a shared chart** — purpose: one chart serving many metrics; MAUSAM adaptation → a telemetry detail panel where selecting "Concrete Temp," "Slump," or "Humidity" drives the same trend chart.
- **Dual-line overlay chart with discrete event markers** — purpose: continuous trend + threshold events; MAUSAM adaptation → RiskTrendChart with threshold-crossing markers.
- **Simple hour-by-hour bar list** — purpose: quick-glance redundant view; MAUSAM adaptation → simplified risk-by-hour view for non-technical personas.
- **Compass wind dial (now vs. tomorrow)** — purpose: intuitive direction + day-over-day comparison; MAUSAM adaptation → reusable WindDial component wherever wind matters to a persona's risk calculation.
- **Locational reference map (no overlay)** — purpose: general orientation; MAUSAM adaptation → low-priority; consider merging with a data-bearing map instead of duplicating an overlay-free one.

## Data Visualization
- The dual-metric overlay with discrete threshold markers is the single most valuable charting pattern here for MAUSAM's risk engine, since RMC risk is fundamentally about continuous conditions (temperature, humidity) crossing discrete thresholds (heat risk, slump-loss risk).
- The selectable-metric-list-driving-one-chart pattern reduces the number of distinct chart components MAUSAM needs to build and maintain.
- The redundant simple/detailed view pairing (bar list vs. full chart) is a good model for serving both technical (RMC) and non-technical (family, commuter) personas from the same underlying data without building two separate data pipelines.

## Map / Route / Telemetry Treatment
This reference's map carries no data overlay and is the weakest pattern in the set — it should not be used as a model for MAUSAM's route or plant maps, which need risk-zone overlays as established in the other two logistics references. If MAUSAM includes a general locational map in a persona dashboard, keep it strictly secondary and consider adding at least a basic weather-layer overlay so it isn't purely decorative.

## Interaction Patterns
- Row-click/selection on the metric list changes which metric drives the chart (Observed selected-state, Inferred click behavior).
- "Czas lokalny / Czas uniwersalny" (local time / universal time) toggle above the chart (Observed control, Inferred toggle behavior).
- "Więcej" ("More") link beside the precipitation-chance list implies expandable detail (Observed link, Inferred destination).
- Horizontal scroll on the hourly row beyond visible cards (Inferred).

## Motion & Animation
Inferred / Recommended: chart line drawing-in animation on initial load or metric switch, and a smooth transition when switching the selected metric so the chart doesn't hard-cut between datasets. Compass needles could animate to their new position on data refresh. Avoid animating the hourly card row automatically — any motion there should be user-initiated (scroll), not automatic.

## MAUSAM Adaptation
Reference: current-conditions "now" card (temp, UV, sunrise/sunset) → MAUSAM RMC: "now" card (ambient temp, humidity, heat-risk tier, wind).
Reference: hourly forecast row → MAUSAM: hourly dispatch-risk window row.
Reference: selectable metric list + shared chart → MAUSAM: telemetry detail panel (concrete temp / slump / humidity) driving one RiskTrendChart.
Reference: precipitation + humidity overlay with event markers → MAUSAM: risk-score line with threshold-crossing event markers (heat risk breach, slump-loss risk breach).
Reference: wind compass now/tomorrow → MAUSAM: WindDial for pour-day planning or travel-persona risk.

## Relevant MAUSAM Screens
- Weather Dashboard
- Risk Analysis
- Live Batch Detail (telemetry panel)
- Agriculture Dashboard
- Health Dashboard
- Travel Dashboard

## Relevant MAUSAM Components
- WeatherMetric
- TelemetryMetric
- RiskTrendChart
- Timeline (for threshold-event markers)
- WindDial (new component suggestion, directly inspired by this reference)

## What MAUSAM SHOULD ADOPT
- A complete "now" summary card as the entry point to any weather-driven screen.
- A repeated, structurally identical hourly card row for near-term scanning.
- A selectable-metric list that drives a single shared chart rather than one chart per metric.
- Overlaying a continuous trend line with discrete threshold-event markers.
- Offering both a simplified quick-glance view and a detailed technical view of the same underlying data for different personas.

## What MAUSAM SHOULD NOT COPY
- The uniformly high density with no calm zone — MAUSAM needs at least one low-density "decision" zone per screen.
- The overlay-free, data-less locational map.
- The blue/magenta chart hues — use MAUSAM's own chart-accent tokens.
- Any Polish-specific labeling or units (this is source data, not a pattern).

## Anti-Pattern Warnings
Do not port this reference's undifferentiated high density directly into an RMC or persona dashboard without adding at least one clearly calmer, decision-oriented zone (as established in the logistics dashboard references) — a screen that is dense everywhere gives an operator nowhere to rest their eyes on the one number or action that actually matters right now.

## AI Coding Instructions
- Use this reference for the weather-telemetry layer: now-card, hourly row, selectable-metric chart, threshold-marker overlay, and wind dial.
- Reuse MAUSAM's existing chart-accent and semantic tokens instead of this reference's blue/magenta/lavender palette.
- Pair this reference's dense telemetry patterns with the DecisionPanel and KPI-row patterns from the logistics references so RMC screens combine weather detail with actionable risk decisions, rather than presenting weather data in isolation.
- Do not reproduce the data-less locational map as-is; either give it a data layer or deprioritize it.

## Design Tokens / Values
**Observed:** now-card + hourly row + selectable-metric-list-with-chart + simplified bar list + dual wind dial + locational map, arranged in an asymmetric grid with no persistent top nav.
**Recommended for MAUSAM:** reuse the selectable-metric/shared-chart and threshold-marker-overlay patterns with MAUSAM's existing chart tokens; introduce a WindDial component if MAUSAM doesn't already have one.

## Confidence & Inference
- OBSERVED: now-card, hourly row, metric list with selected-state, dual-line chart with event markers, simplified bar list, wind compass pair, locational map.
- INFERRED: metric-selection interaction, local/universal time toggle behavior, "More" expansion, hourly-row scroll.
- RECOMMENDED: pair this reference's dense telemetry with a calmer decision zone; introduce a WindDial component; give the locational map a real data layer rather than reproducing it bare.

## Final Design Principle
1. One "now" card should answer the full current-conditions question before any chart is needed.
2. Let one chart serve many metrics through selection, rather than building a chart per metric.
3. Overlay continuous trends with discrete threshold events wherever risk is fundamentally about crossing a line.
4. Offer a simple view and a detailed view of the same data for different personas — don't force RMC-level density onto every audience.
