# Cycle Tracker: RedWright Quiz Questionnaire Context

## Metadata

- cycle_id: `cycle-2026-05-05-redwright-quiz-questionnaire-context`
- status: `planned`
- state: `planning_complete`
- updated: `2026-05-05`
- active_slice: `none`
- active_task: `none`
- source_plan: `ops/plans/2026-05-05-redwright-quiz-questionnaire-context-cycle-plan.md`
- source_spec: `ops/specs/specs/2026-05-05-redwright-quiz-questionnaire-context-spec.md`
- source_conversation:
  - `ops/specs/conv/2026-05-05-redwright-quiz-me-questionnaire-context-conv.md`
  - `ops/specs/conv/2026-05-05-redwright-quiz-me-questionnaire-context-conv-raw.md`
- source_draft: `ops/specs/drafts/2026-05-05-redwright-questionnaire-context-and-ticket-driven-engineering-draft.md`

## Slice Progress

### Slice 1: Quiz Domain Foundation

- status: `pr_merged`
- branch: `fix/slice-1-quiz-domain-foundation`
- PR: `https://codeberg.org/adrianpk/redwright/pulls/303`
- merge_target: `dev`
- last_sync_commit: `3d33c8f`

Tasks:

- [x] `T1.1 add UseCase model scoped to Project with normalized project-local slug`
- [x] `T1.2 add Quiz model scoped to Project and optional UseCase`
- [x] `T1.3 add QuizEntry model storing question and answer together`
- [x] `T1.4 include denormalized project_id and use_case_id on QuizEntry`
- [x] `T1.5 enforce one main project quiz per project and one main use-case quiz per use case`
- [x] `T1.6 add focused model tests for cardinality, slug normalization, associations, and status constants`

Commits:

- [x] `ede9d0a feat(web): add project use cases`
- [x] `053e4ac feat(web): add project scoped quizzes`
- [x] `4d9e829 feat(web): add quiz entries`
- [x] `80329b1 feat(web): denormalize quiz entry scope`
- [x] `db3be0f feat(web): add quiz cardinality helpers`
- [x] `ddb6945 test(web): cover quiz domain constraints`
- [x] `7afa7c6 fix(web): generate fallback protocol stack docs`
- [x] `db78d69 test(web): scope document filter assertion`

Validation:

- [x] `bundle exec bin/rails test test/models/use_case_test.rb test/models/quiz_test.rb test/models/quiz_entry_test.rb test/models/project_test.rb` (pass)
- [x] `bundle exec bin/rails test test/controllers/documents_controller_test.rb:74` (pass)
- [x] `bundle exec bin/rails test test/services/project_setup/context_loop_service_test.rb:357 test/services/project_protocols/initialization_service_test.rb` (pass)
- [x] `bundle exec bin/rails test` (pass)

### Slice 2: Transversal Tagging Foundation

- status: `pr_merged`
- branch: `fix/slice-2-quiz-transversal-tagging`
- PR: `https://codeberg.org/adrianpk/redwright/pulls/304`
- merge_target: `dev`
- last_sync_commit: `4fa24a0`

Tasks:

- [x] `T2.1 inspect current ticket/tag-related persistence and avoid duplicate tag mechanisms`
- [x] `T2.2 add or align Tag and Tagging models with polymorphic taggables`
- [x] `T2.3 normalize tags to lowercase kebab-case`
- [x] `T2.4 denormalize project_id and use_case_id on taggings for future retrieval queries`
- [x] `T2.5 support tagging QuizEntry records`
- [x] `T2.6 add tests for normalization, tag reuse, polymorphic tagging, and project/use-case scoped queries`

Commits:

- [x] `cda6d9b feat(web): add transversal tagging models`
- [x] `19c45a8 test(web): cover quiz tagging queries`

Validation:

- [x] `bundle exec bin/rails test test/models/tag_test.rb test/models/tagging_test.rb test/models/quiz_entry_test.rb` (pass)
- [x] `bundle exec bin/rails test` (pass)

### Slice 3: Quiz Loop Contract and LLM Question Service

- status: `pr_merged`
- branch: `fix/slice-3-quiz-loop-llm-contract`
- PR: `https://codeberg.org/adrianpk/redwright/pulls/305`
- merge_target: `dev`
- last_sync_commit: `029c989`

Tasks:

- [x] `T3.1 define a structured LLM output contract for next quiz question generation`
- [x] `T3.2 reuse or adapt existing project setup question machinery where practical`
- [x] `T3.3 include tag suggestions in the LLM interpretation flow`
- [x] `T3.4 enforce max question count, max follow-up depth, and max tag count from configuration`
- [x] `T3.5 add guardrails against secrets, credentials, tokens, passwords, and PII`
- [x] `T3.6 add deterministic fallback behavior for unavailable or invalid LLM output`

Commits:

- [x] `69f3367 feat(web): add quiz question generation contract`
- [x] `fb9742b test(web): cover quiz LLM contract guardrails`

Validation:

- [x] `bundle exec bin/rails test test/services/quiz_loops/question_contract_test.rb test/services/quiz_loops/question_provider_test.rb` (pass)
- [x] `bundle exec bin/rails test` (pass)

### Slice 4: Quiz Loop Runtime and Controls

- status: `implemented`
- branch: `fix/slice-4-quiz-loop-runtime-controls`
- PR: `pending`
- merge_target: `dev`
- last_sync_commit: `d041b6b`

Tasks:

