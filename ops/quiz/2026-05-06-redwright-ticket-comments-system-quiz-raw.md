# RedWright Ticket Comments System Quiz Raw Capture

Date: 2026-05-06

Related ticket: TKT-20260506074054

## Running Notes

### Q1. Comment Role

Question: Should ticket comments primarily be a human/agent conversation inside the ticket, or should they also act as a system event log?

Answer: Ticket comments should be conversational only, not a system event log. Their purpose is to resolve blockers, add relevant context, and let humans or agents leave additional ticket-scoped notes that may not belong in the ticket core fields. Both `@user` and `@agent` mentions are valid. A future agent inbox should let agents react to comments and detect potential replies that unblock a ticket.

### Q2. Author Identity

Question: Should a comment store structured `author_type` / `author_id` when a real user exists, while also allowing a textual `author_label` for agents or systems that do not have first-class entities yet?

Answer: Storing author type is acceptable for convenience, but identity should mostly be inferable from the author id when a structured author exists. A cached display label may still be useful for rendering and historical stability, especially for agents or identities that may not yet have a dedicated model.

### Q3. Structured Mentions

Question: Should `@user` or `@agent` mentions remain only as parseable body text, or should they also be persisted as structured records such as `TicketCommentMention` for future notification and inbox queries?

Answer: Mentions should clearly be persisted as structured records. The comment body should not be the only source for notification or inbox behavior.

### Q4. Mention Resolution

Question: Should the first implementation resolve mentions against known users or agents and reject unknown mentions, or should unknown mentions be preserved as unresolved intent?

Answer: The UI should eventually provide autocomplete when typing `@...`, suggesting known human users or agents. In practice this will often be an agent because the system is currently single-user. The editing representation may become something like `[@username](ref-a-user-agent)`, making invalid references hard to enter. If parsing still detects mention intent that cannot be resolved, preserving it as unresolved is acceptable unless there is a strong reason not to create a structured reference.

### Q5. Comment Body Format

Question: Should ticket comments support Markdown from the first implementation, like ticket bodies, or is plain text with rendered links and mentions sufficient initially?

Answer: Comments should support Markdown from the start, reusing the ticket body rendering approach where possible. The same mention autocomplete should eventually apply to the ticket body too, and ticket references such as `#NNNNN` should also be considered. Those broader editor/autocomplete capabilities may need separate tickets if they exceed the comment-system slice.

### Q6. Comment UI Placement

Question: In the ticket modal, should comments live in the metadata sidebar, below the main body, or in a third zone/tab?

Answer: In the compact modal view, comments should appear below the current last element, which is linked documents. In the maximized modal view, comments can be placed closer to the expanded body area, but they should not take too much space away from the body.

### Q7. Comment Creation Surface

Question: Is it sufficient for the first slice to create comments only from the web ticket modal, or should there also be a command-query/API entry point so agents can add comments without a browser?

Answer: The system should clearly allow replies from Telegram eventually, even if Telegram integration is not implemented in this ticket. The comment model and application boundary should not be browser-only.

### Q8. Command-Query Entry Point

Question: Should this ticket include a command-query command such as `AddTicketComment`, so agents and runtime code have a structured path even before Telegram uses it?

Answer: Yes, if that matches the existing RedWright workflow pattern. The current codebase already uses command-query handlers for ticket operations such as `CreateTicket`, `UpdateTicket`, `MoveTicket`, `AttachDocumentToTicket`, and `StartTicketExecution`, so `AddTicketComment` fits the established boundary.

### Q9. Editing and Deletion

Question: Should comments be immutable after creation in the first slice, or should users be able to edit or delete their own comments from the UI?

Answer: The first slice should support creating and listing comments only. Editing and deletion can be added later if needed.

### Q10. Thread Order

Question: Should the thread render in chronological ascending order, like a conversation read from top to bottom, with the composer at the end?

Answer: Yes. Chronological ascending order is acceptable by default. A client-side sort toggle can be added later if needed.

### Q11. First Slice Scope

Question: Should this ticket scope include `TicketComment`, `TicketCommentMention`, an `AddTicketComment` command, UI listing and creation in the ticket modal, Markdown rendering, and tests, while leaving real autocomplete, inbox, and Telegram replies to later tickets?

Answer: Yes. That is a reasonable first implementation scope.
