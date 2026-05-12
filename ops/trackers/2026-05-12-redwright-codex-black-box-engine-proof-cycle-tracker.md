# Cycle Tracker: RedWright Codex Black Box Engine Proof

## Metadata

- cycle_id: `2026-05-12-redwright-codex-black-box-engine-proof`
- status: `in_progress`
- state: `slice_1_merged`
- updated: `2026-05-12`
- active_slice: `none`
- active_task: `none`
- source_plan: `ops/plans/2026-05-12-redwright-codex-black-box-engine-proof-cycle-plan.md`
- source_ticket: `ops/tickets/open/20260511182745-prove-codex-resolves-a-cloned-repo-task-inside-docker.md`
- parent_ticket: `ops/tickets/open/20260511180900-spike-codex-managed-worker-ticket-backend.md`
- source_dump: `ops/conv/dump/2026-05-11-redwright-codex-backend-and-agent-sandboxing-dump-raw.md`
- source_draft: `ops/specs/drafts/2026-05-11-redwright-reusable-agent-sandbox-behavior-draft.md`
- proof_repository_seed: `_workspace/Projects/go-todo-agent`
- proof_repository_remote: `operator-supplied Codeberg repository URL`
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

Validation:

- [x] `ruby -Itest test/redwright/codex_proof_input_packet_test.rb` (pass)
- [x] `ruby -Itest test/redwright/codex_proof_harness_test.rb` (pass)
- [x] `ruby scripts/runtime/codex_black_box_proof.rb --packet <temp packet> --runs-root <temp runs>` (pass)
- [x] `A local operator can start a proof run from the repository root.`
- [x] `The proof run creates an isolated run directory with input and output locations.`
- [x] `No Codex credential is required in this slice.`

### Slice 2: Container Runtime Smoke Test

- status: `planned`
- branch: `fix/slice-2-codex-proof-container-smoke`
- PR: `pending`
- merge_target: `dev`
- last_sync_commit: `pending`

Tasks:

- [ ] `T2.1 Build or start the proof Docker runtime from the handcrafted setup.`
- [ ] `T2.2 Pass the proof input packet and runtime-only environment variables into the container without baking them into the image.`
- [ ] `T2.3 Write a structured smoke result artifact from inside the container.`

Commits:

- [ ] `pending feat(runtime): run codex proof container smoke test`
- [ ] `pending test(runtime): cover proof container artifact capture`

Validation:

- [ ] `The container starts successfully for the selected stack.`
- [ ] `The container can read the mounted or copied input packet.`
- [ ] `The host can inspect a structured output artifact after the container exits.`

### Slice 3: Codeberg Repository Clone

- status: `planned`
- branch: `fix/slice-3-codex-proof-repo-clone`
- PR: `pending`
- merge_target: `dev`
- last_sync_commit: `pending`

Tasks:

- [ ] `T3.1 Add Codeberg repository clone logic inside the proof worker.`
- [ ] `T3.2 Create a run-scoped branch or equivalent isolated working state.`
- [ ] `T3.3 Capture clone metadata, checked-out revision, and workspace path in the result artifact.`
- [ ] `T3.4 Ensure the proof repository README explains that the repository is a RedWright Codex black-box proof fixture and identifies where RedWright uses it.`

Commits:

- [ ] `pending feat(runtime): clone proof codeberg repository inside worker`
- [ ] `pending test(runtime): cover proof clone failure result`

Validation:

- [ ] `The worker does not mutate the host's canonical project checkout or the local seed repository.`
- [ ] `The cloned workspace is correlated with the proof run id.`
- [ ] `Clone failures return a structured failure result.`
- [ ] `The selected Codeberg repository has a README that states its proof-fixture purpose and RedWright usage context.`

### Slice 4: Codex And Remote Credential Boundary

- status: `planned`
- branch: `fix/slice-4-codex-proof-auth-preflight`
- PR: `pending`
- merge_target: `dev`
- last_sync_commit: `pending`

Tasks:

- [ ] `T4.1 Add a Codex availability preflight inside the worker.`
- [ ] `T4.2 Inject only the required Codex and Codeberg push credential environment variables at container startup.`
- [ ] `T4.3 Fail clearly when Codex, Codex authentication, or remote push authentication is unavailable.`

Commits:

- [ ] `pending feat(runtime): preflight codex proof credentials`
- [ ] `pending test(runtime): cover codex and remote auth failures`

Validation:

- [ ] `Codex availability is checked before attempting the task.`
- [ ] `No credential value is written into generated files, images, committed artifacts, pushed commits, or result logs.`
- [ ] `Missing Codex authentication and missing remote push authentication return distinct structured failure results.`

### Slice 5: Non-Interactive Codex Task Execution

- status: `planned`
- branch: `fix/slice-5-codex-proof-exec`
- PR: `pending`
- merge_target: `dev`
- last_sync_commit: `pending`

Tasks:

- [ ] `T5.1 Build the Codex prompt from the proof input packet and run metadata without prescribing exact file edits.`
- [ ] `T5.2 Invoke Codex in non-interactive mode inside the runtime boundary.`
- [ ] `T5.3 Capture Codex events, stdout, stderr, exit status, and timeout state.`

Commits:

- [ ] `pending feat(runtime): execute codex proof task noninteractively`
- [ ] `pending test(runtime): cover codex proof execution failures`

Validation:

- [ ] `Codex does not block waiting for human approval.`
- [ ] `Codex runs against the disposable worker workspace, not the host checkout.`
- [ ] `The prompt reads like an implementation ticket for marking todo items as read and adding tests.`
- [ ] `The proof records enough process output for audit even when Codex fails.`

