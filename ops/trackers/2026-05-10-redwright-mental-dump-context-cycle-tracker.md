# Cycle Tracker: RedWright Mental Dump Context

## Metadata

- cycle_id: `cycle-2026-05-10-redwright-mental-dump-context`
- status: `implemented_pending_review`
- state: `awaiting_review`
- updated: `2026-05-10`
- active_slice: `none`
- active_task: `none`
- plan: `ops/plans/2026-05-10-redwright-mental-dump-context-cycle-plan.md`
- spec: `ops/specs/specs/2026-05-10-redwright-mental-dump-context-spec.md`
- related_spec: `ops/specs/specs/2026-05-05-redwright-quiz-questionnaire-context-spec.md`

## Slice Progress

### Slice 1: Dump Domain Foundation

- status: `completed`
- branch: `fix/slice-1-dump-domain-foundation`
- PR: `#414`
- merge_target: `dev`
- last_sync_commit: `24ec44c`

Tasks:

- [x] `T1.1 add Dump model scoped to Project and optional UseCase`
- [x] `T1.2 add DumpEntry model storing raw_input, polished_input, position, and scope fields`
- [x] `T1.3 add capture and curation lifecycle constants`
- [x] `T1.4 implement title/slug generation for unnamed dumps`
- [x] `T1.5 add focused model tests for associations, scope, ordering, lifecycle, and slug behavior`

Commits:

- [x] `e8d7d26 feat(web): add dump domain models`
- [x] `bdc78df test(web): cover dump domain constraints`

Validation:

- [x] `dumps can be project-level or use-case-level`
- [x] `dump entries preserve submitted chunks and polished chunks`
- [x] `dump lifecycle distinguishes capture from curation`
- [x] `bundle exec bin/rails test test/models/dump_test.rb test/models/dump_entry_test.rb`

### Slice 2: Dump LLM Contracts And Fallbacks

- status: `completed`
- branch: `fix/slice-2-dump-llm-contracts`
- PR: `#415`
- merge_target: `dev`
- last_sync_commit: `59f440c`

Tasks:

- [x] `T2.1 define entry polish output contract`
- [x] `T2.2 define curated dump output contract`
- [x] `T2.3 add deterministic fallback for unavailable or invalid LLM output`
- [x] `T2.4 add sensitive-information guardrails for secrets and unnecessary PII`
- [x] `T2.5 add tests for valid output, invalid output, fallback persistence, and hidden rationale boundaries`

Commits:

- [x] `1c78b49 feat(web): add dump curation contracts`
- [x] `5308730 test(web): cover dump LLM fallbacks`

Validation:

- [x] `submitted entries persist even if LLM processing fails`
- [x] `curated dump output follows the spec structure`
- [x] `LLM rationale is not user-facing`
- [x] `bundle exec bin/rails test test/services/dump_loops/entry_contract_test.rb test/services/dump_loops/curated_dump_contract_test.rb test/services/dump_loops/curation_provider_test.rb`

### Slice 3: Dump Runtime And Controls

- status: `completed`
- branch: `fix/slice-3-dump-runtime-controls`
- PR: `#417`
- merge_target: `dev`
- last_sync_commit: `e3c5eb8`

Tasks:

- [x] `T3.1 add a port-agnostic dump loop service`
- [x] `T3.2 resolve or create project-level and use-case-level dumps`
- [x] `T3.3 append free-form chunks as ordered DumpEntry records`
- [x] `T3.4 implement done and cancel with distinct lifecycle behavior`
- [x] `T3.5 implement list, show, and curate operations`
- [x] `T3.6 add service tests for start, append, done, cancel, resume, list, show, and curate`

Commits:

- [x] `e2efe14 feat(web): add dump runtime`
- [x] `45f50f5 test(web): cover dump runtime controls`
- [x] `e3c5eb8 docs(ops): update dump runtime tracker`

Validation:

- [x] `users can build one dump from multiple short posts`
- [x] `done closes capture and creates or refreshes curated output`
- [x] `cancel stops active capture without deleting saved entries`
- [x] `bundle exec bin/rails test test/services/dump_loops/runtime_test.rb`
- [x] `bundle exec bin/rails test test/services/dump_loops/entry_contract_test.rb test/services/dump_loops/curated_dump_contract_test.rb test/services/dump_loops/curation_provider_test.rb test/services/dump_loops/runtime_test.rb`

### Slice 4: Conversation Entrypoint

- status: `completed`
- branch: `fix/slice-4-conversation-entrypoint`
- PR: `#418`
- merge_target: `dev`
- last_sync_commit: `6eadcb8`

Tasks:

- [x] `T4.1 inspect existing web navigation and quiz routes`
- [x] `T4.2 add Conversation or Conv route and navigation label`
- [x] `T4.3 render sibling cards for Dump and Quizzes`
- [x] `T4.4 preserve existing Quiz behavior under the new entrypoint`
- [x] `T4.5 add navigation and routing tests`

