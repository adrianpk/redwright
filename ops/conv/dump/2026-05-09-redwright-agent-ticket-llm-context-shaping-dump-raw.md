# RedWright Agent Ticket LLM Context Shaping Dump Raw

## Status

- type: `dump-raw`
- date: `2026-05-09`
- state: `closed`
- central_topic: `Agent ticket LLM context shaping, correction loops, and app improvement concerns`
- source_draft: `../../specs/drafts/2026-05-09-redwright-agent-ticket-llm-context-shaping-draft.md`

## Opening Frame

The user wants to enter dump mode before a later quiz round.

The goal is to freely capture ideas, concerns, misunderstandings, doubts, and any useful signals that can help tackle the RedWright application and improve it, especially around agent ticket LLM context shaping and ticket implementation/correction workflows.

## Raw Capture

### Ticket Work Taxonomy

The user thinks a ticket can be exhaustively focused on different aspects. The first broad taxonomy that comes to mind is:

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

This taxonomy matters because ticket context may need to vary by work type. A ticket focused on implementation, review, debugging, operations, or planning may require different context sources, authority ordering, output contracts, validation commands, and retry behavior.

### Taxonomy Compression Without Losing Detail

The user does not want to compact or discard the broad list yet, but suspects that the operational model could probably be reduced to a smaller set of no more than eight ticket types, and possibly fewer.

The broad list may remain useful as tags, subtypes, examples, or intent labels, while the execution engine may need a smaller number of policy families. Those policy families would decide what context to send, what outputs to expect, what validation to run, and whether the agent should edit files, inspect only, ask questions, or perform operational commands.

This suggests a two-level model:

- a rich taxonomy of ticket focuses or labels
- a smaller set of execution/context policy families

The user proposes this first candidate set of operational families:

- exploration
- implementation
- modification
- diagnosis
- evaluation
- operation
- planning
- documentation

Even this set may be reducible depending on the harness. The final grouping should probably be driven less by surface labels and more by what the harness actually needs to do: inspect, edit, validate, execute commands, manage state, or produce durable planning/documentation artifacts.

### Pre-Request Classification Round

The reason the user is naming both the extended taxonomy and the smaller candidate family set is to explore whether RedWright should use another roundtrip to the LLM before the real task request.

This would be a lightweight pre-request that determines the nature of the incoming ticket or request without sending the full project context. The prompt would be something like:

```text
You are a software engineer. Determine the nature of the following software request using one of these N request types: ...
```

The pre-request could use RedWright's normalized payload and possibly the same requester path, as long as it does not create too much overhead. The important distinction is that it would not include the expensive context packet.

After the request nature is inferred, RedWright could build the real LLM request with context tailored to that inferred type.

The user gives a simple example: if the request is only to change a comma in a README, RedWright probably should not send the full project context, full file tree, Tree-sitter data, LLM-generated context, or previous conversations. Previous conversations might still be useful in some cases, but the example is meant to show that very small documentation edits should not require the same context as implementation or debugging work.

This suggests a possible two-step context pipeline:

1. classify the request or ticket using lightweight input
2. compose the real context packet according to the classified work family

Open concern: this adds another LLM call. The primary benefit is not necessarily faster response time. In the context of an agent working alone on a ticket, latency may be less important. The main goal is context optimization for better LLM answers: reducing irrelevant material, selecting the right authority sources, and shaping the request so the model can reason more accurately.

The tradeoff is therefore not just speed versus cost. It is more specifically:

- better context quality and answer quality
- versus extra LLM call cost, implementation complexity, and possible classification error

### Semantic Routing And Execution Profile Resolution

The user raised a concern that deterministic classification through specific keywords or regular expressions would be difficult and probably unreliable. Ticket text may appear in many languages, may mix languages, and may be written by users with very different levels of technical knowledge. The same apparent keyword can mean different things depending on context, and many requests are informal, ambiguous, or mixed.

This means keyword or regex classification should not be the primary mechanism for deciding ticket nature.

