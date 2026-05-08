# Dev-To-Main Release Alignment

Use this playbook only when the user explicitly requests a `dev -> main`
alignment PR.

`dev` is the delivery trunk. `main` is protected and only receives changes
through a formal release-alignment pull request.

## Preconditions

- Work from a clean local checkout.
- Confirm the current branch is `dev`.
- Confirm local `dev` is pushed to `origin/dev`.
- Do not commit directly to `main`.
- Do not open normal slice, ticket, or implementation PRs against `main`.

## Scope Check

Inspect the alignment diff before choosing validation:

```sh
git fetch origin
git status --short --branch
git diff --name-only origin/main...origin/dev
```

Use the docs-only exception only when the diff contains only Markdown
repository documentation files.

## Validation

For normal alignment PRs, run:

```sh
bundle exec rake pr:dev_to_main:gate
```

If the gate reports stale badge targets, commit the refreshed `README.md` and
`badges/*` outputs to `dev`, push `dev`, and rerun the gate.

For docs-only alignment PRs, skip the gate and run:

```sh
git diff --name-only origin/main...origin/dev
git diff --check origin/main...origin/dev
```

Record the docs-only exception in the PR body.

## Pull Request

Open exactly one PR:

- head: `dev`
- base: `main`
- title: `chore(release): align dev with main`

When using `tea`, pass the Codeberg login explicitly:

```sh
tea pulls create --login codeberg --repo adrianpk/redwright --head dev --base main
```

Do not rely on implicit/default login resolution for release-alignment PR
creation.

Use this PR body for normal alignment:

```md
## Summary

- align `main` with the latest merged state from `dev`
- include all previously reviewed and merged slice/ticket work

## Validation

- bundle exec rake pr:dev_to_main:gate (pass)
```

Use this PR body for docs-only alignment:

```md
## Summary

- align `main` with the latest documentation state from `dev`

## Validation

- docs-only diff verified with `git diff --name-only origin/main...origin/dev`
- git diff --check origin/main...origin/dev (pass)
- pr:dev_to_main:gate skipped by docs-only exception
```

## Merge

Merge `dev -> main` only through the PR.

Use rebase + fast-forward. Do not squash the alignment PR unless the user
explicitly asks for a different merge strategy.

After merge, fetch and verify:

```sh
git fetch origin
git log --oneline origin/main..origin/dev
```

The command should return no commits when `main` is fully aligned with `dev`.

## Failure Handling

- If the diff includes runtime code, do not use the docs-only exception.
- If validation fails, stop and report the failing command.
- If an unintended PR targets `main`, stop and realign through this playbook.
- If local or remote branches diverge unexpectedly, do not rewrite history
  without explicit user approval.
