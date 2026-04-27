# Redwright Daemon + Telegram Proto-Spec

## Status

- type: `proto-spec`
- date: `2026-04-27`
- source: `ops/specs/drafts/2026-04-27-redwright-daemon-telegram-proto-spec-draft.md`

## 1. Scope

Define the execution contract for introducing daemon runtime behavior and Telegram ingress on top of existing Redwright runtime primitives.

## 2. In-Scope (Cycle)

- single authoritative YAML configuration file
- daemon process command surface and loop lifecycle
- Telegram polling ingress and canonical message dispatch
- persisted action materialization in SQLite
- Telegram acknowledgment responses

## 3. Out-of-Scope (Cycle)

- webhook-based Telegram ingress
- multi-user or multi-tenant runtime
- advanced auth/ACL models beyond chat ID allow-list
- distributed runtime deployment
- GUI/admin panel

## 4. Configuration Contract

Authoritative config path:
- real mode: `~/.config/redwright/config.yml`
- dev mode: `./_workspace/.config/redwright/config.yml`

Required keys:
- `runtime.loop_interval_ms`
- `runtime.blocked_retry_attempts`
- `telegram.bot_token`
- `telegram.poll_interval_seconds`
- `telegram.allowed_chat_ids`
- `paths.default_projects_root` (reserved for next runtime step; must parse correctly)

Startup behavior:
- missing file -> startup error
- invalid YAML/schema -> startup error
- valid file -> daemon starts

## 5. Daemon Contract

Command:
- `redwright daemon run [--dev|--real]`

Behavior:
- initialize bootstrap/runtime dependencies
- load and validate YAML config
- enter persistent loop
- fetch ingress events
- process each canonical message via runtime flow
- continue until stop signal

Shutdown:
- stop on `SIGINT`/`SIGTERM`
- flush in-flight loop iteration before exit

## 6. Telegram Ingress Contract

Input mapping:
- Telegram `message.text` -> runtime `message`
- chat/user metadata captured for access checks and auditing

Access control:
- if `allowed_chat_ids` is non-empty, only listed chat IDs are processed
- non-allowed chats do not trigger runtime actions

Output mapping:
- successful processing -> Telegram message with `project_id`, `workstream_id`, `task_id`, `state`
- processing error -> Telegram message with concise error status

## 7. Persistence Contract

For each accepted ingress message:
- runtime flow must complete project resolution
- runtime flow must resolve/create workstream as needed
- runtime flow must persist task row
- runtime flow result must be externally observable via CLI list/read commands

## 8. Validation Contract

Required validations for cycle completion:
- deterministic tests for YAML config loading and schema checks
- deterministic tests for daemon loop start/stop semantics
- adapter tests for Telegram update-to-canonical-message mapping
- smoke flow in dev mode proving Telegram message -> persisted task -> Telegram response

## 9. Completion Criteria

1. Daemon command is implemented and continuously running.
2. YAML config is required and validated at startup.
3. Telegram polling ingress is active and dispatches runtime actions.
4. Accepted natural-language messages produce persisted runtime artifacts.
5. Telegram response confirms resulting action IDs/state.
