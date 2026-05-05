# RedWright Quiz-Me Questionnaire Context Raw Quiz

## Status

- type: `questionnaire-raw`
- date: `2026-05-05`
- source: structured questionnaire about `/quiz-me`, questionnaire context, Telegram commands, web counterpart, and future context retrieval

## Questionnaire State

- question_cap: 50
- questions_asked: 0
- questions_asked: 50
- active_topic: success criteria
- nesting_depth: 0
- status: completed

## Working Scope

This raw file captures polished user answers and key question context during the questionnaire.

It is working memory, not the final curated artifact.

The final curated quiz will be maintained in:

`ops/quiz/2026-05-05-redwright-quiz-me-questionnaire-context-quiz.md`

## Raw Q/A

### Q1: Product Boundary

Question: Should the first `quiz-me` spec cover only persistent questionnaires and their UI/commands, or should it also include how those questionnaires enrich ticket prompts from the beginning?

Answer: The first focus should be a clean questionnaire system: persistence, entity relationships, project-level questionnaires, use-case-specific questionnaires within a project, and tagging for questions and answers. The system should be designed so those persisted answers can later be used effectively for refined context injection, but prompt injection should be treated as a downstream consumer rather than the core scope of this first spec.

### Q2: Questionnaire as Container

Question: Should `Questionnaire` always exist as the mandatory container, or should questions and answers be allowed to attach directly to a project or use case without a container?

Answer: A project has questionnaires. Questionnaires have sets of question-and-answer tuples. Those tuples are ultimately persisted as rows associated with the questionnaire. They are tagged, and they also reference the project and the questionnaire itself. The questionnaire is always the grouping entity. Questions never hang directly from the project.

### Q3: Question and Answer Granularity

Question: Should question and answer be modeled as one tuple-like entity, or as separate `Question` and `Answer` entities?

Answer: The idea of separating question and answer is worth considering, but the concrete advantage is not yet obvious. The expected retrieval use case may be more answer-centric than question-centric, especially when an LLM later uses these records to build richer prompt context. This is an intuition rather than a verified conclusion.

### Q4: Multiple Answers and Ambiguous Q/A

Question: Can one question have multiple answers or versions over time, or is one current editable answer enough for the first design?

Answer: LLM-generated questionnaires may naturally have imperfections. The system will not necessarily send all previous questions on every generation step to guarantee that no similar question is repeated. It is possible for the system to create two similar questions whose answers are not perfectly aligned. That is acceptable for now. When those records are later selected for context injection, the downstream LLM should process both answers and do the best it can with partially overlapping or ambiguous context.

### Q5: Answer History

Question: When an answer already exists and the user edits it from the web, should RedWright overwrite the current answer or keep visible/retrievable answer history?

Answer: The first design should not keep answer history. It does not provide enough benefit at this stage and may even be counterproductive. Later usage can validate whether this was the right decision; the system can adapt if versioning becomes necessary.

### Q6: Main Questionnaire Cardinality

Question: Should there be one main questionnaire per project and one main questionnaire per use case, or should multiple questionnaires per same scope be allowed from the first design?

Answer: There should definitely be one main questionnaire per project. The concept of a question session could be useful later for analyzing how thinking about the system evolves over time. However, the first solution should stay as unconvoluted as possible. Sessions can be mentioned as a future possibility, but the initial design should remain simpler unless sessions are clearly required.

### Q7: Use Case Questionnaire Cardinality

Question: Should the same "one main questionnaire" rule apply to each use case inside a project?

Answer: The same rule should apply to use cases. There should not be question sessions in the first design. New questions and their answers should be associated with the same main questionnaire. Since records already have the standard timestamps, a later heuristic could infer which records effectively belonged to the same session if that becomes useful.

### Q8: Use Case Creation from Command Argument

Question: When the user runs `/quiz-me <use_case_name>` and that name does not exist as a use case in the active project, should the system create the use case, ask for confirmation, or reject the command with a controlled message?

Answer: The command argument should be interpreted as the name of a use case. This means RedWright needs to introduce the concept of a project use case. If a use case with that name does not exist in the active project, the system should create it. A list command could later reveal open questionnaires and/or use cases.

### Q9: List Command Scope

Question: Should the list command list questionnaires, use cases, or a combined view where each use case shows whether it has a questionnaire and how many Q/A records it has?

Answer: This session should focus on questionnaires. Commands specifically for use cases can be handled in a separate session. There may be an evident one-to-one correlation between use cases and their main questionnaires, but this spec should keep its focus on questionnaires.

