# Cycle Plan: RedWright Use Case Management UI

## Metadata

- cycle_id: `cycle-2026-05-06-redwright-use-case-management-ui`
- status: `planned`
- owner: `adrianpk`
- created: `2026-05-06`
- updated: `2026-05-06`
- goal: `deliver a dedicated project-scoped Use Cases management surface with command-query operations, optional ticket/document scope, association metrics, and safe non-cascading deletion`
- scope: `feature`
- source_spec: `ops/specs/specs/2026-05-06-redwright-use-case-management-ui-spec.md`
- source_quiz:
  - `ops/quiz/2026-05-06-redwright-use-case-management-ui-quiz.md`
  - `ops/quiz/2026-05-06-redwright-use-case-management-ui-quiz-raw.md`
- source_ticket: `ops/tickets/ready/20260506081044-add-use-case-management-ui.md`
- related_future_draft: `ops/specs/drafts/2026-05-06-redwright-ticket-context-inheritance-use-case-document-model-draft.md`

## Slice List

### Slice 1: Use Case Domain Hardening

- status: `pr_merged`
- branch: `fix/slice-1-use-case-domain-hardening`
- pr_title: `feat(slice-1): harden use case domain model`
- objective: `complete the first-class UseCase domain contract before UI work, including required description, project-local name/slug uniqueness, direct document scope support, and safe deletion predicates`
- tasks:
- [ ] `T1.1 inspect existing UseCase, Ticket, Document, Quiz, and QuizEntry persistence for current scope support`
- [ ] `T1.2 require UseCase description and keep slug generated from name`
- [ ] `T1.3 enforce project-local uniqueness for both UseCase name and slug`
- [ ] `T1.4 add direct nullable Document use_case_id scope with project consistency validation`
- [ ] `T1.5 expose UseCase associations for tickets, documents, quiz, quiz entries, and taggings without cascade deletion`
- [ ] `T1.6 add UseCase safe deletion helpers that detect blocking references without index-level checks`
- [ ] `T1.7 add focused model tests for description requirement, uniqueness, document scope, association blocking, and project consistency`
- acceptance:
- `UseCase requires name and description`
- `UseCase slug remains generated and project-local`
- `UseCase names are unique within a project`
- `Documents can optionally belong to a use case from the same project`
- `Tickets and documents may remain project-level with no use case`
- `UseCase deletion is prevented when references exist`
- planned_commits:
- `feat(web): harden use case domain model`
- `test(web): cover use case domain rules`

### Slice 2: Use Case Command-Query Operations

- status: `planned`
- branch: `fix/slice-2-use-case-command-query`
- pr_title: `feat(slice-2): add use case command queries`
- objective: `add structured command-query operations for agents and messaging surfaces to create, update, delete, list, and retrieve project-scoped use cases`
- tasks:
- [ ] `T2.1 add a UseCases command-query handler module following existing service conventions`
- [ ] `T2.2 register CreateUseCase with required project_id, name, and description`
- [ ] `T2.3 register UpdateUseCase with mutable name and description only`
- [ ] `T2.4 register DeleteUseCase with no-cascade safety checks and structured blocked-reference errors`
- [ ] `T2.5 register ListUseCases scoped to project and ordered newest first`
- [ ] `T2.6 register GetUseCase by id or project-local slug`
- [ ] `T2.7 include association metric data only where needed for GetUseCase/detail semantics`
- [ ] `T2.8 add command-query tests for success, invalid payloads, missing records, uniqueness, and blocked deletion`
- acceptance:
- `CreateUseCase, UpdateUseCase, DeleteUseCase, ListUseCases, and GetUseCase are registered`
- `all operations return structured CommandQuery::Result responses`
- `delete returns a structured error when references block deletion`
- `list is project-scoped and newest-first`
- planned_commits:
- `feat(web): add use case command queries`
- `test(web): cover use case command queries`

### Slice 3: Use Cases Navigation and Index

