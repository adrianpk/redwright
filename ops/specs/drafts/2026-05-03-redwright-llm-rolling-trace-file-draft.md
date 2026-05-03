# RedWright LLM Rolling Trace File Draft

## Status

- type: `spec-draft`
- date: `2026-05-03`
- source: debugging need for durable LLM request/response traces with project correlation and context-size visibility

## 1. Scope

This draft defines the need for an opt-in rolling LLM trace file.

It does not define the final implementation, database schema, log viewer UI, distributed tracing system, or observability backend.

## 2. Problem Statement

Most agent behavior ultimately depends on LLM requests and LLM responses.

Current foreground tracing can expose LLM calls while a process is running, but it is not enough for later debugging. It is hard to inspect which prompt was sent, whether the context was too large, whether important context was missing, which project caused the call, and how the model answered.

RedWright needs a simple durable rolling file that records LLM conversations with enough metadata to debug context composition and project-specific behavior.

## 3. Product Need

RedWright needs a configuration-enabled LLM trace file that records:

- each LLM request
- each LLM response
- request/response correlation
- project association
- optional ticket/session association
- model/provider/action metadata
- payload sizes
- prompt/context content when explicitly enabled
- parse/decision metadata when available

The trace file should be useful for answering:

- Did RedWright send unnecessarily heavy context?
- Did RedWright omit necessary project context?
- Which project, ticket, or setup session triggered this LLM call?
- Which model and action produced a bad response?
- Did the system use an LLM result, fallback, or error path?

## 4. Relationship to Existing Trace Mechanism

This feature should complement the existing `Trace.llm_request` and `Trace.llm_response` mechanism.

Foreground trace output remains useful for live debugging.

The rolling file is the durable sink for later inspection. Implementations may reuse the same trace call sites, but the durable file should not require stdout capture.

## 5. Configuration Contract

LLM file tracing must be disabled by default.

It should be enabled through configuration, not by code edits.

Illustrative configuration shape:

```yaml
tracing:
  llm_file:
    enabled: false
    path: "./.log/llm.ndjson"
    max_bytes: 10485760
    keep_files: 5
    include_payloads: true
    include_system_prompt: true
    include_user_text: true
    include_raw_output: true
```

The final key names may change, but the capability must support:

- enabled/disabled switch
- file path under a non-versioned local log directory such as `./.log/`
- maximum file size
- retained rotated files
- independent control for prompt/request and raw response payload inclusion

## 6. File Format

The file should use newline-delimited JSON.

Each line is one event. This keeps writes append-only, easy to tail, easy to rotate, and easy to parse with standard tools.

Required event fields:

- `timestamp`
- `event`: `llm_request` or `llm_response`
- `llm_call_id`
- `trace_id`
- `project_id`
- `project_ref`
- `project_root`
- `ticket_id`
- `session_id`
- `source_channel`
- `actor_identifier`
- `model_role`
- `provider`
- `model`
- `model_alias`
- `resolved_model`
- `action`
- `payload_bytes`

Request events should additionally support:

- `system_prompt`
- `user_text`
- `context_summary`
- `context_bytes`
- `context_sections`

Response events should additionally support:

- `status`
- `latency_ms`
- `output_bytes`
- `finish_reason`
- `raw_output`
- `parsed_intent`
- `parsed_message`
- `parsed_fields`
- `decision_source`
- `error`

Missing optional fields should be omitted or set to `null`; they should not make the event invalid.

## 7. Project Correlation

Every LLM trace event should include project metadata when it is available.

At minimum, runtime and Rails callers should try to attach:

- project id
- project root or project ref
- setup session id when the call belongs to project setup
- ticket id when the call belongs to ticket execution
- trace id for the outer turn

If no project is resolved yet, the event should still be written with `project_id: null` and enough session/source metadata to debug the pre-project call.

## 8. Context Debugging Requirements

The trace must make context weight visible even when full payload logging is disabled.

Each request should record:

- total payload bytes
- context bytes when separable
- context section names
- optional per-section byte counts
- model action

This allows debugging context size problems without always storing full prompt text.

When payload inclusion is enabled, the trace should include the exact system prompt and user text or structured payload sent to the LLM after redaction.

## 9. Rolling Behavior

The trace file should rotate when it reaches the configured maximum size.

The system should retain a bounded number of rotated files and delete older files beyond that limit.

Rotation must not block LLM execution for a long time. If writing or rotation fails, the LLM call should continue and the failure should be visible through runtime trace or a concise warning.

## 10. Safety and Redaction

The trace may contain sensitive project data, prompts, and model outputs.

The first implementation should be local-development oriented and disabled by default.

Before writing events, implementations should redact obvious secrets such as:

- API keys
- bearer tokens
- authorization headers
- known secret environment variable values when available

This draft does not require perfect data-loss-prevention behavior. It requires explicit opt-in, bounded storage, and basic redaction so debugging does not accidentally create unbounded sensitive logs.

## 11. Desired Behavior

- LLM file tracing is disabled by default.
- Users can enable it through configuration.
- LLM request and response events are written to a rolling NDJSON file.
- Request and response events share a stable `llm_call_id`.
- Events include project, ticket, session, actor, channel, model, action, trace id, and size metadata when available.
- Payloads can be included for deep debugging.
- Payload inclusion can be disabled while retaining size and metadata signals.
- Rotation keeps disk usage bounded.
- Trace write failures do not break LLM execution.

## 12. Out of Scope

- Rails trace viewer UI
- remote log shipping
- OpenTelemetry integration
- database-backed trace storage
- perfect secret detection
- prompt quality analysis
- automatic context optimization

## 13. Open Questions

- Should payload inclusion default to false even when file tracing is enabled?
- Should Rails and runtime share one file or write separate files under the same trace directory?
- Should project setup LLM calls and ticket execution LLM calls use different actions or different files?
- What exact redaction rules are required before broader use?
- Should trace rotation use size only, date only, or both?

## 14. Next Iteration Inputs

- define the exact config keys in `config.example.yml`
- define a small `LlmTraceFileWriter` contract
- thread `llm_call_id` through request/response trace calls
- add project/ticket/session metadata to LLM trace call sites
- add tests for enabled/disabled behavior, NDJSON shape, rotation, and redaction
