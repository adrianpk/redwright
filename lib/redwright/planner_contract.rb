# frozen_string_literal: true

module Redwright
  module PlannerContract
    INTENTS = %w[change meta].freeze
    TOP_LEVEL_KEYS = %w[intent message actions].freeze
    ACTION_KEYS = %w[id type args requires_confirmation timeout_ms on_failure].freeze
    ACTION_ON_FAILURE = %w[abort continue].freeze
    ACTION_TYPES = %w[
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

    SYSTEM_PROMPT = <<~PROMPT
      You route runtime tasks for a coding agent.
      Return strict JSON with exactly these keys:
      - intent: one of "change" or "meta"
      - message: concise normalized task text in English
      - actions: array of action objects (can be empty)
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
      Do not return extra keys.
    PROMPT
  end
end
