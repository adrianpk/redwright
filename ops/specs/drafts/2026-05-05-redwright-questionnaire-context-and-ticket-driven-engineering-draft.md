# RedWright Questionnaire Context and Ticket-Driven Engineering Draft

## Status

- type: `spec-draft`
- date: `2026-05-05`
- source: engineering alignment conversation about questionnaires, context enrichment, ticket-driven execution, tags, preflight prompting, and project initialization

## 1. Scope

This draft captures a product and architecture need for persistent questionnaires as a reusable context source for RedWright agents.

It does not define the final Rails schema, controller structure, UI layout, background job design, prompt contract, or implementation plan.

The goal is to preserve the engineering alignment needed to later produce one or more formal specs.

## 2. Conversation Mode

This line of work should continue through short engineering exchanges.

The user explicitly prefers a ping-pong style:

- one idea at a time
- short answers
- no premature architecture chapters
- no implementation before a concrete request
- no noisy transcript-like documentation

This is also a product signal: RedWright should avoid unnecessarily verbose human interactions when information can be inferred, retrieved, or asked more precisely.

## 3. Background

The larger concern is improving how RedWright generates artifacts and code.

The current project setup flow exists and is relatively healthy, but it can create projects without enough implementation-oriented context.

The current formal project initialization question order is:

1. project name
2. description
3. project type
4. language/runtime
5. framework
6. libraries

This order comes from `ProjectSetup::ContextLoopService::SLOT_ORDER`.

## 4. Project Initialization Friction

A possible revised `/project new` flow should be evaluated around these questions:

1. name
2. repository
3. project type
4. tagline
5. description
6. language/runtime
7. framework
8. libraries

The repository question is important because RedWright should avoid registering the same repository twice under slightly different remote URL forms.

Repository absence should be expressible through values such as `none`, `pass`, empty input, or equivalent UI states.

Repository identity should be normalized before comparison. Equivalent forms may include:

- HTTPS remotes
- SSH remotes
- `.git` suffix differences
- owner/repo shorthand
- host, owner, and repository casing or punctuation variants where safe

## 5. `/project new` and `/project clone`

Providing an existing repository during setup introduces extra complexity.

If the repository exists externally but is not yet registered in RedWright, the system could clone or inspect it, infer stack and structure, then avoid redundant questions.

That is useful but makes `/project new` heavier.

Current design preference:

- keep `/project new` simple and declarative
- introduce `/project clone` for onboarding an existing repository
- let `/project clone` own repository normalization, deduplication, clone/inspection, and inference
- evaluate later whether `/project new` should redirect to clone-like behavior when a repository is provided

Telegram and web setup can differ:

- Telegram naturally uses sequential conversation
- web setup can be a form-style interaction

## 6. Prompt and Context Optimization

The planner/general prompt currently includes or can include:

- agent context
- project context
- architecture context
- precedence rule
- injection guardrails
- workspace context
- planner output contract
- current user text or refinement packet

Refinement and ticket loops can additionally include:

- current errors
- normalized failures
- execution results
- selected file snippets
- tree entries
- stack hints
- documentation hints
- semantic symbols or structural extraction
- previous patch summary

The open question is not how to add more context. The useful question is what context is sufficient for a specific use case.

## 7. Working Context Hypotheses

Agent context is likely always useful because it defines identity, role, and interaction posture.

Precedence rules and injection guardrails are small and defensive, so they likely belong in most planner-style prompts.

Project context is likely needed often, but may be compacted into a denser representation.

Architecture context should probably be selective. A small README edit should not need the same architecture payload as a ticket implementation loop.

Workspace context should be selected by use case:

- status queries need little or no repository context
- documentation edits may need one or a few documents
- code generation needs repository structure, relevant files, conventions, and validation signals
- test failure refinement needs errors, touched files, and patch history

## 8. Code Generation Risk

Code generation is the highest-risk context composition case because it is the core purpose of the system.

To implement software changes well, the agent needs enough context to know:

- the project API it is modifying
- the API of libraries the project uses
- where new files belong
- which existing files should receive new functions, classes, constants, variables, or configuration
- local conventions
- architecture boundaries
- test patterns
- validation commands
- previous errors and execution results

Sending the whole repository as an archive is not an acceptable default strategy for large codebases because it creates payload, cost, latency, and signal-to-noise problems.

## 9. Stack-Aware Context Retrieval

RedWright is intended to operate across many stacks.

Therefore, context retrieval cannot depend only on one language-specific strategy.

Possible sources include:

- tree snapshots
- shell-derived repository data
- `rg` searches
- dependency manifests
- generated documentation
- package metadata
- Tree-sitter or equivalent structural extraction
- LSP or type information when available
- selected snippets
- execution diagnostics
- stack-specific docs such as Go docs or Javadocs

Compiled or binary-heavy stacks may require documentation and metadata because local source inspection may not reveal enough API information.

