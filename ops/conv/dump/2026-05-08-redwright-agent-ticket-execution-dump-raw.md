# RedWright Agent Ticket Execution Raw Dump

## Status

- type: `dump-raw`
- date: `2026-05-08`
- source: free-form dump session about agent delivery workflows
- state: `closed`

## Working Notes

This raw capture preserves the user's thinking path in polished English while the dump progresses.
The filename and internal title are temporary and may be corrected if the conversation gravitates toward a more specific topic.

## Session Prelude

The user clarified that conversation branches should be understood as derived threads or conversation threads, not Git branches.

In general, a dump should more naturally produce a draft than a specification. This can be refined later if the dump output is coupled directly to creating another artifact, but that coupling depends on explicit user instruction.

The broad context includes:

- RedWright has documentation artifacts, quiz artifacts, and now dump artifacts.
- Dump artifacts should also exist in RedWright.
- There is a proto-spec, or possibly an implementation, for creating containers so agents can work on tickets in a sandboxed environment.
- There is an `LLMRequestEngine` intended to build prompts in a homogeneous way regardless of which part of the system calls the LLM.
- RedWright may already have, or should incorporate, the ability to send previous conversation context. This needs verification.
- This dump is mostly oriented around how to use those pieces so the agent can ultimately produce deliverables and complete tickets.

The user is mentioning flows and entities that may already exist. The dump should not imply that every mentioned element requires implementation.

## Dump Capture

### Kanban, Ticket Assignment, and Agent Execution Loop

RedWright has a Kanban board.

The system's user/admin should be a single user. That user creates tickets.

Tickets can be assigned to a specific agent.

Eventually, the user can also assign a ticket to themselves for reasons only they know. For example, they may want to use the board to organize their own tasks, or they may sometimes perform development tasks directly.

The coder agent can be assumed to take the tickets assigned to it and complete them in an order that is still to be determined.

However, this depends on configuration:

- Does the user launch the execution loop manually?
- Is the loop an operational concern that is usually always on?
- How does the user interrupt the loop in both cases?
- If the loop is interrupted, does it stop the agent wherever it happens to be? That would be ugly.
- Or does the user send something like `SIGTERM`, as a metaphor for a graceful stop request, allowing the agent to finish its current task before stopping? This does not imply using real operating system signals.

These are open questions. If they are not clarified during this dump, they can later be handled through a refinement session based on quizzes.

### Single-Agent Task Selection Modes

The initial focus is still a single operating agent. Multi-agent parallel operation is not the center of the dump yet.

Within that single-agent model, there are at least two possible task selection modes:

- The agent takes development tasks only when they are assigned to that agent.
- The agent has more freedom and less bureaucracy: any agent can take any task that is available for development or correction, at least when the task has not been self-assigned by the user.

The discussion is currently about development tasks. Review and merge flows have not been discussed yet, although much of the same model may apply to them shortly.

### Sandboxed Ticket Execution and Docker Setup Bootstrap

Every ticket should be resolved by the user or agent in a sandboxed way.

There is a bootstrapping process that the agent itself must perform. In fact, the initial agent that creates the project leaves two tickets related to this. The agent is effectively creating the tickets that should lead it to create the most appropriate Docker configuration so it can work comfortably in its transient work environment.

The Docker setup inference logic is LLM-based.

The project's initialization round is meant to be relatively ordered and predictable. It gathers information about the stack, libraries, and similar project details. This round should be tightened so there is no ambiguity about methodological details and so the Docker setup inference is as precise as possible.

Eventually, although this is not currently part of that initialization round, the user may need space to specify the exact initial image they want, such as Alpine, including its version.

### Docker Setup Maturity and Manual Tuning

It is reasonable to expect that the first iteration of this implementation may not produce a fully polished Docker setup inference, especially at the beginning. The same may later apply to other container types.

Because this setup must be formalized somewhere in the platform model, it should not be difficult for the user to tune the image. The user should be able to do this through the UI, by directly editing a concrete artifact, or possibly through both paths.

At the same time, the initial emphasis is that manual tuning is an understandable fallback, not the normal workflow. The ability to manually fine-tune the setup should always be available. Early on, this may be an unavoidable practical need; later, it can become an interesting optional capability.

In the long run, the LLM, or more precisely the agent using the LLM, should be able to generate an appropriate configuration without difficulty.

### Container Runtime Configuration and Secrets

Another aspect is that the agent's intelligence depends on LLMs, and those LLMs are associated with an API key.

That API key, and any other required runtime value, must be injectable into the container environment so the agent can operate.

As previously expressed, a certain manual per-project approach is acceptable at first. Later, RedWright can consider more ergonomic setup options.

### LLM Request Engine and Context Sources

The dump now opens toward `LLMRequestEngine`, which is the formalization of how all requests to the LLM provider are made and how their context is generated.

A first phase may accept context that is not highly optimized. It may send more than the exact minimum context required. However, RedWright should check the list of possible context sources and verify the implementation state of each one:

- Tree structure.
- Tree-sitter.
- LLM-generated context.
- Documentation, such as Go docs, JavaDocs, and similar generated or external docs.
- Linter errors.
- Compile errors.
- Execution errors.
- Repository conversation artifacts: drafts, specs, quizzes, and dumps. Dumps have not yet been implemented.
- Ticket body, meaning the concrete description of what needs to be done.
- Previous context. This is important, and there is a draft or specification about it that should be reviewed.

For previous context, prior discussion covered having a transient filesystem-based area that keeps a dump of the conversation.

That draft or specification discusses whether RedWright should optimize the previous context through information densification or initially send everything.

Relevant existing repository artifacts:

- `ops/specs/specs/2026-05-05-redwright-llm-request-engine-context-composition-spec.md`
- `ops/specs/drafts/2026-05-05-redwright-prompt-engine-context-composition-draft.md`
- `ops/conv/quiz/2026-05-05-redwright-llm-request-engine-context-composition-quiz.md`
- `ops/conv/quiz/2026-05-05-redwright-llm-request-engine-context-composition-quiz-raw.md`
- `ops/trackers/2026-05-05-redwright-llm-request-engine-context-composition-cycle-tracker.md`

The draft is especially relevant for prior-context details because it explicitly discusses `previous_interactions`, transient filesystem storage under `tmp/redwright/context/`, `conversation.md`, `previous_interactions.jsonl`, and the tradeoff between compact rolling summaries, raw records, and hybrid records.

### Downstream Spec Target: Agent Programming Ticket Delivery

This dump, and its likely later associated quiz, should lay the foundation for a specification. A dump does not always need an associated quiz, but in this case a later quiz is expected to help refine the topic.

The target spec should enable an agent, even in a rough first version, to carry out a programming task described in a ticket.

The expected flow includes:

- Generate a transient container to create a clone or worktree of the project.
- Perform all implementation or correction tasks defined by the ticket.
- Test the changes thoroughly.
- Iterate in a loop until problems are resolved, including linting errors, compile errors, behavioral errors, and similar failures.
- Commit according to project protocols analogous to `AGENTS.md` and referenced by a project.
- Move the ticket to ready for review in the Kanban board through API calls.
- Send any required notifications.

## Derived Threads

### Agent Loop Interruption Policy

This thread emerged from the need to define how a running agent execution loop should stop. It is related to the central topic because ticket delivery requires a controlled execution lifecycle. It may later become a quiz, draft, or implementation ticket. The user has not explicitly asked to pursue it now.
