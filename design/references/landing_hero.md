# Greenova Renewable-Energy Landing Hero Reference

## Reference Type
Marketing / Landing Page Hero (Onboarding-adjacent)

## Reference Purpose
This reference informs:
- pre-app marketing/landing hero composition, if MAUSAM has a public-facing landing page
- how an environmental/climate-adjacent brand builds an emotional hook before showing functionality
- large-type editorial techniques that could inform section dividers or persona-selection screens

This is NOT a layout to copy, and it is the least operationally relevant reference in this set — MAUSAM's primary persona (RMC logistics) has no use for a marketing hero like this inside the product itself.

## Primary Design Lessons

1. **WHAT:** A full-bleed environmental photograph (wind turbines, solar panels, sky) sits behind all UI chrome.
   **WHY:** It establishes domain context (renewable energy) instantly, before any copy is read.
   **HOW FOR MAUSAM:** If MAUSAM ever needs a public landing page, a full-bleed environmental/weather visual (sky, radar imagery, route map) could establish "weather intelligence" context immediately — but this belongs only on a marketing surface, never inside the operational command-center screens.

2. **WHAT:** Headline uses a two-line, large, high-contrast statement ("Brighter Future Begins / with Clean Power") directly over the photo.
   **WHY:** Short, declarative, benefit-oriented copy reads instantly against a busy photographic background because of size and contrast, not clever framing.
   **HOW FOR MAUSAM:** Any marketing headline for MAUSAM (e.g., "Know the Risk Before You Dispatch") should follow the same two-line, high-contrast, benefit-first pattern rather than describing features.

3. **WHAT:** Primary CTA ("Explore Programs") uses a high-saturation accent fill (lime-green) against the photo; secondary CTA ("Book Session") is a translucent/glass button.
   **WHY:** The saturated accent cuts through a photographic, low-saturation background more reliably than a neutral color would.
   **HOW FOR MAUSAM:** This translucent-secondary/solid-accent-primary pairing over imagery is reusable structurally, but MAUSAM must use its own accent token, not lime-green, and should reserve saturated accent color for genuinely primary actions, not decoration.

4. **WHAT:** A giant, oversized wordmark ("Greenova") is placed at the bottom of the hero, overlapping the photo, functioning as a graphic element rather than a navigation label.
   **WHY:** Oversized typography-as-graphic-design is a modern editorial technique that adds visual weight without adding new visual elements (icons, illustrations).
   **HOW FOR MAUSAM:** This is a decorative, brand-forward technique that does not fit MAUSAM's "design the decision, not the dashboard" philosophy — flagged explicitly below as something to avoid.

5. **WHAT:** Top navigation is minimal and translucent (pill-shaped items floating over the photo) rather than a solid bar.
   **WHY:** Keeps the photographic hero uninterrupted while still providing wayfinding.
   **HOW FOR MAUSAM:** A translucent top nav could work for a MAUSAM marketing/landing surface, but MAUSAM's actual operational screens need a persistent, solid, high-legibility navigation rail (see the logistics dashboard references), not a translucent floating one.

## Visual Language
- Overall character: cinematic, editorial, photography-led — closer to a brand campaign than a software product.
- Contrast: text-over-photo contrast is managed with scale and weight rather than overlays/scrims in most areas.
- Icon/illustration usage: none beyond the photograph itself; no data visualization present.
**For MAUSAM:** this cinematic, photography-led language is appropriate only for a landing/marketing context, if one exists, and should not influence any operational screen.

## Information Hierarchy
1. Domain-establishing imagery (what industry are we in)
2. Headline (the promise)
3. Supporting sentence (the mechanism)
4. Primary + secondary CTA
5. Brand wordmark (reinforcement, not information)

**MAUSAM mapping:** if used at all, this hierarchy belongs only on a pre-login marketing page, feeding into persona selection — never inside the command center.

## Layout & Composition
- Single full-bleed hero image spans the entire viewport.
- Content is left-aligned in the upper-middle zone; nav sits above; oversized wordmark anchors the bottom edge.
- No grid of cards or panels — this is a single-message, single-screen composition.

## Density Strategy
- Extremely low density, by design — a marketing hero is meant to be scanned in seconds, not analyzed.
**Relation to RMC:** Zero applicability to RMC operational screens, which require the opposite: high, scannable information density. Only relevant to a pre-app marketing moment.

## Typography
- Two-tier system: a large serif-adjacent geometric sans for the headline and an even larger display weight for the wordmark; body copy is small and secondary.
- No numeric/metric typography present.
**Guidance for MAUSAM:** if a marketing hero is built, reuse MAUSAM's largest heading token for the promise statement; do not introduce a new oversized display type step solely for a wordmark treatment.

