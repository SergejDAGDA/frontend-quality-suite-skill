# Frontend Quality Suite

[Русская версия](README.ru.md)

A reusable Agent Skill plugin for production-grade frontend implementation and QA, bundling the `frontend-production-qa` orchestrator plus separate `frontend-visual-qa` and `frontend-accessibility-qa` audit specialists.

It does not replace specialist skills. It orchestrates them, defines how deeply a browser-facing change must be verified, and decides when the work has enough evidence to be considered complete.

**GitHub repository:** `SergejDAGDA/frontend-quality-suite-skill`. **Installed plugin ID:** `frontend-production-qa@codex-frontend-production-qa` (unchanged). **Bundled Skill IDs:** `$frontend-production-qa`, `$frontend-visual-qa`, `$frontend-accessibility-qa`. The Marketplace ID intentionally retains its historical name to avoid an unapproved change to an existing native Codex registration.

**Version source:** the current plugin version is declared only in `plugin.json`. Renaming the GitHub repository does not update the installed Marketplace checkout or cached plugin. An existing checkout whose origin still names `codex-frontend-production-qa` may fail the strict ownership check after the expected repository changes; do not bypass or silently re-register it. Verify and separately approve the native migration before installation. Do not assume support for other agent hosts has been tested.

## Why this exists

A frontend change can compile and still be wrong:

- a desktop fix breaks mobile;
- one screenshot looks right while another viewport overflows;
- a shared component regresses on another route;
- screenshots are generated but never inspected;
- a visual baseline is updated instead of fixing the regression;
- a plugin appears installed while the expected skill payload is unavailable.

`frontend-production-qa` adds an evidence-based completion workflow around those failure modes.

## Install from GitHub

The GitHub repository is the canonical source. Do not maintain a separate manual copy of this skill when using the plugin distribution.

```powershell
codex plugin marketplace add SergejDAGDA/frontend-quality-suite-skill --ref main
codex plugin add frontend-production-qa@codex-frontend-production-qa
```

Start a fresh Codex session after installation.

### Update from GitHub

```powershell
codex plugin marketplace upgrade codex-frontend-production-qa
codex plugin add frontend-production-qa@codex-frontend-production-qa
```

Then start a fresh Codex session.

The second command is intentionally safe to repeat and ensures the installed plugin payload is materialized from the refreshed marketplace snapshot.

### One source of version truth

The public plugin version lives only in:

```text
plugin.json
```

Do not add separate release versions to `SKILL.md` or dependency manifests.

Every published plugin change must bump the manifest version. This prevents a new Git snapshot from being mistaken for an already-cached payload with the same version.

### Migrating from the old manual install

If `frontend-production-qa` was previously copied to:

```text
~/.agents/skills/frontend-production-qa/
```

remove or rename that old manual copy before using the plugin install. Codex does not merge skills with the same `name`; duplicate copies can both appear.

## Bundled Inspo MCP