### Q10: Command Naming

Question: Is `/quiz-me` acceptable as the command to start or add questions to a questionnaire, and should `/quiz-list` or `/quiz list` list questionnaires?

Answer: It would be better to have one base command for everything related to questionnaires. The shorter name `quiz` is preferred over `questionnaires`. A concern is that if `me` becomes a reserved subcommand, then `me` may not be usable as a use case name.

### Q11: Reserved Command Words

Question: Should RedWright use a form such as `/quiz for <use_case>`, or reserve words such as `me`, `list`, `show`, and `help` while allowing `/quiz <use_case>` directly?

Answer: Reserved command words are a real concern. If `/quiz me` reserves `me`, then `me` cannot be a use case name. The same problem applies to `list` or other subcommands. With the `/quiz for <use_case>` shape, only `for` is reserved. That trade-off seems relatively acceptable.

### Q12: Initial Command Grammar

Question: Should the first iteration use `/quiz` for the active project's main questionnaire, `/quiz for <use_case>` for a use-case questionnaire, and `/quiz list` to list questionnaires for the active project?

Answer: This command grammar should be accepted for the first iteration and will probably remain the long-term command shape.

### Q13: Initial Question Generation Mode

Question: When the user runs `/quiz`, should the system generate a complete initial set of questions if the questionnaire is empty, or should it start with one conversational question?

Answer: Prior discussion about initial question loops applies here. Previous answers should influence later questions up to a bounded level, while maintaining a thread that can return to broader coverage instead of getting trapped in one path. Generating all questions as one static set may make that adaptive approach harder.

### Q14: Telegram Loop Shape

Question: Should `/quiz` in Telegram initially work as a one-question-at-a-time loop with bounded follow-up depth?

Answer: Yes.

### Q46: Sensitive Information Guardrails

Question: Is there information the quiz should not ask for or store by default, such as secrets, passwords, tokens, credentials, or PII?

Answer: Yes. The prompt that generates questions should be biased against asking the user for secret-related data, including passwords, tokens, credentials, and PII. This should be an explicit guardrail.

### Q47: Capture Channel

Question: Should each `QuizEntry` store the capture channel or origin, such as Telegram, web, or agent?

Answer: It does not seem necessary for the first version or even necessarily for a later version. Time may prove that wrong, but the model should be agnostic of the driving port.

### Q48: Permissions and Multi-User Scope

Question: For the first web version, can any logged-in user answer or edit quiz entries for the active project, or are specific roles and permissions needed?

Answer: RedWright is currently a single-user app and may remain that way. The product model is one lead commanding a set of agents. There is no current concept of multiple users. Expanding scope could have value, but if it becomes strongly necessary it may be better to create an adjacent product or later expansion rather than pollute this scope. The core problem is allowing each developer to command their own agent set in an organized and remote way. The current demo/test seeding may create more than one user; this should be reviewed because it can conflict with the intended single-user product model.

### Q49: Context Injection Boundary

Question: Should the spec explicitly say that this feature does not implement context injection yet, but prepares data and tags for a future context selector?

Answer: RedWright already implements context injection. It clearly needs optimization. This feature should be framed as adding a new structured source that can improve and refine existing context injection, not as introducing context injection from scratch.

### Q50: Minimum Success Criteria

Question: Is the minimum success criterion for this spec to create and use project-level and use-case-level quizzes from Telegram and web, persist tagged Q/A tuples, and list quizzes for the active project?

Answer: Yes. That is the minimum success criterion.

### Q36: QuizEntry Fields

Question: What minimum fields should `QuizEntry` have: `question`, `answer`, `status`, `position`, timestamps, and anything else?

Answer: `QuizEntry` should include foreign keys such as project and quiz, and use case when applicable. `position` can be left for future use, but it may not be relevant initially. Tagging-related data should be handled through the tagging system rather than embedded directly in the entry.

### Q37: QuizEntry States

Question: Does each `QuizEntry` need states such as `pending`, `answered`, and `skipped`, or is it enough to infer state from whether the answer is empty?

Answer: Since questions are generated on the fly, it should not be natural for unanswered questions to exist. However, because the loop supports skipping, a skipped state sounds reasonable. It is evident when a question was answered because it has an answer. The meaning of `pending` versus `skipped` needs clarification.

### Q38: Suggested State Constants

Question: Should the spec reduce `QuizEntry` states to `answered` and `skipped`, with a fallback technical state such as `empty` or `draft` only for incomplete cases?

