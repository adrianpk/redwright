---
id: TKT-20260511180854
title: Extract reusable native agent engine boundary
status: open
kind: task
severity: high
priority: normal
scope: llm
tags: native-agent-engine,llm,orchestration
source: chat
reported_at: 2026-05-11T18:08:54Z
ready_at:
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
This is slice 1 of the agent execution roadmap captured in:

- `ops/conv/dump/2026-05-11-redwright-codex-backend-and-agent-sandboxing-dump-raw.md`
- `ops/specs/drafts/2026-05-11-redwright-reusable-agent-sandbox-behavior-draft.md`

RedWright already has several connected pieces for LLM execution: request routing, provider calls, intent preclassification, command preprocessing, context selection, and early harness behavior. Those pieces need a reusable engine boundary that can run inside RedWright for lightweight tasks and later run inside a managed worker with explicit environment variables.

## Problem
The current LLM-related behavior is not yet shaped as one reusable engine contract. Ticket execution, project setup, direct questions, and future managed-worker execution need to reuse the same intelligence layer without turning the runtime loop into a growing orchestration function.

## Expected
- A native agent engine boundary exists with explicit inputs, outputs, dependencies, and configuration.
- The engine can be called in embedded mode from RedWright for non-ticket tasks such as direct questions, project creation, and command interpretation.
- The same engine contract can be packaged later for managed-worker execution by passing explicit environment variables and task inputs.
- The engine does not own kanban state, ticket lifecycle transitions, Docker provisioning, or GitHub publication.
- Existing LLM request behavior keeps working through the new boundary.

## Actual
- LLM request, intent classification, preprocessing, and context assembly are still represented as connected capabilities rather than a clean engine surface.
- The future managed-worker path does not yet have a native RedWright engine contract to plug into.

## Fix Strategy
- Inventory the current LLM request, preclassification, preprocessing, and context-selection entry points.
- Define a small engine interface for task input, execution configuration, result output, events, and failure states.
- Add an embedded RedWright adapter that calls the engine without requiring Docker or a managed workspace.
- Keep Rails runtime and persistence concerns outside the engine boundary.
- Document the environment variables and runtime dependencies that would be required when the same engine is packaged for managed-worker execution.

## Validation
- Existing LLM request tests pass through the new boundary.
- A focused test can execute a simple embedded engine task and receive a structured result.
- A focused test verifies that the engine result does not mutate ticket or kanban state directly.
- Static search shows no new direct ticket-execution coupling inside the engine boundary.

## Outcome
Pending implementation.
