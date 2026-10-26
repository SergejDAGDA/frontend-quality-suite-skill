---
name: frontend-production-qa
description: Orchestrates production-grade frontend implementation and verification across engineering, real-browser testing, responsive checks, visual QA, regression closure, and conditional review gates. Use for browser-facing UI work. Do not use for backend-only or non-UI tasks unless rendered browser behavior changes.
---

# Frontend Production QA

## Role

This skill is an orchestrator.

It coordinates specialist skills and defines the evidence required before a browser-facing task may be considered complete.

It does not replace the specialist skills themselves.

## Authority

Project-local `AGENTS.md`, architecture, legal constraints, accessibility requirements, design decisions, product rules and project-memory policy remain authoritative.

Do not migrate frameworks, replace build systems, redesign the product, or introduce competing project-memory/design documents unless explicitly requested.

## Required runtime stack

Expected capabilities:

- `frontend-ui-engineering`
- `browser-testing-with-devtools`
- `frontend-visual-qa`
- `frontend-accessibility-qa`
- Chrome DevTools MCP

`frontend-visual-qa` and `frontend-accessibility-qa` are bundled with this plugin. Use the bundled copies as the version-consistent visual and accessibility QA layers; do not substitute separately installed upstream copies without reviewing the diff first.

If a required specialist skill is missing:

1. do not pretend that phase ran;
2. use an equivalent direct procedure when possible;
3. report the missing dependency and reduced coverage.

If a real browser cannot be used, full frontend verification is blocked.

## Design references with bundled Inspo

The plugin bundles an `inspo` MCP server backed by the hosted Inspo catalogue.

Use it selectively before implementation when the task involves:

- a new page or interface;
- a new visual component;
- a substantial redesign;
- visual-direction exploration;
- hierarchy or layout exploration;
- an explicit request for references or inspiration.

Prefer the high-level Inspo recommendation flow first, then inspect specific design systems or components only when useful.

Treat Inspo as reference material, not project authority.

Do not use external inspiration to override an existing approved visual language, exact screenshot target, project design system, or project-specific constraints.

For ordinary bug fixes, responsive regressions, faithful existing-design work, and minor visual corrections, skip Inspo unless it materially helps.

If the bundled Inspo MCP is unavailable, report that limitation when reference research was actually needed. Its absence does not block ordinary frontend regression work.

## Motion and interaction specialist

When the external `motion` skill is installed, use it conditionally for work that materially creates or changes:

- animation systems or transition orchestration;
- enter/exit animation and presence;
- shared-layout or layout animation;
- gestures, drag, swipe, or reorder behavior;
- scroll-linked or scroll-triggered motion;
- spring-based interaction;
- animation performance, jank, or layout-thrash diagnosis;
- Motion API usage or upgrades.

Prefer project-native CSS when CSS is sufficient, especially for simple hover, focus, press, fade, loading, or similarly small effects.

Do not introduce the Motion runtime solely because the specialist skill exists. Follow the project's existing framework, animation stack, package version, architecture, and dependency policy.

For Motion-specific implementation, prefer the specialist's current upstream guidance rather than relying on stale API memory. If the specialist is unavailable, continue with the project's existing animation approach and report reduced specialist coverage only when it materially affects the task.

For any animation or interaction change:

- respect `prefers-reduced-motion` and project accessibility policy;
- verify keyboard and touch behavior when relevant;
- verify the start state, active transition, interruption/reversal when meaningful, and settled end state;
- treat geometry, sizing, wrapping, visibility, breakpoint, or shared-layout effects as Class A;
- treat animation-related layout fixes as normal regression-closure changes that invalidate prior visual verification for the affected surface.

## Accessibility authority and routing

Use the bundled `frontend-accessibility-qa` specialist throughout browser-facing work when accessibility can be affected.

Its authority model is:

1. stricter explicit project accessibility/legal requirements;
2. WCAG 2.2 Level A/AA hard requirements;
3. functional/browser correctness;
4. established project design system;
5. APCA perceptual guidance;
6. aesthetic preference.

WCAG 2.2 A/AA is the hard accessibility gate. APCA is advisory only and must never waive a WCAG failure or create an endless contrast-remediation loop.

Choose the smallest complete accessibility mode:

- `DESIGN_GUARD` while choosing colors, semantics, focus treatment, target size, interaction, error/help behavior, or reduced-motion behavior;
- `AFFECTED_AUDIT` after scoped UI changes;
- `FULL_AUDIT` for substantial new UI, explicit accessibility audits, broad design-system accessibility changes, or release acceptance where WCAG accessibility is in scope.

