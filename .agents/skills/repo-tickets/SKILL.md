---
name: repo-tickets
description: Use when working in a repository that follows the ops/tickets Markdown ticket workflow and the user asks to capture, create, list, search, triage, move, check, or explain repository development tickets. Trigger on phrases such as ticket capture, capture round, triage auto, triage manual, ready tickets, check tickets, or ticket workflow.
metadata:
  short-description: Operate repository development tickets
---

# Repository Tickets

Use this skill only inside repositories that follow the `ops/tickets` Markdown ticket workflow.

The source of truth is the repository workflow, not this skill:

- `.agents/playbooks/ticket-workflow.md`
- `ops/tickets/TEMPLATE.md`
- `scripts/agent/tickets/help.sh`
- `scripts/agent/tickets/new.sh`
- `scripts/agent/tickets/search.sh`
- `scripts/agent/tickets/check.sh`

## Startup

1. Confirm the current repository has `.agents/playbooks/ticket-workflow.md`, `ops/tickets/TEMPLATE.md`, and `scripts/agent/tickets/`.
2. Read `.agents/playbooks/ticket-workflow.md` before changing ticket files.
3. Prefer the ticket helper scripts over hand-written shell pipelines.
4. Run `scripts/agent/tickets/check.sh` after modifying tickets.

## Common Commands

Show the operator help:

```sh
scripts/agent/tickets/help.sh
```

List ready tickets:

```sh
scripts/agent/tickets/search.sh --status ready
```

List ticket file paths for a status:

```sh
scripts/agent/tickets/search.sh --status open --format paths
```

Validate ticket metadata and directory alignment:

```sh
scripts/agent/tickets/check.sh
```

Create a low-friction captured ticket:

```sh
scripts/agent/tickets/new.sh "Ticket title" --body "Observed behavior and expected outcome."
```

## Workflow Vocabulary

- `capture`: create one or more tickets from user-provided rough descriptions. Keep classification as `unclassified` unless obvious.
- `capture round`: loop over multiple ticket descriptions. Ask only useful clarifying questions, up to the playbook limit.
- `triage manual`: ask the user before assigning ambiguous classification, priority, severity, scope, or status.
- `triage auto`: classify conservatively. Move a ticket to `ready` only when the expected outcome is actionable without further product alignment.
- `ready`: implementation can start.
- `in_progress`: the ticket is currently being implemented.
- `reviewing`: implementation is done and awaiting review or merge.
- `solved`: implementation has been merged or technically resolved.
- `closed`: administratively closed.

## Rules

- Do not duplicate the playbook content here.
- Do not create tickets for the agent workflow itself unless the requested change belongs to the product or repository being developed.
- Keep ticket content in English.
- Keep status frontmatter aligned with the directory name.
- Use conservative classification when severity, priority, or scope is contextual.
- Prefer one ticket as one implementation unit unless the ticket proves too large and needs an explicit split.
