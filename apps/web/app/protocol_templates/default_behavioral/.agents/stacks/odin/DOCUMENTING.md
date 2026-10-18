# Odin Documentation Overlay

Apply this overlay with `.agents/DOCUMENTING.md` and `.agents/LANGUAGE.md`.

- Keep commands aligned with actual package roots, library collections,
  command-line defines, build tags, and entry packages.
- Use `-file` only when one `.odin` file intentionally forms a complete package.
- Use exact import paths, package declarations, and public declaration names.
- Use `odin doc` or repository-owned tooling when generated API reference is
  part of the workflow.
- Document public declarations, allocator expectations, ownership transfer,
  cleanup, context use, error returns, thread safety, lifetime constraints,
  platform constraints, and ABI contracts when callers depend on them.
- For vendored dependencies and bindings, record upstream source, pinned
  version, license, generation procedure, and local patches.
