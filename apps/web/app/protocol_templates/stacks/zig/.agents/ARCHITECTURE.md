# Zig Architecture

This document describes Zig repository structure and ownership boundaries.

## Objective

Keep the Zig codebase explicit about memory ownership, build wiring, and boundary behavior without hiding complexity behind premature abstractions.

## Baseline structure

```text
build.zig     # canonical build, test, and artifact wiring
build.zig.zon # package metadata and dependencies when used
src/          # application and library source
test/         # broader integration tests when package-local tests are not enough
examples/     # small runnable examples when useful
docs/         # user-facing and technical documentation
.agents/      # collaboration and execution rules for this repository
AGENTS.md     # top-level agent operating contract
```

## Boundary rules

- Keep `build.zig` as the canonical place for build steps, test steps, examples, and install artifacts.
- Keep allocator ownership explicit at API boundaries.
- Separate pure logic from filesystem, process, network, and terminal adapters.
- Keep modules small enough that error sets, ownership, and lifetime expectations remain readable.
- Prefer explicit data structures and error unions over hidden global state.
- Tests can live near the code they validate; broader scenario tests may live under `test/`.

## Memory and errors

- Document ownership expectations for returned buffers, borrowed slices, and caller-owned allocations.
- Keep allocation and deallocation responsibilities visible in call sites or API docs.
- Use precise error sets when they clarify boundary behavior.
- Preserve error context by returning errors instead of collapsing distinct failures into a generic state.
- Avoid `catch unreachable` unless the invariant is local, obvious, and defensible.

## Change discipline

- Structural changes must be explicit in commit scope.
- Do not introduce broad framework layers or global registries without clear need.
- Prefer direct, readable Zig code before abstraction-heavy designs.
