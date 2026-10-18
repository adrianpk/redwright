# Odin Architecture Overlay

Apply this overlay with `.agents/ARCHITECTURE.md` and
`.agents/ENGINEERING_DISCIPLINE.md`.

## Package Layout

```text
*.odin  # a small single-package program can remain at repository root
src/    # optional application packages when already established
vendor/ # pinned third-party source and bindings
tests/  # cross-package or integration harnesses when needed
```

- Do not introduce `src/` or `tests/` only to match this example.
- Treat a directory as one Odin package with one package declaration.
- Keep `package main` focused on process configuration, dependency assembly,
  lifecycle, and top-level control flow.
- Use `@(private)` and `@(private="file")` to narrow Odin's public-by-default
  declarations.
- Isolate foreign imports, ABI details, raw pointers, and platform-specific
  integration behind owned package boundaries.
- Keep conditional files, platform suffixes, build tags, and command-line
  defines beside the package behavior they select.
- Do not import Go, C++, or Rust directory conventions into an Odin repository.

## Runtime and Memory Ownership

- Give every allocated resource an explicit owner, allocator policy, and
  cleanup point.
- Treat implicit `context` as dynamically scoped runtime state and override it
  only within a bounded scope.
- Keep arena, pool, tracking, temporary, and persistent allocation strategies
  explicit at package or workflow boundaries.
- Keep thread startup, synchronization, cancellation, and teardown visible.
