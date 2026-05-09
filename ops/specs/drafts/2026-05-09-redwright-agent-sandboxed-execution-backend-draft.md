# RedWright Agent Sandboxed Execution Backend Draft

## Metadata

- id: `draft-2026-05-09-redwright-agent-sandboxed-execution-backend`
- status: `draft`
- owner: `adrianpk`
- created: `2026-05-09`
- updated: `2026-05-09`
- scope: `agent-ticket-execution/runtime-containers/sandboxed-command-execution`

## Summary

RedWright should preserve the current project workspace model while making command execution sandboxed through an explicit execution backend.

The current agent ticket path can materialize an operational Dockerfile and runtime metadata under `.rw/agent`, but validation commands still execute through the host shell inside the workspace. This means the runtime container configuration currently behaves as context, readiness metadata, and command source, not as the actual isolation boundary for ticket execution.

The next useful step is not to replace `_workspace`; it is to make `run` actions execute through a configurable backend. In the sandboxed mode, that backend should build and run the project-specific agent container using the materialized operational setup.

## Current Reality

The Go manual testcase under `_workspace/Projects/go-todo-agent` has the expected operational setup files:

- `.rw/agent/Dockerfile`
- `.rw/agent/runtime-setup.json`

However, the current validation path executes commands through the primitive executor with a local shell command equivalent to:

```sh
timeout --preserve-status <seconds> sh -lc "<command>"
```

This runs in the workspace directory on the host. It does not build a Docker image, start a Docker container, or execute validation inside the materialized Dockerfile.

The current Runtime Containers model is therefore partially operational:

- it can store and expose runtime container metadata
- it can provide generated files
- it can materialize an agent Dockerfile
- it can provide validation commands
- it can block execution based on readiness

But it does not yet enforce containerized execution for agent ticket work.

## Goal

RedWright should fulfill the sandboxing promise for single-agent-per-project ticket execution.

The agent may continue to work against a project checkout under `_workspace` in development, or another configured workspace root in production. The important boundary is that any shell command that executes project code should run inside the configured sandbox, not directly on the host.

## Non-Goals

This draft does not require:

- multi-agent scheduling
- multi-developer merge orchestration
- production deployment containers
- automatic Dockerfile generation in the first implementation
- remote container builders
- Kubernetes or long-lived orchestration
- replacing the current workspace layout

## Core Model

Separate two concepts that are currently easy to conflate:

1. **Workspace root**
   The checkout that the agent modifies.

2. **Execution backend**
   The mechanism used to execute commands against that checkout.

The workspace can remain:

```text
_workspace/Projects/<project>
```

The execution backend can be one of:

```text
local_shell
docker_container
```

The local shell backend preserves current behavior. The Docker backend enforces sandboxed command execution.

## Execution Backend Boundary

The natural technical boundary is `run` actions.

The current primitive executor already centralizes command execution. Instead of having `execute_run` always call the host shell, it should delegate to an execution backend:

```text
ValidationLoop
  -> workspace.primitive_executor.execute(type: "run")
    -> ExecutionBackend
      -> LocalShellBackend
      -> DockerBackend
```

The first sandboxed implementation should focus on `type: "run"`.

Host-side operations that do not execute project code can remain outside Docker:

- reading files
- writing files
- applying patches
- listing repository state
- computing diffs
- checking Git status

Commands that execute project code or tooling should go through the selected backend:

- tests
- linters
- builds
- formatters
- diagnostics
- agent-requested shell commands
- validation commands

## Runtime Setup Contract

The Docker backend should initially consume the manually provided or materialized runtime setup:

```text
.rw/agent/Dockerfile
.rw/agent/runtime-setup.json
```

The setup metadata should be able to describe:

- execution backend
- Dockerfile path
- image name or image name seed
- working directory inside the container
- repository mount source and target
- mount mode
- validation commands
- cache mounts
- environment policy
- network policy
- resource limits

Example shape:

```json
{
  "execution_backend": "docker",
  "dockerfile": ".rw/agent/Dockerfile",
  "image_name": "redwright-agent-go-todo",
  "working_directory": "/workspace",
  "repository_mount": {
    "source": ".",
    "target": "/workspace",
    "mode": "rw"
  },
  "validation_commands": ["go test ./..."]
}
```

## Docker Execution Shape

