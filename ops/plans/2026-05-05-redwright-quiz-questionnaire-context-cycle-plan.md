# Cycle Plan: RedWright Quiz Questionnaire Context

## Metadata

- cycle_id: `cycle-2026-05-05-redwright-quiz-questionnaire-context`
- status: `planned`
- owner: `adrianpk`
- created: `2026-05-05`
- updated: `2026-05-05`
- goal: `deliver a project- and use-case-scoped Quiz system that captures tagged question-and-answer context through Telegram and web loops, while preserving visual/UX coherence and preparing future context retrieval optimization`
- scope: `feature`
- source_spec: `ops/specs/specs/2026-05-05-redwright-quiz-questionnaire-context-spec.md`
- source_quiz:
  - `ops/conv/quiz/2026-05-05-redwright-quiz-me-questionnaire-context-quiz.md`
  - `ops/conv/quiz/2026-05-05-redwright-quiz-me-questionnaire-context-quiz-raw.md`
- source_draft: `ops/specs/drafts/2026-05-05-redwright-questionnaire-context-and-ticket-driven-engineering-draft.md`

## Slice List

### Slice 1: Quiz Domain Foundation

- status: `planned`
- branch: `fix/slice-1-quiz-domain-foundation`
- pr_title: `feat(slice-1): add quiz domain foundation`
- objective: `introduce the core Quiz, QuizEntry, and UseCase persistence model with project/use-case scoping, denormalized retrieval fields, and first-version cardinality constraints`
- tasks:
- [ ] `T1.1 add UseCase model scoped to Project with normalized project-local slug`
- [ ] `T1.2 add Quiz model scoped to Project and optional UseCase`
- [ ] `T1.3 add QuizEntry model storing question and answer together`
- [ ] `T1.4 include denormalized project_id and use_case_id on QuizEntry`
- [ ] `T1.5 enforce one main project quiz per project and one main use-case quiz per use case`
- [ ] `T1.6 add focused model tests for cardinality, slug normalization, associations, and status constants`
- acceptance:
- `projects can have exactly one project-level quiz`
- `project use cases can have exactly one use-case-level quiz`
- `quiz entries store question and answer together`
- `quiz entries expose project/use-case scope without extra joins`
- planned_commits:
- `feat(web): add quiz domain models`
- `test(web): cover quiz domain constraints`

### Slice 2: Transversal Tagging Foundation

- status: `planned`
- branch: `fix/slice-2-quiz-transversal-tagging`
- pr_title: `feat(slice-2): add transversal quiz tagging`
- objective: `introduce normalized relational tags/taggings suitable for QuizEntry now and tickets/documents later, avoiding inline tag arrays and parallel tag systems`
- tasks:
- [ ] `T2.1 inspect current ticket/tag-related persistence and avoid duplicate tag mechanisms`
- [ ] `T2.2 add or align Tag and Tagging models with polymorphic taggables`
- [ ] `T2.3 normalize tags to lowercase kebab-case`
- [ ] `T2.4 denormalize project_id and use_case_id on taggings for future retrieval queries`
- [ ] `T2.5 support tagging QuizEntry records`
- [ ] `T2.6 add tests for normalization, tag reuse, polymorphic tagging, and project/use-case scoped queries`
- acceptance:
- `quiz entries can be tagged through relational taggings`
- `tags are normalized and reused`
- `taggings can be queried by project, use case, and tag`
- `implementation does not introduce an incompatible ticket-specific tag path`
- planned_commits:
- `feat(web): add transversal tagging models`
- `test(web): cover quiz tagging queries`

### Slice 3: Quiz Loop Contract and LLM Question Service

