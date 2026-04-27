# Redwright Daemon + Telegram Proto-Spec Draft

## Status

- type: `proto-spec-draft`
- date: `2026-04-27`
- source: `ops/specs/specs/2026-04-27-redwright-runtime-spec.md` + alignment decisions (`2026-04-27`)

## 1. Scope

This draft defines the next runtime evolution for Redwright:
- keep current CLI capabilities
- add a persistent daemon runtime loop
- ingest natural-language requests through Telegram
- materialize each request into persisted runtime actions

## 2. Runtime Model (Incremental)

Redwright remains a single-user local harness.
Current one-shot command surface is retained as operational/admin interface.
Primary runtime behavior for this cycle is a continuously running daemon process.

## 3. Configuration Contract (YAML)

A single YAML file is authoritative in v1.1:
- real mode: `~/.config/redwright/config.yml`
- dev mode: `./_workspace/.config/redwright/config.yml`

Initial required sections:
- `runtime`
- `telegram`
- `paths`

The daemon must fail-fast on invalid or missing required configuration.

## 4. Daemon Loop Contract

New runtime command surface:
- `redwright daemon run [--dev|--real]`

Loop requirements:
- remains active until explicit termination signal
- handles `SIGINT` and `SIGTERM` with clean shutdown
- continuously polls ingress source(s)
- dispatches canonical messages to runtime flow processing

## 5. Telegram Ingress Contract

Transport requirements:
- use Telegram Bot API polling (`getUpdates`) in v1.1
- translate Telegram updates into canonical runtime messages
- support natural-language user text as input payload

Outbound requirements:
- send result acknowledgment through Telegram (`sendMessage`)
- include at minimum `project_id`, `workstream_id`, `task_id`, and execution status in response text

## 6. Persistence and Action Materialization

Each accepted Telegram request must produce material effect:
- resolve project
- resolve or create workstream
- create task row in SQLite
- update workstream state as defined by runtime flow

No slice in this cycle is considered complete without persisted evidence in SQLite.

## 7. Security and Access Filters (Initial)

Config-driven access guard:
- `telegram.allowed_chat_ids`

Behavior:
- messages from disallowed chat IDs are ignored
- disallowed attempts are logged as ingress rejections

## 8. Development and Operation Surface

Expected minimal command set after this cycle:
- `redwright daemon run --dev`
- `redwright bootstrap --dev`
- existing project/workstream/task commands remain valid

Rake shortcuts may wrap these commands for local operation, but daemon behavior is defined in runtime, not in Rake.

## 9. Acceptance Gate (Cycle-Level)

The cycle is complete only when all conditions are true:
- daemon process stays active and handles clean shutdown
- daemon receives real Telegram messages in natural language
- each accepted Telegram message creates or updates runtime entities and persists task/workstream evidence
- daemon replies back to Telegram with action result confirmation
- required YAML config sections are validated on startup

## 10. Open Items

- exact strategy for long-poll timeout and backoff values
- final logging format and log sink policy
- whether daemon should auto-register unknown local project paths in dev mode
