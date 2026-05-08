# RedWright Ticket Model Alignment Quiz Raw Capture

Date: 2026-05-06

Related ticket: TKT-20260506072409

## Running Notes

### Q1. Alignment Depth

Question: Should RedWright align with the repository-local ticket workflow through a near 1:1 visible and persisted property model, or only through conceptual equivalence while allowing RedWright to persist fewer or additional fields?

Answer: The preferred direction is to replicate the repository-local model because it has proven useful in the current workflow.

### Q2. Agent Friction

Question: What type of friction should be avoided for agents operating tickets?

Answer: All major sources of agent friction should be avoided: too many required fields during creation, overly strict status transitions, metadata requirements that the agent may not know yet, and any risk that a ticket cannot advance because accessory fields are missing.

### Q3. Required Fields

Question: Should RedWright keep the required field set very small when creating a ticket, such as title, status, and body/context, while allowing all other fields to remain empty or inferred later?

Answer: Yes. Ticket creation should require only a small core field set. Optional metadata may remain empty or be inferred later, but fields that are present or derived by workflow activity should be kept updated consistently.

### Q4. State Transitions and Granularity

Question: Should RedWright use permissive status transitions by default, or should it introduce soft rules that recommend the normal flow without blocking except for clearly invalid cases?

Answer: RedWright is expected to operate around an Implement/Fix -> Review -> Merge model, where review and merge may also be performed by agents or by the same agent acting in a different role. A 1:1 status model may be useful for the current workflow, but excessive state granularity could complicate the operational dynamic unnecessarily.

### Q5. Visible and Internal Statuses

Question: Should RedWright persist all workflow statuses while allowing the UI and agents to operate through a simpler flow where some states are optional or administrative?

Answer: This is acceptable as long as it does not create zombie states. Any persisted status must remain reachable by operational queries and views; tickets must not become hidden or forgotten because a query or board no longer includes their status.

### Q6. Board Columns

Question: Should the board expose every status as an explicit column, possibly with some columns collapsed, or should it keep only a few main columns and expose non-primary statuses through filters or counters?

Answer: The regular board view should not add more columns or statuses than it has now. Optional show/hide mechanics could exist eventually for a human operator, but that direction feels potentially convoluted and should not drive this implementation.

### Q7. Operational Mapping

Question: Should RedWright keep its current operational columns while treating the 1:1 workflow statuses as background lifecycle metadata, or should every workflow status be mapped into an existing board column?

Answer: RedWright should likely keep all shared statuses as a defined enum-like vocabulary, but daily workflows should not force every status to participate in interactions. Some statuses may be skipped operationally until daily experience proves they are needed inside the RedWright workflow.

### Q8. Tracking Fields and Comments

Question: Should fields such as branch, PR, commits, owner, and lifecycle timestamps be persisted directly now, or should some live temporarily in comments/events until a clearer UI or automation exists?

Answer: Comments must not be used as metadata storage. They should remain communication artifacts, not structured state. Tracking metadata should be represented as structured fields when it is introduced.

### Q9. Optional Structured Fields

Question: Should RedWright add these tracking fields now as optional structured fields, even if the initial UI only displays a minimal subset and agents or automations fill them when appropriate?

Answer: Yes. These fields may be introduced now as optional structured fields. The UI can remain minimal at first, while agents and automations populate the fields when applicable.

### Q10. Tags

Question: Should RedWright ticket tags remain a simple comma-separated list on the ticket, or should they use the existing `Tag`/`Tagging` model if available?

Answer: RedWright should not introduce a separate comma-separated tag model for application tickets. Existing drafts/specs define a unified transversal tagging system. Relevant reference: `ops/specs/specs/2026-05-05-redwright-quiz-questionnaire-context-spec.md`, section "Tags". The current Rails app already has `Tag`, `Tagging`, and `Ticket` associations that should be reused and aligned.

### Q11. Status Source of Truth

Question: Should a new ticket `status` field become the source of truth while board columns become only a visual representation, or should RedWright keep columns as the operational source for now and derive or synchronize workflow status from them?

Answer: The behavior should be as automatic and predictable as possible. This is an area where literally replicating the Markdown-based dynamics may not be the highest priority or the most convenient approach. RedWright should avoid making the user or agents manually reconcile status and column state.

### Q12. Initial Scope

Question: Is schema, model behavior, basic synchronization, and tests sufficient for this ticket, leaving detailed UI for later tickets?

Answer: The UI is considered vital. However, this requirement may be split into two tickets if needed: one for the business/model side, and another for the web UI side. Splitting should be considered if keeping everything in one ticket would make the implementation too broad.
