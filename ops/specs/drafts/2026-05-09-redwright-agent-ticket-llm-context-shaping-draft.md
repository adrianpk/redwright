# RedWright Agent Ticket LLM Context Shaping Draft

## Status

- type: `spec-draft`
- status: `promoted_implemented`
- selection_status: `closed`
- date: `2026-05-09`
- source: current implementation review of agent ticket execution context composition
- scope: `rails-web/agent-ticket-execution/llm-context/retry-feedback/context-selection`
- state: `promoted_to_implemented_spec`
- promoted_to: `ops/specs/specs/2026-05-09-redwright-agent-ticket-llm-context-shaping-spec.md`
- completed_plan: `ops/plans/2026-05-09-redwright-llm-context-shaping-cycle-plan.md`
- completed_tracker: `ops/trackers/2026-05-09-redwright-llm-context-shaping-cycle-tracker.md`
- dump: `../../conv/dump/2026-05-09-redwright-agent-ticket-llm-context-shaping-dump.md`
- raw_dump: `../../conv/dump/2026-05-09-redwright-agent-ticket-llm-context-shaping-dump-raw.md`
- quiz: `../../conv/quiz/2026-05-09-redwright-agent-ticket-llm-context-shaping-quiz.md`
- raw_quiz: `../../conv/quiz/2026-05-09-redwright-agent-ticket-llm-context-shaping-quiz-raw.md`
- related:
  - `ops/specs/specs/2026-05-08-redwright-agent-ticket-execution-spec.md`
  - `ops/specs/specs/2026-05-05-redwright-llm-request-engine-context-composition-spec.md`
  - `ops/specs/drafts/2026-05-05-redwright-prompt-engine-context-composition-draft.md`
  - `ops/conv/dump/2026-05-08-redwright-agent-ticket-execution-dump.md`

This draft is intentionally provisional. It captures current implementation facts and early design insights before a user-led dump round and a later bounded quiz round.

## 1. Purpose

This draft frames the next refinement of the context sent to the LLM during RedWright agent ticket implementation and correction operations.

The current implementation already builds a structured context packet for agent ticket execution. The next design question is how that context should become more selective, more task-aware, and better aligned with ticket correction loops without losing the useful broad context that made the first implementation credible.

The draft should be enriched in this order:

1. run a formal dump round using the repository dump playbook and `repo-dump` skill
2. curate the dump into `ops/conv/dump/`
3. run a bounded quiz round using the repository quiz workflow
4. curate the quiz into `ops/conv/quiz/`
5. revise this draft into a stronger specification source

## 2. Current Implementation Summary

Agent ticket execution context is built through this path:

```text
ExecuteAgentTicket
  -> AgentTicketExecution::Runner
  -> ValidationExecutor
  -> ValidationLoop
  -> ContextComposer
  -> LlmRequester
```

`AgentTicketExecution::ContextComposer` builds an execution context with:

- `context_sections`
- `trace_metadata`
- `user_text`
- `diagnostics`

`AgentTicketExecution::LlmRequester` wraps the composed request into the provider-facing payload:

```json
{
  "request": {
    "action": "agent_ticket_execution",
    "ticket_id": "...",
    "ticket_title": "...",
    "ticket_description": "...",
    "mode": "targeted|pickup",
    "branch_name": "..."
  },
  "context_sections": []
}
```

The provider call uses the `agent_ticket_execution` action, the `coding` model role, a strict system prompt, an output contract, structured context sections, and trace metadata.

## 3. Current Context Sections

The default context section providers currently include:

- `ticket`: ticket record, workflow metadata, request mode, target ticket reference, branch name, source channel, and actor identifier
- `project`: project identity, root path, repository URL, stack slug, and project attributes
- `repository_tree`: sorted workspace file inventory, capped at 300 entries
- `relevant_files`: full content for broadly relevant source and project files, capped at 32,000 bytes per file
- `tests`: full content for detected test/spec files, capped at 32,000 bytes per file
- `operational_setup`: `.rw/agent` runtime setup discovery, Dockerfile metadata, production Dockerfile separation, and validation commands
- `protocol_files`: modeled project protocol documents with their file paths and full content
- `protocol_model`: modeled project protocol state
- `previous_interactions`: recent agent-LLM loop records for the same ticket/session/agent
- `validation_feedback`: only present on corrective retry attempts

