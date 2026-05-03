# Cycle Tracker: RedWright Project Protocol Templates

## Metadata

- cycle_id: `cycle-2026-05-03-redwright-project-protocol-templates`
- status: `in_progress`
- state: `slice_1_implemented`
- updated: `2026-05-03`
- active_slice: `Slice 1`
- active_task: `none`
- source_plan: `ops/plans/2026-05-03-redwright-project-protocol-templates-cycle-plan.md`
- source_spec: `ops/specs/specs/2026-05-03-redwright-project-protocol-templates-spec.md`
- source_draft: `ops/specs/drafts/2026-05-03-redwright-project-protocol-templates-draft.md`
- context_only_drafts:
  - `ops/specs/drafts/2026-05-03-redwright-ticket-scoped-ephemeral-runtime-recipes-draft.md`
  - `ops/specs/drafts/2026-05-03-redwright-llm-rolling-trace-file-draft.md`

## Slice Progress

### Slice 1: Project Protocol Domain Foundation

- status: `implemented`
- branch: `fix/slice-1-project-protocol-domain`
- PR: `pending`
- merge_target: `dev`
- last_sync_commit: `4eb6025`

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
- [ ] `pending docs(ops): update project protocol slice 1 status`

Validation:

- [x] `bundle exec bin/rails test test/models/project_protocol_test.rb test/models/project_test.rb test/services/project_protocols/command_query_handlers_test.rb` (pass)
- [x] `bundle exec bin/rails test test/services/runtime_containers/command_query_handlers_test.rb test/controllers/api/v1/command_queries_controller_test.rb` (pass)
- [x] `bundle exec bin/rails test` (pass)

### Slice 2: Seeded Template and Composition Foundation

- status: `planned`
- branch: `fix/slice-2-project-protocol-templates`
- PR: `pending`
- merge_target: `dev`
- last_sync_commit: `pending`

Tasks:

- [ ] `T2.1 add common behavior template seed content for the fixed protocol file skeleton`
- [ ] `T2.2 add initial stack-template seed references for the agreed stack set`
- [ ] `T2.3 define composition inputs for common defaults plus one-or-more stack overlays`
- [ ] `T2.4 define fallback generation contract for missing stack coverage`
- [ ] `T2.5 expose composition output as a concrete project protocol document set`
- [ ] `T2.6 add tests for common-only composition, multi-overlay composition, and missing-stack fallback output`

Commits:

- [ ] `pending feat(web): seed project protocol templates`
- [ ] `pending feat(web): compose project protocol documents`
- [ ] `pending test(web): cover project protocol composition`
- [ ] `pending docs(ops): update project protocol slice 2 status`

Validation:

- [ ] `pending bundle exec bin/rails test <targeted protocol composition paths>`
- [ ] `pending bundle exec bin/rails test`

### Slice 3: Setup-Time Protocol Generation

- status: `planned`
- branch: `fix/slice-3-project-protocol-setup`
- PR: `pending`
- merge_target: `dev`
- last_sync_commit: `pending`

Tasks:

- [ ] `T3.1 extend project setup context to resolve protocol generation inputs`
- [ ] `T3.2 create initial Project Protocol during project setup`
- [ ] `T3.3 apply multiple stack overlays when project shape requires them`
- [ ] `T3.4 synthesize minimal initialization-time protocol content when seed coverage is insufficient`
- [ ] `T3.5 persist project protocol documents and provenance during setup completion`
- [ ] `T3.6 add setup integration tests for covered stacks, multi-overlay contexts, and missing-stack fallback`

Commits:

- [ ] `pending feat(web): initialize project protocols during setup`
- [ ] `pending feat(web): add project protocol setup fallback`
- [ ] `pending test(integration): cover project protocol setup`
- [ ] `pending docs(ops): update project protocol slice 3 status`

Validation:

- [ ] `pending bundle exec bin/rails test <targeted project setup protocol paths>`
- [ ] `pending bundle exec bin/rails test`

### Slice 4: Filesystem Materialization

