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
- source_quiz:
  - `ops/conv/quiz/2026-05-05-redwright-quiz-me-questionnaire-context-quiz.md`
  - `ops/conv/quiz/2026-05-05-redwright-quiz-me-questionnaire-context-quiz-raw.md`
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

- status: `pr_merged`
- branch: `fix/slice-4-quiz-loop-runtime-controls`
- PR: `https://codeberg.org/adrianpk/redwright/pulls/306`
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

- status: `pr_merged`
- branch: `fix/slice-5-telegram-quiz-commands`
- PR: `https://codeberg.org/adrianpk/redwright/pulls/307`
- merge_target: `dev`
- last_sync_commit: `05fa0d3`

Tasks:

- [x] `T5.1 add slash routing for /quiz`
- [x] `T5.2 add slash routing for /quiz for <use_case>`
- [x] `T5.3 add slash routing for /quiz list`
- [x] `T5.4 connect Telegram commands to the port-agnostic quiz loop runtime`
- [x] `T5.5 render answer, skip, done, and cancel control guidance without verbose noise`
- [x] `T5.6 add simulated or adapter-level tests for project quiz, use-case quiz creation, and listing`

Commits:

- [x] `ae57faf feat(web): expose quiz command queries`
- [x] `dcb7e68 feat(telegram): add quiz commands`
- [x] `453f7ea test(telegram): cover quiz command flows`

Validation:

- [x] `bundle exec bin/rails test test/integration/project_setup_telegram_e2e_test.rb` (pass)
- [x] `bundle exec bin/rails test` (pass)

### Slice 6: Web Quiz Surface and Visual Alignment

- status: `pr_merged`
- branch: `fix/slice-6-web-quiz-surface`
- PR: `https://codeberg.org/adrianpk/redwright/pulls/308`
- merge_target: `dev`
- last_sync_commit: `239b4b3`

Tasks:

- [x] `T6.1 add project navigation entry or route for Quizzes`
- [x] `T6.2 render quiz list for the active project`
- [x] `T6.3 render current-question web loop UI`
- [x] `T6.4 support answer, skip, done, and cancel controls from web`
- [x] `T6.5 avoid showing hidden agent reasoning or prior Q/A lists by default`
- [x] `T6.6 harmonize spacing, typography, cards, controls, and page width with existing project surfaces`
- [x] `T6.7 add controller/system coverage for web quiz navigation and loop controls`

Commits:

- [x] `b9808d0 feat(web): add project quiz surface`
- [x] `e3e669c test(web): cover quiz web flows`

Validation:

- [x] `bundle exec bin/rails test test/controllers/project_quizzes_controller_test.rb` (pass)
- [x] `bundle exec bin/rails test` (pass)

### Slice 7: Ticket/UseCase Context Preparation

- status: `implemented`
- branch: `fix/slice-7-quiz-ticket-context-prep`
- PR: `pending`
- merge_target: `dev`
- last_sync_commit: `4d88306`

Tasks:

- [x] `T7.1 inspect current ticket model and board relationships`
- [x] `T7.2 add optional ticket use_case_id if compatible with the current Kanban domain`
- [x] `T7.3 add query objects or scopes for project/use-case/tag quiz entry retrieval`
- [x] `T7.4 add query objects or scopes for shared tag retrieval across quiz entries and tickets`
- [x] `T7.5 keep this slice out of final prompt-manager implementation`
- [x] `T7.6 add tests for retrieval-oriented query shapes`

Commits:

- [x] `3f7a88d feat(web): associate tickets with use cases`
- [x] `cab27d6 test(web): cover quiz context retrieval scopes`

Validation:

- [x] `bundle exec bin/rails test test/models/ticket_test.rb test/queries/quiz_context/retrieval_query_test.rb` (pass)
- [x] `bundle exec bin/rails test` (pass)

### Slice 8: Configuration, Seeding Review, and Cycle Closure

