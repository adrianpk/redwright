# LLM Context Action Audit

## Metadata

- type: `artifact`
- date: `2026-05-09`
- cycle_id: `2026-05-09-redwright-llm-context-shaping`
- slice: `Slice 1`
- status: `in_progress`
- source_spec: `ops/specs/specs/2026-05-09-redwright-agent-ticket-llm-context-shaping-spec.md`
- source_plan: `ops/plans/2026-05-09-redwright-llm-context-shaping-cycle-plan.md`

## Purpose

Inventory current RedWright LLM actions, request-engine call sites, context sources, and capability status before implementing context policy resolution.

This artifact is intentionally descriptive. Slice 1 must not change runtime behavior.

## T1.1 LLM Actions And Request-Engine Call Sites

### Shared Request Engine Boundary

`Redwright::LLM::RequestEngine` is implemented at `lib/redwright/llm/request_engine.rb`.

Current public request method:

```ruby
generate_structured_message(
  model:,
  model_role:,
  provider:,
  action:,
  system_prompt:,
  user_text:,
  output_contract:,
  context_sections: [],
  trace_metadata: {}
)
```

Current behavior:

- receives explicit request inputs
- redacts system and user text before provider invocation
- calls `llm_client.complete_json`
- parses JSON provider output
- validates required fields from `output_contract`
- returns a normalized `Response`
- records diagnostics about context section names, authorities, bytes, trace metadata, and redaction
- does not fetch project, ticket, repository, or business state by itself

### Request Engine Call Sites

#### Agent Ticket Execution

- caller: `AgentTicketExecution::LlmRequester`
- path: `apps/web/app/services/agent_ticket_execution/llm_requester.rb`
- action: `agent_ticket_execution`
- model_role: `coding`
- request engine: `Redwright::LLM::RequestEngine`
- trace recorder: `Redwright::LLM::TraceRecorder`
- output contract: `AgentTicketExecution::LlmContract.output_contract`
- system prompt: `AgentTicketExecution::LlmContract.system_prompt`
- context source: `AgentTicketExecution::ContextComposer`
- notes:
  - This is the richest current structured context path.
  - The requester wraps context sections into provider-facing `user_text`.
  - `protocol_model` content is omitted from provider `user_text` when `protocol_files` are present to avoid duplication.

#### Quiz Question Generation

- caller: `QuizLoops::QuestionProvider`
- path: `apps/web/app/services/quiz_loops/question_provider.rb`
- actions:
  - `quiz_question_generation`
  - `quiz_fast_question_generation`
- model_role: `non_coding`
- request engine: `Redwright::LLM::RequestEngine`
- trace recorder: `Redwright::LLM::TraceRecorder`
- output contracts:
  - deep mode requires `QuestionContract::REQUIRED_FIELDS`
  - fast mode requires `questions`
- context source: local `context_sections_for(input)`
- notes:
  - This flow already uses structured context sections.
  - Context is quiz-specific and not yet available as general context for other actions.

#### Project Setup Prompt Rendering

- caller: `Redwright::ProjectSetupPromptRenderer`
- path: `lib/redwright/project_setup_prompt_renderer.rb`
- action: `project_setup_prompt_render`
- model_role: `non_coding`
- request engine: `Redwright::LLM::RequestEngine`
- trace recorder: `Redwright::LLM::TraceRecorder`
- output contract:
  - required fields: `message`, `semantic_slot`
  - rendered text field: `message`
- context source: local `context_sections_for(payload:, intent:, user_text:)`
- notes:
  - This flow uses the shared request engine for one concise project setup question.
  - It falls back when the LLM is unavailable or violates semantic slot constraints.

### Direct LLM Client Call Sites

These paths call an LLM client directly rather than `Redwright::LLM::RequestEngine`.

#### Telegram Runtime Intent Interpretation

- caller: `Redwright::LlmIntentInterpreter`
- path: `lib/redwright/llm_intent_interpreter.rb`
- provider call: `llm_client.complete_json`
- traced through: `Redwright::TelegramRuntimeHandler#interpret_with_trace`
- trace actions observed:
  - `intent_interpret`
  - `intent_interpret_with_current_context`
  - `intent_interpret_with_gap_answer`
  - `intent_refine_with_errors`
- notes:
  - This flow has project, architecture, and workspace context from `PromptContextLoader`.
  - It does not currently use `Redwright::LLM::RequestEngine`.
  - It should be included in the action-to-policy map or explicitly handled as legacy.

#### Alignment Question Engine

- caller: `Redwright::AlignmentQuestionEngine`
- path: `lib/redwright/alignment_question_engine.rb`
- provider call: `llm_client.complete_json`
- action shape: generates one next planning/alignment question
- notes:
  - This is a direct client path with its own JSON validation.
  - It is not currently integrated with context sections or `TraceRecorder`.

#### Runtime Container LLM Suggestion Provider

- caller: `RuntimeContainers::LlmSuggestionProvider`
- path: `apps/web/app/services/runtime_containers/llm_suggestion_provider.rb`
- provider call:
  - `client.generate_runtime_container(input: input)`, or
  - `client.call(input: input)`
