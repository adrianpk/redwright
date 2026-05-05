# RedWright Quiz Questionnaire Context Specification

## Metadata

- id: `spec-2026-05-05-redwright-quiz-questionnaire-context`
- status: `draft`
- owner: `adrianpk`
- created: `2026-05-05`
- updated: `2026-05-05`
- scope: `rails-web/telegram/quiz/use-cases/tagging/context-source`
- derived_from:
  - `ops/specs/drafts/2026-05-05-redwright-questionnaire-context-and-ticket-driven-engineering-draft.md`
  - `ops/specs/conv/2026-05-05-redwright-quiz-me-questionnaire-context-conv.md`
  - `ops/specs/conv/2026-05-05-redwright-quiz-me-questionnaire-context-conv-raw.md`

## Problem Statement

RedWright already collects some project setup context and already has context injection paths for LLM-backed work.

The missing piece is a structured, reusable way to collect human and product knowledge that is not reliably inferable from code, project setup answers, protocols, tickets, or repository structure.

This knowledge includes:

- product intent
- domain rules
- UX/UI expectations
- implementation preferences
- constraints
- edge cases
- project-specific decisions
- use-case-specific context

Today this type of knowledge can remain trapped in chat, informal documents, or one-off conversations. That makes later ticket execution and artifact generation less precise.

RedWright needs a first-class `Quiz` system that captures question-and-answer entries, scopes them to projects and use cases, tags them for later retrieval, and exposes them through both Telegram and the web UI.

## Goals

- introduce `Quiz` as the persistent grouping entity for project and use-case context questions
- introduce `QuizEntry` as a question-and-answer tuple
- introduce `UseCase` as a project-scoped concept
- support one project-level quiz per project
- support one use-case-level quiz per use case
- keep questions from hanging directly off projects
- support Telegram commands for running and listing quizzes
- support a web counterpart that reuses the same adaptive loop concept
- support relational tags and taggings for quiz entries
- design tagging so it can be reused across tickets and future taggable entities
- keep the implementation compatible with future context retrieval optimization
- avoid overcomplicating the first version with answer history, sessions, roles, or broad prompt-manager work

## Non-Goals

- implementing a full prompt manager
- introducing context injection from scratch
- implementing final ticket context retrieval
- implementing full use-case command management outside quiz needs
- implementing answer history/versioning
- implementing questionnaire sessions as first-class records
- implementing multi-user roles or permissions
- implementing manual tag editing in the first web UI
- implementing a full adaptive questionnaire analytics system
- implementing a perfect tag taxonomy
- implementing a complete graph-style context database

## Product Language

The product term is `Quiz`.

Use short names:

- `Quiz`
- `QuizEntry`
- `UseCase`
- `Tag`
- `Tagging`

`Quiz` is preferred over `Questionnaire` because it is shorter and easier to spell.

`QuizEntry` means a persisted question-and-answer tuple. It must not imply that answers are modeled independently from questions.

## Product Assumptions

RedWright is currently a single-user product.

The product model is one lead commanding a set of agents.

This feature must not introduce multi-user authorization design.

The current demo/test seeding may create more than one user. That should be reviewed separately because it may conflict with the intended single-user product model.

Quiz records should be agnostic of the driving port. A `QuizEntry` should not need to store whether it came from Telegram, web, or another interface.

## Core Model

### Project

A project owns quizzes and use cases.

### UseCase

A `UseCase` belongs to a project.

A use case represents a project-local functional or product area that may need its own quiz context.

Suggested fields:

- `id`
- `project_id`
- `name`
- `slug`
- timestamps

The slug should be normalized and unique within a project.

Suggested uniqueness:

```text
unique(project_id, slug)
```

The spec does not require broad use-case CRUD in the first implementation. It only requires enough `UseCase` behavior to support quiz scoping.

### Quiz

A `Quiz` is always the grouping entity.

Questions never hang directly from a project.

A quiz belongs to:

- a project
- optionally a use case

There is one main project-level quiz per project.

There is one main use-case-level quiz per use case.

A project-level quiz has no `use_case_id`.

Suggested fields:

- `id`
- `project_id`
- `use_case_id`, nullable
- `name` or `title`
- `status`
- timestamps

The first implementation should keep the `status` field available but should not make completion semantics central.

Suggested status values may include:

- `active`
- `paused`
- `archived`

The exact constants may be refined during implementation.

### QuizEntry

A `QuizEntry` stores one question and one answer together.

Suggested fields:

- `id`
- `project_id`
- `quiz_id`
- `use_case_id`, nullable
- `question`
- `answer`
- `status`
- `position`, optional/reserved for future use
- timestamps

The repeated `project_id` and `use_case_id` are intentional denormalization.

Even though those fields can be inferred through `quiz_id`, storing them directly on `QuizEntry` makes future context retrieval simpler and faster.

`QuizEntry` should not keep answer history in the first version.

Editing an answer updates the current answer.

Moderately duplicate or overlapping questions are acceptable. LLM-generated questions may overlap. Both entries may remain in the pool and later retrieval may surface both when relevant.

Suggested entry states may include:

- `answered`
- `skipped`
- `incomplete`

The spec should not overconstrain the exact implementation constants.

## Quiz Cardinality

The first version should avoid questionnaire sessions and multiple quiz instances per same scope.

Required cardinality:

- one project-level quiz per project
- one use-case-level quiz per use case

Question sessions may be inferred later from timestamp bursts if useful.

Do not add first-class session records in the first version.

## Tags

Tags are free-form but normalized.

Tag normalization should use lowercase kebab-case or an equivalent deterministic form.

Tags apply to `QuizEntry`.

Because a `QuizEntry` stores question and answer together, tagging the entry tags the whole Q/A tuple.

The first implementation should use a transversal relational tagging system rather than storing tags as inline arrays.

The goal is to reuse tags across:

- quiz entries
- tickets
- documents
- use cases
- future artifacts

Suggested entities:

- `Tag`
- `Tagging`

Suggested `Tag` fields:

- `id`
- `name`
- `slug`
- timestamps

Suggested `Tagging` fields:

- `id`
- `tag_id`
- `taggable_type`
- `taggable_id`
- `project_id`, nullable/denormalized
- `use_case_id`, nullable/denormalized
- `source`
- `confidence`, optional
- timestamps

The denormalized `project_id` and `use_case_id` in taggings are intentional. They support efficient queries such as:

```text
project + use case + tag
```

This is important for future context retrieval.

The implementation must verify whether ticket tagging already exists and align with a single tagging mechanism rather than creating parallel tag systems.

## Tag Generation

The first version should use LLM-based tag generation.

Tags should be suggested on the fly as part of the question/answer interpretation flow.

Manual tag editing in the web UI is not required in the first version.

Manual editing can be added later to correct mistakes and improve context retrieval.

Tag count must be bounded.

The maximum tag count should be configurable.

Default preference:

- default: 3 tags
- practical upper range: 5 tags

More tags are not automatically better. Excess tags create retrieval dispersion.

## Ticket Relationship

Tickets should eventually participate in the same context retrieval strategy.

Tickets should support optional `use_case_id`.

This is useful because future context selectors may need to retrieve:

- quiz entries for the same project
- quiz entries for the same use case
- quiz entries with shared tags
- tickets with shared tags
- related documents or artifacts

This spec does not require final ticket context retrieval, but it should not block that direction.

## Telegram Commands

Use one base command:

```text
/quiz
```

Initial grammar:

```text
/quiz
/quiz for <use_case>
/quiz list
```

Command behavior:

- `/quiz` runs the active project's main quiz
- `/quiz for <use_case>` runs the active project's quiz for that use case
- `/quiz list` lists quizzes for the active project

The `for` keyword is reserved.

This is acceptable because it avoids reserving multiple possible use-case names such as `me`, `list`, `show`, or `help`.

When `/quiz for <use_case>` receives a use-case name:

1. Resolve the active project.
2. Normalize the use-case name.
3. Find the use case in that project.
4. If it does not exist, create it.
5. Find or create that use case's main quiz.
6. Run the quiz loop.

`/quiz list` should list quizzes, not individual entries.

The list should focus on the active project.

## Telegram Quiz Loop

Telegram quiz execution is a one-question-at-a-time loop.

The next question is LLM-generated.

Previous questions and answers may influence the next question.

The loop must support bounded follow-up depth so it can explore a thread without becoming trapped in one narrow path.

The loop should preserve a path back to broader coverage.

Minimum controls:

- answer
- skip
- done
- cancel

Control semantics:

- `answer`: save an answer for the current question
- `skip`: persist the entry as skipped or otherwise move past it without an answer
- `done`: the user considers the quiz sufficiently answered for now
- `cancel`: stop the loop without marking it as sufficiently answered

Opening the same project or use-case quiz again must never be forbidden.

## Loop Limits

The current questionnaire playbook limit of 50 questions is a reasonable default, but should not be hardcoded as a permanent product rule.

Question count should be configurable.

