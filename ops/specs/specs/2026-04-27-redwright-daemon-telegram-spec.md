# Redwright Daemon + Telegram Specification (v1.1)

## 1. Document Status

- type: `spec`
- version: `v1.1`
- date: `2026-04-27`
- derived from: `ops/specs/specs/2026-04-27-redwright-daemon-telegram-proto-spec.md`

## 2. Purpose

Define the normative behavior for evolving Redwright from CLI-dominant usage to daemon-first operation with Telegram ingress, while preserving existing CLI surfaces.

## 3. System Scope

Redwright remains a local, single-user coding harness.
Daemon mode is the primary runtime mode for agentic operation.
CLI one-shot commands remain valid as complementary operational/admin interfaces.

## 4. In-Scope (v1.1)

- required YAML configuration in fixed location
- daemon loop command and lifecycle
- Telegram polling ingress
- natural-language message intake through Telegram
- persisted workstream/task materialization in SQLite
- Telegram response emission with action identifiers

## 5. Out-of-Scope (v1.1)

- webhook ingress
- multi-user semantics
- non-Telegram ingress channels
- UI/dashboard
- plugin market/runtime extensibility model changes

## 6. Configuration Semantics

### 6.1 File Location

Authoritative config path:
- real mode: `~/.config/redwright/config.yml`
- dev mode: `./_workspace/.config/redwright/config.yml`

### 6.2 Required Structure

The file must define:
- `runtime.loop_interval_ms`
- `runtime.blocked_retry_attempts`
- `telegram.bot_token`
- `telegram.poll_interval_seconds`
- `telegram.allowed_chat_ids`
- `paths.default_projects_root`

### 6.3 Validation

Startup must fail with explicit error when:
- config file is missing
- YAML cannot be parsed
- required keys are absent or invalid

## 7. Daemon Runtime Contract

Command surface:
- `redwright daemon run [--dev|--real]`

Required behavior:
- bootstrap filesystem/db prerequisites
- load and validate config
- enter continuous loop
- poll Telegram updates
- dispatch canonical message events to runtime flow
- emit Telegram acknowledgments

Shutdown behavior:
- `SIGINT` and `SIGTERM` trigger clean shutdown
- process exits only after current iteration is safely finalized

## 8. Telegram Ingress Contract

### 8.1 Intake

- handle `message.text` updates as natural-language requests
- enforce `allowed_chat_ids` filter before dispatch

### 8.2 Dispatch

Each accepted message must produce runtime processing through existing flow primitives.

### 8.3 Response

Daemon sends confirmation message including:
- `project_id`
- `workstream_id`
- `task_id`
- resulting state

On processing error, daemon returns concise error response to originating chat.

## 9. Persistence Contract

Every accepted Telegram request must persist runtime evidence:
- project resolved
- workstream resolved/created
- task created
- workstream state updated

This evidence must be queryable via existing CLI read/list interfaces.

## 10. Invariants

- no removal of existing CLI command surfaces
- no one-shot-only runtime interpretation in product docs
- no message processing for disallowed chat IDs
- no accepted ingress message without persisted task/workstream consequence

## 11. v1.1 Acceptance Criteria (Frozen)

1. Daemon command runs continuously in dev mode.
2. Daemon command runs continuously in real mode.
3. YAML config is required and strictly validated.
4. Telegram message in natural language triggers runtime action.
5. Resulting action is persisted to SQLite.
6. Telegram receives confirmation payload with runtime IDs.
7. Graceful shutdown works under `SIGINT`/`SIGTERM`.
8. Automated tests cover config, loop lifecycle, and ingress mapping.
9. Dev smoke execution proves end-to-end message materialization.
