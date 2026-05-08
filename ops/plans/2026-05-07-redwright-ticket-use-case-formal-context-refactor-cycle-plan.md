# Cycle Plan: RedWright Ticket Use Case Formal Context Refactor

## Metadata

- cycle_id: `cycle-2026-05-07-redwright-ticket-use-case-formal-context-refactor`
- status: `planned`
- owner: `adrianpk`
- created: `2026-05-07`
- updated: `2026-05-07`
- goal: `remove direct ticket formal document attachments and make use-case association the ticket formal context boundary while deferring evidence/assets and final LLM context retrieval`
- scope: `feature`
- source_spec: `ops/specs/specs/2026-05-07-redwright-ticket-use-case-formal-context-refactor-spec.md`
- source_draft: `ops/specs/drafts/2026-05-06-redwright-ticket-context-inheritance-use-case-document-model-draft.md`
- source_quiz:
  - `ops/conv/quiz/2026-05-07-redwright-ticket-context-inheritance-use-case-evidence-model-quiz.md`
  - `ops/conv/quiz/2026-05-07-redwright-ticket-context-inheritance-use-case-evidence-model-quiz-raw.md`
- supersedes_part_of: `ops/specs/specs/2026-05-06-redwright-use-case-management-ui-spec.md`

## Slice List

### Slice 1: Formal Attachment Domain Removal

- status: `pending`
- branch: `fix/slice-1-ticket-formal-attachment-domain-removal`
- pr_title: `fix(slice-1): remove ticket formal attachment domain`
- objective: `remove the direct ticket formal document association model while preserving ticket and document use-case ownership`
- tasks:
- [ ] `T1.1 inspect TicketDocumentLink, TicketManagement::DocumentLinkSyncService, Ticket, Document, and schema references`
- [ ] `T1.2 remove TicketDocumentLink model behavior and direct ticket/document has_many-through associations`
- [ ] `T1.3 add migration to remove ticket_document_links when no longer referenced`
- [ ] `T1.4 remove or update model tests that only validate direct ticket formal document links`
- [ ] `T1.5 keep Ticket use_case_id and Document use_case_id validations intact`
- [ ] `T1.6 run focused model tests for Ticket, Document, UseCase, and removed link behavior`
- acceptance:
- `tickets no longer expose documents through direct formal attachment associations`
- `documents no longer expose tickets through direct formal attachment associations`
- `ticket_document_links table is removed or no active model path depends on it`
- `ticket and document use-case validation still passes`
- planned_commits:
- `fix(web): remove ticket formal attachment domain`
- `test(web): update formal context association tests`
- PR:
- `tbd`

### Slice 2: Ticket Form Context UI Refactor

- status: `pending`
- branch: `fix/slice-2-ticket-use-case-context-ui`
- pr_title: `fix(slice-2): simplify ticket context UI`
- objective: `make Use Case the visible ticket context association and remove the linked formal document picker from ticket create/edit`
- tasks:
- [ ] `T2.1 move the ticket Use Case field higher in the ticket editor context hierarchy`
- [ ] `T2.2 preserve blank Project-level selection semantics`
- [ ] `T2.3 remove the Linked Documents picker markup from the ticket form`
- [ ] `T2.4 remove unused ticket document picker JavaScript bindings and CSS when no other caller uses them`
- [ ] `T2.5 remove document_ids handling from TicketsController params and form sync paths`
- [ ] `T2.6 add controller/view tests for use-case selection and absence of linked document UI`
- acceptance:
- `ticket editor shows Use Case as the main context selector`
- `ticket editor no longer shows Linked Documents`
- `blank use-case selection remains valid and persists as project-level`
- `valid same-project use-case selection still persists`
- planned_commits:
- `fix(web): simplify ticket context UI`
- `test(web): cover ticket context UI`
- PR:
- `tbd`

### Slice 3: Command-Query and Runtime Bridge Cleanup

