# Version Control Workflow

1. Create a branch from `dev`.
2. For slice execution, use `fix/slice-<n>-<slug>`.
3. Never work on `main` directly.
4. Before opening a PR from `dev` to `main`, run `bundle exec rake pr:dev_to_main:gate`.
5. Merge into `main` only via release-alignment PR from `dev`, using rebase + fast-forward. This is mandatory for every `dev -> main` alignment, including docs-only changes.
6. Docs-only gate exception: if `git diff --name-only origin/main...origin/dev` returns only `.md` repository documentation files, do not run the gate or test task. Verify the docs-only diff and run `git diff --check origin/main...origin/dev` instead.
7. If `pr:dev_to_main:gate` reports stale badge targets, commit refreshed `README.md` and `badges/*` outputs before PR.
8. Avoid force push unless explicitly approved.
9. Exception: `ops/plans/*` and `ops/trackers/*` updates may be committed directly to `dev` when they only formalize planning/tracking state.
