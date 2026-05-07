# Cycle Tracker: RedWright Ticket Use Case Formal Context Refactor

## Metadata

- cycle_id: `cycle-2026-05-07-redwright-ticket-use-case-formal-context-refactor`
- status: `planned`
- state: `planning`
- updated: `2026-05-07`
- active_slice: `none`
- active_task: `none`
- source_plan: `ops/plans/2026-05-07-redwright-ticket-use-case-formal-context-refactor-cycle-plan.md`
- source_spec: `ops/specs/specs/2026-05-07-redwright-ticket-use-case-formal-context-refactor-spec.md`
- source_draft: `ops/specs/drafts/2026-05-06-redwright-ticket-context-inheritance-use-case-document-model-draft.md`
- source_quiz:
  - `ops/quiz/2026-05-07-redwright-ticket-context-inheritance-use-case-evidence-model-quiz.md`
  - `ops/quiz/2026-05-07-redwright-ticket-context-inheritance-use-case-evidence-model-quiz-raw.md`
- merge_target: `dev`

## Slice Progress

### Slice 1: Formal Attachment Domain Removal

- status: `pending`
- branch: `fix/slice-1-ticket-formal-attachment-domain-removal`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T1.1 inspect TicketDocumentLink, TicketManagement::DocumentLinkSyncService, Ticket, Document, and schema references`
- [ ] `T1.2 remove TicketDocumentLink model behavior and direct ticket/document has_many-through associations`
- [ ] `T1.3 add migration to remove ticket_document_links when no longer referenced`
- [ ] `T1.4 remove or update model tests that only validate direct ticket formal document links`
- [ ] `T1.5 keep Ticket use_case_id and Document use_case_id validations intact`
- [ ] `T1.6 run focused model tests for Ticket, Document, UseCase, and removed link behavior`

Commits:

- [ ] `pending`

Validation:

- [ ] `bundle exec bin/rails test test/models/ticket_test.rb test/models/document_test.rb test/models/use_case_test.rb`
- [ ] `bundle exec bin/rails test`
- [ ] `scripts/agent/tickets/check.sh`

### Slice 2: Ticket Form Context UI Refactor

- status: `pending`
- branch: `fix/slice-2-ticket-use-case-context-ui`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T2.1 move the ticket Use Case field higher in the ticket editor context hierarchy`
- [ ] `T2.2 preserve blank Project-level selection semantics`
- [ ] `T2.3 remove the Linked Documents picker markup from the ticket form`
- [ ] `T2.4 remove unused ticket document picker JavaScript bindings and CSS when no other caller uses them`
- [ ] `T2.5 remove document_ids handling from TicketsController params and form sync paths`
- [ ] `T2.6 add controller/view tests for use-case selection and absence of linked document UI`

Commits:

- [ ] `pending`

Validation:

- [ ] `bundle exec bin/rails test test/controllers/tickets_controller_test.rb`
- [ ] `bundle exec bin/rails test`
- [ ] `scripts/agent/tickets/check.sh`

### Slice 3: Command-Query and Runtime Bridge Cleanup

- status: `pending`
- branch: `fix/slice-3-ticket-document-command-cleanup`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T3.1 remove document_ids sync handling from ticket create/update command-query paths`
- [ ] `T3.2 remove or deprecate AttachDocumentToTicket command registration`
- [ ] `T3.3 update command-query result payloads so tickets no longer include direct document_links`
- [ ] `T3.4 remove runtime bridge direct ticket document lines`
- [ ] `T3.5 update API and service tests that expect document attachment effects`
- [ ] `T3.6 document that inherited use-case/project context retrieval remains deferred`

Commits:

- [ ] `pending`

Validation:

- [ ] `bundle exec bin/rails test test/services/board_workflow/command_query_handlers_test.rb test/controllers/api/v1/command_queries_controller_test.rb test/services/runtime_bridge/ticket_execution_bridge_test.rb`
- [ ] `bundle exec bin/rails test`
- [ ] `scripts/agent/tickets/check.sh`

### Slice 4: Formal Artifact Scope Verification

- status: `pending`
- branch: `fix/slice-4-formal-artifact-use-case-scope`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T4.1 audit Document, Quiz, QuizEntry, and plan_tracker behavior for project-level versus use-case-level ownership`
- [ ] `T4.2 ensure formal artifacts created with use_case_id stay scoped to that use case`
- [ ] `T4.3 ensure formal artifacts created without use_case_id remain project-level`
- [ ] `T4.4 add missing tests for document and quiz scope behavior where gaps exist`
- [ ] `T4.5 update spec notes if the current model constrains any artifact type differently than expected`

Commits:

- [ ] `pending`

Validation:

- [ ] `bundle exec bin/rails test test/models/document_test.rb test/models/quiz_test.rb test/models/quiz_entry_test.rb test/controllers/documents_controller_test.rb test/controllers/project_quizzes_controller_test.rb`
- [ ] `bundle exec bin/rails test`
- [ ] `scripts/agent/tickets/check.sh`

### Slice 5: Cycle Validation and Closure

- status: `pending`
- branch: `fix/slice-5-ticket-context-refactor-closure`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T5.1 run targeted model, controller, command-query, and runtime bridge tests touched by the refactor`
- [ ] `T5.2 run full Rails test suite from apps/web`
- [ ] `T5.3 run repository ticket workflow checks`
- [ ] `T5.4 update tracker with validation evidence, residual risks, and deferred work`
- [ ] `T5.5 keep evidence/assets and inherited context retrieval deferred unless explicitly approved as new scope`

Commits:

- [ ] `pending`

Validation:

- [ ] `bundle exec bin/rails test`
- [ ] `scripts/agent/tickets/check.sh`

## Event Log

- `2026-05-07` state=`planning` note=`created formal spec, sliced implementation plan, and tracker from exploratory draft plus questionnaire alignment`

## Residual Risks

- Removing direct ticket formal document links touches web UI, command-query, and runtime bridge call sites.
- The future evidence/assets model is intentionally deferred, so ticket-specific supporting material will not have a replacement upload path in this cycle.
- Final LLM context retrieval remains deferred and must be handled by a later context-service or LLMRequestEngine cycle.
