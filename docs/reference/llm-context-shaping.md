# LLM Context Shaping

## Purpose

RedWright shapes LLM request context by resolving a software-engineering action to an explicit context policy, then applying that policy inside `Redwright::LLM::RequestEngine`.

The classifier and policy pipeline optimize which context is sent to the real action request. They do not rewrite the downstream prompt, choose workflow transitions, execute commands, mutate records, or replace action-specific output contracts.

## Runtime Flow

The context shaping flow is:

1. The caller builds the normal action request.
2. The caller supplies structured `Redwright::LLM::ContextSection` objects.
3. The caller supplies a mapped `context_policy`, or opts into dynamic policy resolution.
4. `Redwright::LLM::RequestEngine` optionally asks `Redwright::LLM::ContextPreclassifier` for an execution profile.
5. `RequestEngine` resolves the effective policy.
6. `RequestEngine` selects context sections whose normalized `context_layer` belongs to the policy.
7. `RequestEngine` sends the existing action prompt and output contract to the provider with the selected context.
8. The response diagnostics and LLM trace record the policy decision.

Callers continue to own business state gathering. `RequestEngine` does not fetch projects, tickets, files, documents, or database records by itself.

## Execution Profile

Dynamic context selection uses `Redwright::LLM::ExecutionProfile`.

Required fields:

- `primary_work_family`
- `context_policy`
- `confidence`
- `requires_code_changes`
- `requires_command_execution`
- `requires_validation`
- `should_ask_clarification`
- `reasoning_summary`

Optional fields:

- `runner_up_families`
- `request_complexity`
- `expected_outputs`
- `policy_inputs`

`primary_work_family` must be one strongest family. Mixed work is represented through optional metadata, not through a second operational family.

Allowed confidence bands are:

- `high`
- `medium`
- `low`

`low` confidence resolves to `full_context_fallback`.

## Work Families

The first policy model supports these work families:

- `exploration`
- `implementation`
- `modification`
- `diagnosis`
- `evaluation`
- `operation`
- `planning`
- `documentation`

Every mapped LLM action resolves to one default policy derived from one family. Dynamic preclassification may override that default by returning a valid execution profile.

## Context Policies

Policies live in `Redwright::LLM::ContextPolicy`.

The default policies are:

- `exploration_default`
- `implementation_default`
- `modification_default`
- `diagnosis_default`
- `evaluation_default`
- `operation_default`
- `planning_default`
- `documentation_default`
- `full_context_fallback`

`full_context_fallback` includes every known layer and is used for low confidence, invalid classifier output, unavailable classifier clients, or explicitly broad fallback behavior.

## Context Layers

The policy registry accounts for these normalized layers:

- `agent`
- `project`
- `prompt`
- `concrete_files`
- `file_tree`
- `tree_sitter`
- `llm_based`
- `docs`
- `quizzes`
- `dumps`
- `conversation`
- `protocols`

Each context section should declare its layer with `metadata["context_layer"]`. If no layer metadata exists, `RequestEngine` falls back to the section name.

## Implemented Sources

Agent ticket execution composes policy-selectable context from:

- ticket and project data
- repository tree
- concrete repository files
- test files
- operational setup
- Tree-sitter style code structure for supported source files
- modeled protocol documents
- repository and app documents
- quiz context
- dump context
- derived LLM context
- previous agent interactions and human conversation evidence
- validation feedback

Quiz generation supplies project and quiz context sections. Project setup prompt rendering supplies setup summary, next prompt intent, setup context, and current user text sections.

Dump context comes from the selected project's Markdown documents. The database
indexes their metadata and paths; it does not supply a second body. Agent ticket
execution selects non-empty dumps allowed by the effective context
policy and matched to the ticket's case and topic. Omitted documents carry an
explicit diagnostic reason. Quiz and spec generation also read the current file.


Protocols are read from the project's root `AGENTS.md` and Markdown files under
`.agents/`. The dedicated `protocol_files` section uses those same files as the
web editor. Protocol files are omitted from the general repository filesystem
scan to avoid duplicate context. Additions, removals, and edits made by other
tools appear in the next context composition without re-import.

## Provider Payload Behavior

For provider requests whose JSON payload contains `context_sections`, `RequestEngine` replaces that field with the policy-selected sections before calling the provider.

Protocol content is supplied once through `protocol_files`; there is no
separate database-backed protocol content section.

## Trace Fields

LLM request and response traces can include `policy_decision`.

Policy diagnostics include:

- `policy_name`
- `work_family`
- `confidence`
- `fallback`
- `unknown_policy`
- `included_layers`
- `included_context_sections`
- `omitted_context_sections`
- `omission_reasons`

Response diagnostics also include:

- selected context section names
- context section authorities
- selected context byte size
- trace metadata
- redaction state
- provider or contract failure diagnostics when applicable

Omission reasons use this format:

```text
context_layer_not_in_policy:<layer>:<policy>
```

## Active Action Mapping

Current mapped actions include:

- `agent_ticket_execution` -> `implementation_default`
- `quiz_question_generation` -> `exploration_default`
- `quiz_fast_question_generation` -> `exploration_default`
- `project_setup_prompt_render` -> `planning_default`
- `intent_interpret` -> `planning_default`
- `intent_interpret_with_current_context` -> `planning_default`
- `intent_interpret_with_gap_answer` -> `planning_default`
- `intent_refine_with_errors` -> `diagnosis_default`
- `alignment_question_generation` -> `planning_default`
- `runtime_container_generation` -> `operation_default`

Unmapped callers may pass an explicit policy. Calls without a policy preserve default unfiltered behavior.

## Tuning Guidance

Use trace output to tune policy behavior. Inspect the selected policy, omitted sections, omission reasons, and final provider prompt before changing policy constants.

Prefer changing the explicit policy matrix before adding another routing component. The preclassifier should remain a context-policy selector only.