- status: `planned`
- branch: `fix/slice-3-quiz-loop-llm-contract`
- pr_title: `feat(slice-3): add quiz loop LLM contract`
- objective: `define and implement the bounded LLM-backed next-question contract, including tags, follow-up metadata, limits, controls, and sensitive-information guardrails`
- tasks:
- [ ] `T3.1 define a structured LLM output contract for next quiz question generation`
- [ ] `T3.2 reuse or adapt existing project setup question machinery where practical`
- [ ] `T3.3 include tag suggestions in the LLM interpretation flow`
- [ ] `T3.4 enforce max question count, max follow-up depth, and max tag count from configuration`
- [ ] `T3.5 add guardrails against secrets, credentials, tokens, passwords, and PII`
- [ ] `T3.6 add deterministic fallback behavior for unavailable or invalid LLM output`
- acceptance:
- `next quiz questions are generated through a bounded contract`
- `LLM rationale is hidden from user-facing output`
- `tags are produced on the fly and bounded`
- `question generation avoids asking for sensitive information`
- planned_commits:
- `feat(web): add quiz question generation contract`
- `test(web): cover quiz LLM contract guardrails`

### Slice 4: Quiz Loop Runtime and Controls

- status: `planned`
- branch: `fix/slice-4-quiz-loop-runtime-controls`
- pr_title: `feat(slice-4): add quiz loop runtime controls`
- objective: `implement the reusable quiz loop runtime that persists entries and supports answer, skip, done, and cancel semantics independent of Telegram or web ports`
- tasks:
- [ ] `T4.1 add a port-agnostic quiz loop service`
- [ ] `T4.2 resolve or create the project-level quiz`
- [ ] `T4.3 resolve or create use cases and their main quizzes`
- [ ] `T4.4 persist answered and skipped QuizEntry records`
- [ ] `T4.5 implement done and cancel semantics without forbidding later reopening`
- [ ] `T4.6 add tests for project quiz, use-case quiz, skip, done, cancel, and reopening behavior`
- acceptance:
- `quiz loops can run without storing driving-port-specific state in QuizEntry`
- `skip persists a meaningful entry state`
- `done and cancel stop the loop with distinct semantics`
- `the same quiz can always be opened again`
- planned_commits:
- `feat(web): add quiz loop runtime`
- `test(web): cover quiz loop controls`

### Slice 5: Telegram Quiz Commands

- status: `planned`
- branch: `fix/slice-5-telegram-quiz-commands`
- pr_title: `feat(slice-5): add Telegram quiz commands`
- objective: `expose the quiz loop through Telegram using /quiz, /quiz for <use_case>, and /quiz list while preserving active project resolution and concise interaction semantics`
- tasks:
- [ ] `T5.1 add slash routing for /quiz`
- [ ] `T5.2 add slash routing for /quiz for <use_case>`
- [ ] `T5.3 add slash routing for /quiz list`
- [ ] `T5.4 connect Telegram commands to the port-agnostic quiz loop runtime`
- [ ] `T5.5 render answer, skip, done, and cancel control guidance without verbose noise`
- [ ] `T5.6 add simulated or adapter-level tests for project quiz, use-case quiz creation, and listing`
- acceptance:
- `/quiz` runs the active project's quiz`
- `/quiz for <use_case>` resolves or creates the use case and runs its quiz`
- `/quiz list` lists active-project quizzes`
- `Telegram output remains concise and does not expose hidden rationale`
- planned_commits:
- `feat(telegram): add quiz commands`
- `test(telegram): cover quiz command flows`

### Slice 6: Web Quiz Surface and Visual Alignment

- status: `planned`
- branch: `fix/slice-6-web-quiz-surface`
- pr_title: `feat(slice-6): add web quiz surface`
- objective: `deliver the project-scoped web quiz surface using the same adaptive loop concept while preserving visual and UX harmony with Board, Docs, and Protocols`
- tasks:
- [ ] `T6.1 add project navigation entry or route for Quizzes`
- [ ] `T6.2 render quiz list for the active project`
- [ ] `T6.3 render current-question web loop UI`
- [ ] `T6.4 support answer, skip, done, and cancel controls from web`
- [ ] `T6.5 avoid showing hidden agent reasoning or prior Q/A lists by default`
- [ ] `T6.6 harmonize spacing, typography, cards, controls, and page width with existing project surfaces`
- [ ] `T6.7 add controller/system coverage for web quiz navigation and loop controls`
- acceptance:
- `web users can run project and use-case quizzes`
- `web UI uses the same adaptive loop semantics as Telegram`
- `hidden LLM rationale is not visible`
- `visual and UX alignment with existing RedWright surfaces is non-negotiably satisfied`
- planned_commits:
- `feat(web): add project quiz surface`
- `test(web): cover quiz web flows`

