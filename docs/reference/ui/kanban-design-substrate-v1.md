# Kanban Design Substrate v1

## Status
Normative specification.

This specification defines the interaction and visual contract for the Kanban module.
It is authoritative for implementation and review.

Global visual tokens and shared UI rules are defined in:
- `docs/reference/ui/web-ui-style-system-v1.md`

---

## Purpose
The Kanban module shall provide:
- clear operational state visibility,
- low-friction ticket interaction,
- consistent authentication boundaries,
- predictable modal and drag/drop behavior.

---

## Scope
In scope:
- Board index and board detail UI
- Ticket card interaction model
- Ticket creation/editing modal model
- Drag-and-drop status transitions
- Drag-and-drop archive/delete targets
- Authentication behavior that affects board surfaces

Out of scope:
- Agent planner/routing internals
- Non-UI runtime orchestration logic
- External provider-specific flows

---

## Design Principles
1. State is communicated by position first, decoration second.
2. Interaction legibility has higher priority than visual flourish.
3. Empty states must be intentional and production-grade.
4. Primary actions must remain obvious within each surface.
5. Progressive disclosure is preferred over persistent control noise.
6. Authentication boundaries must never degrade UI integrity.
7. Board interactions must avoid full-page transitions during normal operation.

---

## Information Architecture
## Board Index
Must provide:
- list of boards,
- direct board entry,
- compact project identity cues.

Must not provide:
- full ticket editing controls,
- deep board interaction controls.

## Board Detail
Must provide:
- horizontal Kanban columns,
- visible ticket counts by column,
- ticket cards as primary units,
- board-level elapsed metrics.

Must not provide:
- unrelated runtime diagnostic output,
- secondary controls that compete with ticket flow.

## Ticket Modal Surface
Must provide:
- focused create/edit form,
- clear validation and close actions,
- contextual continuity with board.

Must not provide:
- global navigation complexity inside modal scope.

## Authentication Surface
Must provide:
- full-page sign-in form,
- explicit auth errors/notices,
- clear return flow after successful auth.

Must not provide:
- embedded/fragment login rendering inside board surfaces.

---

## Interaction Contract
## Ticket Open
- Clicking a ticket card must open the edit modal.
- Interactive nested controls must preserve their own behavior.

## Ticket Create
- “New ticket” must open create modal in the same modal surface.

## Modal Close
- Modal must close from:
  - explicit close action,
  - backdrop interaction.
- Closing must return focus to board context.

## Drag and Drop: Column Transition
- Ticket cards must support drag initiation from card body.
- Valid column targets must expose visual drop affordance.
- Drop must update ticket status/column.
- Update must render through Turbo Stream in normal operation.

## Drag and Drop: Archive/Delete
- Overlay targets must appear only during active ticket drag.
- Spatial partition must be:
  - left 25% = archive target,
  - right 75% = delete target.
- Target actions must be deterministic:
  - archive removes ticket from board-visible scope,
  - delete removes ticket entity.

## Auth Boundary Behavior
- Protected board routes must require effective authentication.
- Unauthenticated board access must redirect to full-page login.
- Any frame/modal request resolving to login must promote to top-level navigation.

---

## Component Contracts
## BoardColumn
Required:
- title, count, ticket stack.
- drop-target visual state.

## TicketCard
Required:
- title, optional description, priority, labels, assignee, timing metadata.
- click-to-edit modal behavior.
- drag-to-transition behavior.

## DropTargetOverlay
Required:
- hidden state by default,
- visible state only while dragging,
- icon-only archive/delete affordances,
- clear hover/active response,
- left/right target proportions of `25% / 75%`.

## TicketModal
Required:
- consistent form layout for create/edit,
- validation visibility,
- reliable close behavior without route confusion,
- icon-only window controls in upper-right corner,
- no duplicated escape actions in primary form area.

## AuthForm
Required:
- explicit error/notice visibility,
- deterministic post-auth redirection.

---

## Accessibility Baseline
Must provide:
- keyboard reachable interactive controls,
- visible focus states,
- non-color-only semantic cues for critical states,
- readable contrast for primary text and controls.

---

## Prohibited States
1. Login form rendered as inline fragment inside board canvas.
2. Oversized destructive affordances that dominate workspace.
3. Raw/unstyled fallback blocks in normal UI paths.
4. Permanent ticket-level control clutter replacing contextual actions.
5. Full-page reload as default behavior for board interactions.

---

## Acceptance Criteria
1. Unauthenticated `boards#index` and `boards#show` redirect to full-page login.
2. Login surface renders with system styling and clear error handling.
3. Ticket click opens edit modal consistently.
4. New ticket opens create modal consistently.
5. Drag ticket to another column updates board state via Turbo Stream.
6. Drag overlay appears only during active drag and closes on drag end/drop.
7. Archive and delete targets execute correct actions on drop.
8. Session-expired modal/interaction requests route to top-level login.
9. No raw inline login/render artifacts appear in board surfaces.

---

## Change Protocol
- Any change affecting Kanban UI behavior must update this spec in the same slice.
- Any intentional divergence must be documented in a versioned amendment section before merge.
