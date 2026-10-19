# Specifications Ledger

This directory stores specification artifacts produced from alignment cycles.

File types:

- `drafts/*-proto-spec-draft.md`: working specification drafts derived from discovery and Q&A.
- `../conv/quiz/*-quiz.md`: curated quiz notes paired with a draft (discussion counterpart).
- `specs/*-proto-spec.md`: refined proto-spec ready for formal execution planning.
- `specs/*-spec.md`: stabilized, review-ready specification for implementation.

Rules:

- use dated filenames: `YYYY-MM-DD-<topic>-proto-spec-draft.md`, `YYYY-MM-DD-<topic>-quiz.md`, `YYYY-MM-DD-<topic>-proto-spec.md`, and `YYYY-MM-DD-<topic>-spec.md`
- keep language in English
- for active drafting topics, maintain both a draft under `drafts/` and its quiz counterpart under `../conv/quiz/`
- update related `ops/plans/*` and `ops/trackers/*` when status changes

Templates:

- `ops/templates/spec-draft-template.md`
- `ops/templates/spec-quiz-template.md`

## Completed Delivery

- [Pi Harness](specs/2026-10-19-redwright-pi-harness-spec.md) and [model](specs/2026-10-19-redwright-pi-harness-spec-model.md).
- [Delivery plan](../plans/2026-10-19-redwright-pi-harness-cycle-plan.md) and [tracker](../trackers/2026-10-19-redwright-pi-harness-cycle-tracker.md).
- [Completed cycle report](../artifacts/2026-10-19-redwright-pi-harness-cycle-report.md): all seven slices and 21 tasks complete; unchanged full gate passed at `2c42eb5f0f921aacf355244dddfb795d907ce019`.
