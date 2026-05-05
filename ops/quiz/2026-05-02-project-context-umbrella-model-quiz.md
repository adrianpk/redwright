# Project Context Umbrella Model Quiz Notes

## Status
Living quiz

## Related Draft
`2026-05-02-project-context-umbrella-model-draft.md`

## Purpose
Curated quiz log supporting `2026-05-02-project-context-umbrella-model-draft.md`.

## Sessions

### Session 2026-05-02
#### Context
- Current operational entities (boards, tickets, documents) are useful but disconnected from a shared project anchor.
- The objective is to improve coherence and context retrieval without over-committing to heavy multi-tenant semantics.

#### Questions Raised
- Should `Project` be introduced as umbrella aggregate for core artifacts?
- Which fields should stay fixed in `projects` vs move to a dynamic structure?
- Is duplicating `project_id` across rows pragmatic acceleration or unnecessary denormalization?

#### Candidate Answers
- Keep `Project` minimal and stable (`name`, `description`, `root_path`, `repo_url`, `stack_slug`).
- Move flexible descriptors into a `project_attributes` one-to-many structure.
- Use weighted attributes to rank context relevance for runtime reasoning.
- Roll out ticket-level `project_id` in phases, based on observed query pressure.

#### Current Convergences
- A project umbrella is needed to prevent entity drift.
- Dynamic project attributes are preferred over aggressive fixed-schema expansion.
- Context partitioning is valuable even without full tenant semantics.

#### Open Tensions
- How strict key governance should be for dynamic attributes.
- Whether weight ownership should be user-driven, agent-driven, or mixed.
- When ticket-level duplicated project context becomes justified.

#### Provisional Decisions
- `keep`: Introduce `Project` as root context aggregate.
- `keep`: Introduce dynamic `project_attributes` with `weight`.
- `keep`: Apply phased project linkage strategy for tickets.

#### Deferred / Out of Scope
- UI/UX details for project switching.
- Full migration mechanics and rollback playbook.
- Final multi-tenant policy boundaries.

## Open Questions
- What key naming convention should govern `project_attributes.key`?
- Should there be a bounded catalog of recommended keys from day one?
- Which query paths in runtime need direct `tickets.project_id` most urgently?

## Edit Notes
- This file is intentionally curated and non-final.
- Keep useful reasoning; remove irrelevant detours.
