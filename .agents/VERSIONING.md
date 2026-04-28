# Versioning Rules

This document defines commit, branch, and merge rules.

## Commit format

Use Conventional Commits:
- `<type>(<optional-scope>): <description>`
- common types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `ci`, `build`, `perf`

Examples:
- `feat(core): add project state persistence`
- `fix(cli): handle missing argument error`
- `chore(ops): close slice-2 tracker status`

## Remote policy

- Repository hosting is Codeberg.
- `origin` is the canonical remote for the project workflow.
- Open and manage pull requests against the Codeberg repository.

## Branch policy

- `main` is protected; no direct commits.
- Day-to-day work happens on `dev` or short-lived branches.
- Merge to `main` only via pull request.
- Slice branches should use: `fix/slice-<n>-<short-slug>`.

## Workflow policy

- Prefer small, reviewable commits.
- Keep history linear where practical.
- Avoid history rewrites unless explicitly approved.
- Keep commit scope aligned with one active slice/task concern.
- `ops/plans/*` and `ops/trackers/*` maintenance commits are allowed directly on `dev` when they do not include runtime code changes.

## Git safety

- Never run destructive operations without explicit approval.
- Keep working tree clean before declaring a delivery cycle complete.
