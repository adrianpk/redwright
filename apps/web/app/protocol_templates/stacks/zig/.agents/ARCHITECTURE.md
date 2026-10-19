# Zig Architecture

This document describes Zig repository structure and resource ownership.

- Follow the project's `build.zig` module graph and toolchain version. Keep
  executable assembly separate from reusable modules when the program needs both.
- Make allocation and returned memory ownership visible in APIs. Choose arenas,
  general-purpose allocators, or caller buffers to match actual lifetimes.
- Keep error unions and optional values precise enough for callers to handle.
- Use ordinary structs and functions before introducing generic interfaces or
  extensive compile-time machinery.
- Keep C ABI declarations and pointer conversions at explicit boundaries with
  documented ownership and alignment requirements.
- Do not assume a standard library API from a different Zig version.

Reference: [Zig language reference](https://ziglang.org/documentation/master/).
