# Linting and Quality Gates

This document owns test design, validation scope, execution cost, and retries
across stacks. Use the lightest gate that protects the changed behavior and
its affected contracts. Validation cost is part of engineering quality.

## Baseline checks

- Syntax, type, compile, or static checks for changed files when the stack provides them.
- Targeted tests for changed behavior.
- Broader checks only when affected dependencies or shared behavior justify them.

## Optional stricter checks

If enabled by project setup:
- formatter checks
- lint/static analysis checks
- type checks
- coverage checks

## Test Design

- Use the repository-native test framework and commands.
- Prefer integration tests with real application boundaries for delivered
  workflows. Use isolated, owned databases, storage, and services; reuse the
  project's existing fixture approach before adding tools or dependencies.
- Use unit tests selectively for business rules, calculations, algorithms, or
  other local behavior with a specific, inexpensive regression signal. Do not
  generate a test for every function, type, or file.
- Keep end-to-end tests to representative critical user journeys. Exercise
  variants at the lowest-cost layer that can establish the contract instead
  of repeating a complete application journey for every case.
- Prefer real dependencies over mocks and fakes. Use a test double only for a
  concrete boundary limitation or failure that real fixtures cannot exercise
  reasonably, and state what its evidence cannot establish.
- Reuse or extend an existing test before adding overlapping coverage. Each
  new test must detect a plausible defect not adequately covered already.
- Use table-driven or parameterized tests for deterministic rules, state
  transitions, policy decisions, mappings, parsers, and calculations.
- Cover expected failures, edge cases, boundary contracts, and input
  immutability when relevant.
- For a bug fix, reproduce the defect with a failing test first when practical.
- Select additional techniques from demonstrated risk and available tooling:
  property tests for broad invariants; fuzz tests for parsers and untrusted
  input; mutation testing for uncertain branch coverage; concurrency tests for
  shared state; benchmarks for measured performance paths; and focused
  integration tests for persistence, transport, provider, browser, or external
  boundaries.
- Avoid tests of incidental formatting, inert implementation details, language
  behavior, or a dependency's own internals. Do not add unrelated test ceremony.

## Execution Cost

- Batch tests through the native package or suite runner. Do not launch a
  separate build or test process per case by default. Isolate a root only when
  its resource ownership or failure diagnosis requires it.
- Reuse expensive setup where isolation remains reliable. Keep mutable state
  isolated and cleanup owned; do not trade correctness for shared fixtures.
- Wait for observable conditions with finite deadlines instead of fixed sleeps
  or production-length delays. Use controlled clocks where they fit the contract.
- Do not multiply all tests across tags, configurations, providers, or layers
  without identifying distinct behavior that needs each execution.
- Before materially expanding a gate, inspect existing timings and explain the
  expected cost and added protection in the existing plan or report. Measure
  expensive paths with existing tools; do not build a new measurement framework.
- Treat hours-long routine delivery gates as a design problem to investigate,
  not an automatic cost of quality. Do not silently increase timeouts or retry
  budgets to accommodate accumulated test work.

## Hook policy

If git hooks are configured, pre-commit should run fast checks only:
- changed-file syntax checks
- targeted tests where possible

## Delivery Validation

- During implementation and slice review, use syntax, compile, static, and
  narrowly selected behavior checks. Reserve the combined integration and
  representative end-to-end gate for the end of the delivery set.
- Define that gate from the set's behavior and affected dependencies during
  planning. Include shared-contract regressions when the changes can affect
  them. Do not append every previous set's journeys, chain historical gates,
  or execute every discovered repository test automatically.
- A growing repository suite must not automatically make each set's mandatory
  gate grow. Broaden selection for demonstrated impact, not repository age.
- Run the selected gate against the exact integrated candidate. Keep exhaustive
  repository validation for deliberate global checks, scheduled workflows,
  release requirements, or changes whose impact justifies that scope. Follow
  repository-specific required commands; an unavailable nightly workflow alone
  is not a reason to expand a delivery gate.
- Preserve active controller ownership and frozen gate definitions. Do not
  interrupt running validation or change its acceptance conditions as a shortcut.

## Failure and Retry

- Read the failure and reproduce it with the smallest useful check. Verify the
  correction there before considering a broader rerun.
- Choose the rerun scope from the correction's impact. Repeat an exhaustive
  gate only when an explicit requirement or affected contracts justify it;
  do not restart hours of unrelated checks mechanically after every failure.
- Keep evidence tied to its actual candidate, commands, configuration, and
  environment. Reuse only evidence valid under the repository or controller
  contract; never relabel a previous candidate's result as a current pass.
- When required validation fails and repository changes are needed, follow the
  delivery repair branch and pull-request workflow. An environmental failure
  alone does not justify an empty repair pull request.

## Rules

- Do not leave changed behavior without appropriate validation.
- Fix failing checks before declaring work complete.
- Do not disable tests, weaken assertions, or hide failures to meet a runtime
  target. Before removing redundant coverage, identify the retained protection
  and any behavior that would otherwise lose coverage.
- Report validation commands and outcomes explicitly.
- Distinguish focused checks from the full suite and distinguish local,
  emulator, CI, and production evidence.

## Project-specific commands

- Keep canonical validation commands in project documentation or tooling.
- Prefer commands that can run from the repository root without hidden local setup.

## Protocol Contract Validation

After changing the global agent contract, run:

```text
.agents/scripts/validate-contracts.sh
```

This check validates internal document references, the playbook index, stack
overlay registration, contract ownership sentinels, obsolete terminology, and
whitespace in the active protocol files.
