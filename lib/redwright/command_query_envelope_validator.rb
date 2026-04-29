# frozen_string_literal: true

module Redwright
  class CommandQueryEnvelopeValidator
    Result = Struct.new(:valid, :kind, :name, :payload, :execution_context, :request_id, :errors, keyword_init: true)

    COMMANDS = %w[
      CreateTicket
      UpdateTicket
      AssignTicket
      MoveTicket
      StartWorkOnTicket
      SubmitTicketPullRequest
      ReviewTicketPullRequest
      MergeTicketPullRequest
      PickNextTicket
    ].freeze

    QUERIES = %w[
      GetTicket
      GetTickets
      GetBoard
      GetFactoryStatus
      GetExecutionRun
    ].freeze

    RUNTIMES = %w[interactive factory].freeze
    ROLES = %w[coder reviewer merger human_operator].freeze
    KINDS = %w[command query].freeze

    def validate(envelope)
      errors = []
      unless envelope.is_a?(Hash)
        return invalid(["invalid_envelope:type_mismatch"])
      end

      kind = envelope["kind"].to_s
      name = envelope["name"].to_s
      payload = envelope["payload"]
      execution_context = envelope["execution_context"]
      request_id = envelope["request_id"].to_s

      errors << "invalid_envelope:kind" unless KINDS.include?(kind)
      errors << "invalid_envelope:name" if name.strip.empty?
      errors << "invalid_payload:type_mismatch" unless payload.is_a?(Hash)
      errors << "invalid_envelope:request_id" if request_id.strip.empty?
      errors.concat(execution_context_errors(execution_context))

      if kind == "command" && !COMMANDS.include?(name)
        errors << "unsupported_action:command:#{name}"
      elsif kind == "query" && !QUERIES.include?(name)
        errors << "unsupported_action:query:#{name}"
      end

      return invalid(errors) unless errors.empty?

      Result.new(
        valid: true,
        kind: kind,
        name: name,
        payload: payload,
        execution_context: execution_context,
        request_id: request_id,
        errors: []
      )
    end

    private

    def execution_context_errors(context)
      return ["invalid_envelope:execution_context:type_mismatch"] unless context.is_a?(Hash)

      runtime = context["runtime"].to_s
      role = context["role"].to_s
      actor_id = context["actor_id"].to_s

      errors = []
      errors << "invalid_envelope:execution_context:runtime" unless RUNTIMES.include?(runtime)
      errors << "invalid_envelope:execution_context:role" unless ROLES.include?(role)
      errors << "invalid_envelope:execution_context:actor_id" if actor_id.strip.empty?
      errors
    end

    def invalid(errors)
      Result.new(
        valid: false,
        kind: nil,
        name: nil,
        payload: nil,
        execution_context: nil,
        request_id: nil,
        errors: errors
      )
    end
  end
end
