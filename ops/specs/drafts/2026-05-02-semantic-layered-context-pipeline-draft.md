# Semantic Layered Context Pipeline

## Status
Draft

## Conversation
- `../conv/2026-05-02-semantic-layered-context-pipeline-conv.md`

## Scope
- Define a deterministic and model-agnostic context construction pipeline for LLM payloads.
- Replace monolithic prompt assembly with layered, symbol-aware retrieval and structured compression.
- Establish a stable intermediate representation (IR) used across extraction, compression, and delivery.

## Source Context
- Current context delivery risks overloading payloads with raw code and conversational noise.
- Target behavior is higher signal density and lower token waste while preserving semantic correctness.
- The pipeline must degrade gracefully when structural tooling (Tree-sitter, LSP) is unavailable.

## Working Notes

### 1) Layered Context Strategy (Baseline Contract)
- provisional_status: `keep`
- current issue:
  - Context is often assembled as one monolithic prompt.
  - Large payloads reduce precision and increase irrelevant token usage.
- desired behavior:
  - Split context into tiers:
    - `CORE_TASK`
    - `CURRENT_FILE`
    - `DEPENDENCIES`
    - `GLOBAL_SIGNALS`
  - Always include:
    - core task
    - current file focus
  - Pull extra tiers only when required by objective or unresolved symbols.

### 2) Structural Extraction First (Default Mode)
- provisional_status: `keep`
- current issue:
  - Full-file inclusion is used even when only signatures/types are needed.
- desired behavior:
  - Use structural extraction as default.
  - Preferred tool order:
    - Tree-sitter
    - LSP enrichment (optional)
    - plain-text heuristics fallback
  - Extract by default:
    - function/class signatures
    - imports
    - type definitions
  - Avoid full implementations unless explicitly required.

### 3) Symbol-Level Retrieval (Selection Unit)
- provisional_status: `keep`
- current issue:
  - Retrieval is file-level instead of symbol-level.
- desired behavior:
  - Retrieve only relevant symbols:
    - specific functions
    - specific types
    - direct call/reference dependencies
  - Do not scan the whole project when task scope is local.
  - Build cross-file links only for referenced symbols.

### 4) Semantic Layer via LSP (Enrichment, Not Dependency)
- provisional_status: `keep`
- current issue:
  - Semantic resolution is either missing or treated as mandatory infrastructure.
- desired behavior:
  - Treat LSP as optional enrichment layer.
  - Use LSP for relevant symbols only:
    - symbol references
    - type information
    - cross-file relationships
  - Continue pipeline with deterministic fallbacks when LSP is unavailable.

### 5) Documentation-First Signal Prioritization
- provisional_status: `keep`
- current issue:
  - Implementations are used as first source even when high-value docs already define contracts.
- desired behavior:
  - Prioritize docs over implementation when both exist.
  - Extract structured documentation signals:
    - GoDoc / JavaDoc / Elixir docs / docstrings
    - contracts
    - constraints
    - examples
  - Keep summaries compact; skip verbose prose.

### 6) Repository Topology Snapshot (Lightweight)
- provisional_status: `keep`
- current issue:
  - Model often lacks architectural orientation without excessive code inclusion.
- desired behavior:
  - Include minimal repository map:
    - depth-limited directory tree
    - module boundaries
  - Provide topology as context scaffold, not code dump.

### 7) Stable Intermediate Representation (IR)
- provisional_status: `keep`
- current issue:
  - Payload structure varies between runs and models.
- desired behavior:
  - Use a consistent IR schema per request with fixed sections:
    - `TASK`
    - `CURRENT_FILE`
    - `AVAILABLE_SYMBOLS`
    - `DOC_HINTS`
    - `ERRORS`
    - `REPO_MAP`
  - Prefer compact structured format (minimal JSON or flat text schema).
  - Keep deterministic field naming and ordering across model providers.

### 8) Two-Pass Compression Pipeline
- provisional_status: `keep`
- current issue:
  - Raw extraction is either sent directly or over-compressed without guarantees.
- desired behavior:
  - Pass 1: raw extraction (Tree-sitter / LSP / docs / build-test signals).
  - Pass 2: LLM-assisted condensation into:
    - key constraints
    - relevant APIs
    - recent failures
  - Hard preservation rules during compression:
    - signatures
    - types
    - invariants
  - Compression removes redundancy, never semantics.

### 9) Execution Feedback as Structured Signals
- provisional_status: `keep`
- current issue:
  - Compiler/test logs are included as raw blocks with low density.
- desired behavior:
  - Normalize diagnostics into compact tuples:
    - `file -> line -> error_code(optional) -> short_message`
  - Include:
    - compiler errors
    - test failures
  - Include raw logs only when structured tuples are insufficient.

### 10) Sliding Window with Task Anchoring
- provisional_status: `keep`
- current issue:
  - Entire history is resent, including conversational noise.
- desired behavior:
  - Keep only:
    - current objective
    - last N relevant execution steps
  - Drop irrelevant dialogue from payload assembly.
  - Assume zero memory between calls; every payload must be self-sufficient.

### 11) Tool Discovery and Graceful Fallbacks
- provisional_status: `keep`
- current issue:
  - Pipeline robustness depends on specific tooling availability.
- desired behavior:
  - Runtime capability chain:
    - try Tree-sitter
    - enrich with LSP when available
    - fallback to text parsing heuristics
  - No hard dependency on a single parser or language server.

### 12) Optional Caching for Iterative Runs
- provisional_status: `keep`
- current issue:
  - Repeated extraction recomputes stable signals across iterations.
- desired behavior:
  - Cache reusable artifacts:
    - AST summaries
    - symbol maps
    - doc extracts
  - Reuse cache when unchanged and contextually valid.

## Open Questions
- What should `N` be for sliding window retention by default (for example fixed count vs token budget)?
- Should IR be serialized primarily as JSON, flat text schema, or dual-mode with strict equivalence?
- Which invalidation strategy should govern cache refresh (mtime, git diff, hash of extraction inputs)?
- What is the minimum required diagnostic schema across all supported language toolchains?

## Out of Scope
- Language-specific parser implementation details.
- UI/UX for context inspection dashboards.
- Provider-specific prompt tuning for a single model family.

## Next Iteration Inputs
- Convert this draft into implementation slices for `extract -> structure -> compress -> select -> send`.
- Define concrete IR examples and validation checks.
- Define acceptance tests that verify signature/type/invariant preservation after compression.
