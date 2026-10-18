# Racket Architecture Overlay

Apply this overlay with `.agents/ARCHITECTURE.md` and
`.agents/ENGINEERING_DISCIPLINE.md`.

```text
*.rkt        # modules
main.rkt     # optional executable entry module
info.rkt     # optional package and collection metadata
scribblings/ # package-owned Scribble manuals
tests/       # separate cross-module or integration tests
```

- Preserve the established file, module, collection, and package layout.
- Treat every `.rkt` file as a module with intentional `#lang`, `require`, and
  `provide` boundaries.
- Use `module+ test` and `module+ main` when behavior belongs with the enclosing
  module but executes in a distinct context.
- Do not add collection or package structure when file-relative modules are
  sufficient.
- Keep package metadata in `info.rkt` when distribution, setup, tests, or
  documentation require it.
- Avoid cyclic module dependencies; extract a shared contract only for a real
  shared responsibility.
- Do not import Go directory conventions into Racket or create a package,
  collection, unit, class, or language layer without a concrete need.

## Effects and Runtime

- Use `parameterize` for bounded changes to dynamically scoped parameters.
- Keep thread, place, custodian, eventspace, and port ownership explicit.
- Use `dynamic-wind`, custodians, or repository-native cleanup when lexical
  control flow is insufficient.
- Keep macro-expansion dependencies and runtime dependencies phase-explicit.
