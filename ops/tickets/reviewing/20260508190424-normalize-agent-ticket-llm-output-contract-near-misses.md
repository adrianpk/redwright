---
id: TKT-20260508190424
title: Normalize agent ticket LLM output contract near misses
status: reviewing
kind: bug
severity: high
priority: high
scope: llm
tags: agent-ticket-execution, llm-contract, context, validation
source: manual_test
reported_at: 2026-05-08T19:04:24Z
ready_at: 2026-05-08T19:04:24Z
started_at: 2026-05-08T19:06:09Z
reviewed_at: 2026-05-08T19:24:39Z
closed_at:
resolution:
owner:
branch: fix/ticket-20260508190424-llm-contract-normalization
pr: https://codeberg.org/adrianpk/redwright/pulls/380
commits:
  - 7f69e27
---

## Context
Manual testing of the deterministic Go todo CLI agent-ticket scenario advanced past the previous opaque `invalid_response` failure after PR #379. The run accepted `/ticket start RW-10`, propagated the Telegram trace id, sent rich context to the coding model, and received a technically useful implementation proposal. The ticket still ended in `blocked` and the workspace remained unchanged because the LLM response used near-miss schema fields that RedWright does not currently normalize.

Observed run:

- Telegram command: `/ticket start RW-10`
- Trace: `trc-9d170a0b`
- LLM call: `llm-28a0aa5499e6`
- Ticket: `RW-10`, database id `37`
- Model role: `coding`
- Provider/model: `openai` / `gpt-5.2`
- Final board state: `blocked`
- Workspace diff after run: no filesystem differences outside `.git`
- Resolution-loop LLM interaction count: `1`
- Normalized LLM response status: `ok`
- Parsed fields: `status`, `blocking_reason`, `summary`, `changes`, `commands`, `notes`

## Problem
The LLM produced a solid, likely correct Go patch, but RedWright blocked before applying it because the response did not match the exact executable contract.

Received response shape:

```json
{
  "status": "ready",
  "blocking_reason": null,
  "summary": "Add support for `todo done <task-number>` in the CLI by parsing the task index, marking that task as done in the loaded task list, saving back to the TODO file, and printing `done: <n>` to stdout. Keep other tasks unchanged and ensure tests pass.",
  "changes": [
    {
      "type": "apply_patch",
      "path": "main.go",
      "patch": "*** Begin Patch\n*** Update File: main.go\n@@\n import (\n   \"bufio\"\n   \"fmt\"\n   \"io\"\n   \"os\"\n+  \"strconv\"\n   \"strings\"\n )\n@@\n func run(args []string, stdout io.Writer, stderr io.Writer) int {\n   if len(args) == 0 {\n-    fmt.Fprintln(stderr, \"usage: todo <add|list> [task]\")\n+    fmt.Fprintln(stderr, \"usage: todo <add|list|done> [task]\")\n     return 2\n   }\n@@\n   switch args[0] {\n   case \"add\":\n@@\n     fmt.Fprintf(stdout, \"added: %d\\n\", len(tasks))\n     return 0\n+  case \"done\":\n+    if len(args) != 2 {\n+      fmt.Fprintln(stderr, \"usage: todo done <task-number>\")\n+      return 2\n+    }\n+\n+    n, err := strconv.Atoi(strings.TrimSpace(args[1]))\n+    if err != nil || n < 1 || n > len(tasks) {\n+      fmt.Fprintln(stderr, \"usage: todo done <task-number>\")\n+      return 2\n+    }\n+\n+    tasks[n-1].Done = true\n+    if err := saveTasks(todoFilePath(), tasks); err != nil {\n+      fmt.Fprintf(stderr, \"save tasks: %v\\n\", err)\n+      return 1\n+    }\n+\n+    fmt.Fprintf(stdout, \"done: %d\\n\", n)\n+    return 0\n   case \"list\":\n     for index, task := range tasks {\n       marker := \" \"\n       if task.Done {\n         marker = \"x\"\n       }\n       fmt.Fprintf(stdout, \"%d. [%s] %s\\n\", index+1, marker, task.Text)\n     }\n     return 0\n   default:\n     fmt.Fprintf(stderr, \"unknown command: %s\\n\", args[0])\n     return 2\n   }\n }\n*** End Patch"
    }
  ],
  "commands": [
    {
      "cmd": "go fmt ./...",
      "cwd": "/home/adrian/Projects/redwright/redwright/_workspace/Projects/go-todo-agent",
      "purpose": "Format Go code after changes."
    },
    {
      "cmd": "go test ./...",
      "cwd": "/home/adrian/Projects/redwright/redwright/_workspace/Projects/go-todo-agent",
      "purpose": "Run unit tests to ensure `done` command behavior passes acceptance criteria."
    }
  ],
  "notes": [
    "This implementation uses only the Go standard library (`strconv` for parsing the task number).",
    "Behavior for invalid/missing task number returns exit code 2 and prints `usage: todo done <task-number>` to stderr.",
    "The top-level usage string was updated to include `done` for clarity; tests do not depend on this but it matches the new command set."
  ]
}
```