The Docker backend should build an image from the operational Dockerfile and run commands with the workspace mounted into the container:

```sh
docker build -f .rw/agent/Dockerfile -t <image_name> .rw/agent
```

```sh
docker run --rm \
  -v "$WORKSPACE:/workspace:rw" \
  -w /workspace \
  <image_name> \
  sh -lc "<command>"
```

The exact command builder should be owned by RedWright, not by LLM output. The LLM may propose runtime metadata, but the runtime must construct the Docker invocation from validated fields.

## Sandboxing Defaults

The Docker backend should prefer restrictive defaults:

- no host shell execution for `run` actions
- explicit workspace mount
- explicit working directory
- no implicit secret forwarding
- resource limits when available
- network disabled by default when the command does not require dependency download
- structured failure if Docker is unavailable, the image build fails, or metadata is incomplete

Potential Docker flags:

```sh
--network none
--cpus 2
--memory 2g
--pids-limit 512
```

Read-only root filesystem may be useful later, but it should not be forced until cache and temporary directory behavior is modeled correctly.

## Cache Mounts

Some language toolchains need writable caches. The Docker backend should make these explicit rather than silently writing across the container filesystem.

For Go, likely cache mounts include:

```text
.rw/cache/go-build -> /root/.cache/go-build
.rw/cache/go-mod   -> /go/pkg/mod
```

Cache mounts should be project-local and visible under the operational area so the sandbox remains understandable and cleanable.

## Backend Selection

The backend can start as a simple project/runtime setting.

Possible values:

```text
local_shell
docker_container
```

For development compatibility, `local_shell` may remain available. For the production promise of sandboxed execution, `docker_container` should become the expected backend for agent ticket execution.

If the selected backend is `docker_container` and required setup is missing, RedWright should block explicitly. It should not silently fall back to host execution.

## Image Build and Reuse

The Docker image should be rebuilt only when relevant setup changes.

A practical cache key can be derived from:

- `.rw/agent/Dockerfile`
- `.rw/agent/runtime-setup.json`
- selected runtime container metadata

The first version can build synchronously when ticket execution starts. Later versions can prebuild during project setup or runtime container validation.

## Relationship to LLM Generation

The first implementation can rely on a manual or already materialized setup.

Later, the agent or LLM-based setup flow may generate the Docker setup itself. That generation should be treated as a separate capability:

1. infer or generate runtime setup
2. validate setup
3. mark runtime setup ready
4. execute ticket commands through the selected backend

Generating the sandbox definition is itself a more complex version of solving a project setup ticket. It should not be required before RedWright can execute commands inside a manually provided sandbox.

## Failure Behavior

Sandbox-related failures should be structured and visible in ticket execution traces.

Examples:

- `execution_backend_missing`
- `dockerfile_missing`
- `runtime_setup_invalid`
- `docker_unavailable`
- `docker_build_failed`
- `docker_run_failed`
- `workspace_mount_invalid`
- `validation_commands_missing`

These failures should block the ticket rather than allowing unsafe host execution.

## Trace Requirements

Traces should make the execution boundary auditable.

Each command execution should record:

- selected execution backend
- Dockerfile path when applicable
- image name or image digest when applicable
- workspace mount source and target
- working directory
- command
- timeout
- exit status
- stdout and stderr summaries
- whether the command ran on host or inside Docker

This trace information is necessary to confirm that sandboxing is actually happening.

## Minimal First Slice

A minimal implementation could:

1. Add an execution backend abstraction for `run` actions.
2. Keep local shell behavior behind `local_shell`.
3. Add `docker_container` backend using `.rw/agent/Dockerfile`.
4. Build an image from the operational Dockerfile.
5. Run validation commands inside Docker with the workspace mounted.
6. Block explicitly when Docker setup is missing or invalid.
7. Add trace fields proving which backend executed each command.

This would preserve the current workspace model while making the execution boundary real.

## Open Questions

- Should `docker_container` become the default for production agent ticket execution immediately?
- Should network access be disabled by default, or should dependency-install phases allow it explicitly?
- Should Docker image build happen during project setup, runtime container readiness validation, or ticket execution?
- Should cache mounts be declared by runtime metadata or inferred per language profile?
- Should the backend apply to Git commands as well, or only arbitrary project commands?
- Should Docker be the only sandbox backend, or should the abstraction allow Podman or another OCI runtime later?
