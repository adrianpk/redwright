# Cycle Tracker: RedWright Ticket Use Case Formal Context Refactor

## Metadata

- cycle_id: `cycle-2026-05-07-redwright-ticket-use-case-formal-context-refactor`
- status: `implemented`
- state: `cycle_validated`
- updated: `2026-05-07`
- active_slice: `none`
- active_task: `none`
- source_plan: `ops/plans/2026-05-07-redwright-ticket-use-case-formal-context-refactor-cycle-plan.md`
- source_spec: `ops/specs/specs/2026-05-07-redwright-ticket-use-case-formal-context-refactor-spec.md`
- source_draft: `ops/specs/drafts/2026-05-06-redwright-ticket-context-inheritance-use-case-document-model-draft.md`
- source_quiz:
  - `ops/conv/quiz/2026-05-07-redwright-ticket-context-inheritance-use-case-evidence-model-quiz.md`
  - `ops/conv/quiz/2026-05-07-redwright-ticket-context-inheritance-use-case-evidence-model-quiz-raw.md`
- merge_target: `dev`

## Slice Progress

### Slice 1: Formal Attachment Domain Removal

- status: `implemented`
- branch: `fix/slice-1-ticket-formal-attachment-domain-removal`
- PR: `https://codeberg.org/adrianpk/redwright/pulls/353`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [x] `T1.1 inspect TicketDocumentLink, TicketManagement::DocumentLinkSyncService, Ticket, Document, and schema references`
- [x] `T1.2 remove TicketDocumentLink model behavior and direct ticket/document has_many-through associations`
- [x] `T1.3 add migration to remove ticket_document_links when no longer referenced`
- [x] `T1.4 remove or update model tests that only validate direct ticket formal document links`
- [x] `T1.5 keep Ticket use_case_id and Document use_case_id validations intact`
- [x] `T1.6 run focused model tests for Ticket, Document, UseCase, and removed link behavior`

Commits:

- [x] `fix(web): remove ticket formal document attachments`

Validation:

- [x] `bundle exec bin/rails test test/models/ticket_test.rb test/models/document_test.rb test/models/use_case_test.rb`
- [x] `bundle exec bin/rails test`
- [x] `scripts/agent/tickets/check.sh`

### Slice 2: Ticket Form Context UI Refactor

- status: `implemented`
- branch: `fix/slice-1-ticket-formal-attachment-domain-removal`
- PR: `https://codeberg.org/adrianpk/redwright/pulls/353`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [x] `T2.1 move the ticket Use Case field higher in the ticket editor context hierarchy`
- [x] `T2.2 preserve blank Project-level selection semantics`
- [x] `T2.3 remove the Linked Documents picker markup from the ticket form`
- [x] `T2.4 remove unused ticket document picker JavaScript bindings and CSS when no other caller uses them`
- [x] `T2.5 remove document_ids handling from TicketsController params and form sync paths`
- [x] `T2.6 add controller/view tests for use-case selection and absence of linked document UI`

Commits:

- [x] `fix(web): remove ticket formal document attachments`

Validation:

- [x] `bundle exec bin/rails test test/controllers/tickets_controller_test.rb`
- [x] `bundle exec bin/rails test`
- [x] `scripts/agent/tickets/check.sh`

### Slice 3: Command-Query and Runtime Bridge Cleanup

- status: `implemented`
- branch: `fix/slice-1-ticket-formal-attachment-domain-removal`
- PR: `https://codeberg.org/adrianpk/redwright/pulls/353`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [x] `T3.1 remove document_ids sync handling from ticket create/update command-query paths`
- [x] `T3.2 remove or deprecate AttachDocumentToTicket command registration`
- [x] `T3.3 update command-query result payloads so tickets no longer include direct document_links`
- [x] `T3.4 remove runtime bridge direct ticket document lines`
- [x] `T3.5 update API and service tests that expect document attachment effects`
- [x] `T3.6 document that inherited use-case/project context retrieval remains deferred`

Commits:

- [x] `fix(web): remove ticket formal document attachments`

Validation:

- [x] `bundle exec bin/rails test test/services/board_workflow/command_query_handlers_test.rb test/controllers/api/v1/command_queries_controller_test.rb test/services/runtime_bridge/ticket_execution_bridge_test.rb`
- [x] `bundle exec bin/rails test`
- [x] `scripts/agent/tickets/check.sh`

### Slice 4: Formal Artifact Scope Verification

- status: `implemented`
- branch: `fix/slice-4-formal-artifact-use-case-scope`
- PR: `https://codeberg.org/adrianpk/redwright/pulls/354`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [x] `T4.1 audit Document, Quiz, QuizEntry, and plan_tracker behavior for project-level versus use-case-level ownership`
- [x] `T4.2 ensure formal artifacts created with use_case_id stay scoped to that use case`
- [x] `T4.3 ensure formal artifacts created without use_case_id remain project-level`
- [x] `T4.4 add missing tests for document and quiz scope behavior where gaps exist`
- [x] `T4.5 update spec notes if the current model constrains any artifact type differently than expected`

Commits:

- [x] `fix(web): preserve formal artifact use case scope`

Validation:

- [x] `bundle exec bin/rails test test/models/document_test.rb test/models/quiz_test.rb test/models/quiz_entry_test.rb test/controllers/documents_controller_test.rb test/controllers/project_quizzes_controller_test.rb test/services/document_promotion_service_test.rb`
- [x] `bundle exec bin/rails test`
- [x] `scripts/agent/tickets/check.sh`

### Slice 5: Cycle Validation and Closure

- status: `implemented`
- branch: `fix/slice-5-ticket-context-refactor-closure`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [x] `T5.1 run targeted model, controller, command-query, and runtime bridge tests touched by the refactor`
- [x] `T5.2 run full Rails test suite from apps/web`
- [x] `T5.3 run repository ticket workflow checks`
- [x] `T5.4 update tracker with validation evidence, residual risks, and deferred work`
- [x] `T5.5 keep evidence/assets and inherited context retrieval deferred unless explicitly approved as new scope`

Commits:

- [x] `chore(slice-5): validate ticket context refactor cycle`

Validation:

- [x] `bundle exec bin/rails test`
- [x] `scripts/agent/tickets/check.sh`

## Event Log

- `2026-05-07` state=`planning` note=`created formal spec, sliced implementation plan, and tracker from exploratory draft plus questionnaire alignment`
- `2026-05-07` state=`slices_1_3_implemented` note=`removed direct ticket formal document attachment domain, UI picker, command-query attachment paths, runtime bridge document lines, and setup ticket direct document links in one dependency-bound implementation slice`
- `2026-05-07` validation=`passed` note=`focused Rails tests: 105 runs, 864 assertions, 0 failures`
- `2026-05-07` validation=`passed` note=`full Rails tests: 410 runs, 2628 assertions, 0 failures`
- `2026-05-07` validation=`passed` note=`scripts/agent/tickets/check.sh`
- `2026-05-07` state=`slice_4_implemented` note=`audited formal artifact and quiz scope behavior, fixed draft promotion to preserve use_case_id, and added project-level/use-case-level scope coverage`
- `2026-05-07` validation=`passed` note=`slice 4 focused Rails tests: 61 runs, 319 assertions, 0 failures`
- `2026-05-07` validation=`passed` note=`full Rails tests: 414 runs, 2637 assertions, 0 failures`
- `2026-05-07` validation=`passed` note=`scripts/agent/tickets/check.sh`
- `2026-05-07` state=`cycle_validated` note=`ran final touched-surface validation and full suite after slices 1-4 merged`
- `2026-05-07` validation=`passed` note=`cycle closure targeted Rails tests: 152 runs, 1143 assertions, 0 failures`
- `2026-05-07` validation=`passed` note=`cycle closure full Rails tests: 414 runs, 2637 assertions, 0 failures`
- `2026-05-07` validation=`passed` note=`scripts/agent/tickets/check.sh`

## Residual Risks

- The future evidence/assets model remains intentionally deferred, so ticket-specific supporting material does not have a replacement upload path in this cycle.
- Final LLM context retrieval remains deferred and must be handled by a later context-service or LLMRequestEngine cycle.
