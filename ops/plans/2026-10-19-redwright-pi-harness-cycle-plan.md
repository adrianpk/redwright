# Cycle Plan: RedWright Pi Harness

Status: Approved
Approved: maintainer, 2026-10-19; explicit approval of the seven-slice plan, dependency/platform decisions and autonomous Pi-only commits, PRs and controller-owned Rebase + Fast-forward merges into dev.

## Metadata

- cycle_id: `2026-10-19-redwright-pi-harness`
- delivery_set: `pi-harness`
- status: `approved`
- approval: `maintainer approved, 2026-10-19`
- execution_authority: `autonomous execution of this delivery set approved`
- commit_push_pr_merge_authority: `Pi-only task commits, pushes, PRs and controller-owned merges to dev approved`
- created: `2026-10-19`
- goal: `Use prepared Pi or Codex profiles through Rails authoring and bounded ticket proposals while retaining host validation and workflow authority.`
- scope: `feature`
- active_slice: `Slice 5 - Selectable Pi authoring in the web app (reviewing)`
- active_task: `none (awaiting canonical Slice 5 integration)`
- merge_target: `dev`
- observed_base: `8d63f6fbe6fb67e0bd7ef26bbfb474735ae43cf1`

## Source Contracts

- [Specification](../specs/specs/2026-10-19-redwright-pi-harness-spec.md)
- [Model](../specs/specs/2026-10-19-redwright-pi-harness-spec-model.md)
- [CHR consultation](../conv/quiz/2026-10-19-redwright-pi-harness-quiz.md)
- [Tracker](../trackers/2026-10-19-redwright-pi-harness-cycle-tracker.md)
- [Repository slice contract](../../.agents/SLICES.md)
- [Repository validation contract](../../.agents/LINTING.md)

The maintainer approved this complete delivery contract and autonomous
execution on 2026-10-19. The specification and model are promoted together.
Authority covers only Pi; the held Settings/Setup work remains outside it.

## Approved Delivery Decisions

1. Implement both existing Rails authoring and the current ticket proposal
   step. The latter still returns proposed changes for Rails to apply and test.
2. Keep plain Ruby transport/adapters under `apps/web/app/services/harnesses/`.
   Existing feature services keep prompts, domain checks and file publication.
   Controllers delegate to services. No Go package layout or CHR scheduler is
   introduced.
3. Use sibling CodexAdapter and PiAdapter behind StructuredCall. Preserve
   authoring executable overrides and the current direct-API ticket default
   when no explicit profile is selected.
4. Use ProjectHarnessSetting and HarnessOperation as focused Active Record
   owners. Keep private named profile files outside the repository. Project
   protocol, document and ticket bodies retain their current file authority.
5. Place the authenticated selection UI at a compact project-scoped Harness
   settings resource. Offer independent `authoring` and `ticket_proposal`
   prepared-profile choices; both use the same mutation/admission services.
6. Target Pi 1.3.0, tool-free RPC generation and static credential resources.
   Verify provider/model selection. OAuth refresh and tool-using workers are
   separate capabilities and do not enter this delivery.
7. Implement OS read-only containment with an explicit Linux Bubblewrap policy.
   Pi readiness on macOS returns unsupported until a platform policy has its
   own proof. This does not change existing Codex platform behavior.
8. Add the approved `json_schemer` 2.5.0 in the Rails bundle for complete validation of
   host-owned schemas. Select Draft 2020-12 explicitly, disable remote reference
   resolution and data mutation/default insertion, and keep domain checks.
   This dependency was approved with the delivery plan.

### Containment Policy

Bubblewrap is a construction tool, not a pre-certified sandbox. The Rails
LinuxSandbox owner must define and test its policy. Build an empty mount
namespace with explicit read-only executable/runtime/CA/resolver dependency
mounts, a read-only selected workspace only when needed, private writable
scratch and private selected resource snapshots. Do not bind the whole host
root, home, runtime socket directories or Docker socket.

