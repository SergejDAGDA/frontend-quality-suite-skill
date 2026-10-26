# Toolchain Maintenance

## Principle

External specialists are runtime capabilities, not documentation assumptions.

The orchestrator must determine the exact specialist set required by the current frontend task and run a live preflight before first use. A user does not need to know which specialist is missing, stale, disabled, duplicated, or inactive in order for the orchestrator to surface that condition.

No external specialist version is stored as "current" in this repository.

`specialists.json` stores only:

- exact Skill ID(s);
- provider/repository identity;
- required/recommended class;
- install/update channel;
- live author version/payload source;
- optional official distribution version source;
- activation/reload requirements.

Currentness must be read live from the provider at task time.

Historical changelog entries and prior conversations are never freshness evidence.

## Task-scoped preflight

Primary command:

```powershell
.\scripts\preflight-frontend-specialists.ps1 -SkillId <exact-skill-id>
```

Multiple `-SkillId` values may be supplied. With no Skill ID, the script checks the required external base specialists. `-All` checks every managed external specialist.

The orchestrator should:

1. classify the frontend task;
2. derive the exact required/triggered specialist set;
3. run preflight once per selected provider in the current session;
4. surface missing/stale/conflicting/unverified states before the corresponding phase;
5. offer the exact provider-specific install/update when appropriate;
6. mutate only after explicit user approval;
7. rerun postflight after mutation;
8. require a fresh Codex session when the provider/install channel needs reload;
9. resolve the exact Skill ID in that fresh session before claiming it ran.

Do not preflight unrelated recommended specialists merely because they exist in the registry.

## Status semantics

### INSTALLED_CURRENT

Package/payload matches the current live author source.

This is package-level evidence only. The current Codex Desktop session must still resolve the exact Skill ID before use.

### UPDATE_AVAILABLE

The installed semantic version is older than the author's current live version.

Offer the provider-specific update before use.

### UPDATE_RECOMMENDED

Used when an installed payload differs from the author's current payload but the installed skill does not expose a reliable local semantic version.

This is currently the Motion model. Do not invent an installed version number.

### MISSING / MARKETPLACE_MISSING

The specialist or its required native marketplace is absent.

Offer the exact author-owned install path.

### DISABLED

Native registration exists but is disabled.

Do not treat it as usable. Resolve it in the native provider flow and start a fresh session.

### CONFLICT

Duplicate Skill IDs, duplicate native records, owner mismatch, catalog mismatch, or another hard ambiguity exists.

Do not install/update or select a winner by path order.

### PROVENANCE_UNKNOWN

A package exists but its author-owned marketplace/source cannot be verified.

Do not call it current or safe to update.

### SOURCE_DIVERGENCE

The author's source manifest and the official install distribution disagree.

Do not guess which is current. Inspect provider release/install guidance.

### UNKNOWN_REMOTE / UNKNOWN_DISTRIBUTION / UNKNOWN_LOCAL / DIFFERENT

Evidence is incomplete or cannot be safely ordered.

Do not convert these states into CURRENT or OUTDATED.

### INSTALLED_NOT_ACTIVE

This is an orchestrator/runtime state rather than a filesystem-script result.

If package-level preflight passes but the current Codex session cannot resolve the exact Skill ID, require a fresh session and do not claim that specialist phase ran.

## Live provider adapters

### addyosmani/agent-skills

Owns:

- `frontend-ui-engineering`
- `browser-testing-with-devtools`

Channel:

- native Codex plugin `agent-skills@agent-skills`

Author source:

- `addyosmani/agent-skills`
- live `plugin.json`

Installation/update uses the exact author-owned marketplace/plugin only.

No remembered Agent Skills version is authoritative.

### Taste Skill

Owns current Skill ID:

- `design-taste-frontend`

Repository/plugin:

- `Leonxlnx/taste-skill`
- native plugin `taste-skill@taste-skill`

The directory/plugin name `taste-skill` is not the Skill ID.

Author source:

- live `.codex-plugin/plugin.json`

Use the native Codex plugin channel. Verify marketplace Git origin and catalog source before install/update.

### Impeccable

Skill ID:

- `impeccable`

Author source:

- live `pbakaus/impeccable/package.json`

Official install distribution:

- current npm `impeccable` metadata

Installed version evidence:

- `metadata.version` in the discovered `impeccable` Skill frontmatter

The author manifest and npm distribution must agree before an automatic update is offered.

Approved install:

```powershell
npx --yes impeccable@latest install --providers=codex --scope=global
```

Approved update:

```powershell
npx --yes impeccable@latest update
```

After install/update, inspect `/hooks` in Codex because hook trust may need renewed approval.

### Motion AI Kit

Skill ID:

- `motion`

Author source:

- `motiondivision/ai-kit`
- live `packages/motion-ai/package.json`
- live `plugins/motion/skills/motion/SKILL.md`

