require "json"

module AgentTicketExecution
  class ValidationLoop
    DEFAULT_MAX_ATTEMPTS = 3
    DEFAULT_VALIDATION_COMMANDS = ["go test ./..."].freeze

    Result = Struct.new(:state, :terminal_outcome, :attempts, :validation_results, :application_results, keyword_init: true) do
      def completed?
        state == "completed"
      end

      def blocked?
        state == "blocked"
      end

      def to_execution
        {
          "state" => state,
          "terminal_outcome" => terminal_outcome,
          "details" => {
            "attempts" => attempts,
            "validation_results" => validation_results,
            "application_results" => application_results
          }
        }
      end
    end

    def initialize(
      context_composer:,
      llm_requester:,
      output_applier: OutputApplier.new,
      validation_commands: DEFAULT_VALIDATION_COMMANDS,
      max_attempts: DEFAULT_MAX_ATTEMPTS,
      previous_interaction_store: nil
    )
      @context_composer = context_composer
      @llm_requester = llm_requester
      @output_applier = output_applier
      @validation_commands = validation_commands
      @max_attempts = [max_attempts.to_i, 1].max
      @previous_interaction_store = previous_interaction_store
    end

    def call(request:, ticket:, workspace:)
      feedback = nil
      validation_results = []
      application_results = []

      (1..max_attempts).each do |attempt|
        attempt_request = request.merge("attempt" => attempt, "validation_feedback" => feedback).compact
        context = context_composer.compose(ticket: ticket, request: attempt_request, workspace: workspace)
        llm_result = llm_requester.call(execution_context: context)
        unless llm_result.ok?
          return blocked_result(
            ticket,
            attempt,
            "llm_response_invalid",
            llm_result.warnings.join("; "),
            validation_results,
            application_results
          )
        end
        if llm_result.payload["status"] == "blocked"
          return blocked_result(
            ticket,
            attempt,
            "llm_blocked",
            llm_result.payload["blocking_reason"],
            validation_results,
            application_results
          )
        end

        application = output_applier.apply(payload: llm_result.payload, workspace: workspace)
        application_results << application.to_h
        record_previous_interaction(ticket, attempt_request, llm_result, application, context)

        unless application.ok?
          feedback = feedback_payload(stage: "application", result: application.to_h)
          next
        end

        validation_results = run_validation(workspace)
        if validation_results.all? { |result| result.fetch("status") == "ok" }
          return completed_result(ticket, attempt, validation_results, application_results)
        end

        feedback = feedback_payload(stage: "validation", result: validation_results)
      end

      blocked_result(
        ticket,
        max_attempts,
        "retry_limit_exhausted",
        "validation failed after #{max_attempts} attempt(s)",
        validation_results,
        application_results
      )
    end

    private

    attr_reader :context_composer, :llm_requester, :output_applier, :validation_commands, :max_attempts, :previous_interaction_store

    def run_validation(workspace)
      validation_commands.map.with_index do |command, index|
        result = workspace.primitive_executor.execute(
          project_root: workspace.workspace_path,
          action: {
            "id" => "validation-#{index + 1}",
            "type" => "run",
            "args" => {"command" => command},
            "timeout_ms" => 60_000
          }
        )
        {
          "command" => command,
          "status" => result.status,
          "stdout" => result.stdout,
          "stderr" => result.stderr,
          "error_message" => result.error_message
        }
      end
    end

    def record_previous_interaction(ticket, request, llm_result, application, context)
      return unless previous_interaction_store

      previous_interaction_store.append(
        ticket: ticket,
        request: request,
        request_payload: JSON.parse(context.user_text),
        response_payload: llm_result.payload,
        outcome: application.ok? ? "applied" : "application_failed",
        failure_summary: application.ok? ? nil : application.message,
        context_section_names: context.context_sections.map(&:name)
      )
    end

    def feedback_payload(stage:, result:)
      {
        "stage" => stage,
        "result" => result
      }
    end

    def completed_result(ticket, attempts, validation_results, application_results)
      Result.new(
        state: "completed",
        attempts: attempts,
        validation_results: validation_results,
        application_results: application_results,
        terminal_outcome: {
          "status" => "ready_for_review",
          "ticket_id" => ticket.id,
          "validation" => "passed"
        }
      )
    end

    def blocked_result(ticket, attempts, code, reason, validation_results, application_results)
      Result.new(
        state: "blocked",
        attempts: attempts,
        validation_results: validation_results,
        application_results: application_results,
        terminal_outcome: {
          "status" => "blocked",
          "ticket_id" => ticket.id,
          "code" => code,
          "reason" => reason
        }
      )
    end
  end

end