- status: `planned`
- branch: `fix/slice-3-use-cases-index`
- pr_title: `feat(slice-3): add use cases index`
- objective: `add the dedicated Use Cases web surface scoped to the selected project with minimalist newest-first table navigation`
- tasks:
- [ ] `T3.1 add RESTful UseCases routes using readable slug URLs where practical`
- [ ] `T3.2 add UseCasesController with current-project scoping and first-project fallback consistent with existing navigation`
- [ ] `T3.3 add Use Cases navbar item between Protocols and Quizzes`
- [ ] `T3.4 render newest-first Use Cases index table`
- [ ] `T3.5 include an Edit action per row without delete buttons or per-row association counters`
- [ ] `T3.6 keep the index free of dynamic search and pagination`
- [ ] `T3.7 add controller tests for current-project scoping, fallback behavior, ordering, and navigation availability`
- acceptance:
- `Use Cases appears in the navbar between Protocols and Quizzes`
- `index shows only the selected project's use cases`
- `index is ordered newest first`
- `index does not run destructive-reference checks per row`
- planned_commits:
- `feat(web): add use cases index`
- `test(web): cover use cases navigation`

### Slice 4: Use Case Create and Edit Modal UI

- status: `planned`
- branch: `fix/slice-4-use-case-modal-ui`
- pr_title: `feat(slice-4): add use case modal forms`
- objective: `deliver create and edit/detail modal flows for name and description while preserving the existing sober Rails UI style`
- tasks:
- [ ] `T4.1 add create modal launched from the Use Cases screen`
- [ ] `T4.2 add edit/detail modal launched from each index row`
- [ ] `T4.3 expose editable name and description only`
- [ ] `T4.4 keep slug hidden from first-version forms`
- [ ] `T4.5 render validation errors for missing name, missing description, and duplicate project-local identity`
- [ ] `T4.6 preserve current project scope during create and update redirects`
- [ ] `T4.7 add controller/view tests for create, update, invalid form state, and slug URL behavior`
- acceptance:
- `users can create use cases from a modal`
- `users can edit use cases from the detail/edit modal`
- `name and description are required`
- `slug is generated and not edited directly`
- planned_commits:
- `feat(web): add use case modal forms`
- `test(web): cover use case form flows`

### Slice 5: Ticket Optional Use Case Selection

- status: `planned`
- branch: `fix/slice-5-ticket-use-case-selection`
- pr_title: `feat(slice-5): add ticket use case selection`
- objective: `surface optional Use Case metadata in ticket create/edit flows without changing ticket document attachment semantics`
- tasks:
- [ ] `T5.1 inspect existing ticket modal/form parameters and command-query attributes`
- [ ] `T5.2 add optional use_case_id selector to ticket create/edit surfaces`
- [ ] `T5.3 scope selector options to the ticket board's project`
- [ ] `T5.4 allow blank use_case_id for project-level tickets`
- [ ] `T5.5 preserve document attachments independently from use_case_id`
- [ ] `T5.6 include use_case_id in ticket command-query create/update payload handling if not already complete`
- [ ] `T5.7 add tests for blank selection, valid same-project selection, invalid cross-project selection, and document attachment independence`
- acceptance:
- `ticket create/edit exposes optional Use Case metadata`
- `tickets can remain project-level`
- `cross-project use case assignment is rejected`
- `attaching documents does not change ticket use case`
- planned_commits:
- `feat(web): add ticket use case selector`
- `test(web): cover ticket use case selection`

### Slice 6: Document Optional Use Case Selection

- status: `planned`
- branch: `fix/slice-6-document-use-case-selection`
- pr_title: `feat(slice-6): add document use case selection`
- objective: `surface optional Use Case metadata in document create/edit flows using direct document use_case_id scope`
- tasks:
- [ ] `T6.1 add optional use_case_id selector to document create/edit forms`
- [ ] `T6.2 scope selector options to the document project`
- [ ] `T6.3 allow blank use_case_id for project-level documents`
- [ ] `T6.4 include use_case_id in document command-query create/update handling where applicable`
- [ ] `T6.5 preserve document lifecycle rules for draft, spec, and plan_tracker artifacts`
- [ ] `T6.6 add tests for blank selection, valid same-project selection, invalid cross-project selection, and draft edit behavior`
- acceptance:
- `document create/edit exposes optional Use Case metadata`
- `documents can remain project-level`
- `cross-project use case assignment is rejected`
- `document lifecycle/editability rules remain unchanged`
- planned_commits:
- `feat(web): add document use case selector`
- `test(web): cover document use case selection`

