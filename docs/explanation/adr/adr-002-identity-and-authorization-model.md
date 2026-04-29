# ADR-002: Identity and Authorization Model

## Status
Accepted

## Date
2026-04-29

## Context
The system must support human users and automated agents with strict visibility controls. Automation must not have implicit ticket access.

## Decision
Use **multi-identity agents** plus human RBAC.

1. Human identities:
- Rails-authenticated users with roles: `admin`, `contributor`, `viewer`.

2. Agent identities:
- `agent_coder`
- `agent_reviewer`
- `agent_merger`

3. Ticket access policy:
- Access is granted when either:
  - `ticket.assignee == requesting_identity`, or
  - ticket labels match an allow-list associated to the identity.
- Deny by default when no rule matches.

4. Role constraints:
- Reviewer cannot merge.
- Merger cannot author code changes.

## Consequences

### Positive
- Strong traceability by identity and role.
- Lower blast radius for permission mistakes.
- Easier auditing of automated behavior.

### Negative
- More credential and policy management overhead.
- Requires policy provisioning per environment.