## 10. Preflight Prompting

A future prompt manager may use preflight LLM calls to decide what context should be retrieved before the main implementation prompt.

The conceptual preflight request is:

```text
Given this ticket, project, stack, and available repository map, identify what information should be retrieved before implementation.
```

The output should be an actionable context strategy, not code.

It may include:

- files to inspect
- symbols to search
- commands to run
- dependency docs to retrieve
- tests to examine
- relevant tags
- relevant questionnaire answers
- whether human clarification is needed

Multiple preflight steps may be useful, but nested LLM chains must be bounded by depth, time, token, and cost budgets.

## 11. Ticket Execution Loop

Ticket execution should be a formal loop, not a single LLM shot.

Normal target behavior:

1. read ticket
2. select context
3. plan
4. edit
5. validate
6. refine with failures if needed
7. repeat within limits
8. escalate formally when blocked

The normal goal is no human in the loop.

If the agent cannot resolve a ticket after bounded iterations, escalation should be formal:

- mark the ticket as `blocked` or `standby`
- record the clarification question on the ticket
- optionally notify a human lead
- resume when the human answers

Clarification through the Kanban ticket is preferable to interrupting a user through Telegram by default.

## 12. Persistent Questionnaires

The main new concept is a persistent questionnaire model.

This is not the same as the initial project setup questionnaire.

Project setup captures basic project registration data.

Persistent questionnaires capture reusable engineering context that can later enrich prompts and guide artifact or code generation.

Questionnaires can capture:

- product decisions
- domain rules
- UX/UI expectations
- architecture constraints
- implementation preferences
- testing expectations
- project priorities
- use-case-specific behavior
- information not inferable from code

Questionnaires are not passive storage. Their purpose is future context retrieval.

## 13. Project and Use Case Scope

Questionnaire context should be scoped to a project and optionally to a use case.

The project is the required container.

A use case is optional and belongs to a project.

Conceptual rule:

- no `use_case_id`: applies to the whole project
- present `use_case_id`: applies to that project use case

The term `generic` should not be used for project-level questions. They are project-scoped questions.

A relational model with required `project_id` and nullable `use_case_id` is the preferred starting point.

When `use_case_id` is present, the system must guarantee that the use case belongs to the same project.

## 14. Questionnaire Model

A questionnaire should exist as a first-class grouping entity.

It avoids loose questions without context and gives the system a navigation, history, and retrieval boundary.

Candidate entities:

- `Questionnaire`
- `QuestionnaireSession`
- `Question`
- `Answer`
- `UseCase`
- `Tag`
- `Tagging`

For a first version, a practical rule may be:

- one main project questionnaire per project
- one main use-case questionnaire per project use case
- optional sessions to capture concrete answering rounds

Open question: whether the system should later support multiple thematic questionnaires per scope.

## 15. Questions and Answers

Questions need stable identifiers.

Stable question identity supports:

- autosave
- partial updates
- Turbo Streams
- answer association
- tagging
- auditability
- context retrieval

Answers should preserve useful metadata:

- who answered
- when
- source channel
- session
- status
- whether the answer is partial
- whether it was normalized or generated
- whether it was confirmed by a human

The first implementation may use one current answer per question, while leaving room for answer versioning later.

## 16. Questionnaire Sessions

A questionnaire session represents one concrete answering round.

Potential fields:

- questionnaire
- channel
- trigger
- status
- start time
- completion time
- actor
- metadata

Sessions are useful for auditability, autosave, abandonment, and future loop-style questionnaires.

## 17. Tags

Tags should be a transversal retrieval layer, not just inline arrays on questions.

Tags may apply to:

- questionnaires
- questions
- answers
- tickets
- documents
- use cases
- other artifacts

The practical goal is to retrieve related context across entity types.

Example:

```text
project = X
use_case = payments
tag = ux-ui
```

That query may retrieve related questions, answers, tickets, documents, and prior decisions.

The preferred direction is a relational many-to-many tagging model rather than JSON arrays as the primary query mechanism.

Tags should be limited and canonicalized. Automatic tag generation should reuse existing tags before creating new ones.

## 18. SQLite and Persistence

The initial design should be relational-first, SQLite-compatible, and PostgreSQL-friendly.

SQLite is appropriate for this stage because it is simple and local.

However, the design should avoid relying on JSON querying as the main retrieval mechanism for tags and questionnaire context.

A graph database is not a good POC dependency.

The preferred direction is:

- simple relational tables
- clear indexes
- portable constraints where possible
- no premature graph abstraction

## 19. Use Case Identity

Use cases should have a real database identifier and a human-readable slug.

Recommended shape:

- `id`
- `project_id`
- `name`
- `slug`
- optional description/status/metadata

The slug should be unique within a project:

```text
unique(project_id, slug)
```

Telegram commands can then refer to use cases by slug.

Automatic creation of use cases from ambiguous text should be avoided in the first version.

## 20. Telegram Commands

