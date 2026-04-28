# Cycle Plan: Redwright Bootstrap Gate and Intent Precedence

## Metadata

- owner: `adrianpk`
- status: `draft`
- scope: `runtime`
- objective: `enforce deterministic technical bootstrap gate and fix control-vs-implementation intent precedence`
- tracker: `ops/trackers/2026-04-28-redwright-bootstrap-gate-and-intent-precedence-cycle-tracker.md`
- execution_priority: `deferred` 
- note: `planned for a later cycle; not the immediate next implementation set`

## Problem Statement

Current runtime behavior still allows ambiguity between:

- technical bootstrap minimum questions (required to execute safely), and
- broader alignment/architecture questions (useful but often non-blocking).

Observed gaps:

- implementation may start without a stable minimal bootstrap contract per stack
- messages like "no more questions, continue" can route to control/resume instead of execution continuation
- alignment-style questions can block execution when technical minimum is already satisfied

## Principles

- Separate hard execution prerequisites from optional alignment depth.
- Use deterministic precedence rules in runtime transitions; keep language understanding flexible.
- Treat control intents as explicit control only when no active implementation objective is present.
- Keep user-facing messages natural; keep traceability in structured internal state.

## Slice List

### Slice 1: Technical Bootstrap Gate Contract

- status: `pending`
- branch: `feat/slice-1-bootstrap-gate-contract`
- [ ] `T1.1 define stack-agnostic bootstrap_minimum contract (project_name + stack-specific required fields)`
- [ ] `T1.2 define field registry per stack family (Go module, package manager identity, etc.) via prompt-driven gaps`
- [ ] `T1.3 persist bootstrap_missing_fields state in clarification session payload`
- [ ] `T1.4 add deterministic runtime rule: execution is blocked only while required bootstrap fields are unresolved`
- [ ] `T1.5 add tests for missing vs satisfied bootstrap gate outcomes`

### Slice 2: Intent Precedence Engine (Change > Control in Mixed Turns)

- status: `pending`
- branch: `feat/slice-2-intent-precedence-engine`
- [ ] `T2.1 define precedence matrix for mixed turns: change objective + control phrase`
- [ ] `T2.2 route "stop asking + continue implementation" to cancel_clarification_only + execute`
- [ ] `T2.3 route pure control-only turns to control command path`
- [ ] `T2.4 add confidence fallback: one short disambiguation only when dominance is truly unclear`
- [ ] `T2.5 add multilingual tests for ES/EN mixed phrasing`

### Slice 3: Clarification Scope Separation (Technical vs Architectural)

- status: `pending`
- branch: `feat/slice-3-clarification-scope-separation`
- [ ] `T3.1 label each gap as technical_blocking or alignment_optional`
- [ ] `T3.2 enforce hard-block only for technical_blocking gaps`
- [ ] `T3.3 keep alignment_optional questions resumable/deferred without blocking execution`
- [ ] `T3.4 persist and surface deferred alignment backlog in structured state`
- [ ] `T3.5 add tests proving execution can proceed with deferred optional alignment gaps`

### Slice 4: Runtime Control Semantics Hardening

- status: `pending`
- branch: `feat/slice-4-control-semantics-hardening`
- [ ] `T4.1 refine control intent mapping to avoid accidental resume-only terminal outcomes`
- [ ] `T4.2 add explicit state transition for "clarification cancelled, execution continued"`
- [ ] `T4.3 include guard against repeated re-clarification loops after cancel_clarification_only`
- [ ] `T4.4 add regression tests from real conversation traces`

### Slice 5: Structured Prompt Packet for Bootstrap/Execution Continuity

- status: `pending`
- branch: `feat/slice-5-structured-bootstrap-packet`
- [ ] `T5.1 send bootstrap_state and required_fields explicitly in planner packet`
- [ ] `T5.2 include active_objective and implementation_mode flags in packet`
- [ ] `T5.3 include top-level tree + bounded significant files as continuity context`
- [ ] `T5.4 enforce deterministic truncation and packet budget`
- [ ] `T5.5 add parser/contract tests for packet completeness`

### Slice 6: Conversation UX and Output Contract Tightening

- status: `pending`
- branch: `feat/slice-6-conversation-ux-tightening`
- [ ] `T6.1 keep natural-language clarify prompts without synthetic banner prefixes`
- [ ] `T6.2 keep traceability only in trace_id/session_id/gap_id and optional debug envelope`
- [ ] `T6.3 add tests for human output neutrality and debug mode coexistence`

### Slice 7: End-to-End Matrix for Bootstrap + Mixed Intent

- status: `pending`
- branch: `feat/slice-7-bootstrap-intent-e2e-matrix`
- [ ] `T7.1 new project request without name -> inferred confirm -> execution`
- [ ] `T7.2 Go project request -> module clarification -> execution`
- [ ] `T7.3 mixed message: "no more questions, continue" -> execute (not control_resume terminal)`
- [ ] `T7.4 architecture optional gap deferred while implementation proceeds`
- [ ] `T7.5 assert SQLite state and filesystem effects in isolated workspace`

## Global Exit Criteria

- Runtime always resolves a deterministic technical bootstrap minimum before first mutating execution.
- Mixed turns containing implementation objective and control phrase route to implementation continuation by default.
- Optional alignment questions no longer hard-block execution once technical minimum is satisfied.
- Clarification loops converge without repeated irrelevant re-questioning.
- E2E matrix demonstrates stable behavior across multilingual and multi-stack scenarios.
