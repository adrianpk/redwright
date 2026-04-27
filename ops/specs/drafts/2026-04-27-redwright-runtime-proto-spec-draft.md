# Redwright Runtime Proto-Spec (Refined Draft)

## Status

- type: `proto-spec-draft`
- date: `2026-04-27`
- source: `docs/redwright_ruby_coding_agent_spec.md` + alignment Q&A

## 1. Scope and Positioning

Redwright is a local, single-user coding harness.
It runs as a persistent agent process and executes coding-domain workflows with explicit traceability.

UI concerns are out of scope for v1.
A future UI layer is a note only and does not define runtime contracts.

## 2. Runtime Profile (v1)

- user model: single-user
- execution model: persistent interactive harness
- tool abstraction model: minimal two primitives
  - `run`: execute commands/code
  - `read`: read files and execution outputs

All higher-level operations (git, parsing, persistence operations, etc.) are built on top of these primitives.

## 3. Storage Model

Primary state is persisted in SQLite.

- db path (dev mode): `./_workspace/.redwright/runtime.db`
- db path (real mode target): `~/.redwright/runtime.db`

Runtime bootstrap must create state directories and database automatically when missing.

State must remain inspectable by humans (through readable artifacts, reports, and exported state views).

## 4. Filesystem Layout Strategy

### Real mode target (POSIX-style)

- app state/db: `~/.redwright/`
- config: `~/.config/redwright/`
- project root (v1 hardcoded): `~/RedWright/` (later configurable)

### Dev mode

`./_workspace/` simulates `~`.

Examples:
- `./_workspace/.redwright/`
- `./_workspace/.config/redwright/`
- `./_workspace/RedWright/`

Worktrees in dev mode:
- `./_workspace/RedWright/.worktrees/<workstream-id>`

## 5. Project Identity and Resolution

- project id format: `slug-XXXXXX`
- aliases supported (example: `rw`) with collision checks
- when message omits project, default to last active project

## 6. Workstream Semantics (Current Decisions)

- creating a new workstream requires user confirmation (provisional)
- default deviation handling is inline continuation
- isolation split is explicit and uses git worktree (no “fork” wording)
- intent change within same workstream is allowed when it is the same line of work
- `resume` defaults to last active workstream in current project (provisional)
- worktree lifecycle reuse policy on resume: unresolved

## 7. Task and Commit Policy

- every change maps to a formal task (provisional)
- a task may include multiple commits
- agent operates with autonomy for commits
- full traceability is mandatory:
  - `workstream -> task -> commit -> branch -> PR -> tracker`

## 8. Meta and State Handling

`meta` operations include:
- runtime state inspection
- git inspection and maintenance actions
- operational maintenance views for traceability

`waiting_user` applies to both:
- missing required information
- pending user approval

- `blocked`: external/non-resolvable failure without intervention
- `suspended`: intentional pause

No automatic suspension on inactivity in v1.

## 9. Planning Output Contract

For `plan` intent, output is strict in v1:
- `functional_spec`
- `technical_spec`

Specification artifact flow:
- working drafts: `ops/specs/drafts/`
- operational formalized specs: `ops/specs/specs/`
- stable published docs: `docs/`

## 10. Context Policy

Project facts persisted in SQLite are the primary fast context source.

When context is missing or ambiguous, policy is strict:
- always ask user
- do not guess

## 11. v1 Completion Gate

v1 completion is defined by a closed capability checklist, not by timebox.

## 12. Proposed v1 Done Checklist (for coordinator approval)

- [ ] persistent harness process runs locally in single-user mode
- [ ] runtime bootstraps state directories and SQLite database automatically
- [ ] project registration and resolution works by path, id, alias, and last-active fallback
- [ ] workstream lifecycle supports create, switch, resume, and state persistence
- [ ] deviation handling supports inline continuation and explicit worktree split
- [ ] task model persists task records and links tasks to workstreams
- [ ] commit traceability is recorded from workstream to task to commit to branch to PR/tracker
- [ ] `plan` intent produces both `functional_spec` and `technical_spec` artifacts
- [ ] specs workflow is operational: drafts in `ops/specs/drafts`, formalized specs in `ops/specs/specs`
- [ ] `meta` operations expose runtime state and git/worktree status
- [ ] ambiguity or missing context always triggers explicit user question
- [ ] blocked retry policy is configurable by `n` attempts, then escalates to user help
- [ ] core flows are covered by automated tests with deterministic pass criteria
- [ ] no destructive git operations are executed by default

## 13. Open Items

- exact resume policy for worktree reuse and stale worktree recovery
- strict safety policy for unrestricted `run` primitive (guardrail envelope)
