# frozen_string_literal: true

module Redwright
  module PlannerContract
    INTENTS = %w[change meta].freeze
    CONTROL_INTENTS = %w[none proceed_with_current_context cancel_clarification_only cancel_task cancel_all].freeze
    CONTROL_SCOPES = %w[none gap task workstream chat runtime].freeze
    OPERATIONAL_INTENTS = %w[
      none
      project_new
      project_switch
      project_list
      project_where
      repo_clone
      repo_status
      repo_undo
      task_pause
      task_resume
      task_cancel
      plan_start
      plan_continue
      plan_stop_and_apply
      trace_on
      trace_off
      trace_status
      help
    ].freeze
    OPERATIONAL_SCOPES = %w[none session project runtime].freeze
    SKILL_MODES = %w[none explicit inferred].freeze
    TOP_LEVEL_KEYS = %w[
      intent
      message
      actions
      gaps
      control_intent
      control_scope
      operational_intent
      operational_scope
      operational_args
      operational_requires_project
      operational_requires_confirmation
      skill_requested
      skill_mode
      skill_actions
      skill_exit_condition
    ].freeze
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
      git_undo
    ].freeze
    ACTION_MACRO_TYPES = %w[
      write_files
      run_command
      run_commands
    ].freeze
    ACTION_TYPES = (ACTION_PRIMITIVE_TYPES + ACTION_MACRO_TYPES).freeze
    GAP_KEYS = %w[id question field inferred_value resolved priority].freeze

    def self.primitive_action_type?(value)
      ACTION_PRIMITIVE_TYPES.include?(value.to_s)
    end

    def self.macro_action_type?(value)
      ACTION_MACRO_TYPES.include?(value.to_s)
    end

    def self.allowed_action_types_prompt_lines
      lines = ACTION_PRIMITIVE_TYPES.map { |type| "- #{type}" }
      lines + [
        "- write_files (macro, expands to write_file)",
        "- run_command (macro, expands to run)",
        "- run_commands (macro, expands to run sequence)"
      ]
    end

    SYSTEM_PROMPT = <<~PROMPT
      You route runtime tasks for a coding agent.
      Return strict JSON with exactly these keys:
      - intent: one of "change" or "meta"
      - message: concise normalized task text in English
      - actions: array of action objects (can be empty)
      - gaps: array of unresolved clarification gaps (can be empty)
      - control_intent: one of "none", "proceed_with_current_context", "cancel_clarification_only", "cancel_task", "cancel_all"
      - control_scope: one of "none", "gap", "task", "workstream", "chat", "runtime"
      - operational_intent: one of "none", "project_new", "project_switch", "project_list", "project_where", "repo_clone", "repo_status", "repo_undo", "task_pause", "task_resume", "task_cancel", "plan_start", "plan_continue", "plan_stop_and_apply", "trace_on", "trace_off", "trace_status", "help"
      - operational_scope: one of "none", "session", "project", "runtime"
      - operational_args: object with intent-specific arguments (can be empty)
      - operational_requires_project: boolean
      - operational_requires_confirmation: boolean
      - skill_requested: skill name or empty string
      - skill_mode: one of "none", "explicit", "inferred"
      - skill_actions: array of skill action objects (can be empty)
      - skill_exit_condition: one-line bounded exit condition or empty string
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
      Skill action object keys:
      - id: stable skill action id
      - type: skill action type string
      - args: JSON object
      - requires_confirmation: boolean
      - timeout_ms: positive integer
      - on_failure: one of "abort" or "continue"
      Allowed action types:
      #{allowed_action_types_prompt_lines.join("\n")}
      Do not return extra keys.
    PROMPT
  end
end
