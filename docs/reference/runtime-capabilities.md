# Runtime Capabilities

This document defines what the current RedWright runtime does at a technical level.

## Current Capabilities

- accepts natural-language requests through supported ingress channels
- normalizes planner output into strict action envelopes
- validates payload contracts before execution
- executes bounded primitives for filesystem, shell, and git operations
- stores runtime state and action execution records in SQLite
- emits trace events for ingress, planner, runtime, and persistence stages

## Safety and Boundaries

- execution is constrained to configured project roots
- mutating actions are blocked outside allowed boundaries
- malformed planner output is rejected before execution
- ambiguous or missing runtime context is handled via clarify/error behavior

## Server-Client Runtime Direction

Current cycle work introduces a single-writer server model:

- one runtime owner process controls execution and persistence
- clients (TUI/Telegram/console adapters) submit requests through local IPC
- request/response envelopes remain typed and validated
