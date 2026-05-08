# RedWright Use Case Management UI Quiz Raw Capture

- ticket: `TKT-20260506081044`
- topic: `use-case-management-ui`
- started_at: `2026-05-06`
- max_questions: 50
- status: `completed`

## Session Notes

This raw capture preserves decision-relevant answers during the quiz session. It is working memory for later ticket refinement or curated quiz notes, not a transcript.

## Q1. Primary Need

Question: What concrete problem should a dedicated use-case UI solve: organizing quizzes, organizing tickets/context, preparing implementation, or administering a functional project unit consumed by several surfaces?

Answer: A use case is a simple project-local namespace. A project has many use cases. A use case may reference many documents of all types, many plans and trackers, one quiz session, and many tickets. Before committing to a dedicated relationship model, RedWright should evaluate whether tags could provide the same grouping behavior without creating explicit model/table relationships.

## Q2. Entity Formalization

Question: Should `UseCase` be a strong entity with its own identity and explicit relationships, or should the first implementation explore a tag-based model and only promote to an entity if a concrete need appears?

Answer: A formal `UseCase` entity is preferred. Tags may remain useful for flexible classification, but the use-case concept should be represented as a first-class project-local namespace rather than only as a tag.

## Q3. Minimal Fields

Question: Should the use-case UI manage only the minimal entity fields (`name`, possibly `description`) and leave explicit relationships to documents, plans, trackers, and tickets for later, or should the first implementation include some way to view or attach those relationships?

Answer: The first use-case UI should keep the model minimal. `name` and `description` are mandatory fields. No additional custom fields should be added without a concrete need. Standard Rails audit timestamps are sufficient.

## Q4. Lifecycle and Deletion

Question: If a use case already has quizzes, tickets, documents, plans, or trackers associated with it, should the UI allow physical deletion, or should it use archive/deactivate behavior to preserve relationships and historical context?

Answer: If a use case has associated records, physical deletion should not be allowed. At most, the use case may be archived. Archiving should not cascade to associated entities in the first phase. There is also a product concern: archiving a use case with active associated work may be undesirable, so the UI may need to prevent or warn about archiving when active associations exist.

## Q5. Archive in First UI

Question: Should this ticket implement `archived_at` and archive behavior from the start, or should the first UI only create, edit, and view use cases while leaving delete/archive for a later iteration?

Answer: Including an `archived_at` field in the model is acceptable, but the archive action itself may not be required in the first UI. If archiving has no clear behavioral correlation with associated entities yet, it should not be forced into the first implementation.

## Q6. Navigation Placement

Question: Where should the use-case management screen live: as its own navbar link near Board, Quizzes, and Docs; inside project settings; or accessible from Quizzes while remaining separate from quiz administration?

Answer: The initial UI should expose Use Cases as its own navigation item, placed between `Protocols` and `Quizzes`.

## Q7. Index Shape and Association Semantics

Question: Should the main Use Cases screen use a sober administrative table/list, or cards similar to Quizzes?

Answer: The Use Cases index should use a visually harmonious, minimalist table consistent with the site style. Rows should expose edit and delete actions. However, delete behavior raises an association question: use-case-linked records are not necessarily subordinate children. They are better understood as records associated with a feature/use-case scope. The system should avoid treating associated documents, plans, trackers, quizzes, and tickets as cascade-owned children.

## Q8. Delete Affordance and Reference Checks

Question: Should the use-case index show reference counters such as tickets, documents, quizzes, plans, or trackers, or avoid counters until those relationships are more fully implemented?

Answer: The UI should support deleting use cases created by mistake or no longer intended for implementation. It should not require expensive or noisy per-row reference queries merely to decide whether a delete button is enabled. A simpler first implementation can show the delete action consistently and enforce safety at mutation time, returning a clear message if the use case cannot be deleted because references exist.

Follow-up decision: Backend validation on delete is acceptable and preferable because it happens once per destructive intent. Per-row UI checks would run repeatedly on each index render/refresh and would couple the list UI to all possible associated entity types.

Counters decision: The initial use-case index should not show per-row reference counters for tickets, documents, quizzes, plans, or trackers. Those counters have nearly the same cost and coupling problem as delete pre-checks. Counts may make sense later in a dedicated view/detail page, where the user has explicitly opened one use case.

## Q9. Create and Edit UX

Question: Should use-case creation and editing use modals, like tickets, or regular pages/forms?

Answer: Use modals for create and edit. The form has few fields, and modal-based editing is more consistent with the current site interaction patterns.

## Q10. Detail View and Delete Placement

Question: Is a `show`/detail view needed in the first version, or is index plus create/edit modal plus controlled delete enough?

