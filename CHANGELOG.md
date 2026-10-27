# Changelog

## 1.5.1

Specialist preflight correctness and regression coverage after v1.5.0 (PR #12):

- Distinguish a single directly installed Taste skill (`PROVENANCE_UNKNOWN`) from actual duplicate Skill IDs (`CONFLICT`), without claiming the direct installation is a verified native plugin.
- Detect local duplicate specialists before contacting a remote provider. A provider outage cannot mask a real duplicate.
- Compare installed Motion Skill content against the integrity-verified current `motion-ai` npm release tarball, not the potentially different upstream GitHub `main` file.
- Normalize LF and CRLF line endings during Skill payload comparison to avoid false update recommendations on Windows.
- Verify the moving provider channel before reporting a missing Motion or Impeccable installation. When npm currentness is unavailable, report `UNKNOWN_DISTRIBUTION` rather than offering an unverified install.
- Add deterministic Windows regression tests for the ten agreed Taste/Motion/Impeccable preflight cases, including provider outages, duplicate ownership, payload mismatch, checksum failure and line-ending equivalence.

No changes to skill identities, bundled visual/accessibility QA, design-routing authority, WCAG policy, provider installation commands or automatic-mutation rules. Publishing the release does not update an existing Codex Desktop installation.

## 1.5.0

Conditional Taste art-direction routing:

- Replace the obsolete `taste-skill` optional placeholder with the current `design-taste-frontend` Skill ID from `Leonxlnx/taste-skill`.
- Classify Taste as a recommended external specialist for genuinely new/replacement art direction rather than a generic QA dependency.
- Add explicit triggers and non-triggers so ordinary bug fixes, reference matching, accessibility remediation and release QA do not invoke a redesign workflow.
- Enforce one art-direction authority per task: existing approved project design, Taste, or Impeccable design-direction capability.
- When Taste establishes direction, constrain Impeccable to downstream critique/polish inside that direction; do not alternate the two tools as competing remediation loops.
- Keep bundled visual QA, accessibility QA, responsive verification and regression closure authoritative over Taste's internal inspector/look-fix loop.
- Document the native Codex Taste plugin install path while keeping installation/update explicitly user-approved and unmanaged by normal frontend work.
- Remove hard-coded current-version wording from bilingual READMEs so `plugin.json` remains the only version source.
- Add design-routing safety fixtures for dependency ownership, authority arbitration, anti-loop rules and bilingual documentation.
- Add mandatory task-scoped specialist preflight before first external-skill use; required/triggered specialists can no longer disappear silently.
- Add `specialists.json` as a versionless operational registry: provider identity, owner, install channel and moving current provider channels only.
- Resolve external freshness from moving provider channels; for npm tools, use the configured dist-tag `latest` as current installable-version authority rather than repository `main`.
- Detect missing, disabled, stale/different, duplicate and provenance-unknown specialist states before use.
- After explicit approval, use the exact provider-native install/update channel from the versionless registry; avoid a second custom package-manager wrapper.
- Verify Codex-plugin marketplace Git origin/catalog ownership before mutation; npm-based currentness and provider mutations explicitly use the configured `latest` dist-tag/channel.
- Require package postflight and fresh-session Skill-ID resolution after mutations; cache presence remains insufficient activation evidence.
- Replace the partial legacy update checker with the unified live preflight while retaining older maintenance scripts as read-only compatibility helpers.
- Preserve the prior rollback finding: targeted approved mutations are allowed, but no transactional rollback capability is claimed.

## 1.4.1

Documentation consistency after the 1.4.0 accessibility merge:

- Replace stale "version candidate" wording in the English and Russian READMEs with the current main version.
- Make the accessibility architecture fixture validate the architectural minimum version (`>= 1.4.0`) instead of pinning CI to the original 1.4.0 candidate forever.
- No functional, dependency, routing, accessibility-policy, or runtime behavior changes.

## 1.4.0

Bundled accessibility architecture:

- Add `frontend-accessibility-qa` as a bundled, version-consistent accessibility specialist owned by this repository.
- Use WCAG 2.2 Level A/AA as the hard accessibility gate when conformance is in scope.
- Add three audit depths: `DESIGN_GUARD`, `AFFECTED_AUDIT`, and `FULL_AUDIT`.
- Add design-time contrast/state checks and post-implementation accessibility closure without creating a second responsive matrix.
- Keep APCA optional and advisory; it cannot waive WCAG failures or repeatedly reopen a completed hard-gate remediation loop.
- Treat 84EM `wcag-2.2-aa` and Thrillmade `apca-contrast` as design/reference inputs only, not runtime dependencies.
- Add maintained WCAG A/AA checklist, contrast arbitration policy, evidence/scope guidance, and architecture safety tests.
- Extend readiness, install-planning and maintenance messaging to recognize the new bundled skill.

## 1.3.0

Conditional Motion specialist integration:

- Add the official Motion AI Kit `motion` skill as a recommended external specialist for animation, layout motion, gestures, scroll-linked effects, springs, Motion API work and animation-performance diagnosis.
- Keep Motion external and opt-in: it is neither required nor bundled, and the suite does not install or update it automatically.
- Prefer CSS for simple effects when CSS is sufficient; never add the Motion runtime solely because the agent skill exists.
- Require reduced-motion/accessibility handling and browser verification of relevant animated states, with normal regression closure for layout-affecting motion.
- Extend dependency safety fixtures so Motion cannot silently drift into the required/bundled or managed-install path.

## 1.2.4

Repository identity preparation for `SergejDAGDA/frontend-quality-suite-skill`:

- Keep both bundled Skill IDs `frontend-production-qa` and `frontend-visual-qa` unchanged.
- Preserve the installed native Codex plugin ID `frontend-production-qa@codex-frontend-production-qa` and marketplace catalog name for existing registrations.
- Update the repository canonical source URLs in plugin/marketplace metadata, ownership checks and read-only guidance; do not relax owner-verification refusal for old origins.
- Renaming, merge, published Release, Marketplace re-registration and local installation remain separate approved actions; the candidate itself performs none of them.


## 1.2.3 - 2026-10-17

Guided installation planning for required frontend specialist plugins:

- Add read-only native Codex CLI inventory and documented `/plugins` handoff only after verified local marketplace Git-origin and catalog source checks; fail closed on unverified ownership.
- Detect known direct skill ID collisions and preserve UNKNOWN / CONFLICT refusal.
- Replace legacy multi-component bootstrap mutations with a read-only plan.
- Keep installed-plugin updates and automatic rollback blocked following the native rollback lab's NOT YET SAFE result.
- Preserve all existing plugin IDs, managed bundle ownership, and separate approval for Chrome DevTools MCP / Impeccable.


## 1.2.2 - 2026-10-17

Safety correction for frontend specialist-dependency management:

- Do not perform a broad `codex plugin marketplace upgrade` fallback.
- Replace the old bulk `-Apply` updater with a component-selective read-only plan; applying remains blocked until a real native rollback and enabled-package identity are proven.
- Surface duplicate `SKILL.md` IDs and divergent copies instead of silently using the first search-path candidate.
- Distinguish cache evidence, upstream HEAD, active plugin status and desktop MCP runtime; label incomplete evidence UNKNOWN.
- Clarify bundled-skill ownership and require consent for missing required dependencies. No existing installation, plugin cache or user configuration is changed by this release itself.

## 1.2.1 - 2026-09-29

Codex skill-path maintenance release.

- Prefer `.codex/skills` and plugin cache locations during readiness checks.
- Stop bootstrap and update scripts from downloading or replacing the bundled `frontend-visual-qa` skill.
- Refresh the frontend plugin itself when updating the specialist toolchain.
- Keep the legacy `.agents/skills` path only as a compatibility fallback.

## 1.2.0 - 2026-09-25

Bundled visual QA consistency release.

- Bundled the maintained Codex-adapted `frontend-visual-qa` skill.
- Removed the floating upstream copy as a runtime dependency.
- Documented `ui-designer` and `qa-expert` as optional related skills.
- Kept external `agent-skills` and Chrome DevTools MCP dependencies explicit.

## 1.1.1 - 2026-09-22

Packaging correction release.

- Added the portable root `plugin.json` manifest.
- Moved the bundled Inspo configuration to root `mcp.json`.
- Removed legacy manifest files that duplicated the plugin version and MCP configuration.
- Made the portable root manifest the only release-version source.

## 1.1.0 - 2026-09-22

Git-backed Codex plugin distribution.

- Packaged the repository as a native Codex plugin.
- Added a Git-backed marketplace for direct installation and updates from GitHub.
- Bundled the hosted Inspo MCP endpoint for selective production-site design references.
- Made the plugin manifest the only release-version source.
- Removed duplicate release-version declarations from the skill and dependency manifest.
- Documented migration away from manual copies under `~/.agents/skills`.
- Kept project design and existing UI as authoritative over inspiration sources.
- Kept specialist toolchain maintenance separate from plugin self-updates.

## 1.0.0 - 2026-09-20

Initial public version.

- Added frontend workflow orchestration.
- Added Class A/B/C/D verification model.
- Added full and reduced responsive matrices.
- Added breakpoint boundary checks.
- Added regression-closure rule after CSS/layout changes.
- Added shared-component cross-page verification.
- Added real-browser and screenshot-inspection requirements.
- Added required specialist-stack documentation.
- Added project AGENTS routing fragment.
- Added explicit bootstrap/check/update maintenance scripts.
- Added English and Russian documentation.
