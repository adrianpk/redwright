# Cycle Tracker: RedWright Use Case Management UI

## Metadata

- cycle_id: `cycle-2026-05-06-redwright-use-case-management-ui`
- status: `in_progress`
- state: `slice_7_implemented`
- updated: `2026-05-06`
- active_slice: `Slice 7`
- active_task: `none`
- source_plan: `ops/plans/2026-05-06-redwright-use-case-management-ui-cycle-plan.md`
- source_spec: `ops/specs/specs/2026-05-06-redwright-use-case-management-ui-spec.md`
- source_quiz:
  - `ops/quiz/2026-05-06-redwright-use-case-management-ui-quiz.md`
  - `ops/quiz/2026-05-06-redwright-use-case-management-ui-quiz-raw.md`
- source_ticket: `ops/tickets/ready/20260506081044-add-use-case-management-ui.md`
- related_future_draft: `ops/specs/drafts/2026-05-06-redwright-ticket-context-inheritance-use-case-document-model-draft.md`

## Slice Progress

### Slice 1: Use Case Domain Hardening

- status: `pr_merged`
- branch: `fix/slice-1-use-case-domain-hardening`
- PR: `https://codeberg.org/adrianpk/redwright/pulls/328`
- merge_target: `dev`
- last_sync_commit: `a10bbfa`

Tasks:

- [x] `T1.1 inspect existing UseCase, Ticket, Document, Quiz, and QuizEntry persistence for current scope support`
- [x] `T1.2 require UseCase description and keep slug generated from name`
- [x] `T1.3 enforce project-local uniqueness for both UseCase name and slug`
- [x] `T1.4 add direct nullable Document use_case_id scope with project consistency validation`
- [x] `T1.5 expose UseCase associations for tickets, documents, quiz, quiz entries, and taggings without cascade deletion`
- [x] `T1.6 add UseCase safe deletion helpers that detect blocking references without index-level checks`
- [x] `T1.7 add focused model tests for description requirement, uniqueness, document scope, association blocking, and project consistency`

Commits:

- [x] `87ea65c feat(web): harden use case domain model`

Validation:

- [x] `bundle exec bin/rails test test/models/use_case_test.rb test/models/document_test.rb test/models/ticket_test.rb test/models/quiz_test.rb test/models/quiz_entry_test.rb test/models/tagging_test.rb test/controllers/project_quizzes_controller_test.rb test/queries/quiz_context/retrieval_query_test.rb` (pass)
- [x] `bundle exec bin/rails test test/integration/project_setup_telegram_e2e_test.rb` (pass)
- [x] `bundle exec bin/rails test` (pass)

### Slice 2: Use Case Command-Query Operations

- status: `pr_merged`
- branch: `fix/slice-2-use-case-command-query`
- PR: `https://codeberg.org/adrianpk/redwright/pulls/329`
- merge_target: `dev`
- last_sync_commit: `93b950a`

Tasks:

- [x] `T2.1 add a UseCases command-query handler module following existing service conventions`
- [x] `T2.2 register CreateUseCase with required project_id, name, and description`
- [x] `T2.3 register UpdateUseCase with mutable name and description only`
- [x] `T2.4 register DeleteUseCase with no-cascade safety checks and structured blocked-reference errors`
- [x] `T2.5 register ListUseCases scoped to project and ordered newest first`
- [x] `T2.6 register GetUseCase by id or project-local slug`
- [x] `T2.7 include association metric data only where needed for GetUseCase/detail semantics`
- [x] `T2.8 add command-query tests for success, invalid payloads, missing records, uniqueness, and blocked deletion`

Commits:

- [x] `c70f082 feat(web): add use case command queries`
- [x] `32ef213 test(web): cover use case command queries`

Validation:

- [x] `bundle exec bin/rails test test/services/use_cases/command_query_handlers_test.rb test/models/use_case_test.rb test/services/command_query/dispatcher_test.rb` (pass)
- [x] `bundle exec bin/rails test` (pass)

### Slice 3: Use Cases Navigation and Index

- status: `pr_merged`
- branch: `fix/slice-3-use-cases-index`
- PR: `https://codeberg.org/adrianpk/redwright/pulls/330`
- merge_target: `dev`
- last_sync_commit: `81a70df`

Tasks:

- [x] `T3.1 add RESTful UseCases routes using readable slug URLs where practical`
- [x] `T3.2 add UseCasesController with current-project scoping and first-project fallback consistent with existing navigation`
- [x] `T3.3 add Use Cases navbar item between Protocols and Quizzes`
- [x] `T3.4 render newest-first Use Cases index table`
- [x] `T3.5 include an Edit action per row without delete buttons or per-row association counters`
- [x] `T3.6 keep the index free of dynamic search and pagination`
- [x] `T3.7 add controller tests for current-project scoping, fallback behavior, ordering, and navigation availability`

Commits:

- [x] `32f8e74 feat(web): add use cases index`
- [x] `7ef393a test(web): cover use cases navigation`

Validation:

- [x] `bundle exec bin/rails test test/controllers/use_cases_controller_test.rb test/controllers/project_quizzes_controller_test.rb test/controllers/project_protocols_controller_test.rb` (pass)
- [x] `bundle exec bin/rails test` (pass)

### Slice 4: Use Case Create and Edit Modal UI

- status: `pr_merged`
- branch: `fix/slice-4-use-case-modal-ui`
- PR: `https://codeberg.org/adrianpk/redwright/pulls/331`
- merge_target: `dev`
- last_sync_commit: `274429b`

Tasks:

- [x] `T4.1 add create modal launched from the Use Cases screen`
- [x] `T4.2 add edit/detail modal launched from each index row`
- [x] `T4.3 expose editable name and description only`
- [x] `T4.4 keep slug hidden from first-version forms`
- [x] `T4.5 render validation errors for missing name, missing description, and duplicate project-local identity`
- [x] `T4.6 preserve current project scope during create and update redirects`
- [x] `T4.7 add controller/view tests for create, update, invalid form state, and slug URL behavior`

Commits:

- [x] `dc28aa3 feat(web): add use case modal forms`
- [x] `a66da9d test(web): cover use case form flows`

Validation:

- [x] `bundle exec bin/rails test test/controllers/use_cases_controller_test.rb test/models/use_case_test.rb` (pass)
- [x] `bundle exec bin/rails test test/controllers/use_cases_controller_test.rb test/controllers/project_quizzes_controller_test.rb test/controllers/project_protocols_controller_test.rb` (pass)
- [x] `bundle exec bin/rails test` (pass)

### Slice 5: Ticket Optional Use Case Selection

- status: `pr_merged`
- branch: `fix/slice-5-ticket-use-case-selection`
- PR: `https://codeberg.org/adrianpk/redwright/pulls/332`
- merge_target: `dev`
- last_sync_commit: `34f7570`

Tasks:

- [x] `T5.1 inspect existing ticket modal/form parameters and command-query attributes`
- [x] `T5.2 add optional use_case_id selector to ticket create/edit surfaces`
- [x] `T5.3 scope selector options to the ticket board's project`
- [x] `T5.4 allow blank use_case_id for project-level tickets`
- [x] `T5.5 preserve document attachments independently from use_case_id`
- [x] `T5.6 include use_case_id in ticket command-query create/update payload handling if not already complete`
- [x] `T5.7 add tests for blank selection, valid same-project selection, invalid cross-project selection, and document attachment independence`

Commits:

- [x] `f5762b2 feat(web): add ticket use case selector`
- [x] `bec43a6 test(web): cover ticket use case selection`

Validation:

- [x] `bundle exec bin/rails test test/controllers/tickets_controller_test.rb test/models/ticket_test.rb test/services/board_workflow/command_query_handlers_test.rb` (pass)
- [x] `bundle exec bin/rails test` (pass)

### Slice 6: Document Optional Use Case Selection

- status: `pr_merged`
- branch: `fix/slice-6-document-use-case-selection`
- PR: `https://codeberg.org/adrianpk/redwright/pulls/333`
- merge_target: `dev`
- last_sync_commit: `1c2c5c7`

Tasks:

- [x] `T6.1 add optional use_case_id selector to document create/edit forms`
- [x] `T6.2 scope selector options to the document project`
- [x] `T6.3 allow blank use_case_id for project-level documents`
- [x] `T6.4 include use_case_id in document command-query create/update handling where applicable`
- [x] `T6.5 preserve document lifecycle rules for draft, spec, and plan_tracker artifacts`
- [x] `T6.6 add tests for blank selection, valid same-project selection, invalid cross-project selection, and draft edit behavior`

Commits:

- [x] `ce81358 feat(web): add document use case selector`
- [x] `a606abb test(web): cover document use case selection`

Validation:

- [x] `bundle exec bin/rails test test/controllers/documents_controller_test.rb test/models/document_test.rb test/services/document_management/command_query_handlers_test.rb` (pass)
- [x] `bundle exec bin/rails test` (pass)

