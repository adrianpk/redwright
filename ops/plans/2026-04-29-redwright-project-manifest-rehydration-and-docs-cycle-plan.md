# Cycle Plan: RedWright Project Manifest Rehydration and Docs

## Metadata

- owner: `adrianpk`
- status: `draft`
- scope: `runtime`
- objective: `make .redwright/manifest.yml canonical and rehydratable, then document behavior with Diataxis-aligned technical docs`
- tracker: `ops/trackers/2026-04-29-redwright-project-manifest-rehydration-and-docs-cycle-tracker.md`

## Slice List

### Slice 1: Manifest Schema V1

- status: `completed`
- branch: `feat/slice-1-manifest-schema-v1`
- [x] `T1.1 define manifest keys and required fields`
- [x] `T1.2 add schema_version and migration compatibility rules`
- [x] `T1.3 define project provenance fields for clone/new flows`
- [x] `T1.4 add parser/validator tests`

### Slice 2: Manifest Writer on Project New

- status: `pending`
- branch: `feat/slice-2-manifest-writer-project-new`
- [ ] `T2.1 create .redwright/manifest.yml on project creation`
- [ ] `T2.2 write deterministic defaults and normalized identifiers`
- [ ] `T2.3 ensure idempotent re-runs do not corrupt manifest`
- [ ] `T2.4 add tests for creation/update behavior`

### Slice 3: Manifest Writer on Repo Clone

- status: `pending`
- branch: `feat/slice-3-manifest-writer-repo-clone`
- [ ] `T3.1 create manifest on clone completion`
- [ ] `T3.2 persist clone source metadata (remote url/provider/ref)`
- [ ] `T3.3 register aliases/context from cloned project name`
- [ ] `T3.4 add tests for clone registration + manifest consistency`

### Slice 4: Runtime Rehydration Precedence Model

- status: `pending`
- branch: `feat/slice-4-runtime-rehydration-precedence`
- [ ] `T4.1 define precedence: manifest -> sqlite context -> fallback`
- [ ] `T4.2 implement deterministic startup rehydration routine`
- [ ] `T4.3 handle missing/invalid manifest with explicit recovery path`
- [ ] `T4.4 add tests for cold-start and reset-db scenarios`

### Slice 5: Prompt Context Integration from Manifest

- status: `pending`
- branch: `feat/slice-5-prompt-context-integration-manifest`
- [ ] `T5.1 consume manifest for project/architecture/quality context`
- [ ] `T5.2 keep fallback behavior when manifest omits fields`
- [ ] `T5.3 add tests ensuring no regression in context packet quality`

### Slice 6: Docs Reference Set

- status: `pending`
- branch: `feat/slice-6-docs-reference-set`
- [ ] `T6.1 add docs/reference/project-manifest.md`
- [ ] `T6.2 add docs/reference/slash-commands.md`
- [ ] `T6.3 add docs/reference/runtime-persistence-contract.md`

### Slice 7: Docs How-To Set

- status: `pending`
- branch: `feat/slice-7-docs-howto-set`
- [ ] `T7.1 add docs/how-to/bootstrap-project-context.md`
- [ ] `T7.2 add docs/how-to/clone-and-register-project.md`
- [ ] `T7.3 add docs/how-to/recover-runtime-state-after-db-reset.md`

### Slice 8: Docs Explanation Set

- status: `pending`
- branch: `feat/slice-8-docs-explanation-set`
- [ ] `T8.1 add docs/explanation/manifest-vs-sqlite-state-model.md`
- [ ] `T8.2 add docs/explanation/operational-vs-task-intent-model.md`
- [ ] `T8.3 add docs/explanation/determinism-boundaries-with-llm-routing.md`

## Exit Criteria

- Project manifest is schema-versioned and reliably produced for new and cloned projects.
- Runtime can rehydrate project context deterministically after restart/reset.
- Prompt context uses manifest fields where present without breaking fallbacks.
- Diataxis docs cover contracts, procedures, and rationale with implementation-aligned content.
