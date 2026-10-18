# Go Architecture Overlay

Apply this overlay with `.agents/ARCHITECTURE.md` and
`.agents/ENGINEERING_DISCIPLINE.md`.

## Package Layout

```text
cmd/       # executable assembly entrypoints
internal/  # application code private to the module
pkg/       # contracts intentionally shared outside the module
assets/    # embedded schemas, templates, manifests, and non-code inputs
testdata/  # package-owned fixtures
```

- Keep `cmd/` packages focused on process configuration, dependency assembly,
  startup, and shutdown.
- Default application behavior to `internal/`.
- Use `pkg/` only for intentionally external contracts or libraries.
- Keep tests beside the package they validate and fixtures in package-owned
  `testdata/`.
- Group embedded assets under `assets/` or an owning package.

## Runtime Assembly

- Use deterministic assembly order.
- Keep constructors limited to dependencies and lightweight configuration.
- Put failable initialization in explicit setup or start paths.
- Expose readiness, health, and context-aware shutdown at operationally
  significant package boundaries.
