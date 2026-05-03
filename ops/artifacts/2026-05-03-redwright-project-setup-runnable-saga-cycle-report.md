# Cycle Report: RedWright Project Setup Runnable Saga

## Metadata

- cycle_id: `cycle-2026-05-03-redwright-project-setup-runnable-saga`
- status: `reviewing`
- date: `2026-05-03`
- source_plan: `ops/plans/2026-05-03-redwright-project-setup-runnable-saga-cycle-plan.md`
- source_tracker: `ops/trackers/2026-05-03-redwright-project-setup-runnable-saga-cycle-tracker.md`
- source_spec: `ops/specs/specs/2026-05-03-redwright-project-setup-runnable-saga-spec.md`

## Summary

This cycle made project setup an explicit Rails-backed saga from Telegram entry through local workspace materialization.

The setup flow now collects semantic context, persists questionnaire and materialization state, records planned or scaffolded outcomes, creates board handoff tickets, and reports the final state back to Telegram with materialization, runnable, and validation status.

## Delivered Slices

### Slice 1: Setup LLM Traces and Semantic Slot Normalization

- branch: `fix/slice-1-setup-llm-traces-and-slot-normalization`
- PR: `https://codeberg.org/adrianpk/redwright/pulls/263`
- status: `merged`

Delivered behavior:

- Setup prompt rendering emits traceable LLM request and response events when trace mode is enabled.
- Slot answers are normalized through semantic JSON output with deterministic fallback.
- Raw answers and canonical slot values are preserved separately.
- Prompt-confusion text no longer becomes framework, language, libraries, or stack context.
- Go CLI answers are normalized into coherent setup slots.

### Slice 2: Explicit Setup Saga State and Query Surface

- branch: `fix/slice-2-project-setup-saga-state`
- PR: `https://codeberg.org/adrianpk/redwright/pulls/264`
- status: `merged`

Delivered behavior:

- Setup sessions persist explicit questionnaire, materialization, initial implementation, and ticket operation stages.
- Rails command/query responses expose setup saga state.
- Telegram `/project where` reports setup stage, materialization state, workspace, and handoff state.
- Completion replay preserves idempotent saga state instead of duplicating Rails records.

### Slice 3: Materialization Outcome and Planned Fallback

- branch: `fix/slice-3-project-setup-materialization-outcome`
- PR: `https://codeberg.org/adrianpk/redwright/pulls/265`
- status: `merged`

Delivered behavior:

- Local setup completion writes explicit materialization, initial implementation, validation, and linked ticket metadata into the workspace manifest.
- Planned fallback workspaces include README and `.redwright/setup-notes.md`.
- Unsupported setup contexts produce `materialized_planned` outcomes with reasons instead of ambiguous success.
- A starter implementation ticket is always reconciled for the post-setup handoff.

### Slice 4: Go CLI Initial Implementation Scaffold

- branch: `fix/slice-4-go-cli-initial-scaffold`
- PR: `https://codeberg.org/adrianpk/redwright/pulls/266`
- status: `merged`

Delivered behavior:

- Go CLI setup context selects a deterministic `go_cli` scaffold profile.
- Local workspaces for Go CLI projects include `go.mod`, `main.go`, and `main_test.go`.
- Optional `github.com/urfave/cli/v2` dependency metadata is recorded when requested.
- Local validation records `go test ./...` as `passed`, `failed`, or `skipped` with reason.
- Rails workspace metadata and saga state expose scaffold files, validation, runnable state, and initial implementation status.

### Slice 5: Telegram and Rails End-to-End Closure

- branch: `fix/slice-5-runnable-setup-e2e-closure`
- PR: `pending`
- status: `reviewing`

Delivered behavior:

- Telegram E2E coverage now exercises Go CLI setup from `/project new` through scaffolded workspace completion.
- Telegram E2E coverage also asserts unsupported setup fallback remains planned, non-runnable, and free of scaffold files.
- Completion messages distinguish materialization, initial implementation, runnable, and validation status.
- `/project where` includes validation status when available.
- The cycle has full Rails and repository coverage validation.

## Validation

- `ruby -wc lib/redwright/project_setup_prompt_renderer.rb && ruby -wc lib/redwright/telegram_project_setup_adapter.rb && ruby -wc apps/web/app/services/project_setup/local_workspace_materializer.rb` (pass)
- `cd apps/web && bundle exec bin/rails test test/integration/project_setup_telegram_e2e_test.rb test/services/project_setup/context_loop_service_test.rb test/controllers/api/v1/command_queries_controller_test.rb` (pass)
- `ruby -Itest test/redwright/project_setup_prompt_renderer_test.rb test/redwright/telegram_project_setup_adapter_test.rb` (pass)
- `cd apps/web && bundle exec bin/rails test` (pass)
- `bundle exec rake test:coverage` (pass, coverage 91.46)

## Coverage

- baseline_coverage: `91.39`
- final_coverage: `91.46`
- result: `increased`

## Residual Risks

- Go CLI validation depends on the local Go toolchain. When the toolchain is missing, incompatible, or external dependencies would require network resolution, validation is recorded as `skipped` rather than blocking setup.
- The generated Go scaffold is intentionally minimal. Domain-specific implementation still belongs in board tickets after setup.
- Remote repository provisioning remains out of scope. Local setup continues to materialize `local://` workspaces.
- Runtime container orchestration and protocol template consumption remain separate follow-up cycles.

## Tuning Decision

No additional tuning slice is required for this cycle before review. The primary manual gap that started the cycle, project setup ending at a manifest-only workspace without a clear runnable/planned outcome, is now covered by automated Telegram/Rails E2E tests and explicit saga state.
