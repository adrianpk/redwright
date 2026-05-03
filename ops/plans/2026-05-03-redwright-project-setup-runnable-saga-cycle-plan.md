# Cycle Plan: RedWright Project Setup Runnable Saga

## Metadata

- cycle_id: `cycle-2026-05-03-redwright-project-setup-runnable-saga`
- status: `completed`
- owner: `adrianpk`
- created: `2026-05-03`
- updated: `2026-05-03`
- goal: `make project setup an explicit saga that persists canonical context, materializes Rails/workspace state, produces a runnable scaffold for supported setups, and hands off later work through tickets`
- scope: `feature`
- source_spec: `ops/specs/specs/2026-05-03-redwright-project-setup-runnable-saga-spec.md`

## Slice List

### Slice 1: Setup LLM Traces and Semantic Slot Normalization

- status: `completed`
- branch: `fix/slice-1-setup-llm-traces-and-slot-normalization`
- pr_title: `feat(slice-1): setup llm traces and slot normalization`
- objective: `make setup prompt rendering observable and prevent raw confusing answers from being persisted as canonical slot values`
- tasks:
- [x] `T1.1 characterize missing setup LLM traces and raw slot persistence with focused tests`
- [x] `T1.2 instrument ProjectSetupPromptRenderer with Trace.llm_request and Trace.llm_response`
- [x] `T1.3 add semantic answer normalization contract with strict JSON output, deterministic fallback, and malformed-output handling`
- [x] `T1.4 integrate normalized slot updates into project setup advancement without losing raw answer audit data`
- [x] `T1.5 prevent prompt-confusion/meta answers from filling framework, language_runtime, libraries, or stack`
- [x] `T1.6 synthesize stack from normalized context instead of blindly deriving it from framework`
- [x] `T1.7 add tests for Go CLI answers, framework confusion, fallback normalization, and trace output`
- acceptance:
- `foreground trace mode shows setup prompt LLM requests and responses`
- `normalization fallback is traceable instead of silent`
- `raw answer and canonical slot value are preserved separately`
- `confusion text does not become framework or stack`
- `stack synthesis prefers normalized language/framework/library context`
- planned_commits:
- `test(web): characterize setup slot normalization gaps`
- `feat(telegram): trace setup prompt rendering`
- `feat(web): normalize project setup slot answers`
- `test(web): cover semantic setup normalization`

### Slice 2: Explicit Setup Saga State and Query Surface