Answer: States are constants in code. The spec can suggest some possible states and identify which are likely relevant, but the exact set should not overconstrain the implementation.

### Q39: Quiz Fields

Question: Are the minimum `Quiz` fields `project_id`, nullable `use_case_id`, `title` or `name`, `status`, and timestamps? Is anything else necessary for the first version?

Answer: Nothing else seems necessary for the first version.

### Q40: Quiz Uniqueness

Question: Should there be a uniqueness constraint allowing only one `Quiz` per `(project_id, use_case_id)`, including one project-level quiz where `use_case_id` is null?

Answer: Sessions were already discussed and appear to have limited use for now. They could eventually be inferred from temporal bursts of responses. Adding complexity for sessions or multiple quizzes does not seem worthwhile in the first version. The model should keep one main quiz per scope.

### Q41: Web Navigation Placement

Question: Should the web UI for quizzes live inside the project as `Project -> Quizzes`, or near Board and Docs as another section of the active project?

Answer: Yes, quizzes can live as a section of the active project for now. If the menu becomes overloaded later, the UX/UI can be revisited. An initially imperfect interface is acceptable.

### Q42: Web Quiz Actions

Question: In the web UI, should the user start the general quiz and each use-case quiz from a quiz list, or only enter the active quiz and answer the current question?

Answer: The web UI should accept the same adaptive unpredictability as the Telegram interaction. It should not force a more rigid model just because it is web-based.

### Q43: Duplicate or Similar Questions

Question: If the LLM generates a question that is very similar to one already answered, should the system block it automatically, or should RedWright accept moderate redundancy and let the user answer or skip it?

Answer: This was already discussed. Both entries should be incorporated into the pool. Later retrieval may bring both records, and the downstream agent LLM will do what it can with the ambiguity.

### Q44: LLM Question Contract

Question: When the LLM generates the next question, should it return structured JSON with fields such as `question`, `tags`, hidden rationale, and follow-up depth, or only question text and suggested tags?

Answer: The exact contract can be refined when the formal spec is written. The existing structured question pool used during project creation should be treated as a strong reference. RedWright should not reinvent the wheel for this use case.

### Q45: Hidden Rationale

Question: Should any LLM rationale for choosing a question remain hidden from the user and not be persisted as primary content, while still being allowed in trace/debug if useful?

Answer: Yes.

### Q15: Web Counterpart Flow

Question: Should the web counterpart show all existing questionnaire questions on one editable page, even if Telegram uses a one-question-at-a-time loop?

Answer: The initial thought was to show all questions on one page. However, if the loop logic is implemented for Telegram, reusing it in the web UI is preferable. It is clearer from a UX/UI perspective and preserves the convenience of follow-up questions.

### Q16: Web UI Simplicity

Question: Should the web UI show the current question, answer input, and a visible history of already answered Q/A, instead of a form with all questions?

Answer: Keep the UI simple. The agent should hide its internal reasoning. The user does not need to see the agent's thinking process. If the agent decides that a related follow-up question is useful, it should ask it directly. Showing the process behind that decision is not relevant.

### Q17: Visible Answered-Question List

Question: Should the web UI show at least a simple list of already answered questions, or should the first version show only the current question and basic controls?

Answer: Do not show the list in the first version. It may not be a bad idea later, but it is visual noise for now.

### Q18: Minimum Loop Controls

Question: What minimum controls does the questionnaire loop need: answer, skip, done, and cancel?

Answer: Answer, skip, and done are definitely needed. The user should be free to get tired and stop, even if that works against the agent's goal of collecting more context. The meaning of cancel needed clarification.

### Q19: Cancel Semantics

Question: Should `cancel` mean abandoning the loop without marking the questionnaire as complete, while `done` means the user considers the current questionnaire sufficient for now?

Answer: `cancel` makes sense. It allows the user to stop and resume later. Technically, opening the same project questionnaire or the same use-case questionnaire again should never be forbidden.

### Q20: Questionnaire Status

Question: Should the questionnaire itself have a status such as `open` or `completed`, or should it always remain active while `done` only closes the current loop session?

Answer: Completion can be added later. There can be a status field on the questionnaire grouping entity, but it probably will not be used heavily at first. A `status` field is preferable to a boolean flag because it gives more room for future states.

### Q21: Question Generation Source

Question: Should the next question always be selected or generated by an LLM, or should RedWright also allow deterministic/template questions for some cases?

Answer: Question generation should be LLM-based.

### Q22: Context for Next Question Generation

Question: When the LLM generates the next question, should it receive only the current questionnaire and recent answers, or also project data such as stack, protocols, tickets, and documents?

