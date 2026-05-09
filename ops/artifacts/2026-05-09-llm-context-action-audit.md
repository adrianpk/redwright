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