- status: `implemented`
- branch: `fix/slice-8-quiz-config-and-closure`
- PR: `pending`
- merge_target: `dev`
- last_sync_commit: `85bb9a2`

Tasks:

- [x] `T8.1 add YAML-backed configuration for max questions, follow-up depth, and max tags`
- [x] `T8.2 apply configuration to loop and LLM contract services`
- [x] `T8.3 review demo/test seeding that creates multiple users against the single-user product assumption`
- [x] `T8.4 run targeted and full relevant validation from canonical command locations`
- [x] `T8.5 update tracker and cycle notes with validation evidence and residual risks`
- [x] `T8.6 keep visual/UX alignment as an explicit closure check`

Commits:

- [x] `b05e213 feat(web): add quiz configuration`
- [x] `bd73901 test(web): cover quiz configuration`

Validation:

- [x] `bundle exec bin/rails test test/services/quiz_loops/configuration_test.rb test/services/quiz_loops/question_contract_test.rb test/services/quiz_loops/runtime_test.rb` (pass)
- [x] `bundle exec bin/rails test` (pass)

Closure Notes:

- Demo seeding review: `apps/web/db/seeds.rb` seeds one admin user only, `admin@redwright.local`; additional users are test-only fixtures.
- Visual/UX closure check: Slice 6 introduced Quizzes using the existing Documents/Protocols card language and avoided hidden LLM rationale in the web surface.
- Prompt-manager boundary: retrieval hooks are prepared, but no prompt manager or context-injection runtime was introduced in this cycle.

## Event Log

- `2026-05-05 00:00` state=`planning_complete` note=`formalized the Quiz questionnaire context spec and initialized an eight-slice implementation cycle covering domain, tagging, LLM question loop, runtime controls, Telegram, web, context retrieval preparation, configuration, and closure`
- `2026-05-05 10:00` state=`slice_1_implemented` note=`implemented UseCase, Quiz, and QuizEntry domain foundation with denormalized scope fields, cardinality helpers, model coverage, and green Rails suite`
- `2026-05-05 15:50` state=`slice_2_implemented` note=`implemented transversal Tag and Tagging models for QuizEntry with normalized tag names, denormalized project/use-case scope, scoped retrieval queries, and green Rails suite`
- `2026-05-05 16:05` state=`slice_3_implemented` note=`implemented quiz LLM question contract, prompt intent builder, provider fallback behavior, tag bounding, follow-up depth bounding, and sensitive-information guardrails with green Rails suite`
- `2026-05-05 16:20` state=`slice_4_implemented` note=`implemented port-agnostic quiz loop runtime with project/use-case quiz resolution, answer and skip persistence, done/cancel terminal results, reopening behavior, and green Rails suite`
- `2026-05-05 16:40` state=`slice_5_implemented` note=`implemented Telegram /quiz, /quiz for <use_case>, and /quiz list through command/query handlers and the port-agnostic runtime, with concise rendering and green Rails suite`
- `2026-05-05 17:00` state=`slice_6_implemented` note=`implemented project-scoped web Quiz surface with navigation, list cards, question loop, answer/skip/done/cancel controls, hidden-rationale avoidance, visual alignment, and green Rails suite`
- `2026-05-05 17:20` state=`slice_7_implemented` note=`implemented ticket use-case association and retrieval query shapes for project/use-case/tag quiz entries and tickets without introducing prompt-manager behavior, with green Rails suite`
- `2026-05-05 17:40` state=`slice_8_implemented` note=`implemented YAML-backed quiz limits, applied configuration to contract/runtime, reviewed demo seeding against single-user assumption, recorded closure notes, and confirmed green Rails suite`

## Open Risks

- prompt/context retrieval is prepared through query objects, but final prompt-manager strategy remains future work
- LLM question quality still depends on the future production LLM client and prompt tuning
- web visual alignment passed first implementation, but should be reviewed manually when screenshots are refreshed