Answer: Context usually helps, but the future prompt manager does not exist yet and its exact shape is unclear. Initially, the ability to contextualize from previous questions and answers may be enough. There is no strong bias either way yet because this needs to be seen in practice.

### Q23: Question Limits

Question: Should RedWright keep the questionnaire playbook limit of 50 questions per `/quiz` run, with maximum follow-up depth of 3?

Answer: The limit of 50 comes from the current playbook and may sometimes be too high. It should be configurable, first through YAML and later through dynamic settings in the web UI.

### Q24: Follow-Up Depth Configuration

Question: Should maximum follow-up depth of 3 also be configurable, or should it be fixed initially?

Answer: A depth of 3 seems reasonable, but it is better if it is configurable.

### Q25: Tagging Unit

Question: Should tags be separate for the question and the answer, or should there be one tag set for the Q/A tuple?

Answer: Since question and answer should be stored together for now, the tuple is the natural tagging unit. Tagging the tuple automatically tags both the question and the answer.

### Q26: Tag Creation and Editing

Question: Should Q/A tuple tags be generated automatically by LLM, manually editable in the web UI, or both?

Answer: Manual editing would eventually help correct errors and improve contextualization. For the initial version, the LLM should handle tagging automatically in its pass. Manual web editing can come later.

### Q27: Tagging Timing

Question: Should the LLM suggest tags immediately after each answer, or should tags be assigned at the end of the `/quiz` run in a batch?

Answer: The LLM request can be customized so that it returns its interpretation with refined semantics. It seems easier to resolve tagging on the fly. Later, RedWright can add a reviewing task that improves tagging effectiveness using the global project context and the project's tag cloud.

### Q28: Tag Limit

Question: Should there be an initial maximum number of tags per Q/A tuple, such as 3 or 5?

Answer: The limit should be configurable. More tags are not necessarily better because they can create dispersion. A range between 3 and 5 seems best, with 3 preferred.

### Q29: Tag Taxonomy and Scope

Question: Should tags be global across the app, or scoped by project to avoid mixing vocabularies between projects?

Answer: Tags should be free-form. Adding restrictions implies educating the user and creates unnecessary mental friction. RedWright should normalize tags, for example to lowercase kebab-case.

### Q30: Tag Storage Shape

Question: Even if tags are free-form, should they be stored as reusable relational entities with taggings, rather than as a JSON array on the Q/A tuple?

Answer: This remains a real design question. A simple array is faster to conceptualize and simpler for basic reads, but SQLite support for those query patterns may be suboptimal. A many-to-many tagging system would allow other entities to be tagged as well, such as tickets. Shared tags across Q/A tuples and tickets could support richer context retrieval, including complex queries that bring not only answers but also related tickets where those answers are meaningful. That would improve prompt/context bias.

### Q31: Initial Tagging Architecture

Question: Should the spec choose a transversal relational `tags` and `taggings` model from the start, even though it is more work, because of future value across tickets, documents, and Q/A?

Answer: Start directly with the option that looks harder, because its advantage is clear.

### Q32: Taggable Entities

Question: Should the initial transversal tagging system support Q/A tuples and tickets immediately, or only Q/A tuples while leaving tickets and documents prepared for later?

Answer: RedWright already has projects, boards, and tickets. The implementation should verify how ticket tagging is currently represented and align it into one unified tagging solution for all relevant entities. The goal is one transversal tagging system, not separate incompatible tag mechanisms.

### Q33: Ticket Use Case Association

Question: Should tickets get an optional `use_case_id` in this same spec, or should that be left for a separate Kanban/use-case spec?

Answer: Although it is not implemented yet, it would be useful for optimizing queries that generate context. For example, finding all answers associated with a project, use case, and tag in one pass can be very efficient. Tickets should be able to participate in that relationship.

### Q34: Denormalized Scope Columns and Naming

Question: Should RedWright duplicate `project_id` and `use_case_id` on Q/A tuples and taggings to make context retrieval queries faster and simpler, even though the same data can be inferred through the quiz grouping entity?

Answer: Repeating those fields seems useful. Also, naming should avoid long or spelling-prone terms. A short name such as `Quiz` is preferable to `Questionnaire`. The tuple should not be named in a way that suggests the answer is separated from the question; it should represent the question-and-answer pair together.

### Q35: Base Entity Names

Question: Are `Quiz`, `QuizEntry`, `UseCase`, `Tag`, and `Tagging` acceptable base names for the spec and code?

Answer: Yes.
