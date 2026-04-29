# Persistence Inventory Snapshot (Cycle A / Slice 1)

## Scope

- schema source: `lib/redwright/bootstrap.rb`
- runtime callsite scan scope: `lib/`, `test/`
- generated artifact: `ops/artifacts/2026-04-29-persistence-inventory.json`

## Tables Discovered

- runtime_metadata
- projects
- project_aliases
- workstreams
- tasks
- task_commits
- alignments
- alignment_turns
- alignment_questions
- alignment_answers
- alignment_question_tags
- alignment_question_dependencies
- alignment_artifact_links
- alignment_interruptions
- chat_contexts
- clarification_sessions
- action_executions
- planner_rejections
- execution_feedbacks

## Classification (Initial)

- runtime core: `projects`, `project_aliases`, `workstreams`, `tasks`, `task_commits`, `action_executions`
- context/session: `chat_contexts`, `clarification_sessions`
- alignment/psam: `alignments`, `alignment_turns`, `alignment_questions`, `alignment_answers`, `alignment_question_tags`, `alignment_question_dependencies`, `alignment_artifact_links`, `alignment_interruptions`
- planner/feedback telemetry: `planner_rejections`, `execution_feedbacks`
- metadata: `runtime_metadata`

## Notes

- This slice is inventory-only.
- Zombie detection and keep/remove decisions are deferred to Cycle A / Slice 2.
