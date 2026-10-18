# Engineering Discipline

This document defines a cross-stack approach for ordinary application work. It
focuses on explicit design, bounded behavior, invariant protection, and honest
validation without prescribing language-specific implementation rules.

## Purpose

Prefer software that is safe, correct, predictable, and easy to maintain.
Seek simplicity through deliberate design rather than through deferred
complexity.

Use this document when designing, implementing, or reviewing behavior with
meaningful correctness, resource, concurrency, or maintenance consequences.
Repository and stack-specific rules define the concrete techniques.

## Explicit Design

- Keep control flow, state changes, ownership, and dependencies visible.
- Prefer direct and cohesive code over framework magic, hidden work, or
  speculative abstraction.
- Give each behavior one clear owner and keep cross-boundary orchestration
  close to the workflow that needs it.
- Name concepts, operations, and states precisely. Avoid names that hide a
  domain decision behind a technical implementation detail.
- Keep functions and scopes small enough that a reviewer can reason about all
  relevant state and branches together. Split only along real responsibilities.

## Bounded Work and Resources

- Identify meaningful limits before implementation: input sizes, result sets,
  pagination, timeouts, retries, concurrency, queue depth, retention, and
  resource-pool capacity.
- Make those limits explicit in configuration, contracts, validation, or
  persistence constraints where they apply.
- Do not introduce unbounded accumulation, background work, recursion, or
  retry behavior without a documented and enforceable limit.
- Treat cancellation, deadlines, cleanup, and ownership of external resources
  as part of the behavior rather than incidental implementation details.

## Invariants and Failures

- Distinguish expected operating failures from programmer errors and impossible
  states.
- Handle expected failures explicitly and return useful context without leaking
  secrets or private data.
- Express durable invariants at more than one appropriate boundary when
  practical: domain validation, persistence constraints, transaction logic,
  transport validation, and tests.
- Validate both the positive space that is allowed and the negative space that
  must be rejected.
- Do not use recovery, fallback, or silent error suppression to continue from
  corruption or an invariant violation. Apply the repository and language
  conventions for fail-fast behavior.

## Design Before Debt

- Resolve discovered structural problems while the design is active. Do not
  make intentional technical debt, TODOs, compatibility wrappers, or generic
  layers the default delivery strategy.
- A smaller complete capability is preferable to a broad shallow surface.
- Add abstractions, dependencies, tools, and indirection only when they solve
  a demonstrated current problem with a clear owner and lifecycle.
- Explain why a non-obvious design choice exists, especially when it protects
  an invariant, limit, or failure boundary.

## Validation and Performance

- Apply `.agents/LINTING.md` for proportional coverage, real integration
  boundaries, execution cost, and retry selection. Thoroughness does not mean
  multiplying tests or building a separate validation framework for each change.
- Test workflows at the boundaries that make their contracts real. Include
  valid behavior, invalid behavior, transitions, permissions, idempotency, and
  concurrency where relevant.
- Prefer the real persistence, transport, rendering, or external boundary when
  it is necessary to establish confidence in the delivered behavior.
- Use fuzzing, race detection, fault injection, property testing, benchmarks,
  or simulation when the risk justifies them. These techniques complement a
  precise model; they do not replace it.
- Before consequential performance or capacity choices, make a rough resource
  sketch for latency, throughput, memory, storage, network, and CPU as
  applicable. Measure with repository-native tools before optimizing hot paths.

## Cross-Stack Adaptation

- Do not mechanically adopt rules that depend on a different runtime or
  language, such as static-only allocation, zero dependencies, fixed function
  lengths, or a particular integer type policy.
- In garbage-collected runtimes, control allocation and resource lifetime on
  meaningful paths; prevent unbounded growth and release external resources
  deterministically.
- In application systems, use concrete infrastructure and dependencies when
  they are justified, but keep their configuration, failure modes, and
  operational limits explicit.
- Stack-specific conventions may strengthen this approach. They may not weaken
  its requirements for explicit ownership, enforceable limits, invariant
  protection, and honest validation.