The plugin bundles the hosted [Inspo](https://github.com/Nutlope/inspo) MCP endpoint:

```text
https://inspomcp.dev/api/mcp
```

Inspo provides searchable references from real production websites. The orchestrator uses it selectively for:

- new UI;
- new components;
- substantial redesigns;
- visual-direction exploration;
- hierarchy/layout exploration;
- explicit requests for references or inspiration.

It is not the design authority for an existing project. For bug fixes, screenshot matching, responsive regressions, or work that must preserve an established visual language, the project itself remains the source of truth.

No separate `codex mcp add inspo ...` is needed when the plugin is installed.

## Conditional Motion specialist

For animation-heavy frontend work, the orchestrator can use the official external `motion` skill from [Motion AI Kit](https://github.com/motiondivision/ai-kit).

Use it conditionally for substantial animation, enter/exit orchestration, layout motion, gestures, drag/reorder, scroll-linked effects, springs, Motion API work, or animation-performance diagnosis.

It is **recommended, not required or bundled**. The suite checks Motion only when the task triggers it. Freshness is read from Motion's live author/distribution sources; no Motion version is pinned in this repository.

When Motion is missing or differs from the current author payload, the orchestrator offers the exact provider update/install before use. Mutation still requires explicit user approval.

The current provider installer is invoked as:

```powershell
npx motion-ai@latest
```

The installer can write skill files and hosted MCP configuration, so the action remains explicit and user-approved.

Prefer CSS for simple hover/focus/press/fade/loading effects when CSS is sufficient. Do not add the Motion runtime package solely because the agent skill is available. Respect reduced-motion/accessibility requirements and verify relevant animated states in the browser.

## Conditional Taste art-direction specialist

For frontend work that genuinely needs a new or replacement visual direction, the orchestrator can use the external `design-taste-frontend` skill from [Leonxlnx/taste-skill](https://github.com/Leonxlnx/taste-skill).

Use it conditionally for distinctive new landing/marketing/public pages, portfolios/showcases, deliberate redesign/restyle work, explicitly anti-generic/"AI-made" redesigns, or a new app/dashboard visual world when the user asks for one.

Skip Taste for ordinary bug fixes, responsive regressions, exact reference matching, faithful maintenance of an approved design system, accessibility remediation, small visual corrections, and release QA without redesign.

Use **one art-direction authority per task**:

- an existing approved project design when preservation is required;
- Taste when a new/replacement direction is explicitly warranted;
- Impeccable design-direction capability only when Taste was not selected and direction is still needed.

When Taste establishes the direction, Impeccable may critique/polish within it but must not start a competing redesign. Taste's own inspector/look-fix loop does not replace the suite's viewport matrix, visual QA, accessibility QA, regression closure, or completion evidence.

Taste is **recommended, not required or bundled**. The suite checks it only when Taste routing is triggered. If it is missing or its author-owned plugin has a newer live version, the orchestrator offers the exact native Codex install/update and applies it only after explicit approval.

## Bundled accessibility specialist

The suite bundles `frontend-accessibility-qa` as the accessibility authority for browser-facing work.

It uses **WCAG 2.2 Level A/AA as the hard gate** when accessibility conformance is in scope. APCA is supported only as optional perceptual design guidance and cannot waive a WCAG failure.

Three audit depths prevent over-testing:

- `DESIGN_GUARD` for color, semantics, focus, target size and interaction choices while work is being designed;
- `AFFECTED_AUDIT` for normal scoped changes after implementation;
- `FULL_AUDIT` for substantial new UI, explicit WCAG audits, broad accessibility changes, or release acceptance that includes accessibility.

The accessibility specialist is maintained in this repository. External WCAG/APCA agent skills are reference sources, not runtime dependencies.

## Live specialist preflight

External specialists are not assumed to exist merely because the orchestrator references them.

After classifying a task, the suite derives the exact required/triggered specialist set and performs a **read-only live preflight before first use**:

```powershell
.\scripts\preflight-frontend-specialists.ps1 -SkillId <exact-skill-id>
```

The registry in `skills/frontend-production-qa/specialists.json` stores only provider identity, repository, install channel and live version/payload sources. It intentionally stores **no current external version numbers**.

Freshness is checked against the author's current source at runtime. For npm-distributed providers such as Impeccable and Motion, the author's manifest is also compared with the current official distribution metadata so an unpublished/de-synchronised source is not silently treated as installable.

The preflight distinguishes states including `INSTALLED_CURRENT`, `UPDATE_AVAILABLE`, `UPDATE_RECOMMENDED`, `MISSING`, `DISABLED`, `CONFLICT`, `PROVENANCE_UNKNOWN` and evidence/source unknown states.

If installation/update is appropriate, the orchestrator shows the exact provider-native action from `specialists.json` before changing anything. Only after explicit approval may it execute that one action.

Codex-plugin providers use the exact author-owned marketplace/plugin identity after ownership verification. Provider CLI/installers use the exact current command in the registry, including `@latest` where declared. There is no custom package-manager wrapper and no broad "upgrade everything" operation.

After mutation, rerun live preflight, start a fresh Codex session when required, and resolve the exact Skill ID before claiming that specialist phase ran. A package found on disk is not active-session proof.

## Core workflow

```text
project rules
  -> classify task + live specialist preflight
  -> understand/reproduce
  -> optional design references when warranted
  -> conditional Taste art direction when warranted
  -> accessibility design guard when relevant
  -> frontend implementation
  -> conditional Motion specialist when relevant
  -> design-quality layer when relevant
  -> code checks
  -> real browser
  -> responsive verification
  -> rendered visual QA
  -> accessibility closure
  -> regression closure
  -> conditional review/security/performance/release gates
  -> completion evidence
```

## Verification classes

| Class | Typical change | Required verification |
|---|---|---|
| A | layout, responsive, typography wrapping, shared UI, navigation, release prep | real browser + full 8-viewport matrix + visual QA + regression closure |
| B | small visual change with no plausible geometry impact | real browser + reduced 3-viewport matrix + visual inspection |
| C | nonvisual browser-facing change | targeted browser verification |
| D | backend/non-UI | no frontend workflow unless rendered browser behavior changes |

Full matrix:

```text
320x568
375x812
390x844
768x1024
1024x768
1280x800
1440x900
1920x1080
```

Reduced matrix:

```text
390x844
768x1024
1440x900
```

If breakpoint `B` changes or is suspected, also test `B-1`, `B`, and `B+1`.

## Required specialist stack

The workflow expects:

- `frontend-ui-engineering`
- `browser-testing-with-devtools`
- bundled `frontend-visual-qa`
- bundled `frontend-accessibility-qa`
- Chrome DevTools MCP

The first two come from [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills).

`frontend-visual-qa` is bundled in this repository. Its original upstream source is [daymade/claude-code-skills](https://github.com/daymade/claude-code-skills), but the maintained Codex-adapted copy here is the version used by this plugin.

`frontend-accessibility-qa` is also bundled and maintained here. It uses the W3C [WCAG 2.2 Recommendation](https://www.w3.org/TR/WCAG22/) as its normative accessibility baseline and keeps APCA advisory rather than making it a competing compliance gate.

Chrome DevTools MCP comes from [ChromeDevTools/chrome-devtools-mcp](https://github.com/ChromeDevTools/chrome-devtools-mcp).

Recommended conditional specialists:

- [Taste Skill](https://github.com/Leonxlnx/taste-skill) / `design-taste-frontend` for new or replacement art direction;
- [Impeccable](https://github.com/pbakaus/impeccable) for design-quality critique and polish inside the selected direction;
- [Motion AI Kit](https://github.com/motiondivision/ai-kit) for substantial animation and interaction work.

Related optional skills:

- `ui-designer`
- `qa-expert`

Optional existing integrations:

- `karpathy-guidelines`
- `context-engineering`
- `maintain-project-memory`

The orchestrator does not install or update optional integrations.

## Project routing

Do not copy the whole skill into a project's `AGENTS.md`.

Use the short routing fragment:

```text
skills/frontend-production-qa/assets/AGENTS.frontend.fragment.md
```

Project-specific architecture, legal constraints, design decisions and memory remain authoritative in the project itself.

## Dependency maintenance

The plugin itself is updated through the Git-backed marketplace.

The bundled `frontend-visual-qa` and `frontend-accessibility-qa` skills are updated only with this plugin.

Primary task-time commands:

```powershell
.\scripts\preflight-frontend-specialists.ps1 -SkillId frontend-ui-engineering
.\scripts\preflight-frontend-specialists.ps1 -SkillId design-taste-frontend
.\scripts\check-frontend-updates.ps1
```

These commands are read-only. When preflight finds a missing/stale selected specialist, the orchestrator shows the exact provider-native install/update from `specialists.json`; it executes that command only after explicit approval.

The older `check-frontend-toolchain.ps1`, `plan-frontend-dependencies.ps1`, `bootstrap-frontend-toolchain.ps1`, and `update-frontend-toolchain.ps1` remain compatibility/read-only helpers. They do not replace live task-scoped preflight.

Normal frontend work must never silently mutate third-party dependencies. It must, however, **proactively surface** missing/stale specialists that the selected workflow needs and offer the correct owner-specific install/update. Duplicate IDs, source divergence, unknown provenance, or unverifiable current versions stop automatic mutation.

Review [toolchain maintenance](skills/frontend-production-qa/references/toolchain-maintenance.md) before installation/update. A cached file alone does not prove active-session loading.

See:

- [Dependencies](skills/frontend-production-qa/references/dependencies.md)
- [Verification matrix](skills/frontend-production-qa/references/verification-matrix.md)
- [Toolchain maintenance](skills/frontend-production-qa/references/toolchain-maintenance.md)

## Central completion rule

Any later CSS/layout/spacing/typography/positioning/sizing/visibility/breakpoint/shared-style change invalidates the previous visual verification for the affected surface.

Re-run the applicable browser and responsive checks after the fix.

Do not report `done`, `fixed`, or `ready` when required verification is incomplete.

## License

MIT.
