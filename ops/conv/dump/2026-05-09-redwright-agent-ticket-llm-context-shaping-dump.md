# RedWright Agent Ticket LLM Context Shaping Dump

## Status

- type: `dump`
- date: `2026-05-09`
- source: `ops/conv/dump/2026-05-09-redwright-agent-ticket-llm-context-shaping-dump-raw.md`
- state: `closed`
- related_draft: `ops/specs/drafts/2026-05-09-redwright-agent-ticket-llm-context-shaping-draft.md`
- associated_quiz: `ops/conv/quiz/2026-05-09-redwright-agent-ticket-llm-context-shaping-quiz.md`

## Central Topic

How RedWright should classify ticket/request nature and use that classification to compose better LLM context for ticket implementation, correction, diagnosis, planning, operation, review, and documentation work.

## Summary

The dump establishes that agent ticket execution should not treat all tickets as the same kind of coding request. Tickets may represent many different kinds of software work, and those kinds should drive context composition, output contracts, validation expectations, and harness behavior.

The core idea is to introduce a lightweight pre-request or semantic routing step that resolves an actionable execution profile before the expensive real LLM request is composed. The value is not primarily speed. The value is better LLM answers through better context selection, clearer authority, lower noise, and task-appropriate instructions.

The dump also clarifies that the preprocessor is only useful if RedWright has operational context layers behind it. The later quiz must therefore resolve both the behavior of the execution profile resolver and the implementation status of every context layer that may feed grouped context composition.

## Key Concepts

- A broad ticket taxonomy is useful as vocabulary, but execution needs a smaller set of policy families.
- Context policy families should be driven by what the harness needs to do, not only by surface request labels.
- A pre-request classification round should produce an actionable execution profile, not a decorative category.
- Keyword or regex classification is not reliable enough as the primary mechanism because ticket text may be multilingual, informal, ambiguous, or mixed.
- Deterministic signals may still help when they are structural rather than linguistic.
- Context composition should be policy-driven after semantic routing.
- The LLM request context should be built from named layers with authority, source, freshness, and inclusion semantics.
- The quiz must confirm which context layers are implemented, partial, missing, or conceptual.

## Candidate Ticket Focus Taxonomy

The broad vocabulary of ticket focuses includes:

- architecture
- feature implementation
- bug correction
- refactoring
- code review
- security review
- performance review
- testing
- test generation
- documentation
- research or exploration
- debugging
- log analysis
- migrations
- deployment
- infrastructure operation
- CI/CD configuration
- dependency upgrades
- technical cleanup
- scaffolding or boilerplate
- technical planning
- impact analysis
- spec generation
- hypothesis validation
- command execution
- branch or worktree management
- state or context synchronization
- monitoring or observability
- issue reproduction
- profiling or benchmarking

This list should not be collapsed prematurely. It may remain useful as tags, examples, subtypes, or user-facing language.

## Candidate Policy Families

The user proposed this smaller candidate set:

- exploration
- implementation
- modification
- diagnosis
- evaluation
- operation
- planning
- documentation

This set may still be reducible depending on the harness. The final model should be based on practical behavior:

- inspect
- edit
- validate
- execute commands
- manage state
- produce durable planning/documentation artifacts
- ask for clarification
- stop as blocked

## Semantic Routing

The routing step should infer the nature of the request before full context composition.

The likely shape is:

```text
ticket payload -> execution profile resolver -> context policy -> real LLM request
```

The routing step may use:

- ticket title and body
- ticket metadata
- labels
- Kanban state
- source channel
- explicit file paths
- attached logs
- prior validation output
- manually selected mode

It should not send the full project context by default.

## Execution Profile

The pre-request should return an execution profile with practical downstream decisions.

Candidate fields:

```json
{
  "work_family": "diagnosis",
  "candidate_families": ["diagnosis", "implementation"],
  "confidence": "medium",
  "request_complexity": "moderate",
  "requires_code_changes": "unknown",
  "requires_command_execution": true,
  "requires_validation": true,
  "suggested_context_policy": "diagnosis_with_logs_and_targeted_files",
  "context_needs": ["ticket", "project", "logs_or_error_output", "repository_tree_light", "candidate_files", "tests"],
  "avoid_context": ["full_repository_files", "previous_interactions_unless_same_failure"],
  "reasoning_summary": "The request asks to understand a failure before deciding whether code changes are needed."
}
```

The profile should support:

- `unknown`
- `mixed`
- ordered candidate families
- confidence
- conservative fallback behavior
- traceable reasoning
- manual override through UI or ticket metadata

## Context Layers

The desired context layers are:

- agent
- project
- protocols
- documents, including drafts, specs, plans, trackers, dumps, and quizzes
- file tree
- Tree-sitter or semantic code structure
- LLM-based derived context
- prompt or ticket body
- previous conversation

The prompt and ticket body should be distinguished:

- `ticket_body` is the persisted task artifact: title, description, acceptance criteria, comments, labels, and workflow metadata.
- `prompt` is the provider-facing instruction assembled for a specific LLM call from the ticket body, execution mode, output contract, selected context, and policy.

