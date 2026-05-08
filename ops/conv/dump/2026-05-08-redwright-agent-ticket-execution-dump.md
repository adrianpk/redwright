# RedWright Agent Ticket Execution Dump

## Status

- type: `dump`
- date: `2026-05-08`
- source: `ops/conv/dump/2026-05-08-redwright-agent-ticket-execution-dump-raw.md`
- state: `closed`

## Central Topic

How RedWright should connect Kanban tickets, sandboxed runtime containers, `LLMRequestEngine` context composition, and repository protocols so an agent can complete programming tickets end to end.

## Summary

The dump frames a future agent delivery workflow where a single operating coding agent can take programming tickets from a Kanban board, execute the work in a sandboxed environment, iterate through validation failures, commit according to project protocols, and move the ticket to ready for review.

The first version can be rough. The system should tolerate manual project-level tuning for container setup and secret injection while preserving the long-term goal that the agent, using LLM-based inference and project setup context, can generate a suitable runtime configuration without making manual tuning the normal workflow.

The `LLMRequestEngine` is the central request boundary for LLM calls. It should eventually compose context from repository structure, semantic extraction, docs, ticket content, execution feedback, repository conversation artifacts, and previous interaction context. Existing specs and quizzes already cover part of this model, especially previous interactions and transient filesystem-based conversation context.

## Key Concepts

- A single user/admin creates tickets and may also self-assign tickets for personal work tracking.
- Tickets can be assigned to a specific agent, but a looser mode may allow an agent to take any available development or correction task not self-assigned by the user.
- The initial scope is single-agent operation, not parallel multi-agent execution.
- Ticket work should happen in a sandboxed runtime environment.
- Project bootstrap should create or drive tickets that let the agent infer and formalize the Docker setup needed for transient work.
- Runtime container configuration needs injectable API keys and other environment values so the agent can access LLM providers and supporting services.
- `LLMRequestEngine` should formalize all LLM provider requests and their context generation.
- Previous conversation context is important and already has supporting draft/spec material.

## Decisions Or Strong Preferences

- Conversation branches in dump terminology mean derived threads, not Git branches.
- Dumps should usually lead toward drafts rather than specs, unless the user explicitly directs a stronger downstream artifact.
- Manual container setup tuning should always be available, through UI, direct artifact editing, or both.
- Manual tuning is an acceptable early fallback but should not become the normal workflow.
- The agent should ultimately generate appropriate container configuration without difficulty.
- The user controls when a dump session has enough material and should close.

## Tensions And Tradeoffs

- Explicit agent assignment is more controlled, while free task pickup reduces bureaucracy.
- An always-on execution loop may be operationally convenient, but interruption semantics must avoid cutting work at unsafe points.
- Early LLM-based Docker inference may be imperfect, but over-investing in manual configuration would weaken the intended agent-driven workflow.
- Sending full previous context is simpler at first, but compact rolling summaries or hybrid records may become necessary to control cost, latency, and noise.
- The first implementation can accept non-optimal context selection, but the implementation state of each context source needs verification.

## Assumptions

- Some mentioned flows or entities may already exist; this dump does not imply everything described is unimplemented.
- The first delivery model is mono-agent.
- Review and merge flows are not the immediate focus, although the same model may later apply.
- Docker is the initial container target, with other container types possible later.
- The Kanban board exposes API calls capable of moving tickets to ready for review.

## Context Sources To Verify

- Tree structure.
- Tree-sitter.
- LLM-generated context.
- Generated or external documentation such as Go docs or JavaDocs.
- Linter errors.
- Compile errors.
- Execution errors.
- Repository conversation artifacts: drafts, specs, quizzes, and dumps.
- Ticket body.
- Previous interaction context.

## Existing Related Artifacts

- `ops/specs/specs/2026-05-05-redwright-llm-request-engine-context-composition-spec.md`
- `ops/specs/drafts/2026-05-05-redwright-prompt-engine-context-composition-draft.md`
- `ops/conv/quiz/2026-05-05-redwright-llm-request-engine-context-composition-quiz.md`
- `ops/conv/quiz/2026-05-05-redwright-llm-request-engine-context-composition-quiz-raw.md`
- `ops/trackers/2026-05-05-redwright-llm-request-engine-context-composition-cycle-tracker.md`

The prompt-engine draft is especially relevant for `previous_interactions`, transient filesystem storage under `tmp/redwright/context/`, `conversation.md`, `previous_interactions.jsonl`, and compact-summary versus raw-record tradeoffs.

## Derived Threads

- Agent loop interruption policy: define graceful stop behavior for a running ticket execution loop.
- Agent task selection policy: decide between strict assignment and free pickup of available development tasks.
- Runtime container setup UX: decide how UI and artifact editing expose manual setup tuning.
- Secret injection model: define how API keys and required environment values enter sandboxed containers.
- Previous interaction context policy: decide initial raw, compact, or hybrid inclusion strategy.
- Later review and merge automation: extend the implementation-loop model to review and merge stages.

## Possible Downstream Artifacts

- Draft for agent programming ticket delivery.
- Quiz to refine execution loop lifecycle, task selection, context sources, container setup, and interruption semantics.
- Spec for sandboxed ticket implementation flow after quiz refinement.
- Ticket cycle for verifying current `LLMRequestEngine` context source implementation state.

## Open Questions

- Should the user manually launch the execution loop, or should it usually remain always on?
- What exact ordering should the agent use when multiple assigned or available tickets exist?
- What does graceful loop interruption mean in product terms?
- Where should project container setup be formalized in the platform model?
- Which container setup fields should be user-editable in the first version?
- How should API keys and other environment values be injected safely and ergonomically?
- Which `LLMRequestEngine` context sources are already implemented, partially implemented, or still only specified?
- Should previous interactions initially be sent raw, compacted, or as hybrid records?
