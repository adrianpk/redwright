# Cycle Tracker: RedWright Agent Runtime Containers

## Metadata

- cycle_id: `cycle-2026-05-03-redwright-agent-runtime-containers`
- status: `in_progress`
- state: `slice_5_pr_open`
- updated: `2026-05-03`
- active_slice: `Slice 5`
- active_task: `none`
- source_plan: `ops/plans/2026-05-03-redwright-agent-runtime-containers-cycle-plan.md`
- source_spec: `ops/specs/specs/2026-05-03-redwright-agent-runtime-containers-spec.md`
- source_draft: `ops/specs/drafts/2026-05-03-redwright-agent-runtime-containers-draft.md`
- context_only_drafts:
  - `ops/specs/drafts/2026-05-03-redwright-project-protocol-templates-draft.md`
  - `ops/specs/drafts/2026-05-03-redwright-llm-rolling-trace-file-draft.md`

## Slice Progress

### Slice 1: Runtime Containers Domain Foundation

- status: `merged`
- branch: `fix/slice-1-runtime-containers-domain`
- PR: `#269 https://codeberg.org/adrianpk/redwright/pulls/269 merged into dev`
- merge_target: `dev`
- last_sync_commit: `189d8c4`

Tasks:

- [x] `T1.1 add Runtime Containers domain model or persistence structure associated with Project`
- [x] `T1.2 define readiness and validation state contracts`
- [x] `T1.3 persist generated file proposals and structured execution command fields`
- [x] `T1.4 persist provenance, assumptions, missing information, and risks`
- [x] `T1.5 expose Runtime Containers read state through Rails command/query responses`
- [x] `T1.6 add tests for project association, state defaults, validation stale behavior, and serialization shape`

Commits:

- [x] `f28d1cd chore(repo): ignore local log directory`
- [x] `0c566e5 feat(web): add runtime containers domain`
- [x] `2658dd2 feat(web): expose runtime containers state`
- [x] `10f828e test(web): cover runtime containers state`
- [x] `7e725b5 docs(ops): update runtime containers slice 1 status`
- [x] `189d8c4 docs(ops): record runtime containers slice 1 pr`

Validation:

- [x] `bundle exec bin/rails test test/models/project_runtime_container_test.rb test/services/runtime_containers/command_query_handlers_test.rb` (pass)
- [x] `bundle exec bin/rails test test/models/project_test.rb test/controllers/api/v1/command_queries_controller_test.rb` (pass)
- [x] `bundle exec bin/rails test` (pass)

### Slice 2: Runtime Containers Generation Contract

- status: `merged`
- branch: `fix/slice-2-runtime-containers-generation`
- PR: `#270 https://codeberg.org/adrianpk/redwright/pulls/270 merged into dev`
- merge_target: `dev`
- last_sync_commit: `9000338`

Tasks:

- [x] `T2.1 add generation input builder from project setup context, stack, framework, language, libraries, and workspace hints`
- [x] `T2.2 add deterministic Go CLI Runtime Containers generator`
- [x] `T2.3 define LLM generation contract with strict structured output for future or configured model usage`
- [x] `T2.4 add malformed or unavailable LLM fallback behavior`
- [x] `T2.5 produce explicit blocked or missing-information output for unsupported contexts`
- [x] `T2.6 add tests for Go CLI generation, unsupported contexts, provenance, assumptions, risks, and fallback behavior`

Commits:

- [x] `cde1132 feat(web): build runtime container generation input`
- [x] `a386fb7 feat(web): generate go cli runtime containers`
- [x] `6e83b23 feat(web): define runtime container llm contract`
- [x] `b39660c feat(web): add runtime container llm fallback`
- [x] `f408dc6 feat(web): block unsupported runtime container generation`
- [x] `de87aa4 test(web): cover runtime container generation`
- [x] `58946ec docs(ops): update runtime containers slice 2 status`
- [x] `9000338 docs(ops): record runtime containers slice 2 pr`

Validation:

- [x] `bundle exec bin/rails test test/services/runtime_containers/generation_service_test.rb test/services/runtime_containers/command_query_handlers_test.rb test/models/project_runtime_container_test.rb` (pass)
- [x] `bundle exec bin/rails test` (pass)

