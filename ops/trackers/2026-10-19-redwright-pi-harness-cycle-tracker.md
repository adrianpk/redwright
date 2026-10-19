# Cycle Tracker: RedWright Pi Harness

Status: Approved
Approved: maintainer, 2026-10-19; explicit approval of the seven-slice plan, dependency/platform decisions and autonomous Pi-only commits, PRs and controller-owned Rebase + Fast-forward merges into dev.

## Metadata

- cycle_id: `2026-10-19-redwright-pi-harness`
- delivery_set: `pi-harness`
- status: `approved`
- state: `reviewing`
- approval: `maintainer approved, 2026-10-19`
- execution_authority: `autonomous execution of this delivery set approved`
- updated: `2026-10-19`
- active_slice: `Slice 3 - Bounded Pi RPC calls (reviewing)`
- active_task: `none (awaiting canonical Slice 3 integration)`
- completed_slices: `2/7`
- completed_tasks: `9/21`
- controller: `external Looper controller`
- plan: [Pi Harness plan](../plans/2026-10-19-redwright-pi-harness-cycle-plan.md)
- spec: [Pi Harness specification](../specs/specs/2026-10-19-redwright-pi-harness-spec.md)
- model: [Pi Harness model](../specs/specs/2026-10-19-redwright-pi-harness-spec-model.md)

## Canonical Slice Map

| Slice | Name | Branch | Expected PR title | Report |
| --- | --- | --- | --- | --- |
| Slice 1 | Validated Codex structured calls | `fix/slice-1-pi-validated-codex` | `feat(slice-1): validated codex structured calls` | `ops/artifacts/slices/pi-harness/slice-1-validated-codex.md` |
| Slice 2 | Rails selection and retained operations | `fix/slice-2-pi-rails-harness-selection` | `feat(slice-2): rails selection and retained operations` | `ops/artifacts/slices/pi-harness/slice-2-rails-harness-selection.md` |
| Slice 3 | Bounded Pi RPC calls | `fix/slice-3-pi-pi-rpc` | `feat(slice-3): bounded pi rpc calls` | `ops/artifacts/slices/pi-harness/slice-3-pi-rpc.md` |
| Slice 4 | Linux containment and real Pi proof | `fix/slice-4-pi-pi-linux-containment` | `feat(slice-4): linux containment and real pi proof` | `ops/artifacts/slices/pi-harness/slice-4-pi-linux-containment.md` |
| Slice 5 | Selectable Pi authoring in the web app | `fix/slice-5-pi-pi-authoring-settings` | `feat(slice-5): selectable pi authoring in the web app` | `ops/artifacts/slices/pi-harness/slice-5-pi-authoring-settings.md` |
| Slice 6 | Pi ticket proposals under Rails authority | `fix/slice-6-pi-pi-ticket-proposals` | `feat(slice-6): pi ticket proposals under rails authority` | `ops/artifacts/slices/pi-harness/slice-6-pi-ticket-proposals.md` |
| Slice 7 | Operator guidance and integrated acceptance | `fix/slice-7-pi-pi-harness-acceptance` | `feat(slice-7): operator guidance and integrated acceptance` | `ops/artifacts/slices/pi-harness/slice-7-pi-harness-acceptance.md` |

## Slice Progress

### Slice 1: Validated Codex structured calls