Official install distribution:

- current npm `motion-ai` metadata

The installed Motion Skill does not expose a reliable local semantic version. Therefore preflight compares normalized Skill payload content with the author's current payload and reports `UPDATE_RECOMMENDED` when they differ.

Do not invent or persist a local Motion version.

Approved install/update:

```powershell
npx motion-ai@latest
```

The installer is interactive. Choose the intended scope and Codex target. It may also update hosted MCP configuration.

Afterward start a fresh Codex session and verify the `motion` Skill and required Motion MCP capability before relying on them.

### Bundled QA specialists

`frontend-visual-qa` and `frontend-accessibility-qa` are bundled with this plugin.

They are versioned with `frontend-production-qa` and are not compared to floating upstream copies during task-time preflight.

Do not replace either bundled skill directly from another repository.

## Read-only commands

### Local readiness

```powershell
.\scripts\check-frontend-toolchain.ps1
```

This remains a quick local filesystem/CLI readiness diagnostic. It does not replace live task-scoped version/provenance preflight.

### Unified update evidence

```powershell
.\scripts\check-frontend-updates.ps1
```

This delegates to:

```powershell
.\scripts\preflight-frontend-specialists.ps1 -All
```

It performs no mutation.

### Native package/source planning

```powershell
.\scripts\plan-frontend-dependencies.ps1
```

This older helper remains useful for native plugin/source inventory and repository-identity diagnostics, especially installation of the frontend plugin itself.

It is not the primary task-time freshness checker.

### Bootstrap compatibility helper

```powershell
.\scripts\bootstrap-frontend-toolchain.ps1
```

This remains read-only. It points to the current preflight/manager flow rather than installing multiple components.

### Legacy selected updater

```powershell
.\scripts\update-frontend-toolchain.ps1 -Component <component>
```

This compatibility planner remains read-only and its old `-Apply` path stays blocked.

## Approved single-specialist mutation

Do not maintain a second custom package manager.

When live preflight reports `MISSING`, `MARKETPLACE_MISSING`, `UPDATE_AVAILABLE`, or `UPDATE_RECOMMENDED`, the orchestrator should show the user the exact official provider action from `specialists.json`.

Only after explicit approval for that exact specialist/action may the orchestrator execute it directly.

For native Codex-plugin providers:

1. if the expected marketplace is missing, add only the exact author repository declared in the registry;
2. verify the marketplace Git origin and catalog plugin source against the expected author repository;
3. for an update, refresh only that named marketplace;
4. materialize only the exact plugin ID;
5. rerun live preflight.

For provider CLI/installers:

1. use only the exact executable/arguments from the registry;
2. keep `@latest` where declared;
3. never substitute an alternate installer or locally cached remembered version;
4. rerun live preflight after completion.

Safety properties:

- exactly one provider/action per approved mutation;
- no global or unnamed marketplace upgrade;
- live author version/payload evidence required;
- distribution/source divergence blocks mutation;
- duplicate Skill IDs block mutation;
- native plugin marketplace Git origin/catalog ownership is checked before mutation;
- package-level postflight is required;
- a fresh-session requirement is reported and enforced before claiming the Skill ran;
- transactional rollback is **not** claimed.

If a provider command fails after partially mutating state, treat recovery as a separate explicit task. Do not silently retry with another source or broaden the update scope.

## Why mutation still requires consent

The earlier native Codex rollback lab showed that named marketplace refresh can materialize a new package and prune an old cache without a proven transactional rollback of package activation/configuration.

That finding still matters.

v1.5.0 does **not** restore broad automatic updates. Instead it permits a narrower operation after explicit approval:

- one exact provider;
- verified current author source;
- verified owner/provenance where applicable;
- provider-native install/update path;
- postflight;
- no rollback claim.

This is intentionally different from silently updating everything in the background.

## Required vs recommended behavior

If a required specialist is missing/stale and the user declines the proposed correction, the task may continue only with explicitly reduced/stale coverage. Do not claim current-toolchain verification.

If a triggered recommended specialist is missing/stale and the user declines, skip it or use a bounded fallback and report reduced specialist coverage.

Never omit a selected specialist silently.

## Chrome DevTools MCP

Chrome DevTools MCP remains a separate runtime capability.

Registration evidence alone does not prove process startup, browser connection, or current-session availability. Verify those during the browser phase.

Do not conflate MCP runtime updates with Agent Skill package updates.

## Safety invariants

- No pinned current versions for external specialists.
- No broad update-all fallback.
- No mutation without explicit user approval.
- No duplicate Skill ID winner chosen by traversal order.
- No marketplace-name-only trust.
- No cache path treated as active-session proof.
- No `UNKNOWN` converted to `CURRENT`.
- No direct replacement of bundled QA specialists.
- No claim of rollback capability without an actual restore test.
