# Cycle Plan: RedWright Operational Command Model

## Metadata

- owner: `adrianpk`
- status: `completed`
- scope: `runtime`
- objective: `stabilize deterministic operational commands with natural-language parity and eliminate runtime control-flow crashes`
- tracker: `ops/trackers/2026-04-29-redwright-operational-command-model-cycle-tracker.md`

## Slice List

### Slice 1: Micro-loop Nil Outcome Crash Fix

- status: `completed`
- branch: `fix/slice-1-micro-loop-nil-outcome-crash`
- [x] `T1.1 fix nil merge path in telegram change-loop early exits`
- [x] `T1.2 preserve terminal_reason semantics for clarify/reject exits`
- [x] `T1.3 add regression tests for early exit without prior outcome`

### Slice 2: Operational Intent Taxonomy V1

- status: `completed`
- branch: `feat/slice-2-operational-intent-taxonomy-v1`
- [x] `T2.1 define operational intent catalog independent from stack`
- [x] `T2.2 separate control intent from engineering task intent`
- [x] `T2.3 formalize required runtime fields for operational intents`
- [x] `T2.4 add validator tests for taxonomy contract`

### Slice 3: Slash Command Set Expansion

- status: `completed`
- branch: `feat/slice-3-slash-command-set-expansion`
- [x] `T3.1 add deterministic parser for /project list|where`
- [x] `T3.2 add deterministic parser for /repo clone|status|undo`
- [x] `T3.3 add deterministic parser for /task pause|resume|cancel`
- [x] `T3.4 add deterministic parser for /plan start|continue|stop-and-apply`
- [x] `T3.5 add deterministic parser for /trace on|off|status and /help`

### Slice 4: Natural-Language Parity Router

- status: `completed`
- branch: `feat/slice-4-natural-language-parity-router`
- [x] `T4.1 map natural phrasing to operational intents via structured planner fields`
- [x] `T4.2 enforce precedence policy: slash > explicit control fields > inferred control`
- [x] `T4.3 prevent meta drift when user answers short confirmations`
- [x] `T4.4 add multilingual parity tests for continue/cancel/pause/resume`

### Slice 5: Project and Repo Lifecycle Integration

- status: `completed`
- branch: `feat/slice-5-project-repo-lifecycle-integration`
- [x] `T5.1 unify /project new and /repo clone into canonical project registration`
- [x] `T5.2 persist project provenance (local_new vs remote_clone)`
- [x] `T5.3 set active context deterministically per session/chat`
- [x] `T5.4 add tests for clone/create/switch continuity`

### Slice 6: Undo Semantics V1

- status: `completed`
- branch: `feat/slice-6-undo-semantics-v1`
- [x] `T6.1 define runtime-safe undo contract for non-destructive reversal`
- [x] `T6.2 support last runtime action reversal with explicit constraints`
- [x] `T6.3 define behavior when git and non-git actions are mixed`
- [x] `T6.4 add tests for allowed/blocked undo paths`

### Slice 7: Skill Loop Control Commands

- status: `completed`
- branch: `feat/slice-7-skill-loop-control-commands`
- [x] `T7.1 add explicit command to stop skill sub-loop and accept partial result`
- [x] `T7.2 persist skill sub-loop terminal reason and accepted state`
- [x] `T7.3 ensure handoff from skill loop back to main loop remains deterministic`
- [x] `T7.4 add telemetry + tests for skill stop/accept flow`

### Slice 8: Cross-Channel Operational Parity Matrix

- status: `completed`
- branch: `feat/slice-8-cross-channel-operational-parity-matrix`
- [x] `T8.1 add matrix tests for telegram and tui command parity`
- [x] `T8.2 assert same persistence side effects for equivalent operations`
- [x] `T8.3 assert same user-facing terminal reason classes`
- [x] `T8.4 add simulated interruption/recovery scenarios`

## Exit Criteria

- Runtime no longer crashes on early loop exits.
- Operational command model is deterministic and stack-agnostic.
- Slash and natural-language routes converge to same operational intents.
- Project/repo lifecycle operations are canonical and traceable.
- Skill sub-loop can be stopped with explicit accept-state semantics.
