# RedWright Ticket Context Inheritance, Use Case, and Evidence Model Quiz Notes

## Status
Living quiz

## Related Draft
`../specs/drafts/2026-05-06-redwright-ticket-context-inheritance-use-case-document-model-draft.md`

## Purpose
Curated quiz notes supporting a future revision of the ticket context inheritance and use-case document model.

## Sessions

### Session 2026-05-07
#### Context
- The existing exploratory draft proposed moving formal context ownership toward `UseCase`.
- The follow-up discussion refined that direction by distinguishing formal artifacts from ticket-specific evidence assets.
- The immediate implementation target should be association-model simplification, not final LLM context construction.

#### Questions Raised
- Whether tickets with a use case should still attach formal documents directly.
- Whether ticket-specific additional context should be treated as formal context or as a separate asset/evidence category.
- Whether evidence assets should be attachable to tickets, use cases, and projects from the beginning.
- How project-level formal artifacts should behave for tickets with and without a use case.
- What the ticket UI should show after removing formal document selection.
- Whether runtime context injection belongs in the same spec.

#### Candidate Answers
- `UseCase` should be the primary owner of scoped formal context.
- Tickets may belong to a use case, but tickets without a use case remain valid project-level work items.
- Tickets should no longer manually attach formal artifacts such as drafts, specs, plans, trackers, or quizzes.
- Ticket-specific additional material should be modeled separately as evidence/assets, not as formal documents.
- Evidence/assets are deferred and should not be implemented in the immediate UI.
- Empty use-case selection means project-level scope.
- Use-case selection on a ticket is a transitive association, not a process that copies or attaches use-case documents onto the ticket.

#### Current Convergences
- Formal artifacts created inside a use case should automatically belong to that use case.
- Formal artifacts created without a use case should belong to the general project context.
- Tickets with a use case inherit formal context transitively through that use case.
- Tickets without a use case use project-level formal context.
- Tickets with a use case should probably also have access to project-level formal context because general definitions are often relevant.
- The ticket UI should move the use-case selector higher and remove the formal document selector.
- The first version should not show an inactive placeholder for future evidence uploads.
- There is no compatibility-heavy migration requirement because RedWright is currently a personal development app, not a launched SaaS product.

#### Open Tensions
- Whether all project-level formal artifacts should always be available to use-case tickets or whether later context services should filter them.
- How the current database/UI model represents each formal artifact type and whether any existing implementation details already constrain the association model.
- Whether evidence/assets should later attach only to tickets or also become useful at use-case or project scope.

#### Provisional Decisions
- `keep`: `UseCase` as the scoped owner of formal artifacts.
- `keep`: optional ticket `use_case_id`; `nil` means project-level.
- `keep`: remove ticket-level formal document selection from the ticket UI.
- `keep`: use-case selection should be visually higher in the ticket UI than the current document association area.
- `keep`: ticket-specific additions should be evidence/assets, not formal artifacts.
- `defer`: evidence/assets uploader and processing.
- `defer`: LLMRequestEngine context-shaping and semantic priority rules.
- `defer`: image, PDF, and other asset analysis.
- `review`: current model representation before finalizing the exact artifact types included in the first implementation.

#### Deferred / Out of Scope
- Implementing ticket evidence/assets.
- Processing images, PDFs, or arbitrary uploads.
- Defining final LLM context section shape.
- Defining prompt priority between ticket body, project context, use-case context, and future evidence.
- Runtime inheritance during ticket execution.
- Compatibility migration for external users or SaaS tenants.

## Open Questions
- Which formal artifact types are currently represented in the app model versus only as repository files?
- Should project-level formal artifacts be always available to use-case tickets in v1, or merely associated so a future context service can decide?
- What is the smallest implementation slice that removes ticket formal document selection without blocking current ticket workflows?
- Should the existing exploratory draft be revised directly, or should a new formal spec supersede it?

## Edit Notes
- This file is intentionally curated and non-final.
- Keep useful reasoning; remove irrelevant detours.