Do not run a full audit after every trivial frontend edit. Promote scope when shared components, shared semantic tokens, navigation, forms, or broad interaction patterns change.

## Recommended and optional layers

Use Impeccable for meaningful design/layout/typography/hierarchy/responsive critique or polish when it is installed and relevant.

Use the external `motion` specialist only for the conditional motion/interaction cases above. It is recommended, not required or bundled.

Optional locally available integrations may include:

- `taste-skill`
- `karpathy-guidelines`
- `context-engineering`
- `maintain-project-memory`

Never let optional tools override project rules.

## Toolchain mutation policy

Normal frontend work may perform local presence/readiness checks.

Normal frontend work must not silently:

- install dependencies;
- update dependencies;
- replace third-party skills;
- initialize Impeccable;
- approve hooks.

Bootstrap and updates are explicit maintenance operations only.

### Dependency installation and update handoff

On a **requested installation** of this plugin, or if required specialist capabilities
are missing, inspect `dependencies.yaml` and the installed skill/plugin inventory.
Use `scripts/plan-frontend-dependencies.ps1` for an initial read-only native CLI
inventory, local marketplace Git-origin/catalog verification and native
`/plugins` handoff; treat UNKNOWN and CONFLICT as stop conditions. Do not
construct undocumented deep links or trust the marketplace name alone. Do not execute the legacy multi-component bootstrap actions.
Classify REQUIRED, BUNDLED, RECOMMENDED, OPTIONAL_UNMANAGED and REFERENCE-ONLY
entries; a mention in a README is not an install instruction. Identify existing
packages, duplicate `SKILL.md` IDs, source/owner and install channel. Offer one
grouped plan for missing REQUIRED components and ask for the owner's approval
before any install, MCP registration or hook change. Recommended/optional
components require an explicit separate choice; no silent additions.

On a **user-requested update check**, run the read-only checks, compare only
verified installed package identities against upstream release/revision evidence,
and report `CURRENT`, `DIFFERENT`, `MISSING`, `AMBIGUOUS` or `UNKNOWN`.
A cache hit or a CLI process listing is not proof of activation in the current
Codex Desktop session. Failed network access, indeterminate revisions and
unpinned `@latest` runtimes are `UNKNOWN`, not `CURRENT` or `OUTDATED`.

On an **approved update**, operate only on the exact selected owning package.
Never fall back to an unnamed marketplace upgrade or update unrelated
components. The plugin owns its bundled `frontend-visual-qa`; never overwrite
it directly with `daymade` upstream. Require verified active-package identity,
a tested component-specific rollback including activation/configuration, and
post-update validation. If these gates are unavailable, report `BLOCKED` and
give a bounded native maintenance plan instead of running an unsafe updater.
The retrospective skill is a reviewer, not a dependency installer.

## Classify the change first

### Class A — layout/responsive/shared/release

Examples:

- layout or spacing geometry;
- width/height changes;
- grid/flex behavior;
- breakpoints;
- typography affecting wrapping;
- visibility or positioning;
- shared UI;
- header/footer/navigation;
- modal/drawer geometry;
- responsive media;
- release preparation.

Required:

- real browser;
- full viewport matrix;
- rendered visual QA;
- regression closure.

### Class B — minor visual

Use only when there is no plausible effect on geometry, wrapping, sizing, visibility, or responsive behavior.

Examples:

- color-only correction;
- border color;
- icon color.

Required:

- real browser;
- reduced viewport matrix;
- visual inspection.

If uncertain, promote to Class A.

### Class C — nonvisual browser-facing

Examples:

- link target;
- metadata;
- accessible name;
- browser-side logic with no layout effect.

Required:

- targeted browser verification;
- relevant functional/accessibility check.

### Class D — backend/non-UI

Do not use the frontend workflow unless the change directly alters rendered browser behavior.

## Phase 1 — Understand and reproduce

Before editing:

1. read project instructions;
2. inspect the relevant implementation;
3. identify affected routes/states;
4. identify layout system and breakpoints;
5. identify shared components;
6. identify existing tests/browser tooling;
7. reproduce the defect when practical.

Do not assume the visible symptom is the root cause.

## Phase 2 — Establish design direction when warranted

For new UI, redesign, or substantial visual exploration, use the bundled Inspo reference layer before implementation.

Extract transferable patterns such as hierarchy, composition, spacing logic, navigation structure, component archetypes, and responsive strategy.

Do not copy branding, proprietary content, or another site's visual identity.

