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

External specialist availability and freshness must be established before first use in each task. Do not silently skip a required or task-triggered specialist because the user did not know to ask about it.

If a real browser cannot be used, full frontend verification is blocked.

## Specialist preflight and live-version policy

After classifying the task, derive the exact external specialist set that the task needs.

Always include the required external base capabilities:

- `frontend-ui-engineering`;
- `browser-testing-with-devtools`.

Add conditional recommended specialists only when their routing triggers:

- `design-taste-frontend` for qualifying art-direction work;
- `impeccable` for qualifying design critique/polish or design direction when Taste was not selected;
- `motion` for qualifying substantial motion/interaction work.

Bundled `frontend-visual-qa` and `frontend-accessibility-qa` are versioned with this plugin and must not be checked against floating external copies.

Before first use of any external specialist in the task, run:

```powershell
.\scripts\preflight-frontend-specialists.ps1 -SkillId <exact-skill-id>
```

Batch multiple selected Skill IDs when useful. Run the live check once per selected provider per session unless the task scope changes or a mutation occurs.

The preflight registry stores **identity, owner, install channel, and live author/distribution source only**. It must not pin a remembered external version. Current-version truth must be read from the author's live source at preflight time. Do not use versions remembered from this file, README text, changelog history, prior conversations, or model knowledge as freshness evidence.

Interpret preflight states as follows:

- `INSTALLED_CURRENT` — package/payload matches the current author source; still resolve the exact Skill ID in the current Codex session before claiming it ran;
- `UPDATE_AVAILABLE` / `UPDATE_RECOMMENDED` — proactively tell the user before use and offer the exact provider-specific update;
- `MISSING` / `MARKETPLACE_MISSING` — proactively tell the user and offer the exact author-owned installation;
- `DISABLED` — do not pretend the specialist is usable; enable through the native provider flow and start a fresh session;
- `CONFLICT` — duplicate IDs or ownership disagreement; do not install/update/use the ambiguous specialist until resolved;
- `PROVENANCE_UNKNOWN`, `SOURCE_DIVERGENCE`, `UNKNOWN_REMOTE`, `UNKNOWN_DISTRIBUTION`, `UNKNOWN_LOCAL`, or `DIFFERENT` — do not claim currentness and do not mutate automatically; resolve evidence/provenance first.

A cache hit or readable `SKILL.md` is not proof that the current Codex Desktop session loaded that specialist. Before invoking a specialist, resolve the exact Skill ID in the active session. If package-level preflight passes but the current session cannot resolve it, classify it operationally as `INSTALLED_NOT_ACTIVE`, require a fresh session, and do not claim that specialist phase ran.

When an update is available, do not silently keep using the stale specialist. Offer the update first. If the user declines:

- for a required specialist, continue only with explicitly reduced/stale coverage and do not claim current-toolchain verification;
- for a conditional recommended specialist, skip it or use a bounded fallback and report reduced specialist coverage.

When installation/update is appropriate, show the user the exact provider-specific action from `specialists.json` and obtain explicit approval for that exact specialist/action.

After approval, execute the provider's official channel directly rather than routing it through a custom package-manager wrapper:

- Codex-plugin providers: use only the exact author-owned marketplace/plugin IDs from the registry; verify marketplace Git origin/catalog ownership before mutation; update only that named marketplace/plugin.
- Provider CLI/installers: use only the exact current command recorded in the registry, including `@latest` where declared.

Immediately after mutation:

1. re-run package-level live preflight for that specialist;
2. start a fresh Codex session when required;
3. resolve the exact Skill ID in that fresh session;
4. verify provider-specific runtime capability when relevant, such as Motion MCP or Impeccable hook trust;
5. only then rely on the specialist.

Never update all marketplaces/packages as a side effect of a frontend task. Never claim transactional rollback for a provider whose restore path has not been proven.

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

## Design-direction authority and Taste specialist

Use one art-direction authority per task.

Choose in this order:

1. an existing approved project brand/design system when the task must preserve it;
2. the external `design-taste-frontend` specialist when a new or replacement visual direction is explicitly warranted;
3. Impeccable new-work/design-direction capability only when Taste was not selected and a design direction is still needed.

Do not let Taste and Impeccable independently establish competing visual directions for the same task.

Use `design-taste-frontend` when the task materially asks for:

- a new landing page, marketing/public-facing page, portfolio, campaign, product page, or visual showcase that needs a distinctive art direction;
- a deliberate redesign or restyle that is allowed to replace the existing visual world;
- a page/interface described as generic, templated, "AI-made", bland, or in need of a distinctive/premium/award-level direction;
- a new app/dashboard screen where the user explicitly wants a fresh art direction rather than preservation of an established product design.

Skip Taste for:

- ordinary bug fixes;
- responsive regressions;
- exact screenshot/reference matching;
- faithful maintenance of an approved existing design system;
- accessibility remediation;
- small color/spacing/layout corrections;
- nonvisual browser behavior;
- release QA where no redesign is requested.

When Taste is selected:

- run it before implementation as the art-direction layer, after project constraints and optional reference research are understood;
- preserve project/brand constraints and use Taste's own preservation controls when appropriate;
- treat Taste's browser inspector and look/fix loop as implementation-stage design refinement, **not** as the suite's final completion authority;
- after the Taste direction is chosen, Impeccable may critique or polish the implementation inside that direction, but must not replace the direction unless the user explicitly asks to reopen art direction;
- do not alternate Taste -> Impeccable -> Taste in a remediation loop;
- a downstream Impeccable-only design suggestion gets at most one refinement cycle unless it exposes new evidence of a functional, accessibility, responsive, or explicit project-requirement failure;
- the bundled `frontend-visual-qa` remains the rendered visual-evidence layer;
- the bundled `frontend-accessibility-qa` and explicit project/legal requirements override Taste house rules whenever they conflict;
- the orchestrator's viewport matrix, regression closure, browser checks, and completion evidence remain authoritative.

Taste is a recommended external specialist. Its plugin/repository name is `taste-skill`, but its current Skill ID is `design-taste-frontend`. Do not route by the repository/plugin name as though it were the Skill ID.

If Taste is unavailable, continue with project design authority and/or Impeccable when appropriate; report reduced art-direction coverage only when the task actually depended on it.

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

Use Impeccable for meaningful design/layout/typography/hierarchy/responsive critique or polish when relevant and after task-scoped preflight. If Taste established the art direction, constrain Impeccable to critique/polish inside that direction rather than starting a competing redesign.

Use the external `motion` specialist only for the conditional motion/interaction cases above. It is recommended, not required or bundled.

Use the external `design-taste-frontend` specialist only for the conditional art-direction cases above. It is recommended, not required or bundled.

Optional locally available integrations may include:

- `karpathy-guidelines`
- `context-engineering`
- `maintain-project-memory`

Never let optional tools override project rules.

## Toolchain mutation policy

Task-scoped read-only specialist preflight is mandatory when an external specialist is selected.

Normal frontend work must not silently:

- install dependencies;
- update dependencies;
- replace third-party skills;
- initialize Impeccable;
- approve hooks;
- register an unverified marketplace;
- resolve a duplicate Skill ID by traversal order.

A missing or stale specialist is a user-visible preflight finding, not a reason to quietly omit that phase.

### Dependency installation and update handoff

`scripts/preflight-frontend-specialists.ps1` is the primary task-time check for required and triggered recommended specialists. It reads the current author source live and distinguishes package availability, freshness, duplicate IDs, marketplace provenance, and evidence gaps.

After live preflight, an install/update may be executed only when the user explicitly approves that exact specialist/action.

Do not add a custom package-manager layer. Read the official channel and exact identity from `specialists.json`, then invoke the provider directly:

- Codex-plugin providers: verify marketplace Git origin and catalog plugin source against the author's repository before update/install; a matching marketplace name alone is insufficient.
- Provider CLI/installers: use the current distribution command declared in `specialists.json`; npm-based mutations explicitly request `@latest` where appropriate so local npx cache is not treated as current-version truth.

Every mutation is single-provider, followed by live postflight. Never perform an unnamed/all-marketplace upgrade and never claim current-session activation from package files alone.

The older `plan-frontend-dependencies.ps1`, `bootstrap-frontend-toolchain.ps1`, and `update-frontend-toolchain.ps1` remain compatibility/read-only maintenance helpers. They are not substitutes for task-scoped live specialist preflight.

The plugin owns bundled `frontend-visual-qa` and `frontend-accessibility-qa`; never replace them directly from floating upstream copies.

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

## Phase 1 — Understand, select capabilities, and reproduce

Before editing:

1. read project instructions;
2. classify the frontend change and identify which external specialists are actually required/triggered;
3. run task-scoped live preflight for those specialists;
4. surface missing, stale, disabled, conflicting, unverified, or inactive-session specialists before their phase begins;
5. if the user approves an install/update, mutate only that exact specialist, run postflight, and require a fresh session when indicated;
6. inspect the relevant implementation;
7. identify affected routes/states;
8. identify layout system and breakpoints;
9. identify shared components;
10. identify existing tests/browser tooling;
11. reproduce the defect when practical.

Do not assume the visible symptom is the root cause. Do not silently downgrade the specialist set because the user did not know a dependency was missing.

## Phase 2 — Establish design direction when warranted

For new UI, redesign, or substantial visual exploration, use the bundled Inspo reference layer when reference research is useful.

Then select exactly one art-direction authority.

- Preserve the existing approved project design when preservation is required.
- Use `design-taste-frontend` when the task qualifies for a new/replacement distinctive direction.
- Otherwise use Impeccable for design direction only when appropriate and Taste was not selected.

Extract transferable patterns such as hierarchy, composition, spacing logic, navigation structure, component archetypes, and responsive strategy.

Do not copy branding, proprietary content, or another site's visual identity.

If the task is an existing-design bug fix or regression, preserve the existing project instead of inventing a new direction.

Once the art direction is selected, lock it for the task unless the user explicitly reopens that decision or new hard evidence makes the direction infeasible.

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
- external specialist preflight status for every selected provider;
- any offered/approved install or update and whether a fresh-session activation check completed;
- selected art-direction authority when design direction was in scope;
- Taste/Impeccable role used, if any;
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
- `specialists.json`
- bundled `../frontend-accessibility-qa/SKILL.md`
