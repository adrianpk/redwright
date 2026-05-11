# RedWright Codex Backend and Agent Sandboxing Raw Dump

## Metadata

- date: `2026-05-11`
- central_topic: `Codex as an optional ticket execution backend and agent sandboxing model for RedWright`
- source: `conversation`
- status: `raw_capture`

## Starting Point

The current RedWright setup loop for `/project new` asks a few Telegram-driven questions and then materializes project state. The current behavior can create internal tickets such as:

- `Prepare initial implementation plan`
- `Review Runtime Containers readiness`

This direction is undesirable. These tickets feel self-referential: the agent is creating tickets telling itself that infrastructure still needs to be completed. The preferred product behavior is that project setup should materialize the project and its agent runtime setup directly, including `.rw/agent` files, instead of creating tickets for that setup.

The desired `.rw/agent` setup is not a production Docker setup and not a human development Docker setup. It is specifically an operational runtime for agents: every time an agent needs to work on a ticket, RedWright should be able to provision an isolated or semi-isolated workspace where project commands can run safely.

## Runtime Setup Distinction

The agent Dockerfile should be documented and modeled as:

- not production deployment infrastructure
- not the local human development environment
- not necessarily the app's own Dockerfile or Compose setup
- an ephemeral task runtime for agent ticket execution

The purpose is to give ticket agents a reproducible environment for dependency installation, tests, linters, builds, and validation while keeping the host system and canonical project workspace safer.

## Mounts, Clones, and Workspaces

A container needs access to code to be useful. A bind mount of the existing workspace is not the only model and may not be the right default. The better conceptual model may be for the sandbox to clone or work from a ticket-scoped checkout rather than mutate the main workspace.

This means there may still be mount points, but the mount is not equivalent to giving the container the canonical project checkout. A better model is:

- create a ticket-scoped scratch checkout or git worktree
- mount that scratch workspace into the container
- optionally mount caches explicitly
- optionally mount context/output directories
- keep the canonical workspace untouched until RedWright promotes the result

This makes the sandbox workspace disposable and allows RedWright to inspect diffs before applying, committing, pushing, or opening a PR.

## Host Versus Container Responsibilities

The preferred boundary is:

- RedWright host owns project state, ticket state, orchestration, LLM calls, context construction, traces, finalization, and credentials.
- The container owns project command execution: install, test, lint, build, format, diagnostics.

For the native RedWright backend, the container should not need to call OpenAI, OpenRouter, or any other LLM provider by default. RedWright host owns those LLM calls through `LLMRequestEngine`.

For a managed-agent backend, credentials may need to live wherever the managed agent process runs. If Codex runs inside the execution environment, then an OpenAI credential or equivalent Codex authentication must be injected explicitly for that backend. That should be treated as a backend-specific credential policy, not as general environment inheritance.

The entire process could technically happen inside the container, including git push, but that would require putting git credentials, network permissions, and finalization logic inside the sandbox. The safer default is to let the container produce changes and logs, while RedWright handles final promotion.

## Sandboxing Limits

Docker or Podman sandboxing is not perfect security. It is still an improvement over executing arbitrary project commands directly on the host, especially if RedWright uses:

- explicit workspace mounts
- scratch worktrees
- no default secret forwarding
- explicit cache mounts
- resource limits
- controlled network policies
- teardown after execution

The system should not pretend that Docker means total isolation. It should treat Docker or Podman as a pragmatic execution boundary.

## Reusable Sandbox Behavior

Reusable behavior worth preserving in RedWright's own model:

- a small boundary for running commands outside the main application process
- multiple execution environments behind the same ticket-execution contract
- scratch workspace creation under a managed RedWright run directory
- branch or checkout strategies that keep ticket work away from the canonical workspace
- a lifecycle around preparing a run, starting an execution environment, running commands, collecting output, and closing the run
- explicit mounts for scratch workspace, caches, read-only context, and output artifacts
- a distinction between environments that can see a host-mounted workspace and environments that require explicit sync-in/sync-out

The useful principle is `orchestration != isolated command execution`. RedWright should own the orchestration model and expose only the minimum execution behavior needed by ticket work.

This behavior is expanded in `ops/specs/drafts/2026-05-11-redwright-reusable-agent-sandbox-behavior-draft.md`. The sandbox behavior and the Codex backend are connected, but they are not the same thing.

## Pattern To Capture

The target pattern is a layered orchestration system with interchangeable task-solving boxes.

The reusable shape is:

```text
Ticket intent
  -> RedWright orchestration
  -> task workspace
  -> selected task-solving backend
  -> isolated command execution
  -> result capture
  -> RedWright finalization
  -> kanban transition
```