Follow-up depth should also be configurable.

Default values:

- max questions: 50
- max follow-up depth: 3

Configuration should come from YAML first.

Later, configuration may move into web settings.

## Web Counterpart

The web counterpart should reuse the same adaptive quiz loop concept as Telegram.

The first web UI should not show all previous questions and answers by default.

The first web UI should prioritize simplicity:

- current question
- answer input
- basic controls
- direct progression

The UI must hide the agent's internal reasoning.

If the agent decides a follow-up is useful, it should ask it directly.

The user does not need to see the hidden decision process.

Quizzes should live as a project section near existing project surfaces such as Board and Docs.

If the navigation becomes overloaded later, the UX can be revisited.

## Visual and UX Requirements

Visual and UX alignment is non-negotiable.

This feature must not ship as a generic Rails CRUD surface or visually disconnected form stack.

The web UI must align with the current RedWright product language:

- calm
- compact
- intentional
- professional
- visually coherent with adjacent project surfaces
- consistent with current spacing, typography, card rhythm, and navigation behavior

The product may accept an initially small UI, but not an incoherent one.

Do not introduce:

- scaffold-like admin CRUD aesthetics
- noisy status chips without clear value
- nested-box-heavy layouts
- visually disconnected one-off forms
- controls that feel unrelated to the rest of the app

The web counterpart should feel like it belongs next to existing project areas such as Board, Docs, and Protocols.

## LLM Question Contract

The LLM should generate the next question.

The exact structured output contract should be based on existing RedWright project setup question machinery where practical.

RedWright should not reinvent a completely unrelated LLM question contract if the existing setup question infrastructure can be adapted.

The LLM output should support at least:

- question text
- suggested tags
- whether the question is a follow-up
- enough metadata to enforce depth and loop limits

The contract may include hidden rationale for tracing/debugging, but hidden rationale must not be shown to the user and must not be persisted as primary quiz content.

## Sensitive Information Guardrails

The question-generation prompt must explicitly avoid asking for:

- secrets
- passwords
- tokens
- credentials
- PII

This guardrail is mandatory.

The quiz system is meant to collect reusable engineering context, not sensitive secret material.

## Configuration

Initial YAML-backed configuration should cover:

- maximum questions per quiz run
- maximum follow-up depth
- maximum tags per entry

Later web settings may expose these values.

Defaults:

- max questions: `50`
- max follow-up depth: `3`
- max tags per entry: `3`

## Context Injection Boundary

RedWright already has context injection.

This spec adds a structured context source that can later improve that system.

The first implementation must not need to complete the entire prompt/context optimization story.

However, persistence must be shaped so future retrieval can efficiently select entries by:

- project
- use case
- tag
- related ticket
- related artifact

## Expected Context Retrieval Shape

Future context retrieval should be able to ask questions such as:

```text
Find quiz entries for project X.
Find quiz entries for project X and use case Y.
Find quiz entries for project X and tag Z.
Find quiz entries for project X, use case Y, and tag Z.
Find tickets and quiz entries that share tag Z in project X.
```

This is why the model accepts denormalized `project_id` and `use_case_id` on quiz entries and taggings.

## Acceptance Criteria

The first complete feature should satisfy:

1. A project can have one project-level quiz.
2. A project use case can have one use-case-level quiz.
3. `/quiz` starts or resumes the active project's quiz loop.
4. `/quiz for <use_case>` resolves or creates the use case and starts or resumes its quiz loop.
5. `/quiz list` lists quizzes for the active project.
6. The web app exposes a project quiz area.
7. The web app supports answering quiz questions through the same adaptive loop concept.
8. A `QuizEntry` persists question and answer together.
9. A `QuizEntry` can be skipped.
10. A `QuizEntry` can be tagged.
11. Tags are normalized.
12. Taggings are relational and reusable across future taggable entities.
13. Tag count is bounded by configuration.
14. LLM-generated questions are bounded by max question count and follow-up depth.
15. LLM-generated questions include guardrails against secrets, credentials, and PII.
16. The web UI is visually aligned with current RedWright project surfaces.

## Open Questions

- Exact Rails migration details for nullable `use_case_id` uniqueness.
- Exact `QuizEntry` status constants.
- Exact LLM contract field names.
- Whether tickets receive `use_case_id` in the same first implementation slice or a later slice.
- Whether document tagging joins the initial transversal tagging system immediately or later.
- Exact YAML config namespace.
- Exact web route names.
- Exact navigation label and placement.
- Whether context retrieval should later persist which quiz entries were used for a given ticket prompt.