- status: `completed`
- branch: `fix/slice-2-project-setup-saga-state`
- pr_title: `feat(slice-2): project setup saga state`
- objective: `persist and expose explicit setup stages for questionnaire, materialization, initial implementation, and ticket operation`
- tasks:
- [x] `T2.1 define persisted saga stage metadata compatible with existing ProjectSetupSession states`
- [x] `T2.2 add materialization and initial implementation result structures to setup session metadata`
- [x] `T2.3 expose structured saga state through Rails command/query responses`
- [x] `T2.4 update /project where to report setup stage, workspace, and runnable/planned status when available`
- [x] `T2.5 add tests for stage transitions, repeated completion, and API/query shape`
- acceptance:
- `setup state distinguishes questionnaire, materialization, initial implementation, and ticket operation`
- `API clients can inspect materialization and initial implementation status`
- `/project where` can explain where the active project stands without raw internal state leakage`
- planned_commits:
- `feat(web): persist project setup saga status`
- `feat(telegram): render project setup saga status`
- `test(integration): cover setup saga query status`

### Slice 3: Materialization Outcome and Planned Fallback

- status: `completed`
- branch: `fix/slice-3-project-setup-materialization-outcome`
- pr_title: `feat(slice-3): project setup materialization outcome`
- objective: `make materialization produce explicit runnable/planned/failed outcomes and useful planned fallback artifacts`
- tasks:
- [x] `T3.1 extend workspace manifest with materialization status, initial implementation status, validation status, and linked ticket ids`
- [x] `T3.2 create or update README/setup notes during local workspace materialization`
- [x] `T3.3 create starter implementation ticket when the project is not yet runnable`
- [x] `T3.4 ensure unsupported stack/archetype combinations become materialized_planned with reason`
- [x] `T3.5 add idempotency tests for manifest, README, document, board, and starter ticket reconciliation`
- acceptance:
- `unsupported setups no longer present as ambiguous created projects`
- `planned fallback workspaces have README/setup notes and starter tickets`
- `manifest records materialization and initial implementation status`
- planned_commits:
- `feat(web): record setup materialization outcomes`
- `feat(web): create planned setup fallback artifacts`
- `test(web): cover setup materialization fallback`

### Slice 4: Go CLI Initial Implementation Scaffold

- status: `completed`
- branch: `fix/slice-4-go-cli-initial-scaffold`
- pr_title: `feat(slice-4): go cli initial scaffold`
- objective: `produce a minimal runnable Go CLI scaffold for supported project setup context`
- tasks:
- [x] `T4.1 add deterministic scaffold profile selection for Go CLI projects`
- [x] `T4.2 generate go.mod, main entrypoint, README, and basic test when Go CLI context is detected`
- [x] `T4.3 support optional urfave/cli dependency when libraries include it`
- [x] `T4.4 run or record go test ./... validation depending on local toolchain availability`
- [x] `T4.5 update Rails materialization data and manifest with runnable scaffold results`
- [x] `T4.6 add filesystem and API tests for the Go CLI setup scenario`
- acceptance:
- `Go CLI setup creates a workspace with Go project files, not only a manifest`
- `validation result is recorded as pass/fail/skipped with reason`
- `Telegram completion can honestly say the project is runnable when validation permits it`
- planned_commits:
- `feat(web): add go cli setup scaffold`
- `feat(web): record initial scaffold validation`
- `test(integration): cover go cli runnable setup`

### Slice 5: Telegram and Rails End-to-End Closure

- status: `completed`
- branch: `fix/slice-5-runnable-setup-e2e-closure`
- pr_title: `feat(slice-5): runnable setup e2e closure`
- objective: `close the cycle with end-to-end Telegram, Rails API, workspace, manifest, and ticket handoff coverage`
- tasks:
- [x] `T5.1 add Telegram E2E for project new through Go CLI runnable or validation-skipped setup`
- [x] `T5.2 add Telegram E2E for unsupported setup planned fallback`
- [x] `T5.3 verify completion messages distinguish runnable, planned, and failed outcomes`
- [x] `T5.4 run full Rails tests and repository coverage from canonical locations`
- [x] `T5.5 publish cycle closure report with residual risks and tuning decision`
- acceptance:
- `manual Telegram testing has automated coverage for the project setup path`
- `completed setup ends in runnable or planned state with clear operator message`
- `later work is represented through Rails tickets`
- `coverage is maintained or increased`
- planned_commits:
- `test(integration): cover runnable setup telegram e2e`
- `docs(ops): close runnable setup saga cycle`

## Global Exit Criteria

- Project setup stages are explicit and queryable.
- LLM setup rendering and normalization are traceable.
- Canonical context is semantically normalized before materialization.
- Local completion creates either a runnable scaffold or a planned fallback with reason.
- Go CLI setup produces concrete workspace files.
- Unsupported setup produces tickets and documents rather than a false runnable claim.
- Telegram and Rails API agree on setup outcome.
- Post-setup work is visible in Rails board tickets.
- Test coverage is maintained or increased.

## Validation Command Context

- Rails targeted tests must be run from `apps/web` with `bundle exec bin/rails test <paths>`.
- Ruby targeted tests must be run from repository root with `ruby -Itest <paths>`.
- Repository coverage must be run from repository root.
- Canonical repository coverage command: `bundle exec rake test:coverage`.
- PR validation entries must be reported as command plus `(pass)` or `(fail)`, without raw running traces.

## Non-Goals

- Do not implement full Projects CRUD UI in this cycle.
- Do not create remote Git repositories.
- Do not implement Protocol template CRUD.
- Do not implement Runtime Containers CRUD or sandbox orchestration.
- Do not merge this cycle into the closed conversational saga cycle.
- Do not start `dev -> main` alignment inside a slice.
