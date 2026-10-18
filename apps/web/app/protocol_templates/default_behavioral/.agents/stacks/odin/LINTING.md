# Odin Quality-Gate Overlay

Apply this overlay with `.agents/LINTING.md`. Replace `.` with the actual
package or entry directory, and let repository-owned commands override these
examples.

## Baseline Commands

- Compile: `odin check .`.
- Vet: `odin check . -vet -warnings-as-errors`.
- Test: `odin test .`.
- Build an affected executable: `odin build .`.
- Use `-file` only for an intentional single-file package.

## Package and Diagnostic Rules

- Use `odin test <test-dir> -all-packages` only with an aggregator that imports
  the relevant package graph.
- Keep `@require import` test aggregators aligned with that graph.
- Treat leaks, bad frees, timeouts, assertions, panics, and signals reported by
  the test runner as failures.
- Preserve `ODIN_TEST_RANDOM_SEED` when reproducing randomized failures.
- Prefer compiler-owned checking, vetting, and diagnostics before external
  lint tools.

## Configured Extensions

- Add focused vet flags, unused-procedure analysis, OLS or formatter checks,
  target builds, sanitizers, or WebAssembly validation only when configured or
  relevant to the changed target.
- Use `-strict-style` only when the repository intentionally follows the Odin
  compiler's enforced style.
