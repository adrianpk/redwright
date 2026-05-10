# Cycle Tracker: RedWright Mental Dump Context

## Metadata

- cycle_id: `cycle-2026-05-10-redwright-mental-dump-context`
- status: `planned`
- state: `planning_complete`
- updated: `2026-05-10`
- active_slice: `none`
- active_task: `none`
- plan: `ops/plans/2026-05-10-redwright-mental-dump-context-cycle-plan.md`
- spec: `ops/specs/specs/2026-05-10-redwright-mental-dump-context-spec.md`
- related_spec: `ops/specs/specs/2026-05-05-redwright-quiz-questionnaire-context-spec.md`

## Slice Progress

### Slice 1: Dump Domain Foundation

- status: `pending`
- branch: `fix/slice-1-dump-domain-foundation`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T1.1 add Dump model scoped to Project and optional UseCase`
- [ ] `T1.2 add DumpEntry model storing raw_input, polished_input, position, and scope fields`
- [ ] `T1.3 add capture and curation lifecycle constants`
- [ ] `T1.4 implement title/slug generation for unnamed dumps`
- [ ] `T1.5 add focused model tests for associations, scope, ordering, lifecycle, and slug behavior`

Commits:

- [ ] `feat(web): add dump domain models`
- [ ] `test(web): cover dump domain constraints`

Validation:

- [ ] `dumps can be project-level or use-case-level`
- [ ] `dump entries preserve submitted chunks and polished chunks`
- [ ] `dump lifecycle distinguishes capture from curation`

### Slice 2: Dump LLM Contracts And Fallbacks

- status: `pending`
- branch: `fix/slice-2-dump-llm-contracts`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T2.1 define entry polish output contract`
- [ ] `T2.2 define curated dump output contract`
- [ ] `T2.3 add deterministic fallback for unavailable or invalid LLM output`
- [ ] `T2.4 add sensitive-information guardrails for secrets and unnecessary PII`
- [ ] `T2.5 add tests for valid output, invalid output, fallback persistence, and hidden rationale boundaries`

Commits:

- [ ] `feat(web): add dump curation contracts`
- [ ] `test(web): cover dump LLM fallbacks`

Validation:

- [ ] `submitted entries persist even if LLM processing fails`
- [ ] `curated dump output follows the spec structure`
- [ ] `LLM rationale is not user-facing`

### Slice 3: Dump Runtime And Controls

- status: `pending`
- branch: `fix/slice-3-dump-runtime-controls`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T3.1 add a port-agnostic dump loop service`
- [ ] `T3.2 resolve or create project-level and use-case-level dumps`
- [ ] `T3.3 append free-form chunks as ordered DumpEntry records`
- [ ] `T3.4 implement done and cancel with distinct lifecycle behavior`
- [ ] `T3.5 implement list, show, and curate operations`
- [ ] `T3.6 add service tests for start, append, done, cancel, resume, list, show, and curate`

Commits:

- [ ] `feat(web): add dump runtime`
- [ ] `test(web): cover dump runtime controls`

Validation:

- [ ] `users can build one dump from multiple short posts`
- [ ] `done closes capture and creates or refreshes curated output`
- [ ] `cancel stops active capture without deleting saved entries`

### Slice 4: Conversation Entrypoint

- status: `pending`
- branch: `fix/slice-4-conversation-entrypoint`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T4.1 inspect existing web navigation and quiz routes`
- [ ] `T4.2 add Conversation or Conv route and navigation label`
- [ ] `T4.3 render sibling cards for Dump and Quizzes`
- [ ] `T4.4 preserve existing Quiz behavior under the new entrypoint`
- [ ] `T4.5 add navigation and routing tests`

Commits:

- [ ] `feat(web): add conversation entrypoint`
- [ ] `test(web): cover conversation navigation`

Validation:

- [ ] `web users enter Dumps and Quizzes through a shared Conversation area`
- [ ] `Quizzes remain reachable and behavior-compatible`
- [ ] `Dump and Quizzes remain sibling modes`

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
- [ ] `T8.4 run targeted and relevant broader validation`
- [ ] `T8.5 update tracker with final validation and residual risks`

Commits:

- [ ] `feat(web): add dump configuration`
- [ ] `docs(ops): close dump context cycle`

Validation:

- [ ] `dump limits and behavior are configurable`
- [ ] `durable docs explain how Dump relates to Quiz and Conversation`
- [ ] `validation results are recorded`

## Event Log

- `2026-05-10` state=`planning_complete` note=`Created mental dump context cycle plan and tracker from the approved spec request; implementation is capped at 8 slices and intentionally mirrors the Quiz cycle where appropriate.`
