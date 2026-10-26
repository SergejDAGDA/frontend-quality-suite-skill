# Accessibility Evidence and Scope

## Use the smallest complete audit mode

### DESIGN_GUARD

Use before or during implementation when a decision can create an accessibility defect.

Typical checks:

- semantic element choice;
- color pair and states;
- focus treatment;
- target size;
- keyboard path;
- error/help design;
- reduced motion.

### AFFECTED_AUDIT

Use after scoped changes.

Test the changed component/route plus representative consumers when a shared primitive changed.

### FULL_AUDIT

Use for major new UI, explicit WCAG audit, release acceptance, broad design-system changes, or a substantial remediation program.

## Full-audit evidence

A full audit should cover:

1. automated scan;
2. keyboard/focus pass;
3. color/contrast + zoom/reflow + text spacing;
4. semantics/assistive-technology pass.

A green scanner alone is insufficient.

If a required assistive-technology or browser environment is unavailable, classify the missing proof as ENVIRONMENT or NOT VERIFIED.

## State coverage

Accessibility defects often exist only in non-default states.

Exercise applicable:

- hover;
- focus;
- active/pressed;
- selected;
- expanded/collapsed;
- disabled;
- loading;
- success/error/warning;
- validation failure;
- modal open/close;
- menu open/close;
- drag/reorder alternatives;
- asynchronous updates.

## Responsive coverage

Accessibility and responsive behavior interact.

At affected viewports verify:

- zoom/reflow does not create inaccessible horizontal scrolling where prohibited;
- focus indicators remain visible;
- sticky/fixed UI does not obscure focus;
- touch targets remain usable;
- responsive navigation retains keyboard and semantic behavior;
- reordered visual layout does not produce a misleading focus/reading order.

Use the orchestrator's viewport policy for breadth. Accessibility does not create a second independent viewport matrix.

## Reporting scope

Never convert a component-level check into a site-wide conformance claim.

State:

- exact scope;
- WCAG level;
- routes/components/states;
- automated tool if used;
- manual keyboard method;
- screen reader/assistive technology if used;
- browser/viewports;
- blockers;
- unverified areas.

## Regression closure

An accessibility fix can invalidate visual or interaction verification.

Examples:

- larger target changes layout;
- stronger focus ring changes geometry/clipping;
- contrast fix changes shared tokens;
- semantic control replacement changes native styling/behavior;
- keyboard fix changes focus management;
- reduced-motion fix changes transition behavior.

After such fixes, rerun the affected frontend-production-qa and frontend-visual-qa checks.
