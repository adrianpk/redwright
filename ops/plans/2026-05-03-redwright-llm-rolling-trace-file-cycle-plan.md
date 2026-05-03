# Cycle Plan: RedWright LLM Rolling Trace File

## Metadata

- cycle_id: `cycle-2026-05-03-redwright-llm-rolling-trace-file`
- status: `completed`
- owner: `adrianpk`
- created: `2026-05-03`
- updated: `2026-05-04`
- goal: `add an opt-in rolling NDJSON trace file for LLM request and response events with bounded retention, basic redaction, and request-response correlation`
- scope: `feature`
- source_spec: `ops/specs/specs/2026-05-03-redwright-llm-rolling-trace-file-spec.md`

## Slice List

### Slice 1: Rolling Trace File Foundation

- status: `merged`
- branch: `fix/slice-1-llm-rolling-trace-file`
- pr_title: `feat(slice-1): add llm rolling trace file`
- objective: `thread configuration, correlation, metadata, redaction, and rotation through the existing Trace.llm_request and Trace.llm_response path without breaking live tracing`
- tasks:
- [x] `T1.1 add tracing.llm_file configuration parsing and defaults`
- [x] `T1.2 implement a small rolling NDJSON writer for LLM trace events`
- [x] `T1.3 thread stable llm_call_id correlation through request and response trace calls`
- [x] `T1.4 extend trace call payloads to carry project, ticket, session, actor, source, and context-size metadata when available`
- [x] `T1.5 apply bounded payload inclusion and basic redaction before persistence`
- [x] `T1.6 add tests for disabled behavior, enabled writes, correlation, rotation, redaction, and non-fatal writer failures`
- acceptance:
- `llm request and response trace events can be durably recorded as NDJSON`
- `the file is disabled by default and configuration-driven`
- `rotation keeps retained files bounded`
- `request-response correlation is stable`
- `payload capture is optional and redacted`
- `writer failures do not break LLM execution`
- planned_commits:
- `feat(runtime): add llm rolling trace file config`
- `feat(runtime): write llm rolling trace events`
- `test(runtime): cover llm rolling trace file`

## Global Exit Criteria

- `tracing.llm_file` is a supported configuration surface
- `Trace.llm_request` and `Trace.llm_response` can emit NDJSON events when enabled
- request and response events share a stable `llm_call_id`
- events attach available project and session correlation metadata
- payload inclusion is optional and independently controlled
- basic redaction is applied before persistence
- rotation bounds active and retained files
- tests cover the core feature contract

## Validation Command Context

- Ruby targeted tests must be run from repository root with `ruby -Itest <paths>`
- Rails targeted tests must be run from `apps/web` with `bundle exec bin/rails test <paths>` when web-side setup flows are touched
- PR validation entries must be reported as command plus `(pass)` or `(fail)`, without raw running traces

## Non-Goals

- Do not add a Rails UI for browsing LLM traces in this cycle.
- Do not add remote shipping or database persistence in this cycle.
- Do not introduce a separate tracing subsystem detached from `Trace.llm_request` and `Trace.llm_response`.
