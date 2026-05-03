# Cycle Plan: RedWright Project Protocol Templates

## Metadata

- cycle_id: `cycle-2026-05-03-redwright-project-protocol-templates`
- status: `in_progress`
- owner: `adrianpk`
- created: `2026-05-03`
- updated: `2026-05-03`
- goal: `make Project Protocols a Rails-owned project artifact that is generated during setup, editable as Markdown documents, and materialized automatically into repository protocol files`
- scope: `feature`
- source_spec: `ops/specs/specs/2026-05-03-redwright-project-protocol-templates-spec.md`

## Slice List

### Slice 1: Project Protocol Domain Foundation

- status: `merged`
- branch: `fix/slice-1-project-protocol-domain`
- pr_title: `feat(slice-1): project protocol domain`
- objective: `add project-owned Protocol persistence with document family modeling, ordering, common-versus-stack distinction, and document-level provenance`
- tasks:
- [x] `T1.1 add Project Protocol domain model associated with Project`
- [x] `T1.2 add Project Protocol document model with identity, ordering, Markdown content, and canonical document paths`
- [x] `T1.3 persist common-versus-stack distinction at the Rails model layer`
- [x] `T1.4 persist document-level provenance for template-derived, composed, initialization-generated, and manually authored content`
- [x] `T1.5 expose Protocol read state through Rails command/query responses`
- [x] `T1.6 add tests for project association, document ordering, provenance serialization, and protocol read shape`
- acceptance:
- `each project can own one concrete Project Protocol`
- `project protocol documents are structured rather than implicit filesystem-only state`
- `Rails can query protocol documents with common-versus-stack metadata`
- `document-level provenance is explicit`
- planned_commits:
- `feat(web): add project protocol domain`
- `feat(web): expose project protocol state`
- `test(web): cover project protocol state`

### Slice 2: Seeded Template and Composition Foundation

- status: `merged`
- branch: `fix/slice-2-project-protocol-templates`
- pr_title: `feat(slice-2): project protocol template seeds`
- objective: `define common behavior defaults, seeded stack template references, and composition rules for building a concrete project protocol`
- tasks:
- [x] `T2.1 add common behavior template seed content for the fixed protocol file skeleton`
- [x] `T2.2 add initial stack-template seed references for the agreed stack set`
- [x] `T2.3 define composition inputs for common defaults plus one-or-more stack overlays`
- [x] `T2.4 define fallback generation contract for missing stack coverage`
- [x] `T2.5 expose composition output as a concrete project protocol document set`
- [x] `T2.6 add tests for common-only composition, multi-overlay composition, and missing-stack fallback output`
- acceptance:
- `the system can build a protocol document set from common defaults and stack overlays`
- `the seed list is explicit and intentionally selective`
- `missing stack-template coverage yields a minimal generated protocol rather than missing files`
- `composition remains deterministic enough for Rails-owned protocol persistence`
- planned_commits:
- `feat(web): seed project protocol templates`
- `feat(web): compose project protocol documents`
- `test(web): cover project protocol composition`

### Slice 3: Setup-Time Protocol Generation

- status: `merged`
- branch: `fix/slice-3-project-protocol-setup`
- pr_title: `feat(slice-3): setup project protocols`
- objective: `make /project new always create an initial Project Protocol from defaults, overlays, and minimal generated fallback when necessary`
- tasks:
- [x] `T3.1 extend project setup context to resolve protocol generation inputs`
- [x] `T3.2 create initial Project Protocol during project setup`
- [x] `T3.3 apply multiple stack overlays when project shape requires them`
- [x] `T3.4 synthesize minimal initialization-time protocol content when seed coverage is insufficient`
- [x] `T3.5 persist project protocol documents and provenance during setup completion`
- [x] `T3.6 add setup integration tests for covered stacks, multi-overlay contexts, and missing-stack fallback`
- acceptance:
- `/project new always creates a Project Protocol`
- `supported setups receive a seeded protocol document family`
- `unsupported or weakly covered setups still receive minimal protocol content`
- `setup does not require a proposal-review step before the protocol becomes active`
- planned_commits:
- `feat(web): initialize project protocols during setup`
- `feat(web): add project protocol setup fallback`
- `test(integration): cover project protocol setup`

### Slice 4: Filesystem Materialization

