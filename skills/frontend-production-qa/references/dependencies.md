# Dependencies

## Plugin-bundled

### Inspo MCP

The plugin bundles Inspo as a remote read-only design-reference MCP server.

```text
https://inspomcp.dev/api/mcp
```

Upstream:

https://github.com/Nutlope/inspo

No separate user-level MCP registration is required when `frontend-production-qa` is installed as a plugin.

Use Inspo for new UI, new components, redesigns, visual-direction exploration, or explicit requests for reference material.

Do not use inspiration results as authority over an existing project's approved visual language.

## Dependency classes and source ownership

`dependencies.yaml` declares required, bundled, recommended and optional
integrations, but is **not** a package lockfile or native dependency resolver.
Use the owning plugin/skill identifier (not just a directory or repository
name) to select a source. A **REFERENCE-ONLY** upstream is never an automatic
installation candidate.

Before installing missing required components, first inspect all discovered
paths and enabled-owner evidence. If duplicates share a `SKILL.md` ID, display
each path/source/hash; do not silently select a directory by traversal order.
Old plugin cache versions may remain on disk without being enabled. A
directory/header mismatch (for example `taste-skill` versus declared
`design-taste-frontend`) is an alias requiring explicit resolution.

For upgrades, distinguish package cache version, source commit, enabled
plugin registration and current Desktop session load. No single one of those
proves all the others. Host MCP configuration, active MCP startup and browser
connectivity likewise require separate evidence.

The task-time orchestrator must proactively detect missing or stale REQUIRED
and task-triggered RECOMMENDED specialists. The user does not need to know
which dependency to ask about. Detection is read-only; any mutation still
requires explicit approval for the exact provider/action.

Do not store a remembered "current version" for external specialists here.
Use `specialists.json` plus `preflight-frontend-specialists.ps1` to resolve
the configured moving current provider channel live. For npm-distributed
providers, the configured dist-tag (normally `latest`) is the authoritative
current installable release; repository `main` is not required to match it.

## Task-time live specialist preflight

Primary runtime source registry:

```text
skills/frontend-production-qa/specialists.json
```

Primary read-only check:

```powershell
.\scripts\preflight-frontend-specialists.ps1 -SkillId <exact-skill-id>
```

The registry contains provider identity, repository, install channel and a
moving current provider channel, but no pinned current external versions.

When preflight reports an installable/updateable state, show the exact official provider action from `specialists.json`. Only after explicit approval may the orchestrator execute that one provider-native action directly.

Duplicate IDs, unknown provenance and unverifiable live current-channel evidence block mutation. Do not add a second custom package-manager wrapper around the provider's own Codex plugin or CLI/installer channel.

## Guided installation boundary

Run `scripts/plan-frontend-dependencies.ps1` to inspect native Codex
plugin inventory. The planner does not add, remove, or update anything.
It reports `/plugins` as the supported manual handoff **only** when native
inventory reports a missing plugin, the local marketplace Git origin and
catalog plugin source match the expected repository, and no direct collision
is discovered for the known required skill IDs. A matching marketplace name
alone is insufficient. Custom `codex://` install deep links are unsupported. The user reviews the native install preview and authorizes the
selected package in Codex Desktop; a script may not impersonate that approval.

If evidence is UNKNOWN, a marketplace is unregistered, a plugin is disabled,
or an ID collision is present, stop and investigate. Native Codex installs
do not provide a proven atomic rollback for arbitrary partial failures.
Do not claim that this planner universally resolves every bundled skill ID.

## Required external specialist stack

### addyosmani/agent-skills

Required skills:

- `frontend-ui-engineering`
- `browser-testing-with-devtools`

Current Codex plugin installation:

```powershell
codex plugin marketplace add addyosmani/agent-skills
codex plugin add agent-skills@agent-skills
```

Upstream:

https://github.com/addyosmani/agent-skills

### Bundled frontend-visual-qa

The plugin bundles the maintained Codex-adapted copy in:

```text
skills/frontend-visual-qa/
```

The original upstream source is retained only as a comparison reference:

https://github.com/daymade/claude-code-skills

Do not silently replace the bundled copy with the upstream Claude-oriented version. Changes should be reviewed and committed to this repository so the orchestrator and visual QA rules remain version-consistent.

Legacy user install directory:

```text
~/.agents/skills/frontend-visual-qa/
```

### Bundled frontend-accessibility-qa

The plugin also bundles its own accessibility specialist in:

```text
skills/frontend-accessibility-qa/
```

This skill owns the suite's accessibility policy:

- WCAG 2.2 Level A/AA is the hard gate when accessibility conformance is in scope;
- APCA is optional perceptual guidance only;
- design-time checks use scoped `DESIGN_GUARD`;
- ordinary changes use `AFFECTED_AUDIT`;
- substantial/release/accessibility work can use `FULL_AUDIT`;
- advisory-only APCA findings cannot repeatedly reopen a completed WCAG remediation loop.

