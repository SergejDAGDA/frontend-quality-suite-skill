---
name: frontend-accessibility-qa
description: Bundled accessibility specialist for browser-facing UI. Uses WCAG 2.2 Level A/AA as the hard compliance authority, with APCA only as an optional perceptual design advisory. Supports design-time guards, affected-surface audits, and full release/accessibility audits without reopening completed remediation loops for advisory-only findings.
---

# Frontend Accessibility QA

## Role

This skill is the accessibility specialist bundled with the Frontend Quality Suite.

It is responsible for:

- accessibility checks while UI is being designed or modified;
- scope-sensitive verification after implementation;
- WCAG 2.2 A/AA audit evidence;
- color and non-text contrast checks;
- keyboard, focus, semantics, zoom/reflow and assistive-technology evidence when required;
- preventing APCA or aesthetic advice from overriding normative WCAG failures.

It does not replace browser testing or visual QA. It supplies accessibility authority and evidence to the orchestrator.

## Normative authority

Use **WCAG 2.2 Level A and AA** as the hard accessibility gate whenever WCAG accessibility is in scope.

Project-specific accessibility or legal requirements may be stricter and therefore add requirements.

Do not turn a known WCAG 2.2 A/AA failure into a pass because:

- APCA looks acceptable;
- the design system prefers the color;
- the visual reference uses the same pattern;
- automated tooling did not report it;
- the issue is inconvenient to fix.

WCAG 3 is a developing specification and is not the conformance authority for this skill.

## APCA policy

APCA is an optional perceptual design signal, not a compliance authority.

Use APCA only when a reliable current implementation or project-approved calculator is available and the result materially helps color/palette decisions.

Do not implement or maintain an APCA formula inside this skill.

Do not hard-code APCA as a release gate.

Decision table:

| WCAG 2.2 AA | APCA | Result |
|---|---|---|
| PASS | PASS | pass |
| PASS | advisory concern | WCAG pass; record advisory and refine at most once if useful |
| FAIL | PASS | blocker; fix WCAG |
| FAIL | concern | blocker; fix WCAG |
| PASS | unavailable | pass; APCA absence does not block WCAG closure |

An APCA-only advisory must not reopen a completed hard-gate remediation loop more than once unless it exposes new evidence of a WCAG failure, functional defect, or explicit project requirement.

Never accept an APCA-driven color change that creates a WCAG failure.

## Authority order

When guidance conflicts, use this order:

1. explicit project accessibility/legal requirements that are stricter than the baseline;
2. WCAG 2.2 A/AA hard requirements;
3. functional/browser correctness;
4. established project design system and approved visual direction;
5. APCA perceptual guidance;
6. aesthetic preference.

A lower-priority source cannot invalidate a higher-priority pass.

## Audit modes

Choose the smallest mode that fully covers the change.

### DESIGN_GUARD

Use during design/implementation when a decision can create accessibility debt.

Examples:

- foreground/background colors;
- text, icon, border, focus-ring and control states;
- semantic element choice;
- keyboard interaction design;
- target sizing;
- error/help presentation;
- animation/reduced-motion behavior.

Check only the affected criteria and states before committing to the design.

For color work, evaluate the actual foreground/background pair and all meaningful states, not isolated palette swatches.

### AFFECTED_AUDIT

Use after a scoped browser-facing change.

Verify the changed component/route and representative consumers.

Examples:

- color-token change;
- button/input component change;
- modal or navigation change;
- new form control;
- interaction or focus behavior;
- typography/reflow change;
- animation with accessibility implications.

Run the relevant manual and automated checks for the affected criteria.

### FULL_AUDIT

Use for:

- new substantial UI;
- explicit accessibility/WCAG audit requests;
- release preparation where accessibility is part of acceptance;
- broad design-system changes;
- a substantial accessibility remediation program.

A full audit requires the four evidence passes below.

## Full audit evidence passes

### 1. Automated scan

Use an existing project scanner or browser-compatible accessibility scanner when available.

Examples include axe-based tooling, Lighthouse accessibility checks, or an equivalent project-standard scanner.

Do not add a new package dependency merely to run a scan unless the project/user approves it.

Automated success is evidence, not proof of complete WCAG conformance.

### 2. Keyboard and focus pass

Exercise the real flow without pointer input where applicable.

Verify:

- interactive elements are reachable;
- focus order is logical;
- visible focus is preserved;
- no keyboard trap exists;
- overlays can be operated and dismissed appropriately;
- focus is restored when required;
- focused controls are not obscured by sticky/fixed UI;
- bypass/skip mechanisms work when required.

