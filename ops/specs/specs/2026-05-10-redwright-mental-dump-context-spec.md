# RedWright Mental Dump Context Specification

## Metadata

- id: `spec-2026-05-10-redwright-mental-dump-context`
- status: `draft`
- owner: `adrianpk`
- created: `2026-05-10`
- updated: `2026-05-10`
- scope: `rails-web/telegram/dumps/context-capture/context-curation/context-source`
- derived_from:
  - `ops/conv/dump/`
  - `.agents/skills/repo-dump/SKILL.md`
  - `.agents/playbooks/dump.md`
  - `ops/specs/specs/2026-05-05-redwright-quiz-questionnaire-context-spec.md`
  - `docs/reference/llm-context-shaping.md`

## Problem Statement

RedWright already has a repository-side dump workflow through agent skills and `ops/conv/dump` artifacts. That workflow is useful for preserving broad, free-form human thinking before it becomes a spec, plan, ticket, or implementation task.

The product does not yet have an equivalent first-class RedWright feature.

Quiz captures context by having RedWright ask bounded questions. Dump should capture context by letting the user speak freely across multiple turns until the user decides the dump is finished.

This matters because some knowledge is not best collected through questions:

- the user already knows the shape of the issue
- the topic is broad or still forming
- the important details arrive in sequence
- the user wants to preserve mental state before planning
- the user wants ideas saved without immediately turning them into tasks
- the topic may branch into several possible future specs, drafts, tickets, or docs

Without a product-level Dump feature, this knowledge can remain trapped in transient chat, manually copied notes, or repository-only artifacts that are not visible through the RedWright application.

RedWright needs a Dump system that mirrors the repository `repo-dump` workflow while fitting the product model used by Quiz, documents, tickets, use cases, and LLM context selection.

## Goals

- introduce `Dump` as a first-class project-scoped context capture entity
- support project-level and use-case-level dumps
- support multi-turn free-form capture controlled by the user
- let the user decide when a dump is finished
- maintain an updated polished raw version during the dump
- produce a curated version after or during completion
- preserve the user's thinking path while correcting spelling, punctuation, grammar, and style
- distinguish raw capture from curated interpretation
- identify derived threads without forcing immediate specs, plans, tickets, or docs
- support Telegram and web surfaces through the same port-agnostic runtime
- make Dump and Quiz sibling experiences under a shared Conversation entrypoint
- expose curated dumps as selectable LLM context
- keep the behavior aligned with the repository `repo-dump` skill
- avoid turning Dump into a question-driven workflow

## Non-Goals

- replacing Quiz
- making RedWright ask a bounded questionnaire during dump capture
- requiring every dump to become a spec, plan, ticket, or document
- implementing full knowledge graph behavior
- implementing multi-user review and approval workflows
- storing every typo-preserving literal transcript as the canonical user-facing artifact
- auto-splitting derived threads into separate artifacts without explicit user action
- making dump curation a prompt-manager feature
- implementing manual rich-text editing as a first-version requirement
- treating repository `ops/conv/dump` Markdown files as the only storage backend

## Product Language

The product term is `Dump`.

Use short names:

- `Dump`
- `DumpEntry`
- `DumpSession`
- `UseCase`
- `Tag`
- `Tagging`

`Dump` is preferred over `KnowledgeDump`, `BrainDump`, or `MentalDump` for the product model because it is short, already matches the repository workflow, and pairs naturally with `Quiz`.

User-facing copy may say "dump" or "context dump". Repository and code names should use `Dump`.

## Conceptual Relationship To Quiz

Quiz and Dump are sibling context-capture features.

Quiz:

- RedWright asks questions.
- The user answers one prompt at a time.
- The resulting unit is a question-and-answer entry.
- The flow is bounded and guided.

Dump:

- The user supplies free-form chunks.
- RedWright does not drive the flow with questions.
- The resulting unit is a cleaned sequence of user-provided knowledge.
- The flow is open until the user says it is done.

Both features should share these principles:

- project and use-case scoping
- taggable context entries
- port-agnostic runtime services
- Telegram and web surfaces
- a shared Conversation or Conv product entrypoint
- no hidden LLM rationale in user-facing output
- later retrieval through LLM context policy
- clear separation between capture, curation, and downstream planning

## Conversation Entry Point

The web app should treat Dump and Quiz as sibling conversation-capture modes.

The existing Quizzes entrypoint should become a broader `Conversation` entrypoint, or `Conv` if the shorter label fits the navigation better.

The Conversation page should expose at least two sibling cards:

- `Dump`
- `Quizzes`

The Dump card opens the dump capture and review surfaces.

The Quizzes card opens the existing quiz surfaces, preserving the current Quiz behavior under the broader Conversation area.

This keeps the information architecture aligned with the product meaning:

- Conversation is the top-level area for collecting human context.
- Dump is free-form user-led context capture.
- Quiz is RedWright-led question-and-answer context capture.

The Conversation entrypoint should be a navigation and grouping change, not a semantic merge of Dump and Quiz into one model.

## Product Assumptions

