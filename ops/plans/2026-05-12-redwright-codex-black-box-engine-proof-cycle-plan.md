# Cycle Plan: RedWright Codex Black Box Engine Proof

## Metadata

- cycle_id: `2026-05-12-redwright-codex-black-box-engine-proof`
- status: `complete`
- owner: `adrianpk`
- created: `2026-05-12`
- updated: `2026-05-12`
- goal: `Prove that a manually configured Codex-based black box engine can receive a bounded ticket-like task packet, operate inside a Docker-controlled runtime, clone an existing Codeberg Go todo repository, implement a mark-as-read feature with tests, push a result branch to the remote, and return enough structured output for RedWright to evaluate the run.`
- scope: `runtime/research`
- source_ticket: `ops/tickets/open/20260511182745-prove-codex-resolves-a-cloned-repo-task-inside-docker.md`
- parent_ticket: `ops/tickets/open/20260511180900-spike-codex-managed-worker-ticket-backend.md`
- source_dump: `ops/conv/dump/2026-05-11-redwright-codex-backend-and-agent-sandboxing-dump-raw.md`
- source_draft: `ops/specs/drafts/2026-05-11-redwright-reusable-agent-sandbox-behavior-draft.md`
- proof_repository_seed: `runtime/codex-proof/fixtures/go-todo-agent`
- proof_repository_remote: `https://codeberg.org/adrianpk/go-todo-agent-proof.git`
- proof_task: `Add a user-facing mark-as-read capability to the Go todo CLI, including tests.`

## Delivery Strategy

This cycle is intentionally limited to the first concrete proof of the Codex-based black box engine boundary. Manual runtime choices are allowed when they reduce uncertainty faster than building final automation.

The cycle must prove the boundary, not the final product integration:

- the host starts the proof
- the runtime receives explicit inputs
- credentials are injected only at runtime
- the worker clones an existing Codeberg repository into an isolated workspace
- Codex runs non-interactively inside the selected runtime boundary
- Codex receives a ticket-like task description, not step-by-step file editing instructions
- the worker creates a result branch and pushes it to the configured Codeberg remote
- result artifacts are inspectable from the host
- RedWright-owned code can classify the result without trusting Codex as a domain authority

Execution must follow the slice delivery protocol:

- execute one slice at a time
- use one branch per slice
- target `dev`
- keep one conventional commit per tracker task during implementation
- update the tracker with validation outcomes
- do not merge later slices before earlier dependencies are closed

## Slice List

### Slice 1: Proof Harness Skeleton

- status: `merged`
- branch: `fix/slice-1-codex-proof-harness`
- PR: `#425 https://codeberg.org/adrianpk/redwright/pulls/425`
- objective: `Create the smallest host-side proof entrypoint and fixture layout without invoking Codex yet.`
- tasks:
- [ ] `T1.1 Define the proof input packet shape for Codeberg repository URL, result branch, ticket-like task prompt, validation command, remote push policy, and output directory.`
- [ ] `T1.2 Add a local proof command or script that reads the input packet and creates a run directory.`
- [ ] `T1.3 Add a handcrafted Dockerfile or runtime recipe placeholder for the selected first stack.`
- acceptance:
- `A local operator can start a proof run from the repository root.`
- `The proof run creates an isolated run directory with input and output locations.`
- `No Codex credential is required in this slice.`
- planned_commits:
- `feat(runtime): define codex proof input packet`
- `feat(runtime): prepare codex proof runs`
- `feat(runtime): add codex proof go runtime placeholder`

### Slice 2: Container Runtime Smoke Test

- status: `merged`
- branch: `fix/slice-2-codex-proof-container-smoke`
- PR: `#426 https://codeberg.org/adrianpk/redwright/pulls/426`
- objective: `Prove that the handcrafted runtime can start, receive explicit input, and write host-inspectable output.`
- tasks:
- [ ] `T2.1 Build or start the proof Docker runtime from the handcrafted setup.`
- [ ] `T2.2 Pass the proof input packet and runtime-only environment variables into the container without baking them into the image.`
- [ ] `T2.3 Write a structured smoke result artifact from inside the container.`
- acceptance:
- `The container starts successfully for the selected stack.`
- `The container can read the mounted or copied input packet.`
- `The host can inspect a structured output artifact after the container exits.`
- planned_commits:
- `feat(runtime): build codex proof container`
- `feat(runtime): run codex proof smoke container`
- `feat(runtime): capture codex proof smoke artifact`