Commits:

- [x] `d9ef54b feat(web): add conversation entrypoint`
- [x] `f121ff1 test(web): cover conversation navigation`
- [x] `6eadcb8 docs(ops): update conversation entrypoint tracker`

Validation:

- [x] `web users enter Dumps and Quizzes through a shared Conversation area`
- [x] `Quizzes remain reachable and behavior-compatible`
- [x] `Dump and Quizzes remain sibling modes`
- [x] `bundle exec bin/rails test test/controllers/project_conversations_controller_test.rb test/controllers/project_quizzes_controller_test.rb`

### Slice 5: Telegram Dump Commands

- status: `completed`
- branch: `fix/slice-5-telegram-dump-commands`
- PR: `#419`
- merge_target: `dev`
- last_sync_commit: `5ec1795`

Tasks:

- [x] `T5.1 add slash routing for /dump`
- [x] `T5.2 add slash routing for /dump for <use_case>`
- [x] `T5.3 add slash routing for /dump done, /dump cancel, /dump list, and /dump show`
- [x] `T5.4 route ordinary messages into the active dump session when appropriate`
- [x] `T5.5 render concise acknowledgements without echoing full dumps each turn`
- [x] `T5.6 add adapter-level tests for command and active-session flows`

Commits:

- [x] `6245996 feat(telegram): add dump commands`
- [x] `cbe8817 test(telegram): cover dump command flows`
- [x] `5ec1795 docs(ops): update dump telegram tracker`

Validation:

- [x] `/dump` starts or resumes project-level dumps`
- [x] `/dump for <use_case>` starts or resumes use-case-level dumps`
- [x] `active dump messages append entries`
- [x] `/dump done, /dump cancel, /dump list, and /dump show are routed through Telegram`
- [x] `Telegram append acknowledgements do not echo full submitted dump text`
- [x] `bundle exec bin/rails test test/services/dump_loops/command_query_handlers_test.rb test/integration/project_setup_telegram_e2e_test.rb`

### Slice 6: Web Dump Surface

- status: `completed`
- branch: `fix/slice-6-web-dump-surface`
- PR: `#420`
- merge_target: `dev`
- last_sync_commit: `6c955c8`

Tasks:

- [x] `T6.1 add Dump routes and controller actions under the project Conversation area`
- [x] `T6.2 render dump list with project/use-case scope indicators`
- [x] `T6.3 render focused repeated-post capture UI`
- [x] `T6.4 render polished raw capture preview and curated dump view`
- [x] `T6.5 support continue, append, done, cancel, show, and curate controls`
- [x] `T6.6 add controller/system coverage for dump web flows`

Commits:

- [x] `49ea528 feat(web): add dump surface`
- [x] `f90d3f9 test(web): cover dump web flows`
- [x] `6c955c8 docs(ops): update dump web surface tracker`

Validation:

- [x] `web users can start and continue dumps from Conversation`
- [x] `the UI favors repeated short posts over manual long-document editing`
- [x] `raw polished and curated views are visible when available`
- [x] `web supports done, cancel, show, and curate controls`
- [x] `bundle exec bin/rails test test/controllers/project_dumps_controller_test.rb test/controllers/project_conversations_controller_test.rb`

### Slice 7: Dump Tags And Context Retrieval

- status: `completed`
- branch: `fix/slice-7-dump-context-retrieval`
- PR: `#421`
- merge_target: `dev`
- last_sync_commit: `e9d52dc`

Tasks:

- [x] `T7.1 align Dump tagging with the existing or planned Quiz tagging model`
- [x] `T7.2 add query scopes or query objects for project/use-case/tag dump retrieval`
- [x] `T7.3 integrate curated dumps with the dumps context provider`
- [x] `T7.4 avoid silently injecting active uncurated dumps into unrelated ticket work`
- [x] `T7.5 add tests for tagging, retrieval, and context inclusion/omission`

Commits:

- [x] `97f36d1 feat(llm): add product dump context retrieval`
- [x] `1fecbc5 test(llm): cover dump context selection`
- [x] `e9d52dc docs(ops): update dump context retrieval tracker`

Validation:

- [x] `curated dumps are selectable through the dumps context layer`
- [x] `retrieval can filter by project and use case`
- [x] `tag retrieval is compatible with Quiz tagging`
- [x] `active uncurated dumps do not silently outrank curated context`
- [x] `bundle exec bin/rails test test/models/dump_test.rb test/queries/dump_context/retrieval_query_test.rb test/services/agent_ticket_execution/context_composer_test.rb`

### Slice 8: Configuration, Docs, And Closure

- status: `awaiting_review`
- branch: `fix/slice-8-dump-config-docs`
- PR: `#422`
- merge_target: `dev`
- last_sync_commit: `PENDING_SELF_HASH`

Tasks:

- [x] `T8.1 add configuration for dump limits, polishing behavior, and curation behavior`
- [x] `T8.2 document Conversation, Dump, and Quiz relationship`
- [x] `T8.3 document Telegram and web dump usage`
- [x] `T8.4 update user guide and relevant reference docs for the new Conversation/Dump functionality`
- [x] `T8.5 run targeted and relevant broader validation`
- [x] `T8.6 update tracker with final validation and residual risks`

Commits:

- [x] `c711044 feat(web): add dump configuration`
- [x] `a099824 docs(user-guide): document conversation dump workflow`
- [x] `PENDING_SELF_HASH docs(ops): close dump context cycle`

Validation:

- [x] `dump limits and behavior are configurable`
- [x] `durable docs explain how Dump relates to Quiz and Conversation`
- [x] `validation results are recorded`
- [x] `bundle exec bin/rails test test/services/dump_loops/configuration_test.rb test/services/dump_loops/curation_provider_test.rb test/services/agent_ticket_execution/context_composer_test.rb`
- [x] `bundle exec bin/rails test test/models/dump_test.rb test/models/dump_entry_test.rb test/queries/dump_context/retrieval_query_test.rb test/services/dump_loops/configuration_test.rb test/services/dump_loops/entry_contract_test.rb test/services/dump_loops/curated_dump_contract_test.rb test/services/dump_loops/curation_provider_test.rb test/services/dump_loops/runtime_test.rb test/services/dump_loops/command_query_handlers_test.rb test/controllers/project_conversations_controller_test.rb test/controllers/project_dumps_controller_test.rb test/services/agent_ticket_execution/context_composer_test.rb test/integration/project_setup_telegram_e2e_test.rb`

## Residual Risks

- Dump context ranking is conservative and should be tuned from real ticket execution traces after this PR is merged.
- Entry polishing and dump curation depend on provider availability when enabled; deterministic fallbacks preserve captured content but do not produce the same curated quality.
- Database-backed dumps and repository dump artifacts now share the `dumps` context layer, so future ranking changes should keep source diagnostics explicit.

## Event Log

- `2026-05-10` state=`planning_complete` note=`Created mental dump context cycle plan and tracker from the approved spec request; implementation is capped at 8 slices and intentionally mirrors the Quiz cycle where appropriate.`
- `2026-05-10` state=`awaiting_review` note=`Slice 1 completed with Dump and DumpEntry domain models, migrations, schema update, project/use-case associations, and focused model tests.`
- `2026-05-10` state=`next_slice` note=`Slice 1 merged through PR #414 and dev synced to 24ec44c.`
- `2026-05-10` state=`awaiting_review` note=`Slice 2 completed with dump entry and curated dump contracts, deterministic fallback behavior, secret redaction guardrails, and focused provider tests.`
- `2026-05-10` state=`next_slice` note=`Slice 2 merged through PR #415 and follow-up PR #416; dev synced to 59f440c.`
- `2026-05-10` state=`awaiting_review` note=`Slice 3 completed with port-agnostic dump runtime for open, append, done, cancel, list, show, and curate operations plus focused service tests.`
- `2026-05-10` state=`next_slice` note=`Slice 3 merged through PR #417 and dev synced to e3c5eb8.`
- `2026-05-10` state=`awaiting_review` note=`Slice 4 completed with the project Conversation entrypoint, Conv top navigation, Dump and Quizzes sibling cards, preserved Quizzes routing, and focused controller coverage.`
- `2026-05-10` state=`next_slice` note=`Slice 4 merged through PR #418 and dev synced to 6eadcb8.`
- `2026-05-10` state=`awaiting_review` note=`Slice 5 completed with Telegram /dump commands, use-case scoped dump start, active dump message append routing, done/cancel/list/show controls, concise acknowledgements, and focused CommandQuery plus Telegram integration coverage.`
- `2026-05-10` state=`next_slice` note=`Slice 5 merged through PR #419 and dev synced to 5ec1795.`
- `2026-05-10` state=`awaiting_review` note=`Slice 6 completed with Conversation-linked web Dump routes, project/use-case dump list cards, repeated-post append UI, raw and curated previews, lifecycle controls, and focused controller coverage.`
- `2026-05-10` state=`next_slice` note=`Slice 6 merged through PR #420 and dev synced to 6c955c8.`
- `2026-05-10` state=`awaiting_review` note=`Slice 7 completed with Dump tagging parity, project/use-case/tag retrieval query, database curated dump inclusion in the dumps context provider, explicit omission for active uncurated dumps, and focused model/query/context composer coverage.`
- `2026-05-10` state=`next_slice` note=`Slice 7 merged through PR #421 and dev synced to e9d52dc.`
- `2026-05-10` state=`awaiting_review` note=`Slice 8 opened PR #422 with dump configuration, user guide and reference documentation, final validation, and cycle closure tracking.`