Two external skills were reviewed as reference material while designing this bundled policy:

- https://github.com/84emllc/claude-wcag-skill
- https://github.com/thrillmade/agent-skills/tree/main/skills/apca-contrast

They are **REFERENCE-ONLY** for this suite. Do not install them as runtime dependencies of `frontend-production-qa`, and do not let their own routing/authority rules override the bundled accessibility specialist.

The normative WCAG source remains:

https://www.w3.org/TR/WCAG22/

### Chrome DevTools MCP

Current Codex registration:

```powershell
codex mcp add chrome-devtools -- npx chrome-devtools-mcp@latest
```

Upstream:

https://github.com/ChromeDevTools/chrome-devtools-mcp

Registration alone proves configuration, not successful MCP process startup or Chrome connectivity. Those are runtime checks during actual frontend work.

## Recommended

### Related skills

The bundled `frontend-visual-qa` documentation may refer to these optional adjacent skills:

- `ui-designer` for extracting design systems from reference images;
- `qa-expert` for broader QA strategy and test-program setup.

They are not required to run the production frontend workflow. When installed, use the Codex-compatible copies from `daymade/claude-code-skills` or an explicitly maintained fork.

### Motion AI Kit

The official Motion AI Kit provides the external `motion` skill plus hosted Motion MCP context.

Upstream:

https://github.com/motiondivision/ai-kit

Documentation:

https://motion.dev/docs/ai-kit

Official current installer used after explicit approval:

```powershell
npx motion-ai@latest
```

Official upgrade path:

```powershell
npx motion-ai@latest
```

Treat this as a **conditional external recommendation**, not as a required or bundled dependency. The installer can write skill files and MCP configuration, so do not run it silently from this plugin's bootstrap or updater.

Use the specialist for substantial animation, transition orchestration, layout motion, gestures, drag/reorder, scroll-linked effects, springs, Motion API work, or animation performance diagnostics. Prefer CSS when CSS is sufficient.

Do not install the Motion runtime package solely because the agent skill is present. Project dependency policy remains authoritative.

### Taste Skill

The upstream repository/plugin is:

https://github.com/Leonxlnx/taste-skill

The current Skill ID is:

```text
design-taste-frontend
```

The repository/plugin name `taste-skill` is not the Skill ID.

Native Codex plugin installation:

```powershell
codex plugin marketplace add Leonxlnx/taste-skill
codex plugin add taste-skill@taste-skill
```

Targeted update:

```powershell
codex plugin marketplace upgrade taste-skill
codex plugin add taste-skill@taste-skill
```

Before either path, task-time preflight resolves the live author-owned plugin
channel and verifies marketplace owner/provenance. Start a fresh Codex session after
installation/update and resolve the exact `design-taste-frontend` Skill ID.

Upstream also documents direct skill installation through the agent-skills CLI, but this suite prefers the native Codex plugin route when operating in Codex.

Treat Taste as a **conditional external recommendation**, not as required or bundled content.

Use it when a task genuinely needs new/replacement art direction: distinctive landing/marketing/public pages, portfolios/showcases, deliberate redesign/restyle, explicitly anti-generic work, or a new app/dashboard visual world when the user requests one.

Skip it for ordinary bug fixes, responsive regressions, exact reference matching, faithful maintenance of an established design system, accessibility remediation, small visual corrections, or release QA without redesign.

Taste owns art direction only when selected. Its browser inspector and internal look/fix rounds do not replace the suite's viewport matrix, bundled visual QA, bundled accessibility QA, regression closure, or completion evidence.

If Taste selects the direction, Impeccable may critique/polish inside that direction but must not start a competing redesign unless the user explicitly reopens art direction. Do not alternate Taste and Impeccable as competing remediation loops.

Taste currently requires Node 22+ and Chrome, Edge, or Chromium for its own scripts. Do not silently install or update it from this suite's bootstrap/update scripts.

### Impeccable

Install globally for Codex after explicit approval:

```powershell
npx --yes impeccable@latest install --providers=codex --scope=global
```

Targeted update:

```powershell
npx --yes impeccable@latest update
```

Preflight compares the installed Skill frontmatter version directly with npm
`latest` before offering either mutation. The repository package manifest is
not required to match the published npm channel.

After install/update, Codex users may need to review/approve the project hook with `/hooks`.

Do not automatically initialize Impeccable in mature projects with an established design/project-memory system.

## Optional integrations

The orchestrator may use already installed:

- `karpathy-guidelines`
- `context-engineering`
- `maintain-project-memory`

Their installation and upstream sources are intentionally unmanaged here.
