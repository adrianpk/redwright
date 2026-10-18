# Versioning Rules

This document defines commit, branch, remote, and merge rules.

Before changing version-control state, verify the current branch, working tree,
canonical remote, relevant upstream refs, and active operational artifacts.

## Commit Format

Use Conventional Commits:

```text
<type>(<optional-scope>): <description>
```

Common types are `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `ci`,
`build`, and `perf`.

## Remote Policy

- `origin` is the canonical remote and receives active branches.
- When `mirror` exists, it is a publication remote and receives only `main`
  unless local instructions explicitly define another policy.
- Open and manage pull requests against the canonical forge, not the mirror.

## Branch Policy

- `main` is protected. Do not commit directly to it.
- `dev` is the mandatory trunk for planned and day-to-day delivery work.
- `main` is validated integration history, not the release boundary. It may
  contain unreleased work.
- Ad hoc fixes, maintenance, documentation, and unsliced implementation happen
  directly on `dev` unless the user requests branch-and-PR delivery.
- Create a short-lived branch only when the user explicitly requests one or an
  approved slicing plan and tracker record it.
- Do not infer branch or pull-request authorization from task size, code risk,
  validation scope, review value, or the fact that implementation changed.
- Formal slice branches use the exact name recorded in the plan and tracker.
- In repositories configured for nightly integration, only the scheduled
  nightly workflow advances `main` from an exact green `dev` commit.

## Pull Request Policy

- Feature, fix, maintenance, and slice pull requests target `dev` and require
  explicit authorization, directly or through an approved slicing plan and
  tracker.
- Do not open pull requests for ad hoc fixes, maintenance, documentation,
  tickets, or unsliced implementation unless the user requests one.
- Pull requests targeting `main` are not allowed during normal delivery.

## Nightly Main Integration

- At the start of the scheduled run, capture the exact `origin/dev` commit.
- Run the repository's complete long gate against that immutable commit.
- Advance `origin/main` to the validated commit only when the gate is green and
  the current `origin/main` is its ancestor.
- Advance `main` by fast-forward. Do not rebase, squash, create a merge commit,
  or produce another commit after validation.
- If the gate fails, the candidate changes, `main` diverges, or the push is not
  a fast-forward, do not change `main`.
- Record the gate result against the tested commit hash. The workflow does not
  need a Git tag to preserve that identity.
- The scheduled workflow never creates release tags or releases.
- Do not dispatch or emulate the scheduled integration workflow unless the user
  explicitly requests that action.

## Release Boundary

- A commit on `main` is not a release merely because it is on `main`.
- A release exists only when the maintainer explicitly approves a version and a
  corresponding version tag is created.
- Release artifacts, packages, downloads, and release deployments must build
  from the exact version tag, not from the moving `main` branch.
- A release tag must point to a commit on `main` with the required green
  exact-commit evidence and complete tag-bound metadata.
- `main-release`, `release`, explicit version requests, and explicit tagging
  requests invoke the versioned release workflow.

## Changelog Policy

- Treat `CHANGELOG.md` as reader-facing release notes, not as a commit log.
- Describe what users can now do and meaningful user-visible problems that
  were fixed.
- Use `changelog-normalize` whenever creating, finalizing, or substantially
  rewriting a changelog or release section.
- Write for the product's intended users in plain English. Assume no knowledge
  of repository internals, plans, slices, or commit history.
- Unless the repository has an established reader-facing structure, use a
  concise preamble, `## x.y.z - YYYY-MM-DD` release headings, and non-empty
  `Added`, `Changed`, and `Fixed` sections. Use `Deprecated`, `Removed`, or
  `Security` only when applicable.
- Describe concrete capabilities and observable behavior. Keep public commands,
  configuration names, modes, and artifacts when users need them to act.
- Omit implementation details, package names, tests, internal refactors,
  operational records, development topology, and minor maintenance.
- For projects that ship versioned product releases, keep one `## Unreleased`
  section above versioned releases.
- Update `Unreleased` in the same delivery change that makes a release-worthy
  capability or behavior visible. Do not defer normal changelog authorship to
  release preparation.
- Initialize `CHANGELOG.md` with the first release-worthy delivery when a
  versioned product does not have one.
- Do not add entries for incomplete internal layers. Add or revise one product
  outcome when the behavior becomes usable, and preserve unrelated pending
  entries from concurrent work.
- Apply the following rules only to an explicitly requested versioned release.
- Before a release, compare the selected release commit with the latest tag and
  ensure every
  release-worthy user-facing change is already represented in `Unreleased`.
- Update and validate the User Guide before finalizing the changelog.
- Propose the next SemVer with a rationale and wait for explicit maintainer
  approval before writing it into the changelog.
- Before selecting the final release commit, replace `Unreleased`
  on `dev` with `## x.y.z - YYYY-MM-DD`, preserve bracketed versions when the
  repository already uses comparison links, and create a new empty
  `## Unreleased` above the versioned release.
- Commit and push the final changelog to `dev`. Wait for the scheduled nightly
  workflow to validate that exact commit and advance `main` to it.
- Do not modify release notes directly on `main`; tag the exact integrated
  `main` commit.

## Integration and Release Policy

- Keep regular delivery linear through `dev`.
- Treat the configured full-gate result for the exact `dev` commit as
  authoritative. Use the scheduled nightly build for that gate.
- For a versioned release, follow `.agents/playbooks/main-release.md`.
- If an unintended pull request targets `main`, stop. Normal integration into
  `main` belongs to the scheduled nightly workflow.
- After `main` changes, push it to `mirror` when that remote exists and local
  policy requires publication.

## Workflow and Safety

- Prefer small, reviewable commits.
- Keep commit scope aligned with one active task or slice concern.
- Treat force pushes and published-history rewrites as destructive Git
  operations governed by `.agents/INVARIANTS.md`.
- Planning and tracker maintenance can be committed directly to `dev` when it
  does not include runtime implementation.
- Follow `.agents/LANGUAGE.md` for commit and pull-request language.
- Keep the working tree state explicit before declaring a delivery cycle
  complete.