Answer: A detail view is useful. View can cover some of the same practical surface as edit while also serving as a better place to show metrics or associated-record summaries for a single use case. The delete action should live in the detail view, not in every index row. Because the detail view is scoped to one use case, checking associated records there is acceptable. If associated records exist, the UI should not show the delete button. RedWright should avoid cascading deletes because this is an agent-oriented work board, not Jira, and should avoid disruptive actions.

## Q11. Index Actions

Question: With delete moved to the detail view, should the use-case index table include only `View`/row click and perhaps `Edit`, but no `Delete`?

Answer: The index table should expose an `Edit` button that also functions as the practical view/detail entry point. Delete should not appear in each index row.

## Q12. Detail/Edit Layout

Question: Should the `Edit`/detail surface be a modal with editable fields and an information section, or a full dedicated page?

Answer: Use a compact modal/detail surface. Show the small set of metrics discreetly at the top, without extravagant or unnecessary decoration. Then show the editable `name` and `description` fields. The surface should remain simple because there are only a few fields.

## Q13. Detail Metrics

Question: Which metrics should the first detail/edit surface show: tickets, quiz entries/status, documents, plans/trackers, or only associations that already exist formally in the current model?

Answer: Show metrics for everything associated with the use case. Documents should be grouped by type, such as draft and spec. Plans and trackers can be treated as paired plan/tracker artifacts. For quizzes, showing the number of questions is more useful than showing quiz count, because there should be only one quiz per use case.

## Q14. Missing Associations

Question: If some associations do not yet exist formally in the Rails model, should this ticket add them so metrics are real, or should the first UI show only currently available associations and leave missing links to later tickets?

Answer: The entities to be grouped by a use case already exist conceptually. This ticket may add the required foreign keys and standard Rails associations/helpers needed to connect those entities to `UseCase`, so the detail metrics are backed by real associations.

## Q15. Document Cardinality

Question: Should each document belong to at most one use case through `use_case_id`, or should documents be attachable to many use cases through a join table?

Answer: The likely general case is that a document belongs to at most one use case, even though that may be influenced by the current expected usage pattern. This reference is not merely a human-facing nicety. It primarily helps agents and the `LLMRequestEngine` build rich task context for work scoped to a use case.

## Q16. Document Reassignment and Flexibility

Question: If a document already has `use_case_id`, should the UI allow changing it freely to another use case, or should that be treated as an explicit operation because it affects agent context?

Answer: This exposes a real tension. A join table would allow one document to support multiple use cases, which may be valid if a spec covers a broader set of features or if use cases later become more granular. However, the first version should avoid complexity unless it is clearly needed. The model should favor simple task context creation over maximum relational flexibility.

Decision: Use direct `use_case_id` references instead of join tables for the first version. RedWright should resist the impulse to generalize prematurely. It is an agent orchestration tool for solving work, not Jira. The simpler and more predictable model is preferred.

## Q17. Assigning Documents from Use Cases

Question: Should the first Use Cases UI allow assigning documents to a use case from the modal/detail, or is it enough to show metrics and leave assignment to the documents/specs/drafts surfaces?

Answer: The Use Cases UI should not assign documents in the first version. Keep it focused and avoid turning the use-case detail into a document attachment manager.

Follow-up decision: `use_case_id` and ticket document attachments serve different purposes and should coexist. A use case is structural scope: it tells RedWright that a ticket, document, or quiz primarily belongs to a project-local functional area and helps agents build default context. Ticket document attachments are execution-specific context: they can include documents from the same use case, global project documents, or even documents from another use case when a task needs them. Attaching a document to a ticket should not change the ticket's use case, and assigning a document to a use case should not automatically attach it to every ticket in that use case. The agent and `LLMRequestEngine` should be able to connect these dots when building rich task context.

Document assignment decision: Do not add an `Add docs` button to the Use Case detail in the first version. The better place to assign a document to a use case is the document creation/editing surface, where the user can select the relevant use case as metadata for that document.

## Q18. Ticket Assignment

Question: Should ticket `use_case_id` be selectable when creating or editing a ticket from the existing ticket modal, as another metadata field?

Answer: Yes. The ticket create/edit modal should expose `use_case_id` as ticket metadata. This is a new capability and is not currently available in the UI.

## Q19. Quiz Assignment

Question: Should quiz association to a use case remain implicit from the card/scope where the quiz is launched, or should there be administrative UI to move an existing quiz to another use case?

Answer: There should be no UI for changing a quiz's use case. A quiz is a way to generate domain knowledge in relation to a specific use case. Moving it to another use case would not make semantic sense.

## Q20. Inline Creation from Other Flows

Question: Besides the dedicated Use Cases screen, should other flows such as Quizzes or Tickets be able to create a use case inline when one is missing, or should use cases be created only from the dedicated screen for now?

Answer: Use cases should be created only from the dedicated Use Cases screen. Inline creation from other flows may have residual utility, but it would make the product behavior too chaotic for the first version.