Current executable contract expects:

```json
{
  "status": "proposed_changes",
  "files": [
    {
      "path": "main.go",
      "patch": "*** Begin Patch..."
    }
  ],
  "commands": [
    {
      "command": "go test ./..."
    }
  ]
}
```

Near misses:

- `status: "ready"` should be rejected or normalized to `proposed_changes`.
- `changes` should be rejected or normalized to `files`.
- `commands[].cmd` should be rejected or normalized to `commands[].command`.
- `changes[].type: "apply_patch"` is useful metadata but is not currently part of the executable `files` contract.
- The loop blocks immediately before applying anything, so no validation feedback is generated and no retry loop occurs.

## Response Assessment
The LLM response is technically strong for the requested task.

- The patch is small and targeted.
- It uses only Go standard library code.
- `strconv.Atoi` is idiomatic for parsing the task index.
- It preserves existing open tasks by only mutating `tasks[n-1].Done`.
- It saves through the existing `saveTasks` helper.
- It prints the expected `done: <n>` stdout used by the provided tests.
- It proposes `go fmt ./...` and `go test ./...`.
- The likely correctness level is high for this fixture.

This is not primarily a model-reasoning failure. It is a contract/schema alignment failure between the LLM prompt, `AgentTicketExecution::LlmContract`, and `AgentTicketExecution::OutputApplier`.

## What Was Sent
The request payload was rich enough for this simple Go todo ticket.

Top-level request:

- `action`: `agent_ticket_execution`
- `ticket_id`: `37`
- `ticket_title`: `Implement done command`
- `ticket_description`: add `done <task-number>`, mark task 1 as done, preserve other tasks, pass `go test ./...`, use only stdlib.
- `mode`: `targeted`
- `branch_name`: `null`

Context sections sent:

- `ticket`: full ticket metadata and body, including `ticket_key`, `display_key`, assignee, priority, workflow status, kind, severity, scope, source, request mode, source channel, and actor.
- `project`: project id/name, description, root path, local repo url, `go` stack slug, and project attributes.
- `repository_tree`: 6 files only:
  - `.gitignore`
  - `.rw/agent/Dockerfile`
  - `.rw/agent/runtime-setup.json`
  - `go.mod`
  - `main.go`
  - `main_test.go`
- `relevant_files`: full content of `.rw/agent/Dockerfile`, `go.mod`, `main.go`, and `main_test.go`.
- `tests`: full content of `main_test.go`.
- `operational_setup`: `.rw/agent` runtime setup, Dockerfile path, runtime metadata path, root-relative paths, and production Dockerfile separation flag.
- `protocol_files`: 21 model-backed protocol documents, including `AGENTS.md` and `.agents/**` protocol docs.
- `protocol_model`: metadata only, with content omitted because it is duplicated by `protocol_files`.
- `previous_interactions`: present but empty, with `human_chat_included: false`.

Context not sent in this run:

- Tree-sitter or symbol-level code context.
- External or language/library docs beyond repository protocols.
- LLM-derived docs or provider-side documentation context.
- Linter errors.
- Compile errors.
- Runtime errors.
- Validation feedback.
- Useful previous agent/LLM conversation, because this was the first resolution attempt and previous interactions were empty.

## Context Coverage Questions
This ticket should address the schema mismatch and explicitly decide which context categories are required for the next reliable iteration.

Tree-sitter:

