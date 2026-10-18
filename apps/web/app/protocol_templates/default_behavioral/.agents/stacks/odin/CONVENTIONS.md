# Odin Conventions Overlay

Apply this overlay with `.agents/CONVENTIONS.md`.

## Dependencies and Imports

- Prefer Odin's `base`, `core`, and applicable `vendor` collections before
  external code.
- Pin vendored dependencies and record source, version, license, and local
  modifications because Odin has no official package manager.
- Use package-relative imports or named library collections consistently with
  repository-owned build commands.
- Use import aliases only to resolve collisions or clarify a boundary.
- Prefer free procedures owned by their package; do not emulate methods,
  classes, or inheritance layers.

## Types, Failures, and Memory

- Prefer explicit conversions and named types. Use `distinct` when
  representation-compatible values must remain semantically separate.
- Use multiple returns for expected failures and `or_return` only when direct
  propagation preserves enough context.
- Reserve `assert`, `panic`, and divergent paths for broken invariants.
- Avoid broad `using` declarations and parameters that obscure ownership or
  name resolution.
- Prefer useful zero values. Use `---` only when every read follows complete
  initialization.
- Keep `rawptr`, `transmute`, pointer conversion, and foreign calling
  conventions at narrow documented boundaries.
- Pass an allocator when it is part of the procedure contract; otherwise use
  `context.allocator` deliberately.
- Pair `new` with `free` and `make` with `delete`. Place lexical cleanup after
  successful acquisition with `defer`.
- Do not return references to storage whose allocator lifetime ends before the
  caller finishes using it.

## Testing

- Use `core:testing` and `@(test)` procedures with one `^testing.T` parameter.
- Use focused expectations through `testing.expect`, `testing.expectf`, or
  `testing.expect_value`.
- Test allocator behavior and cleanup responsibilities when relevant.
- Use `testing.T.seed` for useful randomized coverage and report it on failure.
- Account for parallel test execution and synchronize shared process state.
- Prefer `defer` for ordinary cleanup; use `testing.cleanup` only when cleanup
  must survive catastrophic test failure.