Use process/IPC isolation and an isolated terminal session, close inherited
file descriptors and retain owned lifetime/cancellation. Network access needed
by the selected model endpoint is explicit; do not claim network isolation
from the filesystem policy or Pi's offline/discovery flags. The model gets
no shell, write, MCP or inspection tool in this initial delivery.

Reject executable layouts, dependency mounts or capabilities that the prepared
profile cannot support safely. No fallback to an uncontained Pi process or a
weaker tool-only claim. Test the actual profile with successful scratch writes
and rejected workspace/outside writes before reporting containment ready.

### Bounds to Implement

| Boundary | Approved limit |
| --- | --- |
| Authoring deadline | Existing 180 seconds for the whole operation, including setup and cleanup. |
| Existing context | Preserve existing 128 KB caller context bounds; total encoded request at most 1 MiB. |
| Output schema | 64 KiB of host-owned schema; no external URI resolution. |
| Decoded final result | Existing 2 MiB maximum; existing stricter caller limits win. |
| One RPC record | 16 MiB, accommodating an escaped 2 MiB result plus its envelope. |
| Aggregate stdout / stderr | 64 MiB / 2 MiB per call; exceeding a ceiling fails. |
| Retained diagnostics | 256 KiB sanitized data per stream per call. |
| Active harness calls | Two shared across Codex/Pi per application database, enforced across processes. |
| Profile file / profile count | 64 KiB private regular file / 64 named profiles. |
| Retained binding | 16 KiB non-secret semantic binding, plus private resolved references. |
| Selection retry receipts | At most 128 per project, retained seven days; full unexpired capacity fails before mutation. |
| Operation retention | At most 1,024 per project; reclaim only unreferenced terminal operations older than 30 days. |
| Host attempts | Preserve current caller policy: no new authoring retries and the existing three-attempt ticket correction limit. |

Expiry never makes an old selection request apply again against a changed
revision. An expired receipt can return stale/expired instead of reconstructing
a former success. Active or uncertain operation references cannot be evicted
for capacity. Missing usage remains unknown; these byte/attempt limits do not
claim a certified token budget.

## Strategy and Ordering

Slice strategy: behavior-first.

Each slice preserves working Codex behavior and delivers a usable contract,
selection boundary, controlled transport or complete user action. The Pi
transport is not offered for production selection until containment is proven.
Execute one slice at a time in numeric order. Start the next only after the
prior canonical PR is reviewed, merged into dev and its tracker state closed.

Use one Conventional Commit per task and one PR per slice. Tickets below are
supporting slice records; plan and tracker remain the execution authority.

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

## Slice List

### Slice 1: Validated Codex structured calls

