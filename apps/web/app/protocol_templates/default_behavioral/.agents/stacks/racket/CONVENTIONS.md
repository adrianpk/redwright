# Racket Conventions Overlay

Apply this overlay with `.agents/CONVENTIONS.md`.

## Language and Modules

- Preserve the selected `#lang`; do not replace `racket/base`, Typed Racket, a
  teaching language, or a project language with `racket` implicitly.
- Prefer the selected language and distribution libraries before external
  packages.
- Manage package dependencies through `info.rkt` and `raco pkg`, separating
  runtime, build, test, and documentation dependencies.
- Keep `require` and `provide` declarations near the module boundary.
- Avoid `all-defined-out` in reusable libraries.
- Use `only-in`, `except-in`, `rename-in`, or `prefix-in` when they clarify or
  narrow an import boundary.
- Use `contract-out` when runtime checking and blame materially protect a
  public boundary.
- Use `struct-out` only when the representation and generated operations are
  intentionally public.
- Declare macro phase dependencies with `for-syntax`, `for-template`, or the
  applicable phase level.

## Naming, Data, and Failures

- Use lowercase hyphenated names. End predicates with `?`, mutations with `!`,
  conversions with `->`, and ambient parameters with a `current-` prefix.
- Prefer immutable values and pure procedures unless mutation has a clear
  owner and purpose.
- Add `#:transparent` only when transparent representation, equality, and
  inspection are part of the contract.
- Use explicit values for ordinary alternatives and exceptions for failures
  that cannot be handled as ordinary results at that boundary.
- Use contract violations for provider or caller contract failures, not normal
  domain validation.
- Catch the narrowest useful exception type and preserve context when wrapping.
- Keep continuation marks and non-local control flow at narrow documented
  boundaries.

## Macros and Tests

- Prefer procedures and data unless syntax, binding, evaluation order, or a
  language extension requires a macro.
- Preserve lexical scope and report syntax errors at the caller's source
  location.
- Test expansion and runtime behavior separately when both form the contract.
- Use RackUnit unless the repository defines another framework.
- Use `module+ test` for tests that need enclosing private definitions and
  separate modules for public, package, or integration behavior.
- Isolate parameter, port, filesystem, process, and environment changes in
  tests.
