# Cycle Tracker: RedWright Project Protocol Templates

## Metadata

- cycle_id: `cycle-2026-05-03-redwright-project-protocol-templates`
- status: `completed`
- state: `slice_6_merged`
- updated: `2026-05-03`
- updated: `2026-05-04`
- active_slice: `none`
- active_task: `none`
- source_plan: `ops/plans/2026-05-03-redwright-project-protocol-templates-cycle-plan.md`
- source_spec: `ops/specs/specs/2026-05-03-redwright-project-protocol-templates-spec.md`
- source_draft: `ops/specs/drafts/2026-05-03-redwright-project-protocol-templates-draft.md`
- context_only_drafts:
  - `ops/specs/drafts/2026-05-03-redwright-ticket-scoped-ephemeral-runtime-recipes-draft.md`
  - `ops/specs/drafts/2026-05-03-redwright-llm-rolling-trace-file-draft.md`

## Slice Progress

### Slice 1: Project Protocol Domain Foundation

- status: `merged`
- branch: `fix/slice-1-project-protocol-domain`
- PR: `#274 https://codeberg.org/adrianpk/redwright/pulls/274 merged into dev`
- merge_target: `dev`
- last_sync_commit: `a86069f`

Tasks:

- [x] `T1.1 add Project Protocol domain model associated with Project`
- [x] `T1.2 add Project Protocol document model with identity, ordering, Markdown content, and canonical document paths`
- [x] `T1.3 persist common-versus-stack distinction at the Rails model layer`
- [x] `T1.4 persist document-level provenance for template-derived, composed, initialization-generated, and manually authored content`
- [x] `T1.5 expose Protocol read state through Rails command/query responses`
- [x] `T1.6 add tests for project association, document ordering, provenance serialization, and protocol read shape`

Commits:

- [x] `d295136 feat(web): add project protocol domain`
- [x] `df88958 feat(web): expose project protocol state`
- [x] `4eb6025 test(web): cover project protocol state`
- [x] `a86069f docs(ops): update project protocol slice 1 status`

Validation:

- [x] `bundle exec bin/rails test test/models/project_protocol_test.rb test/models/project_test.rb test/services/project_protocols/command_query_handlers_test.rb` (pass)
- [x] `bundle exec bin/rails test test/services/runtime_containers/command_query_handlers_test.rb test/controllers/api/v1/command_queries_controller_test.rb` (pass)
- [x] `bundle exec bin/rails test` (pass)

### Slice 2: Seeded Template and Composition Foundation

- status: `merged`
- branch: `fix/slice-2-project-protocol-templates`
- PR: `#275 https://codeberg.org/adrianpk/redwright/pulls/275 merged into dev`
- merge_target: `dev`
- last_sync_commit: `3cde5d8`

Tasks:

- [x] `T2.1 add common behavior template seed content for the fixed protocol file skeleton`
- [x] `T2.2 add initial stack-template seed references for the agreed stack set`
- [x] `T2.3 define composition inputs for common defaults plus one-or-more stack overlays`
- [x] `T2.4 define fallback generation contract for missing stack coverage`
- [x] `T2.5 expose composition output as a concrete project protocol document set`
- [x] `T2.6 add tests for common-only composition, multi-overlay composition, and missing-stack fallback output`

Commits:

- [x] `5fa4b32 feat(web): seed project protocol templates`
- [x] `d9fb8ad feat(web): compose project protocol documents`
- [x] `3cde5d8 test(web): cover project protocol composition`
- [x] `1e41324 docs(ops): record project protocol slice 2 pr`

Validation:

- [x] `bundle exec bin/rails test test/services/project_protocols/composer_test.rb test/services/project_protocols/command_query_composition_test.rb test/services/project_protocols/command_query_handlers_test.rb test/models/project_protocol_test.rb` (pass)
- [x] `bundle exec bin/rails test test/models/project_protocol_test.rb test/models/project_test.rb test/services/project_protocols/composer_test.rb test/services/project_protocols/command_query_composition_test.rb test/services/project_protocols/command_query_handlers_test.rb test/controllers/api/v1/command_queries_controller_test.rb` (pass)
- [x] `bundle exec bin/rails test` (pass)

### Slice 3: Setup-Time Protocol Generation

- status: `merged`
- branch: `fix/slice-3-project-protocol-setup`
- PR: `#276 https://codeberg.org/adrianpk/redwright/pulls/276 merged into dev`
- merge_target: `dev`
- last_sync_commit: `5bb6774`

Tasks:

- [x] `T3.1 extend project setup context to resolve protocol generation inputs`
- [x] `T3.2 create initial Project Protocol during project setup`
- [x] `T3.3 apply multiple stack overlays when project shape requires them`
- [x] `T3.4 synthesize minimal initialization-time protocol content when seed coverage is insufficient`
- [x] `T3.5 persist project protocol documents and provenance during setup completion`
- [x] `T3.6 add setup integration tests for covered stacks, multi-overlay contexts, and missing-stack fallback`

Commits:

- [x] `94af421 feat(web): initialize project protocols during setup`
- [x] `f0586cb feat(web): add project protocol setup fallback`
- [x] `5bb6774 test(integration): cover project protocol setup`
- [x] `d7e62f6 docs(ops): update project protocol slice 3 status`

Validation:

- [x] `bundle exec bin/rails test test/services/project_protocols/initialization_service_test.rb test/services/project_protocols/composer_test.rb test/services/project_protocols/command_query_composition_test.rb test/services/project_protocols/command_query_handlers_test.rb test/services/project_setup/context_loop_service_test.rb test/integration/project_setup_conversational_e2e_test.rb test/integration/project_setup_telegram_e2e_test.rb test/controllers/api/v1/command_queries_controller_test.rb` (pass)
- [x] `bundle exec bin/rails test` (pass)

### Slice 4: Filesystem Materialization

- status: `merged`
- branch: `fix/slice-4-project-protocol-materialization`
- PR: `#277 https://codeberg.org/adrianpk/redwright/pulls/277 merged into dev`
- merge_target: `dev`
- last_sync_commit: `57db404`

Tasks:

- [x] `T4.1 define canonical filesystem projection for the fixed protocol file skeleton`
- [x] `T4.2 generate AGENTS.md as the lightweight root entrypoint`
- [x] `T4.3 generate PLAYBOOKS.md as the playbook index`
- [x] `T4.4 generate detailed protocol documents under .agents/`
- [x] `T4.5 update materialized files automatically when Rails-backed protocol documents change`
- [x] `T4.6 add tests for initial materialization, update propagation, root placement, and one-way sync behavior`

Commits:

- [x] `9281b9e feat(runtime): materialize project protocol files`
- [x] `a90d466 feat(web): sync project protocols to workspace`
- [x] `57db404 test(integration): cover project protocol materialization`
- [x] `0f8831b docs(ops): update project protocol slice 4 status`

Validation:

- [x] `bundle exec bin/rails test test/services/project_protocols/filesystem_materializer_test.rb test/services/project_protocols/initialization_service_test.rb test/services/project_protocols/composer_test.rb test/services/project_protocols/command_query_composition_test.rb test/services/project_protocols/command_query_handlers_test.rb test/models/project_protocol_test.rb test/models/project_test.rb test/services/project_setup/context_loop_service_test.rb test/integration/project_setup_conversational_e2e_test.rb test/integration/project_setup_telegram_e2e_test.rb test/controllers/api/v1/command_queries_controller_test.rb` (pass)
- [x] `bundle exec bin/rails test` (pass)

### Slice 5: Project Protocol Management Surface

- status: `merged`
- branch: `fix/slice-5-project-protocol-management`
- PR: `#278 https://codeberg.org/adrianpk/redwright/pulls/278 merged into dev`
- merge_target: `dev`
- last_sync_commit: `df23cba`

Tasks:

- [x] `T5.1 expose Protocols as a project area distinct from Documents`
- [x] `T5.2 render the protocol document list in canonical order`
- [x] `T5.3 allow Markdown editing of concrete Project Protocol documents`
- [x] `T5.4 keep user-facing UX constrained without review-state or regeneration controls`
- [x] `T5.5 ensure manual Rails edits propagate to filesystem projection`
- [x] `T5.6 add tests for protocol reads, writes, ordering, and materialization coupling`

Commits:

- [x] `5c8fc94 feat(web): add project protocols area`
- [x] `8d8eac8 feat(web): edit project protocol documents`
- [x] `df23cba test(web): cover project protocol management`
- [x] `5ae0fe7 docs(ops): update project protocol slice 5 status`

Validation:

- [x] `bundle exec bin/rails test test/controllers/project_protocols_controller_test.rb test/controllers/projects_controller_test.rb test/controllers/documents_controller_test.rb test/services/project_protocols/filesystem_materializer_test.rb test/services/project_protocols/initialization_service_test.rb test/services/project_protocols/composer_test.rb test/services/project_protocols/command_query_composition_test.rb test/services/project_protocols/command_query_handlers_test.rb test/models/project_protocol_test.rb test/models/project_test.rb test/services/project_setup/context_loop_service_test.rb test/integration/project_setup_conversational_e2e_test.rb test/integration/project_setup_telegram_e2e_test.rb test/controllers/api/v1/command_queries_controller_test.rb` (pass)
- [x] `bundle exec bin/rails test` (pass)

### Slice 6: Template Administration Follow-Up and Cycle Closure

- status: `merged`
- branch: `fix/slice-6-project-protocol-template-crud`
- PR: `#279 https://codeberg.org/adrianpk/redwright/pulls/279 merged into dev`
- merge_target: `dev`
- last_sync_commit: `ae48365`

Tasks:

- [x] `T6.1 expose common template administration surface`
- [x] `T6.2 expose stack-template administration surface`
- [x] `T6.3 allow seeded template content to be extended or refined from Rails`
- [x] `T6.4 ensure template changes affect future setup composition without mutating existing project copies`
- [x] `T6.5 run full relevant tests and repository coverage from canonical locations`
- [x] `T6.6 publish cycle closure report with residual risks and post-cycle follow-up items`

