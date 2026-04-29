# Project Manifest Reference

## File Path

`<project_root>/.redwright/manifest.yml`

## Purpose

The manifest is the canonical, project-local metadata contract used by RedWright to:

- describe project identity,
- preserve creation provenance,
- rehydrate runtime project registry when SQLite state is missing.

## Schema Version

- `schema_version` is required.
- Current supported value: `1`.

Unsupported versions are treated as invalid for strict manifest reads.

## Schema v1

```yaml
schema_version: 1
project:
  id: "project-123abc"
  name: "hello-cli"
  slug: "hello-cli"
  stack: "ruby"
  created_via: "new" # new | clone
  created_at: "2026-04-29T10:00:00Z"
  summary: "optional"
provenance: # required when created_via=clone
  remote_url: "https://example.com/org/repo.git"
  provider: "github"
  ref: "main"
architecture:
  context: "optional"
  conventions:
    - "optional"
quality:
  auto_validate: false
  lint_command: "optional"
  test_command: "optional"
context:
  project: "optional"
conventions:
  - "optional legacy compatibility"
```

## Required Fields

Always required:

- `schema_version` (integer)
- `project` (object)
- `project.id`
- `project.name`
- `project.slug`
- `project.stack`
- `project.created_via` (`new` or `clone`)
- `project.created_at`

Conditionally required:

- when `project.created_via: clone`, `provenance.remote_url` is required.

## Writer Behavior

### `/project new <name>`

The runtime creates `.redwright/manifest.yml` if missing with deterministic defaults:

- `schema_version: 1`
- `project.stack: unknown`
- `project.created_via: new`

If a manifest already exists, it is preserved (idempotent behavior).

### `/repo clone <url> [as <name>]`

The runtime creates `.redwright/manifest.yml` if missing with:

- `project.created_via: clone`
- `provenance.remote_url`
- `provenance.provider` (best-effort provider hint)
- `provenance.ref` (best-effort checked-out ref)

If a manifest already exists, it is preserved.

## Runtime Read Behavior

- Strict validation uses schema v1 rules.
- Invalid manifests are ignored by manifest-driven context loading.
- During startup rehydration, invalid or missing manifests fall back to path-based project registration.
