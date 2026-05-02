# Cycle Plan: RedWright Layered Semantic Context Pipeline Implementation

## Metadata

- cycle_id: `cycle-2026-05-02-redwright-layered-semantic-context-pipeline`
- status: `planned`
- owner: `adrianpk`
- created: `2026-05-02`
- updated: `2026-05-02`
- goal: `implement layered semantic context assembly with symbol-level retrieval, preferred Tree-sitter/LSP enrichment, deterministic fallbacks, and stable IR delivery`
- scope: `feature`
- source_draft: `ops/specs/drafts/2026-05-02-redwright-layered-semantic-context-pipeline-draft.md`

## Slice List

### Slice 1: Capability Contract and Stable IR V1

- status: `pending`
- branch: `feat/slice-1-semantic-capability-contract-and-ir-v1`
- objective: `define canonical semantic capability contract and deterministic IR schema`
- tasks:
- [ ] `T1.1 define capability contract for parser_mode/lsp_mode with explicit preferred and fallback states`
- [ ] `T1.2 define stable IR v1 sections and deterministic field ordering`
- [ ] `T1.3 add contract tests for schema and ordering invariants`
- acceptance:
- `runtime can emit deterministic IR v1 independent of extraction backend`
- planned_commits:
- `feat(runtime): define semantic capability contract and ir v1 schema`
- `test(runtime): cover ir schema and deterministic ordering invariants`

### Slice 2: Tree-sitter Structural Extraction Baseline

- status: `pending`
- branch: `feat/slice-2-semantic-treesitter-structural-extraction`
- objective: `implement Tree-sitter-first extraction for signatures/imports/types`
- tasks:
- [ ] `T2.1 add tree-sitter extraction adapter for primary repository languages`
- [ ] `T2.2 emit structural units as symbol records in IR`
- [ ] `T2.3 add extraction tests for signatures/imports/types coverage`
- acceptance:
- `structural extraction uses tree-sitter when available and emits bounded symbol records`
- planned_commits:
- `feat(runtime): add tree-sitter structural extraction adapter`
- `test(runtime): cover tree-sitter symbol extraction outputs`

### Slice 3: LSP Enrichment Layer and Cross-File Semantics

- status: `pending`
- branch: `feat/slice-3-semantic-lsp-enrichment-layer`
- objective: `add LSP enrichment for references/types with bounded cross-file expansion`
- tasks:
- [ ] `T3.1 add lsp enrichment adapter for references and type hints`
- [ ] `T3.2 attach enriched edges to symbol-level IR nodes`
- [ ] `T3.3 add tests for enrichment boundaries and deterministic output shape`
- acceptance:
- `LSP enrichment is preferred when available and preserves deterministic bounded payload behavior`
- planned_commits:
- `feat(runtime): add lsp semantic enrichment layer`
- `test(runtime): cover lsp enrichment boundaries and output determinism`

### Slice 4: Deterministic Fallback Extractors

- status: `pending`
- branch: `feat/slice-4-semantic-deterministic-fallback-extractors`
- objective: `ensure no-block fallback behavior when Tree-sitter or LSP is unavailable`
- tasks:
- [ ] `T4.1 add plain-text heuristic extractor fallback preserving IR schema`
- [ ] `T4.2 implement capability downgrade states without runtime abort`
- [ ] `T4.3 add fallback tests for schema parity and graceful degradation`
- acceptance:
- `pipeline continues with deterministic fallback output when preferred tools are unavailable`
- planned_commits:
- `feat(runtime): add deterministic semantic fallback extractors`
- `test(runtime): cover capability downgrade and schema parity`

### Slice 5: Layered Retrieval and Symbol-Level Selection

