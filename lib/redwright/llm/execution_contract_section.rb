# frozen_string_literal: true

require_relative "context_section"

module Redwright
  module LLM
    class ExecutionContractSection
      NAME = "execution_contract"
      AUTHORITY = "execution_contract"

      def self.build(**kwargs)
        new(**kwargs).to_context_section
      end

      def initialize(
        execution_profile: nil,
        execution_mode: nil,
        allowed_outputs: [],
        allowed_actions: [],
        validation_required: nil,
        retry_attempt: nil,
        max_attempts: nil,
        workspace_boundary: nil,
        content: {}
      )
        @execution_profile = execution_profile
        @execution_mode = execution_mode
        @allowed_outputs = allowed_outputs
        @allowed_actions = allowed_actions
        @validation_required = validation_required
        @retry_attempt = retry_attempt
        @max_attempts = max_attempts
        @workspace_boundary = workspace_boundary
        @content = content || {}
      end

      def to_context_section
        ContextSection.new(
          name: NAME,
          content: content,
          authority: AUTHORITY,
          metadata: {high_authority: true}
        )
      end

      private

      attr_reader :execution_profile,
                  :execution_mode,
                  :allowed_outputs,
                  :allowed_actions,
                  :validation_required,
                  :retry_attempt,
                  :max_attempts,
                  :workspace_boundary,
                  :content

      def content
        base = profile_content.merge(
          execution_mode: execution_mode&.to_s,
          allowed_outputs: Array(allowed_outputs).map(&:to_s),
          allowed_actions: Array(allowed_actions).map(&:to_s),
          validation_required: validation_required,
          retry_attempt: retry_attempt,
          max_attempts: max_attempts,
          workspace_boundary: workspace_boundary_content
        ).compact

        base.merge(@content)
      end

      def profile_content
        return {} unless execution_profile

        {
          primary_work_family: execution_profile.primary_work_family,
          context_policy: execution_profile.context_policy,
          confidence: execution_profile.confidence
        }
      end

      def workspace_boundary_content
        return nil unless workspace_boundary
        return workspace_boundary.context if workspace_boundary.respond_to?(:context)

        workspace_boundary
      end
    end
  end
end
