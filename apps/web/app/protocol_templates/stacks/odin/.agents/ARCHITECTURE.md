# Odin Architecture

## Packages and entrypoints

- Organize source around directory-based packages with cohesive data and
  procedures. A small application can remain one package at the repository root.
- Keep package dependencies acyclic. Introduce packages for distinct ownership
  or reusable behavior, rather than reproducing another language's directory tree.
- Keep entrypoints responsible for assembling application state, choosing
  allocators, and coordinating startup and cleanup.
- Expose a narrow set of procedures and types. Use package privacy for details
  that callers should not depend on.

## State and resources

- Keep data representation, state transitions, and resource ownership visible.
  Prefer structs, unions, and ordinary procedures over simulated class hierarchies.
- Choose allocation lifetimes deliberately: per operation, per frame, or for the
  owning component. Keep allocator reset and destruction with that owner.
- Separate computation from filesystem, networking, and foreign-library calls
  where this makes the boundary easier to validate.
- Keep foreign declarations and pointer conversions at explicit boundaries;
  document the corresponding ABI, ownership, and cleanup requirements.

Reference: [Odin overview](https://odin-lang.org/docs/overview/).
