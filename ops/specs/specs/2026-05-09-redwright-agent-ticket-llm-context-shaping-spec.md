# RedWright Agent Ticket LLM Context Shaping Specification

## Metadata

- id: `spec-2026-05-09-redwright-agent-ticket-llm-context-shaping`
- status: `draft`
- owner: `adrianpk`
- created: `2026-05-09`
- updated: `2026-05-09`
- scope: `llm-request-engine/context-policy/execution-profile/context-capabilities/tracing/tests`
- derived_from:
  - `ops/specs/drafts/2026-05-09-redwright-agent-ticket-llm-context-shaping-draft.md`
  - `ops/conv/dump/2026-05-09-redwright-agent-ticket-llm-context-shaping-dump.md`
  - `ops/conv/dump/2026-05-09-redwright-agent-ticket-llm-context-shaping-dump-raw.md`
  - `ops/conv/quiz/2026-05-09-redwright-agent-ticket-llm-context-shaping-quiz.md`
  - `ops/conv/quiz/2026-05-09-redwright-agent-ticket-llm-context-shaping-quiz-raw.md`
  - `ops/specs/specs/2026-05-05-redwright-llm-request-engine-context-composition-spec.md`
  - `ops/specs/specs/2026-05-08-redwright-agent-ticket-execution-spec.md`
  - `ops/specs/specs/2026-05-03-redwright-project-protocol-templates-spec.md`

## Problem Statement

RedWright already sends meaningful context to LLM calls. Agent ticket execution currently composes ticket, project, repository tree, relevant files, tests, operational setup, modeled protocols, previous agent-LLM interactions, and validation feedback. Quiz and project-setup flows also use the shared `Redwright::LLM::RequestEngine` pattern with structured context sections.

The problem is not that RedWright has no context. The problem is that context selection is still broad, mechanical, and uneven across flows. It does not yet use a task-aware policy model to decide which context should be injected for the concrete request being performed.

Sending the same broad context shape to every LLM request creates avoidable risks:

- irrelevant context can reduce answer quality
- stale context can outrank current evidence
- large context can hide the few files or records that matter
- protocol and document authority can remain implicit
- retry feedback can be too raw or repetitive
- policy decisions are not traceable enough for tuning
- missing context capabilities can make a future preclassifier ineffective

RedWright needs a complete context-shaping cycle that does two things:

1. resolves a request/action to an actionable context policy
2. makes every injectable context capability operational, traceable, and testable

## Goals

- introduce an optional preclassification stage that resolves the best context policy for a concrete LLM request
- keep the preclassifier focused on context optimization only
- avoid prompt rewriting in the preclassifier
- keep the architecture simple by placing policy resolution in `Redwright::LLM::RequestEngine` when that is the simplest viable boundary
- map every existing LLM action to one of the selected policy families
- make all injectable context types operational by the end of the slicing plan
- define explicit Ruby policies for context inclusion
- use a low-confidence fallback equivalent to the current broad context bundle
- trace selected policy, confidence, family, included layers, omitted layers, and omission reasons
- test policies with representative cases
- test preclassification through table-driven fake LLM responses
- preserve compatibility for existing callers while making context shaping available across all LLM actions

## Non-Goals

- regex or keyword classification as the primary semantic mechanism
- prompt-template selection or prompt rewriting by the preclassifier
- adding another orchestration component between the preclassifier and `LLMRequestEngine`
- perfect final taxonomy before implementation
- arbitrary compression of protocol documents
- treating generated protocol files as the canonical protocol source
- provider-backed tests for preclassification
- naming bikeshedding beyond provisional implementation names

## Product Contract

RedWright must use task-aware context policy to shape LLM requests.

When context policy resolution is enabled for a request:

1. RedWright prepares the normal request payload for the action.
2. A lightweight preclassification stage resolves an execution profile.
3. The profile chooses one primary `context_policy`.
4. `LLMRequestEngine` uses that policy to select or shape context layers.
5. The concrete LLM request proceeds with the existing downstream action prompt and output contract.
6. The trace records the policy decision and final context packet.

The preclassifier must not become a new planner. It does not change the prompt, choose business workflow, mutate records, or execute commands. It decides the context policy for the request that performs the real action.

