# Zig Validation

- Run `zig fmt --check` on changed Zig files using the supported compiler version.
- Run `zig build test` when defined, or `zig test <file>` for focused module tests.
  Build affected targets with the repository's own build steps.
- Use `std.testing` assertions and its test allocator for allocation-sensitive
  tests. Exercise cleanup after partial failure and allocation failure when relevant.
- Check error variants, invalid inputs, and borrowed-memory lifetimes at boundaries.
- Run the configured safety modes and target builds when arithmetic, undefined
  behavior, or target assumptions change. Do not substitute a newer compiler
  merely because a documented command fails on the pinned version.

Reference: [Zig testing](https://ziglang.org/documentation/master/#Zig-Test).
