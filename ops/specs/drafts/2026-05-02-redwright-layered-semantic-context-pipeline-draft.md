# RedWright Layered Semantic Context Pipeline

## Status
Draft

## Conversation
- `2026-05-02-redwright-layered-semantic-context-pipeline-conv.md`

## Scope
- Define a repository-grounded context pipeline for LLM payload construction in runtime planning/change loops.
- Replace file-heavy monolithic packet composition with layered, symbol-aware, and deterministic context assembly.
- Establish a stable intermediate representation (IR) that can be formalized into a spec and implemented incrementally.

## Source Context
- Current context packet behavior (`lib/redwright/iteration_context_packet_builder.rb`) is deterministic but file-snippet centric.
- Current prompt context loader (`lib/redwright/prompt_context_loader.rb`) provides project/architecture/workspace sections with manifest and AGENTS fallbacks.
- Current workspace snapshot (`lib/redwright/workspace_snapshot_builder.rb`) already provides lightweight topology but not semantic/module boundaries.
- Current failure normalization (`lib/redwright/feedback_normalizer.rb`) classifies failure classes but does not provide structured file/line diagnostics.

## Working Notes

### 1) Current-State Baseline (What Exists)
- provisional_status: `keep`
- current issue:
  - Existing packet v2 is useful but optimized for bounded text transfer, not semantic retrieval.
- desired behavior:
  - Preserve existing deterministic guardrails:
    - bounded packet size
    - bounded tree entries
    - bounded file payload
  - Reuse current packet architecture as migration base.

### 2) Layered Context Contract (Target Retrieval Strategy)
- provisional_status: `keep`
- current issue:
  - Context assembly is not explicitly tiered by necessity.
- desired behavior:
  - Introduce strict tiers:
    - `CORE_TASK`
    - `CURRENT_FILE`
    - `DEPENDENCIES`
    - `GLOBAL_SIGNALS`
  - Always include:
    - core task
    - current file
  - Include remaining tiers only when symbol/task relevance requires it.

### 3) Structural Extraction by Default
- provisional_status: `keep`
- current issue:
  - Packet currently includes file snippets, not structural signatures/types/imports.
- desired behavior:
  - Default extraction output should prioritize:
    - function/class signatures
    - imports
    - type definitions
  - Full implementations are included only when explicitly required.

### 4) Symbol-Level Retrieval as Primary Unit
- provisional_status: `keep`
- current issue:
  - Retrieval is currently file-level selection (`significant_files` + snippets).
- desired behavior:
  - Move selection unit from files to symbols.
  - Retrieve only relevant functions/types and minimal cross-file dependencies.
  - Avoid full project scans during local-scope tasks.

### 5) Semantic Enrichment Layer (LSP Optional)
- provisional_status: `keep`
- current issue:
  - No dedicated semantic resolution layer for references/types across files.
- desired behavior:
  - Add optional LSP-backed enrichment for relevant symbols:
    - references
    - type resolution
    - cross-file links
  - LSP is enhancement only, not a hard runtime dependency.

### 6) Documentation-First Signal Priority
- provisional_status: `keep`
- current issue:
  - Runtime context does not prioritize contract-heavy docs over implementation details.
- desired behavior:
  - When docs and implementation both exist, docs are prioritized for context payload.
  - Extract structured doc hints:
    - contracts
    - constraints
    - examples
  - Avoid verbose prose blocks.

### 7) Stable Intermediate Representation (IR)
- provisional_status: `keep`
- current issue:
  - Current packet uses text serialization and implicit keys, not fixed model-agnostic IR sections.
- desired behavior:
  - Adopt stable IR sections:
    - `TASK`
    - `CURRENT_FILE`
    - `AVAILABLE_SYMBOLS`
    - `DOC_HINTS`
    - `ERRORS`
    - `REPO_MAP`
  - Enforce deterministic ordering and compact structure.

### 8) Repository Topology as Lightweight Architecture Signal
- provisional_status: `keep`
- current issue:
  - Topology exists but lacks explicit module-boundary orientation.
- desired behavior:
  - Preserve depth-limited tree behavior.
  - Extend to include module boundary hints without large code payload.

### 9) Two-Pass Compression Policy
- provisional_status: `keep`
- current issue:
  - Current trimming is byte-budget truncation, not semantic condensation.
- desired behavior:
  - Pass 1: raw structural extraction + optional semantic/doc/diagnostic enrichment.
  - Pass 2: compression into high-density payload preserving:
    - signatures
    - types
    - invariants
  - Compression removes redundancy, not semantics.

### 10) Structured Execution Feedback Contract
- provisional_status: `keep`
- current issue:
  - Failures are currently flattened to coarse strings and classes.
- desired behavior:
  - Normalize compiler/test diagnostics to compact records:
    - `file -> line -> error_code(optional) -> short_message`
  - Keep raw logs out of packet by default; include only when disambiguation is needed.

### 11) Sliding Window and Task Anchoring
- provisional_status: `keep`
- current issue:
  - History management is implicit and can drift toward noisy context inclusion.
- desired behavior:
  - Explicitly include only:
    - current objective
    - last N relevant steps
  - Drop conversational noise.
  - Assume zero memory between calls; each payload remains self-sufficient.

### 12) Tool Chain and Graceful Fallback
- provisional_status: `keep`
- current issue:
  - No explicit extraction fallback chain is defined.
- desired behavior:
  - Capability sequence:
    - Tree-sitter
    - LSP enrichment (when available)
    - plain-text structural heuristics
  - No hard dependency on any single tool.

### 13) Optional Caching for Iterative Runtime Loops
- provisional_status: `keep`
- current issue:
  - Repeated turns recompute stable context components.
- desired behavior:
  - Cache reusable artifacts:
    - AST summaries
    - symbol maps
    - doc summaries
  - Invalidate based on deterministic change signals.

## Open Questions
- Which default retention policy should define `N` for sliding window (`count` vs `token budget`)?
- Should IR canonical encoding be JSON-only, text-only, or dual-mode with strict equivalence tests?
- Which cache invalidation strategy is preferred for runtime safety (`mtime`, content hash, or git diff-based)?
- Which first target language(s) should receive structural extraction coverage in phase one?

## Out of Scope
- Full language-by-language parser correctness parity.
- Provider-specific prompt tuning.
- Full-repository semantic indexing for every turn.

## Next Iteration Inputs
- Convert this draft into formal spec with explicit contracts and acceptance criteria.
- Define migration slices for `IterationContextPacketBuilder` from packet `v2` toward layered IR.
- Define deterministic tests for semantic-preservation invariants during compression.
