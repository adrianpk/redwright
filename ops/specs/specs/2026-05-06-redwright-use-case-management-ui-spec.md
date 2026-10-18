# RedWright Use Case Management UI Specification

## Metadata

- id: `spec-2026-05-06-redwright-use-case-management-ui`
- status: `draft`
- owner: `adrianpk`
- created: `2026-05-06`
- updated: `2026-05-06`
- scope: `rails-web/use-cases/tickets/documents/quizzes/command-query/context`
- derived_from:
  - `ops/conv/quiz/2026-05-06-redwright-use-case-management-ui-quiz.md`
  - `ops/conv/quiz/2026-05-06-redwright-use-case-management-ui-quiz-raw.md`
  - `ops/tickets/solved/20260506081044-add-use-case-management-ui.md`

## Problem Statement

RedWright already uses use cases as scope for quizzes, and tickets already have a `use_case_id` model-level concept. However, use cases do not yet have a dedicated management surface or enough visible relationships to act as a practical project-local namespace.

Without a dedicated use-case surface, Quizzes risks becoming responsible for use-case administration. That is the wrong ownership boundary. Quizzes should consume use cases as context scope, not create or manage them as a side effect.

Use cases should help RedWright organize domain knowledge and agent work around functional areas of a project. They should remain simple and operationally useful, not grow into a generalized Jira-like feature hierarchy.

## Goals

- provide a dedicated Use Cases UI scoped to the current project
- keep `UseCase` as a first-class project-local entity
- require only `name` and `description` as user-managed fields
- support readable slug-based URLs without exposing slug editing in the first UI
- make use cases useful by associating tickets, documents, quizzes, and plan artifacts
- expose optional use-case selection in ticket and document editing flows
- preserve project-level tickets and documents by allowing unset use case
- show discreet per-use-case association metrics in the detail/edit surface
- provide command-query operations so agents and messaging surfaces can operate use cases
- avoid cascading deletes and disruptive association behavior
- preserve future compatibility with LLM context retrieval

## Non-Goals

- building Jira-style hierarchy, cascade behavior, or complex dependency management
- replacing tags with use cases for all classification needs
- adding many-to-many use-case join tables in the first version
- inline use-case creation from Tickets, Quizzes, or Documents
- attaching documents from inside the Use Case detail surface
- moving an existing quiz from one use case to another
- implementing dynamic search or pagination in the first Use Cases index
- defining final archive semantics
- implementing final `LLMRequestEngine` context retrieval
- designing SaaS-grade multi-user permissions

## Product Model

### UseCase

A `UseCase` is a project-local namespace for a functional or product area.

It is a first-class entity because it has stronger semantics than a tag:

- it belongs to exactly one project
- it can scope tickets
- it can scope documents
- it can own one use-case quiz
- it can group plan artifacts
- it can act as an input signal for agent context selection

Tags remain useful for flexible transversal classification, but they should not replace `UseCase`.

### Required Fields

The user-managed fields are:

- `name`, required
- `description`, required

System-managed fields should include:

- `project_id`
- `slug`, generated from name
- timestamps

`archived_at` may exist in the model later, but archive behavior is not required in the first UI unless implementation already has a clear, non-disruptive semantic.

### Slug

Use cases should support slug-based URLs because readable URLs are useful for manual entry and browser history.

The slug should be generated from `name`. It should not be exposed as a primary editable field in the first UI.

Use-case names and slugs should be unique within a project.

### Scope

The Use Cases UI is scoped by the project selected in the navbar.

When the user opens Use Cases:

- show only use cases for the selected project
- if no project is selected, falling back to the first available project is acceptable

Use cases are not global.

## Associations

The first useful implementation must include associations. A CRUD that only creates names and descriptions without linking the rest of the system would not provide enough product value.

### Direct Use Case References

Prefer direct nullable `use_case_id` references over many-to-many join tables in the first version.

This applies to entities that are primarily scoped to one use case:

- tickets
- documents
- quizzes or quiz entries where appropriate
- plan artifacts, if represented as documents/artifacts

This decision is intentional. RedWright should resist premature generalization. It is an agent orchestration tool, not a broad issue-management suite.

### Optional Scope

Tickets and documents may remain project-level by leaving `use_case_id` unset.

This is important for:

- hotfixes
- generic bugs
- global project documents
- architecture documents
- project-wide plans or specs

### Documents

Documents should be assignable to a use case from the document create/edit surface.

Do not add an `Add docs` action to the Use Case detail in the first version. The Use Case detail should remain a summary and editing surface, not a document attachment manager.

Documents should use direct `use_case_id` in the first version. A document that applies broadly should remain project-level or use tags/direct ticket attachments where appropriate.

### Tickets

Ticket create/edit should expose optional `Use Case` metadata.

Assigning a ticket to a use case scopes the ticket structurally. It does not constrain which documents may be attached to that ticket.

### Quizzes

