# RedWright Minimal Runtime and Skills Spec

## 1. Purpose

Define the next runtime evolution so RedWright can execute software work with lower interaction friction, stronger deterministic control, and reusable capability modules, while preserving natural-language-first interaction.

## 2. Scope

This spec defines:

- turn-loop behavior for planning and execution
- context assembly and payload shaping for model calls
- skill activation and skill sub-loop orchestration
- operational control plane (`slash` commands)
- project/session continuity across ingress channels
- bounded convergence and deterministic stop conditions

This spec does not define:

- production-grade distributed orchestration
- multi-tenant isolation
- enterprise RBAC

## 3. Runtime Model

RedWright runtime remains deterministic at orchestration boundaries and model-driven inside semantic decision points.

Core principles:

- keep primitive tool catalog small and stable
- keep model payloads selective and bounded
- run bounded micro-loops with explicit terminal reasons
- persist enough structured state for resume/recovery
- keep ingress channels as adapters over one runtime contract

Session continuity rule:

- each active session has one explicit active project binding by default
- project switching is explicit through control plane operations
- natural-language project switches are allowed only when resolved to explicit project refs before execution

## 4. Turn Loop Contract

Each turn must follow this order:

1. ingest message and resolve session/project context
2. parse control plane signals (`slash`, `@hints`) and merge with NL intent
3. build bounded turn context packet
4. call planner/interpreter with strict output schema
5. validate allowed actions
6. execute actions through primitive executor
7. run validation gates when required (build/test/lint)
8. persist artifacts and transition state
9. continue or stop according to bounded policies

## 5. Context Assembly Contract

For each model call, runtime must include:

- agent context (identity + safety invariants)
- project context (path, stack hints, active conventions)
- architecture context (local project rules)
- turn context packet:
  - active objective (1-2 lines)
  - active clarification state
  - top-level tree summary
  - top-K significant files/snippets
  - last execution results and normalized failures
  - last patch/action summary

Default bounds:

- `top_k_files`: 5
- `snippet_lines_per_file`: configurable bounded value
- deterministic truncation order

## 6. Control Plane Contract

Control plane precedence:

1. slash command
2. parsed `@hints`
3. natural-language inference

Required slash commands (phase baseline):

- `/project <ref>`
- `/status`
- `/pause`
- `/resume`
- `/cancel`
- `/skill <name>`
- `/continue`

## 7. Skills Contract

Skills are reusable behavior modules loaded from discoverable paths.

Skill activation modes:

- explicit (`/skill <name>`)
- inferred (planner-selected with confidence)
- none

Skill execution runs as a bounded sub-loop and returns a structured artifact to the main loop.

Required skill metadata:

- name
- description
- trigger hints
- optional constraints

## 8. Clarification Contract

Clarification state is explicit and persistent.

Rules:

- one active high-value question at a time by default
- answer consumption must target active clarification state before new planning
- user can force continue with current context
- clarification loop has attempt/time bounds

## 9. Convergence and Stop Conditions

Per task/workstream limits:

- max attempts
- max wall-time
- max consecutive no-progress cycles
- max identical failure fingerprints

Terminal reasons:

- `success`
- `needs_user_input`
- `blocked`
- `cancelled`
- `timeout`
- `max_attempts`

## 10. Persistence Contract

Persist structured entities for recoverability:

- session
- project context binding
- workstream
- task
- action execution
- validation result
- clarification session

Dev mode reset must allow clean recovery without manual database edits.

## 11. Channel Parity Contract

Telegram and console ingress must share:

- same session/project resolution model
- same skill activation semantics
- same control plane semantics
- same runtime loop and terminal reason model

Default project continuity behavior:

- console starts from current active project binding
- messaging continues on active session project unless explicitly switched

## 12. Bootstrap Skills Contract

Provide reusable bootstrap capabilities for:

- repository initialization and remote binding
- AGENTS/.agents scaffolding by stack profile
- README scaffolding by project profile

Source resolution order:

1. project-local templates
2. user-global templates
3. configured remote template catalog
4. model-generated fallback (bounded + reviewable)

## 13. Acceptance Criteria

- natural-language and structured signals are interpreted without control drift
- runtime converges or exits with explicit deterministic reason
- skill activation works via explicit slash and inference
- per-turn payload stays bounded and actionable
- channel parity tests pass for control and skills flows
- bootstrap scaffolds are reproducible and safe
