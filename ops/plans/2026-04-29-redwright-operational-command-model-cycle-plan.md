# Cycle Plan: RedWright Operational Command Model

## Metadata

- owner: `adrianpk`
- status: `draft`
- scope: `runtime`
- objective: `stabilize deterministic operational commands with natural-language parity and eliminate runtime control-flow crashes`
- tracker: `ops/trackers/2026-04-29-redwright-operational-command-model-cycle-tracker.md`

## Slice List

### Slice 1: Micro-loop Nil Outcome Crash Fix

- status: `pending`
- branch: `fix/slice-1-micro-loop-nil-outcome-crash`
- [ ] `T1.1 fix nil merge path in telegram change-loop early exits`
- [ ] `T1.2 preserve terminal_reason semantics for clarify/reject exits`
- [ ] `T1.3 add regression tests for early exit without prior outcome`

### Slice 2: Operational Intent Taxonomy V1

- status: `pending`
- branch: `feat/slice-2-operational-intent-taxonomy-v1`
- [ ] `T2.1 define operational intent catalog independent from stack`
- [ ] `T2.2 separate control intent from engineering task intent`
- [ ] `T2.3 formalize required runtime fields for operational intents`
- [ ] `T2.4 add validator tests for taxonomy contract`

### Slice 3: Slash Command Set Expansion

- status: `pending`
- branch: `feat/slice-3-slash-command-set-expansion`
- [ ] `T3.1 add deterministic parser for /project list|where`
- [ ] `T3.2 add deterministic parser for /repo clone|status|undo`
- [ ] `T3.3 add deterministic parser for /task pause|resume|cancel`
- [ ] `T3.4 add deterministic parser for /plan start|continue|stop-and-apply`
- [ ] `T3.5 add deterministic parser for /trace on|off|status and /help`

### Slice 4: Natural-Language Parity Router

- status: `pending`
- branch: `feat/slice-4-natural-language-parity-router`
- [ ] `T4.1 map natural phrasing to operational intents via structured planner fields`
- [ ] `T4.2 enforce precedence policy: slash > explicit control fields > inferred control`
- [ ] `T4.3 prevent meta drift when user answers short confirmations`
- [ ] `T4.4 add multilingual parity tests for continue/cancel/pause/resume`

### Slice 5: Project and Repo Lifecycle Integration

- status: `pending`
- branch: `feat/slice-5-project-repo-lifecycle-integration`
- [ ] `T5.1 unify /project new and /repo clone into canonical project registration`
- [ ] `T5.2 persist project provenance (local_new vs remote_clone)`
- [ ] `T5.3 set active context deterministically per session/chat`
- [ ] `T5.4 add tests for clone/create/switch continuity`

### Slice 6: Undo Semantics V1

- status: `pending`
- branch: `feat/slice-6-undo-semantics-v1`
- [ ] `T6.1 define runtime-safe undo contract for non-destructive reversal`
- [ ] `T6.2 support last runtime action reversal with explicit constraints`
- [ ] `T6.3 define behavior when git and non-git actions are mixed`
- [ ] `T6.4 add tests for allowed/blocked undo paths`

### Slice 7: Skill Loop Control Commands

- status: `pending`
- branch: `feat/slice-7-skill-loop-control-commands`
- [ ] `T7.1 add explicit command to stop skill sub-loop and accept partial result`
- [ ] `T7.2 persist skill sub-loop terminal reason and accepted state`
- [ ] `T7.3 ensure handoff from skill loop back to main loop remains deterministic`
- [ ] `T7.4 add telemetry + tests for skill stop/accept flow`

### Slice 8: Cross-Channel Operational Parity Matrix

- status: `pending`
- branch: `feat/slice-8-cross-channel-operational-parity-matrix`
- [ ] `T8.1 add matrix tests for telegram and tui command parity`
- [ ] `T8.2 assert same persistence side effects for equivalent operations`
- [ ] `T8.3 assert same user-facing terminal reason classes`
- [ ] `T8.4 add simulated interruption/recovery scenarios`

## Exit Criteria

- Runtime no longer crashes on early loop exits.
- Operational command model is deterministic and stack-agnostic.
- Slash and natural-language routes converge to same operational intents.
- Project/repo lifecycle operations are canonical and traceable.
- Skill sub-loop can be stopped with explicit accept-state semantics.