A use-case quiz is semantically tied to its use case. There should be no UI for changing a quiz's use case after creation.

For UI metrics, showing the number of questions or quiz entries is more useful than showing quiz count, because a use case should have at most one main quiz.

### Plans and Trackers

Plans and trackers are conceptually paired: a tracker tracks a plan.

For first-version Use Case metrics, show a single `Plans` metric rather than separate plan and tracker metrics. Missing tracker behavior can be handled later when agents execute plans.

## Scope vs Attachments

Use-case scope and ticket document attachments are different context signals.

`use_case_id` is structural scope:

- it tells RedWright the primary functional area for a ticket, document, or quiz
- it helps agents discover default context
- it should remain simple and predictable

Ticket document attachments are execution-specific context:

- they may include documents from the same use case
- they may include project-level documents
- they may include documents from another use case when the task requires them

Attaching a document to a ticket must not change the ticket's use case.

Assigning a document to a use case must not automatically attach it to all tickets in that use case.

Future LLM context composition should be able to combine:

1. direct ticket context
2. ticket use case
3. documents attached to the ticket
4. documents scoped to the same use case
5. use-case quiz entries
6. project-level context

The concrete retrieval algorithm is outside this spec and should be revisited near `LLMRequestEngine` implementation.

## Web UI

### Navigation

Add `Use Cases` as a navbar item between `Protocols` and `Quizzes`.

The screen uses the current project selector as scope.

### Index

The Use Cases index should be a sober, minimalist table consistent with the rest of the site.

Ordering:

- newest use cases first

The index should not:

- show per-row delete buttons
- run per-row association checks
- show association counters in the first version
- include dynamic search or pagination in the first version

Dynamic search and pagination are likely future needs but should not block the first iteration.

Each row should expose an `Edit` action. In practice this action also opens the detail/edit surface.

### Create

Create should use a modal.

Fields:

- `name`
- `description`

Use cases should only be created from the dedicated Use Cases screen in the first version.

Other flows such as Tickets, Documents, or Quizzes should not create use cases inline.

### Detail/Edit Modal

The edit surface should also function as the practical detail surface.

Layout:

- discreet metrics at the top
- editable `name`
- editable `description`
- save action
- delete action only when allowed

Avoid decorative cards or heavy visual treatment. The surface is administrative and small.

### Metrics

The detail/edit modal should show small, discreet metrics for associations.

Expected metrics:

- tickets
- documents grouped by artifact type, such as drafts and specs
- plans
- quiz questions or quiz entries

Because the modal is scoped to a single use case, computing these metrics there is acceptable.

### Delete

Delete should live in the detail/edit modal, not in the index.

Rules:

- no cascading deletes
- if the use case has references, do not show delete
- backend must still validate deletion when attempted
- if backend blocks deletion, show a flash message
- if deletion is allowed, a browser confirmation is sufficient

Backend validation happens once per destructive intent and is preferred over repeated index-level checks.

## Command-Query Boundary

Use cases should have structured command-query operations from the start because RedWright should remain operable through Telegram or other messaging surfaces.

Minimum operations:

- `CreateUseCase`
- `UpdateUseCase`
- `DeleteUseCase`
- `ListUseCases`
- `GetUseCase`

`DeleteUseCase` must follow the same safety rules as the UI:

- no cascade
- delete only when references do not block it
- return structured errors when blocked

Telegram-specific interaction details can be refined later.

## Validation

The implementation is complete when the specified behavior works as specified.

Validation should cover:

- current-project scoped Use Cases navigation
- use-case create modal
- use-case edit/detail modal
- required `name` and `description`
- generated slug and readable URL behavior
- project-local uniqueness of names/slugs
- optional use-case selection on tickets
- optional use-case selection on documents
- use-case detail metrics
- delete hidden or blocked when references exist
- delete allowed when safe
- no cascading deletes
- flash error for blocked delete
- command-query create/update/delete/list/get behavior

## Delivery Guidance

If this spec is too broad for one implementation unit, split it.

Suggested order:

1. backend/model/business associations and tests
2. command-query operations
3. dedicated Use Cases index and create/edit/detail UI
4. ticket and document optional use-case selectors
5. metrics and delete behavior refinement

Rails-specific implementation may combine steps where strict separation would create artificial friction.

## Deferred Work

- archive semantics
- hiding archived use cases in Quizzes
- dynamic search and pagination
- many-to-many document/use-case associations
- inline use-case creation from other workflows
- document attach/detach from Use Case detail
- final LLM context retrieval algorithm
- Telegram-specific conversational flows

## Open Questions

- Exact plan/tracker representation may need refinement when RedWright formalizes internal plan and tracker artifacts.
- Archive behavior should be specified only when it has clear effects across Quizzes, Tickets, Documents, and agent context retrieval.
- `LLMRequestEngine` context use of `use_case_id` should be versioned when retrieval behavior is implemented.
