# Worktree Layout

This document defines the canonical location, naming, and lifecycle of project
worktrees on this machine.

## Canonical Layout

- Keep the primary checkout at `~/Projects/<project>/` on `dev` for integration,
  application builds, and normal execution.
- Use `main` in the primary checkout only during an explicitly authorized
  promotion or release operation.
- Create task worktrees only under `~/Projects/worktrees/<project>/`.
- Keep project test and playground material under
  `~/Projects/playground/<project>/`; it is not a worktree location.

## Directory Names

Name each new worktree directory:

```text
YYYYMMDD-HHMM-<task-slug>
```

- Use the machine's local time at worktree creation in 24-hour format.
- Use a lowercase kebab-case task slug that identifies the branch, slice, fix,
  review, or other bounded task.
- Treat the timestamp as creation metadata. Do not rename an active worktree to
  refresh it.
- If the same project, minute, and task slug collide, append `-2`, `-3`, and so
  on.
- Keep Git branch names independent from worktree directory names; the branch
  does not need the timestamp.

Examples:

```text
~/Projects/worktrees/odra/20260911-0915-open-dir
~/Projects/worktrees/odra/20260910-2105-slice-7-jan-document-fidelity
```

## Lifecycle

- Perform task implementation, slicing, reviews, and experiments in their
  named worktrees.
- Integrate completed work into `dev` in the primary checkout.
- Do not modify the primary checkout while its application build is running.
- Preserve per-worktree build directories; do not share a mutable build
  directory between concurrent branches.
- Apply this naming rule to new worktrees. Do not move, rename, or remove an
  existing worktree without explicit authorization.
