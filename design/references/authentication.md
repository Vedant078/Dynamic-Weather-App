# Cashly Fintech Auth Reference

## Reference Type
Authentication / Onboarding

## Reference Purpose
This reference informs:
- split-screen authentication composition (form + brand/value panel)
- how a consumer-grade product communicates trust and category identity before the user enters the app
- how a value proposition can be reinforced at the exact moment of login, not just at first install

This is NOT a layout to copy.

## Primary Design Lessons

1. **WHAT:** The screen splits into a functional zone (form) and a narrative zone (dark showcase panel with carousel).
   **WHY:** It lets the product explain "what you get" without interrupting the transactional flow of logging in — the two jobs (convince, and authenticate) are separated spatially instead of competing for the same copy.
   **HOW FOR MAUSAM:** MAUSAM's login/onboarding can reserve one region for account creation and a second, visually distinct region that rotates through persona value props (e.g., "See slump-retention risk before it happens," "Get monsoon alerts for your farm plot") rather than a single generic tagline.

2. **WHAT:** The form panel uses a light, low-saturation gradient background while the showcase panel is near-black.
   **WHY:** Contrast between the two panels visually separates "your task" (light, neutral, low-cognitive-load) from "the story" (dark, high-contrast, emotionally weighted), without either competing with input legibility.
   **HOW FOR MAUSAM:** Keep the authentication form on a neutral/light surface using MAUSAM's existing background token, and reserve any high-contrast/dark surface for the marketing or persona-selection side, never mixing the two in the same region.

3. **WHAT:** Inputs are large, full-width, rounded, and white against a tinted background — a single visual weight for both fields.
   **WHY:** Removing visual noise from inputs (no heavy borders, no labels floating awkwardly) reduces friction on a screen whose only goal is task completion.
   **HOW FOR MAUSAM:** Apply the same principle to MAUSAM's login/persona-selection inputs, but keep the corner radius and elevation consistent with MAUSAM's existing token set rather than reproducing this exact rounding.

4. **WHAT:** Primary action ("Sign in") is rendered as a solid black full-width bar; secondary action ("Log in with Google") is outlined/lighter.
   **WHY:** A single unmistakable primary action prevents decision paralysis; the visual weight hierarchy (solid > outline) tells the user which path is default.
   **HOW FOR MAUSAM:** For RMC users logging into a command-center tool, the primary action should carry the same unambiguous visual dominance — but MAUSAM should use its semantic primary-action color, not black, since MAUSAM is an operational tool, not a fintech brand.

5. **WHAT:** The showcase panel pairs a bold headline ("Track your all transactions") with a single supporting sentence and a decorative hero graphic.
   **WHY:** One idea per panel, reinforced by one visual — this keeps the marketing message scannable in the 1–2 seconds a returning user glances at it.
   **HOW FOR MAUSAM:** MAUSAM's equivalent panel (for RMC managers, or persona-specific onboarding) should carry one operational promise per rotation frame ("Predict slump loss before dispatch") rather than a paragraph of feature copy.

6. **WHAT:** A pagination/carousel indicator (three dots) implies multiple rotating messages behind the same visual frame.
   **WHY:** This signals there is more context without forcing it all on screen at once, and gives returning users a reason to glance again.
   **HOW FOR MAUSAM:** If MAUSAM supports multiple personas, this pattern could rotate through 2–3 persona-specific value statements (RMC, agriculture, commuter) on the auth screen, letting the product hint at its breadth without cluttering the login task.

## Visual Language
- Overall character: consumer-friendly fintech softness (rounded corners, soft gradients) paired with a bold, high-contrast dark panel for brand storytelling.
- Density: low — one task, generous whitespace around each field.
- Elevation: minimal; flat surfaces distinguished mainly by background tone, not shadow.
- Icon/illustration usage: a single decorative hero graphic (illustrative, playful) carries emotional tone rather than literal information.
**For MAUSAM:** operational tools should keep the low-density, single-task layout for the auth step itself, but MAUSAM's supporting panel should feel like environmental/operational intelligence (data-driven, telemetry-adjacent) rather than playful fintech illustration — translate "playful hero graphic" into "a live-feeling weather/route visual" using MAUSAM's own design tokens.

## Information Hierarchy
1. Task identity ("Welcome Back!")
2. Task instruction ("Enter your credentials")
3. Required inputs
4. Primary action
5. Secondary/alternate auth path
6. Account-switch link (sign up)
7. Brand/value reinforcement (secondary panel, non-blocking)

**MAUSAM mapping:** Persona/role framing should sit above the credential fields (e.g., "Welcome back, Plant Manager" once persona is known), with the operational value panel positioned as reinforcement, never ahead of the credential task.

## Layout & Composition
- Two-column split: ~45% functional form column, ~55% narrative showcase column, both inset within a single outer card on a colored page background.
- Form column: logo top-left, headline, subtext, stacked inputs, primary CTA, divider ("or continue"), secondary CTA, footer link.
- Showcase column: full-bleed dark panel with logo repeated at top, centered hero graphic, headline + body text near the bottom, pagination dots.

## Density Strategy
- Extremely low density on the form side — this is intentional and correct for a one-task screen.
- Showcase side is also low density (one message at a time) despite being visually rich.
**For MAUSAM:** Auth/onboarding is the one place in MAUSAM that should stay this sparse — resist the instinct to preview dashboard density here.

