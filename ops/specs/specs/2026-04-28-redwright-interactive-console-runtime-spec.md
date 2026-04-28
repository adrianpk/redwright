# Redwright Interactive Console Runtime Specification

## Status

- type: `spec`
- date: `2026-04-28`
- scope: `runtime + console ingress`
- goal: `add a minimal, extensible interactive console harness that reuses the existing deterministic runtime core and coexists with Telegram`

## 1. Product Intent

Redwright must provide a first-class local interactive experience in terminal while preserving current remote operation over Telegram.

Console mode is not a different agent. It is another ingress/egress surface over the same runtime contracts.

Primary outcomes:

- local operator can run long-lived interactive sessions from terminal
- all execution still flows through deterministic runtime state, action normalization, and persistence
- Telegram and console share behavior contracts, not divergent logic

## 2. Non-Goals

- no feature-heavy or complex TUI surface in first milestone
- no plugin marketplace implementation in this cycle
- no rewrite of existing Telegram runtime path
- no replacement of SQLite persistence in this cycle

## 3. Architecture Constraints

### 3.1 Single Runtime Core

All task planning/execution remains in existing runtime flow.

Console layer must not duplicate:

- intent routing logic
- micro-loop convergence logic
- action execution logic
- persistence writes

### 3.2 New Isolated Namespace

Console implementation must live under:

- `lib/redwright/console/*`

Ruby naming model:

- namespace/module based (`Redwright::Console::*`)
- no top-level cross-cutting helpers outside `lib/redwright/console`

### 3.3 Ingress Port Reuse

Console must implement the same ingress port shape already used by telegram/simulated adapters:

- poll events
- emit canonical event object
- support output message dispatch

## 4. Operating Model

### 4.1 Session Scope (PoC)

Console session is `single-project scoped`.

Rules:

- active project derives from launch directory or explicit startup arg
- no cross-project switching inside same console session in PoC
- multi-project workflows continue via Telegram (already supported)

Rationale:

- lower accidental cross-repo mutation risk
- faster and safer first iteration

### 4.2 Daemon Integration

`daemon run` must support additional ingress mode:

- `--ingress console`

Runtime startup output must clearly display:

- mode (`dev`/`real`)
- ingress (`console`)
- project scope resolution result

### 4.3 Event Semantics

Each user line entered in console becomes one canonical runtime event with:

- stable synthetic `external_message_id` increment
- stable local `external_chat_id` per session
- `transport: "console"`
- raw `text`

## 5. UX Contract (Console)

### 5.1 Human Output First

Default console output is human-readable.

Debug JSON envelope remains optional via existing flag behavior.

### 5.2 Input/Execution Behavior

- input line submitted while runtime idle: processed immediately
- input line submitted while runtime busy:
  - queued deterministically
  - delivered with the same steering/follow-up rules used by runtime queue semantics

### 5.3 Interrupt Semantics

Console must support deterministic interrupt command path:

- local cancel signal maps to existing control intents
- no out-of-band runtime state mutation

## 6. Clarification and Control Semantics

### 6.1 Shared Behavior with Telegram

Console must reuse same behavior for:

- dynamic clarifications
- gap sessions persistence
- cancel/resume semantics
- terminal reasons

### 6.2 Intent Precedence Safety

When message mixes implementation objective and stop-asking phrasing:

- runtime must prefer `continue implementation` semantics
- must not collapse into pure `control_resume` unless message is control-only

This rule belongs in runtime core and applies equally to console + telegram.

## 7. Minimal Tooling Model (Runtime Perspective)

Runtime must preserve minimal primitive model for execution:

- read/list/search
- write/edit/patch
- run command
- vcs operations (status/branch/commit/push)

Macro actions may exist but must normalize deterministically into primitive actions.

No hidden side channels.

## 8. Context and Prompt Packet Requirements

Console turns must construct same structured packet family used in runtime:

- agent context
- project context
- architecture/context rules
- bounded workspace snapshot (tree + top-K significant files)
- recent error context
- loop metadata

Packet limits must remain deterministic and configurable.

## 9. Persistence Contract

All console interactions must be persisted through existing stores.

Required persisted artifacts:

- task rows with trace linkage
- action execution rows
- clarification session rows
- workstream state transitions
- terminal reasons

No console-specific persistence bypass.

## 10. File/Module Design

### 10.1 Required New Components

- `lib/redwright/console/ingress_adapter.rb`
  - reads stdin lines
  - converts to canonical events
- `lib/redwright/console/client.rb`
  - sends human/debug output to stdout
  - typing hint behavior: no-op or lightweight spinner hook
- `lib/redwright/console/session.rb`
  - deterministic local session metadata (chat id, message counter)
- `lib/redwright/console/io_loop.rb`
  - polling loop integration helper

### 10.2 Runtime Wiring

- `lib/redwright.rb`
  - extend daemon CLI ingress options: `telegram|console|none`
  - build console adapter/client when selected
  - pass existing runtime handler with same dependencies

## 11. Configuration Contract

No mandatory new config keys for first console milestone.

Optional keys (future-safe, may be added in follow-up):

- `console.local_chat_id`
- `console.prompt_prefix`
- `console.enable_json_envelope`

If absent, runtime uses deterministic defaults.

## 12. Testing Strategy

### 12.1 Unit Tests

- console adapter line->event mapping
- deterministic local message id increment
- stdout formatting consistency
- busy-queue behavior

### 12.2 Integration Tests

- daemon + console ingress startup invariant
- console event -> runtime -> persistence chain
- clarification roundtrip in console mode
- cancel/resume behavior in console mode

### 12.3 Simulated E2E Matrix

Minimum matrix scenarios:

1. simple implementation request executes and writes files
2. technical clarification required, answer consumed, execution continues
3. "no more questions, continue" proceeds with defaults (not control-only)
4. bounded non-convergent path exits with `max_attempts`

## 13. Security and Safety

- all mutating actions still constrained by `allowed_projects_root`
- console scope must not mutate outside resolved project root in PoC mode
- destructive vcs actions remain blocked by confirmation policy

## 14. Observability

Trace model must remain channel-independent.

- same trace id behavior for console and telegram
- trace output toggled by existing environment flags
- no mandatory debug banners in human-facing responses

## 15. Phased Delivery Plan (Spec-Level)

### Phase A: Console Ingress PoC

- implement console adapter/client/session
- wire daemon ingress `console`
- implement a minimal full-screen TUI shell over console ingress
- pass core invariants and integration tests

### Phase B: Interaction Refinement

- queue ergonomics
- improved interrupt handling
- parity checks across telegram/console behavior

### Phase C: Advanced UI Layer (Optional)

- richer terminal UI components
- command palette/history/widgets
- still backed by same runtime core

## 16. Acceptance Criteria

Spec is satisfied when all are true:

- console ingress runs through the same runtime handler as telegram
- console session executes deterministic task lifecycle with persisted records
- clarification + control semantics match telegram behavior contracts
- mixed "stop asking + implement" messages continue execution correctly
- no unsafe cross-project mutations occur in PoC scoped mode
- integration/e2e coverage validates console workflow end-to-end