### Slice 3: Codeberg Repository Clone

- status: `merged`
- branch: `fix/slice-3-codex-proof-repo-clone`
- PR: `#427 https://codeberg.org/adrianpk/redwright/pulls/427`
- objective: `Make the worker clone the existing Codeberg Go todo repository into its own disposable workspace inside the run boundary.`
- tasks:
- [ ] `T3.1 Add Codeberg repository clone logic inside the proof worker.`
- [ ] `T3.2 Create a run-scoped branch or equivalent isolated working state.`
- [ ] `T3.3 Capture clone metadata, checked-out revision, and workspace path in the result artifact.`
- [ ] `T3.4 Ensure the proof repository README explains that the repository is a RedWright Codex black-box proof fixture and identifies where RedWright uses it.`
- [ ] `T3.5 Define the remote reset policy: default branch remains the clean fixture, every proof run uses a run-scoped branch, and reset means deleting or replacing only the run branch.`
- [ ] `T3.6 Keep the proof fixture source outside _workspace so manual workspace scenarios remain independent.`
- [ ] `T3.7 Make the proof outcome visible to operators through the Codeberg branch, README explanation, logs, clone metadata, and validation artifacts.`
- acceptance:
- `The worker does not mutate the host's canonical project checkout or the local seed repository.`
- `The cloned workspace is correlated with the proof run id.`
- `Clone failures return a structured failure result.`
- `The selected Codeberg repository has a README that states its proof-fixture purpose and RedWright usage context.`
- `The proof cannot spoil the clean fixture branch because work is isolated to a run-scoped branch.`
- `The fixture seed lives under runtime/codex-proof/fixtures and does not depend on _workspace manual scenarios.`
- `The fixture README explains what the operator should see when a proof run succeeds.`
- planned_commits:
- `feat(runtime): clone codex proof repository`
- `fix(runtime): support container clone proof fixtures`
- `docs(runtime): document codex proof fixture repo`

### Slice 4: Codex And Remote Credential Boundary

- status: `merged`
- branch: `fix/slice-4-codex-proof-auth-preflight`
- PR: `#428 https://codeberg.org/adrianpk/redwright/pulls/428`
- objective: `Verify Codex can be invoked inside the runtime and that Codex plus Codeberg push credentials are supplied only through explicit runtime injection.`
- tasks:
- [ ] `T4.1 Add a Codex availability preflight inside the worker.`
- [ ] `T4.2 Inject only the required Codex and Codeberg push credential environment variables at container startup.`
- [ ] `T4.3 Fail clearly when Codex, Codex authentication, or remote push authentication is unavailable.`
- acceptance:
- `Codex availability is checked before attempting the task.`
- `No credential value is written into generated files, images, committed artifacts, pushed commits, or result logs.`
- `Missing Codex authentication and missing remote push authentication return distinct structured failure results.`
- planned_commits:
- `feat(runtime): preflight codex proof credentials`

### Slice 5: Non-Interactive Codex Task Execution

- status: `pr_open`
- branch: `fix/slice-5-codex-proof-exec`
- objective: `Run Codex non-interactively against the cloned workspace with a bounded ticket-like task prompt for the mark-as-read feature.`
- tasks:
- [x] `T5.1 Build the Codex prompt from the proof input packet and run metadata without prescribing exact file edits.`
- [x] `T5.2 Invoke Codex in non-interactive mode inside the runtime boundary.`
- [x] `T5.3 Capture Codex events, stdout, stderr, exit status, and timeout state.`
- acceptance:
- `Codex does not block waiting for human approval.`
- `Codex runs against the disposable worker workspace, not the host checkout.`
- `The prompt reads like an implementation ticket for marking todo items as read and adding tests.`
- `The proof records enough process output for audit even when Codex fails.`
- planned_commits:
- `feat(runtime): execute codex proof task noninteractively`
- `test(runtime): cover codex proof execution failures`

### Slice 6: Diff, Commit, Push, And Artifact Return

