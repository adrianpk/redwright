# RedWright Use Case Management UI Quiz Notes

## Status
Curated quiz

## Related Spec
`ops/specs/specs/2026-05-06-redwright-use-case-management-ui-spec.md`

## Raw Capture
`ops/quiz/2026-05-06-redwright-use-case-management-ui-quiz-raw.md`

## Purpose
Capture the decisions behind RedWright's dedicated Use Case management surface and its minimal associations with tickets, documents, quizzes, plans, and agent context.

## Context
Use cases already exist as a project-scoped concept in the Quiz system, but they do not yet have a dedicated management surface. Quizzes should consume use cases as scope, not own their creation or administration.

The session clarified that a use case is not just a UI nicety. It is a project-local namespace that helps agents and the LLM context machinery understand the functional area of work.

## Current Convergences

### Use Case as Entity
- `UseCase` should remain a first-class entity, not collapse into tags.
- Tags remain useful for flexible transversal classification, but a use case needs stable identity, project scope, and explicit relationships.
- The model should stay simple and resist premature generalization. RedWright is an agent orchestration tool for solving software work, not a Jira replacement.

### Minimal Fields
- Required use-case fields are `name` and `description`.
- Standard Rails timestamps are enough for audit.
- A generated `slug` is desirable for readable URLs and browser history, but it should not become an editable concern in the first UI.
- Names should be unique within a project to avoid human and operational confusion.

### Project Scope
- Use Cases are scoped by the project selected in the navbar.
- The Use Cases screen should show only the current project's use cases.
- If no project is selected, using the first available project as fallback is acceptable to keep navigation simple.

### Associations
- A use case can group tickets, documents, one use-case quiz, and plan artifacts.
- The spec must include associations; otherwise the CRUD is empty and not useful.
- Direct `use_case_id` references are preferred over join tables for the first version.
- Documents and tickets can remain project-level by leaving use case unset.
- Quiz association is semantic: a use-case quiz should not be moved to a different use case.

### Scope vs Attachments
- `use_case_id` and ticket document attachments serve different purposes.
- `use_case_id` is structural scope and helps build default context for agents.
- Ticket document attachments are execution-specific context and may include documents outside the ticket's use case.
- Assigning a document to a use case should not attach it to all tickets in that use case.
- Attaching a document to a ticket should not change the ticket's use case.
- The agent and `LLMRequestEngine` should later connect these context signals when building task context.

### UI Shape
- Add a dedicated `Use Cases` navbar item between `Protocols` and `Quizzes`.
- The index should be a visually harmonious, minimalist table ordered newest first.
- The index should not show delete buttons, per-row reference counters, or association checks.
- Search, Turbo Stream filtering, and pagination are likely needed later, but not in the first iteration.
- Create/edit should use modals, consistent with current site patterns.
- The edit/detail modal should show small metrics discreetly at the top, then editable `name` and `description`.
- Delete belongs in the detail/edit surface, not the index.

### Delete Behavior
- No cascading deletes.
- A use case with references should not be physically deleted.
- The backend should validate delete only when the user actually attempts deletion.
- The UI should not run per-row association checks on every index render.
- If delete is blocked, show a flash message.
- If delete is allowed, a classic browser confirmation is enough for the first implementation.
- Archive behavior may exist later, but should not be forced into the first UI without clear semantics.

### Metrics
- The detail/edit surface should show metrics for associated records.
- Documents should be grouped by artifact type, such as drafts and specs.
- Quiz metric should prefer question count over quiz count because there should be one quiz per use case.
- Plans can be shown as a single metric; tracking is considered intrinsic to a plan and can be handled later when agents execute plans.

### Integration Points
- Ticket create/edit should expose optional `Use Case` metadata.
- Document create/edit should expose optional `Use Case` metadata.
- Quizzes should not create use cases inline.
- Other flows should not create use cases inline in the first version.
- Important operations should have command-query coverage to support Telegram and agent-driven operation.

## Provisional Delivery Shape
- If the scope remains broad, split into slices.
- Prefer backend/model/business support first.
- Then build the dedicated Use Cases UI.
- Ticket and document selectors can follow in later slices.
- Rails-specific coupling can be tolerated where separating backend and UI would create artificial friction.

## Deferred / Out of Scope
- Use-case archive semantics.
- Inline use-case creation from tickets, quizzes, or documents.
- Attach-docs UI inside the Use Case detail.
- Dynamic search and pagination.
- Join tables for many-to-many use-case associations.
- Moving quizzes between use cases.
- Final LLM retrieval implementation.
- Telegram-specific refinements beyond command-query readiness.

## Open Questions
- Exact implementation shape for plan/tracker artifacts may need refinement when RedWright formalizes plans and trackers internally.
- Archive semantics should be revisited when archived use cases have clear behavior in Quizzes, Tickets, and agent context retrieval.
- LLM context retrieval should revisit `use_case_id` as a signal when implementation reaches the `LLMRequestEngine` integration point.

