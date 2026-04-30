# Engineering Playbooks

Operational procedures for this repository.

## 1. Branching and PR Flow

1. Create a branch from `dev`.
2. For slice execution, use `fix/slice-<n>-<slug>`.
3. Never work on `main` directly.
4. Before opening a PR from `dev` to `main`, run `bundle exec rake pr:dev_to_main:gate`.
5. Merge into `main` only via PR.
6. If `pr:dev_to_main:gate` reports stale badge targets, commit the refreshed `README.md` and `badges/*` outputs before PR.
7. Avoid force push unless explicitly approved.
8. Exception: `ops/plans/*` and `ops/trackers/*` updates may be committed directly to `dev` (no slice PR required) when they only formalize planning/tracking state.

## 2. Slice Delivery

1. Evaluate single-slice vs multi-slice execution.
2. Define behavior-first slice boundaries.
3. Implement and validate per slice.
4. Integrate incrementally while keeping repository healthy.

## 3. Slice PR Title and Body

PR title format (required):
- `feat(slice-<n>): <short slice name>`

PR body format (required):

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

Ordering rules (required):
1. `Summary`: functional impact first, ordered from primary behavior change to secondary change.
2. `Changes`: group entries in this order: runtime/library code, tests, docs, ops artifacts.
3. `Validation`: list commands from most targeted to broadest.
4. Validation commands must be executable and include a brief outcome (`pass`/`fail`) when reported after execution.

## 4. Traceability Contract

For each slice, keep explicit correlation across artifacts:
- plan entry in `ops/plans/*-plan.md`
- tracker entry in `ops/trackers/*-tracker.md`
- branch name and PR title
- commit list that maps to slice tasks

When closing a slice, update tracker tasks, commits, and the validation checklist in the same cycle.

## 5. Blocker Handling

1. Capture failing command and exact error.
2. Attempt the least-invasive compliant alternative.
3. Report blocker and stop further risky changes.

## 6. Completion Checklist

1. Scope implemented.
2. Relevant checks run.
3. Tracker/plan status updated.
4. Final status reported with concrete outcomes.

## 7. Slice Execution Workflow (Mandatory)

1. Execute one slice at a time.
2. Implement slice tasks in order.
3. Create one conventional commit per task.
4. Open one PR per slice.
5. Do not open PRs per task or per commit.
6. Complete PR review using manual review and/or automated review tooling.
7. Integrate with fast-forward policy to `main` after approval.
8. Report implementation and validation status.
9. Start the next slice only after the previous one is fully closed.

## 8. Ticket Workflow for Small Fixes

Use tickets for small, bounded fixes where full plan/tracker formalization is unnecessary.

1. Create ticket files under `ops/tickets/`.
2. Use sortable filename format: `YYYYMMDDHHMMSS-<slug>.md` (UTC timestamp).
3. Use the frontmatter fields from `ops/tickets/TEMPLATE.md`.
4. Keep code and repository documentation in English.
5. Set `status: open` when reported; add `started_at` when implementation begins.
6. Link delivery artifacts in frontmatter (`branch`, `pr`, `commits`).
7. Set `status: closed` and `closed_at` only after validation is complete.
8. If scope expands beyond a small fix, promote the ticket to a formal plan/slice/tracker flow and reference that plan from the ticket.

## 9. Full Workflow (Plan-Driven)

Use this workflow for large features, architectural changes, or multi-slice workstreams.

1. Start from a long-form idea/ticket.
2. Create `ops/plans/*` and `ops/trackers/*` artifacts.
3. Define slices as behavior increments; define tasks inside each slice.
4. Implement tasks in order; create one Conventional Commit per task.
5. Open one PR per slice (not per task).
6. Complete review (manual and/or automated tooling such as Greptile).
7. Report slice completion using canonical status format: `Slice N of M completed`.
8. Start the next slice only after the previous slice is merged.
9. After the final slice, publish a canonical end-to-end cycle report summarizing all slices.

## 10. Reduced Workflow (Ticket-Driven)

Use this workflow for minor features, minor changes, bugs, and hotfixes.

1. Create ticket under `ops/tickets/`.
2. Create a branch from `dev`.
3. Implement the fix.
4. Open one PR for the ticket.
5. Complete review (manual and/or automated tooling such as Greptile).
6. Merge and close the ticket.

## 11. Dev-to-Main Release Alignment

Canonical release-alignment PR from `dev` to `main`:

1. Run `bundle exec rake pr:dev_to_main:gate`.
2. Open PR with title: `chore(release): align dev with main`.
3. Use this PR body format:

```md
## Summary

- align `main` with the latest merged state from `dev`
- include all previously reviewed and merged slice/ticket work

## Validation

- bundle exec rake pr:dev_to_main:gate (pass)
```

4. Merge `dev -> main` only through PR.
