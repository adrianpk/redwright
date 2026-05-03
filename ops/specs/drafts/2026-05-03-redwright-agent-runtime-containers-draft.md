# RedWright Agent Runtime Containers Draft

## Status

- type: `spec-draft`
- date: `2026-05-03`
- source: alignment conversation about ticket execution, sandboxed agent work, and project-tuned runtime containers

## 1. Scope

This draft defines the product need for agent runtime container specifications in RedWright.

It does not define the final Docker implementation, Rails schema, controller structure, container orchestration engine, production deployment model, or security-hardening details.

The need has three equal parts:

- generate a useful initial Docker setup for agent work
- expose that setup for inspection and correction in the Rails application
- make ticket execution consume the resulting setup when agents work in a sandbox

## 2. Problem Statement

RedWright's intended execution model is ticket-first agent work. Agents inspect the board, select eligible tickets by assignment and priority, and execute ticket lifecycle phases such as coding, review, and merge.

Those agents should not rely only on the host machine environment. They need project-specific sandbox runtime containers that provide the dependencies, tools, filesystem mounts, credentials policy, and commands required to work safely and reproducibly on a project.

The current project setup model already captures `runtime_container_profile`, and recent runtime bridge work passes runtime context from Rails tickets into the runtime. However, the actual container specification is still mostly an intended contract rather than an editable project artifact.

## 3. Product Need

The Rails application needs a first-class place to manage the agent runtime container specification for each project.

This specification describes the containers used by agents to perform development work, including:

- coding a ticket
- running tests and linters
- preparing or updating branches
- performing review checks
- preparing merge work when the role allows it

This is not the same as the production deployment specification for the user's application. It may be derived from the same stack knowledge, but its purpose is agent execution in a sandbox.

The product should treat the agent Docker setup as a project artifact that can be generated, reviewed, edited, validated, and then used by runtime execution.

## 4. Terminology

The product concept should be called `Runtime Containers`.

`Runtime Containers` means the project-specific container/deployment files and metadata that define how RedWright agents execute work for that project.

The term should remain distinct from `Protocols`:

- `Protocols` bias agent behavior, rules, and project operating context.
- `Runtime Containers` define the sandbox execution environment used by agents.

## 5. Project-Specific Runtime Container Copy

Each project should have a concrete editable Runtime Containers configuration.

It may be created from:

- setup answers
- project stack and framework inference
- repository inspection
- Protocol content
- known stack templates
- LLM-generated best guess
- later manual edits in the Rails application

After creation, the project-specific Runtime Containers configuration belongs to the project. Editing it should tune that project only and should not mutate reusable templates.

## 6. LLM Inference Role

During project setup, the LLM may infer a reasonable initial runtime container specification.

The inference should consider:

- project type
- language runtime
- framework
- libraries
- repository files when available
- documented project conventions
- Protocol content
- prior setup answers
- known stack profiles

When project documents conflict, newer project documents should generally receive more decision weight than older documents because project understanding evolves over time. This is a heuristic, not an absolute rule; explicit user edits or accepted project Protocols should override stale assumptions.

The inferred result should be treated as editable scaffolding, not as an irreversible decision.

## 7. LLM Docker Setup Generation

The LLM should be able to generate an initial Docker-oriented setup that is practical for agent work.

The generated setup should describe enough information for the runtime to prepare a sandbox, such as:

- base image or runtime image family
- language/runtime version
- operating system packages
- package manager commands
- dependency installation commands
- test, lint, build, and formatting commands
- working directory
- repository mount strategy
- cache mount strategy when useful
- environment variables needed for local execution
- secret placeholders without embedding secret values
- network assumptions
- user/permission expectations
- validation command that proves the container can run useful work

The LLM should produce structured metadata with the generated files, including:

- input signals used
- confidence
- assumptions
- missing information
- risks
- commands that should be validated before enabling agent execution

The generated Docker setup should be good enough for coding, review, and merge preparation work. It does not need to match the final production deployment architecture.

## 8. Rails Management Surface

The Rails application should expose a CRUD surface for Runtime Containers.

The project-level surface should allow users to:

