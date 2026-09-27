# MAUSAM Design References — Index

This index sits below `PRD.md` and `design/skills.md` in authority. It exists to help an AI coding agent decide which reference to consult for which screen or component. None of these references should ever override `PRD.md` or `design/skills.md`, and none should be reproduced literally — see each file's "What MAUSAM SHOULD NOT COPY" and "Anti-Pattern Warnings" sections before applying anything.

| Reference | File | Primary Use | MAUSAM Screens | MAUSAM Components |
|---|---|---|---|---|
| Cashly Fintech Auth | `authentication.md` | Split-screen auth composition, single-CTA hierarchy, persona-value reinforcement panel | Authentication, Onboarding | (none of the core RMC components) |
| Greenova Landing Hero | `landing_hero.md` | Marketing-hero headline/CTA pattern, if a public landing page exists | Onboarding (marketing-only), Authentication (companion hero) | (none of the core RMC components) |
| Fleet Ops Dashboard + ML Recommendation | `rmc_operations_dashboard.md` | KPI row, trend-with-highlighted-bar, compact confirmatory map, alert feed, predictive DecisionPanel | RMC Command Center, Live Batch Detail, Risk Analysis, Decision Panel | KPIStat, RiskGauge/RiskBadge, AlertFeed, RecommendationCard/DecisionPanel, RouteMap (compact), TelemetryMetric |
| Horizon Fleet Route Tracking | `route_tracking.md` | Sidebar nav w/ badges, equal-weight chart+map, progress-bar batch rows, capacity/outcome panels | Route Intelligence, RMC Command Center, Live Batch Detail, Route Comparison | RouteMap (full-detail), BatchCard, TelemetryMetric, KPIStat, StatusPill, Timeline |
| Multi-Panel Weather Dashboard | `weather_intelligence.md` | "Now" card, hourly row, selectable-metric shared chart, threshold-event overlay, wind dial | Weather Dashboard, Risk Analysis, Live Batch Detail (telemetry panel), Agriculture/Health/Travel Dashboards | WeatherMetric, TelemetryMetric, RiskTrendChart, Timeline, WindDial (new) |

## Reference Hierarchy

Ranked by relevance to MAUSAM's primary RMC persona and overall reuse value:

1. **`rmc_operations_dashboard.md`** — highest relevance. Its predictive recommendation + action-button pattern is the closest existing analog to MAUSAM's core "risk → decision" loop.
2. **`route_tracking.md`** — high relevance. Its progress-bar batch row and equal-weight chart/map pairing are directly reusable for Route Intelligence and Live Batch Detail.
3. **`weather_intelligence.md`** — high relevance to the telemetry layer specifically. Its selectable-metric-chart and threshold-marker-overlay patterns should underpin MAUSAM's risk-trend charting across every screen that shows weather-driven risk.
4. **`authentication.md`** — moderate relevance, scoped narrowly to the auth/onboarding screens only.
5. **`landing_hero.md`** — lowest relevance. Useful only if MAUSAM has a public marketing surface separate from the product; not applicable to any operational screen.

## Which Reference Should Influence Which Screen

- **RMC Command Center:** primarily `rmc_operations_dashboard.md` (KPI row, alert feed, DecisionPanel); secondarily `route_tracking.md` for sidebar nav structure.
- **Route Intelligence / Route Comparison:** primarily `route_tracking.md` (equal-weight chart+map, progress-bar rows); secondarily `weather_intelligence.md` for overlaying weather risk onto the route trend.
- **Live Batch Detail:** `route_tracking.md` for the progress-bar/status pattern, `weather_intelligence.md` for the telemetry detail panel (selectable metric + shared chart), `rmc_operations_dashboard.md` for the DecisionPanel if the batch has an active risk recommendation.
- **Risk Analysis:** `weather_intelligence.md` for the threshold-event-overlay charting technique, `rmc_operations_dashboard.md` for how a risk is converted into a recommended action.
- **Decision Panel (component):** `rmc_operations_dashboard.md` almost exclusively — this is the reference's single most important contribution.
- **Weather Dashboard / Agriculture / Health / Travel Dashboards (secondary personas):** `weather_intelligence.md` primarily, using its simplified/detailed dual-view pattern to match each persona's technical depth.
- **Authentication / Onboarding:** `authentication.md` primarily, with `landing_hero.md` only if a pre-login marketing surface is in scope.

## Which References Overlap

- `rmc_operations_dashboard.md` and `route_tracking.md` overlap heavily on KPI-row treatment, map/status-color conventions, and general logistics-dashboard structure. Where they conflict (see below), `route_tracking.md`'s equal-weight chart/map pairing should govern Route Intelligence specifically, while `rmc_operations_dashboard.md`'s compact/subordinate map should govern the summary Command Center.
- `weather_intelligence.md` overlaps with both logistics references on charting technique (trend lines, threshold/event markers) — its selectable-metric-list pattern should be treated as the shared charting foundation both logistics screens build on when weather telemetry is involved.
- `authentication.md` and `landing_hero.md` overlap only in that both could theoretically appear on a pre-login user journey; they should not be merged into one screen without a clear reason, since one is transactional (auth) and one is purely narrative (marketing).

## Which References Should NOT Be Combined

- Do not combine `landing_hero.md`'s cinematic, photography-led, low-density marketing style with any operational screen informed by `rmc_operations_dashboard.md` or `route_tracking.md`. These are different disciplines (marketing vs. operational tooling) and mixing them will produce an inconsistent, unfocused interface.
- Do not combine `weather_intelligence.md`'s uniformly high density with `authentication.md`'s intentionally sparse, single-task layout — they serve opposite goals and should never appear on the same screen.

## Potential Design Conflicts

1. **Map dominance:** `rmc_operations_dashboard.md` treats the map as compact and subordinate; `route_tracking.md` treats it as equal-weight to the trend chart.
   **Resolution:** Use the compact treatment on the RMC Command Center (a summary/monitoring screen) and the equal-weight treatment on Route Intelligence (a screen used to actively make a routing decision). The map's prominence should scale with how directly it drives the decision being made on that specific screen.

2. **Navigation structure:** `rmc_operations_dashboard.md`'s source uses a top navigation bar; `route_tracking.md`'s source uses a persistent left sidebar.
   **Resolution:** Adopt the persistent left sidebar with attention-count badges from `route_tracking.md` as MAUSAM's single, consistent primary navigation pattern across all RMC screens, since it scales better to MAUSAM's larger number of operational sections (Command Center, Route Intelligence, Risk Analysis, Decision Panel, Delivery Outcome, ML Feedback) than a flat top bar would.

3. **Chart color conventions:** each logistics reference and the weather reference use different, unrelated hue choices (magenta accent, blue/teal accent, blue/purple overlay).
   **Resolution:** None of these palettes should be adopted directly. MAUSAM must define its own semantic chart-color tokens once (bound to outcome valence, not source-specific hues, per the caution raised in `rmc_operations_dashboard.md`) and apply them consistently across every chart, map legend, and status pill in the product.

4. **Density philosophy:** `weather_intelligence.md` is uniformly dense with no calm zone; the logistics references alternate dense and spacious zones deliberately.
   **Resolution:** Follow the logistics references' alternating-density model as MAUSAM's general layout philosophy, and treat `weather_intelligence.md`'s density only as a pattern for telemetry sub-panels embedded within an otherwise well-paced screen — never as a model for full-screen density.