### Slice 3: Runtime Containers Management and Validation

- status: `merged`
- branch: `fix/slice-3-runtime-containers-management`
- PR: `#271 https://codeberg.org/adrianpk/redwright/pulls/271 merged into dev`
- merge_target: `dev`
- last_sync_commit: `9d90ade`

Tasks:

- [x] `T3.1 add Runtime Containers update command/query actions`
- [x] `T3.2 add regeneration as proposed changes without overwriting the active configuration`
- [x] `T3.3 add comparison output between active configuration and regenerated suggestions`
- [x] `T3.4 add validation result recording with pass, fail, skipped, and stale states`
- [x] `T3.5 enforce readiness transition rules`
- [x] `T3.6 add tests for editing, regeneration, comparison, validation recording, readiness, and stale validation transitions`

Commits:

- [x] `f0a0b9e feat(web): manage runtime containers`
- [x] `6d753ab feat(web): validate runtime containers readiness`
- [x] `0ee495b test(web): cover runtime containers management`
- [x] `9d90ade docs(ops): update runtime containers slice 3 status`

Validation:

- [x] `bundle exec bin/rails test test/services/runtime_containers/management_test.rb test/services/runtime_containers/generation_service_test.rb test/services/runtime_containers/command_query_handlers_test.rb test/models/project_runtime_container_test.rb` (pass)
- [x] `bundle exec bin/rails test` (pass)

### Slice 4: Ticket Execution Runtime Readiness Gate

- status: `merged`
- branch: `fix/slice-4-runtime-containers-ticket-gate`
- PR: `#272 https://codeberg.org/adrianpk/redwright/pulls/272 merged into dev`
- merge_target: `dev`
- last_sync_commit: `74c8ed5`

Tasks:

- [x] `T4.1 extend ticket execution context with Runtime Containers configuration references`
- [x] `T4.2 add readiness gate for sandbox-required execution`
- [x] `T4.3 return structured readiness problems for missing, blocked, not-ready, and stale validation states`
- [x] `T4.4 render operator-safe readiness messages through Telegram or runtime adapter paths where applicable`
- [x] `T4.5 add tests for ready, missing, blocked, not-ready, and validation-stale execution paths`

Commits:

- [x] `a623064 feat(runtime): resolve runtime containers context`
- [x] `fba3dcb feat(web): gate tickets on runtime containers readiness`
- [x] `a17bfb9 test(integration): cover runtime containers ticket gate`
- [x] `a82de39 docs(ops): update runtime containers slice 4 status`
- [x] `74c8ed5 docs(ops): record runtime containers slice 4 pr`

Validation:

- [x] `bundle exec bin/rails test test/services/runtime_containers/execution_readiness_test.rb test/services/runtime_bridge/ticket_execution_bridge_test.rb test/services/board_workflow/command_query_handlers_test.rb test/services/project_setup/setup_runtime_bridge_integration_test.rb test/controllers/api/v1/command_queries_controller_test.rb` (pass)
- [x] `bundle exec bin/rails test` (pass)

### Slice 5: Setup Integration and Cycle Closure

- status: `pr_open`
- branch: `fix/slice-5-runtime-containers-setup-e2e`
- PR: `#273 https://codeberg.org/adrianpk/redwright/pulls/273`
- merge_target: `dev`
- last_sync_commit: `pending`

Tasks:

- [x] `T5.1 initialize Runtime Containers during project setup for supported known contexts`
- [x] `T5.2 create planned readiness ticket or task when Runtime Containers cannot be generated as ready`
- [x] `T5.3 include Runtime Containers state in project setup status and workspace manifest metadata`
- [x] `T5.4 add end-to-end tests for setup through Runtime Containers generation and ticket readiness`
- [x] `T5.5 run full Rails tests and repository coverage from canonical locations`
- [x] `T5.6 publish cycle closure report with residual risks and tuning decision`

Commits:

- [x] `6ab1fad feat(web): initialize runtime containers during setup`
- [x] `4426419 test(integration): cover runtime containers setup e2e`
- [x] `eea84f8 docs(ops): close runtime containers cycle`
- [x] `pending docs(ops): record runtime containers slice 5 pr`