Deterministic signals may still be useful when they are structural rather than linguistic, for example:

- explicit ticket kind
- labels
- Kanban column
- UI action source
- explicit file paths
- attached logs or validation output
- existing failing command output
- manually selected execution mode

The semantic interpretation of the ticket/request text should probably be LLM-based.

However, the LLM pre-request should not return only a decorative category. It should return an actionable execution profile that downstream code can use to select context and behavior.

Possible execution profile fields:

```json
{
  "work_family": "diagnosis",
  "confidence": "medium",
  "request_complexity": "moderate",
  "requires_code_changes": "unknown",
  "requires_command_execution": true,
  "requires_validation": true,
  "suggested_context_policy": "diagnosis_with_logs_and_targeted_files",
  "context_needs": [
    "ticket",
    "project",
    "logs_or_error_output",
    "repository_tree_light",
    "candidate_files",
    "tests"
  ],
  "avoid_context": [
    "full_repository_files",
    "previous_interactions_unless_same_failure"
  ],
  "reasoning_summary": "The request asks to understand a failure before deciding whether code changes are needed."
}
```

The important product is not the label itself. The important product is a set of practical decisions:

- whether file edits are allowed or expected
- whether command execution is needed
- whether validation is needed
- whether the request is primarily inspect-only
- whether the request is mixed or unknown
- which context sections are required
- which context sections should be avoided
- which output contract should apply
- whether the agent should ask for clarification

The classifier should support:

- `unknown`
- `mixed`
- ordered candidate families
- confidence
- conservative fallback policies
- traceable reasoning summaries
- manual override through UI or ticket metadata

This should probably be described as semantic routing or execution profile resolution, not merely classification. A candidate name is `ExecutionProfileResolver`, because the goal is to resolve a harness/context profile that can drive the real request, not just assign a category.

### Context Layers And Request-Type Policies

The user agrees with adding a classifier or preprocessor to infer request type, but only if RedWright then acts strongly on that result to optimize what gets sent for each request type.

The preprocessor is valuable when it drives a real context policy. It is not valuable if every classified request still receives the same broad context bundle.

The user names the current or desired context layers as:

- agent
- project
- protocols
- documents, including drafts, specs, plans, and trackers
- file tree
- Tree-sitter or semantic code structure
- LLM-based derived context
- prompt or ticket body
- previous conversation

Initial layer categorization:

```text
Identity and operating posture
  - agent

Primary task input
  - prompt or ticket body

Project grounding
  - project
  - protocols

Planning and repository memory
  - documents, including drafts, specs, plans, trackers, dumps, and quizzes
  - previous conversation

Workspace structure
  - file tree

Code understanding
  - Tree-sitter or semantic code structure
  - selected source/test files

Derived reasoning context
  - LLM-based summaries, rankings, issue analysis, prior attempt summaries, and generated context
```

The user asks whether prompt and ticket body are the same thing. A useful distinction may be:

- `ticket_body`: the persisted task artifact, including title, description, acceptance criteria, comments, labels, and workflow metadata
- `prompt`: the provider-facing instruction assembled for a specific LLM call

Under that model, the prompt may contain a wrapper such as:

```text
We need to resolve this ticket: {ticket body}
```

But it is not the same as the ticket body. The prompt is an execution instruction built from the ticket body plus request mode, context policy, output contract, and selected context sections.

Possible policy implications:

- Agent context is probably always included, but should be compact and stable.
- Ticket body or request body is always included because it is the primary task input.
- Project context is almost always included, but detail level should vary.
- Protocols are high authority and should usually be included, at least in compact form.
- Documents should be selected by relevance; sending all specs, plans, and trackers would likely be noisy.
- File tree should vary from omitted, light, targeted, or full depending on work family.
- Tree-sitter and semantic code structure should be used when code navigation or implementation depends on it, not for every request.
- LLM-derived context should be treated as lower authority than primary artifacts unless explicitly generated for the current request.
- Previous conversation should be scoped and selective; it may be important for continuity, but it can also carry stale assumptions.

