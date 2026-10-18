# Ruby Conventions Overlay

Apply this overlay with `.agents/CONVENTIONS.md`.

- Prefer the Ruby standard library and existing project tooling before adding
  gems.
- Prefer plain Ruby objects for workflows that do not need a framework base
  class.
- Use cohesive objects or modules for multi-step behavior.
- Keep reusable library behavior under `lib/` and executable coordination under
  `bin/` when the repository uses those boundaries.
- Use the repository's configured Ruby test framework and idioms.
- Avoid controller or CLI branches that hide a multi-step workflow.
