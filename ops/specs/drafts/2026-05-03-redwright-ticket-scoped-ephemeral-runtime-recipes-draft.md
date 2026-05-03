# RedWright Ticket-Scoped Ephemeral Runtime Recipes Draft

## Status

- type: `spec-draft`
- status: `draft`
- date: `2026-05-03`
- source: clarification that Runtime Containers are project recipes for per-ticket ephemeral agent sandboxes, not long-lived development environments

## 1. Scope

This draft clarifies the intended product model for Runtime Containers after the initial Runtime Containers cycle.

It focuses on the missing requirement that project setup must produce stack-aware runtime recipes that ticket agents can use to create short-lived work containers on demand.

This draft does not define the final Docker or Podman adapter implementation, container security policy, process supervisor, remote builder, or exact branch and pull request automation protocol.

## 2. Core Product Need

RedWright is a ticket-first software factory. A project is created through `/project new`, the setup conversation collects enough context to understand the project stack, and agents later take assigned tickets from the Kanban board.

Each ticket execution needs a suitable transient work environment. The agent should not use a generic host environment or a long-lived shared development container.

The setup flow must therefore generate a project-level Runtime Containers recipe that can be reused to instantiate ticket-scoped ephemeral containers.

The core relationship is:

- `ProjectRuntimeContainer` is the persistent project recipe.
- `TicketExecution` is one short-lived runtime session created from that recipe.
- The physical container is created for one ticket, used for that ticket's work, and destroyed after completion or failure.

## 3. Required Lifecycle

The intended lifecycle is:

1. A user starts project setup with `/project new`.
2. RedWright asks setup questions and uses LLM or deterministic stack logic to identify the project type, language runtime, framework, libraries, repository, and workflow expectations.
3. Rails persists the project and setup context.
4. Rails generates a project Runtime Containers recipe from that context.
5. The recipe stores the base image, dependency commands, test commands, lint/build/format commands, working directory, repository mount policy, generated file proposals, validation command, assumptions, missing information, and risks.
6. If the recipe is incomplete, Rails creates or exposes readiness work before ticket execution can proceed.
7. An agent picks an assigned ticket from the Kanban board.
8. Ticket execution resolves the project recipe and refuses to start if it is missing, blocked, stale, or not ready.
9. If the recipe is ready, the runtime adapter creates an ephemeral sandbox for that ticket.
10. The agent works inside that sandbox, validates the change, commits, pushes, and opens or updates a pull request.
11. The runtime tears down the ticket sandbox.

## 4. Recipe Semantics

Runtime Containers should be described as recipes, not as live containers.

A recipe is durable project configuration. It answers:

- which image family or base image should be used
- which runtime version is required
- where the repository is mounted
- which dependency setup commands should run
- which commands prove work is valid
- which generated files are needed
- which secrets or environment placeholders are allowed
- which assumptions and risks remain
- whether the recipe is ready for ticket execution

A recipe must not imply that a container already exists.

The runtime creates containers from recipes only at ticket execution time.

## 5. Web Management Requirement

Runtime Containers recipes must be editable from the web application as a project-level feature or entity.

The setup process should estimate an initial recipe from the project setup conversation, repository hints, stack signals, and available deterministic or LLM-backed generators.

That initial estimate is not final authority. After setup, the user must be able to inspect, correct, replace, and fine-tune the recipe from the project's web CRUD surface.

The web surface should support project-specific judgment. A user may decide that the generated recipe is close enough and only adjust commands or image versions, or they may replace the generated recipe with a better hand-authored configuration for that particular project.

This means Runtime Containers should behave like durable project configuration:

- created or estimated during `/project new`
- persisted as part of the project model
- editable independently of the setup conversation
- reviewable before it is marked ready
- replaceable when the generated estimate is wrong
- consumed by ticket execution only after readiness requirements are satisfied

## 6. Stack-Aware Generation Requirement

Runtime Containers generation must not be Go-specific.

Go CLI can remain one deterministic supported profile, but `/project new` must eventually generate useful recipes for the common stacks RedWright is expected to operate on.

Examples:

- Ruby or Rails projects should produce a Ruby image, Bundler setup commands, Rails or Ruby test commands, and appropriate working directory and cache policy.
- Go projects should produce a Go image, module download commands, Go test, Go vet, and Go build commands.
- Node projects should produce a Node image, npm/yarn/pnpm install commands, test commands, and package manager cache policy.
- Python projects should produce a Python image, pip/uv/poetry setup commands, pytest or project-specific test commands, and virtual environment assumptions.

If deterministic generation cannot support a stack, an LLM-backed generator may propose a structured recipe. That output must still go through the same validation, readiness, and review rules.

Unsupported or ambiguous contexts must become explicit blocked recipes, not silent host execution.

## 7. Generated Files and Materialization

The recipe may contain generated file proposals such as:

- `Dockerfile`
- `Containerfile`
- `.redwright/runtime-containers.json`
- setup scripts
- compose files for local agent execution

Generated file proposals are not automatically equivalent to committed workspace files.

The product needs a later materialization step that writes accepted generated files into the project workspace or repository before a runtime adapter attempts to build or run the ticket container.

Materialization must be traceable and reviewable because generated container files may become part of the project repository.

## 8. Ticket-Scoped Runtime Contract

When a ticket starts, Rails should provide the runtime adapter with:

- project identity
- ticket identity
- Runtime Containers recipe id
- readiness and validation state
- base image or image family
- repository root on the host
- repository mount target inside the sandbox
- working directory inside the sandbox
- generated files or materialized file paths
- dependency commands
- validation, test, lint, build, and format commands
- branch, commit, push, and pull request expectations when those are formalized

The runtime adapter should then:

- create a container/session scoped to the ticket
- mount or copy the ticket workspace
- run setup commands
- invite or launch the agent inside that sandbox
- run validation commands before completion
- publish changes according to the ticket workflow
- destroy the sandbox

No ticket should reuse another ticket's mutable container state.

## 9. Readiness Boundary

Ticket execution must not create an ephemeral sandbox unless the project recipe is ready.

Readiness means:

- required execution fields are present
- generated file proposals are accepted or explicitly skipped
- validation has passed or has been explicitly skipped with a reason
- no blocking risk remains unresolved
- validation is not stale after critical edits

If readiness fails, the agent receives a structured problem and should work the readiness ticket or ask for operator input instead of modifying the project code.

## 10. Open Design Questions

- Which stack profiles should be deterministic before LLM generation is used?
- Should accepted generated files be committed to the target project repository before the first ticket execution?
- Should each ticket get a fresh clone, a worktree, or a mounted existing checkout?
- How should runtime teardown handle failed validation while preserving logs and diffs?
- How should secrets be injected without persisting secret values in Rails?
- Should reviewer and merger roles use the same recipe as coder roles or narrower specialized recipes?

## 11. Next Formalization Target

This draft should be promoted into a formal spec before implementing the physical ephemeral container adapter.

The next formal spec should define:

- stack-aware recipe generation for Ruby, Go, Node, and Python
- generated file materialization rules
- ticket-scoped sandbox lifecycle
- runtime adapter request and response shape
- teardown and artifact retention behavior
- how commits, pushes, and pull requests are coordinated from inside the ticket sandbox
