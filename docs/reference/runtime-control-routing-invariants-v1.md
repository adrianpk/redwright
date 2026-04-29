# Runtime Control Routing Invariants V1

## Scope

This document defines deterministic precedence for runtime control routing in telegram ingress.

## Invariants

1. Direct control slashes are resolved before planner interpretation.
2. Explicit `control_intent` from planner output has precedence over `operational_intent`.
3. Inferred natural-language control is allowed only when planner `intent` is `meta`.
4. Operational slash commands are routed through deterministic dispatcher paths.
5. When both control and operational intents are present, control wins and operational control mapping is ignored.

## Expected Outcomes

- `/pause`, `/resume`, `/cancel` always trigger runtime control directly.
- `control_intent=cancel_task` always maps to `stop` regardless of non-meta intent noise.
- `operational_intent=task_resume` does not override an explicit control intent.