Commits:

- [x] `c5d5e05 feat(web): manage project protocol templates`
- [x] `64dd277 test(integration): cover project protocol templates`
- [x] `ae48365 docs(ops): close project protocol templates cycle`

Validation:

- [x] `bundle exec bin/rails test test/models/project_protocol_template_test.rb test/services/project_protocols/template_catalog_test.rb test/services/project_protocols/composer_test.rb test/services/project_protocols/initialization_service_test.rb test/services/project_protocols/command_query_composition_test.rb test/services/project_protocols/command_query_handlers_test.rb test/controllers/project_protocol_templates_controller_test.rb test/controllers/project_protocols_controller_test.rb test/controllers/projects_controller_test.rb test/controllers/documents_controller_test.rb test/models/project_protocol_test.rb test/models/project_test.rb test/services/project_setup/context_loop_service_test.rb test/integration/project_setup_conversational_e2e_test.rb test/integration/project_setup_telegram_e2e_test.rb test/controllers/api/v1/command_queries_controller_test.rb` (pass)
- [x] `bundle exec bin/rails test` (pass)
- [x] `bundle exec rake test:coverage` (pass, coverage 91.46)

## Coverage Guard

- baseline_coverage: `91.46`
- target_rule: `post-slice coverage >= pre-slice coverage for new code paths`
- final_coverage: `91.46`
- tuning_needed: `no`
- tuning_evidence: `full Rails suite and repository coverage pass; template edits affect future setup composition while existing project protocol copies remain unchanged`

## Event Log

- `2026-05-03` state=`planned` note=`promoted the Project Protocol Templates draft plus curated conversation into a formal spec, cycle plan, and tracker; Runtime Containers remains separate cycle history and ticket-scoped runtime recipes plus rolling trace remain context-only drafts`
- `2026-05-03` state=`slice_1_implemented` note=`implemented Project Protocol domain persistence, document-level modeling, project query exposure, targeted protocol tests, dependent query coverage, and full Rails validation on fix/slice-1-project-protocol-domain`
- `2026-05-03` state=`slice_1_merged` note=`PR #274 merged into dev; Slice 1 is closed and Slice 2 remains pending explicit start`
- `2026-05-03` state=`slice_2_implemented` note=`implemented seeded protocol template registry, stack-aware composition, generated fallback behavior, composition command surface, targeted composition validation, and full Rails validation on fix/slice-2-project-protocol-templates`
- `2026-05-03` state=`slice_2_pr_open` note=`opened Codeberg PR #275 from fix/slice-2-project-protocol-templates into dev`
- `2026-05-03` state=`slice_2_merged` note=`PR #275 merged into dev; Slice 2 is closed and Slice 3 moved into implementation`
- `2026-05-03` state=`slice_3_implemented` note=`implemented setup-time protocol initialization, protocol generation/session metadata exposure, library-aware overlay resolution, fallback protocol persistence, targeted setup validation, and full Rails validation on fix/slice-3-project-protocol-setup`
- `2026-05-03` state=`slice_3_pr_open` note=`opened Codeberg PR #276 from fix/slice-3-project-protocol-setup into dev`
- `2026-05-03` state=`slice_3_merged` note=`PR #276 merged into dev; Slice 3 is closed and Slice 4 remains pending explicit start`
- `2026-05-03` state=`slice_4_implemented` note=`implemented protocol filesystem materialization into AGENTS.md and .agents paths, one-way Rails-to-workspace sync, manifest protocol metadata, stale file cleanup, setup workspace integration, and targeted/full Rails validation on fix/slice-4-project-protocol-materialization`
- `2026-05-03` state=`slice_4_pr_open` note=`opened Codeberg PR #277 from fix/slice-4-project-protocol-materialization into dev`
- `2026-05-04` state=`slice_4_merged` note=`PR #277 merged into dev; Slice 4 is closed and Slice 5 remains pending explicit start`
- `2026-05-04` state=`slice_5_implemented` note=`implemented project-scoped Protocols web area, canonical document listing, Markdown editing surface, project area navigation, and targeted/full Rails validation on fix/slice-5-project-protocol-management`
- `2026-05-04` state=`slice_5_pr_open` note=`opened Codeberg PR #278 from fix/slice-5-project-protocol-management into dev`
- `2026-05-04` state=`slice_5_merged` note=`PR #278 merged into dev; Slice 5 is closed and Slice 6 remains pending explicit start`
- `2026-05-04` state=`slice_6_implemented` note=`implemented persisted common and stack protocol templates, admin template editing surface, composition against Rails-backed templates, future-only template application semantics, full Rails validation, coverage validation, and cycle report publication on fix/slice-6-project-protocol-template-crud`
- `2026-05-04` state=`slice_6_pr_open` note=`opened Codeberg PR #279 from fix/slice-6-project-protocol-template-crud into dev`
- `2026-05-04` state=`slice_6_merged` note=`PR #279 merged into dev; the Project Protocol Templates cycle is complete on dev`