- contract: `RuntimeContainers::LlmGenerationContract`
- notes:
  - This path validates structured runtime container attributes.
  - It does not use `Redwright::LLM::RequestEngine`.
  - It should map to an operation or planning policy once migrated.

### Context Builders Adjacent To LLM Calls

#### Prompt Context Loader

- path: `lib/redwright/prompt_context_loader.rb`
- current outputs:
  - `project_context`
  - `architecture_context`
  - `quality`
  - `workspace_context`
- used by: Telegram runtime interpretation path
- notes:
  - This is an existing project/workspace context loader, but not a `ContextSection` provider.

#### Iteration Context Packet Builder

- path: `lib/redwright/iteration_context_packet_builder.rb`
- current outputs include:
  - task goal
  - previous message
  - active clarification
  - errors
  - normalized failures
  - last execution results
  - file snippets
  - tree entries
  - semantic capabilities
  - Tree-sitter/plain-text/LSP-derived structural data where available
- notes:
  - This is a relevant existing semantic context capability.
  - It is not currently wired into agent ticket execution context policy.

## T1.1 Summary

Current LLM action coverage splits into two groups:

- structured request-engine users:
  - agent ticket execution
  - quiz question generation
  - project setup prompt rendering
- direct LLM client users or adjacent legacy paths:
  - Telegram runtime intent interpretation
  - alignment question generation
  - runtime container suggestion generation

Slice follow-up tasks must audit the current context layers for these call sites and classify each context capability as operational, partial, missing, or conceptual.

## T1.2 Context Layers Per Action

### Agent Ticket Execution

Action:

- `agent_ticket_execution`

Provider-facing request shape:

- `system_prompt`: stable coding-agent instruction from `AgentTicketExecution::LlmContract`
- `user_text`: JSON object built by `AgentTicketExecution::LlmRequester`
- `context_sections`: passed both to `RequestEngine` and embedded into provider `user_text`
- `output_contract`: structured implementation response contract

Context sections:

| Section | Authority | Source | Current selection behavior |
| --- | --- | --- | --- |
| `ticket` | `ticket_record` | `AgentTicketExecution::ContextSectionProviders::TicketProject` | always included for selected ticket |
| `project` | `project_record` | `AgentTicketExecution::ContextSectionProviders::TicketProject` | always included for selected ticket project |
| `repository_tree` | `workspace_filesystem` | `AgentTicketExecution::ContextSectionProviders::Repository` | all non-skipped files, capped at 300 entries |
| `relevant_files` | `workspace_filesystem` | `AgentTicketExecution::ContextSectionProviders::Repository` | broad filename/extension selection, capped at 32,000 bytes per file |
| `tests` | `workspace_filesystem` | `AgentTicketExecution::ContextSectionProviders::Repository` | broad test/spec path pattern selection, capped at 32,000 bytes per file |
| `operational_setup` | `project_operational_setup` | `AgentTicketExecution::ContextSectionProviders::OperationalSetupSection` | `.rw/agent` runtime setup discovery and validation commands |
| `protocol_files` | `project_protocol_model` | `AgentTicketExecution::ContextSectionProviders::Protocols` | modeled project protocol documents with full body |
| `protocol_model` | `project_protocol_model` | `AgentTicketExecution::ContextSectionProviders::Protocols` | modeled protocol state; provider payload omits content when `protocol_files` exists |
| `previous_interactions` | `historical_agent_llm_interaction` | `AgentTicketExecution::ContextSectionProviders::PreviousInteractions` | recent agent-LLM loop records for same ticket/session/agent when store exists |
| `validation_feedback` | `current_execution_feedback` | `AgentTicketExecution::ContextSectionProviders::ValidationFeedback` | only included on retry attempts with validation/application feedback |

Trace behavior:

- `ContextComposer` trace metadata includes trace id, project id, project ref, project root, ticket id, session id, source channel, actor identifier, context summary, context bytes, and context section names.
- `LlmRequester` records request and response through `Redwright::LLM::TraceRecorder` when available.
- Request trace includes full context section summaries through `context_sections.map(&:to_h)`.
- Response trace includes contract validation diagnostics and context bytes.

Current limitations:

- no policy selection
- no selected/omitted layer reasons
- no human conversation context
- no general docs/quizzes/dumps context
- no Tree-sitter context in this path
- protocol selection is all modeled protocol documents, not policy-specific document selection

### Quiz Question Generation

Actions:

- `quiz_question_generation`
- `quiz_fast_question_generation`

Provider-facing request shape:

- `system_prompt`: deep or fast quiz generation prompt
- `user_text`: JSON request payload containing project, quiz, recent entries, current question, and output contract
- `context_sections`: passed to `RequestEngine`
- `output_contract`: deep or fast quiz contract

Context sections:

| Section | Authority | Source | Current selection behavior |
| --- | --- | --- | --- |
| `project` | `project_context` | `QuizLoops::QuestionProvider#context_sections_for` | `input["project"]` |
| `quiz` | `request_context` | `QuizLoops::QuestionProvider#context_sections_for` | `input["quiz"]` |
| `recent_entries` | `quiz_context` | `QuizLoops::QuestionProvider#context_sections_for` | `input["recent_entries"]` |
| `current_question` | `request_context` | `QuizLoops::QuestionProvider#context_sections_for` | `input["current_question"]` |