Candidate commands:

- `/quiz-me`
- `/quiz-me <use_case>`
- `/quiz-list` or `/quiz list`

`/quiz-me` without an argument should use the active project and the main project questionnaire.

`/quiz-me <use_case>` should resolve the use case inside the active project and use its main questionnaire.

If the use case does not exist, the system should fail or ask for confirmation rather than silently creating it.

The list command should list questionnaires, not individual questions.

Open naming decisions remain.

## 21. Web UI

The preferred POC web UI is not a step-by-step loop.

It should show all questions for a questionnaire on one page.

Each question should have a stable input and support partial updates.

Turbo Streams should be used from the first version for question-level updates.

Autosave may happen by interval, debounce, blur, or explicit submit.

Autosave should not block on expensive LLM tagging.

A future loop-style UI can ask one adaptive question at a time, but that is not the first requirement.

## 22. Future Question Loop

The future adaptive mode should be called a questionnaire loop or question loop, not a saga.

RedWright already uses saga for larger orchestration.

The loop may support bounded follow-up chains:

```text
primary question -> follow-up -> deeper clarification
```

Depth must be bounded.

This mode is more powerful for discovery but more complex than the POC all-at-once web page.

## 23. Tickets and Context Retrieval

Tickets should become a natural context retrieval entrypoint.

A ticket may eventually have:

- required project
- optional use case
- tags

When the agent works a ticket, RedWright can retrieve questionnaire context using:

- project
- use case
- ticket tags
- related questionnaire tags
- related documents and prior tickets

This supports both agents and humans working from the Kanban board.

Open questions:

- who assigns the ticket use case
- whether tags are manual, automatic, or mixed
- whether tickets can have multiple use cases
- whether the agent can add clarification questions back to the ticket
- whether the context packet used for each ticket should be recorded

## 24. Questionnaire Context Packet

Questionnaire context should be a formal source inside context composition.

It should not be appended as an unstructured dump.

Possible packet shape:

```text
questionnaire_context:
  scope: project/use_case/tags
  selected_questions:
    - question
    - answer
    - tags
    - source
    - updated_at
```

The packet should be compact and relevance-ranked.

Short Q/A pairs can be preserved literally. Long answers may need summaries.

## 25. Ranking and Selection

Signals for ranking questionnaire context may include:

- same project
- same use case
- shared ticket tags
- tag weights
- recency
- completeness
- human-authored source
- confidence
- previous successful use
- semantic similarity to the ticket
- question/follow-up hierarchy

Possible priority order:

1. same project + same use case + ticket tags
2. same project + same use case
3. same project + ticket tags
4. project-level questionnaire context
5. related taggable entities
6. protocols or global context when applicable

## 26. Prompt Manager Integration

A future prompt manager can treat questionnaire context as one source among others.

It should decide:

- whether questionnaire context is needed
- whether to run preflight
- which tags or use case scopes to use
- how much Q/A context to include
- whether full project or architecture context is needed
- whether snippets, docs, or diagnostics are needed

Minimum strategy families may include:

- setup prompt
- Telegram planner prompt
- ticket preflight prompt
- ticket implementation prompt
- refinement prompt
- questionnaire generation prompt
- tag classification prompt

## 27. Possible Services

Candidate service boundaries:

- `QuestionnaireResolver`
- `QuestionnaireSessionService`
- `QuestionGenerationService`
- `AnswerUpsertService`
- `TagClassificationService`
- `QuestionnaireContextSelector`
- `TicketContextPreflightService`

These services are not all required for the first implementation.

They are listed to keep responsibilities from collapsing into one large workflow object.

## 28. Open Questions

- What is the exact first version of the questionnaire model?
- Should there be exactly one main questionnaire per project/use case scope?
- Are answers mutable, versioned, or both?
- Should `project_id` and `use_case_id` be denormalized into questions, answers, or taggings?
- What is the first command naming set?
- What is the first web route and navigation placement?
- How are questionnaire questions generated?
- When does tag classification run?
- How many tags can be attached automatically?
- Does ticket execution record which questionnaire context was used?
- When does the agent ask a new question instead of continuing autonomous execution?
- How is human clarification stored on a ticket?

## 29. Non-Goals for the First Spec

- Final graph database design.
- Full adaptive questionnaire loop.
- Perfect tag taxonomy.
- Full prompt manager implementation.
- Complete stack-specific dependency documentation retrieval.
- Automatic use case creation from ambiguous text.
- UI design for every questionnaire surface.

## 30. Provisional Direction

The strongest current direction is:

- keep project setup and persistent questionnaires as separate concepts
- keep `/project new` and `/project clone` separate initially
- introduce project/use-case-scoped questionnaires as reusable context
- use relational tags for cross-entity retrieval
- treat tickets as the main downstream context retrieval trigger
- use preflight prompting selectively for ticket implementation
- keep context packets compact, explicit, and traceable
