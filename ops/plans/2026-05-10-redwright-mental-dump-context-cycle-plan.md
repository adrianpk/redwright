# Cycle Plan: RedWright Mental Dump Context

## Metadata

- cycle_id: `cycle-2026-05-10-redwright-mental-dump-context`
- status: `planned`
- owner: `adrianpk`
- created: `2026-05-10`
- updated: `2026-05-10`
- goal: `deliver a project- and use-case-scoped Dump system under a shared Conversation entrypoint, preserving user-led multi-entry context capture, polished raw consolidation, curated dump output, and selectable dump context for later LLM work`
- scope: `feature`
- source_spec: `ops/specs/specs/2026-05-10-redwright-mental-dump-context-spec.md`
- related_spec: `ops/specs/specs/2026-05-05-redwright-quiz-questionnaire-context-spec.md`

## Slice List

### Slice 1: Dump Domain Foundation

- status: `planned`
- branch: `fix/slice-1-dump-domain-foundation`
- pr_title: `feat(slice-1): add dump domain foundation`
- objective: `introduce Dump and DumpEntry persistence with project/use-case scoping, lifecycle state, consolidated polished raw body, curated body, and retrieval-oriented denormalized fields`
- tasks:
- [ ] `T1.1 add Dump model scoped to Project and optional UseCase`
- [ ] `T1.2 add DumpEntry model storing raw_input, polished_input, position, and scope fields`
- [ ] `T1.3 add capture and curation lifecycle constants`
- [ ] `T1.4 implement title/slug generation for unnamed dumps`
- [ ] `T1.5 add focused model tests for associations, scope, ordering, lifecycle, and slug behavior`
- acceptance:
- `dumps can be project-level or use-case-level`
- `dump entries preserve submitted chunks and polished chunks`
- `dump lifecycle distinguishes capture from curation`
- `retrieval fields support project/use-case scoped lookup`
- planned_commits:
- `feat(web): add dump domain models`
- `test(web): cover dump domain constraints`

### Slice 2: Dump LLM Contracts And Fallbacks

- status: `planned`
- branch: `fix/slice-2-dump-llm-contracts`
- pr_title: `feat(slice-2): add dump LLM contracts`
- objective: `define fakeable LLM-backed contracts for entry polishing, aggregate raw consolidation, curated dump output, tag suggestions, and derived thread hints with deterministic fallbacks`
- tasks:
- [ ] `T2.1 define entry polish output contract`
- [ ] `T2.2 define curated dump output contract`
- [ ] `T2.3 add deterministic fallback for unavailable or invalid LLM output`
- [ ] `T2.4 add sensitive-information guardrails for secrets and unnecessary PII`
- [ ] `T2.5 add tests for valid output, invalid output, fallback persistence, and hidden rationale boundaries`
- acceptance:
- `each submitted entry is persisted even if LLM processing fails`
- `polished raw capture can be updated from entries`
- `curated dump output follows the spec structure`
- `LLM rationale is not user-facing`
- planned_commits:
- `feat(web): add dump curation contracts`
- `test(web): cover dump LLM fallbacks`

### Slice 3: Dump Runtime And Controls

- status: `planned`
- branch: `fix/slice-3-dump-runtime-controls`
- pr_title: `feat(slice-3): add dump runtime controls`
- objective: `implement the port-agnostic dump runtime for start, continue, append, done, cancel, list, show, and curate semantics`
- tasks:
- [ ] `T3.1 add a port-agnostic dump loop service`
- [ ] `T3.2 resolve or create project-level and use-case-level dumps`
- [ ] `T3.3 append free-form chunks as ordered DumpEntry records`
- [ ] `T3.4 implement done and cancel with distinct lifecycle behavior`
- [ ] `T3.5 implement list, show, and curate operations`
- [ ] `T3.6 add service tests for start, append, done, cancel, resume, list, show, and curate`
- acceptance:
- `users can build one dump from multiple short posts`
- `done closes capture and creates or refreshes curated output`
- `cancel stops the active capture without deleting saved entries`
- `runtime behavior is independent of Telegram or web ports`
- planned_commits:
- `feat(web): add dump runtime`
- `test(web): cover dump runtime controls`

### Slice 4: Conversation Entrypoint

- status: `planned`
- branch: `fix/slice-4-conversation-entrypoint`
- pr_title: `feat(slice-4): add conversation entrypoint`
- objective: `replace the narrow Quizzes navigation entry with a shared Conversation or Conv entrypoint that presents Dump and Quizzes as sibling context-capture modes`
- tasks:
- [ ] `T4.1 inspect existing web navigation and quiz routes`
- [ ] `T4.2 add Conversation or Conv route and navigation label`
- [ ] `T4.3 render sibling cards for Dump and Quizzes`
- [ ] `T4.4 preserve existing Quiz behavior under the new entrypoint`
- [ ] `T4.5 add navigation and routing tests`
- acceptance:
- `web users enter Dumps and Quizzes through a shared Conversation area`
- `Quizzes remain reachable and behavior-compatible`
- `Dump and Quizzes are presented as sibling modes, not merged models`
- planned_commits:
- `feat(web): add conversation entrypoint`
- `test(web): cover conversation navigation`

### Slice 5: Telegram Dump Commands

