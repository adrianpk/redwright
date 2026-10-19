# Odin Documentation

- Document packages through their public procedures, data types, and usage
  examples. Explain invariants and ownership that signatures cannot express.
- Include allocator expectations, borrowed versus owned return values, cleanup
  responsibilities, and invalidation rules for views into mutable storage.
- Show the actual entry package and import collections used by the repository.
  Document required compiler defines, build tags, target settings, and foreign
  libraries when they affect the example.
- Explain error return values and the caller's recovery options.
- Keep runnable examples aligned with the repository's pinned compiler and
  commands; do not assume a package manager or a universal directory layout.

Reference: [Odin packages and commands](https://odin-lang.org/docs/overview/).
