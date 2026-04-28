# frozen_string_literal: true

module Redwright
  module PlannerContract
    INTENTS = %w[change meta].freeze
    CONTROL_INTENTS = %w[none proceed_with_current_context cancel_clarification_only cancel_task cancel_all].freeze
    CONTROL_SCOPES = %w[none gap task workstream chat runtime].freeze
    TOP_LEVEL_KEYS = %w[intent message actions gaps control_intent control_scope].freeze
    ACTION_KEYS = %w[id type args requires_confirmation timeout_ms on_failure].freeze
    ACTION_ON_FAILURE = %w[abort continue].freeze
    ACTION_PRIMITIVE_TYPES = %w[
      list_files
      read_file
      search
      write_file
      apply_patch
      run
      git_status
      git_branch
      git_commit
      git_push
    ].freeze
    ACTION_MACRO_TYPES = %w[
      write_files
      run_command
      run_commands
    ].freeze
    ACTION_TYPES = (ACTION_PRIMITIVE_TYPES + ACTION_MACRO_TYPES).freeze
    GAP_KEYS = %w[id question field inferred_value resolved priority].freeze

    SYSTEM_PROMPT = <<~PROMPT
      You route runtime tasks for a coding agent.
      Return strict JSON with exactly these keys:
      - intent: one of "change" or "meta"
      - message: concise normalized task text in English
      - actions: array of action objects (can be empty)
      - gaps: array of unresolved clarification gaps (can be empty)
      - control_intent: one of "none", "proceed_with_current_context", "cancel_clarification_only", "cancel_task", "cancel_all"
      - control_scope: one of "none", "gap", "task", "workstream", "chat", "runtime"
      Gap object keys:
      - id: stable gap id
      - question: one high-value clarification question
      - field: normalized missing field name
      - inferred_value: inferred suggestion string or empty string
      - resolved: boolean
      - priority: integer from 1 (highest) to 5 (lowest)
      Action object keys:
      - id: stable action id
      - type: action type string
      - args: JSON object
      - requires_confirmation: boolean
      - timeout_ms: positive integer
      - on_failure: one of "abort" or "continue"
      Allowed action types:
      - list_files
      - read_file
      - search
      - write_file
      - apply_patch
      - run
      - git_status
      - git_branch
      - git_commit
      - git_push
      - write_files (macro, expands to write_file)
      - run_command (macro, expands to run)
      - run_commands (macro, expands to run sequence)
      Do not return extra keys.
    PROMPT
  end
end