## Color Strategy
- Background: photographic (blues, greens, whites from sky/turbines/panels) — not a token-driven surface.
- Accent: single saturated lime-green CTA against the cool photo tones for maximum pop.
- No semantic warning/danger/success colors present (not applicable to a marketing hero).
**Translate to MAUSAM:** if MAUSAM builds a marketing hero, use MAUSAM's existing primary-action token for the CTA rather than a new lime accent; do not import this palette into the product.

## Components Observed
- **Floating pill navigation** — purpose: minimal wayfinding over imagery; MAUSAM adaptation: marketing-only, not for operational nav.
- **Photographic hero with headline overlay** — purpose: emotional/domain framing; MAUSAM adaptation: could inform a landing page hero using weather/route imagery.
- **Dual CTA (solid + glass)** — purpose: primary/secondary action pairing over imagery; MAUSAM adaptation: reusable pattern structurally, restyle with MAUSAM tokens.
- **Oversized wordmark graphic** — purpose: brand reinforcement; MAUSAM adaptation: avoid — flagged as anti-pattern below.

## Data Visualization
Not applicable — no charts, metrics, or telemetry in this reference.

## Map / Route / Telemetry Treatment
Not applicable.

## Interaction Patterns
- Play button bottom-left suggests an embedded video (Observed).
- Scrubber/progress bar beneath wordmark suggests scroll-linked or video progress (Inferred).
- Hover states on nav pills (Inferred / Recommended).

## Motion & Animation
Inferred / Recommended: subtle parallax on the background photo during scroll, and a slow crossfade if headline copy rotates. Any such motion belongs strictly on a marketing surface, not in RMC operational views, where motion should only ever communicate state change (e.g., risk level shifting).

## MAUSAM Adaptation
Reference: renewable-energy campaign hero → MAUSAM: a landing/pre-login page (if one exists) establishing "weather + logistics intelligence" using MAUSAM's own imagery (radar, route, telemetry visuals) rather than stock photography of turbines.
Reference: "Brighter Future Begins with Clean Power" → MAUSAM: an operational promise headline appropriate to whichever persona the landing page targets first.

## Relevant MAUSAM Screens
- Onboarding (marketing/pre-login only, if applicable)
- Authentication (as a possible companion hero, not the login form itself)

This reference is explicitly NOT relevant to: RMC Command Center, Live Batch Detail, Route Intelligence, Risk Analysis, Decision Panel, Delivery Outcome, ML Feedback, or any other operational screen.

## Relevant MAUSAM Components
None of MAUSAM's core operational components (RiskGauge, TelemetryMetric, BatchCard, RouteMap, AlertFeed, DecisionPanel, KPIStat) are informed by this reference.

## What MAUSAM SHOULD ADOPT
- The general principle of a short, benefit-first, two-line headline for any marketing surface.
- The pairing of one solid CTA with one lower-emphasis CTA over imagery, restyled with MAUSAM tokens.

## What MAUSAM SHOULD NOT COPY
- The oversized brand wordmark used as a graphic element.
- The lime-green accent and cool photographic palette.
- The translucent floating navigation style for anything beyond a marketing page.
- Stock nature photography as a stand-in for real weather/route visuals.
- Duplicate "Services" nav items (an evident placeholder error in the source, not a pattern to inherit).

## Anti-Pattern Warnings
Do not let this reference influence any operational MAUSAM screen. Its cinematic, low-density, single-message composition is the opposite of what an RMC command center or risk-analysis screen needs. If an AI coding agent is tempted to reuse the oversized wordmark or translucent nav pattern inside the product, that is a misapplication of this reference.

## AI Coding Instructions
- Use this reference only if MAUSAM has a public marketing/landing surface separate from the operational product.
- Do not port the color palette, oversized wordmark, or translucent nav into any dashboard screen.
- If building a landing hero, replace the stock photography concept with MAUSAM's own weather/route/telemetry imagery and use MAUSAM's existing type and color tokens.

## Design Tokens / Values
**Observed:** full-bleed photographic hero; two-line large headline; dual CTA (solid + glass); oversized bottom wordmark.
**Recommended for MAUSAM:** none — this reference should not contribute new tokens; reuse existing MAUSAM headline and button tokens if a marketing hero is ever built.

## Confidence & Inference
- OBSERVED: photographic hero, headline/CTA structure, translucent nav, oversized wordmark.
- INFERRED: video playback, scroll-linked motion, hover states.
- RECOMMENDED: restrict use of this reference to a marketing-only surface, with MAUSAM's own imagery and tokens substituted throughout.

## Final Design Principle
1. Marketing composition and operational composition are different disciplines — do not let one bleed into the other.
2. A short, benefit-first headline works because of scale and contrast, not decoration.
3. If MAUSAM has no marketing landing page in scope, this reference should be archived with low priority rather than actively applied.
