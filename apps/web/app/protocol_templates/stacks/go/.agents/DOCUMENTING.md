# Go Documentation

- Write doc comments for exported contracts, beginning with the declared name.
  Add a package comment when readers need orientation beyond individual APIs.
- Document errors, context cancellation, goroutine safety, ownership, and whether
  a zero value is usable when these affect callers.
- Use `Example` tests for small runnable API examples; include expected output
  when the example should also verify behavior.
- Keep import paths, module requirements, build tags, and command entrypoints
  accurate. Describe optional tools separately from standard Go commands.
- Explain how to stop background work and release returned resources.

Reference: [Go doc comments](https://go.dev/doc/comment).