The repository scan intentionally skips directories such as `.git`, `node_modules`, `vendor`, `tmp`, `log`, `coverage`, `dist`, `build`, `target`, and `.next`.

It also excludes `AGENTS.md` and `.agents/` from normal workspace file scanning. Protocols enter through `protocol_files` and `protocol_model`, not through `repository_tree` or `relevant_files`.

## 4. Current Retry And Correction Behavior

`AgentTicketExecution::ValidationLoop` recomposes context on every attempt.

Each attempt:

1. builds an attempt request
2. composes context
3. calls the LLM
4. validates the LLM output contract
5. applies files, commands, or direct actions through `OutputApplier`
6. records the previous interaction when applicable
7. runs validation commands
8. retries with feedback when application or validation fails

Correction context is currently explicit and mechanical:

```json
{
  "stage": "application|validation",
  "result": "..."
}
```

On the next attempt, that feedback appears in both:

- the request payload as `validation_feedback`
- a dedicated `validation_feedback` context section

Previous interactions are scoped to the agent LLM loop. They do not include general human chat history.

## 5. Working Insights

### 5.1 Broad Context Works For First-Cycle Execution

- provisional_status: `keep`
- current behavior:
  - The first implementation sends broad practical context: ticket, project, tree, source files, tests, operational setup, protocols, prior agent attempts, and retry feedback.
- value:
  - This is appropriate for small or medium ticket execution where correctness matters more than prompt size.
  - It gives the coding model enough context to propose patches, commands, or direct primitive actions.
- risk:
  - As project size grows, broad inclusion increases latency, cost, contradiction risk, and low-signal context volume.

### 5.2 File Selection Is Still Mostly Mechanical

- provisional_status: `refine`
- current behavior:
  - Relevant files are selected by broad extension and filename lists.
  - Tests are selected by common path and filename patterns.
  - There is no ticket-aware ranking, ownership-aware selection, semantic search, symbol extraction, or use-case-aware narrowing in this path.
- desired behavior:
  - Keep broad fallback behavior for small repositories.
  - Add a policy layer that can prioritize files mentioned by the ticket, related tests, changed files from prior attempts, protocol-owned areas, and validation failure traces.

### 5.3 Protocol Authority Is Separated From Workspace File Authority

- provisional_status: `keep`
- current behavior:
  - Protocol files are excluded from normal workspace scanning and injected from project protocol state.
  - `protocol_model` content is omitted in the provider payload when `protocol_files` are already present, avoiding direct duplication.
- value:
  - This gives project protocols a distinct authority channel.
  - It reduces the chance that copied or stale protocol files in the workspace outrank modeled protocol state.
- open issue:
  - The intended authority order between ticket, protocol, repository files, validation output, and previous interactions should be made explicit.

### 5.4 Correction Context Is Present But Not Yet Curated

- provisional_status: `refine`
- current behavior:
  - Validation and application failures are passed forward as raw structured feedback.
  - Previous attempts are stored and replayed as recent records.
- value:
  - The model can see what failed and can adjust its next patch.
- risk:
  - Raw stdout, stderr, and previous records can become verbose or repetitive.
  - There is no explicit failure summarizer, affected-file extractor, or error-to-context selector yet.
- desired behavior:
  - Preserve raw feedback for early reliability.
  - Add an optional summarized correction packet that highlights failing commands, error classes, affected files, likely root causes, and what changed in the prior attempt.

### 5.5 The LLM Output Contract Is Clearer Than The Context Selection Contract

- provisional_status: `refine`
- current behavior:
  - The output contract is explicit: `proposed_changes`, `needs_correction`, or `blocked`, with files, commands, actions, warnings, and affected files.
  - The context contract is implicit in the current provider list and provider payload shape.
