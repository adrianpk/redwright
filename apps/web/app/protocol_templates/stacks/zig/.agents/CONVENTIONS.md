# Zig Conventions

- Follow `zig fmt` and the naming conventions of the existing Zig code.
- Pass allocators when an API allocates, or document the owning allocator when
  it is part of a stateful type.
- Use `defer` for unconditional cleanup and `errdefer` for rollback during partial
  initialization. Free owned allocations at the corresponding lifetime boundary.
- Use `try` and `catch` to make error handling visible. Reserve `unreachable`
  for locally established invariants, not untrusted input or inconvenient errors.
- Treat slices as borrowed views unless the API explicitly transfers ownership.
  Avoid returning references to temporary storage.
- Use `comptime` and `anytype` for concrete reuse needs; keep generated behavior
  understandable from the call site.

Reference: [Zig language reference](https://ziglang.org/documentation/master/).
