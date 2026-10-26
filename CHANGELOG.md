# Changelog

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