## Q21. Empty States in Dependent Surfaces

Question: If a surface that depends on use cases, such as Quizzes or Tickets, has no available use cases, should it show only a link/CTA to the dedicated Use Cases screen, or should it allow continuing without a use case?

Answer: For Quizzes, the UI should show empty slots when use-case quiz sets are missing. It should not allow creating new quiz sets if the project-level quiz already exists and all existing use cases already have their associated quiz set.

## Q22. Index Ordering

Question: Should the Use Cases table be ordered alphabetically by `name`, by newest creation first, or by last activity/update?

Answer: Order use cases with the newest entries first. The most recently created use case is likely to be the one currently relevant for upcoming work. Client-side tools may later support changing sort order. This UI is more agent-oriented than human-oriented: a use case is created as a scope for work and may not require much human management afterward.

## Q23. Search and Pagination

Question: Does the first Use Cases screen need search/filter, or is a table ordered by newest first enough for now?

Answer: Dynamic search, likely Turbo Streams based, and pagination will probably become necessary sooner rather than later. However, they are not required in the first iteration.

## Q24. Duplicate Names

Question: Should RedWright prevent creating two use cases with the same `name` inside the same project?

Answer: Yes. Duplicate use-case names within the same project should be prohibited because they create confusion, even if agents can technically distinguish records through primary keys and foreign keys.

## Q25. Slugs

Question: Should use cases expose or allow editing a `slug`, or is it enough to generate one internally from `name` and keep it out of the UI?

Answer: Slugs are desirable for readable URLs and Rails can likely generate them easily. However, RedWright is an internal tool and agents do not care about cosmetic URL readability. If slugs are added, they should be generated internally from `name` and should not become a central editable concern in the first UI.

## Q26. Slug URLs

Question: If slugs are used, are routes such as `/projects/:project_id/use_cases/:slug` acceptable, or should RedWright prefer simpler id-based routes even if they are less readable?

Answer: Slug-based URLs are acceptable because they make URLs easier to type manually and easier to recognize in browser history.

## Q27. Permissions

Question: Should creating, editing, and deleting use cases be restricted to admins, or should any authenticated user be allowed for now?

Answer: RedWright is not a SaaS product. It is a local/developer-run tool for administering a set of agents that build software. The expected operating model is one user and one admin: the developer running the tool. Do not overdesign multi-user permission rules for this UI.

## Q28. Current Project Scope

Question: Should the `Use Cases` navigation item show use cases for the project currently selected in the navbar, like Board and Quizzes, or should it show a global list across all projects?

Answer: Use Cases must be scoped by the project selector in the navbar. The screen should show only use cases for the currently selected project.

## Q29. Missing Current Project

Question: If no project is selected yet, should the Use Cases screen redirect to project selection, show an empty state, or use the first available project as a fallback?

Answer: Falling back to the first available project is a sensible option. It keeps navigation simple and avoids overcomplicating the first implementation.

## Q30. Delete Confirmation

Question: When a use case has no associations and the detail view shows `Delete`, is a simple browser confirmation enough, or should RedWright use a custom confirmation modal?

Answer: Start with the classic browser-generated confirmation message using JavaScript. A custom confirmation modal is not required for the first implementation.

## Q31. Delete Errors

Question: If the backend blocks delete because associations exist, where should the error be shown: inside the modal/detail, as a flash on the index page, or both depending on flow?

Answer: Use a flash message. This also suggests creating a draft/spec that captures the intended behavior at a product/UI level, without going too low-level into Rails mechanics that the framework already provides.

## Q32. Output Artifact

Question: Should the end of this quiz produce a short but substantive Use Case Management UI spec in addition to updating the ticket, or should it only enrich the ticket and go straight to implementation?

Answer: A spec is usually the best tangible result of a quiz/question round. This session should produce a brief but substantive specification and then refine the ticket from it.

## Q33. Spec Scope

Question: Should the spec cover only the Use Case CRUD UI, or should it also cover the minimal associations with tickets, documents, and quizzes because those associations make the UI meaningful?

Answer: The spec must cover the associations too. Without the associations, the implementation would be empty CRUD without meaningful product value.

## Q34. Plans and Trackers

Question: Should plans and trackers be treated as special `Document` artifact types associated through `documents.use_case_id`, or as separate relational entities with their own use-case associations?

Answer: In the repository workflow, plans and trackers are created as paired artifacts, and RedWright can assume a similar relationship. What gets tracked is a plan; there is an intrinsic relationship between them. The spec should represent this concept without overcomplicating the first implementation. Plans and trackers should be treated as related artifacts under the use-case context rather than as unrelated independent scopes.

## Q35. Plan and Tracker Metrics

