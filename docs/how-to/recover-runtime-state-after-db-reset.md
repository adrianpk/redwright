# Recover Runtime State After DB Reset

## Goal

Recover runtime project state after deleting runtime SQLite in dev mode.

## When To Use

- Runtime DB was removed or corrupted in local development.
- You need to rebuild project registry from workspace contents.

## Steps

1. Stop runtime processes.

2. Remove runtime DB file in dev workspace:

```bash
rm -f _workspace/redwright/runtime.db
```

3. Bootstrap runtime again:

```bash
bin/rake bootstrap
```

4. Start server and client:

```bash
bin/rake server:run
# new terminal
bin/rake tui
```

## Recovery Behavior

At bootstrap, runtime project rehydration runs:

1. If SQLite project registry is non-empty, existing SQLite state is kept.
2. If SQLite project registry is empty, runtime scans `_workspace/Projects`.
3. For each project directory:
   - valid manifest: register from manifest metadata,
   - missing/invalid manifest: fallback to path-based registration.

## Verify

- You can `/project switch <name>` to known projects.
- `/repo status` resolves against expected project.
- Existing project manifests remain unchanged.
