# Cycle Plan: RedWright Agent Runtime Containers

## Metadata

- cycle_id: `cycle-2026-05-03-redwright-agent-runtime-containers`
- status: `in_progress`
- owner: `adrianpk`
- created: `2026-05-03`
- updated: `2026-05-03`
- goal: `make project Runtime Containers a Rails-owned artifact that can be generated, edited, validated, and used to gate ticket-first agent execution`
- scope: `feature`
- source_spec: `ops/specs/specs/2026-05-03-redwright-agent-runtime-containers-spec.md`

## Slice List

### Slice 1: Runtime Containers Domain Foundation

- status: `merged`
- branch: `fix/slice-1-runtime-containers-domain`
- pr_title: `feat(slice-1): runtime containers domain`
- objective: `add project-owned Runtime Containers persistence with readiness, validation, generated files, provenance, assumptions, missing information, and risks`
- tasks:
- [x] `T1.1 add Runtime Containers domain model or persistence structure associated with Project`
- [x] `T1.2 define readiness and validation state contracts`
- [x] `T1.3 persist generated file proposals and structured execution command fields`
- [x] `T1.4 persist provenance, assumptions, missing information, and risks`
- [x] `T1.5 expose Runtime Containers read state through Rails command/query responses`
- [x] `T1.6 add tests for project association, state defaults, validation stale behavior, and serialization shape`
- acceptance:
- `each project can own Runtime Containers state`
- `new records start in an explicit non-ready state`
- `runtime execution fields and generated file proposals are structured`
- `Rails can query the current Runtime Containers state`
- planned_commits:
- `feat(web): add runtime containers domain`
- `feat(web): expose runtime containers state`
- `test(web): cover runtime containers state`

### Slice 2: Runtime Containers Generation Contract

- status: `merged`
- branch: `fix/slice-2-runtime-containers-generation`
- pr_title: `feat(slice-2): runtime containers generation`
- objective: `generate initial Runtime Containers suggestions from project setup context with deterministic Go CLI support and safe fallback behavior`
- tasks:
- [x] `T2.1 add generation input builder from project setup context, stack, framework, language, libraries, and workspace hints`
- [x] `T2.2 add deterministic Go CLI Runtime Containers generator`
- [x] `T2.3 define LLM generation contract with strict structured output for future or configured model usage`
- [x] `T2.4 add malformed or unavailable LLM fallback behavior`
- [x] `T2.5 produce explicit blocked or missing-information output for unsupported contexts`
- [x] `T2.6 add tests for Go CLI generation, unsupported contexts, provenance, assumptions, risks, and fallback behavior`
- acceptance:
- `Go CLI projects receive a useful Runtime Containers suggestion`
- `unsupported contexts do not become ready by accident`
- `generation records input signals, confidence, assumptions, missing information, and risks`
- `malformed LLM output does not corrupt the Runtime Containers configuration`
- planned_commits:
- `feat(web): generate runtime container suggestions`
- `feat(web): add runtime container fallback generation`
- `test(web): cover runtime container generation`

### Slice 3: Runtime Containers Management and Validation

- status: `merged`
- branch: `fix/slice-3-runtime-containers-management`
- pr_title: `feat(slice-3): runtime containers management`
- objective: `allow Runtime Containers inspection, editing, regeneration, comparison, validation recording, and readiness transitions`
- tasks:
- [x] `T3.1 add Runtime Containers update command/query actions`
- [x] `T3.2 add regeneration as proposed changes without overwriting the active configuration`
- [x] `T3.3 add comparison output between active configuration and regenerated suggestions`
- [x] `T3.4 add validation result recording with pass, fail, skipped, and stale states`
- [x] `T3.5 enforce readiness transition rules`
- [x] `T3.6 add tests for editing, regeneration, comparison, validation recording, readiness, and stale validation transitions`
- acceptance:
- `users can correct generated Runtime Containers from Rails`
- `regeneration is reviewable before acceptance`
- `validation status is explicit`
- `ready state is blocked when required fields or validation are missing`
- planned_commits:
- `feat(web): manage runtime containers`
- `feat(web): validate runtime containers readiness`
- `test(web): cover runtime containers management`

