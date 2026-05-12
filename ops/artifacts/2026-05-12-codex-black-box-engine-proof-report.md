# Codex Black Box Engine Proof Report

## Metadata

- cycle_id: `2026-05-12-redwright-codex-black-box-engine-proof`
- date: `2026-05-12`
- status: `complete`
- decision: `viable_with_constraints`
- blocker: `codex_auth_failed`
- backend: `codex`
- proof_repository: `https://codeberg.org/adrianpk/go-todo-agent-proof.git`
- fixture_seed: `runtime/codex-proof/fixtures/go-todo-agent`
- plan: `ops/plans/2026-05-12-redwright-codex-black-box-engine-proof-cycle-plan.md`
- tracker: `ops/trackers/2026-05-12-redwright-codex-black-box-engine-proof-cycle-tracker.md`

## Decision

The Codex black box engine boundary is viable with constraints.

This cycle built and exercised the reusable foundation for a replaceable worker engine: input packet preparation, Docker runtime boundary, isolated Codeberg clone, explicit runtime credential injection, non-interactive Codex invocation, output artifacts, diff and push paths, validation capture, and a host-readable result envelope.

The cycle did not prove that Codex can complete the mark-as-read ticket end-to-end. The final proof run reached Codex inside the container and failed with API `401 Unauthorized`. That is a clear blocker for successful ticket execution, not a failure of the worker boundary or artifact contract.

## Final Proof Run

- command: `ruby scripts/runtime/codex_black_box_proof.rb --packet <temp packet> --runs-root <temp runs> --codex-exec`
- run_id: `codex-proof-20260512192808-37ed6417`
- repository_url: `https://codeberg.org/adrianpk/go-todo-agent-proof.git`
- result_branch: `redwright/codex-proof/codex-proof-20260512192808-37ed6417`
- task_prompt: `Add a mark-as-read feature to the Go todo CLI so a user can mark an existing todo item as read, and cover the behavior with automated tests.`
- validation_command: `go test ./...`
- image_name: `redwright-codex-proof-go:local`
- codex_cli_source: `@openai/codex@0.130.0`

## Result Envelope

```json
{
  "schema_version": 1,
  "backend": "codex",
  "status": "codex_auth_failed",
  "summary": {
    "has_diff": false,
    "changed_file_count": 0,
    "push_status": "not_attempted",
    "validation_status": "not_run"
  },
  "result_branch": "redwright/codex-proof/codex-proof-20260512192808-37ed6417",
  "commit_sha": "",
  "pushed_branch": null,
  "changed_files": [],
  "diff_path": "/redwright/output/git-diff.patch",
  "validation": {
    "status": "not_run",
    "command": "go test ./...",
    "exit_status": null,
    "timed_out": false,
    "stdout_path": "/redwright/output/validation-stdout.log",
    "stderr_path": "/redwright/output/validation-stderr.log"
  },
  "raw_events_path": "/redwright/output/codex-events.jsonl",
  "stderr_path": "/redwright/output/codex-stderr.log",
  "execution_result_path": "/redwright/output/codex-execution-result.json"
}
```

## Evidence

- The Docker proof image built successfully.
- The worker cloned `https://codeberg.org/adrianpk/go-todo-agent-proof.git` inside `/redwright/workspace/repo`.
- The worker created the disposable branch `redwright/codex-proof/codex-proof-20260512192808-37ed6417`.
- Codex was invoked non-interactively with `codex exec --json --color never --sandbox workspace-write`.
- The prompt was ticket-like and did not prescribe exact file edits.
- `codex-stderr.log` recorded repeated `401 Unauthorized` responses from `wss://api.openai.com/v1/responses`.
- The run wrote host-inspectable artifacts:
  - `codex-prompt.txt`
  - `codex-events.jsonl`
  - `codex-stderr.log`
  - `codex-execution-result.json`
  - `result-envelope.json`
  - `changed-files.txt`
  - `git-diff.patch`
  - `git-commit.log`
  - `git-push.log`
  - `validation-stdout.log`
  - `validation-stderr.log`
  - `post-codex-status.txt`

## Credential Handling

- Codex and Codeberg credentials are injected at runtime through explicit environment variables.
- The proof image does not bake API keys or Codeberg tokens.
- Generated prompt, envelope, diff, and logs do not include credential values.
- The final run had no usable Codex credential path and correctly classified the result as `codex_auth_failed`.
- The push path was not attempted because Codex failed before producing a diff.

## Manual Parts

- Selecting and seeding the Codeberg proof repository.
- Providing runtime credential environment variables.
- Choosing Docker image, Codex CLI version, and proof command.
- Running the proof script manually.
- Inspecting and interpreting output artifacts.

## Productization Work

- Persist backend configuration for engine type, image, Codex version, credentials, and timeouts.
- Add host-side credential preflight before attempting Codex execution.
- Add a managed worker lifecycle for run directory creation and cleanup.
- Add a host-side interpreter for `result-envelope.json`.
- Decide whether branch push remains inside the worker or moves to host finalization.
- Connect result statuses to ticket lifecycle transitions.

## Branch Push Policy Finding

The proof supports worker-side push structurally, but did not exercise it end-to-end because Codex auth failed before producing a diff.

Recommended next policy: keep worker-side push available for proof mode, but prefer host-owned finalization for production so RedWright can enforce validation, branch naming, retry, audit, and cleanup policy before remote mutation.

## Follow-Up Series

The next series should be shorter because the foundation now exists. Proposed focus:

1. Authenticated runtime readiness.
2. Successful mark-as-read ticket execution.
3. Remote result finalization.
4. End-to-end evidence report.

## Exit Criteria

- `Codex executed non-interactively inside the selected runtime boundary or failed with a clear blocker`: met with `codex_auth_failed`.
- `Worker clones an existing Codeberg Go todo repository into an isolated workspace`: met.
- `Proof repository README explains what it is and where RedWright uses it`: met.
- `Runtime credentials are injected explicitly and not persisted`: met.
- `Codex receives a ticket-like mark-as-read task prompt`: met.
- `Worker pushes a result branch when a valid diff and credentials are available`: structurally implemented; not exercised because Codex auth failed before diff.
- `Host receives structured artifacts for status, logs, changed files, diff, pushed branch, validation, and failure reason`: met.
- `Final report records a viability decision and the minimum next slice needed for product integration`: met.