- status: `planned`
- branch: `fix/slice-4-project-protocol-materialization`
- PR: `pending`
- merge_target: `dev`
- last_sync_commit: `pending`

Tasks:

- [ ] `T4.1 define canonical filesystem projection for the fixed protocol file skeleton`
- [ ] `T4.2 generate AGENTS.md as the lightweight root entrypoint`
- [ ] `T4.3 generate PLAYBOOKS.md as the playbook index`
- [ ] `T4.4 generate detailed protocol documents under .agents/`
- [ ] `T4.5 update materialized files automatically when Rails-backed protocol documents change`
- [ ] `T4.6 add tests for initial materialization, update propagation, root placement, and one-way sync behavior`

Commits:

- [ ] `pending feat(runtime): materialize project protocol files`
- [ ] `pending feat(web): sync project protocols to workspace`
- [ ] `pending test(integration): cover project protocol materialization`
- [ ] `pending docs(ops): update project protocol slice 4 status`

Validation:

- [ ] `pending bundle exec bin/rails test <targeted materialization paths>`
- [ ] `pending bundle exec bin/rails test`

### Slice 5: Project Protocol Management Surface

- status: `planned`
- branch: `fix/slice-5-project-protocol-management`
- PR: `pending`
- merge_target: `dev`
- last_sync_commit: `pending`

Tasks:

- [ ] `T5.1 expose Protocols as a project area distinct from Documents`
- [ ] `T5.2 render the protocol document list in canonical order`
- [ ] `T5.3 allow Markdown editing of concrete Project Protocol documents`
- [ ] `T5.4 keep user-facing UX constrained without review-state or regeneration controls`
- [ ] `T5.5 ensure manual Rails edits propagate to filesystem projection`
- [ ] `T5.6 add tests for protocol reads, writes, ordering, and materialization coupling`

Commits:

- [ ] `pending feat(web): add project protocols area`
- [ ] `pending feat(web): edit project protocol documents`
- [ ] `pending test(web): cover project protocol management`
- [ ] `pending docs(ops): update project protocol slice 5 status`

Validation:

- [ ] `pending bundle exec bin/rails test <targeted project protocol management paths>`
- [ ] `pending bundle exec bin/rails test`

### Slice 6: Template Administration Follow-Up and Cycle Closure

- status: `planned`
- branch: `fix/slice-6-project-protocol-template-crud`
- PR: `pending`
- merge_target: `dev`
- last_sync_commit: `pending`

Tasks:

- [ ] `T6.1 expose common template administration surface`
- [ ] `T6.2 expose stack-template administration surface`
- [ ] `T6.3 allow seeded template content to be extended or refined from Rails`
- [ ] `T6.4 ensure template changes affect future setup composition without mutating existing project copies`
- [ ] `T6.5 run full relevant tests and repository coverage from canonical locations`
- [ ] `T6.6 publish cycle closure report with residual risks and post-cycle follow-up items`

Commits:

- [ ] `pending feat(web): manage project protocol templates`
- [ ] `pending test(integration): cover project protocol templates`
- [ ] `pending docs(ops): close project protocol templates cycle`

Validation:

- [ ] `pending bundle exec bin/rails test <targeted project protocol template paths>`
- [ ] `pending bundle exec bin/rails test`
- [ ] `pending bundle exec rake test:coverage`

## Coverage Guard

- baseline_coverage: `pending`
- target_rule: `post-slice coverage >= pre-slice coverage for new code paths`
- final_coverage: `pending`
- tuning_needed: `pending`
- tuning_evidence: `pending`

## Event Log

- `2026-05-03` state=`planned` note=`promoted the Project Protocol Templates draft plus curated conversation into a formal spec, cycle plan, and tracker; Runtime Containers remains separate cycle history and ticket-scoped runtime recipes plus rolling trace remain context-only drafts`
- `2026-05-03` state=`slice_1_implemented` note=`implemented Project Protocol domain persistence, document-level modeling, project query exposure, targeted protocol tests, dependent query coverage, and full Rails validation on fix/slice-1-project-protocol-domain`
