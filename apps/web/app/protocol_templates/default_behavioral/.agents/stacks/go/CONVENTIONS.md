# Go Conventions Overlay

Apply this overlay with `.agents/CONVENTIONS.md`.

- Prefer the standard library before external modules.
- Keep package-local types unexported unless a public contract requires them.
- Return errors with useful context without hiding the original cause.
- Use small interfaces only at boundaries with a real substitution need.
- Use `New...` for constructors and keep parameter order stable within a
  package.
- Use Godoc for exported symbols when it helps callers understand a contract.
- Use Go's `testing` package by default, keep tests beside their package, and
  prefer fakes to broad mocks.
- Avoid generic `util` packages, public packages created for internal
  convenience, and stringly typed contracts when structs or named types fit.
