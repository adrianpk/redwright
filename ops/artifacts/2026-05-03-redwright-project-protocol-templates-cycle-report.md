# Cycle Report: RedWright Project Protocol Templates

## Metadata

- cycle_id: `cycle-2026-05-03-redwright-project-protocol-templates`
- status: `implemented_pending_review`
- date: `2026-05-04`
- source_plan: `ops/plans/2026-05-03-redwright-project-protocol-templates-cycle-plan.md`
- source_tracker: `ops/trackers/2026-05-03-redwright-project-protocol-templates-cycle-tracker.md`
- source_spec: `ops/specs/specs/2026-05-03-redwright-project-protocol-templates-spec.md`

## Summary

This cycle made Project Protocols a Rails-owned project artifact with full lifecycle coverage.

Projects now get setup-time protocol generation, filesystem materialization into `AGENTS.md` and `.agents/*`, a project-scoped Markdown management surface, and editable common plus stack template administration that affects future setups without rewriting existing project copies.

## Delivered Slices

### Slice 1: Project Protocol Domain Foundation

- branch: `fix/slice-1-project-protocol-domain`
- PR: `https://codeberg.org/adrianpk/redwright/pulls/274`
- status: `merged`

Delivered behavior:

- Projects own a single Project Protocol record.
- Project Protocol documents are persisted as ordered Markdown documents.
- Document layer and provenance are explicit.
- Rails command/query responses expose project Protocol state.

### Slice 2: Seeded Template and Composition Foundation

- branch: `fix/slice-2-project-protocol-templates`
- PR: `https://codeberg.org/adrianpk/redwright/pulls/275`
- status: `merged`

Delivered behavior:

- Common behavioral defaults exist for the fixed protocol skeleton.
- Seeded stack templates exist for the agreed initial stack set.
- Composition overlays stack-specific content on the common baseline.
- Missing stack coverage falls back to generated initialization content rather than omitted files.

### Slice 3: Setup-Time Protocol Generation

- branch: `fix/slice-3-project-protocol-setup`
- PR: `https://codeberg.org/adrianpk/redwright/pulls/276`
- status: `merged`

Delivered behavior:

- `/project new` always creates a concrete Project Protocol.
- Setup persists generated protocol documents and provenance.
- Setup metadata and setup saga state include protocol generation output.
- Unsupported stacks still produce minimal protocol content.

### Slice 4: Filesystem Materialization

- branch: `fix/slice-4-project-protocol-materialization`
- PR: `https://codeberg.org/adrianpk/redwright/pulls/277`
- status: `merged`

Delivered behavior:

- Local workspaces materialize `AGENTS.md`, `.agents/*`, and `.agents/playbooks/*`.
- Workspace manifest data includes protocol materialization state.
- Rails-backed protocol changes sync one-way to workspace files.
- Stale materialized protocol files tracked in the manifest are cleaned up.

### Slice 5: Project Protocol Management Surface

- branch: `fix/slice-5-project-protocol-management`
- PR: `https://codeberg.org/adrianpk/redwright/pulls/278`
- status: `merged`

Delivered behavior:

- The web app exposes `Protocols` as a project area distinct from `Documents`.
- Protocol documents render in canonical order.
- Concrete protocol documents are editable in Markdown.
- Project surface links to Protocols, Documents, and Board areas.

### Slice 6: Template Administration Follow-Up and Cycle Closure

- branch: `fix/slice-6-project-protocol-template-crud`
- PR: `pending`
- status: `reviewing`

Delivered behavior:

- Rails persists common and stack protocol templates as editable records.
- Admin surface exposes common and stack template catalogs plus document editing.
- Composer and setup read from the persisted template catalog.
- Editing templates affects future compositions and future project setups.
- Existing project protocol copies remain unchanged after template edits.

## Validation

- `cd apps/web && bundle exec bin/rails test test/models/project_protocol_template_test.rb test/services/project_protocols/template_catalog_test.rb test/services/project_protocols/composer_test.rb test/services/project_protocols/initialization_service_test.rb test/services/project_protocols/command_query_composition_test.rb test/services/project_protocols/command_query_handlers_test.rb test/controllers/project_protocol_templates_controller_test.rb test/controllers/project_protocols_controller_test.rb test/controllers/projects_controller_test.rb test/controllers/documents_controller_test.rb test/models/project_protocol_test.rb test/models/project_test.rb test/services/project_setup/context_loop_service_test.rb test/integration/project_setup_conversational_e2e_test.rb test/integration/project_setup_telegram_e2e_test.rb test/controllers/api/v1/command_queries_controller_test.rb` (pass)
- `cd apps/web && bundle exec bin/rails test` (pass)
- `bundle exec rake test:coverage` (pass, coverage 91.46)

## Coverage

- baseline_coverage: `91.46`
- final_coverage: `91.46`
- result: `maintained`

## Residual Risks

- Template administration is intentionally minimal. It supports document editing but not richer matcher editing, template lifecycle workflows, or advanced conflict tooling.
- Stack template seeding remains intentionally selective and reflects current team familiarity rather than exhaustive ecosystem coverage.
- Template materialization is still scoped to local workspace flows. Remote repository projection and bidirectional sync remain out of scope.
- Codeberg PR title rate limiting remains an external workflow risk. It does not affect persisted product behavior, but it may require operational title workarounds during slice publication.

## Tuning Decision

No additional tuning slice is required before review. The cycle goal is covered: Project Protocols are Rails-owned, setup-generated, materialized to repository files, manageable from the project surface, and backed by editable common and stack templates for future project initialization.
