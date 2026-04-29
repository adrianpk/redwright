# Bootstrap Project Context

## Goal

Initialize runtime state and establish a usable active project context in dev mode.

## Preconditions

- You are in the repository root.
- Ruby dependencies are installed.

## Steps

1. Initialize workspace directories and runtime database.

```bash
bin/rake bootstrap
```

2. Start the runtime server.

```bash
bin/rake server:run
```

3. In another terminal, open one client channel.

TUI:

```bash
bin/rake tui
```

Telegram adapter:

```bash
bin/rake telegram
```

4. Create or switch project context.

```text
/project new hello-cli
```

or

```text
/project switch hello-cli
```

## Expected Result

- Active project context is bound for the current session/chat.
- Project directory exists under `_workspace/Projects/<name>` in dev mode.
- `.redwright/manifest.yml` exists for newly created projects.

## Verify

- `bin/rake server:status`
- `bin/rake server:ctl:status`
- `bin/rake server:ping`
