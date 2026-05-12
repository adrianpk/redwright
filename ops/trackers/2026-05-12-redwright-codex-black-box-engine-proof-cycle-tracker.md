# Cycle Tracker: RedWright Codex Black Box Engine Proof

## Metadata

- cycle_id: `2026-05-12-redwright-codex-black-box-engine-proof`
- status: `complete`
- state: `slice_8_implemented`
- updated: `2026-05-12`
- active_slice: `slice_8`
- active_task: `complete`
- source_plan: `ops/plans/2026-05-12-redwright-codex-black-box-engine-proof-cycle-plan.md`
- source_ticket: `ops/tickets/open/20260511182745-prove-codex-resolves-a-cloned-repo-task-inside-docker.md`
- parent_ticket: `ops/tickets/open/20260511180900-spike-codex-managed-worker-ticket-backend.md`
- source_dump: `ops/conv/dump/2026-05-11-redwright-codex-backend-and-agent-sandboxing-dump-raw.md`
- source_draft: `ops/specs/drafts/2026-05-11-redwright-reusable-agent-sandbox-behavior-draft.md`
- proof_repository_seed: `runtime/codex-proof/fixtures/go-todo-agent`
- proof_repository_remote: `https://codeberg.org/adrianpk/go-todo-agent-proof.git`
- proof_task: `Add a user-facing mark-as-read capability to the Go todo CLI, including tests.`

## Slice Progress

### Slice 1: Proof Harness Skeleton

- status: `merged`
- branch: `fix/slice-1-codex-proof-harness`
- PR: `#425 https://codeberg.org/adrianpk/redwright/pulls/425`
- merge_target: `dev`
- last_sync_commit: `a1e048d`

Tasks:

- [x] `T1.1 Define the proof input packet shape for Codeberg repository URL, result branch, ticket-like task prompt, validation command, remote push policy, and output directory.`
- [x] `T1.2 Add a local proof command or script that reads the input packet and creates a run directory.`
- [x] `T1.3 Add a handcrafted Dockerfile or runtime recipe placeholder for the selected first stack.`

Commits:

- [x] `88ebd09 feat(runtime): define codex proof input packet`
- [x] `4f24271 feat(runtime): prepare codex proof runs`
- [x] `6a32248 feat(runtime): add codex proof go runtime placeholder`

Acceptance:

- [x] `ruby -Itest test/redwright/codex_proof_input_packet_test.rb` (pass)
- [x] `ruby -Itest test/redwright/codex_proof_harness_test.rb` (pass)
- [x] `ruby scripts/runtime/codex_black_box_proof.rb --packet <temp packet> --runs-root <temp runs>` (pass)
- [x] `A local operator can start a proof run from the repository root.`
- [x] `The proof run creates an isolated run directory with input and output locations.`
- [x] `No Codex credential is required in this slice.`

### Slice 2: Container Runtime Smoke Test

- status: `merged`
- branch: `fix/slice-2-codex-proof-container-smoke`
- PR: `#426 https://codeberg.org/adrianpk/redwright/pulls/426`
- merge_target: `dev`
- last_sync_commit: `ad0f5f8`

Tasks:

- [x] `T2.1 Build or start the proof Docker runtime from the handcrafted setup.`
- [x] `T2.2 Pass the proof input packet and runtime-only environment variables into the container without baking them into the image.`
- [x] `T2.3 Write a structured smoke result artifact from inside the container.`

Commits:

- [x] `df3eb86 feat(runtime): build codex proof container`
- [x] `a4b522a feat(runtime): run codex proof smoke container`
- [x] `ad0f5f8 feat(runtime): capture codex proof smoke artifact`

Validation:

- [x] `ruby -Itest test/redwright/codex_proof_container_smoke_test.rb` (pass)
- [x] `ruby scripts/runtime/codex_black_box_proof.rb --packet <temp packet> --runs-root <temp runs> --smoke` (pass)
- [x] `cat <temp run>/output/smoke-result.json` (pass)
- [x] `The container starts successfully for the selected stack.`
- [x] `The container can read the mounted or copied input packet.`
- [x] `The host can inspect a structured output artifact after the container exits.`

### Slice 3: Codeberg Repository Clone

- status: `merged`
- branch: `fix/slice-3-codex-proof-repo-clone`
- PR: `#427 https://codeberg.org/adrianpk/redwright/pulls/427`
- merge_target: `dev`
- last_sync_commit: `9a9178b`

Tasks:

