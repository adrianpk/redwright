# Slice-Based Development Strategy

Use formal slices for non-trivial coordinated work. Slices form a defined,
maintainer-visible delivery loop. Small independent maintenance can use a
ticket or direct `dev` delivery.

This document owns slice definitions, strategy, planning gates, and
traceability. Use `.agents/playbooks/slice-delivery.md` for the execution
procedure.

## Definitions and Naming

- A delivery set is one approved plan with an ordered local slice map.
- A slice is the smallest meaningful, testable behavior increment or reviewable
  implementation layer.
- Slice labels use `Slice 1`, `Slice 2`, and so on.
- Every delivery set restarts at `Slice 1`.
- Task labels use `T1.1`, `T1.2`, `T2.1`, and so on.
- Completion reporting uses `Slice N of M completed`.
- Reports use the canonical location defined by `.agents/REPORTING.md`.
- Slice numbers are not repository-global, PR numbers, or continuations of a
  prior delivery set.

Do not use alphabetic or Roman-numeral slice and task labels.

## Planning Gate

Before implementing a formal slice, an approved, committed plan and tracker
must define:

- the delivery-set name and purpose;
- the selected slicing strategy and reason when it is not behavior-first;
- the full ordered slice list;
- the active slice number and short name;
- the exact branch name and expected PR title;
- the expected report path;
- task IDs and validation expectations;
- the delivery-set gate selected under `.agents/LINTING.md`, its affected
  contracts, and expected execution cost when significant;
- prerequisites that are already delivered or externally blocked.

If the plan and tracker disagree, correct them before creating a branch or
changing runtime code.

## Strategy Selection

- Prefer behavior-first vertical slices for user-visible or end-to-end
  increments that can remain independently valid.
- Prefer layered slices for substantial package work when contracts, tests,
  mappings, implementation, and integration are easier to review separately.
- State the selected strategy in the plan. Do not select it implicitly or
  switch strategies during implementation without updating and approving the
  plan.

### Layered Strategy

Layered slicing separates contracts, tests, mappings, behavior, and integration
into reviewable units. Use only the layers required by the work, normally in
this order:

1. Types and package contracts.
2. Function, method, and interface skeletons.
3. Behavior tests for the target logic.
4. Mapping and adapter-neutral glue.
5. Logic implementation.
6. Edge-case hardening and broader tests.
7. Package documentation and report closure.
8. Integration adjustments.

- Every layered slice must compile and pass its required checks.
- A preparatory or test-first slice must not commit intentionally failing tests.
- Use skipped assertions only when their reason is explicit and useful.
- Keep shared services and workflows adapter-neutral. Put adapter mappings in
  adapter-owned files or layers.
- Record `Slice strategy: layered` and the reason in the plan. Record
  `Slice strategy: behavior-first` and its reason when selecting vertical
  behavior increments for substantial package work.

## Slice Rules

Each slice must:

- deliver a meaningful behavior, contract, or reviewable layer;
- be testable and independently reviewable;
- keep the repository in a valid state;
- stay within its recorded task list;
- produce one durable implementation report;
- use one Conventional Commit per tracker task when practical;
- use one branch and one pull request targeting `dev`.

## Integration and Traceability

- Keep a one-to-one mapping between tracker tasks and commits when practical.
- Open one pull request per slice. Do not open one per task or commit.
- Keep each slice passing its recorded focused and slice-level checks.
- When the maintainer accepts integration risk, `dev` may temporarily contain
  a regression between slices in the same delivery set. Never promote the
  delivery set to `main` in that state.
- After the final slice is merged into `dev`, run the selected delivery-set gate
  for the exact candidate. `.agents/LINTING.md` owns selection, execution cost,
  and retry scope. This also applies when the set contains only one slice.
- If that validation fails and repository changes are required, create
  `fix/<delivery-slug>-validation` from the failing `dev`, apply only the
  integration corrections, run focused checks, and open one pull request
  targeting `dev`. Revalidate the correction under `.agents/LINTING.md` and the
  repository's required gate. Do not create the branch or pull request when
  validation passes or when no repository change is required.
- Close the delivery set only after its required gate reports the exact
  `dev` candidate green.
- After delivery-set closure, follow `.agents/VERSIONING.md` for `main`
  integration and any later release.

## Scope Control

- Do not derive slice numbers from PR numbers or another delivery set.
- Do not add a tuning or integration slice automatically. Record the need and
  update the approved plan first.

## Looper Controller

Apply the Looper approach only when an agent drives slice work directly with
maintainer steering. Within that workflow, `looper` can continue an approved
delivery set when autonomous execution is authorized.

When an established automation tool manages the delivery lifecycle, follow
that tool's workflow, ownership rules, and recovery mechanisms. Do not start an
additional Looper controller for the same delivery set.

Start with `looper --help` to learn its commands, preferred defaults, project
selection, live output, viewing, and recovery workflow.

Run it from the project's Git worktree. `looper status --json` inspects that
project, and `looper --watch` opens its existing persistent view. Use
`looper list --all --json` only for explicit discovery across projects.
Starting or resuming a controller still requires an approved delivery set and
the corresponding execution and merge authority.

## Pull Request Body Contract

Use this exact structure and heading order for a slice pull request:

```md
## Summary

<One concise paragraph describing the delivered slice outcome and its explicit
boundary.>

## Changes

- <one concrete delivered outcome>
- <one concrete delivered outcome>
- <one concrete delivered outcome>
- <documentation, validation evidence, or explicit deferred boundary>
- [Slice N report](<immutable-report-url>)

## Validation

- `<exact successful repository-required command>`
- `<exact focused validation command>`
- `git diff --check`
```

- Replace placeholders without changing headings, section order, or list
  structure.
- Keep `Summary` as prose.
- Keep only concrete delivered outcomes under `Changes`.
- Make the final `Changes` item the report link through the immutable commit
  that introduced it. Use the canonical report path from
  `.agents/REPORTING.md`, not a branch URL.
- List only commands that ran successfully under `Validation`. Keep
  repository-required commands in canonical order, followed by focused
  commands, with `git diff --check` last.
- Do not replace a command with descriptive prose.
- Obtain explicit user approval before deviating from this template.
