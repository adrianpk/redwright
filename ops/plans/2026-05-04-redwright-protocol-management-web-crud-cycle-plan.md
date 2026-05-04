# Cycle Plan: RedWright Protocol Management Web CRUD

## Metadata

- cycle_id: `cycle-2026-05-04-redwright-protocol-management-web-crud`
- status: `implemented_pending_review`
- owner: `adrianpk`
- created: `2026-05-04`
- updated: `2026-05-04`
- goal: `deliver a coherent Rails web CRUD experience for project Protocols, global Protocol Templates, and Playbooks that preserves the current product language while raising the design quality to a professional and harmonious level`
- scope: `feature`
- source_spec: `ops/specs/specs/2026-05-04-redwright-protocol-management-web-crud-spec.md`
- source_conversation:
  - `ops/specs/conv/2026-05-04-redwright-protocol-management-web-crud-conv.md`
  - `ops/specs/conv/2026-05-04-redwright-protocol-management-web-crud-conv-raw.md`

## Slice List

### Slice 1: Project Protocol Navigation and Canonical Index

- status: `merged`
- branch: `fix/slice-1-protocol-management-project-index`
- pr_title: `feat(slice-1): add project protocols navigation and canonical index`
- objective: `expose Protocols as a top-level Rails area and render the project-scoped canonical card index, including empty-card handling for missing entries and PLAYBOOKS entry routing`
- tasks:
- [ ] `T1.1 add Protocols top-level navigation alongside Boards and Documents`
- [ ] `T1.2 render project Protocols as a card-based canonical index aligned with the existing Documents interaction model`
- [ ] `T1.3 show AGENTS plus the .agents-backed protocol entries in one unified Protocol view`
- [ ] `T1.4 represent missing canonical entries as empty cards with direct create actions rather than generic add flows`
- [ ] `T1.5 treat PLAYBOOKS as a special card that routes to a dedicated Playbooks subview`
- [ ] `T1.6 add controller and integration coverage for navigation, canonical ordering, and empty-card behavior`
- acceptance:
- `Protocols appears in the top navigation`
- `the project Protocol index is card-based and recognizably consistent with current product surfaces`
- `missing canonical entries render as empty cards`
- `PLAYBOOKS routes into its own subview`
- planned_commits:
- `feat(web): add protocols navigation and project index`
- `test(web): cover project protocol index navigation`

### Slice 2: Project Protocol Read-Edit Surface and Playbooks

- status: `merged`
- branch: `fix/slice-2-protocol-management-project-editing`
- pr_title: `feat(slice-2): add project protocol editing flow`
- objective: `deliver the low-ceremony project Protocol editing experience with combined read-edit screens, explicit save, autosave, last-save feedback, and fixed-set Playbooks management`
- tasks:
- [ ] `T2.1 replace show-then-edit ceremony with a combined read-edit Protocol screen`
- [ ] `T2.2 keep explicit Save while adding autosave behavior and visible last-successful-save feedback`
- [ ] `T2.3 ensure project Protocol creation is limited to missing canonical entries and disallows duplicate canonical types within one project set`
- [ ] `T2.4 allow deletion and later recreation of canonical project Protocol entries`
- [ ] `T2.5 implement the dedicated project Playbooks subview using the fixed canonical set`
- [ ] `T2.6 add tests for project Protocol create, edit, autosave, delete, recreate, and Playbooks flows`
- acceptance:
- `project Protocols can be read and edited in the same screen`
- `explicit Save and autosave coexist`
- `last successful save is visible`
- `project Playbooks are managed through a dedicated subview`
- planned_commits:
- `feat(web): add project protocol editing flow`
- `feat(web): add project protocol autosave and playbooks`
- `test(web): cover project protocol editing flows`

### Slice 3: Global Template Administration Surfaces

