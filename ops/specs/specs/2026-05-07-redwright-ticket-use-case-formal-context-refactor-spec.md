# RedWright Ticket Use Case Formal Context Refactor Specification

## Metadata

- id: `spec-2026-05-07-redwright-ticket-use-case-formal-context-refactor`
- status: `draft`
- owner: `adrianpk`
- created: `2026-05-07`
- updated: `2026-05-07`
- scope: `rails-web/tickets/use-cases/documents/quizzes/formal-context`
- derived_from:
  - `ops/specs/drafts/2026-05-06-redwright-ticket-context-inheritance-use-case-document-model-draft.md`
  - `ops/conv/quiz/2026-05-07-redwright-ticket-context-inheritance-use-case-evidence-model-quiz.md`
  - `ops/conv/quiz/2026-05-07-redwright-ticket-context-inheritance-use-case-evidence-model-quiz-raw.md`
  - `ops/specs/specs/2026-05-06-redwright-use-case-management-ui-spec.md`

## Problem Statement

The current ticket model has two competing context mechanisms:

- tickets can belong to a `UseCase`
- tickets can also manually attach formal `Document` records through `ticket_document_links`

This creates duplicated context ownership and pushes cognitive load onto the user. When formal artifacts already belong to a use case, requiring the user to remember which drafts, specs, plans, trackers, or quizzes must also be attached to each ticket is tedious and error-prone.

Direct ticket-level formal document selection also creates unstable behavior when a ticket's use case changes. A ticket may retain manually attached documents that now duplicate or conflict with the newly selected use case's formal context.

RedWright should simplify the association model before adding more context-selection rules.

## Goals

- make `UseCase` the scoped owner of formal context
- preserve project-level formal context for artifacts without a use case
- keep ticket `use_case_id` optional; blank means project-level work
- remove direct ticket-level formal document attachment
- remove ticket formal document selector UI
- make the ticket use-case selector the visible context association control
- keep ticket-specific evidence/assets as a deferred, separate concept
- avoid implementing final LLM context shaping in this cycle
- avoid placeholder UI for future evidence/assets
- preserve current document and quiz use-case ownership behavior where it is already correct

## Non-Goals

- implementing ticket evidence/assets uploads
- processing images, PDFs, screenshots, or arbitrary binary assets
- defining final `LLMRequestEngine` context section shape
- assigning prompt priority to ticket body, project context, use-case context, or future evidence
- implementing runtime inherited context selection
- adding ticket-level formal document overrides
- building project/use-case evidence libraries
- preserving SaaS-grade migration compatibility for external users

## Product Model

### Formal Context

Formal context includes structured RedWright engineering artifacts:

- drafts
- specifications
- plan/tracker artifacts
- quizzes and quiz entries
- future formal contextual entities

Formal context belongs either to:

- a project, when `use_case_id` is blank
- a use case, when `use_case_id` is present

Tickets do not directly attach formal context artifacts.

### Evidence Assets

Evidence assets are ticket-specific supporting material that may help resolve a ticket without becoming formal context.

Examples:

- screenshots
- UI defect captures
- user complaints
- user notes
- PDFs
- logs
- external references
- temporary investigation notes
- future analyzable images or assets

Evidence assets are explicitly deferred. The first version of this refactor must not add an inactive uploader or placeholder UI.

### Ticket Scope

A ticket may belong to one use case through nullable `use_case_id`.

Rules:

- `use_case_id` present means use-case-level ticket
- `use_case_id` blank means project-level ticket
- blank `use_case_id` is valid and intentional
- changing `use_case_id` corrects the ticket's structural scope
- changing `use_case_id` must not copy, attach, or sync formal documents onto the ticket

### Project-Level Tickets

Project-level tickets are valid for:

- bugs
- hotfixes
- UI glitches
- internal refactors
- infrastructure work
- broad project tasks

These tickets rely on their body, project ownership, and project-level formal artifacts. This spec does not define how those inputs are prioritized for LLM prompts.

## Current Model Notes

The current Rails model already has:

- `documents.use_case_id`
- `tickets.use_case_id`
- `quizzes.use_case_id`
- `quiz_entries.use_case_id`
- use-case validation that scoped records belong to the same project

The current Rails model still has ticket formal document attachment behavior:

- `TicketDocumentLink`
- `tickets.documents`
- `documents.tickets`
- ticket form "Linked Documents" picker
- `TicketManagement::DocumentLinkSyncService`
- `AttachDocumentToTicket` command-query behavior
- runtime bridge output that reads `ticket.ticket_document_links`

This refactor removes or neutralizes the direct ticket formal document path.

## Association Rules

### Formal Artifacts

When a formal artifact is created with a selected use case, it belongs to that use case.

When a formal artifact is created without a selected use case, it belongs to project-level formal context.

This applies conceptually to all formal artifacts. The implementation should respect the artifact types currently represented in the Rails model and avoid inventing unrelated storage for repository-only ops files.

### Tickets

Ticket create/edit exposes use-case association as the ticket's structural context scope.

The ticket form must allow project-level tickets by leaving the use-case selector blank.

Ticket create/edit must not expose direct formal document attachment controls.

### Direct Ticket Formal Attachments

Direct ticket formal attachments are removed from the product model.

The system must not require users to manually attach drafts, specs, plans, trackers, quizzes, or other formal artifacts to tickets.

The system must not materialize inherited use-case documents into ticket-document join rows.

## Web UI

### Ticket Form

The ticket form should show `Use Case` as the main context association control.

The use-case selector should be visually higher than the current document association area. It should not be buried below low-level metadata.

The selector may start as a normal select if that matches current implementation, but the intended direction is a search/autocomplete control similar in utility to the existing document picker.

### Removed Document Picker

Remove the ticket "Linked Documents" section.

Do not replace it with:

- an empty evidence uploader
- a disabled placeholder
- explanatory text about future evidence

The UI should simply stop showing formal document attachment controls.

### Use Case Inheritance Explanation

The ticket UI does not need to explain that formal context is inherited through the use case. That behavior is considered natural in the model.

## Command-Query Boundary

Ticket command-query operations should preserve `use_case_id` support.

Ticket command-query operations should stop accepting or syncing `document_ids` as formal ticket attachments.

The `AttachDocumentToTicket` operation should be removed from active command-query registration or converted to an unsupported/deprecated response within this cycle.

No replacement evidence command is required in this cycle.

## Runtime Boundary

This spec does not implement inherited context injection for ticket execution.

Any existing runtime bridge code that depends on direct ticket document links must be removed or neutralized so the refactor compiles and validates, but it must not be replaced by a new use-case/project formal context retrieval algorithm in this cycle.

The future context service may decide how to combine:

- ticket body
- project-level formal context
- use-case formal context
- future ticket evidence
- code/runtime state

That policy is outside this spec.

## Data and Migration

RedWright is currently a personal development app, not a launched SaaS product with external tenants.

The migration strategy can be direct and low ceremony:

- remove the `ticket_document_links` table if no longer used
- remove model associations and services tied only to direct formal ticket attachments
- update tests and fixtures to the new association model

No compatibility-heavy legacy preservation is required.

## Validation Requirements

Model validation should cover:

- tickets may have blank `use_case_id`
- tickets may reference a same-project use case
- tickets reject cross-project use cases
- documents may have blank `use_case_id`
- documents may reference a same-project use case
- documents reject cross-project use cases
- ticket formal document link behavior no longer exists where removed

Controller/view validation should cover:

- ticket create/edit shows use-case selection
- ticket create/edit does not show linked document picker
- ticket create/edit preserves blank project-level use case
- ticket create/edit persists valid use-case selection

Command-query validation should cover:

- ticket create/update still accept `use_case_id`
- ticket create/update do not sync `document_ids`
- direct document attachment command is unavailable or removed

Full validation should include:

- targeted model/controller/service tests touched by the refactor
- full Rails test suite
- `scripts/agent/tickets/check.sh` after ops artifact updates

## Superseded Behavior

This spec supersedes the "Scope vs Attachments" ticket formal document attachment direction from the use-case management UI spec.

The new direction is:

- `UseCase` is structural formal context scope
- project-level formal artifacts remain available as project context
- tickets do not manually attach formal documents
- ticket-specific non-formal inputs belong to a future evidence/assets model

## Open Questions

- Should the ticket use-case selector be upgraded to autocomplete in this cycle or in a follow-up after removing formal document attachments?
- Should `AttachDocumentToTicket` return a structured deprecation error for one cycle or be removed immediately?
- Which existing runtime bridge tests should be rewritten now versus deferred to the future inherited-context service?