RedWright is currently a single-user product.

The first version should not introduce multi-user permissions, reviewers, or approval roles.

Dump records should be agnostic of the driving port. A dump should not need to know whether it came from Telegram, web, TUI, or a future interface.

The repository `repo-dump` workflow remains valid for agent-side operational artifacts. The product Dump feature should mirror its shape, not replace it.

## Core Model

### Project

A project owns dumps.

### UseCase

A use case may own scoped dumps through its project.

A dump can be:

- project-level
- use-case-level

Project-level dumps have no `use_case_id`.

Use-case-level dumps belong to one project and one use case.

### Dump

A `Dump` is the durable grouping entity.

Suggested fields:

- `id`
- `project_id`
- `use_case_id`, nullable
- `title`
- `slug`
- `status`
- `capture_status`
- `curation_status`
- `raw_body`
- `curated_body`
- `summary`
- timestamps

Suggested status values:

- `active`
- `completed`
- `cancelled`
- `archived`

Suggested capture status values:

- `capturing`
- `closed`

Suggested curation status values:

- `not_curated`
- `curating`
- `curated`
- `needs_review`

The exact constants may be refined during implementation, but the first version must preserve the distinction between capture lifecycle and curation lifecycle.

### DumpSession

A `DumpSession` represents one active capture run.

Suggested fields:

- `id`
- `dump_id`
- `project_id`
- `use_case_id`, nullable
- `status`
- `started_at`
- `ended_at`
- timestamps

Suggested status values:

- `active`
- `completed`
- `cancelled`

The first version may collapse `DumpSession` into `Dump` if the implementation can still support resume, done, and cancel semantics cleanly. If the model is collapsed, the spec still requires distinct active capture state.

### DumpEntry

A `DumpEntry` stores one user-provided chunk.

Suggested fields:

- `id`
- `dump_id`
- `project_id`
- `use_case_id`, nullable
- `position`
- `raw_input`
- `polished_input`
- `derived_thread_hint`, optional
- timestamps

`raw_input` preserves the submitted text closely enough for audit and recovery.

`polished_input` corrects spelling, punctuation, grammar, and style while preserving intent and sequence.

The repeated `project_id` and `use_case_id` are intentional denormalization for future context retrieval.

## Capture Contract

During capture, the user can send multiple free-form chunks.

For each chunk, RedWright should:

1. append the input as a new `DumpEntry`
2. create or update `polished_input`
3. update the aggregate `raw_body`
4. preserve the user's thinking path and useful sequence
5. group obvious topic shifts with headings where appropriate
6. mark possible derived threads without expanding them automatically
7. avoid adding interpretation that belongs in curated notes

The aggregate raw body is not a typo-preserving transcript. It is the polished capture version: corrected, readable, and faithful to the user's intent.

Dump capture should favor short posting cycles over a single large textarea-only workflow.

The user may still paste a large block when useful, but the default interaction should support repeated smaller posts that accumulate into one dump. Each post becomes a `DumpEntry`; the aggregate `Dump` is the consolidated body formed from those entries.

This preserves the natural mental-dump rhythm:

1. user posts one chunk
2. RedWright saves and lightly polishes it
3. user continues with the next chunk
4. RedWright keeps consolidating the dump
5. user finishes when ready

## Curation Contract

When the user finishes the dump, RedWright should produce or refresh `curated_body`.

The curated body should include:

- central topic
- raw source reference
- summary
- key concepts
- decisions or strong preferences
- tensions and tradeoffs
- assumptions
- derived threads
- possible downstream artifacts
- open questions

Curation may happen incrementally for preview, but the completion curation is the durable artifact.

Curated notes may interpret structure, extract decisions, and group related concepts. They must not invent requirements that are not supported by the dump.

## Interaction Rules

RedWright should let the user dump freely before steering.

Clarifying questions are allowed only sparingly. They should be used when:

- the central topic is unclear enough that capture may become useless
- the user asks RedWright to help organize the dump
- the dump appears to have split into unrelated major topics

If the interaction becomes primarily question-driven, RedWright should suggest switching to Quiz.

Dump must not create specs, plans, tickets, or derived drafts unless the user explicitly asks.

## Runtime Controls

Required controls:

- start dump
- continue dump
- finish dump
- cancel dump
- list dumps
- show dump
- curate dump

Suggested command language:

- `/dump`
- `/dump for <use_case>`
- `/dump continue`
- `/dump done`
- `/dump cancel`
- `/dump list`
- `/dump show <dump>`
- `/dump curate <dump>`

The exact command shape may follow existing RedWright slash routing conventions.

`done` means the user has finished capture and wants the durable curated version.

`cancel` means the current capture run should stop without treating the dump as completed. Existing saved entries may remain available unless explicitly deleted by a separate future action.

## Telegram Surface

Telegram should support the first dump loop because it is the most natural surface for free-form multi-turn capture.

Telegram behavior:

- `/dump` starts or resumes a project-level dump for the active project
- `/dump for <use_case>` starts or resumes a use-case-level dump
- ordinary messages during an active dump append entries
- `/dump done` closes capture and returns a concise completion summary
- `/dump cancel` stops the active session
- `/dump list` lists recent dumps for the active project

