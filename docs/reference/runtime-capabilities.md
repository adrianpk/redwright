# Runtime Capabilities

This document defines what the current RedWright runtime does at a technical level.

## Current Capabilities

- accepts natural-language requests through supported ingress channels
- normalizes planner output into strict action envelopes
- validates payload contracts before execution
- executes bounded primitives for filesystem, shell, and git operations
- applies structured patch output through a dedicated patch application boundary
- stores runtime state and action execution records in SQLite
- emits trace events for ingress, planner, runtime, and persistence stages
- can execute selected development tickets through the agent ticket execution
  loop when project, workspace, operational setup, LLM response, validation, and
  git finalization checks pass

## Safety and Boundaries

- execution is constrained to configured project roots
- mutating actions are blocked outside allowed boundaries
- malformed planner output is rejected before execution
- ambiguous or missing runtime context is handled via clarify/error behavior
- agent ticket execution uses human-readable ticket keys for external
  invocation and database ids only as internal row identifiers
- validation commands are resolved from operational setup or runtime container
  metadata; missing validation commands block execution

## Agent Ticket Execution

Agent ticket execution currently supports targeted single-ticket work.

The execution path:

1. selects or resolves a development-ready ticket
2. resolves the project workspace inside the allowed projects root
3. composes LLM context from ticket, project, repository tree, relevant files,
   tests, operational setup, protocols, previous interactions, and retry
   feedback
4. requests structured changes from the LLM request engine
5. normalizes recoverable response contract near misses
6. applies file or structured patch output
7. runs validation commands
8. retries with validation feedback until success or retry exhaustion
9. commits successful changes and moves the ticket to review
10. moves unresolved work to blocked with a structured reason

## Server-Client Runtime Direction

Current cycle work introduces a single-writer server model:

- one runtime owner process controls execution and persistence
- clients (TUI/Telegram/console adapters) submit requests through local IPC
- request/response envelopes remain typed and validated
