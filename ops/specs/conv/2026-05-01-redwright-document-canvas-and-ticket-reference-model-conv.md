# RedWright Document Canvas and Ticket Reference Model Conversation Notes

## Status
Living discussion

## Related Draft
`2026-05-01-redwright-document-canvas-and-ticket-reference-model-draft.md`

## Purpose
Curated discussion log supporting `2026-05-01-redwright-document-canvas-and-ticket-reference-model-draft.md`.

## Sessions

### Session 2026-05-01
#### Context
- The board is an operational surface for humans and agents, not only an organizational view.
- Agents should derive priorities from board state and keep ticket status current.
- Remote operation through Telegram is part of the expected interaction model.

#### Questions Raised
- How to avoid overloading ticket content when scope is complex?
- How to represent initialization/bootstrap intents that do not fit standard task-ticket semantics?
- How to preserve exploratory reasoning while still producing formal artifacts?

#### Candidate Answers
- Introduce a document canvas with explicit artifact classes: `draft`, `spec`, `plan+tracking`.
- Keep ticket as execution trigger, but attach references to richer artifacts.
- Use `draft` for rough evolution and `spec` for formalized output.
- Keep `plan+tracking` under agent control with user-facing visual access.

#### Current Convergences
- `draft/spec/plan+tracking` is the preferred artifact taxonomy.
- `draft` and `spec` share base structure; `spec` requires higher curation.
- Promotion to `spec` does not remove the source `draft`.
- UI expansion should prioritize document visibility around the existing ticket-centric interface.

#### Open Tensions
- Boundaries of phase-one CRUD by document class remain to be specified.
- Exact behavior for board-level bootstrap intents remains undefined.
- Degree of user editability for `plan+tracking` in first phase is unresolved.

#### Provisional Decisions
- keep: Ticket remains the only task execution trigger.
- keep: Tickets can reference `spec` and potentially `plan+tracking`.
- keep: First phase should focus on docs support and readable UI, not conversational in-app automation.
- unsure: Future conversational flow may generate `draft` or direct `spec`, then `plan+tracking`.

#### Deferred / Out of Scope
- Full conversational authoring loop integrated into the app.
- Agent autonomy features beyond current phase scope.

## Open Questions
- What are the minimal lifecycle states for each document type?
- Which links are mandatory on ticket creation: `spec`, `plan`, or optional?
- What is the migration path from current ticket-only flows?

## Edit Notes
- This file is intentionally curated and non-final.
- Keep useful reasoning; remove irrelevant detours.
