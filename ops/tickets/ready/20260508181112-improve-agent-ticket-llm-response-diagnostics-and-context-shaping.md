---
id: TKT-20260508181112
title: Improve agent ticket LLM response diagnostics and context shaping
status: ready
kind: bug
severity: high
priority: high
scope: llm
tags: llm-trace, agent-ticket-execution, context, diagnostics
source: trace
reported_at: 2026-05-08T18:11:12Z
ready_at: 2026-05-08T18:11:12Z
started_at:
reviewed_at:
closed_at:
resolution:
owner: 
branch:
pr:
commits: []
---

## Context
After the Telegram ticket execution async fix, manual testing of `/ticket start RW-10` still blocked without applying repository changes. The issue was reproduced with both OpenRouter `openrouter/auto` and OpenAI `gpt-5.2`. In both cases RedWright recorded `agent_ticket_execution` as `invalid_response` with `output_bytes=0`, `raw_output=null`, `parsed_fields=[]`, and `trace_id=null`.

This scenario was anticipated in the agent ticket execution dump/quizzes: the first implementation may send broad context, but the `LLMRequestEngine` must make requests observable, preserve enough provider diagnostics, carry previous/conversation context correctly, and later optimize context instead of blindly sending duplicated material.

Relevant artifacts:

- `ops/conv/dump/2026-05-08-redwright-agent-ticket-execution-dump.md`
- `ops/conv/quiz/2026-05-08-redwright-agent-ticket-execution-quiz.md`
- `ops/specs/specs/2026-05-08-redwright-agent-ticket-execution-spec.md`
- `ops/specs/specs/2026-05-05-redwright-llm-request-engine-context-composition-spec.md`

Observed manual scenario:

- reset command: `make agent-ticket-scenario-ready`
- Telegram command: `/ticket start RW-10`
- verification command: `make agent-ticket-scenario-inspect`
- latest OpenRouter attempts: `invalid_response`, no filesystem diff
- latest OpenAI attempt: `ticket_id=36`, `provider=openai`, `model=gpt-5.2`, `payload_bytes=78177`, `status=invalid_response`, `output_bytes=0`, no filesystem diff
- board outcome: ticket moved to `blocked`
- project outcome: active project remained identical to the reference outside `.git`

## Problem
The agent ticket execution loop cannot distinguish why the provider response is invalid. The trace records the normalized status but omits the actionable diagnostic details needed to decide whether the failure is caused by invalid JSON, missing required fields, empty provider output, provider adapter parsing, context size, duplicated context, or a contract mismatch.

The request also still sends broad duplicated context. The observed context includes both `protocol_files` and `protocol_model`, around `31KB + 35KB`, within a total payload around `78KB`. This makes provider behavior harder to reason about and increases the chance of malformed or empty structured responses.

The async execution thread also loses the originating Telegram trace id, so the Telegram ingress trace cannot be reliably correlated with the LLM request/response events.

## Expected
- `agent_ticket_execution` traces include enough failure diagnostics to explain `invalid_response`.
- LLM response trace entries include warnings, diagnostic error class/message, raw response references when configured, and parsed/missing contract fields when available.
- Async Telegram ticket execution propagates the originating trace id into the background execution.
- Agent ticket LLM context avoids obviously duplicated protocol content before provider submission.
- The provider request keeps enough context to solve the ticket: ticket body, project facts, repository tree, relevant files, tests, operational setup, protocols, previous interactions, and validation feedback.
- `invalid_response` outcomes are visible as blocked/error outcomes, not user-facing successful completions.

## Actual
- `invalid_response` appears with `output_bytes=0`, `raw_output=null`, `parsed_fields=[]`, and no recorded warning/error detail.
- `trace_id` is null on `agent_ticket_execution` LLM events triggered from the async Telegram path.
- Switching from OpenRouter to OpenAI did not change the outcome.
- The active Go todo workspace shows no diff after the agent claims a terminal outcome.
- The prompt context includes large duplicated protocol material.

## Fix Strategy
- Propagate the Telegram ingress `trace_id` into the async ticket execution thread and into LLM trace metadata.
- Extend `LLM::TraceRecorder` and/or `AgentTicketExecution::LlmRequester#record_response` to persist response warnings, diagnostics, error class/message, missing fields, raw response references, and finish reason when available.
- Make `RequestEngine` distinguish empty provider content, invalid JSON, non-object JSON, missing required fields, and provider errors in diagnostics.
- Filter or compact duplicated protocol context for provider submission. A first conservative change can omit `protocol_model.content` when `protocol_files` are already included, while still keeping metadata in diagnostics.
- Keep provider-submitted context inspectable through `.log/llm.ndjson` without leaking raw provider internals to Telegram.
- Adjust the final Telegram message for blocked outcomes so it clearly communicates blocked/error, not successful completion.

## Validation
- Run the focused LLM request engine and agent ticket execution tests.
- Run `make agent-ticket-scenario-ready`.
- Trigger `/ticket start RW-10` using OpenAI and inspect `.log/llm.ndjson`.
- Confirm `agent_ticket_execution` events include a non-null trace id correlated with Telegram ingress.
- Confirm any `invalid_response` includes actionable diagnostics instead of only `output_bytes=0`.
- Confirm provider-submitted context no longer duplicates full `protocol_files` and `protocol_model` content.
- Run `make agent-ticket-scenario-inspect` and verify any applied changes or blocked outcome are explainable from trace data.

## Outcome
Pending implementation.
