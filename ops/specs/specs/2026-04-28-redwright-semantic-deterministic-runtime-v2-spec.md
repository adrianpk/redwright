# Redwright Semantic Deterministic Runtime V2 Specification

## Status

- type: `spec`
- date: `2026-04-28`
- scope: `runtime workflow model`
- goal: `deterministic state machine with semantic LLM appendices and bounded convergence loops`

## 1. Design Principle

Redwright runtime is a deterministic state machine.

LLM-powered behaviors are allowed only as semantic appendices behind strict contracts:

- typed request envelope
- typed response envelope
- bounded retries and timeouts
- explicit terminal reason

No language-specific hardcoded branching is allowed in core runtime routing.

## 2. Runtime Operating Modes

Runtime MUST support two compatible interaction modes:

- structured mode:
  - alignment session
  - planning
  - slicing
  - implementation flow (branch/commit/pr lifecycle)
- direct mode:
  - request-specific execution (example: "fix bug X in project Y")

Mode selection is inferred semantically and remains overridable by explicit user intent.

## 3. Deterministic State Machine

### 3.1 Required States

- `ingress_received`
- `context_resolution`
- `context_gap_collection`
- `alignment_active`
- `planning_active`
- `execution_active`
- `verification_active`
- `delivery_ready`
- `blocked`
- `clarify_wait`
- `user_paused`

### 3.2 Required Terminal Reasons

- `converged`
- `needs_clarification`
- `blocked_by_constraints`
- `max_attempts`
- `timeout`
- `user_stopped`

All transitions MUST be validated against a static transition contract.

## 4. Semantic Request Packet to LLM

Each LLM call MUST include:

- `agent_context`
- `project_context`
- `architecture_context`
- `task_prompt`
- `workspace_tree_snapshot` (tree-like view)
- `selected_files` (heuristic-selected file payloads)
- `error_context` (compile/test/runtime failures from prior attempt)
- `loop_metadata` (`attempt_index`, `max_attempts`, `deadline`)

Packet payload must be bounded by configurable limits.

## 5. Semantic Response Packet from LLM

Response MUST be strict JSON with no extra keys:

- `intent`
- `normalized_goal`
- `gaps`
- `questions`
- `actions`
- `verification_plan`
- `confidence`
- `stop_or_continue`

Where:

- `gaps` are missing facts detected by model
- `questions` are generated only for unresolved high-impact gaps
- `actions` are runtime-contract actions only (or macro actions that normalize deterministically)

## 6. Gap Handling and Dynamic Clarification

Gap handling MUST be semantic and non-mechanical.

Rules:

- if project name is inferred but not explicit:
  - ask confirmation: inferred candidate + yes/no or corrected value
- if user response includes multiple gap answers in one turn:
  - system MUST consume all satisfied gaps and avoid re-asking solved items
- if ambiguity remains after normalization:
  - ask one high-value clarification at a time

No fixed language-specific question trees are allowed in core flow.

## 7. Project Identity and Naming Policy

When creating/switching project context:

- infer candidate name from user text
- ask confirmation before creation when explicit name absent
- persist confirmed canonical name
- attach aliases extracted from user phrasing

Example behavior:

- user: "build a tic-tac-toe app"
- system: "I inferred project name `tic-tac-toe`. Confirm or provide another name."

## 8. Multi-Stack Strategy Without Hardcoded If-Chains

Stack-specific details (go module, package manager, build/test commands, etc.) are handled by semantic planning + tool evidence.

Runtime core constraints:

- no router conditionals of the form `if language == ...` for workflow semantics
- stack resolution relies on context packet + file evidence + command results
- stack-specific actions still pass through unified deterministic action contract

## 9. Mini-Loop Inside the Turn

For execution turns, runtime MUST run internal bounded convergence loop:

1. build semantic packet
2. request LLM plan/actions
3. normalize/validate actions
4. execute actions
5. run verification (build/test/lint as applicable)
6. if verification fails, append failures to `error_context` and iterate
7. stop on convergence or terminal bound

Loop constraints:

- configurable `max_attempts`
- configurable `max_turn_seconds`
- explicit terminal reason on exit
- no user-facing response until loop exits, unless blocked/clarify condition is reached

## 10. Verification and Convergence Contract

A turn is `converged` when all are true:

- planned actions executed under policy
- required verification checks passed
- no unresolved critical errors
- resulting state persisted consistently

If not converged, terminal reason MUST be non-success and auditable.

## 11. Persistence Contract

SQLite persistence MUST capture:

- canonical turn inputs
- model decision packet metadata
- executed actions and outcomes
- verification results
- terminal reason
- clarification gaps/questions and resolution state

Persistence must support deterministic resume and audit.

## 12. Telegram UX Contract (Current Transport)

User-facing behavior over Telegram:

- natural-language replies by default
- optional JSON envelope for debug/trace mode
- single concise question for clarification when required
- explicit PR link delivery when structured implementation flow creates PR

## 13. Phase Strategy

### Phase A (current target)

- accept partial explicitness from user
- enforce deterministic runtime contracts
- semantic gap filling and clarification with minimal friction

### Phase B (evolution)

- increasingly natural interactions
- reduced explicit routing syntax burden
- stronger autonomous context inference and continuity

## 14. Acceptance Criteria

Spec is satisfied when all are true:

- deterministic state contract enforced with valid transitions only
- semantic packet includes tree + selected files + error context
- project-name inference confirmation exists and is auditable
- mini-loop converges or exits with explicit terminal reason
- multi-stack requests execute without hardcoded language branches in workflow core
- structured and direct modes both operate correctly