Validation:

- [x] `bundle exec bin/rails test test/services/project_setup/context_loop_service_test.rb test/integration/project_setup_conversational_e2e_test.rb test/integration/project_setup_telegram_e2e_test.rb test/services/project_setup/setup_runtime_bridge_integration_test.rb test/services/runtime_containers/generation_service_test.rb` (pass)
- [x] `bundle exec bin/rails test test/controllers/api/v1/command_queries_controller_test.rb test/services/runtime_bridge/ticket_execution_bridge_test.rb test/services/runtime_containers/execution_readiness_test.rb test/services/board_workflow/command_query_handlers_test.rb test/services/project_setup/guided_alignment_service_test.rb test/services/project_setup/state_machine_test.rb` (pass)
- [x] `bundle exec bin/rails test` (pass)
- [x] `bundle exec rake test:coverage` (pass, coverage 91.46)

## Coverage Guard

- baseline_coverage: `91.46`
- target_rule: `post-slice coverage >= pre-slice coverage for new code paths`
- final_coverage: `91.46`
- tuning_needed: `no`
- tuning_evidence: `full Rails suite and repository coverage pass; setup E2E covers Runtime Containers generation, readiness gate, ready transition, and ticket execution context`

## Event Log

- `2026-05-03` state=`planned` note=`promoted the agent Runtime Containers draft into a focused formal spec, cycle plan, and tracker; Protocol templates and LLM rolling trace drafts remain context-only and out of this cycle scope`
- `2026-05-03` state=`slice_1_implemented` note=`implemented Runtime Containers domain persistence, state contracts, structured fields, command/query read surface, and targeted/full Rails validation on fix/slice-1-runtime-containers-domain`
- `2026-05-03` state=`slice_1_pr_open` note=`opened Codeberg PR #269 from fix/slice-1-runtime-containers-domain into dev`
- `2026-05-03` state=`slice_1_merged` note=`PR #269 merged into dev; Slice 1 is closed and Slice 2 remains pending explicit start`
- `2026-05-03` state=`slice_2_implemented` note=`implemented Runtime Containers generation input, deterministic Go CLI generation, strict LLM contract, malformed/unavailable LLM fallback, unsupported blocked output, and targeted/full Rails validation on fix/slice-2-runtime-containers-generation`
- `2026-05-03` state=`slice_2_pr_open` note=`opened Codeberg PR #270 from fix/slice-2-runtime-containers-generation into dev`
- `2026-05-03` state=`slice_2_merged` note=`PR #270 merged into dev; Slice 2 is closed and Slice 3 remains pending explicit start`
- `2026-05-03` state=`slice_3_implemented` note=`implemented Runtime Containers update, regeneration proposal, comparison, validation recording, readiness policy, and targeted/full Rails validation on fix/slice-3-runtime-containers-management`
- `2026-05-03` state=`slice_3_merged` note=`PR #271 merged into dev; Slice 3 is closed and Slice 4 remains pending explicit start`
- `2026-05-03` state=`slice_4_implemented` note=`implemented Runtime Containers execution context resolution, sandbox-required ticket gate, structured readiness problems, operator-safe messages, and targeted/full Rails validation on fix/slice-4-runtime-containers-ticket-gate`
- `2026-05-03` state=`slice_4_pr_open` note=`opened Codeberg PR #272 from fix/slice-4-runtime-containers-ticket-gate into dev`
- `2026-05-03` state=`slice_4_merged` note=`PR #272 merged into dev; Slice 4 is closed and Slice 5 remains pending explicit start`
- `2026-05-03` state=`slice_5_implemented` note=`implemented setup integration, Runtime Containers readiness ticket creation, setup status and manifest metadata, setup-to-ticket readiness E2E coverage, full Rails validation, coverage validation, and cycle closure report on fix/slice-5-runtime-containers-setup-e2e`
- `2026-05-03` state=`slice_5_pr_open` note=`opened Codeberg PR #273 from fix/slice-5-runtime-containers-setup-e2e into dev`
