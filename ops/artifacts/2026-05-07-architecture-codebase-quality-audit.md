# Architecture and Codebase Quality Audit

Ticket: `TKT-20260507065222`

## Scope

This audit inspected the Ruby and Rails codebase with emphasis on maintainability, naming consistency, architectural boundaries, Rails object size, callback behavior, ActiveRecord usage, error handling, test structure, and file organization.

## Implemented Improvements

- Extracted ticket mention parsing and persistence from `TicketComment` into `TicketManagement::MentionCaptureService`.
  - Category: fat model, callback side effect, naming, ActiveRecord usage.
  - Impact: the model now delegates mention capture to an explicit service, and user lookup uses a single `pluck` instead of instantiating every user record through `find_each`.
- Added `CommandQuery::PayloadReader` and adopted it across command/query handlers.
  - Category: duplicated service object plumbing, naming consistency, responsibility boundaries.
  - Impact: common payload access behavior now has one implementation instead of repeated `value_from`, `hash_from`, and `key_present?` methods across handlers.
- Made document promotion transactional and gave it an explicit domain error.
  - Category: transaction boundary, error handling strategy.
  - Impact: spec creation and lineage relation creation now commit or roll back together, and controllers/command handlers rescue `DocumentPromotionService::PromotionError` instead of a broad `StandardError`.
- Reworked quiz list entry counting to avoid one count query per quiz.
  - Category: ActiveRecord usage, query-in-loop risk.
  - Impact: `ListQuizzes` computes entry counts with one grouped query.

## Findings

### Medium Severity

#### Large Command/Query Handler Objects

Category: service object architecture, file organization, test architecture.

Files:
- `apps/web/app/services/project_setup/context_loop_service.rb`
- `apps/web/app/services/board_workflow/command_query_handlers.rb`
- `apps/web/app/services/project_setup/command_query_handlers.rb`
- `apps/web/app/services/use_cases/command_query_handlers.rb`
- `apps/web/app/services/document_management/command_query_handlers.rb`

Risk:
Several command/query handlers combine input normalization, lookup, business branching, persistence, serialization, and result construction. This makes them easy to extend by copying local helper methods and hard to review as domain contracts evolve.

Recommendation:
Continue extracting shared command/query primitives only when duplication is concrete. Good next targets are result/error builders and serializers, but they should be extracted per domain or command family rather than as a broad framework layer.

#### Model Callbacks with IO or Persistence Side Effects

Category: callback usage, hidden execution flow, transaction boundaries.

Files:
- `apps/web/app/models/ticket_comment.rb`
- `apps/web/app/models/project_protocol.rb`
- `apps/web/app/models/project_protocol_document.rb`

Risk:
Callbacks can hide persistence or filesystem materialization work behind model saves. This is acceptable for small invariant defaults, but it becomes harder to reason about when callbacks create related records or trigger filesystem projection.

Recommendation:
Prefer explicit services for side-effectful workflows. The ticket mention capture callback has been reduced to a service call. Protocol filesystem materialization should be reviewed separately because it may need a lifecycle service or explicit controller/service orchestration.

#### Broad Error Rescue Boundaries

Category: error handling strategy, architectural clarity.

Files:
- `apps/web/app/controllers/documents_controller.rb`
- `apps/web/app/services/command_query/dispatcher.rb`
- `apps/web/app/services/quiz_loops/question_provider.rb`
- `apps/web/app/services/runtime_containers/llm_suggestion_provider.rb`

Risk:
Broad `StandardError` rescues can hide programming errors or mix expected domain failures with unexpected infrastructure failures.

Recommendation:
Use explicit domain error classes around expected failures. Document promotion now uses `DocumentPromotionService::PromotionError`; similar treatment should be considered for LLM suggestion and quiz provider fallback boundaries.

### Low Severity

#### Query-in-Loop Risk in Serializers

Category: ActiveRecord usage, presentation/service serialization.

Files:
- `apps/web/app/services/quiz_loops/command_query_handlers.rb`
- `apps/web/app/services/board_workflow/command_query_handlers.rb`
- `apps/web/app/views/tickets/_comments.html.erb`

Risk:
Several serializers and views traverse associations while building nested payloads. Some already use `includes`, but count and nested relation access should be checked whenever new fields are added.

Recommendation:
Prefer preload/grouped-count patterns for list endpoints. `ListQuizzes` now uses a grouped `QuizEntry` count.

#### Oversized View Partials

Category: view layer architecture, readability.

Files:
- `apps/web/app/views/tickets/_form.html.erb`
- `apps/web/app/views/layouts/application.html.erb`

Risk:
Large ERB files can accumulate conditional presentation logic and make visual consistency changes harder.

Recommendation:
Extract small partials only around repeated or conceptually distinct sections. Avoid introducing a component framework until repetition justifies it.

#### Repeated JSON Attribute Normalization

Category: model consistency, dead abstraction risk.

Files:
- `apps/web/app/models/project_runtime_container.rb`
- `apps/web/app/models/project_setup_session.rb`
- `apps/web/app/models/project_protocol.rb`
- `apps/web/app/models/project_protocol_document.rb`

Risk:
Several models parse and normalize JSON-backed attributes manually. A shared abstraction could reduce duplication, but a premature abstraction could obscure model-specific invariants.

Recommendation:
Wait for one more concrete refactor before extracting a shared JSON attribute helper. Keep the model-specific behavior explicit for now.

## Follow-Up Candidates

- Split `BoardWorkflow::CommandQueryHandlers` serializers and result builders into focused private collaborator objects or domain-specific serializers.
- Review protocol filesystem materialization callbacks and decide whether saves should call an explicit materialization lifecycle service.
- Introduce explicit domain error classes for LLM suggestion fallback and quiz provider failures where failures are expected and recoverable.
- Audit ticket and board views for presentation logic that should move into small partials or helpers.

## Validation

- `bundle exec bin/rails test test/models/ticket_comment_test.rb test/services/ticket_management/mention_capture_service_test.rb test/services/document_promotion_service_test.rb test/controllers/documents_controller_test.rb test/services/document_management/command_query_handlers_test.rb test/services/use_cases/command_query_handlers_test.rb test/services/board_workflow/command_query_handlers_test.rb test/services/project_setup/context_loop_service_test.rb test/services/project_setup/guided_alignment_service_test.rb test/services/runtime_containers/command_query_handlers_test.rb test/services/project_protocols/command_query_handlers_test.rb test/services/quiz_loops/runtime_test`
