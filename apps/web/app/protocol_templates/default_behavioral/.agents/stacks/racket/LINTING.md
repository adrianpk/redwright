# Racket Quality-Gate Overlay

Apply this overlay with `.agents/LINTING.md`. Use actual module and package
names, and let repository-owned commands override these examples.

## Baseline Commands

- Compile changed modules: `raco make <module.rkt> ...`.
- Run test submodules recursively: `raco test -x .`.
- Run a focused test: `raco test <module-or-test.rkt>`.
- Run the documented entry module when executable behavior changes.

## Package and Documentation Checks

- For a package, use `raco test -p <package>` when package-scope validation is
  part of the project workflow.
- Verify runtime, build, test, and documentation dependencies in `info.rkt`.
- Render `.scrbl` manuals with `raco scribble` or the repository wrapper.
- Use an isolated package scope for installation or setup validation. Do not
  mutate the user's default Racket package scope implicitly.

## Test and Diagnostic Rules

- Treat RackUnit failures, uncaught exceptions, non-zero exits, and configured
  timeout or stderr failures as test failures.
- Restore parameters, ports, environment variables, current directories,
  custodians, and other ambient state changed by tests.
- Keep filesystem, process, network, GUI, thread, and place tests isolated.
- Use formatter, static analysis, macro expansion, Typed Racket, parallel test,
  or distribution checks only when configured or relevant.