- status: `pending`
- branch: `feat/slice-5-semantic-layered-symbol-selection`
- objective: `replace file-first selection with layered symbol-level retrieval`
- tasks:
- [ ] `T5.1 implement layered retrieval tiers CORE_TASK CURRENT_FILE DEPENDENCIES GLOBAL_SIGNALS`
- [ ] `T5.2 implement symbol-scoped dependency expansion with strict bounds`
- [ ] `T5.3 add tests for retrieval prioritization and bounded expansion`
- acceptance:
- `context selection is symbol-scoped and layered with deterministic bounds`
- planned_commits:
- `feat(runtime): add layered symbol-level context selection`
- `test(runtime): cover layered retrieval prioritization and bounds`

### Slice 6: Documentation-First Signal Prioritization

- status: `awaiting_review`
- branch: `fix/slice-6-semantic-documentation-priority`
- objective: `prioritize contracts/docs signals over implementation snippets when both exist`
- tasks:
- [ ] `T6.1 add doc hint extraction and normalization contract`
- [ ] `T6.2 integrate doc-priority scoring into layered retrieval`
- [ ] `T6.3 add tests for docs-first precedence and compact hint payloads`
- acceptance:
- `docs-first signals are explicitly prioritized without violating context bounds`
- planned_commits:
- `feat(runtime): prioritize documentation signals in semantic context selection`
- `test(runtime): cover documentation-priority retrieval behavior`

### Slice 7: Two-Pass Compression and Semantic Preservation

- status: `awaiting_review`
- branch: `fix/slice-7-semantic-two-pass-compression`
- objective: `add two-pass compression preserving signatures/types/invariants`
- tasks:
- [ ] `T7.1 implement pass-1 structural aggregate and pass-2 semantic compression`
- [ ] `T7.2 enforce preservation invariants for signatures/types/contracts`
- [ ] `T7.3 add regression tests preventing semantic-loss compression`
- acceptance:
- `compressed packet remains semantically dense and invariant-safe`
- planned_commits:
- `feat(runtime): add two-pass semantic context compression`
- `test(runtime): enforce semantic-preservation compression invariants`

### Slice 8: Structured Feedback and Error Signal Integration

- status: `pending`
- branch: `fix/slice-8-semantic-structured-feedback-signals`
- objective: `normalize execution feedback into structured diagnostics and feed selection`
- tasks:
- [ ] `T8.1 extend feedback normalizer to compact file/line/code/message tuples`
- [ ] `T8.2 inject diagnostic signals into layered retrieval scoring`
- [ ] `T8.3 add tests for structured-feedback impact on context selection`
- acceptance:
- `retry payloads include structured diagnostics and improve relevance deterministically`
- planned_commits:
- `feat(runtime): add structured feedback signals for semantic context selection`
- `test(runtime): cover diagnostic normalization and selection influence`

### Slice 9: Runtime Integration, Caching, and End-to-End Validation

- status: `pending`
- branch: `fix/slice-9-semantic-runtime-integration-and-e2e`
- objective: `integrate semantic pipeline into runtime packet builder with bounded caching and e2e verification`
- tasks:
- [ ] `T9.1 integrate semantic pipeline into iteration context packet assembly`
- [ ] `T9.2 add cache for structural/symbol/doc artifacts with deterministic invalidation`
- [ ] `T9.3 run end-to-end validation suite and update operational evidence`
- acceptance:
- `runtime uses semantic layered packets in planning/execution loops with passing e2e coverage`
- planned_commits:
- `feat(runtime): integrate layered semantic context pipeline into runtime packet assembly`
- `docs(ops): close semantic context pipeline cycle with validation evidence`

## Global Exit Criteria

- `semantic context pipeline is layered and symbol-first by default`
- `Tree-sitter and LSP are preferred capabilities with explicit fallback semantics`
- `IR schema is stable and deterministic across capability modes`
- `two-pass compression preserves signatures types and invariants`
- `structured diagnostics influence retry context selection deterministically`
- `end-to-end runtime validation remains green with maintained quality gates`

## Validation Command Context

- `bundle exec rake test:coverage` must be executed from repository root (`~/Projects/redwright/redwright`).
