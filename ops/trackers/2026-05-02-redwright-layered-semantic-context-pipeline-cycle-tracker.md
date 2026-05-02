# Cycle Tracker: RedWright Layered Semantic Context Pipeline Implementation

## Metadata

- cycle_id: `cycle-2026-05-02-redwright-layered-semantic-context-pipeline`
- status: `in_progress`
- state: `awaiting_review`
- updated: `2026-05-02`
- active_slice: `Slice 2`
- active_task: `T2.3`
- source_plan: `ops/plans/2026-05-02-redwright-layered-semantic-context-pipeline-implementation-cycle-plan.md`

## Slice Progress

### Slice 1: Capability Contract and Stable IR V1

- status: `completed`
- branch: `feat/slice-1-semantic-capability-contract-and-ir-v1`
- PR: `https://codeberg.org/adrianpk/redwright/pulls/235`
- merge_target: `dev`
- last_sync_commit: `21ccf5f`

Tasks:

- [x] `T1.1 define capability contract for parser_mode/lsp_mode with explicit preferred and fallback states`
- [x] `T1.2 define stable IR v1 sections and deterministic field ordering`
- [x] `T1.3 add contract tests for schema and ordering invariants`

Commits:

- [x] `31514e4 feat(runtime): define semantic capability contract and ir v1 schema`
- [x] `3d01c87 test(runtime): cover ir schema and deterministic ordering invariants`

Validation:

- [x] `ruby -Itest test/redwright/iteration_context_packet_builder_test.rb (pass)`

### Slice 2: Tree-sitter Structural Extraction Baseline

- status: `awaiting_review`
- branch: `feat/slice-2-semantic-treesitter-structural-extraction`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `b73fee4`

Tasks:

- [x] `T2.1 add tree-sitter extraction adapter for primary repository languages`
- [x] `T2.2 emit structural units as symbol records in IR`
- [x] `T2.3 add extraction tests for signatures/imports/types coverage`

Commits:

- [x] `c7fa634 feat(runtime): add tree-sitter structural extraction adapter`
- [x] `d6e6290 test(runtime): cover tree-sitter symbol extraction outputs`

Validation:

- [x] `ruby -Itest test/redwright/tree_sitter_structural_extractor_test.rb && ruby -Itest test/redwright/iteration_context_packet_builder_test.rb (pass)`

### Slice 3: LSP Enrichment Layer and Cross-File Semantics

- status: `pending`
- branch: `fix/slice-3-semantic-lsp-enrichment-layer`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T3.1 add lsp enrichment adapter for references and type hints`
- [ ] `T3.2 attach enriched edges to symbol-level IR nodes`
- [ ] `T3.3 add tests for enrichment boundaries and deterministic output shape`

Commits:

- [ ] `<sha> feat(runtime): add lsp semantic enrichment layer`
- [ ] `<sha> test(runtime): cover lsp enrichment boundaries and output determinism`

Validation:

- [ ] `lsp enrichment boundary suite pass`

### Slice 4: Deterministic Fallback Extractors

- status: `pending`
- branch: `fix/slice-4-semantic-deterministic-fallback-extractors`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T4.1 add plain-text heuristic extractor fallback preserving IR schema`
- [ ] `T4.2 implement capability downgrade states without runtime abort`
- [ ] `T4.3 add fallback tests for schema parity and graceful degradation`

Commits:

- [ ] `<sha> feat(runtime): add deterministic semantic fallback extractors`
- [ ] `<sha> test(runtime): cover capability downgrade and schema parity`

Validation:

- [ ] `fallback extractor parity suite pass`

### Slice 5: Layered Retrieval and Symbol-Level Selection

- status: `pending`
- branch: `fix/slice-5-semantic-layered-symbol-selection`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T5.1 implement layered retrieval tiers CORE_TASK CURRENT_FILE DEPENDENCIES GLOBAL_SIGNALS`
- [ ] `T5.2 implement symbol-scoped dependency expansion with strict bounds`
- [ ] `T5.3 add tests for retrieval prioritization and bounded expansion`

Commits:

- [ ] `<sha> feat(runtime): add layered symbol-level context selection`
- [ ] `<sha> test(runtime): cover layered retrieval prioritization and bounds`

Validation:

- [ ] `layered selection and bounded expansion suite pass`

### Slice 6: Documentation-First Signal Prioritization

- status: `pending`
- branch: `fix/slice-6-semantic-documentation-priority`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T6.1 add doc hint extraction and normalization contract`
- [ ] `T6.2 integrate doc-priority scoring into layered retrieval`
- [ ] `T6.3 add tests for docs-first precedence and compact hint payloads`

Commits:

- [ ] `<sha> feat(runtime): prioritize documentation signals in semantic context selection`
- [ ] `<sha> test(runtime): cover documentation-priority retrieval behavior`

Validation:

- [ ] `docs-first retrieval suite pass`

### Slice 7: Two-Pass Compression and Semantic Preservation

- status: `pending`
- branch: `fix/slice-7-semantic-two-pass-compression`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T7.1 implement pass-1 structural aggregate and pass-2 semantic compression`
- [ ] `T7.2 enforce preservation invariants for signatures/types/contracts`
- [ ] `T7.3 add regression tests preventing semantic-loss compression`

Commits:

- [ ] `<sha> feat(runtime): add two-pass semantic context compression`
- [ ] `<sha> test(runtime): enforce semantic-preservation compression invariants`

Validation:

- [ ] `two-pass compression invariant suite pass`

### Slice 8: Structured Feedback and Error Signal Integration

- status: `pending`
- branch: `fix/slice-8-semantic-structured-feedback-signals`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T8.1 extend feedback normalizer to compact file/line/code/message tuples`
- [ ] `T8.2 inject diagnostic signals into layered retrieval scoring`
- [ ] `T8.3 add tests for structured-feedback impact on context selection`

Commits:

- [ ] `<sha> feat(runtime): add structured feedback signals for semantic context selection`
- [ ] `<sha> test(runtime): cover diagnostic normalization and selection influence`

Validation:

- [ ] `structured feedback integration suite pass`

### Slice 9: Runtime Integration, Caching, and End-to-End Validation

- status: `pending`
- branch: `fix/slice-9-semantic-runtime-integration-and-e2e`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T9.1 integrate semantic pipeline into iteration context packet assembly`
- [ ] `T9.2 add cache for structural/symbol/doc artifacts with deterministic invalidation`
- [ ] `T9.3 run end-to-end validation suite and update operational evidence`

Commits:

- [ ] `<sha> feat(runtime): integrate layered semantic context pipeline into runtime packet assembly`
- [ ] `<sha> docs(ops): close semantic context pipeline cycle with validation evidence`

Validation:

- [ ] `cd ~/Projects/redwright/redwright && bundle exec rake test:coverage`

## Coverage Guard

- baseline_coverage: `maintain_or_improve`
- target_rule: `post-cycle coverage >= pre-cycle coverage`

## Event Log

- `2026-05-02` state=`planned` note=`semantic layered context pipeline cycle tracker initialized from draft and prior semantic packet v2 baseline`
- `2026-05-02` state=`awaiting_review` note=`Slice 1 completed with semantic capability mode contract, stable IR v1 sections, and deterministic schema ordering tests`
- `2026-05-02` state=`slice_merged` note=`Slice 1 merged to dev`
- `2026-05-02` state=`awaiting_review` note=`Slice 2 completed with tree-sitter structural extraction adapter and AVAILABLE_SYMBOLS emission in IR v1`
