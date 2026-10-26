# Contrast Policy

## Purpose

Use WCAG 2.2 A/AA as the hard accessibility authority and APCA only as an optional perceptual design advisor.

This prevents two contrast models from becoming competing release gates.

## Hard/soft arbitration

| WCAG | APCA | Classification | Action |
|---|---|---|---|
| PASS | PASS | PASS | keep |
| PASS | concern | IMPROVEMENT/FUTURE | optionally refine once |
| FAIL | PASS | BLOCKER | fix WCAG |
| FAIL | concern | BLOCKER | fix WCAG |
| PASS | unavailable | PASS | do not block |

APCA cannot waive WCAG.

APCA cannot force a change that creates a WCAG failure.

An APCA-only concern must not repeatedly reopen an already closed WCAG remediation loop.

## Design-time color checks

When choosing a foreground/background combination:

1. identify the semantic role and actual rendered background;
2. identify text size/weight and relevant WCAG criterion;
3. check required WCAG contrast;
4. check meaningful interaction/status states;
5. check that color is not the sole carrier of meaning where 1.4.1 applies;
6. only after WCAG passes, optionally inspect APCA for perceptual quality;
7. prefer a refinement that preserves the existing design system and all hard gates.

For transparent overlays, gradients, images, alpha blending, or dynamic surfaces, test the effective rendered pair in the real browser.

## Shared tokens and themes

A token is not accessible in isolation.

For semantic or shared tokens, verify the actual pairings:

- text-on-surface;
- muted text-on-surface;
- link states;
- button labels/backgrounds;
- focus indicators;
- input borders and error states;
- icon/control states;
- selected/active states;
- light/dark themes;
- project-specific high-contrast themes when supported.

A shared token change can broaden verification to many consumers.

## APCA implementation boundary

This repository does not implement APCA mathematics.

If APCA is desired:

- use a current, project-approved calculator/library/tool;
- record the tool/version when the result matters;
- treat the result as advisory unless the project explicitly has an additional APCA design requirement;
- even under a project-specific APCA requirement, WCAG 2.2 remains a separate hard gate when WCAG conformance is in scope.

Do not copy a third-party APCA threshold table into the compliance rules and treat it as stable normative WCAG guidance.

## Anti-loop rule

Once a color pair passes all hard requirements, an advisory-only change gets at most one refinement cycle by default.

A second advisory-only request to change the same pair should be recorded as a design preference unless new evidence shows:

- a WCAG failure;
- a functional defect;
- an explicit stricter project requirement.

This prevents oscillation between two perceptually acceptable color choices.
