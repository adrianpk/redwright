# Cycle Plan: Redwright Server-Client Runtime Transition

## Metadata

- owner: `adrianpk`
- status: `draft`
- scope: `runtime + ingress + tui + telegram`
- objective: `move to a single-writer rw-server with socket clients so Telegram and TUI can run concurrently without state collisions`
- tracker: `ops/trackers/2026-04-28-redwright-server-client-runtime-cycle-tracker.md`

## Principles

- Single writer for runtime state.
- All channels go through one server execution path.
- Clients are stateless transport/render adapters.
- Runtime safety invariants remain enforced centrally.
- Human output remains clean; traces/logs are operational.

## Slice List

### Slice 1: Server Core and Runtime Lock

- status: `pending`
- branch: `feat/slice-1-server-core-runtime-lock`
- [ ] `T1.1 add rw-server process entrypoint with dev/real mode support`
- [ ] `T1.2 add runtime lock file ownership in state dir to enforce single writer`
- [ ] `T1.3 add lock lifecycle handling for startup, shutdown, and stale lock detection`
- [ ] `T1.4 expose basic server health operation (ping/status)`
- [ ] `T1.5 add tests for lock exclusivity and stale lock recovery semantics`

### Slice 2: Local IPC Protocol and Session Bus

- status: `pending`
- branch: `feat/slice-2-local-ipc-session-bus`
- [ ] `T2.1 define local Unix socket protocol using newline-delimited JSON envelopes`
- [ ] `T2.2 define request/response/event message contracts (send/ack/error/subscribe/event)`
- [ ] `T2.3 add server session registry keyed by channel and session id`
- [ ] `T2.4 add routing from inbound client messages to runtime server dispatcher`
- [ ] `T2.5 add protocol validation tests and malformed payload rejection tests`

### Slice 3: Runtime Execution Ownership Migration

- status: `pending`
- branch: `feat/slice-3-server-runtime-ownership`
- [ ] `T3.1 move runtime flow invocation behind server dispatcher as single execution owner`
- [ ] `T3.2 ensure telegram/tui/console clients submit events only, never execute primitives directly`
- [ ] `T3.3 preserve existing safety constraints (allowed_projects_root, confirmations, gate behavior)`
- [ ] `T3.4 persist execution/result envelopes centrally from server path`
- [ ] `T3.5 add regression tests for parity with pre-server behavior on core flows`

### Slice 4: TUI and Telegram as Socket Clients

- status: `pending`
- branch: `feat/slice-4-tui-telegram-socket-clients`
- [ ] `T4.1 convert TUI ingress mode into a socket client bound to rw-server`
- [ ] `T4.2 convert Telegram daemon ingress into a socket client adapter`
- [ ] `T4.3 separate UI output from operational logs in TUI mode`
- [ ] `T4.4 make telegram config requirements conditional on selected ingress channel`
- [ ] `T4.5 add integration tests for simultaneous TUI + Telegram client activity`

### Slice 5: Recovery, Controls, and Cross-Channel Parity

- status: `pending`
- branch: `feat/slice-5-recovery-controls-parity`
- [ ] `T5.1 add client reconnection and resume behavior for dropped local sessions`
- [ ] `T5.2 add server control operations (` + "`status|stop|resume|trace`" + `) via lightweight ctl client`
- [ ] `T5.3 add deterministic multi-client sequencing tests for same project and mixed projects`
- [ ] `T5.4 assert no out-of-root mutations and no direct-client state writes across channels`
- [ ] `T5.5 close cycle with parity matrix and operational runbook updates in ops tracker`

## Global Exit Criteria

- Exactly one server process owns runtime state writes per environment.
- Telegram and TUI can run concurrently as clients against one server.
- Server is the only primitive executor and persistence writer.
- Client-side UX remains clean while traces/logs remain available operationally.
- Cross-channel behavior and safety invariants are deterministic and test-covered.
