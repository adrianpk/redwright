# frozen_string_literal: true

require_relative "context_policy"

module Redwright
  module LLM
    class ExecutionProfile
      OPTIONAL_DEFAULTS = {
        runner_up_families: [],
        request_complexity: nil,
        expected_outputs: [],
        policy_inputs: {}
      }.freeze

      attr_reader :primary_work_family,
                  :context_policy,
                  :confidence,
                  :requires_code_changes,
                  :requires_command_execution,
                  :requires_validation,
                  :should_ask_clarification,
                  :reasoning_summary,
                  :runner_up_families,
                  :request_complexity,
                  :expected_outputs,
                  :policy_inputs

      def self.from_hash(payload)
        normalized = (payload || {}).each_with_object({}) do |(key, value), values|
          values[key.to_sym] = value
        end

        new(**OPTIONAL_DEFAULTS.merge(normalized))
      end

      def initialize(
        primary_work_family:,
        confidence:,
        requires_code_changes:,
        requires_command_execution:,
        requires_validation:,
        should_ask_clarification:,
        reasoning_summary:,
        context_policy: nil,
        runner_up_families: [],
        request_complexity: nil,
        expected_outputs: [],
        policy_inputs: {}
      )
        @primary_work_family = primary_work_family.to_s
        @confidence = confidence.to_s
        @context_policy = resolved_context_policy(context_policy)
        @requires_code_changes = requires_code_changes
        @requires_command_execution = requires_command_execution
        @requires_validation = requires_validation
        @should_ask_clarification = should_ask_clarification
        @reasoning_summary = reasoning_summary.to_s
        @runner_up_families = Array(runner_up_families).map(&:to_s)
        @request_complexity = request_complexity&.to_s
        @expected_outputs = Array(expected_outputs).map(&:to_s)
        @policy_inputs = policy_inputs || {}
      end

      def to_h
        {
          primary_work_family: primary_work_family,
          context_policy: context_policy,
          confidence: confidence,
          requires_code_changes: requires_code_changes,
          requires_command_execution: requires_command_execution,
          requires_validation: requires_validation,
          should_ask_clarification: should_ask_clarification,
          reasoning_summary: reasoning_summary,
          runner_up_families: runner_up_families,
          request_complexity: request_complexity,
          expected_outputs: expected_outputs,
          policy_inputs: policy_inputs
        }
      end

      private

      def resolved_context_policy(context_policy)
        policy = context_policy.to_s
        return policy unless policy.empty?

        ContextPolicy.policy_for(family: primary_work_family, confidence: confidence).to_s
      end
    end
  end
end