### Slice 7: Ticket/UseCase Context Preparation

- status: `planned`
- branch: `fix/slice-7-quiz-ticket-context-prep`
- pr_title: `feat(slice-7): prepare quiz context retrieval hooks`
- objective: `prepare ticket and future context retrieval integration without implementing the full prompt manager, including optional ticket use-case association if it fits the existing board model`
- tasks:
- [ ] `T7.1 inspect current ticket model and board relationships`
- [ ] `T7.2 add optional ticket use_case_id if compatible with the current Kanban domain`
- [ ] `T7.3 add query objects or scopes for project/use-case/tag quiz entry retrieval`
- [ ] `T7.4 add query objects or scopes for shared tag retrieval across quiz entries and tickets`
- [ ] `T7.5 keep this slice out of final prompt-manager implementation`
- [ ] `T7.6 add tests for retrieval-oriented query shapes`
- acceptance:
- `quiz entries can be selected by project, use case, and tag`
- `tickets can participate in use-case/tag context retrieval when implemented`
- `no full prompt-manager behavior is introduced in this cycle`
- planned_commits:
- `feat(web): prepare quiz context retrieval queries`
- `test(web): cover quiz context retrieval scopes`

### Slice 8: Configuration, Seeding Review, and Cycle Closure

- status: `planned`
- branch: `fix/slice-8-quiz-config-and-closure`
- pr_title: `feat(slice-8): close quiz questionnaire context cycle`
- objective: `add YAML-backed quiz configuration, review single-user demo seeding assumptions, finish validation, and publish cycle closure updates`
- tasks:
- [ ] `T8.1 add YAML-backed configuration for max questions, follow-up depth, and max tags`
- [ ] `T8.2 apply configuration to loop and LLM contract services`
- [ ] `T8.3 review demo/test seeding that creates multiple users against the single-user product assumption`
- [ ] `T8.4 run targeted and full relevant validation from canonical command locations`
- [ ] `T8.5 update tracker and cycle notes with validation evidence and residual risks`
- [ ] `T8.6 keep visual/UX alignment as an explicit closure check`
- acceptance:
- `quiz limits are configurable`
- `single-user seeding assumptions are reviewed or documented`
- `all relevant tests and quality gates pass`
- `cycle closure records residual risks and future prompt/context retrieval work`
- planned_commits:
- `feat(web): add quiz configuration`
- `docs(ops): close quiz questionnaire context cycle`

## Global Exit Criteria

- project-level and use-case-level quizzes exist and respect first-version cardinality
- quiz entries store Q/A tuples without answer history
- quiz entries are taggable through normalized relational tags
- Telegram exposes `/quiz`, `/quiz for <use_case>`, and `/quiz list`
- web exposes a visually coherent project quiz surface
- question generation is LLM-backed, bounded, and guarded against sensitive information
- loop controls support answer, skip, done, and cancel
- future context retrieval is prepared through project/use-case/tag query shapes
- no broad prompt-manager implementation is introduced in this cycle
- visual and UX alignment with the existing product is treated as non-negotiable

## Validation Command Context

- Rails targeted tests must be run from `apps/web` with `bundle exec bin/rails test <paths>`.
- Repository coverage and broader quality checks must be run from repository root when required by the active slice.
- Validation entries must be reported as command plus `(pass)` or `(fail)`.
- Docs-only updates can use the documented docs-only gate exception.

## Non-Goals

- Do not implement a full prompt manager in this cycle.
- Do not add answer history or questionnaire sessions in this cycle.
- Do not add multi-user permissions in this cycle.
- Do not expose hidden LLM rationale in the UI.
- Do not ship a generic scaffold-style CRUD surface for quizzes.
- Do not make manual tag editing part of the first version.