Each layer should behave like a black box with a narrow contract:

- task workspace prepares a place to work
- task-solving backend attempts the ticket
- isolated command execution runs project commands safely enough for the chosen policy
- result finalization decides what to do with the outcome

The interchangeable boxes are the task-solving backends:

```text
Managed-agent backend
  external agent harness; useful first implementation path

Native RedWright backend
  RedWright LLMRequestEngine, context shaping, memory, retry loop, and cheaper model routing
```

The rest of the system should not care which backend produced the result as long as the backend returns the agreed task execution result.

## Current RedWright State

RedWright already has pieces of the native path:

- ticket lifecycle and board workflow
- Telegram command routing for ticket execution
- `AgentTicketExecution` services for request building, context composition, LLM request, patch application, validation, and presentation
- `LLMRequestEngine` and context policy work
- runtime container records and generated `.rw/agent` operational setup for some project shapes
- validation through `PrimitiveExecutor`

The current gap is orchestration architecture rather than proof that an LLM can make a code change. RedWright has already demonstrated a simple Go ticket execution path. The next product problem is making agent execution repeatable, isolated, backend-selectable, traceable, and connected to kanban state.

The current validation path still runs project commands through the host shell. The future shape should route project command execution through the reusable sandbox behavior, independently of whether the task-solving backend is managed-agent or native RedWright.

## Codex as a Backend

RedWright should remain capable of using cheaper OpenRouter-backed models such as Kimi or DeepSeek, while also supporting a pragmatic managed-agent backend when that is the fastest route to useful ticket execution.

The immediate product value is agent orchestration: assigning tickets to agents, letting them work, capturing outcomes, and moving tickets through the kanban. RedWright's native intelligence layer (`LLMRequestEngine`, command preprocessing, custom context generation, context policy, memory, and cheaper model routing) should plug into the same orchestration contract as it matures.

For that reason, using Codex as the first practical backend is acceptable. It lets RedWright focus on the orchestration system first:

- ticket assignment
- backend selection
- isolated workspaces
- run lifecycle
- audit trail
- validation capture
- kanban transitions
- result promotion

The orchestration layer should be useful before every native context-intelligence detail is complete. The native path can then plug into the same behavior without rewriting ticket routing, workspace isolation, result ingestion, or kanban transitions.

The key conclusion is that Codex should not be modeled as just another LLM provider inside `LLMRequestEngine`. Codex is an agent harness. It has its own context exploration, tools, sandboxing, command execution, and iteration behavior.

Therefore, Codex fits better as an optional ticket execution backend:

- `native_llm`: RedWright-owned execution through `LLMRequestEngine`, OpenRouter/OpenAI/etc., context policies, retry loop, and validation.
- `codex_exec`: RedWright delegates a ticket to Codex CLI or SDK in a controlled scratch workspace.

This keeps RedWright focused on ticket orchestration while allowing deeper context-intelligence work to evolve behind a compatible backend contract.

## Codex Non-Interactive Operation

Official Codex documentation describes `codex exec` as a non-interactive mode for scripts and CI. It supports:

- running Codex from scripts
- `--json` event output
- `--sandbox workspace-write`
- stdin as prompt/context
- structured output schemas
- API-key-based automation with `CODEX_API_KEY`

This makes a `CodexExecBackend` worth testing as a concrete backend hypothesis.

The preferred target shape is for Codex to run inside the managed execution environment, not directly in the RedWright Rails process. In that shape, RedWright starts the task workspace and execution environment, injects the narrow Codex credential set required by the backend, invokes `codex exec` inside that environment, captures events, and then pulls the result back into RedWright.

A host-run Codex spike may still be useful as a smaller first test of process invocation and result parsing, but it does not fully validate the target sandboxed-agent behavior.

## Codex Backend Feasibility Hypothesis

The Codex-backed approach appears feasible enough to validate, but RedWright should not treat it as proven until a spike demonstrates the full boundary end to end.

The hypothesis is that Codex can be operated as a managed-agent worker while RedWright owns the task boundary:

- create or select the task workspace
- start the execution environment
- inject only the credentials required by the selected backend
- invoke Codex in non-interactive mode inside the selected run boundary
- stream or persist events
- inspect git status and diff after the run
- run RedWright-owned validation if needed
- map the outcome to `completed`, `blocked`, or `failed`
- keep final promotion under RedWright policy

If this works, the approach should also be compatible with later native execution because both paths can return the same task execution result shape.

Feasibility constraints to verify:

- Codex availability and authentication must be explicit.
- If Codex runs inside the execution environment, credential injection must be narrow and backend-specific.
- The first version should not auto-push by default.
- The first version should not mutate the canonical project workspace directly.
- RedWright should treat Codex output as an execution result, not as a domain authority.
- RedWright should retain the right to run additional validation after Codex finishes.
- If Codex cannot run, the backend should fail clearly and leave the ticket in a blocked or unchanged state according to policy.

Minimum proof needed:

- run Codex non-interactively from a RedWright-controlled boundary
- provide a scratch workspace and bounded ticket prompt
- prove where Codex runs: host process or managed execution environment
- prove how the required Codex credential is supplied
- capture structured output or enough process output for audit
- detect changed files and diff after the run
- distinguish success, blocked, and execution failure
- leave the canonical workspace untouched
- prove that RedWright can decide ticket movement from the captured result

The proposed RedWright integration shape:

```text
/ticket start RW-123 --backend codex

RedWright:
  create scratch workspace/worktree
  build a concise ticket prompt
  run codex exec --json --sandbox workspace-write -
  capture JSONL events
  inspect git diff
  run validation if needed
  update ticket state
  keep or discard scratch workspace according to policy
```

Authorization is the explicit command to start a ticket with the Codex backend. Codex should not need to ask for confirmation for each internal step, because RedWright constrains the environment and policy.

## RedWright Ownership

Even with Codex delegation, RedWright should remain responsible for:

- project registry
- ticket lifecycle
- Telegram and web surfaces
- backend selection
- scratch workspace creation
- sandbox policy
- audit trail
- result ingestion
- promotion to review, commit, push, or PR according to policy

Codex should be treated as a controlled worker backend, not as the owner of RedWright's domain model.

## Strong Direction

The current preferred direction is:

```text
AgentTicketExecution::Backends::NativeLlmBackend
AgentTicketExecution::Backends::CodexExecBackend
```

Common backend contract:

```text
call(ticket:, project:, workspace:, execution_policy:)
  -> status
  -> summary
  -> changed_files
  -> diff
  -> validation
  -> raw_events
  -> backend
```

Codex should be optional and explicit:

```text
/ticket start RW-123 --backend codex
/ticket start RW-123 --backend native
```

This gives RedWright both paths:

- independence and lower-cost model routing through native execution
- pragmatic delegation through Codex when desired

The abstraction must make these paths interchangeable at the orchestration level. RedWright should be able to develop the Codex-backed version first, then plug in the improved native backend later without rewriting project setup, ticket routing, isolated workspace handling, result ingestion, or kanban transitions.

Both backends should run under the same isolation expectations:

- ticket-scoped workspace
- no direct mutation of the canonical project workspace by default
- controlled command execution
- captured logs and events
- explicit result handoff to RedWright
- RedWright-owned promotion and ticket movement

Codex should not get a privileged architectural path. It is the first practical backend, not the domain model.

## Derived Threads

### Agent Runtime Provisioning

The `.rw/agent` setup should probably move into its own boundary rather than living inside the growing project setup context loop. A possible service namespace:

```text
AgentRuntimeProvisioning::Provisioner
AgentRuntimeProvisioning::RuntimeProfileBuilder
AgentRuntimeProvisioning::DockerfileGenerator
AgentRuntimeProvisioning::SetupMaterializer
AgentRuntimeProvisioning::ValidationService
```

This thread is related but separate from Codex delegation.

### Scratch Workspace and Branch Strategy

RedWright needs a ticket-scoped workspace strategy. Options include:

- git worktree per ticket
- clone per ticket
- branch per ticket
- cleanup or preservation policy

This is a prerequisite for both Codex and native sandboxed execution.

### Isolated Execution Boundary

RedWright needs a small boundary for isolated or delegated command execution. It should support at least:

- start
- exec
- stream or capture output
- copy in/out when needed
- close

Initial providers could be:

- local shell
- Docker
- Podman

### Credential Policy

Codex delegation and git operations require a clear credential policy. The default should avoid passing broad secrets into containers. Codex automation may use `CODEX_API_KEY` at the host integration boundary. Git push and PR creation should remain host-owned unless a later policy explicitly allows container-side credentials.

## Open Questions

- Should the first `CodexExecBackend` use CLI subprocess integration or the Codex SDK?
- Should Codex run on the host against a scratch worktree, or inside an agent runtime container?
- Should RedWright run its own validation after Codex finishes, even if Codex reports tests passing?
- Should Codex be allowed to commit, or should RedWright always inspect diff and commit itself?
- Should `/project new` still create a starter implementation ticket, or should it only materialize project setup and leave implementation tickets to explicit user intent?
- How much of `.rw/agent` is required before a Codex backend exists?
- How should backend selection be configured: project default, ticket option, user command flag, or UI selector?