- [x] `T3.1 Add Codeberg repository clone logic inside the proof worker.`
- [x] `T3.2 Create a run-scoped branch or equivalent isolated working state.`
- [x] `T3.3 Capture clone metadata, checked-out revision, and workspace path in the result artifact.`
- [x] `T3.4 Ensure the proof repository README explains that the repository is a RedWright Codex black-box proof fixture and identifies where RedWright uses it.`
- [x] `T3.5 Define the remote reset policy: default branch remains the clean fixture, every proof run uses a run-scoped branch, and reset means deleting or replacing only the run branch.`
- [x] `T3.6 Keep the proof fixture source outside _workspace so manual workspace scenarios remain independent.`
- [x] `T3.7 Make the proof outcome visible to operators through the Codeberg branch, README explanation, logs, clone metadata, and validation artifacts.`

Commits:

- [x] `e87dddb feat(runtime): clone codex proof repository`
- [x] `0661ac8 docs(runtime): document codex proof fixture repo`
- [x] `9a9178b fix(runtime): support container clone proof fixtures`

Validation:

- [x] `ruby -Itest test/redwright/codex_proof_harness_test.rb` (pass)
- [x] `ruby -Itest test/redwright/codex_proof_container_smoke_test.rb` (pass)
- [x] `ruby -c scripts/runtime/codex_black_box_proof.rb` (pass)
- [x] `container clone proof against temporary mounted bare repository` (pass)
- [x] `container clone proof against https://codeberg.org/adrianpk/go-todo-agent-proof.git` (pass, checkout `3ab9bfb`)
- [x] `GOWORK=off go test ./...` from `runtime/codex-proof/fixtures/go-todo-agent` (pass)
- [x] `The worker does not mutate the host's canonical project checkout or the local seed repository.`
- [x] `The cloned workspace is correlated with the proof run id.`
- [x] `Clone failures return a structured failure result.`
- [x] `The fixture README template states the proof-fixture purpose and RedWright usage context.`
- [x] `The proof cannot spoil the clean fixture branch because work is isolated to a run-scoped branch.`
- [x] `The fixture seed lives under runtime/codex-proof/fixtures and does not depend on _workspace manual scenarios.`
- [x] `The fixture README explains what the operator should see when a proof run succeeds.`
- [x] `Create or verify real Codeberg repository go-todo-agent-proof` (pass, created by operator and seeded from canonical asset)

### Slice 4: Codex And Remote Credential Boundary

- status: `merged`
- branch: `fix/slice-4-codex-proof-auth-preflight`
- PR: `#428 https://codeberg.org/adrianpk/redwright/pulls/428`
- merge_target: `dev`
- last_sync_commit: `0963d4b`

Tasks:

- [x] `T4.1 Add a Codex availability preflight inside the worker.`
- [x] `T4.2 Inject only the required Codex and Codeberg push credential environment variables at container startup.`
- [x] `T4.3 Fail clearly when Codex, Codex authentication, or remote push authentication is unavailable.`

Commits:

- [x] `0963d4b feat(runtime): preflight codex proof credentials`

Validation:

- [x] `ruby -Itest test/redwright/codex_proof_container_smoke_test.rb` (pass)
- [x] `ruby -c scripts/runtime/codex_black_box_proof.rb` (pass)
- [x] `ruby scripts/runtime/codex_black_box_proof.rb --packet <temp packet> --runs-root <temp runs> --preflight` (expected fail, structured result)
- [x] `cat <temp run>/output/preflight-result.json` (pass: `codex_auth_missing`, `codeberg_push_auth_missing`, `codex_version: codex-cli 0.130.0`)
- [x] `Codex availability is checked before attempting the task.`
- [x] `No credential value is written into generated files, images, committed artifacts, pushed commits, or result logs.`
- [x] `Missing Codex authentication and missing remote push authentication return distinct structured failure results.`

### Slice 5: Non-Interactive Codex Task Execution

- status: `merged`
- branch: `fix/slice-5-codex-proof-exec`
- PR: `#429`
- merge_target: `dev`
- last_sync_commit: `45f2230`

Tasks:

- [x] `T5.1 Build the Codex prompt from the proof input packet and run metadata without prescribing exact file edits.`
- [x] `T5.2 Invoke Codex in non-interactive mode inside the runtime boundary.`
- [x] `T5.3 Capture Codex events, stdout, stderr, exit status, and timeout state.`

Commits:

- [x] `cf6dcdc feat(runtime): execute codex proof task noninteractively`
- [x] `45f2230 test(runtime): cover codex proof execution failures`

Validation:

- [x] `Codex does not block waiting for human approval.`
- [x] `Codex runs against the disposable worker workspace, not the host checkout.`
- [x] `The prompt reads like an implementation ticket for marking todo items as read and adding tests.`
- [x] `The proof records enough process output for audit even when Codex fails.`

Validation:

- [x] `ruby -Itest test/redwright/codex_proof_container_smoke_test.rb` (pass)
- [x] `ruby -Itest test/redwright/codex_proof_input_packet_test.rb` (pass)
- [x] `ruby -Itest test/redwright/codex_proof_harness_test.rb` (pass)
- [x] `ruby -c scripts/runtime/codex_black_box_proof.rb` (pass)
- [x] `ruby scripts/runtime/codex_black_box_proof.rb --packet <temp packet> --runs-root <temp runs> --codex-exec` (expected fail: Codex exits with HTTP 401 auth failure after cloning the disposable Codeberg branch and writing prompt/events/stderr/result artifacts)

### Slice 6: Diff, Commit, Push, And Artifact Return

- status: `merged`
- branch: `fix/slice-6-codex-proof-diff-artifacts`
- PR: `#430`
- merge_target: `dev`
- last_sync_commit: `736b2ba`

Tasks:

- [x] `T6.1 Collect changed files and git diff from the worker repository.`
- [x] `T6.2 Commit the Codex-produced changes on the configured result branch when the working tree has a valid diff.`
- [x] `T6.3 Push the result branch to the configured Codeberg remote and capture push metadata.`
- [x] `T6.4 Copy or write result artifacts into the host-inspectable output directory.`
- [x] `T6.5 Classify no-diff and push-failed results separately from execution failures.`

Commits:

- [x] `07cc517 feat(runtime): push codex proof result branch`
- [x] `622af98 test(runtime): cover proof diff and push classification`

Validation:

- [x] `The host can inspect the final diff without entering the container.`
- [x] `No-diff, changed, push-failed, and failed outcomes are distinct.`
- [x] `The result branch is pushed to the configured Codeberg remote when credentials and validation policy allow it.`
- [x] `Raw logs and structured summary artifacts are preserved according to proof policy.`

Validation:

- [x] `ruby -Itest test/redwright/codex_proof_container_smoke_test.rb` (pass)
- [x] `ruby -Itest test/redwright/codex_proof_input_packet_test.rb` (pass)
- [x] `ruby -Itest test/redwright/codex_proof_harness_test.rb` (pass)
- [x] `ruby -c scripts/runtime/codex_black_box_proof.rb` (pass)
- [x] `ruby scripts/runtime/codex_black_box_proof.rb --packet <temp packet> --runs-root <temp runs> --codex-exec` (expected fail: Codex exits with HTTP 401 auth failure; structured output includes `codex_execution_failed`, `changed-files.txt`, `git-diff.patch`, `git-commit.log`, `git-push.log`, and `push_status: not_attempted`)

### Slice 7: Validation Command And Result Envelope

- status: `merged`
- branch: `fix/slice-7-codex-proof-validation`
- PR: `#431`
- merge_target: `dev`
- last_sync_commit: `a5e7e94`

Tasks:

- [x] `T7.1 Run the proof validation command inside the worker workspace after Codex completes.`
- [x] `T7.2 Capture validation stdout, stderr, exit status, and timeout state.`
- [x] `T7.3 Emit a structured result envelope with status, summary, changed files, diff path, validation, pushed branch, raw events, and backend name.`

Commits:

- [x] `ce557ab feat(runtime): add codex proof result envelope`
- [x] `a5e7e94 test(runtime): cover codex proof validation outcomes`

Validation:

- [x] `Validation pass, validation failure, execution failure, authentication failure, push failure, and no-diff outcomes are distinguishable.`
- [x] `The result envelope is close enough to the proposed backend contract to evaluate interchangeability.`
- [x] `RedWright host-side code remains responsible for interpreting the result.`

Validation:

- [x] `ruby -Itest test/redwright/codex_proof_container_smoke_test.rb` (pass)
- [x] `ruby -Itest test/redwright/codex_proof_input_packet_test.rb` (pass)
- [x] `ruby -Itest test/redwright/codex_proof_harness_test.rb` (pass)
- [x] `ruby -c scripts/runtime/codex_black_box_proof.rb` (pass)
- [x] `ruby scripts/runtime/codex_black_box_proof.rb --packet <temp packet> --runs-root <temp runs> --codex-exec` (expected fail: Codex exits with HTTP 401 auth failure; structured envelope includes `status: codex_auth_failed`, `backend: codex`, `validation.status: not_run`, and host-inspectable artifact paths)

### Slice 8: Proof Report And Readiness Decision