Potential inclusion levels:

```text
required
compact
targeted
conditional
omit
```

Candidate context-policy matrix:

```text
Exploration
  required: agent, prompt/ticket, project
  compact: protocols, file tree
  targeted: documents, previous conversation
  conditional: Tree-sitter, LLM-derived context
  omit by default: full source files

Implementation
  required: agent, prompt/ticket, project, protocols
  targeted: file tree, source files, tests, Tree-sitter
  conditional: documents, previous conversation, LLM-derived context
  include on retry: validation feedback, prior attempt summary

Modification
  required: agent, prompt/ticket, project, protocols
  targeted: affected files, nearby tests, file tree
  conditional: Tree-sitter, documents, previous conversation
  include on retry: validation feedback and affected files

Diagnosis
  required: agent, prompt/ticket, project
  targeted: logs, failing commands, error output, relevant files, tests
  compact: protocols, file tree
  conditional: Tree-sitter, previous conversation, LLM-derived issue summaries

Evaluation
  required: agent, prompt/ticket, project, protocols
  targeted: files or areas under review, tests, security/performance evidence
  conditional: documents, previous conversation, Tree-sitter
  output bias: findings, risks, evidence, recommendations

Operation
  required: agent, prompt/ticket, project, protocols
  targeted: CI/CD config, deployment files, runtime setup, environment constraints, command history
  conditional: file tree, documents, previous conversation
  output bias: commands, safety checks, rollback notes

Planning
  required: agent, prompt/ticket, project, protocols
  targeted: relevant documents, specs, plans, trackers, previous conversation
  compact: file tree
  conditional: Tree-sitter or source files when planning depends on code reality
  output bias: plan, scope, risks, open questions

Documentation
  required: agent, prompt/ticket, project, protocols
  targeted: relevant docs and referenced files
  compact: file tree when needed
  conditional: previous conversation, source files, specs
  omit by default: broad source/test context unless documentation depends on implementation facts
```

### Current Capability Status Must Be Audited

The user wants the dump to express not only doubts but also attempts to resolve them.

There is a specific open question: of all the context layers named above, which capabilities are currently implemented, which are partial, and which are only conceptual?

The status update should be complete enough to know where RedWright currently stands.

The audit should answer:

- which context layers exist today
- where they are implemented
- how they feed `Redwright::LLM::RequestEngine`
- which services or engines call that request engine
- what context those callers provide
- whether each context source is broad, targeted, compact, or missing
- where the current implementation differs from the desired context-policy model

Initial capability audit targets:

- `Redwright::LLM::RequestEngine`
- `Redwright::LLM::ContextSection`
- `Redwright::LLM::TraceRecorder`
- `AgentTicketExecution::ContextComposer`
- `AgentTicketExecution::ContextSectionProviders`
- `AgentTicketExecution::LlmRequester`
- `AgentTicketExecution::ValidationLoop`
- `QuizLoops::QuestionProvider`
- `Redwright::ProjectSetupPromptRenderer`
- legacy Telegram runtime intent interpretation traces

### Dump And Quiz Completion Goal

The dump and the later quiz must clear doubts for two related goals.

First, they must define enough about the preprocessor or execution profile resolver so it can do its work effectively. That includes request families, confidence, mixed or unknown behavior, context policy selection, and fallback behavior.

Second, they must verify that every part involved in grouped context composition is actually operational. It is not enough to design the preprocessor if the context layers it selects are missing, stale, not wired, or not injected into the final LLM request.

The desired outcome is:

- each context layer is identified
- each layer has a source of truth
- each layer has an implementation status
- each layer has an owner/service boundary
- each layer has an injection path into `Redwright::LLM::RequestEngine` or its caller
- each layer has rules for when it is required, compact, targeted, conditional, or omitted
- each layer has authority and freshness semantics
- each layer is used conveniently by the services and engines that need it

The quiz should therefore resolve both:

- semantic routing and execution profile behavior
- operational readiness of context composition layers