- status: `planned`
- branch: `fix/slice-5-telegram-dump-commands`
- pr_title: `feat(slice-5): add Telegram dump commands`
- objective: `expose the dump runtime through Telegram commands and active-dump message routing while preserving concise interaction behavior`
- tasks:
- [ ] `T5.1 add slash routing for /dump`
- [ ] `T5.2 add slash routing for /dump for <use_case>`
- [ ] `T5.3 add slash routing for /dump done, /dump cancel, /dump list, and /dump show`
- [ ] `T5.4 route ordinary messages into the active dump session when appropriate`
- [ ] `T5.5 render concise acknowledgements without echoing full dumps each turn`
- [ ] `T5.6 add adapter-level tests for command and active-session flows`
- acceptance:
- `/dump` starts or resumes a project-level dump`
- `/dump for <use_case>` starts or resumes a use-case-level dump`
- `active dump messages append entries`
- `Telegram output stays concise`
- planned_commits:
- `feat(telegram): add dump commands`
- `test(telegram): cover dump command flows`

### Slice 6: Web Dump Surface

- status: `planned`
- branch: `fix/slice-6-web-dump-surface`
- pr_title: `feat(slice-6): add web dump surface`
- objective: `deliver the project-scoped web Dump surface under Conversation with repeated-post capture, polished raw preview, curated view, and lifecycle controls`
- tasks:
- [ ] `T6.1 add Dump routes and controller actions under the project Conversation area`
- [ ] `T6.2 render dump list with project/use-case scope indicators`
- [ ] `T6.3 render focused repeated-post capture UI`
- [ ] `T6.4 render polished raw capture preview and curated dump view`
- [ ] `T6.5 support continue, append, done, cancel, show, and curate controls`
- [ ] `T6.6 add controller/system coverage for dump web flows`
- acceptance:
- `web users can start and continue dumps from Conversation`
- `the UI favors repeated short posts over manual long-document editing`
- `raw polished and curated views are visible when available`
- `web behavior matches the port-agnostic runtime`
- planned_commits:
- `feat(web): add dump surface`
- `test(web): cover dump web flows`

### Slice 7: Dump Tags And Context Retrieval

- status: `planned`
- branch: `fix/slice-7-dump-context-retrieval`
- pr_title: `feat(slice-7): add dump context retrieval`
- objective: `make curated dumps taggable and available through the existing dumps LLM context layer using project, use-case, tag, recency, and curation status selection`
- tasks:
- [ ] `T7.1 align Dump tagging with the existing or planned Quiz tagging model`
- [ ] `T7.2 add query scopes or query objects for project/use-case/tag dump retrieval`
- [ ] `T7.3 integrate curated dumps with the dumps context provider`
- [ ] `T7.4 avoid silently injecting active uncurated dumps into unrelated ticket work`
- [ ] `T7.5 add tests for tagging, retrieval, and context inclusion/omission`
- acceptance:
- `curated dumps are selectable through the dumps context layer`
- `retrieval can filter by project and use case`
- `tag retrieval is compatible with Quiz tagging`
- `active uncurated dumps do not silently outrank curated context`
- planned_commits:
- `feat(llm): add product dump context retrieval`
- `test(llm): cover dump context selection`

### Slice 8: Configuration, Docs, And Closure

- status: `planned`
- branch: `fix/slice-8-dump-config-docs`
- pr_title: `feat(slice-8): close dump context cycle`
- objective: `add configuration, operator documentation, validation evidence, and cycle closure artifacts for the Dump implementation`
- tasks:
- [ ] `T8.1 add configuration for dump limits, polishing behavior, and curation behavior`
- [ ] `T8.2 document Conversation, Dump, and Quiz relationship`
- [ ] `T8.3 document Telegram and web dump usage`
- [ ] `T8.4 update user guide and relevant reference docs for the new Conversation/Dump functionality`
- [ ] `T8.5 run targeted and relevant broader validation`
- [ ] `T8.6 update tracker with final validation and residual risks`
- acceptance:
- `dump limits and behavior are configurable`
- `durable docs explain how Dump relates to Quiz and Conversation`
- `validation results are recorded`
- `cycle closure captures residual risks and follow-ups`
- planned_commits:
- `feat(web): add dump configuration`
- `docs(user-guide): document conversation dump workflow`
- `docs(ops): close dump context cycle`

## Global Exit Criteria

- project-level and use-case-level dumps exist
- dumps can be built from multiple user-led entries
- RedWright maintains polished raw capture and curated dump output
- Conversation or Conv becomes the shared web entrypoint for Dump and Quizzes
- Quizzes remain behavior-compatible under the shared entrypoint
- Telegram exposes dump start, append, done, cancel, list, and show behavior
- web exposes dump list, capture, polished raw, curated view, and controls
- curated dumps are available through the dumps LLM context layer
- implementation does not turn Dump into a question-driven Quiz flow
- no downstream specs, plans, tickets, or docs are created without explicit user action

## Validation Command Context

- Rails targeted tests must be run from `apps/web` with `bundle exec bin/rails test <paths>`.
- Repository coverage and broader quality checks must be run from repository root when required by the active slice.
- Validation entries must be reported as command plus `(pass)` or `(fail)`.
- Docs-only updates can use the documented docs-only gate exception.

## Non-Goals

- Do not replace Quiz.
- Do not make Dump question-driven by default.
- Do not implement multi-user review or approval roles.
- Do not expose hidden LLM rationale in the UI.
- Do not silently create specs, plans, tickets, or docs from dumps.
- Do not require repository Markdown export in the first cycle.
