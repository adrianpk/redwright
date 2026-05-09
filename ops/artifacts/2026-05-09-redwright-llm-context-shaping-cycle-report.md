# Cycle Report: RedWright LLM Context Shaping

## Metadata

- cycle_id: `2026-05-09-redwright-llm-context-shaping`
- status: `implemented_pending_review`
- date: `2026-05-09`
- source_plan: `ops/plans/2026-05-09-redwright-llm-context-shaping-cycle-plan.md`
- source_tracker: `ops/trackers/2026-05-09-redwright-llm-context-shaping-cycle-tracker.md`
- source_spec: `ops/specs/specs/2026-05-09-redwright-agent-ticket-llm-context-shaping-spec.md`
- source_dump: `ops/conv/dump/2026-05-09-redwright-agent-ticket-llm-context-shaping-dump.md`
- source_quiz: `ops/conv/quiz/2026-05-09-redwright-agent-ticket-llm-context-shaping-quiz.md`

## Summary

This cycle implemented task-aware LLM context shaping across RedWright's shared request-engine path.

The delivered model defines explicit work families, execution profiles, policy constants, action mappings, low-confidence fallback behavior, policy diagnostics, trace fields, modeled protocol selection, document, quiz, dump, conversation, Tree-sitter, and LLM-derived context capabilities, plus end-to-end tests for representative ticket execution, quiz generation, and project setup flows.

The preclassifier is intentionally narrow. It selects the context policy for the real request and does not rewrite prompts, choose workflow transitions, execute commands, or change output contracts.

## Delivered Model

- `Redwright::LLM::ContextPolicy` defines the eight work families, confidence bands, all known context layers, default family policies, action mappings, and `full_context_fallback`.
- `Redwright::LLM::ExecutionProfile` normalizes classifier output and forces low confidence to `full_context_fallback`.
- `Redwright::LLM::ContextPreclassifier` provides optional LLM-backed policy selection with fakeable tests and fallback behavior.
- `Redwright::LLM::RequestEngine` applies policies to supplied context sections and records policy diagnostics.
- Agent ticket execution, quiz generation, and project setup prompt rendering opt into mapped context policies.
- Agent ticket execution composes all required context capabilities as selectable sections.
- Provider payloads receive policy-filtered context sections.
- LLM request and response traces include selected policy metadata.

## Context Capability Status

| Context type | Final status |
| --- | --- |
| `agent` | operational through execution contract and stable system prompts |
| `project` | operational across ticket execution, quiz generation, and project setup |
| `prompt` | operational and distinct from ticket body and preclassification |
| `concrete_files` | operational in ticket execution |
| `file_tree` | operational in ticket execution |
| `tree_sitter` | operational in ticket execution with broad supported source extensions |
| `llm_based` | operational through derived recent interaction summaries |
| `docs` | operational through repository and app document selection |
| `quizzes` | operational through quiz artifact and app quiz context selection |
| `dumps` | operational through repository dump artifact selection |
| `conversation` | operational through previous interactions and scoped conversation evidence |
| `protocols` | operational from modeled project protocol state |

## Trace And Debug Evidence

Policy diagnostics are recorded with request-engine responses and propagated into trace records. The trace payload can show:

- selected policy
- work family
- confidence band when dynamic classification is used
- fallback state
- included layers
- included context sections
- omitted context sections
- omission reasons
- selected context section authorities
- selected context byte size

This gives operators enough information to tune policy constants and classifier behavior from actual request outcomes.

## Validation

- `bundle exec rails test test/lib/redwright/llm/context_policy_test.rb test/lib/redwright/llm/execution_profile_test.rb` (pass)
- `ruby test/redwright/llm_context_preclassifier_test.rb` (pass)
- `ruby test/redwright/llm_request_engine_test.rb` (pass)
- `bundle exec rails test test/services/agent_ticket_execution/context_composer_test.rb test/services/agent_ticket_execution/llm_requester_test.rb` (pass)
- `bundle exec rails test test/services/agent_ticket_execution/llm_requester_test.rb test/services/quiz_loops/question_provider_test.rb` (pass)
- `ruby test/redwright/project_setup_prompt_renderer_test.rb` (pass)
- `git diff --check` (pass)

## Residual Risks

- The policy matrix is intentionally a first tuning baseline and should be adjusted from trace evidence.
- Dynamic preclassification depends on provider quality when enabled, so low-confidence fallback must stay broad.
- Tree-sitter context currently uses local extraction heuristics and supported source extensions, not a full parser integration for every language.
- Document, quiz, dump, and conversation selection is operational but conservative; deeper ranking can be added after observing real traces.
- The preclassifier should remain constrained to context policy selection to avoid becoming a second planning system.

## Tuning Guidance

Tune in this order:

1. Inspect trace `policy_decision` for selected and omitted context.
2. Adjust `ContextPolicy::DEFAULT_INCLUDED_LAYERS_BY_FAMILY` when a family consistently lacks or over-includes a layer.
3. Adjust action-to-family mappings when a whole action consistently behaves like another family.
4. Tune classifier prompt or examples only after the static policy matrix is validated from traces.
5. Keep `full_context_fallback` broad until enough trace evidence supports narrower fallback behavior.
