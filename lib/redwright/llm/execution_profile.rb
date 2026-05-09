# frozen_string_literal: true

require_relative "context_policy"

module Redwright
  module LLM
    class ExecutionProfile
      BOOLEAN_FIELDS = %i[
        requires_code_changes
        requires_command_execution
        requires_validation
        should_ask_clarification
      ].freeze

      REQUIRED_FIELDS = %i[
        primary_work_family
        context_policy
        confidence
        requires_code_changes
        requires_command_execution
        requires_validation
        should_ask_clarification
        reasoning_summary
      ].freeze

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
        primary_work_family: nil,
        confidence: nil,
        requires_code_changes: nil,
        requires_command_execution: nil,
        requires_validation: nil,
        should_ask_clarification: nil,
        reasoning_summary: nil,
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

      def valid?
        errors.empty?
      end

      def errors
        validation_errors = []
        validation_errors << "primary_work_family is required" if primary_work_family.empty?
        validation_errors << "primary_work_family is invalid" unless primary_work_family.empty? || ContextPolicy.valid_work_family?(primary_work_family)
        validation_errors << "confidence is required" if confidence.empty?
        validation_errors << "confidence is invalid" unless confidence.empty? || ContextPolicy.valid_confidence?(confidence)
        validation_errors << "context_policy is required" if context_policy.empty?
        validation_errors << "reasoning_summary is required" if reasoning_summary.empty?

        BOOLEAN_FIELDS.each do |field|
          value = public_send(field)
          validation_errors << "#{field} must be true or false" unless value == true || value == false
        end

        validation_errors
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
        return ContextPolicy::FULL_CONTEXT_FALLBACK if confidence.to_s == "low"

        policy = context_policy.to_s
        return policy unless policy.empty?

        ContextPolicy.policy_for(family: primary_work_family, confidence: confidence).to_s
      end
    end
  end
end
