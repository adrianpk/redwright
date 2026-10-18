# Collaboration Invariants

This document defines non-negotiable scope, approval, safety, and truthfulness
rules.

## Scope Integrity

- Execute only approved scope.
- Record out-of-scope ideas instead of implementing them.
- Do not infer authorization from task size, technical value, or prior work.

## Context Privacy

- Do not copy incidental local identifiers such as usernames, home paths,
  hostnames, device names, private domains, or remote URLs into versioned
  artifacts, pull requests, tickets, examples, or reports.
- When an example is necessary, use neutral invented values unless the
  artifact explicitly requires the real identifier to function.
- Before publishing or committing artifacts, remove environment details that
  came only from reproduction or diagnostic context.
- Never expose internal VPN information in public or versioned artifacts,
  clone instructions, forge metadata, release archives, or generated output.
  This includes private hostnames, tailnet DNS suffixes, VPN addresses, and
  internal SSH endpoints. Apply this rule to every project.
- Keep real VPN identifiers only in explicitly authorized private connection
  configuration, device inventories, or recovery documents. Their presence in
  a diagnostic session does not authorize publication or reuse in examples.
- Use the approved public HTTPS endpoint for public Git clone instructions.
  Maintainer SSH access remains private and belongs in local configuration;
  do not advertise it as a public clone endpoint.
- Before publication, inspect forge metadata and expanded release contents as
  well as source files. A source-only text scan does not cover generated or
  compiled artifacts.

## Approval Gates

- High-impact changes require explicit approval.
- Production deployment and external billing, credential, access, or account
  mutations require explicit approval.
- Start, stop, or restart long-running development services only when the user
  requests it or authorized validation requires it.
- Never interrupt, terminate, suspend, or restart a running build, test, gate,
  or other long-running process unless the user explicitly requests that
  process-control action or an immediate host-safety emergency requires it.
- Treat questions, concerns, or comments about duration, resource use, scope,
  or necessity as requests for explanation, not as authorization to control a
  running process. If intent is unclear, explain the current state and ask
  before sending a signal or terminating its controlling session.

## Safe Delivery

- Prefer incremental, reversible changes.
- Keep the repository in a working state between delivery units.
- Do not use destructive Git operations without explicit approval.
- Keep secrets and local agent configuration out of version control.
- Preserve unrelated user changes and report any overlap with requested work.

## Quality and Truthfulness

- Do not mark work complete with failing required checks.
- Do not describe focused checks as the full validation suite.
- Distinguish local implementation from deployed or externally verified state.
- Record checks that could not run and the reason.
- Keep repository, tracker, commit, and pull-request state consistent.