### Slice 7: Use Case Detail Metrics and Delete Behavior

- status: `implemented`
- branch: `fix/slice-7-use-case-metrics-delete`
- PR: `pending`
- merge_target: `dev`
- last_sync_commit: `pending`

Tasks:

- [x] `T7.1 add UseCase metric calculation for tickets, grouped documents, plans, and quiz entries`
- [x] `T7.2 render metrics discreetly at the top of the detail/edit modal`
- [x] `T7.3 hide delete action when references are present`
- [x] `T7.4 validate deletion again in the controller/backend when attempted`
- [x] `T7.5 show a flash error when backend deletion is blocked`
- [x] `T7.6 allow deletion with browser confirmation only when safe`
- [x] `T7.7 add tests for metric counts, grouped document types, hidden delete, blocked delete, allowed delete, and no cascading deletes`

Commits:

- [x] `818a759 feat(web): add use case metrics and safe delete`
- [x] `b507ea5 test(web): cover use case metrics and delete`

Validation:

- [x] `bundle exec bin/rails test test/controllers/use_cases_controller_test.rb test/models/use_case_test.rb test/services/use_cases/command_query_handlers_test.rb` (pass)
- [x] `bundle exec bin/rails test` (pass)

### Slice 8: Cycle Validation and Closure

- status: `planned`
- branch: `fix/slice-8-use-case-cycle-closure`
- PR: `pending`
- merge_target: `dev`
- last_sync_commit: `pending`

Tasks:

- [ ] `T8.1 run targeted model, command-query, controller, and integration tests for all use-case surfaces`
- [ ] `T8.2 run the full Rails test suite from apps/web`
- [ ] `T8.3 perform a final spec-to-implementation checklist against the validation section`
- [ ] `T8.4 update tracker with validation evidence and any residual risks`
- [ ] `T8.5 keep deferred items deferred unless explicitly approved as new scope`

Commits:

- [ ] `pending`

Validation:

- [ ] `pending`

## Activity Log

- `2026-05-06` state=`planning_complete` note=`created cycle plan and tracker from use case management UI spec, curated quiz, raw quiz, and ready implementation ticket; no slice approved or started`
- `2026-05-06` state=`slice_1_active` note=`started Slice 1 on branch fix/slice-1-use-case-domain-hardening after planning commit on dev`
- `2026-05-06` state=`slice_1_implemented` note=`implemented UseCase domain hardening with description requirement, document use_case scope, deletion blockers, tests, migration, and full Rails validation`
- `2026-05-06` state=`slice_1_merged` note=`PR #328 merged into dev and local dev fast-forwarded to a10bbfa`
- `2026-05-06` state=`slice_2_implemented` note=`implemented UseCase command-query create, update, delete, list, and get operations with structured errors, metrics, tests, and full Rails validation`
- `2026-05-06` state=`slice_2_merged` note=`PR #329 merged into dev and local dev fast-forwarded to 93b950a`
- `2026-05-06` state=`slice_3_implemented` note=`implemented Use Cases navigation and newest-first index with project scoping, no index delete/counters, controller coverage, and full Rails validation`
- `2026-05-06` state=`slice_3_merged` note=`PR #330 merged into dev and local dev fast-forwarded to 81a70df`
- `2026-05-06` state=`slice_4_implemented` note=`implemented Use Case create/edit modal forms with generated slug hidden, validation rendering, route coverage, and full Rails validation`
- `2026-05-06` state=`slice_4_merged` note=`PR #331 merged into dev and local dev fast-forwarded to 274429b`
- `2026-05-06` state=`slice_5_implemented` note=`implemented optional ticket Use Case selection with project-scoped form options, project-level blank selection, document link independence, command-query payload data, focused tests, and full Rails validation`
- `2026-05-06` state=`slice_5_merged` note=`PR #332 merged into dev and local dev fast-forwarded to 34f7570`
- `2026-05-06` state=`slice_6_implemented` note=`implemented optional document Use Case selection for draft create/edit, command-query use_case_id handling, project-level blank selection, cross-project validation coverage, lifecycle editability preservation, and full Rails validation`
- `2026-05-06` state=`slice_6_merged` note=`PR #333 merged into dev and local dev fast-forwarded to 1c2c5c7`
- `2026-05-06` state=`slice_7_implemented` note=`implemented UseCase detail metrics, edit-modal metric rendering, hidden delete for referenced use cases, backend delete blocking, safe delete with confirmation, controller/model coverage, and full Rails validation`