### 3. Contrast, color and zoom/reflow pass

Verify applicable WCAG 2.2 criteria, including:

- 1.4.1 Use of Color;
- 1.4.3 Contrast (Minimum);
- 1.4.10 Reflow;
- 1.4.11 Non-text Contrast;
- 1.4.12 Text Spacing;
- 1.4.13 Content on Hover or Focus.

For WCAG text contrast:

- normal text: at least 4.5:1;
- qualifying large text: at least 3:1.

For required non-text UI/graphical contrast under 1.4.11, use the WCAG 2.2 requirement and its exceptions; do not blindly apply text thresholds to every decorative border.

Check actual rendered states and backgrounds.

If APCA is used, run it only after the WCAG gate has been established.

### 4. Semantics and assistive-technology pass

Use semantic HTML first.

Verify as applicable:

- page language;
- landmarks and headings;
- meaningful sequence;
- labels/instructions;
- accessible names;
- name/role/value;
- alt text or intentionally empty alt;
- status/live-region announcements;
- error identification and suggestions;
- dialog/menu/tab semantics;
- route/state changes.

For a full conformance claim, use an available screen reader or equivalent assistive-technology evidence for the relevant flow.

If that evidence cannot be obtained, report it as NOT VERIFIED rather than claiming full conformance.

## WCAG 2.2 criteria that deserve explicit attention

Do not forget the WCAG 2.2 additions commonly missed by older 2.1-oriented checklists:

- 2.4.11 Focus Not Obscured (Minimum);
- 2.5.7 Dragging Movements;
- 2.5.8 Target Size (Minimum);
- 3.2.6 Consistent Help;
- 3.3.7 Redundant Entry;
- 3.3.8 Accessible Authentication (Minimum).

Do not report 4.1.1 Parsing as a WCAG 2.2 conformance failure.

Read `references/wcag-2.2-aa-checklist.md` for the maintained A/AA checklist.

## Color and component-state policy

When selecting or changing color-dependent UI, test the semantic pair, not just the raw token.

At minimum consider applicable states:

- default;
- hover;
- focus;
- active/pressed;
- selected;
- disabled when information still needs to be perceivable;
- error/warning/success;
- visited links when used;
- light/dark themes;
- forced/high-contrast or project-specific accessibility themes when supported.

For shared color tokens or design-system changes, expand verification to representative consumers.

Color must not be the only means of communicating state or meaning when WCAG 1.4.1 applies.

## Scope-sensitive routing

Examples:

| Change | Minimum accessibility scope |
|---|---|
| href/metadata only | targeted semantic/functional check |
| text color only | affected WCAG contrast pair; APCA advisory optional |
| shared semantic color token | all affected semantic pairings and representative consumers |
| button/input primitive | contrast, focus, keyboard, name/role/value, target size, states |
| modal/menu/navigation | keyboard, focus management, semantics, visible states |
| form | labels, instructions, errors, keyboard, status, redundant entry where applicable |
| drag/reorder | keyboard/single-pointer alternative and 2.5.7 |
| animation | reduced motion, keyboard/touch implications, settled layout |
| release / explicit WCAG audit | FULL_AUDIT |

Promote the scope when shared primitives or broad tokens are affected.

## Remediation and anti-loop rule

Fix evidenced hard failures.

After a remediation:

1. rerun the affected WCAG check;
2. rerun browser/visual checks invalidated by the change;
3. if the fix changes shared tokens/components, broaden to representative consumers.

APCA-only or aesthetic findings are improvements after WCAG passes.

They must not cause repeated color oscillation between two acceptable designs.

If two remediation rounds on the same accessibility goal fail, stop incremental tweaking and diagnose the common root cause before a third round.

## Reporting

Classify findings consistently:

- **BLOCKER** — evidenced WCAG 2.2 A/AA failure or accessibility safety failure in current scope;
- **ENVIRONMENT** — required browser/tool/assistive-technology evidence cannot be obtained;
- **IMPROVEMENT/FUTURE** — APCA-only or non-required quality improvement;
- **NOT VERIFIED** — evidence is incomplete or only inferred.

For each blocker report:

- criterion number/name when applicable;
- affected element/state/route;
- evidence;
- fix;
- re-verification result.

Do not claim "WCAG 2.2 AA compliant", "accessible", or equivalent broad conformance unless the claimed scope and required evidence actually support it.

## References

Read:

- `references/wcag-2.2-aa-checklist.md`
- `references/contrast-policy.md`
- `references/evidence-and-scope.md`

Normative source:

- https://www.w3.org/TR/WCAG22/
