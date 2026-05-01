# Branching and PR Flow

1. Create a branch from `dev`.
2. For slice execution, use `fix/slice-<n>-<slug>`.
3. Never work on `main` directly.
4. Before opening a PR from `dev` to `main`, run `bundle exec rake pr:dev_to_main:gate`.
5. Merge into `main` only via PR.
6. If `pr:dev_to_main:gate` reports stale badge targets, commit refreshed `README.md` and `badges/*` outputs before PR.
7. Avoid force push unless explicitly approved.
8. Exception: `ops/plans/*` and `ops/trackers/*` updates may be committed directly to `dev` when they only formalize planning/tracking state.
