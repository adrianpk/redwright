# Run Dev-to-Main Quality Gate

Use this procedure before opening a `dev -> main` pull request.

## Command

```bash
bundle exec rake pr:dev_to_main:gate
```

## What it checks
1. Runs local quality checks and badge refresh.
2. Fails when tracked badge outputs are stale.

## Required outcome
Gate must exit with success before opening the PR.
