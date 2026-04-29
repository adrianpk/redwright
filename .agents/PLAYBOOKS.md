# Engineering Playbooks

Operational procedures for this repository.

## 1. Branching and PR flow

1. Create a branch from `dev`.
2. For slice execution, use `fix/slice-<n>-<slug>`.
3. Never work on `main` directly.
4. Before opening a PR from `dev` to `main`, run `bundle exec rake pr:dev_to_main:gate`.
5. Merge into `main` only via PR.
6. If `pr:dev_to_main:gate` reports stale badge targets, commit the refreshed `README.md` and `badges/*` outputs before PR.
7. Avoid force push unless explicitly approved.
8. Exception: `ops/plans/*` and `ops/trackers/*` updates may be committed directly to `dev` (no slice PR required) when they only formalize planning/tracking state.

## 2. Slice delivery

1. Evaluate single-slice vs multi-slice execution.
2. Define behavior-first slice boundaries.
3. Implement and validate per slice.
4. Integrate incrementally while keeping repository healthy.

## 3. Slice PR title and body

PR title format:
- `slice <n>: <short slice name>`

Preferred PR body format:

```md
## Summary

- <functional increment 1>
- <functional increment 2>

## Changes

- <path/to/file>
  - <change detail>
- <path/to/other_file>
  - <change detail>

## Validation

- <command and result>
```

## 4. Traceability contract

For each slice, keep explicit correlation across artifacts:
- plan entry in `ops/plans/*-plan.md`
- tracker entry in `ops/trackers/*-tracker.md`
- branch name and PR title
- commit list that maps to slice tasks

When closing a slice, update tracker tasks, commits, and validation checklist in the same cycle.

## 5. Blocker handling

1. Capture failing command and exact error.
2. Attempt least-invasive compliant alternative.
3. Report blocker and stop further risky changes.

## 6. Completion checklist

1. Scope implemented.
2. Relevant checks run.
3. Tracker/plan status updated.
4. Final status reported with concrete outcomes.