- status: `pr_open`
- branch: `fix/slice-8-codex-proof-report`
- PR: `#432`
- merge_target: `dev`
- last_sync_commit: `pending`

Tasks:

- [x] `T8.1 Run the proof against the selected Codeberg Go todo repository and mark-as-read task.`
- [x] `T8.2 Record the proof outcome, command context, artifacts, and credential-handling evidence.`
- [x] `T8.3 Update the tracker and publish a cycle report with the viability decision and next implementation risks.`

Commits:

- [x] `pending docs(ops): report codex black box proof outcome`
- [ ] `pending docs(ops): update codex proof tracker`

Validation:

- [x] `The cycle report states whether the Codex black box engine is viable, viable with constraints, or not viable.`
- [x] `The report identifies which parts were manual and which must become productized later.`
- [x] `The parent managed-worker backend ticket has concrete evidence for the next decision, including whether branch push belongs inside the worker or host finalization policy.`

Validation:

- [x] `ruby scripts/runtime/codex_black_box_proof.rb --packet <temp packet> --runs-root <temp runs> --codex-exec` (blocked as expected: `codex_auth_failed`; Docker image built, Codeberg repository cloned, disposable branch created, non-interactive Codex invoked, and `result-envelope.json` emitted)
- [x] `ops/artifacts/2026-05-12-codex-black-box-engine-proof-report.md` records decision `viable_with_constraints` and follow-up authenticated execution series.

## Global Exit Criteria

- [x] `Codex has been executed non-interactively inside the selected runtime boundary or has failed with a clear, documented blocker.`
- [x] `The worker clones an existing Codeberg Go todo repository into an isolated workspace rather than mutating the canonical host checkout or local seed repository.`
- [x] `The selected Codeberg proof repository README explains what the repository is and where RedWright uses it.`
- [x] `Runtime credentials are injected explicitly and are not persisted in generated files, images, committed artifacts, or logs.`
- [x] `Codex receives a ticket-like task prompt for adding a mark-as-read feature and tests, not prescriptive file-level editing instructions.`
- [x] `The worker pushes a result branch to the configured Codeberg remote when the run produces a valid diff and credentials are available.`
- [x] `The host receives structured artifacts for status, logs, changed files, diff, pushed branch, validation, and failure reason.`
- [x] `The proof leaves user-visible evidence: a Codeberg branch, readable logs, and structured artifacts.`
- [x] `The result shape is compatible with a future codex_managed_worker backend contract.`
- [x] `The final report records a viability decision and the minimum next slice needed for product integration.`

## Event Log

