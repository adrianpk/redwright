# Go Architecture

This document describes Go repository structure and package ownership.

- Begin with a package or module that fits the application. Use `cmd/` for
  multiple commands and `internal/` for implementation packages when useful;
  a public library does not require a `pkg/` directory.
- Name packages for the capability they provide. Keep imports acyclic and avoid
  catch-all `util`, `common`, or `types` packages.
- Define small interfaces near their consumers when substitution is needed.
  Return concrete types unless callers benefit from an interface.
- Constructors may return errors when acquiring resources; make ownership and
  cleanup clear. Add separate lifecycle methods only for actual lifecycle needs.
- Give every goroutine an owner, an exit condition, and a way to observe failure.
  Propagate cancellation through `context.Context` for request-scoped work.

Reference: [Module layout](https://go.dev/doc/modules/layout).