## Typography
- Large, bold sans-serif headline dominates each panel; body copy is small and restrained by comparison.
- Numeric/data typography is absent here (not a data screen).
**Guidance for MAUSAM:** Reuse MAUSAM's existing heading scale for the welcome headline; keep supporting copy in the smallest body size in the type scale so it doesn't compete with the login task.

## Color Strategy
- Background: soft mint-to-teal gradient (brand-colored, not neutral gray) — establishes brand tone even on a utility screen.
- Primary action: near-black, functioning as a neutral "confident" action color rather than the brand hue.
- Accent: a single warm gold/brown used only inside the decorative hero graphic, not in UI chrome.
**Translate to MAUSAM:** Use MAUSAM's existing background/surface tokens for the page background (do not introduce a new gradient), and use MAUSAM's existing primary-action token for the CTA. Do not borrow the mint/gold palette.

## Components Observed
- **Auth form card** — purpose: collect credentials; visual behavior: white/light stacked inputs with password visibility toggle; MAUSAM adaptation: reuse existing MAUSAM input component, add persona context above the field stack.
- **Primary CTA bar** — purpose: single unambiguous next step; visual behavior: full-width, high-contrast fill; MAUSAM adaptation: map to MAUSAM's primary button token.
- **OAuth secondary button** — purpose: alternate auth path; visual behavior: outlined, lower visual weight; MAUSAM adaptation: reuse for SSO/OTP paths if applicable.
- **Showcase/value panel** — purpose: reinforce product value at a non-critical moment; visual behavior: dark, full-bleed, rotating message; MAUSAM adaptation: repurpose as a persona-value carousel.
- **Carousel pagination dots** — purpose: indicate rotating content; MAUSAM adaptation: reuse for persona rotation indicator only, not for operational data.

## Data Visualization
Not applicable — this reference contains no charts or telemetry.

## Map / Route / Telemetry Treatment
Not applicable.

## Interaction Patterns
- Password visibility toggle (Observed).
- "Forget password?" and "Sign Up" as low-emphasis text links (Observed).
- Carousel auto-rotation or swipe (Inferred / Recommended).

## Motion & Animation
Inferred / Recommended: gentle auto-advancing crossfade for the showcase panel's rotating message, timed slowly (5–8s) so it never feels like an alert. No motion should be applied to the credential form itself.

## MAUSAM Adaptation
Reference: fintech value showcase panel → MAUSAM: persona value/promise panel (RMC risk prevention, farmer monsoon alerts, commuter transit safety).
Reference: single dark brand panel → MAUSAM: panel using MAUSAM's operational-intelligence surface treatment, not literal fintech darkness copied verbatim.
Reference: "Track your all transactions" → MAUSAM: persona-specific single-sentence promises rotated per session.

## Relevant MAUSAM Screens
- Authentication
- Onboarding
- Persona Selection (if it precedes login)

## Relevant MAUSAM Components
- KPIStat (not directly, but the "single confident message" principle applies to any hero stat shown pre-login)
- StatusPill (for carousel indicator equivalent)

## What MAUSAM SHOULD ADOPT
- Split functional/narrative composition for auth screens.
- One primary CTA with unambiguous visual dominance.
- Low information density on the credential-entry surface.
- Rotating, single-message value reinforcement rather than a paragraph of marketing copy.

## What MAUSAM SHOULD NOT COPY
- The mint/teal gradient background and gold accent color.
- The playful money/wings illustration style.
- The "Cashly" branding, wordmark, or copy.
- The exact 45/55 column proportions or rounding values — adapt to MAUSAM's grid.

## Anti-Pattern Warnings
Do not let the showcase/value panel drift into decorative illustration for MAUSAM — RMC and other operational personas need this panel to feel credible and data-grounded, not playful, or it will undercut trust in the product's operational seriousness.

## AI Coding Instructions
- Use this reference only for the two-column auth composition and CTA hierarchy.
- Reuse MAUSAM's existing color tokens, input components, and button components — do not introduce mint/gold hues.
- Keep the credential-entry region visually calm and low-density regardless of how rich the value panel becomes.
- If building a persona carousel, cap it at one message per frame and rotate slowly.

## Design Tokens / Values
**Observed:** two-panel split layout; full-width stacked inputs; solid dark primary CTA; outlined secondary CTA; 3-dot pagination.
**Recommended for MAUSAM:** apply this structural pattern using MAUSAM's existing surface, primary-action, and typography tokens; no new tokens required.

## Confidence & Inference
- OBSERVED: two-column split, input styling, CTA hierarchy, carousel dots, color palette.
- INFERRED: carousel auto-rotation, swipe interaction.
- RECOMMENDED: persona-value rotation panel, reuse of MAUSAM's existing tokens instead of this reference's palette.

## Final Design Principle
1. Separate the transactional task (login) from the narrative task (value reinforcement) spatially, not sequentially.
2. One CTA, one visual weight tier above everything else on the screen.
3. Let the "showcase" region breathe with a single message at a time.
4. Never let brand personality override MAUSAM's operational-trust tone, even on a low-stakes screen like login.
