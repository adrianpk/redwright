# RedWright

RedWright is a Ruby runtime agent for software engineering work.

It receives natural-language requests (currently via Telegram), resolves the active project context, plans a structured turn, and executes safe, bounded actions inside the project workspace.

## What RedWright Does

- interprets user intent into a strict runtime plan
- validates planner output before execution
- executes filesystem, shell, and git primitives with guardrails
- persists runtime state and action evidence in SQLite
- emits traces for ingress, planning, execution, and persistence

## Runtime Boundaries

- execution is constrained to the active project/worktree boundary
- invalid or ambiguous context yields clarify/error responses instead of unsafe execution
- action execution follows explicit contracts (`id`, `type`, `args`, confirmation, timeout, failure policy)

## Interaction Model

- the user sends a request in natural language
- RedWright normalizes and validates the turn plan
- RedWright executes allowed actions and returns a concise runtime response

RedWright is designed to evolve into a modular coding agent runtime with strict contracts between planning, validation, normalization, execution, and traceability layers.

<!-- REDWRIGHT_LOCAL_BADGES:START -->
## Local Quality Badges

| Check | Status | Color |
|---|---|---|
| lint | PASS | green |
| test | PASS | green |
| summary | PASS | green |
<!-- REDWRIGHT_LOCAL_BADGES:END -->
