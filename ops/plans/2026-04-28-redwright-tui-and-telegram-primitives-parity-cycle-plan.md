# Cycle Plan: Redwright TUI and Telegram Primitives Parity

## Metadata

- owner: `adrianpk`
- status: `draft`
- scope: `runtime + ingress + tui`
- objective: `deliver a minimal full-screen TUI backed by the same primitive runtime contract used by Telegram`
- tracker: `ops/trackers/2026-04-28-redwright-tui-and-telegram-primitives-parity-cycle-tracker.md`

## Principles

- One runtime core, multiple channels.
- No duplicated execution logic across Telegram and TUI.
- Primitive actions are canonical and channel-agnostic.
- User-facing messages remain natural; debug output remains optional.
- Keep first TUI milestone humble in scope, full-screen in form.

## Slice List

### Slice 1: Console Ingress Foundation

- status: `pending`
- branch: `feat/slice-1-console-ingress-foundation`
- [ ] `T1.1 add Redwright::Console namespace under lib/redwright/console`
- [ ] `T1.2 implement console ingress adapter producing canonical runtime events`
- [ ] `T1.3 implement console session metadata (chat id + message id sequence)`
- [ ] `T1.4 extend daemon ingress options to telegram|console|none`
- [ ] `T1.5 add invariant tests for daemon startup in console ingress mode`

### Slice 2: Primitive Contract Unification

- status: `pending`
- branch: `feat/slice-2-primitive-contract-unification`
- [ ] `T2.1 formalize primitive action catalog in one runtime-facing contract`
- [ ] `T2.2 ensure macro actions normalize deterministically into primitive actions`
- [ ] `T2.3 ensure both Telegram and Console invoke the same normalization path`
- [ ] `T2.4 add tests for action normalization parity across channels`

### Slice 3: Busy-Turn Message Queue

- status: `pending`
- branch: `feat/slice-3-busy-turn-message-queue`
- [ ] `T3.1 add runtime queue subsystem for steering/follow-up messages`
- [ ] `T3.2 support deterministic queue drain modes (one-at-a-time/all)`
- [ ] `T3.3 integrate queue handling in runtime handler turn boundary`
- [ ] `T3.4 add tests for queue semantics and interruption safety`

### Slice 4: Intent Precedence Hardening

- status: `pending`
- branch: `feat/slice-4-intent-precedence-hardening`
- [ ] `T4.1 enforce implementation-dominant precedence for mixed control/change turns`
- [ ] `T4.2 preserve pure control-only routing for explicit pause/stop/resume intent`
- [ ] `T4.3 prevent accidental control_resume terminal when user asks to continue implementation`
- [ ] `T4.4 add multilingual tests for intent precedence robustness`

### Slice 5: Bootstrap Minimum Gate

- status: `pending`
- branch: `feat/slice-5-bootstrap-minimum-gate`
- [ ] `T5.1 enforce technical-blocking bootstrap fields before first mutating execution`
- [ ] `T5.2 separate technical_blocking gaps from alignment_optional gaps`
- [ ] `T5.3 allow execution with deferred optional alignment gaps`
- [ ] `T5.4 add stack-agnostic gate tests with Go/Ruby/Node-style fixtures`

### Slice 6: Minimal Full-Screen TUI Shell

- status: `pending`
- branch: `feat/slice-6-minimal-fullscreen-tui-shell`
- [ ] `T6.1 implement full-screen terminal shell with message pane + input pane`
- [ ] `T6.2 wire TUI shell to console ingress adapter and runtime output`
- [ ] `T6.3 show task lifecycle summary in TUI without JSON noise by default`
- [ ] `T6.4 keep debug envelope optional and off by default`
- [ ] `T6.5 add rendering/input tests for key interaction flows`

### Slice 7: Cross-Channel Parity Matrix

- status: `pending`
- branch: `feat/slice-7-cross-channel-parity-matrix`
- [ ] `T7.1 add e2e scenario set executed once through Telegram and once through Console/TUI`
- [ ] `T7.2 assert equivalent primitive action execution and terminal reasons`
- [ ] `T7.3 assert equivalent persistence side effects in SQLite`
- [ ] `T7.4 assert no mutation outside allowed_projects_root across channels`

## Global Exit Criteria

- TUI runs full-screen with humble feature scope and drives the same runtime core.
- Telegram and TUI use the same primitive action contract and execution path.
- Mixed control/change user messages are resolved consistently toward intended implementation behavior.
- Technical bootstrap minimum is enforced before mutating actions.
- Cross-channel parity matrix passes with deterministic persistence and terminal reasons.
