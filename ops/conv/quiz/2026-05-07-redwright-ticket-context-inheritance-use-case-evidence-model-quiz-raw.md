# RedWright Ticket Context Inheritance, Use Case, and Evidence Model Raw Quiz

## Status
Raw capture

## Related Draft
`../specs/drafts/2026-05-06-redwright-ticket-context-inheritance-use-case-document-model-draft.md`

## Session 2026-05-07

### Question 1
When a ticket has `use_case_id`, should formal context inherited from the use case be mandatory and exclusive for formal artifacts, meaning the ticket cannot manually attach drafts, specs, plans, trackers, or quizzes under any circumstance?

### Answer 1
No. A ticket inside a use case may sometimes need additional ticket-specific information that should not be added to the whole use case. If that information were attached at the use-case level, it would create irrelevant context noise for other tickets in the same use case. The concern is practical: unnecessary tokens and cost.

### Question 2
Should that ticket-specific additional information always be separate `evidence/supporting material`, or should tickets also be allowed to attach extra formal artifacts when those artifacts are relevant only to that ticket?

### Answer 2
The distinction is that ticket-specific additions are assets, not drafts, specs, plans, or tracking artifacts. They may start as text, but they should eventually support any analyzable asset type.

### Question 3
Should evidence assets be attachable only to tickets in the first version, or also to use cases and projects from the beginning?

### Answer 3
For now, evidence assets should be attached only to tickets. Later iterations can evaluate whether they also provide value at the use-case level. The first version should keep the model simple.

### Question 4
If a ticket belongs to a use case, should the agent receive all formal artifacts from that use case automatically, or should RedWright choose which artifacts to include based on relevance to the ticket?

### Answer 4
A use case may expand across multiple tickets, but the first version should not introduce ticket-level heuristics for selecting formal artifacts. The simpler initial rule is preferred.

### Question 5
For tickets without a use case, what formal context should they receive in the first version: only `ticket.body` plus global project context, or also project-level formal artifacts when they exist?

### Answer 5
Tickets without a use case should receive the ticket body plus formal artifacts associated with the project itself, meaning artifacts that are not associated with any particular use case.

### Question 6
When a ticket does have a use case, should it also receive project-level formal artifacts in addition to use-case artifacts, or only the use-case context plus body and evidence?

### Answer 6
The current inclination is to include project-level formal artifacts as well. General project definitions are often relevant regardless of use case, and excluding them may remove too much useful context. Including them does not seem likely to overload context too much in the first version.

### Question 7
When a draft, spec, plan, tracker, or quiz is created from inside a use case, should it automatically be associated with that use case without asking for confirmation?

### Answer 7
Yes. If a use case is selected, new formal artifacts should automatically belong to that use case. If no use case is selected, they become part of the general project context.

### Question 8
In the ticket UI, should the formal document selector/manager be removed completely and replaced by two separate concepts: a use-case selector and an evidence asset section?

### Answer 8
Conceptually, tickets should have a use-case selector similar to the current document autocomplete, but for use cases. The use-case association should be visually higher in the ticket UI, not buried below like the current document association area. The formal document selector should be removed. It should not be replaced immediately by an asset uploader because the asset uploader is not part of the immediate implementation. The questionnaire and later draft/spec should explicitly mention this deferred uploader/evidence capability.

### Question 9
For the first version, if the formal document selector is removed from tickets and the asset uploader is not implemented yet, what should the UI show in that area: nothing, a non-interactive note, or only the reordered ticket layout with use case visible higher up?

### Answer 9
Show nothing in that area. Remove the formal document selector without adding a placeholder or non-interactive note. The draft/spec should still record that a related component is expected to return later as ticket evidence/assets, but it should not be part of the immediate UI.

### Question 10
What should happen to existing ticket-document links in current data: migrate them automatically to use-case or project ownership, leave them as hidden legacy state, or remove them because they are no longer part of the model?

### Answer 10
There are no meaningful existing links to preserve. RedWright is not launched as a SaaS product; it is currently a personal development app used by one person to build RedWright itself. The spec can assume a clean model change without a compatibility-heavy migration strategy.

### Question 11
When RedWright assembles context for an agent, should the context be explicitly separated by source, such as ticket body, project formal context, use-case formal context, and future ticket evidence, or is a combined priority-ordered context list enough?

### Answer 11
This is outside the scope of the artifact association process. The later LLMRequestEngine work, or the higher-level services calling it, should decide how to indicate which assets to use and which to omit. The current spec should focus on the association and ownership model, not final prompt/context section shaping.

### Question 12
Should the immediate spec scope be only association model and UI, such as associating artifacts to use cases and use cases to tickets, or should it also include runtime/agent inheritance when executing a ticket?

### Answer 12
Focus on associating artifacts to use cases and use cases to tickets. Everything related to runtime execution, LLM context selection, and inherited context injection should be handled in another iteration.

### Question 13
Which formal artifacts are in scope for use-case association: only existing `Document` records, or also quizzes and future trackers/plans even when some currently live as repository files under `ops/`?

### Answer 13
All of those formal artifacts are potentially associable with a use case.

### Question 14
Should the spec say that every formal artifact can belong to a use case even if the first implementation only connects the artifact types that already exist in the web UI or database?

### Answer 14
This should not be answered without reviewing the current model representation. The general direction may already be defined elsewhere. If this creates ambiguity during spec writing, it should be revisited with the schema/model in view instead of guessing.

### Question 15
When a ticket changes use case, should it simply update `use_case_id` without any extra document or evidence logic, since formal documents are no longer attached directly to the ticket?

### Answer 15
A ticket changing use case should normally mean the initial association was wrong and is being corrected. After this refactor, the ticket only knows formal documents transitively through its use case. Selecting a use case on the ticket should not trigger a process that attaches all use-case documents to the ticket.

### Question 16
Should the ticket UI show any explicit indication such as "formal context inherited from use case", or is it enough in v1 for the use case to be visible and editable near the top of the ticket?

### Answer 16
No explicit inheritance explanation is needed. The inherited formal context is the natural behavior of the model.

### Question 17
Should the ticket use-case selector allow an explicit empty value for project-level tickets, or should it push the user to choose a use case while still allowing `none`?

### Answer 17
Leaving the selector empty means the ticket is project-level. Empty `use_case_id` is a valid association state, not an incomplete ticket.

### Question 18
When creating formal artifacts from the UI, should the use-case scope work the same way: empty means project-level, selected means use-case-level?

### Answer 18
The expected answer is yes, and this may already be implemented. This should be reviewed against the current implementation in case an existing detail is being missed.

### Question 19
Should the spec explicitly state that `ticket.body` is always the primary execution objective, even when the ticket inherits formal context from the project or use case?

### Answer 19
This is mostly irrelevant to the association model. The service that sends context to the LLM should assign semantic priority to each field. The ticket body is clearly the core description of what the ticket is trying to solve, but this spec should not define prompt priority rules.

### Question 20
Should the goal of the spec be simplifying the association model rather than directly improving LLM context behavior, leaving LLM context handling as motivation and future work?

### Answer 20
Yes. When creating a document, quiz, or similar formal artifact, it should be associated with a use case when applicable. Then, when resolving a ticket, the user does not have to remember which documents should be attached manually. This appears to be a better option, but real usage should determine whether a different approach must be reconsidered later.
