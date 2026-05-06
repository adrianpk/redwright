# RedWright Ticket Context Inheritance and Use Case Document Model

## Status
Exploratory draft

## Related Artifacts
- `ops/specs/specs/2026-05-06-redwright-use-case-management-ui-spec.md`
- `ops/quiz/2026-05-06-redwright-use-case-management-ui-quiz.md`
- `ops/quiz/2026-05-06-redwright-use-case-management-ui-quiz-raw.md`

## Scope
This draft explores a stricter future context model where `UseCase` becomes the canonical container for formal execution context and tickets inherit that context through optional use-case association.

It does not supersede the current Use Case Management UI specification. The agreed implementation path remains valid unless a later formal revision explicitly changes it.

## Source Context
This draft captures a follow-up design idea produced after the Use Case Management UI quiz/spec cycle. The idea may contradict or refine parts of earlier decisions, especially around ticket-level document attachments. It should be treated as future design input, not as immediate implementation scope.

## Working Notes

### 1) Use Case as Formal Context Container
- provisional_status: `unsure`
- current issue:
  - The current direction allows tickets to have their own use-case association while also manually attaching documents.
  - This can be useful for execution-specific overrides, but may also create fragmented context ownership.
- desired behavior:
  - A `UseCase` becomes the primary aggregation boundary for formal project knowledge related to a feature, workflow, initiative, or implementation area.
  - A use case may contain or reference:
    - drafts
    - specifications
    - plans
    - tracking documents
    - quizzes
    - future formal contextual entities
  - Tickets consume formal context through their optional use-case association rather than manually assembling that context.

### 2) Ticket to Use Case Association
- provisional_status: `keep`
- current issue:
  - Tickets already need optional `use_case_id` support.
  - Not every ticket belongs to a use case.
- desired behavior:
  - A ticket may reference a `UseCase`.
  - A ticket may also exist without use-case association.
  - Project-wide, infrastructure, hotfix, internal refactor, DevOps, and operational tasks may remain project-level.
  - When a ticket references a use case, it should inherit the formal context attached to that use case.

### 3) Implicit Context Inheritance
- provisional_status: `unsure`
- current issue:
  - Direct ticket document selection creates explicit local context but may duplicate use-case context.
  - Multiple tickets may manually reference the same formal documents.
  - Ownership of formal context can become unclear.
- desired behavior:
  - If a ticket references a use case, the ticket automatically gains access to:
    - documents associated with the use case
    - plans associated with the use case
    - tracking artifacts associated with those plans
    - quiz entries associated with the use case
    - future formal contextual entities attached to the use case
  - Project-level documents may still be injected when relevant.
  - Project-wide context remains globally accessible.
  - Context inheritance is implicit and deterministic.

### 4) Removal of Ticket-Level Formal Document Selection
- provisional_status: `unsure`
- current issue:
  - Ticket-level document autocomplete and manual attachment can increase UI and orchestration complexity.
  - Manual selection may produce inconsistent execution environments and fragmented context.
- desired behavior:
  - Remove ticket-level selection of existing formal documents.
  - Remove manual ticket attachment of drafts, specs, plans, trackers, and quizzes.
  - Remove ticket-managed formal document aggregation logic.
  - Tickets derive formal context through:
    - use-case inheritance
    - project-level context injection
  - This would be a later formal revision, not a patch to the currently agreed implementation.

### 5) Ticket UI Direction
- provisional_status: `unsure`
- current issue:
  - The current ticket modal includes document attachment management.
  - The Use Case Management UI spec adds optional ticket use-case selection.
- desired behavior:
  - Replace the ticket document selector with a `Use Case` selector.
  - Initial selector may be a simple dropdown.
  - Later selector may use Turbo Streams autocomplete, dynamic search, and richer previews.
  - Ticket formal context should then come from the selected use case and project-level context.

### 6) Miscellaneous Uploads
- provisional_status: `keep`
- current issue:
  - Some context does not belong in formal RedWright artifacts.
  - Examples include screenshots, PDFs, external references, vendor documents, diagrams, temporary notes, and ad-hoc attachments.
- desired behavior:
  - Future upload support may allow miscellaneous ticket or project attachments outside the formal context model.
  - Miscellaneous uploads must not be treated as drafts, specs, plans, trackers, or quizzes.
  - This upload system is deferred and should not influence the current use-case simplification work.

### 7) Formal Context vs Miscellaneous Context
- provisional_status: `keep`
- current issue:
  - RedWright needs to distinguish structured engineering artifacts from arbitrary references.
- desired behavior:
  - Formal context includes:
    - drafts
    - specifications
    - plans
    - tracking artifacts
    - quizzes
  - Miscellaneous context includes:
    - arbitrary uploads
    - auxiliary references
    - non-structured artifacts
  - Formal context should have deterministic ownership and retrieval paths.
  - Miscellaneous context may remain looser and explicitly deferred.

## Architectural Intent
This direction aims to:

- centralize formal context ownership
- reduce duplicated associations
- simplify ticket orchestration
- simplify contextual injection for agents
- create deterministic context boundaries
- make use cases the canonical semantic unit for feature-scoped work
- reduce manual association logic
- improve long-term maintainability

The possible long-term shape is:

```text
Project
  Global Context
  Use Cases
    Drafts
    Specifications
    Plans
    Trackings
    Quizzes
    Future Contextual Entities
  Tickets
    Optional Use Case Association
    Context inherited automatically
```

## Open Questions
- Should ticket-level formal document attachments be removed entirely, or should they remain as explicit overrides for exceptional execution context?
- Can use-case inheritance fully replace ticket document attachment without losing practical flexibility for agents?
- Should project-level formal documents always be available to tickets, or only when selected by a context policy?
- How should miscellaneous uploads relate to ticket execution context without becoming another formal document system?
- What migration path would preserve existing ticket-document links if the model later removes direct ticket formal document selection?
- Should the `LLMRequestEngine` receive inherited context directly, or should a higher-level business service resolve context before calling the engine?

## Out of Scope
- Changing the current Use Case Management UI spec.
- Removing ticket document attachments in the current implementation cycle.
- Implementing miscellaneous uploads.
- Implementing final LLM context retrieval.
- Defining migration behavior for existing ticket-document links.

## Next Iteration Inputs
- Compare this draft against the current Use Case Management UI spec after the first implementation is complete.
- Observe whether direct ticket document attachments remain useful in practice.
- Review actual agent context failures or redundancies before formalizing removal of ticket-level document selection.
- If the stricter model still holds, produce a formal revision spec that explicitly supersedes the relevant parts of the previous spec.
