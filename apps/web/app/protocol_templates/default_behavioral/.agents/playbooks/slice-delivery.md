# Slice Delivery

Use this playbook only for formal delivery work authorized under
`.agents/ROUTING.md`. `.agents/SLICES.md` owns slice definitions, policy, entry
conditions, naming, strategy, and integration invariants.

## Creation Gate

Verify every planning prerequisite in `.agents/SLICES.md`. Stop before branch
creation or runtime changes when the gate is not satisfied.

## Workflow

1. Verify current `dev`, `origin/dev`, working tree, plan, tracker, and relevant
   pull-request state.
2. Create the recorded branch from current `dev`.
3. Implement only the active slice tasks in order.
4. Use one Conventional Commit per tracker task when practical.
5. Use `changelog-normalize` to update `CHANGELOG.md` `Unreleased` when the
   slice completes a release-worthy user-visible outcome. Omit incomplete
   internal layers.
6. Run focused checks and the smallest relevant slice regression gate recorded
   in the plan. Do not run the full repository suite for each slice unless
   repository-specific rules require it.
7. Update tracker tasks, commits, and validation results.
8. Create the report required by `.agents/playbooks/slice-reporting.md`.
9. Set the report to `reviewing` and prepare the pull-request body from the
   contract in `.agents/SLICES.md`.
10. Open one pull request targeting `dev` with the exact title recorded in the
    plan and tracker.
11. Complete review and wait for the maintainer-controlled merge.
12. After merge confirmation, return to `dev`, verify the merge, and close the
    report and tracker.
13. If the same approved delivery set has a next slice, activate and execute it
    without requesting another confirmation.
14. After the final slice is merged into `dev`, execute the delivery-set
    validation and correction route defined by `.agents/SLICES.md`.
15. Close the delivery set only when the exit conditions in
    `.agents/SLICES.md` and `.agents/LIFECYCLE.md` are satisfied.

Use `.agents/LIFECYCLE.md` for blockers and completion. Use
`.agents/VERSIONING.md` for branch, pull-request, nightly integration, and
release policy.