If the task is an existing-design bug fix or regression, preserve the existing project instead of inventing a new direction.

## Phase 3 — Accessibility design guard when relevant

Before committing to a design decision that can create accessibility debt, use `frontend-accessibility-qa` in `DESIGN_GUARD` mode.

Typical triggers include:

- text/background and semantic color pairs;
- focus indicators;
- interactive target sizing;
- semantic element choice;
- keyboard interaction design;
- form labels/errors/help;
- animation/reduced-motion behavior.

For contrast, establish the WCAG 2.2 gate first. Use APCA only as an optional perceptual refinement after WCAG passes.

## Phase 4 — Implement

Use `frontend-ui-engineering`.

Prefer root-cause fixes and existing project conventions.

Avoid:

- arbitrary offsets;
- unexplained negative margins;
- unnecessary absolute positioning;
- one-screenshot breakpoint hacks;
- duplicate responsive exceptions;
- unrelated cleanup;
- framework migration without approval.

## Phase 5 — Code-level checks

Run applicable existing checks:

- lint;
- type checking;
- unit/component/integration tests;
- end-to-end tests;
- production build.

Use TDD when the changed behavior can reasonably be protected by a regression test.

A passing build is not evidence that rendered UI is correct.

## Phase 6 — Real browser

Use `browser-testing-with-devtools`.

Inspect as applicable:

- rendered DOM;
- geometry/layout;
- console;
- failed requests;
- interactions;
- accessibility structure;
- screenshots;
- viewport behavior.

New relevant console errors caused by the change are blockers.

## Phase 7 — Responsive verification

Read `references/verification-matrix.md`.

Class A uses the full matrix.

Class B uses the reduced matrix.

Class C uses targeted verification.

If breakpoint `B` changed or is suspected, also test `B-1`, `B`, and `B+1`.

## Phase 8 — Rendered visual QA

Use `frontend-visual-qa`.

Screenshots must be opened and visually inspected. Generating them is not enough.

Inspect the affected region and surrounding layout context.

For long pages, inspect below the fold.

For shared components, inspect representative consuming routes.

Do not update visual baselines merely to silence a regression.

## Phase 9 — Accessibility closure

Use `frontend-accessibility-qa` after implementation.

Default to `AFFECTED_AUDIT` for ordinary scoped UI work.

Use `FULL_AUDIT` only when the task scope warrants it, including substantial new UI, explicit WCAG/a11y audits, broad design-system accessibility work, or release acceptance that includes accessibility.

Accessibility checks reuse the existing real-browser and responsive evidence where valid. Do not create a second independent viewport matrix merely because accessibility is being checked.

If APCA produces an advisory concern after WCAG passes, it may justify one refinement cycle. It must not repeatedly reopen an otherwise completed hard-gate remediation loop unless new evidence identifies a WCAG failure, functional defect, or stricter explicit project requirement.

## Regression closure

This is the central rule.

Any later change to:

- CSS;
- layout;
- spacing;
- typography;
- positioning;
- sizing;
- visibility;
- breakpoint logic;
- component structure;
- shared frontend styles

invalidates previous visual verification for the affected surface.

After the fix, rerun the applicable browser, viewport, visual, and accessibility verification invalidated by the change.

Do not retest only the originally failing viewport.

Repeat until the affected verification surface is clean.

## Shared impact

When a shared primitive changes, broaden verification.

Examples:

- global header/footer/navigation;
- page shell/container;
- typography;
- CSS variables/design tokens;
- forms/buttons/cards/modals;
- global media rules.

Verify representative consumers across routes.

## Conditional final gates

Use additional specialist skills when applicable:

- `code-review-and-quality` for substantial/shared/release work;
- `security-and-hardening` for auth, uploads, permissions, tokens, sensitive input/data;
- `performance-optimization` when loading/rendering/assets/JS cost/Core Web Vitals may change;
- `shipping-and-launch` for production release/deployment preparation.

Do not force irrelevant gates into trivial work.

## Completion evidence

Before reporting completion, state:

- what changed;
- root cause when applicable;
- routes/pages checked;
- viewport sizes checked;
- code checks run;
- browser checks run;
- console status;
- visual QA status;
- accessibility mode used and WCAG status;
- APCA advisory status if APCA was used;
- shared consumers checked;
- anything blocked or unverified.

Do not say `done`, `fixed`, `ready`, or equivalent when required verification is incomplete.

Read:

- `references/verification-matrix.md`
- `references/dependencies.md`
- `references/toolchain-maintenance.md`
- bundled `../frontend-accessibility-qa/SKILL.md`
