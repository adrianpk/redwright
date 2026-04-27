# Cycle Plan: Redwright Daemon + Telegram Runtime

## Metadata

- cycle_id: `runtime-cycle-2026-04-27-redwright-daemon-telegram`
- status: `in_progress`
- owner: `adrianpk`
- created: `2026-04-27`
- updated: `2026-04-27`
- goal: `evolve redwright into a continuously running daemon that receives natural-language Telegram messages and materializes runtime actions`
- scope: `feature`

## Slice List

### Slice 1: YAML Runtime Configuration Foundation

- status: `completed`
- branch: `feat/slice-1-yaml-runtime-config-foundation`
- objective: `introduce authoritative YAML config loading and validation for daemon execution`
- tasks:
- [x] `T1.1 add config loader for ~/.config/redwright/config.yml and _workspace mirror`
- [x] `T1.2 define strict schema validation for runtime/telegram/paths keys`
- [x] `T1.3 add deterministic tests for valid and invalid config scenarios`
- acceptance:
- `daemon prerequisites can load validated config from one authoritative file path`
- `invalid config fails fast with explicit error`
- planned_commits:
- `feat(config): add yaml runtime configuration loader and schema validation`
- `test(config): cover yaml parsing and required key validation`
- PR:
- `tbd (to be opened from feat/slice-1-yaml-runtime-config-foundation)`

### Slice 2: Persistent Daemon Loop Surface

- status: `completed`
- branch: `feat/slice-2-persistent-daemon-loop-surface`
- objective: `add daemon command and continuous runtime loop with graceful shutdown`
- tasks:
- [x] `T2.1 add CLI surface redwright daemon run [--dev|--real]`
- [x] `T2.2 implement loop lifecycle with SIGINT/SIGTERM handling`
- [x] `T2.3 add loop lifecycle tests`
- acceptance:
- `daemon stays running until explicit termination signal`
- `graceful shutdown guarantees in-flight iteration completion`
- planned_commits:
- `feat(runtime): add daemon run loop command`
- `test(runtime): validate daemon loop lifecycle and shutdown semantics`
- PR:
- `tbd (to be opened from feat/slice-2-persistent-daemon-loop-surface)`

### Slice 3: Telegram Polling Ingress Adapter

- status: `pending`
- branch: `feat/slice-3-telegram-polling-ingress-adapter`
- objective: `receive Telegram updates and map natural-language messages to canonical runtime events`
- tasks:
- [ ] `T3.1 implement polling client for Telegram getUpdates`
- [ ] `T3.2 map update payloads into canonical runtime message inputs`
- [ ] `T3.3 enforce allowed_chat_ids filter from config`
- acceptance:
- `accepted Telegram text messages are transformed into canonical flow inputs`
- `messages from disallowed chats are rejected before runtime action`
- planned_commits:
- `feat(telegram): add polling ingress adapter and canonical event mapping`
- `test(telegram): verify update mapping and chat allow-list enforcement`
- PR:
- `tbd`

### Slice 4: Runtime Action Materialization + Telegram Response

- status: `pending`
- branch: `feat/slice-4-runtime-materialization-and-telegram-response`
- objective: `wire daemon ingress to runtime flow so each accepted message creates persisted actions and sends acknowledgment`
- tasks:
- [ ] `T4.1 dispatch accepted canonical messages into runtime flow`
- [ ] `T4.2 persist workstream/task outcomes for each accepted message`
- [ ] `T4.3 send Telegram acknowledgment including runtime identifiers and state`
- acceptance:
- `Telegram natural-language message leads to persisted task/workstream material effect`
- `Telegram response includes project/workstream/task identifiers`
- planned_commits:
- `feat(runtime): connect daemon ingress to flow processing and persistence`
- `feat(telegram): emit action acknowledgment responses`
- `test(runtime): cover end-to-end materialization path`
- PR:
- `tbd`

### Slice 5: Dev Smoke and Operational Gate

- status: `pending`
- branch: `feat/slice-5-daemon-telegram-smoke-gate`
- objective: `add repeatable validation entrypoints for daemon + telegram end-to-end flow`
- tasks:
- [ ] `T5.1 add dev smoke command path for daemon startup validation`
- [ ] `T5.2 add invariant test gate for daemon+telegram critical contract`
- [ ] `T5.3 update tracker with slice commit and validation correlation`
- acceptance:
- `team can execute one command sequence to validate daemon+telegram flow in dev mode`
- `CI/local gate fails when daemon or ingress core invariants regress`
- planned_commits:
- `chore(tooling): add daemon telegram smoke execution path`
- `test(invariants): enforce daemon telegram runtime contract`
- `chore(ops): close daemon telegram cycle tracker status`
- PR:
- `tbd`

## Global Exit Criteria

- `redwright runs as a persistent daemon process`
- `daemon ingests natural-language Telegram messages`
- `accepted messages materialize persisted runtime actions in SQLite`
- `daemon sends Telegram acknowledgment for each processed message`
- `cycle tracker correlates slices, commits, PRs, and validations`
