# ADR-007: Runtime Reliability Guardrails v1

## Status
Accepted

## Date
2026-04-29

## Context
Factory-mode execution introduces concurrent runs, long-running sandbox steps, and cross-environment state transfer. Current runtime behavior can fail in ways that are hard to isolate when lifecycle boundaries are implicit.

## Decision
Adopt explicit reliability guardrails in the runtime/application boundary.

1. Step-scoped timeouts
- Every lifecycle step uses an explicit timeout policy.
- Timeouts are modeled with step-specific error types.

2. Worktree concurrency locking
- Named worktrees must use lock files with stale-lock recovery.
- Collision fails fast with a deterministic error.

3. Abort and cancellation contract
- Run-level cancellation must stop in-flight execution safely.
- Cancellation must preserve diagnostic state needed for recovery.

4. Prompt safety boundary
- Inline prompts are treated as literal content.
- Template interpolation/expansion only applies to explicit template files.

5. Session transfer contract
- Session artifacts support host/sandbox transfer with deterministic path rewriting.
- Session continuity is opt-in and auditable.

## Consequences

### Positive
- Lower risk of hidden hangs and concurrency corruption.
- Better failure diagnosis and deterministic recovery paths.
- Safer prompt handling against accidental interpolation side effects.

### Negative
- Higher implementation complexity in lifecycle orchestration.
- Additional test matrix for timeout/cancel/recovery combinations.
