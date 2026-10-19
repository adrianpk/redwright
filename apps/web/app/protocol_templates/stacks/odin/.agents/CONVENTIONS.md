# Odin Conventions

## Procedures and values

- Follow the package's naming style; prefer descriptive procedure names and
  explicit data arguments. Avoid broad `using` declarations that hide origins.
- Use named types or `distinct` types when representation alone cannot express
  a meaningful domain distinction.
- Design useful zero values. Use uninitialized storage only when every read
  follows complete initialization.
- Represent expected failure with explicit return values, errors, or tagged
  results. Use `or_return` when direct propagation retains the required context.
- Reserve assertions and panics for violated invariants, rather than ordinary
  invalid input or unavailable resources.

## Memory and integration

- Use `context.allocator` deliberately; accept an allocator explicitly when its
  choice is part of the public procedure contract.
- State whether returned slices, strings, pointers, and containers are borrowed
  or owned. Never let temporary or arena-backed storage outlive its allocator.
- Pair allocation with the appropriate cleanup: `new` with `free`, and `make`
  with `delete`. Place `defer` after successful resource acquisition.
- Prefer applicable `core` and `vendor` packages before adding dependencies.
  Record the version and license of externally vendored code.
- Keep `rawptr`, `transmute`, and foreign calling conventions localized and
  justify the invariants that make them valid.

References: [Language overview](https://odin-lang.org/docs/overview/),
[memory package](https://pkg.odin-lang.org/core/mem/).
