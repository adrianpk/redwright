# Redwright Planner-Executor Hardening Spec

## Metadata

- id: `spec-2026-04-27-redwright-planner-executor-hardening`
- status: `draft`
- owner: `adrianpk`
- created: `2026-04-27`
- updated: `2026-04-27`
- scope: `runtime/planner-executor`

## Problem Statement

Current runtime turns can fail even when the LLM produces plausible structured output, because planner action types are not strictly aligned with executor-supported primitives. The most visible failure mode is `unsupported action type` during execution.

In parallel, prompt construction lacks an explicit anti-injection structure and precedence model. This creates unnecessary risk of policy drift, capability overreach, and unstable planner behavior.

## Goals

- ensure planner output is executable by runtime without type mismatches
- support ergonomic macro actions without breaking primitive-first architecture
- define strict context layering and prompt-injection defense rules
- keep runtime modular and explicit across planner, normalizer, validator, and executor

## Non-Goals

- full autonomous project lifecycle orchestration redesign
- introducing new transports beyond current Telegram ingress
- replacing SQLite persistence in this cycle

## Runtime Contract (Target)

### 1. Supported Primitive Actions

Canonical primitives remain the execution substrate:

- `list_files`
- `read_file`
- `search`
- `write_file`
- `apply_patch`
- `run`
- `git_status`
- `git_branch`
- `git_commit`
- `git_push`

### 2. Supported Macro Actions (Planner-facing)

Macros are accepted at planner boundary and normalized to primitives before execution:

- `write_files` -> one `write_file` per file
- `run_command` -> one `run`
- `run_commands` -> ordered sequence of `run`

### 3. Execution Rule

Executor executes only canonical primitives. Any unknown type after normalization must be rejected before execution with a planner-level validation error.

## Prompt and Injection Hardening

## Context Layers (ordered)

1. **Agent Context**
- identity: `RedWright`
- role: software engineering agent
- constraints: safety, repository invariants, branch/PR workflow rules

2. **Project Context**
- active project id/path
- stack/language/tooling hints
- runtime mode (`dev`/`real`) and workspace boundary

3. **Architecture Context**
- allowed action catalog
- normalization rules
- confirmation and boundary policies

4. **Task Prompt**
- user intent for the turn
- desired deliverable for this run

## Precedence Rule

The model must treat layers in strict precedence order:

- Agent Context > Project Context > Architecture Context > Task Prompt

Lower layers cannot override higher-layer constraints.

## Injection Defenses

- reject instructions that request policy override (e.g. "ignore previous instructions")
- never expand capability catalog from user text
- disallow execution of action types not present in explicit allowed catalog
- preserve confirmation requirements for risky git primitives
- keep path boundary checks (`project_root` confinement) mandatory

## Planner Output Requirements

Planner JSON output must:

- use only allowed action types (primitive or macro catalog)
- include valid `args` schema per action type
- include `requires_confirmation`, `timeout_ms`, and `on_failure`
- avoid adding undeclared top-level keys

## Validation and Normalization Pipeline

1. planner returns JSON
2. payload validator checks schema and allowed action catalog
3. normalizer expands macros into canonical primitive list
4. post-normalization validator re-checks canonical action integrity
5. executor runs primitives

If any step fails, runtime returns clarify/error response and persists evidence.

## Observability Requirements

For each turn:

- record raw planner output
- record normalization summary (macro count, expanded action count)
- record per-action execution outcome
- correlate all artifacts by `trace_id`

## Acceptance Criteria

- no `unsupported action type` for planner outputs using documented primitive/macro catalog
- macro actions are expanded deterministically and verifiably
- prompt builder includes all four context layers with explicit precedence
- known injection strings do not alter allowed capabilities or policy constraints
- end-to-end turn tests cover success, reject, and clarify paths

## Risks

- over-constraining planner may reduce flexibility on ambiguous user requests
- macro expansion can hide complexity if observability is weak
- schema drift between prompt and validator can reintroduce runtime mismatch

## Rollout Notes

- start with planner+validator+normalizer hardening under existing daemon flow
- keep compatibility with existing primitive execution and traces
- defer advanced policy tuning (dynamic trust levels, user profile scopes) to future cycle