### Slice 7: Use Case Detail Metrics and Delete Behavior

- status: `planned`
- branch: `fix/slice-7-use-case-metrics-delete`
- pr_title: `feat(slice-7): add use case metrics and safe delete`
- objective: `complete the detail/edit surface with discreet association metrics and destructive behavior that is hidden or blocked according to reference state`
- tasks:
- [ ] `T7.1 add UseCase metric calculation for tickets, grouped documents, plans, and quiz entries`
- [ ] `T7.2 render metrics discreetly at the top of the detail/edit modal`
- [ ] `T7.3 hide delete action when references are present`
- [ ] `T7.4 validate deletion again in the controller/backend when attempted`
- [ ] `T7.5 show a flash error when backend deletion is blocked`
- [ ] `T7.6 allow deletion with browser confirmation only when safe`
- [ ] `T7.7 add tests for metric counts, grouped document types, hidden delete, blocked delete, allowed delete, and no cascading deletes`
- acceptance:
- `detail/edit modal shows tickets, document type groups, plans, and quiz-entry metrics`
- `delete is not shown when references exist`
- `backend blocks unsafe delete attempts`
- `safe delete removes only the use case`
- planned_commits:
- `feat(web): add use case metrics and safe delete`
- `test(web): cover use case metrics and deletion`

### Slice 8: Cycle Validation and Closure

- status: `planned`
- branch: `fix/slice-8-use-case-cycle-closure`
- pr_title: `test(slice-8): validate use case management cycle`
- objective: `run full relevant validation, close tracker state, and record residual deferred work without expanding implementation scope`
- tasks:
- [ ] `T8.1 run targeted model, command-query, controller, and integration tests for all use-case surfaces`
- [ ] `T8.2 run the full Rails test suite from apps/web`
- [ ] `T8.3 perform a final spec-to-implementation checklist against the validation section`
- [ ] `T8.4 update tracker with validation evidence and any residual risks`
- [ ] `T8.5 keep deferred items deferred unless explicitly approved as new scope`
- acceptance:
- `all relevant targeted tests pass`
- `full Rails test suite passes or failures are documented with precise blockers`
- `tracker records final status, validation, and residual risks`
- `deferred work remains out of scope`
- planned_commits:
- `test(web): validate use case management cycle`
- `docs(ops): close use case management cycle`

## Global Exit Criteria

- Use Cases have a dedicated current-project scoped UI.
- Use Cases require only user-managed name and description.
- Slugs are generated from names and support readable URLs.
- Use Cases are project-local and not global.
- Tickets and documents expose optional use-case assignment.
- Project-level tickets and documents remain valid without a use case.
- Use Case detail/edit shows discreet association metrics.
- Delete is safe, non-cascading, and blocked when references exist.
- Command-query operations cover create, update, delete, list, and get.
- Quizzes continue to consume use cases without owning inline creation.
- No Jira-style hierarchy, archive semantics, search, pagination, many-to-many associations, or final LLM retrieval behavior is introduced.

## Validation Command Context

- Rails targeted tests must be run from `apps/web` with `bundle exec bin/rails test <paths>`.
- Full Rails validation must be run from `apps/web` with `bundle exec bin/rails test`.
- Validation entries must be reported as command plus `(pass)` or `(fail)`.
- Ops-only documentation updates can use the documented docs-only gate exception.

## Non-Goals

- Do not implement archive semantics.
- Do not add inline use-case creation from Tickets, Documents, or Quizzes.
- Do not add dynamic search or pagination to the Use Cases index.
- Do not introduce many-to-many use-case join tables.
- Do not remove ticket document attachments as part of this cycle.
- Do not implement final `LLMRequestEngine` context retrieval.
- Do not add Telegram-specific conversational flows beyond command-query readiness.