- status: `delivered`
- branch: `fix/slice-1-pi-validated-codex`
- expected_pr_title: `feat(slice-1): validated codex structured calls`
- report: `ops/artifacts/slices/pi-harness/slice-1-validated-codex.md`
- ticket: [TKT-20261019165600](../tickets/solved/20261019165600-preserve-codex-authoring-through-validated-rails-calls.md)
- merge_target: `dev`
- PR: [#10](https://forge.adrianpk.com/adrianpk/redwrigh/pulls/10)
- last_sync_commit: `09de3682a9c7ab76d40fae3f0cec37ddcfd53d3e`

Tasks:

- [x] `T1.1` Introduce Harnesses request/result values, StructuredCall and host JSON-Schema validation; add the approved json_schemer 2.5.0 to the Rails bundle.
- [x] `T1.2` Extract a CodexAdapter and route Specifications, Slicing, Dumps and protocol references through it without changing their prompts, defaults, deadlines or file authority.
- [x] `T1.3` Cover real subprocess success/failure, nested schema rejection and preservation of existing artifacts/statuses.

Commits:

- `T1.1`: `6908a8c2d4032e92c3e2a28ee62ec20268632bf2` - host structured-call validation.
- `T1.2`: `89dac88b963a8912da2e8dfbd2fc87294d6501ad` - shared Codex adapter and consumer routing.
- `T1.3`: `1a4409c49d1298cd240f3753e4fceb9555c1a9eb` - real subprocess and artifact-preservation coverage; report introduction.

Validation:

- [x] Planned focused checks: 35 tests, 389 assertions; no failures, errors or skips.
- [x] Exact-head full Rails suite passed: 549 tests, 4,043 assertions at `09de3682a9c7ab76d40fae3f0cec37ddcfd53d3e`.
- [x] Changed Ruby syntax and `git diff --check` passed during task implementation.
- [x] Canonical PR #10 verified merged by the external controller.

### Slice 2: Rails selection and retained operations

- status: `delivered`
- branch: `fix/slice-2-pi-rails-harness-selection`
- expected_pr_title: `feat(slice-2): rails selection and retained operations`
- report: `ops/artifacts/slices/pi-harness/slice-2-rails-harness-selection.md`
- ticket: [TKT-20261019165601](../tickets/solved/20261019165601-persist-project-harness-selection-and-logical-operation-bindings.md)
- merge_target: `dev`
- PR: [#11](https://forge.adrianpk.com/adrianpk/redwrigh/pulls/11)
- last_sync_commit: `07b22440fc1ae520429382bf44cafaf135c871b5`

Tasks:

- [x] `T2.1` Add ProjectHarnessSetting and HarnessOperation with original create-table migrations, constraints, data-preserving database preparation and private named-profile resolution.
- [x] `T2.2` Implement one Rails selection/admission service with optimistic revisions, bounded idempotency receipts and immutable bindings across nested calls/retries.
- [x] `T2.3` Verify separate-process selection races, stale requests, private projections, operation capacity and legacy defaults on owned SQLite fixtures.

Commits:

- `T2.1`: `b3e172d4b129baf4d89bb3350ad5ef41854f2914` - constrained persistence, private profiles and database preservation.
- `T2.2`: `a84be2f7b18aed217de4b16210a42ee69b41f97c` - retained selections, bindings and owned call lifecycle.
- `T2.3`: `4e82dded7c0bc56674149f8082690492799fd396` - process races, capacity/retention, damaged-binding rejection and report introduction.

Validation:

- [x] Planned focused suite passed: 18 tests, 214 assertions; no failures, errors or skips.
- [x] Exact-head full Rails suite passed: 567 tests, 4,257 assertions at `07b22440fc1ae520429382bf44cafaf135c871b5`.
- [x] Changed Ruby syntax and `git diff --check` passed during task implementation.
- [x] Canonical PR #11 verified merged by the external controller.

### Slice 3: Bounded Pi RPC calls

- status: `reviewing`
- branch: `fix/slice-3-pi-pi-rpc`
- expected_pr_title: `feat(slice-3): bounded pi rpc calls`
- report: `ops/artifacts/slices/pi-harness/slice-3-pi-rpc.md`
- ticket: [TKT-20261019165603](../tickets/reviewing/20261019165603-add-a-bounded-pi-rpc-adapter-for-structured-generation.md)
- merge_target: `dev`
- PR: [#12](https://forge.adrianpk.com/adrianpk/redwrigh/pulls/12)
- last_sync_commit: `bdabeda2de5f4a38e03a2238d4ba1c399a54bae4`

Tasks:

- [x] `T3.1` Implement shared owned-process supervision with concurrent pipe draining, deadlines, stream ceilings, sanitized diagnostics and deterministic reaping.
- [x] `T3.2` Implement PiAdapter for Pi 1.3.0 RPC, exact model/provider setup, ephemeral tool-free sessions and final settlement validation.
- [x] `T3.3` Exercise split/interleaved records, invalid UTF-8, early/late exits, provider failure, cancellation and encoded 2 MiB results through real pipe fixtures.

Commits:

- `T3.1`: `5029674d2dbbd8139739c7c83f6aacc3670b6e9b` - shared bounded process supervision and Codex transport extraction.
- `T3.2`: `b15c5e8aadbda4849829d486f0e9d0f2b43f21df` - pinned Pi RPC setup and settlement validation.
- `T3.3`: `bdabeda2de5f4a38e03a2238d4ba1c399a54bae4` - real-pipe lifecycle and byte-limit coverage; report introduction.

Validation:

- [x] Planned focused suite passed: 16 tests, 308 assertions; no failures, errors or skips.
- [ ] Full Rails suite before canonical merge.
- [ ] Changed Ruby syntax and `git diff --check`.
- [x] Report complete and canonical PR #12 opened.
- [ ] Canonical PR verified merged by the external controller.

### Slice 4: Linux containment and real Pi proof

- status: `pending`
- branch: `fix/slice-4-pi-pi-linux-containment`
- expected_pr_title: `feat(slice-4): linux containment and real pi proof`
- report: `ops/artifacts/slices/pi-harness/slice-4-pi-linux-containment.md`
- ticket: [TKT-20261019165604](../tickets/ready/20261019165604-contain-pi-authoring-on-linux-and-prove-the-real-binary-boundary.md)
- merge_target: `dev`
- PR: `pending`
- last_sync_commit: `none`

Tasks:

- [ ] `T4.1` Implement LinuxSandbox command construction with read-only mount allowlists, private writable scratch, no inherited host IPC sockets/fds and explicit policy identity/readiness.
- [ ] `T4.2` Isolate the selected static credential/model configuration, disable discovery and unattended UI, and expose precise platform/version/resource failures.
- [ ] `T4.3` Run the pinned real Pi 1.3.0 against an owned loopback endpoint, proving write denial, resource exclusion, cleanup and valid structured output.

Commits: none.

Validation:

- [ ] Planned focused checks from the plan's corresponding slice.
- [ ] Pinned real Pi/Bubblewrap loopback acceptance.
- [ ] Full Rails suite before canonical merge.
- [ ] Changed Ruby syntax and `git diff --check`.
- [ ] Report reviewed and canonical PR verified merged.

### Slice 5: Selectable Pi authoring in the web app

- status: `pending`
- branch: `fix/slice-5-pi-pi-authoring-settings`
- expected_pr_title: `feat(slice-5): selectable pi authoring in the web app`
- report: `ops/artifacts/slices/pi-harness/slice-5-pi-authoring-settings.md`
- ticket: [TKT-20261019165605](../tickets/ready/20261019165605-expose-prepared-profiles-and-wire-pi-into-rails-authoring.md)
- merge_target: `dev`
- PR: `pending`
- last_sync_commit: `none`

Tasks:

- [ ] `T5.1` Inject one retained authoring operation into Specs, slicing, Dumps and protocol references; preserve current revisions, semantic checks and atomic publication.
- [ ] `T5.2` Add a project-scoped Harness settings resource with compact controls for prepared profiles, clear-to-default, active bindings and local readiness.
- [ ] `T5.3` Verify authenticated and stale/conflicting changes, independent process visibility, responsive rendering and all four authoring consumer boundaries.

Commits: none.

Validation:

- [ ] Planned focused checks from the plan's corresponding slice.
- [ ] Full Rails suite before canonical merge.
- [ ] Changed Ruby syntax and `git diff --check`.
- [ ] Report reviewed and canonical PR verified merged.

### Slice 6: Pi ticket proposals under Rails authority

- status: `pending`
- branch: `fix/slice-6-pi-pi-ticket-proposals`
- expected_pr_title: `feat(slice-6): pi ticket proposals under rails authority`
- report: `ops/artifacts/slices/pi-harness/slice-6-pi-ticket-proposals.md`
- ticket: [TKT-20261019165606](../tickets/ready/20261019165606-use-pi-for-ticket-proposals-while-retaining-host-application-and-validation.md)
- merge_target: `dev`
- PR: `pending`
- last_sync_commit: `none`

Tasks:

- [ ] `T6.1` Add an injected harness requester to the existing ticket model boundary, preserving the current direct-API default, context shaping and separate role selection.
- [ ] `T6.2` Retain the logical correction-loop binding and per-attempt base/schema/policy evidence; reconcile uncertain application/finalization before retrying effects.
- [ ] `T6.3` Verify valid/invalid proposals, changed-base conflicts, correction attempts, uncertain replay and failure of host validation without false ticket completion.

Commits: none.

Validation:

- [ ] Planned focused checks from the plan's corresponding slice.
- [ ] Full Rails suite before canonical merge.
- [ ] Changed Ruby syntax and `git diff --check`.
- [ ] Report reviewed and canonical PR verified merged.

### Slice 7: Operator guidance and integrated acceptance

- status: `pending`
- branch: `fix/slice-7-pi-pi-harness-acceptance`
- expected_pr_title: `feat(slice-7): operator guidance and integrated acceptance`
- report: `ops/artifacts/slices/pi-harness/slice-7-pi-harness-acceptance.md`
- ticket: [TKT-20261019165607](../tickets/ready/20261019165607-document-and-validate-the-integrated-pi-harness-workflow.md)
- merge_target: `dev`
- PR: `pending`
- last_sync_commit: `none`

Tasks:

- [ ] `T7.1` Update the existing User Guide/configuration reference with static-profile setup, effective selections, Linux containment, limits and truthful capability/usage evidence.
- [ ] `T7.2` Exercise a representative configured-project journey, cross-process switching/recovery, Codex-only compatibility and ticket validation using owned fixtures.
- [ ] `T7.3` Run the unchanged delivery-set gate on the exact integrated candidate and close the cycle report/tracker only with matching green evidence.

Commits: none.

Validation:

- [ ] Planned focused checks from the plan's corresponding slice.
- [ ] Pinned real Pi/Bubblewrap loopback acceptance.
- [ ] Full Rails suite before canonical merge.
- [ ] Changed Ruby syntax and `git diff --check`.
- [ ] Report reviewed and canonical PR verified merged.

## Delivery Gate and Closure

- [ ] All 7 slice integrations and all 21 task/commit mappings verified.
- [ ] Full Rails suite on the exact integrated candidate.
- [ ] Required real Pi 1.3.0/Bubblewrap loopback acceptance.
- [ ] Root `bundle exec rake test`.
- [ ] Ticket metadata and whitespace checks.
- [ ] PI-01 through PI-15 evidence mapping and operator guidance.
- [ ] Cycle report records actual checks, candidate and evidence boundaries.

## Approval / Blockers

The maintainer approved the plan, dependency and Pi-only autonomous commit,
push, PR and controller-merge authority on 2026-10-19. Slices 1 and 2 are delivered; Slice 3 is implemented in its dedicated worktree; the external controller owns
validation evidence and all merge mutations.

Before startup, prepare the independent clean execution checkout described in
the plan and publish only the approved Pi artifacts. Preserve the existing
Settings/Setup files, preview service and their withheld commit authority.

A paid provider smoke test and macOS Pi containment are not part of the initial
Linux acceptance. No result here claims either was verified.

## Planning Validation

- Passed: 12 document bodies rendered; only Kramdown's expected diagnostics for
  GitHub task markers were present. Ticket frontmatter was validated separately.
- Passed: 64 existing local links, 7 identical canonical slice rows, 21 matching
  tasks across plan/tracker/tickets and 7 unique open ticket identities.
- Passed: repository ticket metadata checks, whitespace/fence checks and
  private-path scan.
- The canonical table header was checked against the installed Looper source.
  No controller configuration was registered or started; approval is now recorded;
  committed artifacts remain a prerequisite for controller validation.
- Application and live-model tests were not run for this planning-only change.

## Event Log

- `2026-10-19` state=`planning`: user requested Pi harness slicing for subsequent autonomous delivery.
- `2026-10-19` state=`planning`: prepared 7 ordered slices and 21 tasks; all implementation remains pending.

- `2026-10-19` state=`idle`: maintainer approved the complete contract and autonomous Pi-only integration.

- `2026-10-19` state=`reviewing`: Slice 1 tasks implemented; focused validation passed (35 tests, 389 assertions). Canonical PR #10 is open; final clean-HEAD controller validation follows the PR-reference commit.

- `2026-10-19T17:27:34Z` state=`implementing`: verified PR #10 merged at its validated head; closed Slice 1 and activated Slice 2.

- `2026-10-19T17:40:52Z` state=`reviewing`: Slice 2 tasks implemented; focused validation passed (18 tests, 214 assertions). Canonical PR #11 is open; final clean-head controller validation follows the PR-reference commit.

- `2026-10-19T17:47:04Z` state=`implementing`: verified PR #11 merged at its validated head; closed Slice 2 and activated Slice 3.

- `2026-10-19T18:05:44Z` state=`reviewing`: Slice 3 tasks implemented; focused validation passed (16 tests, 308 assertions). Canonical PR #12 is open; final clean-head controller validation follows the PR-reference commit.
