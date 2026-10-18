# Versioned Main Release

Use this playbook only after release authorization under
`.agents/VERSIONING.md`.

1. Verify the working tree, `dev`, `origin/dev`, `main`, `origin/main`, tags,
   open release work, and the latest scheduled nightly results.
2. Identify the latest release tag and inventory the user-visible changes
   intended for the next release.
3. Confirm that the User Guide describes the delivered behavior.
4. Use `changelog-normalize` to audit `Unreleased` against the inventory.
5. Propose the next SemVer with a rationale and wait for explicit maintainer
   approval.
6. Finalize every tag-bound input on `dev`: version, release date, changelog,
   version files, release notes, and required publication metadata.
7. Run focused documentation and release-preparation checks, commit, and push
   the final candidate to `dev`.
8. Keep that `dev` candidate unchanged until the scheduled nightly workflow
   captures its hash. Continue unrelated work only on separate branches or
   worktrees during this interval.
9. Wait for the scheduled nightly workflow to run the full gate for that exact
   commit and fast-forward `main` to the same hash.
10. If the gate fails or another hash was tested, do not tag. Correct the
    candidate through `dev` and wait for exact-commit validation again.
11. Verify that the approved candidate is present on `origin/main`, that its
    required gate is green, and that all tag-bound metadata is complete.
12. Create the approved version tag on that exact commit, push the tag to
    `origin`, and verify its target.
13. Build release artifacts, packages, downloads, and release deployments from
    the version tag.
14. When `mirror` exists and local policy requires publication, push updated
    `main` and only the allowed release tag, then verify the remote refs.
