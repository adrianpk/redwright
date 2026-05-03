# RedWright LLM Rolling Trace File Specification

## Metadata

- id: `spec-2026-05-03-redwright-llm-rolling-trace-file`
- status: `draft`
- owner: `adrianpk`
- created: `2026-05-03`
- updated: `2026-05-04`
- scope: `runtime-core/llm-tracing/configuration/local-observability`
- derived_from:
  - `ops/specs/drafts/2026-05-03-redwright-llm-rolling-trace-file-draft.md`

## Problem Statement

RedWright already exposes foreground LLM tracing through `Trace.llm_request` and `Trace.llm_response`, but that signal is transient and tied to live process output.

That is not enough for later debugging. When an LLM interaction goes wrong, RedWright needs a durable local trace that makes it possible to inspect which prompt was sent, how much context was attached, which project or session triggered the call, what the model returned, and whether the system followed an LLM or fallback path.

Without a durable trace sink, debugging context composition and project-specific LLM behavior remains slower and more error-prone than it needs to be.

## Goals

- add an opt-in durable rolling LLM trace file
- keep the trace file local-development oriented and disabled by default
- record one append-only NDJSON event per LLM request or response
- preserve request/response correlation with a stable `llm_call_id`
- attach `trace_id`, project, ticket, session, model, actor, action, and payload-size metadata when available
- make context weight visible even when prompt and output payload capture is disabled
- reuse the existing `Trace.llm_request` and `Trace.llm_response` call sites rather than introducing a parallel tracing API
- keep rotation bounded by configured file size and retained file count
- make writer failures non-fatal to LLM execution
- add basic secret redaction before payload-bearing fields are persisted

## Non-Goals

- Rails trace viewer UI
- remote log shipping
- database-backed trace persistence
- OpenTelemetry integration
- distributed tracing semantics beyond the existing `trace_id`
- perfect secret detection
- prompt quality scoring or automatic prompt optimization
- a new product surface for managing or browsing trace logs

## Product Contract

RedWright must support an opt-in rolling trace file for LLM calls.

When enabled, every LLM request and response traced through `Trace.llm_request` and `Trace.llm_response` must also be written to a newline-delimited JSON file under a local non-versioned log directory such as `./.log/`.

This durable trace complements live foreground trace output. It does not replace it, and it must not require stdout capture.

## Configuration Contract

LLM rolling file tracing must be disabled by default.

The capability must be enabled through configuration, not by code edits.

The first formal configuration contract is:

```yaml
tracing:
  llm_file:
    enabled: false
    path: "./.log/llm.ndjson"
    max_bytes: 10485760
    keep_files: 5
    include_payloads: false
    include_system_prompt: false
    include_user_text: false
    include_raw_output: false
```

Required semantics:

- `enabled` controls whether the file writer runs at all
- `path` points to the active NDJSON file
- `max_bytes` bounds the active file before rotation
- `keep_files` bounds the number of retained rotated files
- `include_payloads` controls whether payload-bearing fields may be emitted
- `include_system_prompt`, `include_user_text`, and `include_raw_output` are independent payload toggles that must not override `include_payloads: false`

## Event Format

The file format must be newline-delimited JSON.

Each line represents exactly one event.

Required event fields:

- `timestamp`
- `event`
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

Request events must additionally support:

- `system_prompt`
- `user_text`
- `context_summary`
- `context_bytes`
- `context_sections`

Response events must additionally support:

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

Optional fields may be omitted or set to `null`.

## Correlation Contract

Each traced request and response pair must share a stable `llm_call_id`.

Every event must include the current outer `trace_id` when available.

When the caller can resolve more metadata, the event must also include:

- `project_id`
- `project_ref`
- `project_root`
- `ticket_id`
- `session_id`
- `source_channel`
- `actor_identifier`

If some correlation values are unknown at the time of the call, the event must still be written with `null` values rather than being dropped.

## Context Visibility Contract

The trace file must remain useful even when payload capture is disabled.

Each request event must still record:

- `payload_bytes`
- `context_bytes` when separable
- `context_summary` when available
- `context_sections` when available
- `action`

That is required so context-size debugging remains possible without always persisting full prompts.

## Rotation and Failure Contract

The active trace file must rotate when it reaches the configured maximum size.

The system must retain only the configured number of rotated files and delete older ones.

Writer failures, directory-creation failures, and rotation failures must not break LLM execution.

When durable trace writing fails:

- the LLM call continues
- foreground trace output remains unaffected
- the failure may be surfaced through a concise warning path, but it must not raise back into the caller's normal LLM flow

## Redaction Contract

The durable trace may contain sensitive prompts and outputs.

The first implementation is explicitly local-development oriented and disabled by default.

Before writing payload-bearing fields, the system must apply basic redaction to obvious secrets such as:

- API keys
- bearer tokens
- authorization header values
- configured secret environment variable values when available

The first implementation does not need perfect DLP behavior. It does need explicit opt-in, bounded storage, and basic redaction.

## Call-Site Scope

The first cycle should instrument the existing productive `Trace.llm_request` and `Trace.llm_response` usage already present in runtime code, including:

- project setup prompt rendering
- Telegram runtime intent interpretation

The design should allow additional call sites later without changing the file format contract.

## Acceptance Criteria

1. RedWright has a formal `tracing.llm_file` configuration surface in `config.example.yml` and `AppConfigLoader`.
2. LLM file tracing is disabled by default.
3. When enabled, `Trace.llm_request` writes an NDJSON request event.
4. When enabled, `Trace.llm_response` writes an NDJSON response event.
5. Request and response events share a stable `llm_call_id`.
6. Events include `trace_id`, action, model metadata, and payload-size metadata.
7. Available project, ticket, session, actor, and source metadata are attached to events.
8. Request events retain useful context-size visibility even when payload capture is disabled.
9. Payload-bearing fields obey the payload-inclusion toggles.
10. Payload-bearing fields are redacted before persistence.
11. The active trace file rotates at the configured size and retains only the configured number of files.
12. Trace write or rotation failures do not break LLM execution.
13. Existing live foreground trace behavior continues to work.
14. Tests cover disabled behavior, enabled NDJSON writes, correlation, rotation, and redaction.
