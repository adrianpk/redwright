# Determinism Boundaries With LLM Routing

RedWright is deterministic in persistence and control flow, but intentionally non-deterministic in LLM-driven reasoning.

The design goal is controlled variability, not full determinism.

## Deterministic Surfaces

The following are deterministic by contract:

- storage schema and migration behavior,
- project/workstream/task persistence transitions,
- slash-command control semantics,
- path safety constraints for mutating actions,
- startup rehydration ordering.

## Non-Deterministic Surface

LLM routing and planning output can vary by:

- model stochasticity,
- language phrasing,
- contextual interpretation.

This variability is expected and constrained rather than removed.

## Boundary Enforcement

RedWright enforces boundaries so LLM output cannot redefine runtime contracts:

- strict planner output schema,
- allowed action type catalog,
- operational command precedence,
- persistence integrity checks,
- bounded execution attempts in change loops.

## Failure Containment

When LLM output is invalid or low-confidence, runtime should degrade to:

- clarification requests,
- fallback decisions,
- blocked execution with explicit reason,
- no unsafe mutation outside allowed scope.

## Why This Matters

A coding harness cannot rely on deterministic language generation alone.

The reliable strategy is:

- deterministic runtime skeleton,
- bounded LLM freedom inside that skeleton,
- explicit persistence and control invariants.

That is the practical boundary where autonomy and safety coexist.
