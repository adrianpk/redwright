# Agent Operating Contract

This file is the project entrypoint for agent work. It routes
work to the normative documents under `.agents/`.

## Required Loading

Treat the current user-authorized objective as one task. Before its first
workspace or external-state change:

1. Load `.agents/INVARIANTS.md` and
   `.agents/ROUTING.md` once for the task.
2. Load only the concern documents required for the current action. If the
   concern changes, load its owner before acting.
3. Inspect `.agents/PLAYBOOKS.md` only when the task may match an
   operational procedure, then load the smallest applicable playbook set.
4. Detect applicable repository stacks from repository-owned files:
   - Chrome extension applies when a root `manifest.json` declares Manifest
     V3.
   - Rails applies when `Gemfile` declares Rails; otherwise Ruby applies when
     `Gemfile` exists.
   - Go applies when `go.mod` or `go.work` exists.
   - Odin applies when repository-owned `.odin` source exists.
   - Racket applies when repository-owned `.rkt` or `.scrbl` source exists.
   - TypeScript applies when a TypeScript configuration or repository-owned
     `.ts` or `.tsx` source exists.
   - Rust applies when `Cargo.toml` exists.
   - Apply independent overlays together when multiple conditions hold.
5. For each applicable stack, load only the documents under
   `.agents/stacks/<stack>/` that match the active concerns.
6. Read `.agents/protocol/ACTIVITY.md` before reconstructing or summarizing
   completed work, answering activity or timesheet questions, creating a
   commit, or changing pull-request state.
7. Read `.agents/protocol/KNOWLEDGE.md` before consulting or changing Lore,
   and before reconstructing a non-trivial repeated workflow when stored
   operational knowledge may materially reduce inference.
8. Read `.agents/protocol/IRIS.md` and perform its bounded startup inbox
   check at the beginning of each user-requested turn when the `iris` CLI is
   available. Follow its project-registration and host-owned worker boundaries.

Do not reload an unchanged document during the same task. Reload when its file
changes, the authorized objective changes, a new concern or stack becomes
active, or interrupted-session recovery makes the prior context unreliable.

## Concern Routing

- User collaboration and responses: `.agents/COMMUNICATION.md`
- Repository language and locale boundaries: `.agents/LANGUAGE.md`
- Request classification and authorization: `.agents/ROUTING.md`
- Work-state transitions and completion: `.agents/LIFECYCLE.md`
- Safety and scope boundaries: `.agents/INVARIANTS.md`
- Branches, commits, remotes, pushes, and pull requests:
  `.agents/VERSIONING.md`
- Playground layout, naming, and lifecycle: `.agents/PLAYGROUNDS.md`
- Worktree layout, naming, and lifecycle: `.agents/WORKTREES.md`
- Documentation and operational artifacts: `.agents/DOCUMENTING.md`
- Quiz and dump discovery artifacts: `.agents/DISCOVERY.md`
- Specifications and model companions: `.agents/SPECIFICATIONS.md`
- Repository development tickets: `.agents/TICKETS.md`
- Architecture and ownership: `.agents/ARCHITECTURE.md`
- Explicit design, bounds, invariants, and validation discipline:
  `.agents/ENGINEERING_DISCIPLINE.md`
- Code and stack conventions: `.agents/CONVENTIONS.md`
- Validation and quality gates: `.agents/LINTING.md`
- Formal delivery sets and slices: `.agents/SLICES.md`
- Persistent implementation reports: `.agents/REPORTING.md`
- Operational procedures: `.agents/PLAYBOOKS.md`
- Activity retrieval, recording, and reporting: `.agents/protocol/ACTIVITY.md`
- Operational knowledge retrieval and capture: `.agents/protocol/KNOWLEDGE.md`
- Cross-project agent communication and inbox checks: `.agents/protocol/IRIS.md`

Resolve these paths relative to the project root.

## Scope and Precedence

- Apply stack rules only to work in that stack.
- Repository-owned commands and validation requirements override generic stack
  defaults.
- Repository `AGENTS.md` files, when present, are more specific than these
  global instructions within their scope.
- Repository-local `.agents/ARCHITECTURE.md`, `.agents/CONVENTIONS.md`,
  `.agents/LINTING.md`, `.agents/PLAYBOOKS.md`, and `.agents/GUARDRAILS.md`
  refine the corresponding global defaults. Read the files relevant to the
  current task before acting.