- status: `merged`
- branch: `fix/slice-6-codex-proof-diff-artifacts`
- objective: `Return changed files, git diff, logs, push metadata, and raw worker artifacts to the host.`
- tasks:
- [x] `T6.1 Collect changed files and git diff from the worker repository.`
- [x] `T6.2 Commit the Codex-produced changes on the configured result branch when the working tree has a valid diff.`
- [x] `T6.3 Push the result branch to the configured Codeberg remote and capture push metadata.`
- [x] `T6.4 Copy or write result artifacts into the host-inspectable output directory.`
- [x] `T6.5 Classify no-diff and push-failed results separately from execution failures.`
- acceptance:
- `The host can inspect the final diff without entering the container.`
- `No-diff, changed, push-failed, and failed outcomes are distinct.`
- `The result branch is pushed to the configured Codeberg remote when credentials and validation policy allow it.`
- `Raw logs and structured summary artifacts are preserved according to proof policy.`
- planned_commits:
- `feat(runtime): push codex proof result branch`
- `test(runtime): cover proof diff and push classification`

### Slice 7: Validation Command And Result Envelope

- status: `implemented`
- branch: `fix/slice-7-codex-proof-validation`
- objective: `Run the declared validation command and produce the common result envelope needed by RedWright orchestration.`
- tasks:
- [x] `T7.1 Run the proof validation command inside the worker workspace after Codex completes.`
- [x] `T7.2 Capture validation stdout, stderr, exit status, and timeout state.`
- [x] `T7.3 Emit a structured result envelope with status, summary, changed files, diff path, validation, pushed branch, raw events, and backend name.`
- acceptance:
- `Validation pass, validation failure, execution failure, authentication failure, push failure, and no-diff outcomes are distinguishable.`
- `The result envelope is close enough to the proposed backend contract to evaluate interchangeability.`
- `RedWright host-side code remains responsible for interpreting the result.`
- planned_commits:
- `feat(runtime): add codex proof result envelope`
- `test(runtime): cover codex proof validation outcomes`

### Slice 8: Proof Report And Readiness Decision

- status: `implemented`
- branch: `fix/slice-8-codex-proof-report`
- objective: `Close the proof with documented evidence, limitations, and the decision on whether the Codex black box engine boundary is viable.`
- tasks:
- [x] `T8.1 Run the proof against the selected Codeberg Go todo repository and mark-as-read task.`
- [x] `T8.2 Record the proof outcome, command context, artifacts, and credential-handling evidence.`
- [x] `T8.3 Update the tracker and publish a cycle report with the viability decision and next implementation risks.`
- acceptance:
- `The cycle report states whether the Codex black box engine is viable, viable with constraints, or not viable.`
- `The report identifies which parts were manual and which must become productized later.`
- `The parent managed-worker backend ticket has concrete evidence for the next decision, including whether branch push belongs inside the worker or host finalization policy.`
- planned_commits:
- `docs(ops): report codex black box proof outcome`
- `docs(ops): update codex proof tracker`

## Global Exit Criteria

- Codex has been executed non-interactively inside the selected runtime boundary or has failed with a clear, documented blocker.
- The worker clones an existing Codeberg Go todo repository into an isolated workspace rather than mutating the canonical host checkout or local seed repository.
- The selected Codeberg proof repository README explains what the repository is and where RedWright uses it.
- Runtime credentials are injected explicitly and are not persisted in generated files, images, committed artifacts, or logs.
- Codex receives a ticket-like task prompt for adding a mark-as-read feature and tests, not prescriptive file-level editing instructions.
- The worker pushes a result branch to the configured Codeberg remote when the run produces a valid diff and credentials are available.
- The host receives structured artifacts for status, logs, changed files, diff, pushed branch, validation, and failure reason.
- The proof leaves user-visible evidence: a Codeberg branch, readable logs, and structured artifacts.
- The result shape is compatible with a future `codex_managed_worker` backend contract.
- The final report records a viability decision and the minimum next slice needed for product integration.

## Validation Command Context

- Repository root commands should be run from `/home/adrian/Projects/redwright/redwright`.
- Rails targeted tests must be run from `apps/web` with `bundle exec bin/rails test <paths>`.
- Ruby targeted tests must be run from repository root with `ruby -Itest <paths>`.
- Docker proof commands must report whether they require local Docker access and which environment variables are passed.
- Validation entries must be reported as command plus `(pass)`, `(fail)`, or `(blocked)`.

## Non-Goals

- Do not implement automatic `.rw/agent` runtime inference in this cycle.
- Do not wire the proof into kanban movement.
- Do not open pull requests automatically from the worker.
- Do not push to the default branch.
- Do not package the native RedWright engine as a managed worker in this cycle.
- Do not treat Docker as complete security isolation.
- Do not add broad secret inheritance into the worker environment.