- [x] `T4.1 add a port-agnostic quiz loop service`
- [x] `T4.2 resolve or create the project-level quiz`
- [x] `T4.3 resolve or create use cases and their main quizzes`
- [x] `T4.4 persist answered and skipped QuizEntry records`
- [x] `T4.5 implement done and cancel semantics without forbidding later reopening`
- [x] `T4.6 add tests for project quiz, use-case quiz, skip, done, cancel, and reopening behavior`

Commits:

- [x] `fb07e05 feat(web): add quiz loop runtime`
- [x] `ee3a282 test(web): cover quiz loop controls`

Validation:

- [x] `bundle exec bin/rails test test/services/quiz_loops/runtime_test.rb` (pass)
- [x] `bundle exec bin/rails test` (pass)

### Slice 5: Telegram Quiz Commands

- status: `planned`
- branch: `fix/slice-5-telegram-quiz-commands`
- PR: `pending`
- merge_target: `dev`
- last_sync_commit: `pending`

Tasks:

- [ ] `T5.1 add slash routing for /quiz`
- [ ] `T5.2 add slash routing for /quiz for <use_case>`
- [ ] `T5.3 add slash routing for /quiz list`
- [ ] `T5.4 connect Telegram commands to the port-agnostic quiz loop runtime`
- [ ] `T5.5 render answer, skip, done, and cancel control guidance without verbose noise`
- [ ] `T5.6 add simulated or adapter-level tests for project quiz, use-case quiz creation, and listing`

Commits:

- [ ] `pending`

Validation:

- [ ] `pending`

### Slice 6: Web Quiz Surface and Visual Alignment

- status: `planned`
- branch: `fix/slice-6-web-quiz-surface`
- PR: `pending`
- merge_target: `dev`
- last_sync_commit: `pending`

Tasks:

- [ ] `T6.1 add project navigation entry or route for Quizzes`
- [ ] `T6.2 render quiz list for the active project`
- [ ] `T6.3 render current-question web loop UI`
- [ ] `T6.4 support answer, skip, done, and cancel controls from web`
- [ ] `T6.5 avoid showing hidden agent reasoning or prior Q/A lists by default`
- [ ] `T6.6 harmonize spacing, typography, cards, controls, and page width with existing project surfaces`
- [ ] `T6.7 add controller/system coverage for web quiz navigation and loop controls`

Commits:

- [ ] `pending`

Validation:

- [ ] `pending`

### Slice 7: Ticket/UseCase Context Preparation

- status: `planned`
- branch: `fix/slice-7-quiz-ticket-context-prep`
- PR: `pending`
- merge_target: `dev`
- last_sync_commit: `pending`

Tasks:

- [ ] `T7.1 inspect current ticket model and board relationships`
- [ ] `T7.2 add optional ticket use_case_id if compatible with the current Kanban domain`
- [ ] `T7.3 add query objects or scopes for project/use-case/tag quiz entry retrieval`
- [ ] `T7.4 add query objects or scopes for shared tag retrieval across quiz entries and tickets`
- [ ] `T7.5 keep this slice out of final prompt-manager implementation`
- [ ] `T7.6 add tests for retrieval-oriented query shapes`

Commits:

- [ ] `pending`

Validation:

- [ ] `pending`

### Slice 8: Configuration, Seeding Review, and Cycle Closure

- status: `planned`
- branch: `fix/slice-8-quiz-config-and-closure`
- PR: `pending`
- merge_target: `dev`
- last_sync_commit: `pending`

Tasks:

- [ ] `T8.1 add YAML-backed configuration for max questions, follow-up depth, and max tags`
- [ ] `T8.2 apply configuration to loop and LLM contract services`
- [ ] `T8.3 review demo/test seeding that creates multiple users against the single-user product assumption`
- [ ] `T8.4 run targeted and full relevant validation from canonical command locations`
- [ ] `T8.5 update tracker and cycle notes with validation evidence and residual risks`
- [ ] `T8.6 keep visual/UX alignment as an explicit closure check`

Commits:

- [ ] `pending`

Validation:

- [ ] `pending`

## Event Log

- `2026-05-05 00:00` state=`planning_complete` note=`formalized the Quiz questionnaire context spec and initialized an eight-slice implementation cycle covering domain, tagging, LLM question loop, runtime controls, Telegram, web, context retrieval preparation, configuration, and closure`
- `2026-05-05 10:00` state=`slice_1_implemented` note=`implemented UseCase, Quiz, and QuizEntry domain foundation with denormalized scope fields, cardinality helpers, model coverage, and green Rails suite`
- `2026-05-05 15:50` state=`slice_2_implemented` note=`implemented transversal Tag and Tagging models for QuizEntry with normalized tag names, denormalized project/use-case scope, scoped retrieval queries, and green Rails suite`
- `2026-05-05 16:05` state=`slice_3_implemented` note=`implemented quiz LLM question contract, prompt intent builder, provider fallback behavior, tag bounding, follow-up depth bounding, and sensitive-information guardrails with green Rails suite`
- `2026-05-05 16:20` state=`slice_4_implemented` note=`implemented port-agnostic quiz loop runtime with project/use-case quiz resolution, answer and skip persistence, done/cancel terminal results, reopening behavior, and green Rails suite`

## Open Risks

- nullable `use_case_id` uniqueness may need careful Rails/SQLite handling
- existing ticket/tag semantics must be inspected before adding transversal tagging
- LLM question generation should reuse existing setup machinery where practical
- web UI must stay visually aligned with existing product surfaces and avoid scaffold-style CRUD
- the cycle prepares context retrieval but intentionally avoids implementing a full prompt manager
