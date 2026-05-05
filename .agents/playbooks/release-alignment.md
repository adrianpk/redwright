# Dev-to-Main Release Alignment

Canonical release-alignment PR from `dev` to `main`.

1. Open a PR for every `dev -> main` alignment. The PR is mandatory, including docs-only changes.
2. Run `bundle exec rake pr:dev_to_main:gate`.
3. Docs-only gate exception: if `git diff --name-only origin/main...origin/dev` returns only `.md` repository documentation files, skip `pr:dev_to_main:gate` and the test task. Validate with the docs-only diff and `git diff --check origin/main...origin/dev`.
4. Open PR with title: `chore(release): align dev with main`.
   - When using `tea`, pass the Codeberg login explicitly:

     ```sh
     tea pulls create --login codeberg --repo adrianpk/redwright --head dev --base main
     ```

   - Do not rely on implicit/default login resolution for release-alignment PR creation.
5. Use this PR body:

```md
## Summary

- align `main` with the latest merged state from `dev`
- include all previously reviewed and merged slice/ticket work

## Validation

- bundle exec rake pr:dev_to_main:gate (pass)
```

For docs-only alignment PRs, use this validation section instead:

```md
## Validation

- docs-only diff verified with `git diff --name-only origin/main...origin/dev`
- git diff --check origin/main...origin/dev (pass)
- pr:dev_to_main:gate skipped by docs-only exception
```

6. Merge `dev -> main` only through PR, using rebase + fast-forward.