- status: `merged`
- branch: `fix/slice-4-project-protocol-materialization`
- pr_title: `feat(slice-4): materialize project protocols`
- objective: `materialize Rails-owned Project Protocols automatically into AGENTS.md, .agents/*, and PLAYBOOKS.md using the existing repository pattern`
- tasks:
- [x] `T4.1 define canonical filesystem projection for the fixed protocol file skeleton`
- [x] `T4.2 generate AGENTS.md as the lightweight root entrypoint`
- [x] `T4.3 generate PLAYBOOKS.md as the playbook index`
- [x] `T4.4 generate detailed protocol documents under .agents/`
- [x] `T4.5 update materialized files automatically when Rails-backed protocol documents change`
- [x] `T4.6 add tests for initial materialization, update propagation, root placement, and one-way sync behavior`
- acceptance:
- `protocol files are created automatically in repository root and .agents/`
- `AGENTS.md stays lightweight and references the deeper protocol tree`
- `PLAYBOOKS.md indexes concrete playbook files`
- `filesystem projection updates when Rails protocol state changes`
- planned_commits:
- `feat(runtime): materialize project protocol files`
- `feat(web): sync project protocols to workspace`
- `test(integration): cover project protocol materialization`

### Slice 5: Project Protocol Management Surface

- status: `merged`
- branch: `fix/slice-5-project-protocol-management`
- pr_title: `Project Protocols web management surface`
- objective: `expose Protocols as a first-class project area with Markdown document editing focused on the concrete project protocol`
- tasks:
- [x] `T5.1 expose Protocols as a project area distinct from Documents`
- [x] `T5.2 render the protocol document list in canonical order`
- [x] `T5.3 allow Markdown editing of concrete Project Protocol documents`
- [x] `T5.4 keep user-facing UX constrained without review-state or regeneration controls`
- [x] `T5.5 ensure manual Rails edits propagate to filesystem projection`
- [x] `T5.6 add tests for protocol reads, writes, ordering, and materialization coupling`
- acceptance:
- `Protocols is a distinct project area`
- `users can inspect and edit the concrete Project Protocol in Markdown`
- `the UI remains document-oriented and low-configuration`
- `Rails edits continue to drive automatic filesystem updates`
- planned_commits:
- `feat(web): add project protocols area`
- `feat(web): edit project protocol documents`
- `test(web): cover project protocol management`

### Slice 6: Template Administration Follow-Up and Cycle Closure

- status: `pr_open`
- branch: `fix/slice-6-project-protocol-template-crud`
- pr_title: `feat(slice-6): manage project protocol templates`
- objective: `add near-term administration surfaces for common and stack templates, then close the cycle with full validation and residual-risk notes`
- tasks:
- [x] `T6.1 expose common template administration surface`
- [x] `T6.2 expose stack-template administration surface`
- [x] `T6.3 allow seeded template content to be extended or refined from Rails`
- [x] `T6.4 ensure template changes affect future setup composition without mutating existing project copies`
- [x] `T6.5 run full relevant tests and repository coverage from canonical locations`
- [x] `T6.6 publish cycle closure report with residual risks and post-cycle follow-up items`
- acceptance:
- `common and stack templates are manageable from Rails`
- `template editing does not rewrite existing project protocol copies`
- `future setups can consume refined templates`
- `cycle closes with full validation evidence`
- planned_commits:
- `feat(web): manage project protocol templates`
- `test(integration): cover project protocol templates`
- `docs(ops): close project protocol templates cycle`

## Global Exit Criteria

- Project Protocols are a Rails-owned project artifact.
- `/project new` always creates a concrete Project Protocol.
- Project Protocols are represented as multiple Markdown documents with document-level provenance.
- The fixed protocol file skeleton is materialized automatically into `AGENTS.md`, `.agents/*`, and `PLAYBOOKS.md`.
- `Protocols` is exposed as a project area distinct from `Documents`.
- The first UX remains document-oriented, Markdown-based, and low-configuration.
- Common behavior defaults and seeded stack overlays can produce useful project protocol content.
- Missing stack-template coverage still yields minimal usable protocol guidance.
- Template administration surfaces exist by cycle end without rewriting existing project protocol copies.
- Full relevant tests pass and coverage is maintained or increased.

## Validation Command Context

- Rails targeted tests must be run from `apps/web` with `bundle exec bin/rails test <paths>`.
- Ruby targeted tests must be run from repository root with `ruby -Itest <paths>`.
- Repository coverage must be run from repository root.
- Canonical repository coverage command: `bundle exec rake test:coverage`.
- PR validation entries must be reported as command plus `(pass)` or `(fail)`, without raw running traces.

## Non-Goals

- Do not implement Runtime Containers changes in this cycle.
- Do not implement hook-based agent enforcement in this cycle.
- Do not implement Anthropic-oriented harness-control strategies in this cycle.
- Do not add bidirectional filesystem-to-Rails sync in this cycle.
- Do not add protocol regeneration actions in the first project-facing surface.
- Do not start `dev -> main` alignment inside a slice.
