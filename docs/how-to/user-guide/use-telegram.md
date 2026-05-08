# Use Telegram

## Purpose

Use Telegram as the practical control channel for project setup, project context, ticket lookup, ticket execution, planning hints, and runtime control.

## Before You Start

- Configure `telegram.bot_token`.
- Start the local stack or at least the runtime server plus Telegram ingress.
- Confirm the Telegram bot is reachable from your chat.
- If `allowed_chat_ids` is not empty, make sure your chat ID is included.

## Steps

1. Start the full foreground stack.

```bash
bundle exec rake app:run:foreground
```

2. Create a project from Telegram.

```text
/project new my-project
```

You can also include a short description:

```text
/project new my-project "A small CLI for local notes"
```

The setup flow may ask follow-up questions. Answer in the same chat.

3. Inspect project context.

```text
/project list
/project where
```

4. Clone and register a repository.

```text
/repo clone https://example.com/acme/tool.git
/repo clone https://example.com/acme/tool.git as tool
```

5. Check repository state.

```text
/repo status
```

6. Work with tickets.

```text
/ticket list
/ticket pick
/ticket start <ticket-key>
```

Use the ticket key shown on the board, for example:

```text
/ticket start RW-10
```

Ticket execution is asynchronous. Telegram returns an initial acknowledgement
quickly and sends the final completed or blocked result after RedWright finishes
the execution loop.

7. Send planning and continuation hints.

```text
/plan start
/plan continue
/plan stop-and-apply
/continue
/status
```

8. Control current task flow.

```text
/pause
/resume
/cancel
```

Task-scoped aliases are also accepted:

```text
/task pause
/task resume
/task cancel
```

9. Use skills when available.

```text
/skills
/skill <name>
/skill stop-and-apply
```

10. Use trace commands for runtime trace handling hints.

```text
/trace on
/trace off
/trace status
```

For durable LLM request/response inspection, enable the rolling trace file in config and inspect `.log/llm.ndjson`.

## Verify

- Telegram replies include a `Trace:` line for request correlation.
- `/project where` returns the active setup session or project context.
- `/ticket pick` returns an eligible ticket when one exists.
- `/ticket start <ticket-key>` returns an initial acknowledgement and later a
  structured execution result or readiness problem.
- Completed ticket execution moves the ticket to review.
- Blocked ticket execution moves the ticket to blocked and includes a reason.
- When LLM file tracing is enabled, `.log/llm.ndjson` receives `llm_request` and `llm_response` events.

## Troubleshooting

- If the bot is silent, confirm the Telegram token and process logs.
- If commands are ignored, confirm the Telegram adapter is running.
- If `/ticket list` says no active project context exists, run `/project where`, `/project list`, or start/switch a project first.
- If `/ticket start` cannot find a ticket, confirm you are using the ticket key
  shown on the board rather than a database row id.
- If ticket execution is blocked by runtime containers or operational setup,
  inspect the readiness ticket, runtime container state, or validation command
  metadata before retrying.
- If LLM trace files do not appear, restart the runtime after enabling `tracing.llm_file`.

## Related Docs

- [Slash Commands Reference](../../reference/slash-commands.md)
- [Debug LLM Calls](debug-llm-calls.md)
- [Runtime Containers In Ticket Work](runtime-containers-in-ticket-work.md)
