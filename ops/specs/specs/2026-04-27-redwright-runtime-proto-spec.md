# Redwright Runtime Proto-Spec

## Status

- type: `proto-spec`
- date: `2026-04-27`
- source: `docs/redwright_ruby_coding_agent_spec.md` + alignment Q&A

## 1. Scope

Redwright is a local, single-user coding harness.
It runs as a persistent agent process and executes coding-domain workflows with explicit traceability.

UI is out of scope for v1 and remains a future note only.

## 2. Runtime Profile (v1)

- user model: single-user
- process model: persistent interactive harness
- tool model:
  - `run`: execute commands/code
  - `read`: read files and execution outputs

All higher-level capabilities (git operations, parsing, persistence handling) are composed through these two primitives.

## 3. Storage

Primary runtime state is persisted in SQLite.

- real-mode target db path: `~/.redwright/runtime.db`
- dev-mode db path: `./_workspace/.redwright/runtime.db`

Bootstrap must create missing state directories and database files automatically.

## 4. Filesystem Layout

Real-mode target layout:
- app state/db: `~/.redwright/`
- config: `~/.config/redwright/`
- project root (v1 hardcoded): `~/redwright/` (later configurable)

Dev mode mirrors home paths under `./_workspace/`.

Dev-mode worktree path:
- `./_workspace/redwright/.worktrees/<workstream-id>`

## 5. Project Resolution

- `Project.id` format: `slug-XXXXXX`
- aliases supported with collision checks (example alias: `rw`)
- if project is omitted, resolve to last active project

## 6. Workstream Behavior

- new workstream creation requires user confirmation (provisional)
- default deviation handling is inline continuation
- split handling is explicit worktree-based isolation
- intent change within same workstream is allowed for same line of work
- `resume` defaults to last active workstream in current project (provisional)
- worktree reuse policy on resume remains open

## 7. Task and Commit Policy

- every code change maps to a formal task (provisional)
- tasks may include multiple commits
- agent has commit autonomy
- mandatory traceability chain:
  - `workstream -> task -> commit -> branch -> PR -> tracker`

## 8. State Semantics

`meta` covers runtime state, git/worktree state, and maintenance/trace views.

`waiting_user` is valid for:
- missing required information
- pending explicit user approval

State distinction:
- `blocked`: external/non-resolvable failure without intervention
- `suspended`: intentional pause

No automatic suspension by inactivity in v1.

## 9. Planning Output Contract

For `plan` intent, v1 requires both artifacts:
- `functional_spec`
- `technical_spec`

Specification flow:
- drafts: `ops/specs/drafts/`
- formalized operational specs: `ops/specs/specs/`
- stable published docs: `docs/`

## 10. Context Policy

SQLite-persisted project facts are the primary fast context source.

If context is missing or ambiguous:
- always ask user
- do not guess

## 11. Failure Retry Policy

Blocked retry behavior is configurable via runtime config:
- automatic retries: `n` attempts
- on exhaustion: escalate to user help (`waiting_user`)

## 12. v1 Done Gate

v1 completion is checklist-based (not timeboxed).

Required capabilities:
- persistent harness process in single-user mode
- auto-bootstrap of state directories and SQLite db
- project resolution by path/id/alias/last-active fallback
- persisted workstream lifecycle with switch/resume support
- inline deviation and explicit worktree split
- persisted task model linked to workstreams
- full traceability chain to tracker artifacts
- `plan` output generation (`functional_spec` + `technical_spec`)
- operational spec flow (`ops/specs/drafts` -> `ops/specs/specs`)
- `meta` coverage for runtime and git/worktree visibility
- ask-first behavior on ambiguity/missing context
- configurable blocked retries with user escalation
- deterministic automated tests for core flows
- no destructive git operations by default

## 13. Open Items

- exact resume policy for worktree reuse and stale worktree recovery
- strict safety envelope for unrestricted `run` execution
