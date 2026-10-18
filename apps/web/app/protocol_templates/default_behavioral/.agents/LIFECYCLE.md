# Delivery Lifecycle Contract

This document defines work-state transitions, completion, and blocked-state
handling.

## Work Phases

1. Alignment
2. Planning when requested
3. Implementation after approval
4. Validation
5. Versioning and push within the authorized workflow
6. Report and handoff

Use `.agents/ROUTING.md` to determine whether a request authorizes planning or
implementation. Use `.agents/VERSIONING.md` and applicable playbooks for
versioning and publication procedures.

## State Alignment

- For a status question, confusion, or state challenge, verify and report state
  without changing files, branches, tickets, trackers, or pull requests.
- Before starting or continuing a defined workflow, verify its required branch,
  remote, operational artifacts, and review or merge state.
- Continue in the same turn after routine verification succeeds.
- Stop for a mismatch, destructive action, missing authority, material user
  decision, or blocker.
- After a reported merge, verify it and close the delivered work on `dev`.
  Follow `.agents/SLICES.md` when another slice remains in the same delivery
  set.

## Interrupted Session Recovery

When the user reports a lost session, restart, or unexpected machine or
application failure:

1. Treat the report as state recovery, not automatic authorization to modify
   workspace or external state.
2. Query the latest bounded Acta events for the relevant scope before
   interpreting prior progress.
3. Verify the necessary live state: working tree, branch and upstream, active
   plans, trackers, reports, pull-request state, and relevant running
   processes.
4. Report the recovered checkpoint and uncommitted state before resuming
   workflow mutations under the current routing authorization.

## Exit Gates

A work unit is complete only when:

- the requested scope is implemented;
- relevant checks and exact failures are reported;
- `CHANGELOG.md` `Unreleased` content reflects any complete release-worthy
  user behavior delivered by the work unit when the project ships versioned
  releases;
- versioned artifacts reflect the actual state;
- the working tree and branch state are explicit;
- remaining risks and external prerequisites are recorded.

After completing the requested scope, report the outcome and stop unless the
same authorized workflow defines another unit.

## Blocked State

When blocked:

- capture the failing command and concise error context;
- exhaust safe in-scope alternatives;
- record the blocker in the active tracker or ticket when one exists;
- stop before speculative, destructive, or out-of-scope changes.

Store lifecycle artifacts in the locations defined by
`.agents/DOCUMENTING.md` and `.agents/REPORTING.md`.
