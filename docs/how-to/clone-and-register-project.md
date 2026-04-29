# Clone And Register Project

## Goal

Clone a remote repository into the workspace and register it as a runtime project.

## Preconditions

- Runtime server is running.
- A client channel is connected (TUI or Telegram adapter).

## Command

Clone with inferred name:

```text
/repo clone <remote-url>
```

Clone with explicit name:

```text
/repo clone <remote-url> as <project-name>
```

## What Happens

1. Repository is cloned into `_workspace/Projects/<project-name>` in dev mode.
2. Project is registered in SQLite project registry.
3. `.redwright/manifest.yml` is created when missing.
4. Clone provenance metadata is persisted in manifest (`remote_url`, `provider`, `ref`).

## Verify

1. Switch to the cloned project context:

```text
/project switch <project-name>
```

2. Check repository status:

```text
/repo status
```

3. Confirm manifest exists in project root:

`<project-root>/.redwright/manifest.yml`