Question: Should the Use Case detail show one metric such as `Plans`, assuming trackers are part of plans, or show separate `Plans` and `Trackers` metrics?

Answer: Start with a single `Plans` metric. When an agent implements a plan, it can expose that tracking is missing or create the tracker on the fly if needed.

## Q36. Document Use Case Field

Question: When creating or editing a document, should the `Use Case` field be optional with a `None` or `Project-level` option for documents that apply globally to the project?

Answer: Yes. Documents should be able to remain project-level/global by leaving use case unset.

## Q37. Ticket Use Case Field

Question: In the ticket modal, should `Use Case` also be optional with a `None` or `Project-level` option, or should every ticket tend to belong to a use case?

Answer: Ticket use case assignment must be optional. Many tickets, such as hotfixes or bugs, may not belong to a specific use case.

## Q38. Archived Use Cases in Quizzes

Question: If `archived_at` exists later, should Quizzes hide archived use cases by default?

Answer: Archived use-case behavior in Quizzes is too fine-grained for the first implementation and should be deferred. If archiving is implemented later, hiding archived use cases by default probably makes sense, but this decision does not need to be finalized now.

## Q39. Delivery Shape

Question: Should this ticket cover all agreed scope in one branch, including model associations, CRUD UI, ticket/document selectors, and metrics, or should the resulting spec split into more than one ticket or slice if needed?

Answer: This ticket may be decomposed into more than one ticket if the evidence shows that is convenient. If the quiz results in a long draft or specification, the plan should be correspondingly thorough, and slicing should follow the normal rule: one branch and PR per slice.

## Q40. First Slice Shape

Question: If a first slice is needed, is it reasonable for it to cover only backend/model associations and tests before touching UI?

Answer: Backend/model/business support should come before UI. In Rails, the separation may not be perfectly clean or necessary, so implementation should preserve that order as a preference without forcing artificial separation if it creates friction.

## Q41. First UI Slice

Question: After backend support exists, should the first UI slice focus on the dedicated Use Cases screen, leaving ticket and document selectors to later slices?

Answer: Yes. The first UI slice should focus on the dedicated Use Cases screen. Ticket and document use-case selectors can be implemented in later slices.

## Q42. Command-Query Boundary

Question: Do use cases need structured command-query operations for agents from the start, such as `CreateUseCase`, `UpdateUseCase`, and `ListUseCases`, or is Rails UI/controller support enough initially?

Answer: Structured command-query operations are strongly recommended from the start. A recurring RedWright principle is that important operations should be usable through Telegram or other messaging surfaces, so users do not need to stay in the browser loop. This boundary also helps agent-driven integration.

## Q43. Minimal Commands and Queries

Question: For the first command-query version, are `CreateUseCase`, `UpdateUseCase`, `DeleteUseCase`, `ListUseCases`, and possibly `GetUseCase` sufficient, or is another minimal operation needed?

Answer: Start with that minimal set and refine later when Telegram-side work is active.

## Q44. Delete Command Consistency

Question: Should `DeleteUseCase` apply the same rule as the UI: delete only when there are no references, never cascade, and return a structured error if deletion is blocked?

Answer: Yes. Use-case delete behavior should be consistent across UI and command-query boundaries.

## Q45. LLM Context Signal

Question: Should the spec explicitly state that `LLMRequestEngine` or its calling service should consider `use_case_id` as a context signal, while leaving concrete retrieval implementation outside this ticket?

Answer: Yes, but with caution. `use_case_id` should be identified as a future context signal, but details should be revisited when implementing retrieval behavior closer to `LLMRequestEngine` or its coordinating service.

## Q46. Validation Standard

Question: What minimum manual validation should be possible in the app for the first delivery of this spec to be considered complete?

Answer: The validation standard is that the implemented behavior should work as specified. The spec should define expected behavior clearly enough that validation follows directly from it rather than reducing completion to an underspecified checklist.

## Q47. Scope Boundaries

Question: What should explicitly stay out of this spec or first implementation, even if tempting?

Answer: The scope is already sufficiently defined by prior answers. The first implementation should not add features beyond the agreed scope.

## Q48. Final Artifacts

Question: Should the session produce a curated quiz file first and then a formal spec, or create the spec directly?

Answer: It is desirable to produce both curated quiz notes and a formal spec, without omitting important details from the conversation.

## Q49. Ticket Refinement

Question: After creating curated quiz notes and the spec, should `TKT-20260506081044` be updated to reference them and likely moved from `open` to `ready`, or remain open until a plan/slicing artifact exists?

Answer: Update the ticket with links to the quiz and spec artifacts. If the resulting ticket is actionable, moving it from `open` to `ready` is appropriate.

## Q50. Final Gap Check

Question: Is there any important Use Case decision not yet covered that must appear in the curated quiz or spec?

Answer: No additional important decision is known at session close.
