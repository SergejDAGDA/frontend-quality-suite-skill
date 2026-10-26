## Frontend workflow

For tasks that create, modify, fix, review, test, or prepare user-facing browser UI, use the `frontend-production-qa` skill.

This includes HTML, CSS, responsive layout, browser-side JavaScript, navigation, forms, interactive components, animation, transitions, gestures, accessibility, visual fixes, frontend regressions, and frontend release preparation.

Do not apply this workflow to backend-only, database-only, infrastructure-only, data-processing, or documentation-only work unless the change directly affects rendered browser behavior.

Keep project-specific architecture, product, legal, accessibility, design, release and project-memory constraints in this `AGENTS.md`.

Let `frontend-production-qa` route accessibility-sensitive work through the bundled `frontend-accessibility-qa` specialist. WCAG 2.2 A/AA remains the hard gate when in scope; APCA is advisory and must not override WCAG or established project requirements.

Do not install, update, or repair third-party frontend skills during normal development work. Toolchain bootstrap and updates are explicit maintenance operations.