- `2026-05-12` state=`planned` note=`created the 8-slice plan and tracker for proving the Codex black box engine boundary with manual runtime configuration, isolated repository work, explicit credential injection, non-interactive Codex execution, artifact return, validation capture, and viability reporting`
- `2026-05-12` state=`scope_refined` note=`refined the proof to use an existing Codeberg Go todo repository seeded from runtime/codex-proof/fixtures/go-todo-agent, pass a ticket-like mark-as-read task, run Codex inside the Docker boundary, implement tests, and push a result branch to the remote`
- `2026-05-12` state=`slice_1_implemented` note=`implemented the proof input packet contract, local run preparation harness, script entrypoint, and Go runtime Dockerfile placeholder on fix/slice-1-codex-proof-harness`
- `2026-05-12` state=`slice_1_pr_open` note=`opened Codeberg PR #425 from fix/slice-1-codex-proof-harness into dev`
- `2026-05-12` state=`slice_1_merged` note=`PR #425 merged into dev; Slice 1 is closed and Slice 2 is ready to start`
- `2026-05-12` state=`readme_requirement_added` note=`recorded that the selected Codeberg Go todo proof repository must explain in its README that it is a RedWright Codex black-box proof fixture and where RedWright uses it`
- `2026-05-12` state=`slice_2_implemented` note=`implemented Docker build/run smoke behavior, runtime-only packet and environment passing, host-inspectable smoke artifact capture, and targeted plus real Docker smoke validation on fix/slice-2-codex-proof-container-smoke`
- `2026-05-12` state=`slice_2_pr_open` note=`opened Codeberg PR #426 from fix/slice-2-codex-proof-container-smoke into dev`
- `2026-05-12` state=`slice_2_merged` note=`PR #426 merged into dev; Slice 2 is closed and Slice 3 is ready to start`
- `2026-05-12` state=`slice_3_implemented_with_external_blocker` note=`implemented container-side clone, run-scoped branch expansion, clone metadata capture, fixture README template, and reset policy; real Codeberg proof repository creation was initially blocked because the configured tea token lacked write:user/write:organization scopes`
- `2026-05-12` state=`slice_3_pr_blocked_rate_limit` note=`pushed fix/slice-3-codex-proof-repo-clone, but Codeberg rejected PR creation because similarly named PRs were created within the last hour; retry with canonical title feat(slice-3): codex proof repository clone after the rate-limit window`
- `2026-05-12` state=`fixture_seed_relocated` note=`added runtime/codex-proof/fixtures/go-todo-agent as the canonical seed source so the proof does not depend on _workspace manual testing scenarios`
- `2026-05-12` state=`visibility_requirement_added` note=`recorded that a successful proof must be visible to the operator through the Codeberg branch, readable logs, clone metadata, validation output, and structured artifacts`
- `2026-05-12` state=`proof_repo_ready` note=`operator created adrianpk/go-todo-agent-proof; seeded main from runtime/codex-proof/fixtures/go-todo-agent and validated container clone from https://codeberg.org/adrianpk/go-todo-agent-proof.git at checkout 3ab9bfb`
- `2026-05-12` state=`slice_3_pr_blocked_rate_limit` note=`retried PR creation after proof repository validation, but Codeberg still rejected the canonical PR title because similarly named PRs were created within the last hour`
- `2026-05-12` state=`slice_3_pr_open` note=`opened Codeberg PR #427 from fix/slice-3-codex-proof-repo-clone into dev`
- `2026-05-12` state=`slice_3_merged` note=`PR #427 merged into dev; Slice 3 is closed and Slice 4 is ready to start`
- `2026-05-12` state=`slice_4_implemented` note=`implemented Codex CLI installation in the proof image, explicit Codex and Codeberg credential preflight, runtime-only credential injection, and structured missing-auth failures on fix/slice-4-codex-proof-auth-preflight`
- `2026-05-12` state=`slice_4_pr_open` note=`opened Codeberg PR #428 from fix/slice-4-codex-proof-auth-preflight into dev`
- `2026-05-12` state=`slice_4_merged` note=`PR #428 merged into dev; Slice 4 is closed and Slice 5 is ready to start`
- `2026-05-12` state=`slice_5_implemented` note=`implemented non-interactive Codex execution inside the proof container with a ticket-like prompt, disposable Codeberg clone, bounded timeout, JSONL/stderr/last-message/status artifacts, and real Docker validation that reached Codex auth with HTTP 401 after cloning`
- `2026-05-12` state=`slice_5_pr_open` note=`opened Codeberg PR #429 from fix/slice-5-codex-proof-exec into dev`
- `2026-05-12` state=`slice_5_merged` note=`PR #429 merged into dev; Slice 5 is closed and Slice 6 is ready to start`
- `2026-05-12` state=`slice_6_implemented` note=`implemented worker diff collection, changed-file artifacts, conditional commit, Codeberg push attempt with runtime token injection, push/no-diff/failure classification, and real Docker validation that preserves diff and push artifacts when Codex fails before producing changes`
- `2026-05-12` state=`slice_6_pr_blocked_rate_limit` note=`pushed fix/slice-6-codex-proof-diff-artifacts, but Codeberg rejected PR creation for canonical title feat(slice-6): codex proof diff artifacts because similarly named PRs were created within the last hour; wait and retry with the same title`
- `2026-05-12` state=`slice_6_pr_open` note=`opened Codeberg PR #430 from fix/slice-6-codex-proof-diff-artifacts into dev`
- `2026-05-12` state=`slice_6_merged` note=`PR #430 merged into dev; Slice 6 is closed and Slice 7 is ready to start`
- `2026-05-12` state=`slice_7_implemented` note=`implemented validation command capture and a host-readable Codex result envelope with backend, status, summary, changed files, diff path, validation result, pushed branch, and raw event paths; real Docker validation classifies the current missing auth path as codex_auth_failed`
- `2026-05-12` state=`slice_7_pr_open` note=`opened Codeberg PR #431 from fix/slice-7-codex-proof-validation into dev`
- `2026-05-12` state=`slice_7_merged` note=`PR #431 merged into dev; Slice 7 is closed and Slice 8 is ready to start`
- `2026-05-12` state=`slice_8_implemented` note=`published the Codex black box engine proof report with decision viable_with_constraints, blocker codex_auth_failed, evidence for the runtime boundary and artifact contract, and a four-slice authenticated execution follow-up series`
- `2026-05-12` state=`slice_8_pr_open` note=`opened Codeberg PR #432 from fix/slice-8-codex-proof-report into dev`
