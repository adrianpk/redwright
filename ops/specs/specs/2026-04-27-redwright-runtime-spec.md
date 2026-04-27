# Redwright Runtime Specification (v1)

## 1. Document Status

- type: `spec`
- version: `v1.0`
- date: `2026-04-27`
- derived from: `ops/specs/specs/2026-04-27-redwright-runtime-proto-spec.md`

## 2. Purpose

Define the execution-ready contract for the first implementation phase of Redwright.
This document is normative for runtime behavior and implementation planning.

## 3. System Scope

Redwright is a local coding harness for a single user.
It runs as a persistent process and executes coding-domain workflows with explicit traceability.

## 4. In-Scope (v1)

- persistent local harness process
- project/workstream/task lifecycle persistence
- two primitive execution interfaces:
  - `run` for command/code execution
  - `read` for file/output retrieval
- SQLite-backed runtime state
- project resolution by path, id, alias, and last-active fallback
- explicit workstream split via git worktree
- strict ask-first policy on missing context or ambiguity
- `plan` intent outputs:
  - `functional_spec`
  - `technical_spec`
- operational traceability:
  - `workstream -> task -> commit -> branch -> PR -> tracker`
- operational specification workflow:
  - `ops/specs/drafts/` -> `ops/specs/specs/` -> `docs/` (promotion when stable)

## 5. Out-of-Scope (v1)

- multi-user runtime behavior
- UI/API contract definition (including Rails integration)
- plugin-specific semantic hardcoding in core router
- transport-specific UX requirements beyond current harness operation
- automatic suspension by inactivity
- advanced safety sandboxing beyond current guardrail policy

## 6. Runtime Operating Model

### 6.1 User and Process Model

- single-user local runtime
- persistent interactive execution model

### 6.2 Storage Model

Primary state store is SQLite.

- real-mode path: `~/.redwright/runtime.db`
- dev-mode path: `./_workspace/.redwright/runtime.db`

Bootstrap requirement:
- runtime must create missing directories and database on first start.

### 6.3 Filesystem Layout

Real-mode targets:
- state/db: `~/.redwright/`
- config: `~/.config/redwright/`
- managed projects root (v1 default): `~/redwright/`

Dev-mode mirror root:
- `./_workspace/` simulates `~`

Dev-mode worktrees:
- `./_workspace/redwright/.worktrees/<workstream-id>`

## 7. Identity and Resolution

### 7.1 Project Identity

- project id format: `slug-XXXXXX`
- project aliases allowed and must be collision-checked

### 7.2 Default Resolution

If project reference is omitted, runtime resolves to last active project.

## 8. Workstream and Task Semantics

### 8.1 Workstream Rules

- creating a new workstream requires explicit user confirmation
- default deviation handling is inline continuation
- split into isolated execution context is explicit and worktree-based
- intent change within same workstream is allowed when same line of work
- `resume` defaults to last active workstream in current project

### 8.2 Task Rules

- each code change must map to a formal task
- tasks may contain multiple commits
- agent can commit autonomously

## 9. State Semantics

- `waiting_user`:
  - missing required information
  - pending explicit user approval
- `blocked`:
  - external/non-resolvable failure without intervention
- `suspended`:
  - intentional pause

Blocked retry policy:
- configurable automatic retries (`n`)
- on retry exhaustion, escalate to user (`waiting_user`)

## 10. Planning Contract

For `plan` intent, runtime must output both:
- `functional_spec`
- `technical_spec`

No plan is complete until both artifacts exist for the active planning cycle.

## 11. Context Policy

- primary fast context source: SQLite-persisted project facts
- if context is missing or ambiguous:
  - always ask user
  - never guess

## 12. Invariants

- no destructive git operations by default
- no phrase-level semantic routing in core
- no cross-workstream contamination
- deterministic traceability from runtime work item to delivery artifact

## 13. v1 Acceptance Criteria (Frozen)

v1 is complete only when all criteria below are satisfied:

1. Harness process runs persistently in single-user mode.
2. State bootstrap creates required directories and SQLite db automatically.
3. Project resolution works for path, id, alias, and last-active fallback.
4. Workstream lifecycle is persisted and supports create/switch/resume.
5. Inline continuation and explicit worktree split both work.
6. Task records are persisted and linked to workstreams.
7. Traceability chain is recorded to tracker artifacts.
8. `plan` output includes both `functional_spec` and `technical_spec`.
9. Spec workflow directories are operational (`drafts`, `specs`).
10. `meta` visibility covers runtime and git/worktree state.
11. Ambiguity handling always asks user.
12. Blocked retry policy is configurable and escalates on exhaustion.
13. Core flows are covered by deterministic automated tests.
14. Runtime does not execute destructive git operations by default.

## 14. Open Questions for Post-v1

- exact policy for worktree reuse and stale worktree recovery on resume
- strict execution safety envelope for unrestricted `run`
