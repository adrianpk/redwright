# Version Control Workflow

`.agents/VERSIONING.md` owns all commit, branch, remote, pull-request, nightly
integration, release, and history-rewrite policy.

1. Classify the requested version-control action under `.agents/ROUTING.md` and
   `.agents/VERSIONING.md`.
2. Inspect the current branch, working tree, canonical remote, upstream refs,
   and active operational artifacts.
3. Select the applicable delivery route: direct `dev` work, an authorized
   branch and pull request, scheduled nightly integration, or an explicit
   versioned release.
4. Follow the more specific playbook for a formal slice or versioned release.
5. Run the repository-required validation for the exact commit being delivered.
6. Perform only the version-control mutations authorized for the selected
   route.
7. Reinspect local and remote state, then report the resulting commit, branch,
   validation, and publication state.