### Slice 4: Ticket Execution Runtime Readiness Gate

- status: `merged`
- branch: `fix/slice-4-runtime-containers-ticket-gate`
- pr_title: `feat(slice-4): runtime containers ticket gate`
- objective: `make ticket execution resolve Runtime Containers readiness before sandbox-required agent work starts`
- tasks:
- [x] `T4.1 extend ticket execution context with Runtime Containers configuration references`
- [x] `T4.2 add readiness gate for sandbox-required execution`
- [x] `T4.3 return structured readiness problems for missing, blocked, not-ready, and stale validation states`
- [x] `T4.4 render operator-safe readiness messages through Telegram or runtime adapter paths where applicable`
- [x] `T4.5 add tests for ready, missing, blocked, not-ready, and validation-stale execution paths`
- acceptance:
- `ticket execution can resolve the project Runtime Containers configuration`
- `sandbox-required work does not start without ready Runtime Containers`
- `operators receive actionable readiness errors`
- `runtime context includes execution commands and workspace paths when ready`
- planned_commits:
- `feat(runtime): resolve runtime containers context`
- `feat(web): gate tickets on runtime containers readiness`
- `test(integration): cover runtime containers ticket gate`

### Slice 5: Setup Integration and Cycle Closure

- status: `implemented`
- branch: `fix/slice-5-runtime-containers-setup-e2e`
- pr_title: `feat(slice-5): runtime containers setup e2e`
- objective: `initialize Runtime Containers during project setup and close the cycle with end-to-end coverage from setup to ticket readiness`
- tasks:
- [x] `T5.1 initialize Runtime Containers during project setup for supported known contexts`
- [x] `T5.2 create planned readiness ticket or task when Runtime Containers cannot be generated as ready`
- [x] `T5.3 include Runtime Containers state in project setup status and workspace manifest metadata`
- [x] `T5.4 add end-to-end tests for setup through Runtime Containers generation and ticket readiness`
- [x] `T5.5 run full Rails tests and repository coverage from canonical locations`
- [x] `T5.6 publish cycle closure report with residual risks and tuning decision`
- acceptance:
- `project setup creates or schedules Runtime Containers readiness work`
- `Go CLI setup gets an initial Runtime Containers suggestion`
- `unsupported setup gets explicit planned readiness work`
- `ticket execution readiness is visible after setup`
- `coverage is maintained or increased`
- planned_commits:
- `feat(web): initialize runtime containers during setup`
- `test(integration): cover runtime containers setup e2e`
- `docs(ops): close runtime containers cycle`

## Global Exit Criteria

- Runtime Containers are a Rails-owned project artifact.
- Runtime Containers can be generated, inspected, edited, regenerated, compared, validated, and marked ready.
- Go CLI projects receive a useful deterministic Runtime Containers suggestion.
- Unsupported contexts are explicit and actionable.
- Ticket execution gates sandbox-required work on Runtime Containers readiness.
- Setup initializes or schedules Runtime Containers readiness work.
- Full relevant tests pass and coverage is maintained or increased.

## Validation Command Context

- Rails targeted tests must be run from `apps/web` with `bundle exec bin/rails test <paths>`.
- Ruby targeted tests must be run from repository root with `ruby -Itest <paths>`.
- Repository coverage must be run from repository root.
- Canonical repository coverage command: `bundle exec rake test:coverage`.
- PR validation entries must be reported as command plus `(pass)` or `(fail)`, without raw running traces.

## Non-Goals

- Do not implement Protocol template management in this cycle.
- Do not implement LLM rolling trace files in this cycle.
- Do not implement production deployment generation.
- Do not implement hardened container isolation.
- Do not create a template marketplace.
- Do not start `dev -> main` alignment inside a slice.