## Context Policy Direction

The initial inclusion levels are:

- `required`
- `compact`
- `targeted`
- `conditional`
- `omit`

Policy examples:

- Exploration should usually include agent, prompt/ticket, project, compact protocols, light file tree, targeted docs, and optional semantic code context.
- Implementation should include agent, prompt/ticket, project, protocols, targeted source/tests/tree, and retry feedback when applicable.
- Modification should focus on affected files, nearby tests, file tree, protocols, and prior failure context.
- Diagnosis should prioritize logs, failing commands, error output, relevant files, tests, and compact project/protocol context.
- Evaluation should prioritize review targets, tests, evidence, protocols, and findings-oriented output.
- Operation should prioritize CI/CD, deployment files, runtime setup, environment constraints, command history, safety checks, and rollback notes.
- Planning should prioritize documents, specs, plans, trackers, prior conversation, compact file tree, and source reality when needed.
- Documentation should prioritize relevant docs and referenced files while omitting broad source/test context unless implementation facts are needed.

## Current Capability Status

The current implementation status is mixed.

Implemented strongly:

- `Redwright::LLM::RequestEngine` as a structured LLM request/response boundary.
- `Redwright::LLM::ContextSection` with name, content, authority, metadata, and byte size.
- `Redwright::LLM::TraceRecorder` for request/response tracing.
- Agent ticket context composition through `AgentTicketExecution::ContextComposer`.
- Agent ticket context providers for ticket, project, repository tree, relevant files, tests, operational setup, protocols, previous interactions, and validation feedback.
- Retry feedback injection through `AgentTicketExecution::ValidationLoop`.
- Previous agent-LLM interaction replay scoped to ticket/session/agent.
- Quiz and project-setup paths that use the same request-engine pattern.

Partially implemented:

- Agent context, mostly as system prompt, model role, and action, not as a distinct rich context layer.
- Project context across flows.
- Protocol context.
- Previous conversation, limited to previous agent-LLM loop records in ticket execution.
- LLM-derived context, limited to prior interactions and validation feedback.
- Diagnostics for context quality through trace metadata and bytes.

Missing or still conceptual:

- `ExecutionProfileResolver`.
- Pre-request semantic routing.
- Context policy matrix by request type.
- Tree-sitter context layer in agent ticket execution.
- General documents layer for drafts, specs, plans, trackers, dumps, and quizzes.
- Ticket-aware file ranking.
- Validation-feedback summarization.
- Selection and omission reasons.
- Authority order contract.
- Context freshness model.
- Manual override of execution profile or context policy.

## Decisions Or Strong Preferences

- The preprocessor should be designed as semantic routing or execution profile resolution, not simple classification.
- LLM-based semantic interpretation is preferred over keyword/regex classification for request text.
- Structural deterministic signals may still be used as supporting evidence.
- A preprocessor only matters if it drives strong context policy decisions.
- The later quiz must address operational readiness of all context layers, not only the routing step.
- The output of routing should be actionable by the harness and context composer.

## Tensions And Tradeoffs

- Extra LLM roundtrip adds cost, complexity, and classification-error risk.
- The intended benefit is better context quality, not necessarily faster response time.
- Broad context is robust for first-cycle execution but becomes noisy as project size grows.
- Fine-grained policy can improve answers but requires clear source ownership and operational wiring.
- LLM-derived summaries can reduce noise but may have lower authority than primary artifacts.
- Previous conversation helps continuity but may carry stale assumptions.

## Assumptions

- Agent ticket execution will continue to operate through structured LLM request boundaries.
- The first execution-profile implementation can be conservative and observable.
- Low-confidence or mixed classification should not block work; it should select a safe fallback policy.
- Context layers should have traceable inclusion and omission semantics.
- The harness capabilities should influence the final policy families.

## Derived Threads

- Execution profile resolver design.
- Context layer capability audit.
- Context authority and freshness contract.
- Documents layer integration for specs, drafts, plans, trackers, dumps, and quizzes.
- Tree-sitter or semantic code context integration.
- Ticket-aware file ranking and evidence selection.
- Validation feedback summarization.
- Manual override UX for execution profile and context policy.

## Possible Downstream Artifacts

- Quiz for execution profile and context-layer readiness.
- Formal spec for agent ticket context shaping.
- Implementation plan for `ExecutionProfileResolver`.
- Ticket cycle for context-layer capability audit.
- Ticket cycle for documents and Tree-sitter context integration.

## Open Questions

- What is the minimal first execution profile schema?
- Should policy families remain eight, be reduced, or be derived directly from harness capabilities?
- Which fields are required for confidence and mixed/unknown behavior?
- What source of truth owns each context layer?
- Which services should produce each layer?
- Which services should consume each layer?
- What is the authority order between ticket, protocol, documents, source files, validation output, LLM-derived context, and previous conversation?
- When should previous conversation be included, summarized, or omitted?
- How should documents be selected without sending all repository planning artifacts?
- When should Tree-sitter or semantic code structure be required?
- How should validation feedback be summarized for correction loops?
- What fallback policy should run when classification confidence is low?
