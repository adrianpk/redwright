# Cycle Tracker: Redwright Daemon + Telegram Runtime

## Metadata

- cycle_id: `runtime-cycle-2026-04-27-redwright-daemon-telegram`
- status: `in_progress`
- state: `awaiting_review`
- updated: `2026-04-27`
- active_slice: `slice-2`
- active_task: `T2.3`

## Slice Progress

### Slice 1: YAML Runtime Configuration Foundation

- status: `completed`
- branch: `feat/slice-1-yaml-runtime-config-foundation`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [x] `T1.1 add config loader for ~/.config/redwright/config.yml and _workspace mirror`
- [x] `T1.2 define strict schema validation for runtime/telegram/paths keys`
- [x] `T1.3 add deterministic tests for valid and invalid config scenarios`

Commits:

- [ ] `<sha> feat(config): add yaml runtime configuration loader and schema validation`
- [ ] `<sha> test(config): cover yaml parsing and required key validation`

Validation:

- [x] `config loads from authoritative path in dev and real mode`
- [x] `invalid schema fails fast with explicit errors`

### Slice 2: Persistent Daemon Loop Surface

- status: `completed`
- branch: `feat/slice-2-persistent-daemon-loop-surface`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [x] `T2.1 add CLI surface redwright daemon run [--dev|--real]`
- [x] `T2.2 implement loop lifecycle with SIGINT/SIGTERM handling`
- [x] `T2.3 add loop lifecycle tests`

Commits:

- [ ] `<sha> feat(runtime): add daemon run loop command`
- [ ] `<sha> test(runtime): validate daemon loop lifecycle and shutdown semantics`

Validation:

- [x] `daemon remains active until stop signal`
- [x] `graceful shutdown finalizes current loop iteration`

### Slice 3: Telegram Polling Ingress Adapter

- status: `pending`
- branch: `feat/slice-3-telegram-polling-ingress-adapter`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T3.1 implement polling client for Telegram getUpdates`
- [ ] `T3.2 map update payloads into canonical runtime message inputs`
- [ ] `T3.3 enforce allowed_chat_ids filter from config`

Commits:

- [ ] `<sha> feat(telegram): add polling ingress adapter and canonical event mapping`
- [ ] `<sha> test(telegram): verify update mapping and chat allow-list enforcement`

Validation:

- [ ] `allowed Telegram updates become canonical runtime messages`
- [ ] `disallowed chat IDs are rejected before runtime processing`

### Slice 4: Runtime Action Materialization + Telegram Response

- status: `pending`
- branch: `feat/slice-4-runtime-materialization-and-telegram-response`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T4.1 dispatch accepted canonical messages into runtime flow`
- [ ] `T4.2 persist workstream/task outcomes for each accepted message`
- [ ] `T4.3 send Telegram acknowledgment including runtime identifiers and state`

Commits:

- [ ] `<sha> feat(runtime): connect daemon ingress to flow processing and persistence`
- [ ] `<sha> feat(telegram): emit action acknowledgment responses`
- [ ] `<sha> test(runtime): cover end-to-end materialization path`

Validation:

- [ ] `natural-language Telegram message creates persisted runtime artifacts`
- [ ] `daemon returns confirmation with project/workstream/task identifiers`

### Slice 5: Dev Smoke and Operational Gate

- status: `pending`
- branch: `feat/slice-5-daemon-telegram-smoke-gate`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T5.1 add dev smoke command path for daemon startup validation`
- [ ] `T5.2 add invariant test gate for daemon+telegram critical contract`
- [ ] `T5.3 update tracker with slice commit and validation correlation`

Commits:

- [ ] `<sha> chore(tooling): add daemon telegram smoke execution path`
- [ ] `<sha> test(invariants): enforce daemon telegram runtime contract`
- [ ] `<sha> chore(ops): close daemon telegram cycle tracker status`

Validation:

- [ ] `dev-mode smoke demonstrates daemon + Telegram E2E materialization`
- [ ] `invariant gate protects daemon ingress and persistence contract`

## Event Log

- `2026-04-27 14:15` state=`planning` note=`new daemon+telegram cycle initialized with approved slice plan before implementation`
- `2026-04-27 14:45` state=`executing_slice` note=`slice 1 implementation started on feat/slice-1-yaml-runtime-config-foundation`
- `2026-04-27 14:52` state=`awaiting_review` note=`slice 1 completed with yaml config loader + validation tests; awaiting PR review`
- `2026-04-27 15:02` state=`executing_slice` note=`slice 2 implementation started on feat/slice-2-persistent-daemon-loop-surface`
- `2026-04-27 15:09` state=`awaiting_review` note=`slice 2 completed with daemon run command, loop lifecycle, and signal-stop tests`