- inspect the current generated runtime container files
- edit the files or structured fields
- see what stack/setup signals produced the initial guess
- tune commands, packages, mounts, environment variables, and runtime profile details
- trigger regeneration from current project context
- compare regenerated suggestions against the current project-specific setup
- accept, reject, or manually merge generated changes
- run or record validation status
- mark the configuration ready for agent execution

The purpose of this CRUD is correction and tuning. If the LLM best guess is imperfect, the user must be able to adjust the sandbox environment without leaving RedWright.

The Rails CRUD is also the point where generated Docker setup stops being just an LLM suggestion and becomes the concrete project Runtime Containers configuration.

## 9. Expected Artifact Shape

The final artifact shape is out of scope for this draft, but the product must support materializing project Runtime Containers into concrete files.

Possible projections include:

- `Dockerfile`
- `Containerfile`
- compose/deployment files for local agent execution
- RedWright runtime container metadata
- setup scripts or dependency bootstrap files

The exact filenames and filesystem location should be defined later. The important product requirement is that the Rails-managed project configuration can become executable container files for the runtime.

## 10. Role and Lifecycle Needs

Runtime Containers may be shared across agent roles or specialized by lifecycle phase.

The system should allow later differentiation for:

- coder environment
- reviewer environment
- merger environment

The first implementation may use one project runtime container if that is sufficient, but the model should not assume that coding, review, and merge always require identical permissions, credentials, or mounted resources.

## 11. Relationship to Ticket Execution

Ticket execution should consume the project Runtime Containers configuration when starting work.

The runtime bridge should not only pass a string profile such as `ephemeral_docker`; it should eventually pass or resolve the concrete project runtime container configuration needed to execute the ticket.

The runtime should use this configuration to prepare the sandbox before executing agent work.

If the project Runtime Containers configuration is missing, invalid, or not marked ready, ticket execution should surface that as an explicit readiness problem rather than silently falling back to host execution.

## 12. Relationship to Production Deployment

Runtime Containers are for RedWright agent execution, not production deployment.

A project may later have separate production deployment artifacts. Those artifacts should not be treated as interchangeable with the agent sandbox unless the user explicitly chooses to align them.

This distinction matters because agent containers may need development tools, test dependencies, debug utilities, repository mounts, and restricted credentials that are not appropriate for production images.

## 13. Desired Behavior

- Project setup can generate an initial Runtime Containers configuration.
- The generated configuration can be inferred from stack, repository, setup answers, Protocol, and recent project documents.
- The LLM can generate Docker setup files and structured metadata for agent execution.
- The user can edit the generated configuration from Rails.
- The user can regenerate, compare, accept, reject, or manually tune generated Docker setup changes.
- The user can validate or mark readiness before agents depend on the setup.
- Ticket execution can resolve the project Runtime Containers configuration.
- Agent work can eventually run inside the configured sandbox instead of directly on the host.
- Runtime Containers remain separate from production deployment artifacts.
- The system preserves provenance for the generated best guess and later user edits.

## 14. Out of Scope

- Docker/Podman implementation details
- final filesystem layout
- container security hardening
- secrets management
- remote builder support
- Kubernetes or production deployment design
- multi-agent scheduling
- complete role-separated runtime pool behavior

## 15. Open Questions

- Should a project start with one runtime container or role-specific containers for coder, reviewer, and merger?
- Should Runtime Containers have reusable stack templates similar to Protocol stack overlays?
- Should users edit raw files, structured fields, or both?
- Should the runtime block ticket execution until Runtime Containers are marked ready?
- What minimum validation should run before a Runtime Containers configuration is accepted?
- Where should materialized files live relative to the project workspace and `.redwright/manifest.yml`?
- Should regeneration create proposed changes only, or may it update the project Runtime Containers draft directly?
- Which generated assumptions require explicit human approval before ticket execution?

## 16. Next Iteration Inputs

- define the first Rails UI slice for project Runtime Containers
- define minimum fields/files for a usable `ephemeral_docker` agent sandbox
- define how `/project new` stores generated Runtime Containers provenance
- define the runtime bridge contract for resolving concrete container configuration
- define validation commands for generated container specs
- define the LLM output contract for Docker setup generation
- define readiness states for generated, edited, validated, and active Runtime Containers
