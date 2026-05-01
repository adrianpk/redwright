# Dev-to-Main Release Alignment

Canonical release-alignment PR from `dev` to `main`.

1. Run `bundle exec rake pr:dev_to_main:gate`.
2. Open PR with title: `chore(release): align dev with main`.
3. Use this PR body:

```md
## Summary

- align `main` with the latest merged state from `dev`
- include all previously reviewed and merged slice/ticket work

## Validation

- bundle exec rake pr:dev_to_main:gate (pass)
```

4. Merge `dev -> main` only through PR.
