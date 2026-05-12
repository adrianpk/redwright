# Go Todo Agent Proof Fixture

This repository is a small Go CLI todo application used as a controlled fixture
for the RedWright Codex black-box engine proof.

RedWright uses this repository to validate that a Codex-based managed worker can:

- run inside a Docker-controlled execution environment
- receive a bounded ticket-like task packet
- clone an existing Codeberg repository into an isolated workspace
- implement a small feature in a Go project
- add or update tests
- run `go test ./...`
- push the result to a run-scoped branch
- return logs, diff metadata, validation output, and branch metadata to RedWright

## What The Operator Should See

A successful proof run should leave visible evidence for the operator:

- a run-scoped branch pushed to this repository
- a readable commit produced by the worker
- container logs captured by RedWright
- a result artifact that records status, branch, changed files, diff location, and validation output
- `go test ./...` output from the worker workspace

The repository itself is part of the proof. The operator should be able to open
the pushed branch on Codeberg and inspect the implementation that the managed
worker produced.

## Clean Fixture Policy

The default branch is the clean reusable fixture state. Proof executions must not
push directly to the default branch.

Each proof run should use a disposable branch such as:

```text
redwright/codex-proof/<run-id>
```

Resetting the fixture means deleting or replacing only the run-scoped branch.
The clean default branch should remain stable so repeated RedWright proof runs
start from the same base project.

## Current Proof Task

The initial RedWright proof task asks the managed worker to add a user-facing
mark-as-read capability to the todo CLI and cover the behavior with tests.