- status: `delivered`
- dependencies: approved and committed delivery artifacts; clean execution checkout
- branch: `fix/slice-1-pi-validated-codex`
- expected_pr_title: `feat(slice-1): validated codex structured calls`
- report: `ops/artifacts/slices/pi-harness/slice-1-validated-codex.md`
- ticket: [TKT-20261019165600](../tickets/solved/20261019165600-preserve-codex-authoring-through-validated-rails-calls.md)
- PR: [#10](https://forge.adrianpk.com/adrianpk/redwrigh/pulls/10)
- objective: All existing authoring operations keep working through one Rails structured-call service with full host schema validation and unchanged domain publication.
- acceptance_mapping: `PI-01, PI-03, PI-04, PI-05`

Tasks:

- [x] `T1.1` Introduce Harnesses request/result values, StructuredCall and host JSON-Schema validation; add the approved json_schemer 2.5.0 to the Rails bundle.
- [x] `T1.2` Extract a CodexAdapter and route Specifications, Slicing, Dumps and protocol references through it without changing their prompts, defaults, deadlines or file authority.
- [x] `T1.3` Cover real subprocess success/failure, nested schema rejection and preservation of existing artifacts/statuses.

Acceptance:

- Codex-only authoring and all four existing consumers work with Pi absent.
- Invalid JSON/schema/domain results and nonzero or timed-out subprocesses cannot publish an artifact.
- Existing executable overrides retain their Codex-compatible meaning; unsupported adapter names cannot fall through.

Planned validation from `apps/web`:

```sh
RAILS_ENV=test bundle exec rails test test/services/harnesses/structured_call_test.rb test/services/specifications/generator_test.rb test/services/specifications/feature_workflow_test.rb test/services/dumps/curation_test.rb test/services/project_protocols/documents_test.rb
RAILS_ENV=test bundle exec rails test
```

These are future commands, not reported results. New test paths are delivered
by this slice. Use an owned SQLite test database, never the preview database.
Check changed Ruby syntax and finish with `git diff --check`.

Planned task commits:

- `T1.1`: `feat(harnesses): validate structured call results in Rails`
- `T1.2`: `refactor(harnesses): route Codex authoring through one adapter`
- `T1.3`: `test(harnesses): protect Codex authoring contracts`

### Slice 2: Rails selection and retained operations

- status: `delivered`
- dependencies: Slice 1 integrated and closed
- branch: `fix/slice-2-pi-rails-harness-selection`
- expected_pr_title: `feat(slice-2): rails selection and retained operations`
- report: `ops/artifacts/slices/pi-harness/slice-2-rails-harness-selection.md`
- ticket: [TKT-20261019165601](../tickets/solved/20261019165601-persist-project-harness-selection-and-logical-operation-bindings.md)
- PR: [#11](https://forge.adrianpk.com/adrianpk/redwrigh/pulls/11)
- objective: One Active Record owner serializes each project's authoring/ticket-proposal defaults, while each logical operation keeps an immutable resolved binding.
- acceptance_mapping: `PI-02, PI-10, PI-11, PI-12`

Tasks:

- [x] `T2.1` Add ProjectHarnessSetting and HarnessOperation with original create-table migrations, constraints, data-preserving database preparation and private named-profile resolution.
- [x] `T2.2` Implement one Rails selection/admission service with optimistic revisions, bounded idempotency receipts and immutable bindings across nested calls/retries.
- [x] `T2.3` Verify separate-process selection races, stale requests, private projections, operation capacity and legacy defaults on owned SQLite fixtures.

Acceptance:

- Project selections use one Rails database authority rather than ProjectAttribute business context or a parallel workspace config.
- New requests see a complete settings revision without restart; existing operation bindings do not change.
- No running database or Factory files are reset, migrated or replaced during fixture validation.

Planned validation from `apps/web`:

```sh
RAILS_ENV=test bundle exec rails test test/models/project_harness_setting_test.rb test/services/harnesses/selection_test.rb test/services/harnesses/operation_test.rb test/services/specifications/database_rebuild_test.rb
RAILS_ENV=test bundle exec rails test
```

These are future commands, not reported results. New test paths are delivered
by this slice. Use an owned SQLite test database, never the preview database.
Check changed Ruby syntax and finish with `git diff --check`.

Planned task commits:

- `T2.1`: `feat(harnesses): persist project selections and operations`
- `T2.2`: `feat(harnesses): retain resolved operation bindings`
- `T2.3`: `test(harnesses): verify selection and admission concurrency`

### Slice 3: Bounded Pi RPC calls

- status: `delivered`
- dependencies: Slice 2 integrated and closed
- branch: `fix/slice-3-pi-pi-rpc`
- expected_pr_title: `feat(slice-3): bounded pi rpc calls`
- report: `ops/artifacts/slices/pi-harness/slice-3-pi-rpc.md`
- ticket: [TKT-20261019165603](../tickets/solved/20261019165603-add-a-bounded-pi-rpc-adapter-for-structured-generation.md)
- objective: A pinned Pi adapter handles correlated setup, settlement, final output and owned-process cleanup through the shared Rails call contract.
- acceptance_mapping: `PI-02, PI-05, PI-06, PI-07, PI-11, PI-12`

Tasks:

- [x] `T3.1` Implement shared owned-process supervision with concurrent pipe draining, deadlines, stream ceilings, sanitized diagnostics and deterministic reaping.
- [x] `T3.2` Implement PiAdapter for Pi 1.3.0 RPC, exact model/provider setup, ephemeral tool-free sessions and final settlement validation.
- [x] `T3.3` Exercise split/interleaved records, invalid UTF-8, early/late exits, provider failure, cancellation and encoded 2 MiB results through real pipe fixtures.

Acceptance:

- A prompt acknowledgment, agent_end, partial JSON or tool event alone is never accepted as a final result.
- The adapter rejects missing containment evidence until the next slice supplies it; existing Codex remains usable.
- Fixtures establish transport behavior without paid provider calls or a new background service.

Planned validation from `apps/web`:

```sh
RAILS_ENV=test bundle exec rails test test/services/harnesses/pi_transport_test.rb test/services/harnesses/process_supervisor_test.rb
RAILS_ENV=test bundle exec rails test
```

These are future commands, not reported results. New test paths are delivered
by this slice. Use an owned SQLite test database, never the preview database.
Check changed Ruby syntax and finish with `git diff --check`.

Planned task commits:

- `T3.1`: `feat(harnesses): supervise bounded subprocess calls`
- `T3.2`: `feat(harnesses): add the Pi structured call adapter`
- `T3.3`: `test(harnesses): cover Pi RPC lifecycle and limits`

### Slice 4: Linux containment and real Pi proof

- status: `delivered`
- dependencies: Slice 3 integrated and closed
- branch: `fix/slice-4-pi-pi-linux-containment`
- expected_pr_title: `feat(slice-4): linux containment and real pi proof`
- report: `ops/artifacts/slices/pi-harness/slice-4-pi-linux-containment.md`
- ticket: [TKT-20261019165604](../tickets/solved/20261019165604-contain-pi-authoring-on-linux-and-prove-the-real-binary-boundary.md)
- objective: Prepared Pi profiles can run tool-free calls inside an explicitly verified Linux Bubblewrap policy with isolated selected resources.
- acceptance_mapping: `PI-02, PI-06, PI-07, PI-08, PI-09, PI-11, PI-12, PI-14`

Tasks:

- [x] `T4.1` Implement LinuxSandbox command construction with read-only mount allowlists, private writable scratch, no inherited host IPC sockets/fds and explicit policy identity/readiness.
- [x] `T4.2` Isolate the selected static credential/model configuration, disable discovery and unattended UI, and expose precise platform/version/resource failures.
- [x] `T4.3` Run the pinned real Pi 1.3.0 against an owned loopback endpoint, proving write denial, resource exclusion, cleanup and valid structured output.

Acceptance:

- Only the declared scratch area is writable; workspace and outside sentinel write attempts fail at the OS boundary.
- No entire home, runtime socket directory or unrelated credentials are mounted; discovered resources cannot gain authority.
- The Linux proof is required on the delivery host. macOS remains explicitly unsupported for Pi until an equivalent policy is verified; Codex behavior is preserved.

Planned validation from `apps/web`:

```sh
RAILS_ENV=test bundle exec rails test test/services/harnesses/linux_sandbox_test.rb test/services/harnesses/pi_resources_test.rb
RAILS_ENV=test REDWRIGHT_PI_ACCEPTANCE=1 bundle exec rails test test/integration/pi_harness_acceptance_test.rb
RAILS_ENV=test bundle exec rails test
```

These are future commands, not reported results. New test paths are delivered
by this slice. Use an owned SQLite test database, never the preview database.
Check changed Ruby syntax and finish with `git diff --check`.

Planned task commits:

- `T4.1`: `feat(harnesses): contain Pi calls with Bubblewrap`
- `T4.2`: `feat(harnesses): isolate Pi resources and readiness`
- `T4.3`: `test(harnesses): prove real Pi containment and generation`

### Slice 5: Selectable Pi authoring in the web app

- status: `reviewing`
- dependencies: Slice 4 integrated and closed
- branch: `fix/slice-5-pi-pi-authoring-settings`
- expected_pr_title: `feat(slice-5): selectable pi authoring in the web app`
- report: `ops/artifacts/slices/pi-harness/slice-5-pi-authoring-settings.md`
- ticket: [TKT-20261019165605](../tickets/reviewing/20261019165605-expose-prepared-profiles-and-wire-pi-into-rails-authoring.md)
- objective: Users can inspect/change project harness defaults through a compact authenticated Rails page and use Pi for each existing authoring action.
- acceptance_mapping: `PI-02, PI-03, PI-04, PI-08, PI-10, PI-15`

Tasks:

- [x] `T5.1` Inject one retained authoring operation into Specs, slicing, Dumps and protocol references; preserve current revisions, semantic checks and atomic publication.
- [x] `T5.2` Add a project-scoped Harness settings resource with compact controls for prepared profiles, clear-to-default, active bindings and local readiness.
- [x] `T5.3` Verify authenticated and stale/conflicting changes, independent process visibility, responsive rendering and all four authoring consumer boundaries.

Acceptance:

- The UI uses the existing Rails visual language and selection service; it accepts profile keys rather than executable or credential paths.
- Changing defaults affects new calls only, including separate authoring and ticket-proposal choices.
- No refresh/restart, paid probe or provider installation is hidden in a settings mutation.

Planned validation from `apps/web`:

```sh
RAILS_ENV=test bundle exec rails test test/controllers/project_harness_settings_controller_test.rb test/services/harnesses/authoring_integration_test.rb test/controllers/documents_controller_test.rb test/controllers/project_protocols_controller_test.rb
RAILS_ENV=test bundle exec rails test
```

These are future commands, not reported results. New test paths are delivered
by this slice. Use an owned SQLite test database, never the preview database.
Check changed Ruby syntax and finish with `git diff --check`.

Planned task commits:

- `T5.1`: `feat(harnesses): use selected profiles for Rails authoring`
- `T5.2`: `feat(web): expose project harness selections`
- `T5.3`: `test(web): verify harness switching and authoring`

### Slice 6: Pi ticket proposals under Rails authority

- status: `pending`
- dependencies: Slice 5 integrated and closed
- branch: `fix/slice-6-pi-pi-ticket-proposals`
- expected_pr_title: `feat(slice-6): pi ticket proposals under rails authority`
- report: `ops/artifacts/slices/pi-harness/slice-6-pi-ticket-proposals.md`
- ticket: [TKT-20261019165606](../tickets/ready/20261019165606-use-pi-for-ticket-proposals-while-retaining-host-application-and-validation.md)
- objective: The existing ticket model step can use a selected structured harness while Rails continues to own context, application, validation and Git.
- acceptance_mapping: `PI-05, PI-07, PI-10, PI-11, PI-12, PI-13`

Tasks:

- [ ] `T6.1` Add an injected harness requester to the existing ticket model boundary, preserving the current direct-API default, context shaping and separate role selection.
- [ ] `T6.2` Retain the logical correction-loop binding and per-attempt base/schema/policy evidence; reconcile uncertain application/finalization before retrying effects.
- [ ] `T6.3` Verify valid/invalid proposals, changed-base conflicts, correction attempts, uncertain replay and failure of host validation without false ticket completion.

Acceptance:

- The model proposes data; OutputApplier, ValidationLoop, workspace checks and GitFinalizer retain their current authority.
- Schema-valid proposals still need domain/path/base-state checks; external changes cannot be overwritten blindly.
- No tool-using Pi worker, CHR scheduler, automatic forge publication authority or Codex proof replacement is introduced.

Planned validation from `apps/web`:

```sh
RAILS_ENV=test bundle exec rails test test/services/agent_ticket_execution test/services/harnesses/ticket_proposal_integration_test.rb
RAILS_ENV=test bundle exec rails test
```

These are future commands, not reported results. New test paths are delivered
by this slice. Use an owned SQLite test database, never the preview database.
Check changed Ruby syntax and finish with `git diff --check`.

Planned task commits:

- `T6.1`: `feat(harnesses): generate ticket proposals through selected profiles`
- `T6.2`: `feat(tickets): retain proposal bases and reconcile retries`
- `T6.3`: `test(tickets): protect Pi proposal application authority`

### Slice 7: Operator guidance and integrated acceptance

- status: `pending`
- dependencies: Slice 6 integrated and closed
- branch: `fix/slice-7-pi-pi-harness-acceptance`
- expected_pr_title: `feat(slice-7): operator guidance and integrated acceptance`
- report: `ops/artifacts/slices/pi-harness/slice-7-pi-harness-acceptance.md`
- ticket: [TKT-20261019165607](../tickets/ready/20261019165607-document-and-validate-the-integrated-pi-harness-workflow.md)
- objective: An operator can configure prepared Pi profiles, switch a project, understand failures and verify the integrated behavior with recorded evidence.
- acceptance_mapping: `PI-01 through PI-15`

Tasks:

- [ ] `T7.1` Update the existing User Guide/configuration reference with static-profile setup, effective selections, Linux containment, limits and truthful capability/usage evidence.
- [ ] `T7.2` Exercise a representative configured-project journey, cross-process switching/recovery, Codex-only compatibility and ticket validation using owned fixtures.
- [ ] `T7.3` Run the unchanged delivery-set gate on the exact integrated candidate and close the cycle report/tracker only with matching green evidence.

Acceptance:

- All PI acceptance requirements have an explicit delivered/unsupported evidence mapping and the selected real-binary proof passes.
- Full Rails regression and the existing root Ruby suite pass on the exact integrated candidate; no main promotion occurs.
- Application code, Settings/Setup work and preview services outside this delivery remain preserved.

Planned validation from `apps/web`:

```sh
RAILS_ENV=test bundle exec rails test test/integration/harness_workflow_test.rb
RAILS_ENV=test REDWRIGHT_PI_ACCEPTANCE=1 bundle exec rails test test/integration/pi_harness_acceptance_test.rb
RAILS_ENV=test bundle exec rails test
```

These are future commands, not reported results. New test paths are delivered
by this slice. Use an owned SQLite test database, never the preview database.
Check changed Ruby syntax and finish with `git diff --check`.

Planned task commits:

- `T7.1`: `docs(harnesses): explain selectable Pi and Codex workflows`
- `T7.2`: `test(harnesses): verify integrated selection and recovery`
- `T7.3`: `chore(ops): close the validated Pi harness delivery`

## Delivery-set Gate

Use this unchanged ordered gate for the exact integrated candidate:

1. From `apps/web`: `RAILS_ENV=test bundle exec rails test`.
2. From `apps/web`:
   `RAILS_ENV=test REDWRIGHT_PI_ACCEPTANCE=1 bundle exec rails test test/integration/pi_harness_acceptance_test.rb`.
3. From the repository root: `bundle exec rake test`.
4. From the repository root: `scripts/agent/tickets/check.sh` and `git diff --check`.

The full Rails suite before each slice merge is repository-required. The final
root Ruby suite protects the preserved direct-provider/runtime contracts.
Focused suites first localize failures; do not multiply every test across
every provider/model. The required real-Pi proof uses Pi 1.3.0, Bubblewrap,
owned files and a deterministic loopback endpoint. It starts no paid provider
request and must fail if those prerequisites are absent, rather than skip.

Expected cost is minutes on the prepared host; no timing baseline was measured
during documentation-only slicing. Measure the first required run and record
its actual cost. Do not silently expand timeouts, append historical gates or
weaken acceptance after controller startup.

No external provider credential or paid authentication proof is authorized by
this plan proposal. Record that boundary separately from binary/protocol,
filesystem and domain acceptance.

### Exact Controller Gate

The controller must pin this equivalent encoding of the ordered gate:

```sh
(cd apps/web && RAILS_ENV=test bundle exec rails test) && (cd apps/web && RAILS_ENV=test REDWRIGHT_PI_ACCEPTANCE=1 bundle exec rails test test/integration/pi_harness_acceptance_test.rb) && bundle exec rake test && scripts/agent/tickets/check.sh && git diff --check
```

## Isolation and Approved Startup

The main checkout and preview worktree contain unrelated uncommitted work.
Preserve both. A clean independent execution checkout from canonical origin
under the established worktree parent avoids mutating their branches, index,
files or preview service. Do not reset, stash or fast-forward the dirty checkout.

Approved startup sequence:

1. Verify canonical dev and its relationship to the observed base. Reconcile
   any changed base before starting; never force-push or overwrite user work.
2. Prepare the independent clean checkout from canonical dev. Transfer only
   the approved Pi specification/model/consultation, this plan/tracker, their
   seven tickets and Pi-only index edits. Do not copy the dirty Settings/Setup
   changes or whole edited index files containing them.
3. Commit and publish only those approved planning artifacts on dev. Record the
   commit through Acta. No runtime code is included in that preparation commit.
4. Confirm plan/tracker/task/table identity and all prerequisites. Pin a local
   Looper configuration outside the repository, using the exact gate and paths.
5. The approved autonomous authority is task commits, slice PRs, reviews and
   controller-owned Rebase + Fast-forward merges to dev for this set only.
   Max worker turns: 200; max stalled turns: 10. These are finite controller
   bounds, not a requested model token budget. Preserve them once started.
6. Start one controller, inspect its acknowledged ownership and report the
   selected run/view command. Continue sequentially until complete or an
   actual blocker requires a maintainer decision.
7. At closure, retain exact candidate/check evidence in
   `ops/artifacts/2026-10-19-redwright-pi-harness-cycle-report.md`.
   Do not advance main, mirror, tags, services or an existing database.

The earlier hold on committing pending Settings/Setup work remains in force.
The maintainer explicitly approved commits and integration for this Pi delivery.
That approval does not include the held Settings/Setup changes.

## Current Prerequisite Evidence

- Canonical dev matched the observed base during slicing.
- No RedWright Looper set was registered in either inspected checkout.
- The installed Pi executable reports 1.3.0.
- A read-only Bubblewrap namespace invocation of `true` succeeded. This proves
  primitive availability only, not the proposed policy or Pi containment.
- Docker's API was unavailable to this user; Docker is not a delivery dependency.
- No model call, dependency install, schema migration, service restart or
  implementation commit was performed to prepare these documents.

## Approval and Exit Criteria

The maintainer approved scope, Rails persistence, the dependency, Linux policy
and Pi-only autonomous integration. Prepare the controller after committing
and publishing the approved artifacts on dev.

The set is complete when all seven slice PRs are integrated, PI-01 through
PI-15 have truthful evidence, operator guidance is current and the exact
integrated candidate passes the fixed delivery gate. Unsupported platforms
remain explicit. Configuration presence, process exit or focused tests alone
cannot establish completion.

## Technical References

- [json_schemer 2.5.0](https://rubygems.org/gems/json_schemer/versions/2.5.0)
- [JSONSchemer configuration](https://github.com/davishmcclurg/json_schemer/blob/main/README.md)
- [Bubblewrap policy responsibilities](https://github.com/containers/bubblewrap/blob/main/README.md)
- [Pi 1.3.0 RPC](https://github.com/earendil-works/pi/blob/v1.3.0/packages/coding-agent/docs/rpc.md)