## Current Implementation Baseline

The current `Redwright::LLM::RequestEngine`:

- accepts explicit inputs
- calls the configured LLM client
- validates JSON and required fields
- returns normalized response objects
- records diagnostics for context section names, authorities, and bytes
- does not fetch project, ticket, repository, or business state by itself

The current `Redwright::LLM::ContextSection` supports:

- `name`
- `content`
- `authority`
- `metadata`
- byte calculation

The current agent ticket execution context path includes:

- `ticket`
- `project`
- `repository_tree`
- `relevant_files`
- `tests`
- `operational_setup`
- `protocol_files`
- `protocol_model`
- `previous_interactions`
- `validation_feedback`

The current implementation already avoids duplicating generated protocol files by excluding `AGENTS.md` and `.agents/` from normal repository scanning. Protocols enter ticket execution context from the modeled project protocol state.

## Architecture Decision

### Preclassification Ownership

The preclassifier may live inside `Redwright::LLM::RequestEngine` as an optional first stage when that is the simplest implementation.

No new external policy orchestration component should be introduced for this cycle.

The allowed responsibility split is:

```text
LLM caller
  -> LLMRequestEngine
    -> optional preclassification
    -> policy resolution
    -> context layer selection
    -> provider request
```

The caller may still gather explicit business inputs. The engine must not fetch Active Record or workflow state on its own.

### Preclassifier Boundary

The preclassifier owns:

- semantic interpretation of the request/action payload for context policy selection
- primary work family selection
- confidence band selection
- context policy selection
- reasoning metadata for trace/debug

The preclassifier does not own:

- prompt rewriting
- business workflow orchestration
- ticket transitions
- command execution
- file edits
- validation execution
- user-facing planning
- final action output contract

## Execution Profile

The preclassifier returns an execution profile.

The provisional name `ExecutionProfileResolver` is acceptable, but naming is not the primary concern. The architecture must allow a later rename without changing the contract meaning.

### Required Profile Fields

The profile must include:

```json
{
  "primary_work_family": "implementation",
  "context_policy": "implementation_default",
  "confidence": "high",
  "requires_code_changes": true,
  "requires_command_execution": true,
  "requires_validation": true,
  "should_ask_clarification": false,
  "reasoning_summary": "The request asks to implement a feature in code and validate it."
}
```

The profile may include:

```json
{
  "runner_up_families": ["diagnosis"],
  "request_complexity": "moderate",
  "expected_outputs": ["files", "commands"],
  "policy_inputs": {
    "explicit_paths": ["app/models/ticket.rb"],
    "has_validation_feedback": false
  }
}
```

### Primary Family Rule

The profile must always choose one strongest primary family.

`mixed` must not become an operational output that triggers a second heuristic layer. If the request is mixed, that uncertainty belongs in metadata or trace fields such as `runner_up_families` and `reasoning_summary`.

### Confidence Bands

Confidence must use simple bands:

- `high`
- `medium`
- `low`

The first implementation acts only on the band, not on a numeric score.

When confidence is `low`, RedWright must use an explicit broad fallback policy equivalent to the current loaded context bundle.

The fallback policy should be named:

```text
full_context_fallback
```

## Work Families

The initial family set is experimental but explicit:

- `exploration`
- `implementation`
- `modification`
- `diagnosis`
- `evaluation`
- `operation`
- `planning`
- `documentation`

These families must be isolated enough to merge, rename, or split later without rewriting the full request pipeline.

The family set is not intended to erase a richer ticket taxonomy. The richer vocabulary may still exist as ticket metadata, labels, subtypes, or user-facing language.

## Policy Contract

The preclassifier returns a `context_policy`.

`LLMRequestEngine` uses or resolves that policy into the context layers that are injected into the concrete request.

Policies must be explicit Ruby code. The first implementation should use the simplest Ruby representation that solves the problem:

- declarative constants or hashes when enough
- objects/classes only when actual policy logic requires them

Policies may live in one Ruby file or one file per policy module. The organization should favor simplicity and testability.

## Existing Action Mapping

Every existing LLM action must map to one selected family or policy.

Known action areas include:

- `agent_ticket_execution`
- quiz question generation
- project setup prompt rendering
- existing Telegram/runtime intent interpretation paths where still relevant

The mapping must be explicit and tested. Dynamic preclassification can be enabled per action, but all actions must still have a default policy/family mapping.

## Context Layers

All injectable context types must be accounted for and operational by the end of the implementation plan:

- `execution_contract`
- `project`
- `prompt`
- `concrete_files`
- `file_tree`
- `treesitter`
- `llm_based_context`
- `docs`
- `quizzes`
- `dumps`
- `previous_conversation`
- `protocols`

The plan may add slices to enable missing capabilities before policy pruning is complete.

### Execution Contract

Stable agent instructions remain in `system_prompt`.

Do not create a broad narrative `agent` context section.

Create a compact structured section named:

```text
execution_contract
```

It should include variable execution data such as:

- primary work family
- context policy
- execution mode
- allowed outputs
- allowed actions
- whether validation is required
- retry attempt
- max attempts
- workspace boundary

This section is high authority and should be considered alongside `system_prompt` for operational constraints.

### Project

Project context is required by default.

Keep it simple. The first implementation should prefer a consistently available project section over sophisticated omission rules.

Project context may later support levels, but no arbitrary compaction mechanism should be assumed unless implemented and tested.

### Prompt

The prompt is distinct from the ticket body.

- `ticket_body` is persisted task content and workflow metadata.
- `prompt` is the provider-facing request instruction assembled by the downstream action.

The preclassifier does not rewrite the prompt.

The preclassifier optimizes the context injected into the later concrete request.

### Protocols

`Protocols` is a RedWright system entity. It must not be confused with this repository's `.agents` files, even when there is conceptual overlap.

The canonical source is modeled project protocol state:

- `ProjectProtocol`
- `ProjectProtocolDocument`
- document `key`
- document `path`
- document `title`
- document `layer`
- document `position`
- document `body`
- document `provenance`

The filesystem projection is operational output, not the canonical context source.

Policy selection must evaluate which modeled protocol documents matter for each work family.

Examples:

- code work may need conventions and linting-oriented protocol documents
- Git operations may need versioning-oriented protocol documents
- design decisions may need architecture-oriented protocol documents

These examples are illustrative. The implementation must inspect the actual protocol model and available protocol documents rather than hardcoding this repository's `.agents` paths as the source of truth.

Protocol documents should be specific enough in their own form. Do not force arbitrary condensation.

A minimal representation of the full protocol set may be introduced only if it is simple and useful. It must not replace selecting relevant full protocol documents.

### Documents

Documents include durable RedWright artifacts such as:

- drafts
- specs
- plans
- trackers
- user/project documents
- related repository artifacts when modeled or discoverable

This is a pruning/refinement effort, not a first-time context definition. Everything should be available for use, then selected by policy and relevance.

Document selection must be traceable. Traces should show selected and omitted documents when policy resolution considers them.

### Quizzes

Quiz artifacts are a context source.

Selection may depend on:

- project scope
- use-case scope
- ticket scope
- action family
- recency
- explicit links

The first implementation must make quiz context operational where not already operational.

### Dumps

Dumps are not implemented as an injectable context source yet.

They must be tracked as a missing capability and enabled by an explicit slice.

### Previous Conversation

Previous conversation must include both:

- agent-LLM execution-loop conversation
- relevant human-RedWright conversation

Human conversation matters because TUI and Telegram flows involve humans.

Selection scope may vary by policy:

- use-case-only
- use-case-plus-project
- project-wise

Project-wise context may later become consistently useful, but the first implementation should preserve policy-level control.

### Concrete Files

Concrete file context includes the content of files selected for the request.

Selection should become policy-driven and traceable. Current broad extension/name selection is a useful fallback, but it is not sufficient as the final pruning model.

### File Tree

File tree context must be available as a layer.

Policies may include:

- no tree
- light tree
- targeted subtree
- full bounded tree

### Tree-sitter

Tree-sitter or equivalent semantic code structure is a required context capability for the complete cycle.

It should not be injected into every request. Policies that need code structure should include it.

If Tree-sitter is missing, the implementation plan must include an enablement slice.

### LLM-Based Context