Trace behavior:

- records request/response through `Redwright::LLM::TraceRecorder`
- request trace currently uses a text context summary of `Quiz next-question generation.`
- context sections are recorded as `context_sections.map(&:to_h)`

Current limitations:

- no policy selection
- no cross-flow quiz context provider for non-quiz requests
- no selected/omitted context reasons
- no document/protocol/file context

### Project Setup Prompt Rendering

Action:

- `project_setup_prompt_render`

Provider-facing request shape:

- `system_prompt`: project setup prompt-rendering instruction
- `user_text`: JSON payload containing setup summary, next prompt intent, semantic contract, setup context, user text, and output contract
- `context_sections`: passed to `RequestEngine`
- `output_contract`: `message` and `semantic_slot`

Context sections:

| Section | Authority | Source | Current selection behavior |
| --- | --- | --- | --- |
| `setup_summary` | `request_context` | `ProjectSetupPromptRenderer#context_sections_for` | API response summary text |
| `next_prompt_intent` | `request_context` | `ProjectSetupPromptRenderer#context_sections_for` | selected next setup slot intent |
| `setup_context` | `project_context` | `ProjectSetupPromptRenderer#context_sections_for` | setup context hash from response payload |
| `user_text` | `current_user_request` | `ProjectSetupPromptRenderer#context_sections_for` | latest user text |

Trace behavior:

- records request/response through `Redwright::LLM::TraceRecorder`
- request trace includes context summary, setup context bytes, and context sections
- response trace records fallback decision source when semantic slot does not match

Current limitations:

- no policy selection
- no project protocol or document context
- no conversation context beyond current user text

### Telegram Runtime Intent Interpretation

Actions observed through trace metadata:

- `intent_interpret`
- `intent_interpret_with_current_context`
- `intent_interpret_with_gap_answer`
- `intent_refine_with_errors`

Provider-facing request shape:

- direct `llm_client.complete_json` call through `Redwright::LlmIntentInterpreter`
- not currently routed through `Redwright::LLM::RequestEngine`
- `system_prompt` is built by `PlannerPromptBuilder`
- `user_text` is the incoming or refined Telegram text

Context sources:

| Context | Source | Current behavior |
| --- | --- | --- |
| `project_context` | `Redwright::PromptContextLoader` | manifest-derived or fallback project context |
| `architecture_context` | `Redwright::PromptContextLoader` | manifest-derived architecture/convention/quality context or fallback AGENTS extraction |
| `workspace_context` | `Redwright::PromptContextLoader` | workspace snapshot string |

Trace behavior:

- `TelegramRuntimeHandler#interpret_with_trace` records request and response through `Redwright::Trace`
- trace metadata includes context summary, context bytes, and context section names as plain names, not `ContextSection` objects

Current limitations:

- not using `RequestEngine`
- no context section authorities
- no policy selection
- fallback architecture context may read this repository's AGENTS rules and referenced `.agents` files

### Alignment Question Engine

Action:

- no shared action name currently exposed through `RequestEngine`
- conceptual action: alignment question generation

Provider-facing request shape:

- direct `llm_client.complete_json`
- `system_prompt`: `AlignmentQuestionEngine::SYSTEM_PROMPT`
- `user_text`: plain text payload with objective and prior turns

Context sources:

- objective
- prior turns

Trace behavior:

- no `RequestEngine` trace recorder integration found in the audited path

Current limitations:

- not using `RequestEngine`
- no context sections
- no policy mapping

### Runtime Container LLM Suggestion Provider

Action:

- no shared action name currently exposed through `RequestEngine`
- conceptual action: runtime container generation/suggestion

Provider-facing request shape:

- calls injected client through `generate_runtime_container(input:)` or `call(input:)`
- validates output with `RuntimeContainers::LlmGenerationContract`

Context sources:

- `RuntimeContainers::GenerationInputBuilder` output passed as `input`

Trace behavior:

- no `RequestEngine` trace recorder integration found in the audited path

Current limitations:

- not using `RequestEngine`
- no context sections
- no policy mapping

### Iteration Context Packet Builder

This is not a current `RequestEngine` call site, but it is a significant existing context construction capability.

Context packet fields include:

- task goal
- previous message
- active clarification
- last patch summary
- semantic capabilities
- stack hints
- current errors
- normalized failures
- last execution results
- tree entries
- file snippets
- intermediate representation (`ir_v1`)
- layered semantic selection
- bounds

Current limitations:

- not wired into agent ticket execution context composition
- not exposed as a named `ContextSection` layer
- Tree-sitter support exists as part of this packet builder area, but not as an operational policy-selectable layer for the new context-shaping model

## T1.2 Summary

Structured `RequestEngine` users already pass context sections, but the shape is caller-specific and policy-free.

Direct LLM client users still need either migration to `RequestEngine` or explicit legacy mapping before context shaping can be complete.

Context tracing exists, but it traces what was sent rather than why it was selected or omitted.