- status: `pending`
- branch: `fix/slice-3-ticket-document-command-cleanup`
- pr_title: `fix(slice-3): remove ticket document command paths`
- objective: `remove active command-query and runtime bridge dependencies on direct ticket formal document links without adding inherited context retrieval`
- tasks:
- [ ] `T3.1 remove document_ids sync handling from ticket create/update command-query paths`
- [ ] `T3.2 remove or deprecate AttachDocumentToTicket command registration`
- [ ] `T3.3 update command-query result payloads so tickets no longer include direct document_links`
- [ ] `T3.4 remove runtime bridge direct ticket document lines`
- [ ] `T3.5 update API and service tests that expect document attachment effects`
- [ ] `T3.6 document that inherited use-case/project context retrieval remains deferred`
- acceptance:
- `ticket command-query create/update keep use_case_id support`
- `ticket command-query create/update do not accept direct formal document attachments`
- `AttachDocumentToTicket is unavailable or returns a structured deprecation response`
- `runtime bridge does not read ticket_document_links`
- `no inherited-context retrieval algorithm is introduced`
- planned_commits:
- `fix(web): remove ticket document command paths`
- `test(web): cover ticket command cleanup`
- PR:
- `tbd`

### Slice 4: Formal Artifact Scope Verification

- status: `pending`
- branch: `fix/slice-4-formal-artifact-use-case-scope`
- pr_title: `test(slice-4): verify formal artifact use case scope`
- objective: `verify existing formal artifact ownership rules and close gaps without expanding into evidence/assets or runtime context selection`
- tasks:
- [ ] `T4.1 audit Document, Quiz, QuizEntry, and plan_tracker behavior for project-level versus use-case-level ownership`
- [ ] `T4.2 ensure formal artifacts created with use_case_id stay scoped to that use case`
- [ ] `T4.3 ensure formal artifacts created without use_case_id remain project-level`
- [ ] `T4.4 add missing tests for document and quiz scope behavior where gaps exist`
- [ ] `T4.5 update spec notes if the current model constrains any artifact type differently than expected`
- acceptance:
- `documents preserve optional use-case scope`
- `quizzes preserve optional use-case scope`
- `quiz entries preserve quiz/use-case consistency`
- `project-level formal artifacts remain valid`
- `no repository-only ops artifact storage is invented`
- planned_commits:
- `test(web): verify formal artifact use case scope`
- `docs(ops): record formal artifact scope findings`
- PR:
- `tbd`

### Slice 5: Cycle Validation and Closure

- status: `pending`
- branch: `fix/slice-5-ticket-context-refactor-closure`
- pr_title: `test(slice-5): validate ticket context refactor`
- objective: `run full validation, close tracker state, and record deferred evidence/assets and LLM context work`
- tasks:
- [ ] `T5.1 run targeted model, controller, command-query, and runtime bridge tests touched by the refactor`
- [ ] `T5.2 run full Rails test suite from apps/web`
- [ ] `T5.3 run repository ticket workflow checks`
- [ ] `T5.4 update tracker with validation evidence, residual risks, and deferred work`
- [ ] `T5.5 keep evidence/assets and inherited context retrieval deferred unless explicitly approved as new scope`
- acceptance:
- `all targeted tests pass`
- `full Rails suite passes or blockers are precisely documented`
- `scripts/agent/tickets/check.sh passes`
- `tracker records final status and residual risks`
- planned_commits:
- `test(web): validate ticket context refactor`
- `docs(ops): close ticket context refactor cycle`
- PR:
- `tbd`

## Global Exit Criteria

- Tickets use `use_case_id` as their formal context scope.
- Project-level tickets remain valid with blank `use_case_id`.
- Ticket create/edit no longer exposes direct formal document attachments.
- Direct ticket formal document association code paths are removed or neutralized.
- Documents and quizzes keep optional project-level/use-case-level ownership.
- No evidence/assets uploader is added.
- No final LLM context retrieval policy is implemented.
- Full Rails validation and repository ticket checks pass.

## Validation Command Context

- Rails targeted tests must be run from `apps/web` with `bundle exec bin/rails test <paths>`.
- Full Rails validation must be run from `apps/web` with `bundle exec bin/rails test`.
- Repository workflow checks must run from repository root with `scripts/agent/tickets/check.sh`.

## Non-Goals

- Do not implement ticket evidence/assets.
- Do not add image, PDF, or arbitrary upload processing.
- Do not build final inherited context retrieval for LLMRequestEngine.
- Do not add ticket-level formal document overrides.
- Do not preserve legacy ticket-document links for external users.