- desired behavior:
  - Define a durable context contract for ticket implementation and correction.
  - Include section names, authority levels, selection reasons, omission reasons, size limits, and freshness expectations.

### 5.6 Trace Metadata Already Carries Useful Diagnostics

- provisional_status: `keep`
- current behavior:
  - Trace metadata includes project, ticket, actor, source channel, section names, section summaries, and total context bytes.
- value:
  - This makes future context tuning measurable.
- desired behavior:
  - Use trace records to compare successful and failed attempts by context sections, bytes, selected files, and validation outcomes.

## 6. Candidate Context Policy Direction

The next design iteration should probably keep a layered policy rather than replace the current composer outright.

Possible policy shape:

```yaml
ticket_implementation:
  always_include:
    - ticket
    - project
    - operational_setup
    - protocol_files
    - tests
  include_when_available:
    - relevant_files
    - previous_interactions
  retry_only:
    - validation_feedback
  rank_files_by:
    - explicit ticket references
    - validation failure paths
    - prior affected files
    - nearby tests
    - project ownership/protocol rules
    - extension and filename fallback
```

Possible correction policy shape:

```yaml
ticket_correction:
  always_include:
    - ticket
    - previous_attempt_summary
    - validation_feedback
    - affected_files
    - failing_tests
    - protocol_files
  include_when_needed:
    - repository_tree
    - broader relevant_files
```

These are not final requirements. They are seed material for the dump and quiz rounds.

## 7. Questions For The Dump Round

The dump round should let the user freely clarify:

- what kinds of ticket work should be supported first: implementation, correction, refactor, docs, review fixes, or runtime setup changes
- when broad context is acceptable and when it becomes harmful
- which context sources should have the highest authority
- whether protocols should override ticket text or only constrain implementation style
- how much raw validation output should be sent to the LLM
- whether previous interactions should be raw, summarized, or hybrid
- how user-provided project knowledge should be injected before quizzes
- what counts as enough context for a correction attempt
- what should happen when context selection is uncertain

## 8. Expected Dump Artifacts

The next user-led dump should create:

- raw capture: `ops/conv/dump/2026-05-09-redwright-agent-ticket-llm-context-shaping-dump-raw.md`
- curated notes: `ops/conv/dump/2026-05-09-redwright-agent-ticket-llm-context-shaping-dump.md`

The dump should preserve user reasoning before turning it into a questionnaire.

## 9. Expected Quiz Direction

The later quiz should be bounded and sharper than the dump.

Candidate quiz sections:

- context authority order
- task types and context policies
- retry/correction feedback shape
- file selection and ranking rules
- previous interaction retention and summarization
- protocol inclusion and duplication rules
- trace/debug requirements
- first implementation constraints

## 10. Open Questions

- Should implementation and correction use one context policy with retry additions, or separate policy families?
- Should `needs_correction` remain a valid LLM output status if the current loop mainly reacts to application and validation failures?
- Should the system summarize validation feedback before retrying, or send raw output first and summarize only when large?
- Should repository conversation artifacts such as specs, quizzes, and dumps be part of ticket execution context, or should they only feed project protocols and tickets?
- Should context selection be deterministic only, LLM-assisted, or hybrid?
- What is the first measurable threshold for context bloat: bytes, tokens, file count, retry count, or failed attempts?

## 11. Out Of Scope

- implementing the new context policy
- changing the LLM provider adapter
- changing ticket lifecycle states
- changing the command/query API contract
- adding semantic search or Tree-sitter extraction in this draft
- replacing the current broad-context implementation

## 12. Next Iteration Inputs

- formal dump raw and curated artifacts
- formal quiz raw and curated artifacts
- selected trace examples from successful and failed ticket execution attempts
- current ticket for improving agent ticket LLM diagnostics and context shaping
- implementation evidence from `AgentTicketExecution::ContextComposer`, `ContextSectionProviders`, `ValidationLoop`, and `LlmRequester`