- Not present in this run.
- Question: is Tree-sitter intentionally out of scope for the current composer, or should minimal symbol/code-structure extraction be added before retry loops become serious?
- Expected decision: either add a minimal `code_symbols`/Tree-sitter context section, or document that file-level context is enough for this fixture phase.

LLM docs / external docs:

- Not present in this run.
- For this Go stdlib todo case, external docs are probably unnecessary.
- Question: when a ticket references framework/library APIs not visible in repo context, do we need a docs-provider context section?
- Expected decision: keep absent for this fixture unless the ticket references APIs not present in repository context.

Linter, compile, and runtime errors:

- Not present because no patch was applied and no validation ran.
- Question: after a first attempt applies but validation fails, should feedback re-enter as separated sections such as `lint_errors`, `compile_errors`, and `runtime_errors` instead of one generic `validation_feedback` blob?
- Expected decision: preserve structured feedback enough for a second LLM iteration to reason about the failure.

Previous conversation:

- Present as `previous_interactions`, but empty.
- Question: after a recoverable schema mismatch, should the invalid-but-useful LLM response be stored as a previous interaction before retrying?
- Expected decision: likely yes, because it contains a useful patch and should not be discarded.

Protocols:

- Present through model-backed `protocol_files`.
- `protocol_model` content was omitted while metadata was retained.
- Question: should 21 protocol docs remain in the prompt, or should the protocol payload be further reduced or selected by relevance?
- Expected decision: keep broad protocol context for now unless payload size or output quality suffers, but keep the question visible for future optimization.

Agent/project context:

- Present and useful.
- Question: should `operational_setup` or a new executable-contract context section explicitly tell the LLM which primitive output schema RedWright can execute?
- Expected decision: yes. The model invented reasonable-but-wrong schema fields, so the executable contract should be shown more concretely in the prompt.

## Expected
- RedWright should not block immediately on a recoverable near-miss response that contains a valid patch and commands.
- The agent ticket execution contract should be explicit enough that models return `proposed_changes`, `files`, and `commands[].command`.
- A defensive normalizer should handle common near-miss aliases when the response is otherwise safe and executable.
- Normalization should be trace-visible so debugging can distinguish exact contract compliance from corrected aliases.
- The first successful attempt should apply the patch, run validation, and either move the ticket to review or enter a second LLM iteration with structured feedback.

## Actual
- LLM response was normalized as `ok` by the request engine.
- `LlmContract` rejected the semantic payload because `status: "ready"` is outside `proposed_changes`, `needs_correction`, and `blocked`.
- `changes` was not treated as executable `files`.
- `cmd` was not treated as executable `command`.
- The loop returned `blocked`.
- The ticket moved to the `blocked` column.
- No patch was applied.
- No validation command ran.
- No second iteration occurred.

## Fix Strategy
- Strengthen `AgentTicketExecution::LlmContract.system_prompt` with a concrete JSON example using the exact executable keys.
- Add a response-normalization layer for safe near misses:
  - `ready` -> `proposed_changes`
  - `changes` -> `files`
  - `commands[].cmd` -> `commands[].command`
  - preserve `purpose` as metadata if useful, but do not require it for execution.
- Record normalization diagnostics in traces and/or previous interaction records.
- Ensure invalid-but-useful responses can be retained as previous interaction context for retry when they cannot be normalized.
- Decide whether to add an explicit executable-contract context section to the LLM request.
- Decide whether Tree-sitter/symbol context and external docs are required now or explicitly deferred.
- Add focused tests with the exact response shape from `trc-9d170a0b`.

## Validation
- Reset the deterministic scenario with `make agent-ticket-scenario-ready`.
- Trigger `/ticket start RW-10`.
- Confirm the LLM response shape from the captured trace is accepted or normalized.
- Confirm `main.go` is patched.
- Confirm `go fmt ./...` and `go test ./...` run.
- Confirm the ticket moves to review when validation passes.
- Confirm `.log/llm.ndjson` records any schema normalization performed.
- Confirm `make agent-ticket-scenario-inspect` shows a meaningful diff or a committed/review-ready state, not an unexplained blocked state.
- Run focused unit tests for `LlmContract`, `LlmRequester`, `OutputApplier`, and the validation loop.
- Run `scripts/agent/tickets/check.sh`.

## Outcome
Implemented in PR #380.