Telegram output should be concise. It should not echo the full curated dump after every entry.

After each entry, a short acknowledgement is enough, optionally with the current inferred section or derived thread hint.

## Web Surface

The web surface should expose project and use-case dumps in a way that fits the existing RedWright app.

Required first-version capabilities:

- list dumps for a project
- filter or indicate use-case scope
- enter Dumps through the shared Conversation or Conv area
- start a new dump
- continue an active dump
- append free-form entries
- finish capture
- view polished raw body
- view curated body

The web UI should not be a generic scaffold CRUD surface.

The primary experience should be a focused capture and review workspace:

- input area for the next dump chunk, optimized for repeated posts
- compact session status
- polished raw capture preview
- curated view when available
- derived thread list when available
- clear finish and cancel controls

The web surface may include a textarea, but it should not make the first version feel like editing one long document manually. The main workflow is repeated contribution and consolidation.

## Tags And Retrieval

Dumps should be taggable through the same relational tagging model used or planned for Quiz.

Tags may apply to:

- `Dump`
- optionally `DumpEntry` in a later version

The first version should prefer tagging `Dump` unless entry-level retrieval is straightforward and does not complicate the model.

Tags should be normalized consistently with Quiz tags.

Curated dumps must be available as selectable context for LLM requests through the existing `dumps` context layer.

Retrieval should support:

- project scope
- use-case scope
- tag scope where available
- title or slug match
- recency
- curation status

Only curated or explicitly selected active dumps should be injected as high-value context. Raw active dumps may be useful during the current interaction but should not silently outrank curated context in unrelated ticket work.

## LLM Use

LLM use is allowed for:

- polishing each entry
- updating the aggregate polished raw body
- producing curated notes
- suggesting tags
- identifying derived threads
- summarizing completion

LLM use must not:

- ask a quiz-style sequence of questions by default
- create downstream specs, plans, tickets, or docs without explicit user instruction
- expose hidden reasoning to the user
- treat uncertain interpretation as fact
- request secrets, credentials, tokens, passwords, or unnecessary PII

The first version should use fakeable contracts and deterministic fallbacks for tests.

## Output Contracts

### Entry Polish Output

For each user chunk, the polishing contract should produce:

- `polished_input`
- `topic_heading`, optional
- `derived_thread_hints`, optional list
- `tag_suggestions`, optional list

### Curated Dump Output

The curation contract should produce:

- `central_topic`
- `summary`
- `key_concepts`
- `decisions_or_preferences`
- `tensions_and_tradeoffs`
- `assumptions`
- `derived_threads`
- `possible_downstream_artifacts`
- `open_questions`
- `tag_suggestions`

Invalid or unavailable LLM output should not lose the submitted entry. RedWright should persist the raw input and fall back to minimal deterministic polishing.

## Repository Artifact Export

The product Dump feature may later export to repository artifacts:

- `ops/conv/dump/YYYY-MM-DD-<topic>-dump-raw.md`
- `ops/conv/dump/YYYY-MM-DD-<topic>-dump.md`

Export is not required for the first product implementation unless it is cheap and fits existing document artifact behavior.

If export is implemented, the exported Markdown should follow the repository `repo-dump` format.

## Safety And Data Boundaries

Dump capture can contain sensitive strategy, product, or implementation information.

The first version should:

- avoid asking for secrets
- warn or redact obvious secrets when detected
- keep hidden LLM rationale out of user-facing views
- preserve enough raw input for recovery
- avoid silently deleting entries on cancel
- keep project boundaries explicit

## Acceptance Criteria

- users can start a project-level dump
- users can start a use-case-level dump
- users can append multiple free-form entries
- web users enter Dumps and Quizzes from a shared Conversation or Conv area
- RedWright maintains a polished raw capture version
- RedWright produces a curated dump version on completion
- users can list and view dumps
- `done` and `cancel` have distinct behavior
- the flow does not become question-driven by default
- derived threads are identified without automatically creating downstream artifacts
- curated dumps are available to the `dumps` context layer
- tests cover capture, polishing fallback, curation, done, cancel, list, and retrieval scope

## Open Questions

- Should the first version store `DumpSession` separately or collapse active session state into `Dump`?
- Should tags attach only to `Dump` first, or also to `DumpEntry`?
- Should repository Markdown export be included in the first implementation cycle?
- Should active uncurated dumps ever be eligible for ticket execution context?
- Should `/dump` resume the latest active dump automatically or always create a new dump when no explicit title is provided?
- What title generation policy should be used when the user starts a dump without naming it?

## Future Work

- export product dumps to repository `ops/conv/dump` artifacts
- promote curated dumps into specs, plans, tickets, or documents through explicit user commands
- add side-by-side diff between raw input and polished capture
- add entry-level tags and retrieval when needed
- add manual curation edits in web UI
- add dump-to-quiz conversion when open questions dominate
- add dump-to-spec scaffolding when the curated dump is mature enough
