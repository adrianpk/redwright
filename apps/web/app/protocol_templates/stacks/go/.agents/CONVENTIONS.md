# Go Conventions

- Format with `gofmt`; use MixedCaps identifiers and short lowercase package names.
- Prefer useful zero values and straightforward control flow. Keep error returns
  explicit; wrap with `%w` when callers need to inspect the original error.
- Use `errors.Is` and `errors.As` rather than matching error messages.
- Put a context first in functions that accept one. Avoid storing request
  contexts in long-lived structs.
- Use `defer` for cleanup after successful acquisition. Check close or flush
  errors when they affect whether an operation succeeded.
- Choose channels or locks for the actual synchronization need. Synchronize shared
  mutable state and document channel ownership before introducing goroutines.
- Use generics for repeated type-safe algorithms, rather than speculative APIs.

Reference: [Effective Go](https://go.dev/doc/effective_go).