### Slice 6: Diff, Commit, Push, And Artifact Return

- status: `planned`
- branch: `fix/slice-6-codex-proof-diff-artifacts`
- PR: `pending`
- merge_target: `dev`
- last_sync_commit: `pending`

Tasks:

- [ ] `T6.1 Collect changed files and git diff from the worker repository.`
- [ ] `T6.2 Commit the Codex-produced changes on the configured result branch when the working tree has a valid diff.`
- [ ] `T6.3 Push the result branch to the configured Codeberg remote and capture push metadata.`
- [ ] `T6.4 Copy or write result artifacts into the host-inspectable output directory.`
- [ ] `T6.5 Classify no-diff and push-failed results separately from execution failures.`

Commits:

- [ ] `pending feat(runtime): push codex proof result branch`
- [ ] `pending test(runtime): cover proof diff and push classification`

Validation:

- [ ] `The host can inspect the final diff without entering the container.`
- [ ] `No-diff, changed, push-failed, and failed outcomes are distinct.`
- [ ] `The result branch is pushed to the configured Codeberg remote when credentials and validation policy allow it.`
- [ ] `Raw logs and structured summary artifacts are preserved according to proof policy.`

### Slice 7: Validation Command And Result Envelope

- status: `planned`
- branch: `fix/slice-7-codex-proof-validation`
- PR: `pending`
- merge_target: `dev`
- last_sync_commit: `pending`

Tasks:

- [ ] `T7.1 Run the proof validation command inside the worker workspace after Codex completes.`
- [ ] `T7.2 Capture validation stdout, stderr, exit status, and timeout state.`
- [ ] `T7.3 Emit a structured result envelope with status, summary, changed files, diff path, validation, pushed branch, raw events, and backend name.`

Commits:

- [ ] `pending feat(runtime): add codex proof result envelope`
- [ ] `pending test(runtime): cover codex proof validation outcomes`

Validation:

- [ ] `Validation pass, validation failure, execution failure, authentication failure, push failure, and no-diff outcomes are distinguishable.`
- [ ] `The result envelope is close enough to the proposed backend contract to evaluate interchangeability.`
- [ ] `RedWright host-side code remains responsible for interpreting the result.`

### Slice 8: Proof Report And Readiness Decision

- status: `planned`
- branch: `fix/slice-8-codex-proof-report`
- PR: `pending`
- merge_target: `dev`
- last_sync_commit: `pending`

Tasks:

- [ ] `T8.1 Run the proof against the selected Codeberg Go todo repository and mark-as-read task.`
- [ ] `T8.2 Record the proof outcome, command context, artifacts, and credential-handling evidence.`
- [ ] `T8.3 Update the tracker and publish a cycle report with the viability decision and next implementation risks.`

Commits:

- [ ] `pending docs(ops): report codex black box proof outcome`
- [ ] `pending docs(ops): update codex proof tracker`

Validation:

- [ ] `The cycle report states whether the Codex black box engine is viable, viable with constraints, or not viable.`
- [ ] `The report identifies which parts were manual and which must become productized later.`
- [ ] `The parent managed-worker backend ticket has concrete evidence for the next decision, including whether branch push belongs inside the worker or host finalization policy.`

## Global Exit Criteria

- [ ] `Codex has been executed non-interactively inside the selected runtime boundary or has failed with a clear, documented blocker.`
- [ ] `The worker clones an existing Codeberg Go todo repository into an isolated workspace rather than mutating the canonical host checkout or local seed repository.`
- [ ] `The selected Codeberg proof repository README explains what the repository is and where RedWright uses it.`
- [ ] `Runtime credentials are injected explicitly and are not persisted in generated files, images, committed artifacts, or logs.`
- [ ] `Codex receives a ticket-like task prompt for adding a mark-as-read feature and tests, not prescriptive file-level editing instructions.`
- [ ] `The worker pushes a result branch to the configured Codeberg remote when the run produces a valid diff and credentials are available.`
- [ ] `The host receives structured artifacts for status, logs, changed files, diff, pushed branch, validation, and failure reason.`
- [ ] `The result shape is compatible with a future codex_managed_worker backend contract.`
- [ ] `The final report records a viability decision and the minimum next slice needed for product integration.`

## Event Log

- `2026-05-12` state=`planned` note=`created the 8-slice plan and tracker for proving the Codex black box engine boundary with manual runtime configuration, isolated repository work, explicit credential injection, non-interactive Codex execution, artifact return, validation capture, and viability reporting`
- `2026-05-12` state=`scope_refined` note=`refined the proof to use an existing Codeberg Go todo repository seeded from _workspace/Projects/go-todo-agent, pass a ticket-like mark-as-read task, run Codex inside the Docker boundary, implement tests, and push a result branch to the remote`
- `2026-05-12` state=`slice_1_implemented` note=`implemented the proof input packet contract, local run preparation harness, script entrypoint, and Go runtime Dockerfile placeholder on fix/slice-1-codex-proof-harness`
- `2026-05-12` state=`slice_1_pr_open` note=`opened Codeberg PR #425 from fix/slice-1-codex-proof-harness into dev`
- `2026-05-12` state=`slice_1_merged` note=`PR #425 merged into dev; Slice 1 is closed and Slice 2 is ready to start`
- `2026-05-12` state=`readme_requirement_added` note=`recorded that the selected Codeberg Go todo proof repository must explain in its README that it is a RedWright Codex black-box proof fixture and where RedWright uses it`
