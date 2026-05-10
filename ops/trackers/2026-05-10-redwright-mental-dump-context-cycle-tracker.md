# Cycle Tracker: RedWright Mental Dump Context

## Metadata

- cycle_id: `cycle-2026-05-10-redwright-mental-dump-context`
- status: `in_progress`
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
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `05b2bab`

Tasks:

- [x] `T4.1 inspect existing web navigation and quiz routes`
- [x] `T4.2 add Conversation or Conv route and navigation label`
- [x] `T4.3 render sibling cards for Dump and Quizzes`
- [x] `T4.4 preserve existing Quiz behavior under the new entrypoint`
- [x] `T4.5 add navigation and routing tests`

Commits:

- [x] `d9ef54b feat(web): add conversation entrypoint`
- [x] `f121ff1 test(web): cover conversation navigation`
- [x] `05b2bab docs(ops): update conversation entrypoint tracker`

Validation:

- [x] `web users enter Dumps and Quizzes through a shared Conversation area`
- [x] `Quizzes remain reachable and behavior-compatible`
- [x] `Dump and Quizzes remain sibling modes`
- [x] `bundle exec bin/rails test test/controllers/project_conversations_controller_test.rb test/controllers/project_quizzes_controller_test.rb`

### Slice 5: Telegram Dump Commands

- status: `pending`
- branch: `fix/slice-5-telegram-dump-commands`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T5.1 add slash routing for /dump`
- [ ] `T5.2 add slash routing for /dump for <use_case>`
- [ ] `T5.3 add slash routing for /dump done, /dump cancel, /dump list, and /dump show`
- [ ] `T5.4 route ordinary messages into the active dump session when appropriate`
- [ ] `T5.5 render concise acknowledgements without echoing full dumps each turn`
- [ ] `T5.6 add adapter-level tests for command and active-session flows`

Commits:

- [ ] `feat(telegram): add dump commands`
- [ ] `test(telegram): cover dump command flows`

Validation:

- [ ] `/dump` starts or resumes project-level dumps`
- [ ] `/dump for <use_case>` starts or resumes use-case-level dumps`
- [ ] `active dump messages append entries`

### Slice 6: Web Dump Surface

- status: `pending`
- branch: `fix/slice-6-web-dump-surface`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T6.1 add Dump routes and controller actions under the project Conversation area`
- [ ] `T6.2 render dump list with project/use-case scope indicators`
- [ ] `T6.3 render focused repeated-post capture UI`
- [ ] `T6.4 render polished raw capture preview and curated dump view`
- [ ] `T6.5 support continue, append, done, cancel, show, and curate controls`
- [ ] `T6.6 add controller/system coverage for dump web flows`

Commits:

- [ ] `feat(web): add dump surface`
- [ ] `test(web): cover dump web flows`

Validation:

- [ ] `web users can start and continue dumps from Conversation`
- [ ] `the UI favors repeated short posts over manual long-document editing`
- [ ] `raw polished and curated views are visible when available`

### Slice 7: Dump Tags And Context Retrieval

- status: `pending`
- branch: `fix/slice-7-dump-context-retrieval`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T7.1 align Dump tagging with the existing or planned Quiz tagging model`
- [ ] `T7.2 add query scopes or query objects for project/use-case/tag dump retrieval`
- [ ] `T7.3 integrate curated dumps with the dumps context provider`
- [ ] `T7.4 avoid silently injecting active uncurated dumps into unrelated ticket work`
- [ ] `T7.5 add tests for tagging, retrieval, and context inclusion/omission`

Commits:

- [ ] `feat(llm): add product dump context retrieval`
- [ ] `test(llm): cover dump context selection`

Validation:

- [ ] `curated dumps are selectable through the dumps context layer`
- [ ] `retrieval can filter by project and use case`
- [ ] `active uncurated dumps do not silently outrank curated context`

### Slice 8: Configuration, Docs, And Closure

- status: `pending`
- branch: `fix/slice-8-dump-config-docs`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T8.1 add configuration for dump limits, polishing behavior, and curation behavior`
- [ ] `T8.2 document Conversation, Dump, and Quiz relationship`
- [ ] `T8.3 document Telegram and web dump usage`
- [ ] `T8.4 update user guide and relevant reference docs for the new Conversation/Dump functionality`
- [ ] `T8.5 run targeted and relevant broader validation`
- [ ] `T8.6 update tracker with final validation and residual risks`

Commits:

- [ ] `feat(web): add dump configuration`
- [ ] `docs(user-guide): document conversation dump workflow`
- [ ] `docs(ops): close dump context cycle`

Validation:

- [ ] `dump limits and behavior are configurable`
- [ ] `durable docs explain how Dump relates to Quiz and Conversation`
- [ ] `validation results are recorded`

## Event Log

- `2026-05-10` state=`planning_complete` note=`Created mental dump context cycle plan and tracker from the approved spec request; implementation is capped at 8 slices and intentionally mirrors the Quiz cycle where appropriate.`
- `2026-05-10` state=`awaiting_review` note=`Slice 1 completed with Dump and DumpEntry domain models, migrations, schema update, project/use-case associations, and focused model tests.`
- `2026-05-10` state=`next_slice` note=`Slice 1 merged through PR #414 and dev synced to 24ec44c.`
- `2026-05-10` state=`awaiting_review` note=`Slice 2 completed with dump entry and curated dump contracts, deterministic fallback behavior, secret redaction guardrails, and focused provider tests.`
- `2026-05-10` state=`next_slice` note=`Slice 2 merged through PR #415 and follow-up PR #416; dev synced to 59f440c.`
- `2026-05-10` state=`awaiting_review` note=`Slice 3 completed with port-agnostic dump runtime for open, append, done, cancel, list, show, and curate operations plus focused service tests.`
- `2026-05-10` state=`next_slice` note=`Slice 3 merged through PR #417 and dev synced to e3c5eb8.`
- `2026-05-10` state=`awaiting_review` note=`Slice 4 completed with the project Conversation entrypoint, Conv top navigation, Dump and Quizzes sibling cards, preserved Quizzes routing, and focused controller coverage.`
