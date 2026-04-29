# Ticket Visibility Policy v1

## Agent Visibility
Agent identities are evaluated with default deny.

Grant conditions:
1. `ticket.assignee == actor_id`, or
2. at least one ticket label matches actor allow-list.

Optional explicit deny labels (environment policy):
- `human-only`
- `internal`

If explicit deny label matches actor deny-list, deny wins.

## Human Visibility
Human users require project membership and RBAC role.

## Policy Requirements
1. Policy evaluation must be auditable.
2. Deny decisions must include reason code.
3. Label taxonomies must be documented per deployment.
