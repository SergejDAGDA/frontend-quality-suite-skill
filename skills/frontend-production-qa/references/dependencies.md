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

Use one explicit approval for the known missing REQUIRED set. RECOMMENDED
and OPTIONAL components are opt-in. Do not automatically update or replace
an independently maintained bundle when its upstream repository changes.

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

Official installer:

```powershell
npx motion-ai
```

Official upgrade path:

```powershell
npx motion-ai@latest
```

Treat this as a **conditional external recommendation**, not as a required or bundled dependency. The installer can write skill files and MCP configuration, so do not run it silently from this plugin's bootstrap or updater.

Use the specialist for substantial animation, transition orchestration, layout motion, gestures, drag/reorder, scroll-linked effects, springs, Motion API work, or animation performance diagnostics. Prefer CSS when CSS is sufficient.

Do not install the Motion runtime package solely because the agent skill is present. Project dependency policy remains authoritative.

### Impeccable

Install globally for Codex:

```powershell
npx impeccable install --providers=codex --scope=global
```

Check/update:

```powershell
npx impeccable check
npx impeccable update
```

After install/update, Codex users may need to review/approve the project hook with `/hooks`.

Do not automatically initialize Impeccable in mature projects with an established design/project-memory system.

## Optional integrations

The orchestrator may use already installed:

- `taste-skill`
- `karpathy-guidelines`
- `context-engineering`
- `maintain-project-memory`

Their installation and upstream sources are intentionally unmanaged here.