- status: `merged`
- branch: `fix/slice-3-protocol-management-template-surfaces`
- pr_title: `feat(slice-3): add protocol template management surfaces`
- objective: `deliver Settings-based Common and Stack Protocol Template management with one-screen-per-stack behavior, canonical-entry CRUD rules, and stack-set creation beyond seeded defaults`
- tasks:
- [ ] `T3.1 add Settings entry points for Common Protocol Templates and Stack Protocol Templates as separate cards`
- [ ] `T3.2 align Common Protocol Template management with the same card and low-ceremony editing model used for project Protocols`
- [ ] `T3.3 implement one-screen-per-stack template management rather than a combined cross-stack editor`
- [ ] `T3.4 support creating new stack template sets by stack identity and seeding empty canonical entries`
- [ ] `T3.5 apply the fixed-set PLAYBOOKS subview pattern to template management with playbooks treated as common-only in MVP`
- [ ] `T3.6 add tests for template navigation, stack-set creation, duplicate prevention within a set, delete and recreate, and Playbooks routing`
- acceptance:
- `Protocol Templates live under Settings rather than top navigation`
- `Common and Stack template entry points are separate cards`
- `stack template management is one screen per stack set`
- `new stack template sets can be created beyond seeded defaults`
- planned_commits:
- `feat(web): add protocol template settings surfaces`
- `feat(web): add stack template set creation`
- `test(web): cover protocol template management`

### Slice 4: Visual Harmonization and Validation Closure

- status: `implemented`
- branch: `fix/slice-4-protocol-management-visual-harmonization`
- pr_title: `feat(slice-4): harmonize protocol management UI`
- objective: `raise the Protocol management surfaces to a professional visual quality while preserving harmony with the current app and close the cycle with full validation evidence`
- tasks:
- [ ] `T4.1 harmonize spacing, typography, card treatment, and form hierarchy across Protocols, Protocol Templates, and Playbooks`
- [ ] `T4.2 eliminate any generic scaffold-like or outdated model-form presentation from the new Protocol management surfaces`
- [ ] `T4.3 avoid introducing a disconnected trend-driven redesign that clashes with current Documents and neighboring views`
- [ ] `T4.4 verify that semantic stack cues and save-state feedback remain legible without overcrowding cards`
- [ ] `T4.5 run targeted and full relevant validation from canonical command locations`
- [ ] `T4.6 publish cycle closure artifacts with residual risks and follow-up notes`
- acceptance:
- `the new Protocol surfaces feel professionally designed rather than scaffold-generated`
- `the UI is visually harmonious with current product surfaces`
- `forms do not resemble a 2006 model admin`
- `the UI also does not break consistency with an unrelated 2026 redesign language`
- planned_commits:
- `feat(web): harmonize protocol management styling`
- `test(web): validate protocol management flows`
- `docs(ops): close protocol management web CRUD cycle`

## Global Exit Criteria

- `Protocols` is exposed as a top-level Rails area distinct from `Documents`
- project Protocols use a canonical card index with empty-card handling for missing entries
- project Protocol editing is direct and low-ceremony, with explicit save and autosave
- PLAYBOOKS is managed through dedicated subviews rather than inline blocks
- Protocol Templates are managed under `Settings` through separate Common and Stack entry points
- stack template sets can be created beyond seeded defaults
- duplicate canonical entries are prevented within a managed set, while delete and recreate remain allowed
- the resulting surfaces are visually harmonious with the current app and meet a professional design bar
- targeted and full relevant validation pass and are recorded explicitly

## Validation Command Context

- Rails targeted tests must be run from `apps/web` with `bundle exec bin/rails test <paths>`.
- Repository coverage and broader quality checks must be run from repository root when required by the active slice.
- Validation entries must be reported as command plus `(pass)` or `(fail)`.

## Non-Goals

- Do not change the underlying Protocol concept in this cycle.
- Do not redesign filesystem materialization rules in this cycle.
- Do not introduce an open-ended arbitrary Protocol file manager in MVP.
- Do not create a third independent Playbook template category.
- Do not adopt a one-off visual language that breaks harmony with the existing app.
