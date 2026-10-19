# Zig Documentation

- Use declaration doc comments for public APIs and module comments for orientation.
- Document allocation ownership, borrowed slice lifetimes, alignment, error sets,
  and cleanup responsibilities.
- State the supported Zig version and actual `build.zig` steps; build and standard
  library interfaces vary between releases.
- Explain compile-time parameters and target-specific behavior when callers need
  them to use an API correctly.
- Keep examples valid for the supported toolchain and include cleanup where
  allocation occurs. Document C interop assumptions at the foreign boundary.

Reference: [Zig documentation comments](https://ziglang.org/documentation/master/#Comments).