LLM-based context includes derived summaries, rankings, issue analysis, previous attempt summaries, or generated context.

It has lower authority than primary artifacts unless explicitly generated for the current request.

The implementation must define which LLM-based context sources exist, where they are stored, and how they are selected.

## Authority Order

The initial conflict-resolution order is:

1. `system_prompt` and `execution_contract`
2. Protocols
3. ticket / prompt
4. current source files / validation output
5. project docs / quizzes / dumps / conversation
6. LLM-derived summaries

This order is an initial default. It must be traceable and tunable.

## Policy Tracing

Each request with context policy resolution must trace:

- selected policy
- primary work family
- confidence band
- runner-up families when present
- included context layers
- omitted context layers
- omission reasons
- selected documents/protocols/quizzes/dumps when applicable
- fallback use
- policy inputs that influenced selection

Policy trace data should live in the same trace record family as request/response data so behavior can be tuned from real outcomes.

## Testing Requirements

### Unit Tests

Policy tests must prove:

- included layers per representative family
- omitted layers per representative family
- low-confidence fallback
- action-to-policy mapping
- protocol selection behavior against modeled protocol documents
- trace metadata shape

### Integration Tests

Integration tests must verify:

- existing callers still work
- every mapped action receives a policy
- final request traces include policy data
- context sections match policy expectations
- low confidence uses `full_context_fallback`

### Preclassifier Tests

Preclassifier tests must use fake table-driven responses.

Tests must not depend on live provider calls.

The fake response set must cover:

- each work family
- low confidence
- medium/high confidence
- runner-up metadata
- invalid classifier payload
- fallback behavior

## Compatibility

Context policy resolution may be opt-in at the call boundary for compatibility, but every LLM action must still have an explicit default policy/family mapping.

Existing request behavior must remain stable until that action is migrated into policy resolution.

Action-specific context shaping should not break existing output contracts.

## Implementation Constraints

- Keep all repository documentation and code in English.
- Do not introduce another policy orchestration component.
- Do not make regex/keyword matching the primary semantic classifier.
- Do not hardcode RedWright repository `.agents` paths as protocol truth.
- Do not assume compaction exists unless implemented.
- Use explicit Ruby policy definitions.
- Add capability enablement slices for missing context types.
- Keep the system traceable enough to tune after implementation.

## Required Capability Audit

Before or during implementation, audit all context types:

| Context type | Current status | Required end state |
| --- | --- | --- |
| `execution_contract` | missing | operational structured section |
| `project` | partial/implemented across flows | required default layer |
| `prompt` | implemented by callers | distinct from preclassifier and ticket body |
| `concrete_files` | implemented broadly in ticket execution | policy-selected and traced |
| `file_tree` | implemented in ticket execution | policy-selectable |
| `treesitter` | missing in ticket execution | operational capability |
| `llm_based_context` | partial | defined and selectable |
| `docs` | partial/conceptual | selectable context source |
| `quizzes` | implemented in quiz loops, not general ticket context | selectable context source |
| `dumps` | missing | operational capability |
| `previous_conversation` | partial agent-LLM loop only | include human and agent conversation where relevant |
| `protocols` | implemented as modeled protocol state | policy-selected modeled documents |

## Acceptance Criteria

The cycle is complete when:

1. every LLM action maps to a family/policy
2. `LLMRequestEngine` can use a returned `context_policy`
3. low confidence triggers `full_context_fallback`
4. all context types are operational or explicitly implemented by capability slices
5. `execution_contract` is injected where relevant
6. protocols are selected from modeled protocol state
7. docs, quizzes, dumps, and previous conversation have defined selection paths
8. Tree-sitter context is available and policy-selectable
9. policy decisions are present in traces
10. unit tests cover policy inclusion/omission
11. integration tests verify final traces and request context
12. preclassifier tests use table-driven fake responses

## Open Questions

- What exact Ruby shape should the policy definitions use?
- What exact field names should the execution profile use?
- Which existing actions should enable dynamic preclassification immediately versus use static default policies first?
- What exact source should provide human conversation context across TUI and Telegram?
- What is the smallest viable dumps context implementation?
- Which Tree-sitter language support is needed first?
- How should LLM-based context be stored and invalidated?
