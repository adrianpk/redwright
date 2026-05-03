# Run The Local Stack

## Purpose

Run RedWright locally with the runtime server, Rails web app, and Telegram adapter.

## Before You Start

- Configure RedWright first.
- Make sure Ruby dependencies are installed.
- Make sure the Telegram bot token is configured if you run Telegram.

## Steps

1. Bootstrap runtime state.

```bash
bundle exec rake bootstrap
```

2. Start the full local foreground stack.

```bash
bundle exec rake app:run:foreground
```

This starts:

- runtime server
- Rails web app
- Telegram adapter

The command also prepares the Rails database and seeds local users for the web app.

3. Open the web app.

```text
http://127.0.0.1:3000
```

Default seeded users include:

```text
adrian@redwright.local
agent-coder@redwright.local
agent-reviewer@redwright.local
agent-merger@redwright.local
```

Default local passwords:

```text
adrian@redwright.local: changeme-owner
agent-coder@redwright.local: changeme-agent-coder
agent-reviewer@redwright.local: changeme-agent-reviewer
agent-merger@redwright.local: changeme-agent-merger
```

Override them with environment variables before startup for non-throwaway local use.

4. Run only the runtime server when you do not need Rails or Telegram.

```bash
bundle exec rake server:run
```

5. Run a one-shot TUI or Telegram client against the local server.

```bash
bundle exec rake tui
bundle exec rake telegram
```

## Verify

Check runtime health:

```bash
bundle exec rake server:status
bundle exec rake server:ping
bundle exec rake server:ctl:status
```

Check foreground logs:

```text
tmp/logs/server.live.log
tmp/logs/web.live.log
```

## Troubleshooting

- If the Rails app does not start, inspect `tmp/logs/web.live.log`.
- If the runtime server does not start, inspect `tmp/logs/server.live.log`.
- If port `3000` is busy, set `WEB_PORT` before running the foreground stack.
- If Telegram starts but does not respond, confirm the bot token and allowed chat IDs.

## Related Docs

- [Run RedWright](../run-redwright.md)
- [Runtime Capabilities](../../reference/runtime-capabilities.md)
