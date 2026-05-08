---
id: TKT-20260508173734
title: Make Telegram ticket execution asynchronous
status: ready
kind: bug
severity: high
priority: high
scope: runtime
tags: telegram, agent-ticket-execution, async, llm-trace
source: manual_test
reported_at: 2026-05-08T17:37:34Z
ready_at: 2026-05-08T17:37:34Z
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
Manual testing of `/ticket start RW-10` showed that Telegram remains coupled to the full Rails ticket execution request. The Rails command waits for LLM execution, the Telegram HTTP client times out with `Net::ReadTimeout`, and the ticket eventually moves to `blocked` after an invalid or empty LLM response.

Relevant observed traces:

- Telegram returned: `Rails project setup API failed: Net::ReadTimeout with #<TCPSocket:(closed)>`
- Trace: `trc-2e36cc62`
- Latest inspected execution: `ticket_id=34`, `ticket_key=RW-10`
- LLM request: `agent_ticket_execution`, payload around `78KB`
- LLM response: `status=invalid_response`, `output_bytes=0`
- Board outcome: ticket moved to `blocked`
- Workspace outcome: no filesystem changes outside `.git` compared with the reference project

The corrective work should align the implementation with the existing agent ticket execution spec and quiz/dump intent: Telegram must acknowledge quickly, ticket execution must continue asynchronously, and the final outcome must be reported after completion.

## Problem
Telegram-driven ticket execution is currently synchronous across the Telegram daemon, Rails API request, LLM request, output application, validation, and kanban transition. This makes a normal LLM execution exceed the Telegram Rails API client's read timeout and returns a misleading error to the user even though Rails continues processing in the background.

The current error wording is also misleading: `Rails project setup API failed` is emitted for a ticket execution command, not only for project setup.

## Expected
- `/ticket start RW-10` sends an immediate acknowledgement to Telegram with the ticket reference and trace/work item information.
- The Telegram daemon does not keep an HTTP request open for the full LLM execution.
- Ticket execution continues asynchronously after acknowledgement.
- Telegram receives a final completion message when the execution ends, including the ticket reference, outcome, and trace.
- Timeout behavior does not surface as a project setup error for ticket execution commands.
- The manual scenario remains reproducible with `make agent-ticket-scenario-ready` and inspectable with `make agent-ticket-scenario-inspect`.

## Actual
- Telegram waits on the synchronous Rails command request.
- The Telegram Rails API client times out while Rails is still waiting on the LLM.
- The user receives `Rails project setup API failed: Net::ReadTimeout...`.
- Rails later marks the ticket as `blocked` after an invalid LLM response.
- No code is applied to `_workspace/Projects/go-todo-agent`.

## Fix Strategy
- Introduce an asynchronous execution boundary for Telegram-triggered `ExecuteAgentTicket`.
- Return an immediate command acknowledgement from Rails or the Telegram adapter instead of waiting for the full ticket execution loop.
- Ensure the background execution path can send or enqueue the final Telegram notification with ticket reference, outcome, and trace.
- Rename or route the Telegram error path so ticket execution failures do not report as project setup API failures.
- Keep a tactical timeout increase only if it is still useful for non-ticket commands; do not rely on timeout extension as the primary fix.
- Preserve current LLM trace visibility and include enough diagnostic context to identify invalid or empty LLM responses.

## Validation
- Run `make agent-ticket-scenario-ready`.
- Trigger `/ticket start RW-10` from Telegram.
- Confirm Telegram receives a quick acknowledgement without waiting for the LLM request to finish.
- Confirm no `Net::ReadTimeout` is returned to Telegram during normal ticket execution latency.
- Confirm final Telegram notification arrives after execution completes or blocks.
- Run `make agent-ticket-scenario-inspect` and verify the active project diff reflects the final execution outcome.
- Run the relevant Rails/runtime test suite for Telegram ticket execution and command query handling.

## Outcome
Pending implementation.
