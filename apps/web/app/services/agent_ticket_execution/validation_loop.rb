require "json"

module AgentTicketExecution
  class ValidationLoop
    DEFAULT_MAX_ATTEMPTS = 3
    DEFAULT_VALIDATION_COMMANDS = [].freeze

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
      validation_commands: nil,
      max_attempts: DEFAULT_MAX_ATTEMPTS,
      previous_interaction_store: nil
    )
      @context_composer = context_composer
      @llm_requester = llm_requester
      @output_applier = output_applier
      @validation_commands = validation_commands
      @max_attempts = max_attempts.to_i.clamp(1, DEFAULT_MAX_ATTEMPTS)
      @previous_interaction_store = previous_interaction_store
    end

    def call(request:, ticket:, workspace:)
      if llm_requester.respond_to?(:for_operation)
        return with_operation(request: request, ticket: ticket, workspace: workspace) do |scoped|
          scoped.call(request: request, ticket: ticket, workspace: workspace)
        end
      end
      workspace = workspace_for(workspace)
      feedback = nil
      validation_results = []
      application_results = []

      (1..max_attempts).each do |attempt|
        llm_requester.prepare_attempt! if llm_requester.respond_to?(:prepare_attempt!)
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

        application = if llm_requester.respond_to?(:apply!)
          llm_requester.apply!(payload: llm_result.payload) { output_applier.apply(payload: llm_result.payload, workspace: workspace) }
        else
          output_applier.apply(payload: llm_result.payload, workspace: workspace)
        end
        application_results << application.to_h
        record_previous_interaction(ticket, attempt_request, llm_result, application, context)

        unless application.ok?
          llm_requester.correction! if llm_requester.respond_to?(:correction!)
          feedback = feedback_payload(stage: "application", result: application.to_h)
          next
        end

        validation_commands = validation_commands_for(ticket, workspace)
        if validation_commands.empty?
          return blocked_result(
            ticket,
            attempt,
            "validation_commands_missing",
            "no validation commands were available from the operational setup",
            validation_results,
            application_results
          )
        end

        validation_results = if llm_requester.respond_to?(:validate!)
          llm_requester.validate! { run_validation(workspace, validation_commands) }
        else
          run_validation(workspace, validation_commands)
        end
        if validation_results.all? { |result| result.fetch("status") == "ok" }
          return completed_result(ticket, attempt, validation_results, application_results)
        end

        feedback = feedback_payload(stage: "validation", result: validation_results)
        llm_requester.correction! if llm_requester.respond_to?(:correction!)
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

    def with_operation(request:, ticket:, workspace:)
      return yield self unless llm_requester.respond_to?(:for_operation)

      session = llm_requester.for_operation(ticket: ticket, request: request, workspace: workspace)
      scoped = dup
      scoped.instance_variable_set(:@llm_requester, session)
      session.run { yield scoped }
    rescue Harnesses::Error => error
      blocked_result(ticket, session&.operation&.reload&.attempts&.size || 0, error.code.to_s, error.message, [], [])
    end

    def workspace_for(workspace)
      llm_requester.respond_to?(:workspace) ? llm_requester.workspace : workspace
    end

    def finalize
      llm_requester.respond_to?(:finalize!) ? llm_requester.finalize! { yield } : yield
    end

    private

    attr_reader :context_composer, :llm_requester, :output_applier, :validation_commands, :max_attempts, :previous_interaction_store

    def validation_commands_for(ticket, workspace)
      explicit_commands = Array(validation_commands).compact_blank
      return explicit_commands unless explicit_commands.empty?

      OperationalSetup.new(project: ticket.project)
        .discover(workspace_path: workspace.workspace_path)
        .fetch("validation_commands", [])
    end

    def run_validation(workspace, commands)
      commands.map.with_index do |command, index|
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
          "ticket_ref" => ticket.display_key,
          "ticket_key" => ticket.ticket_key,
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
          "ticket_ref" => ticket.display_key,
          "ticket_key" => ticket.ticket_key,
          "code" => code,
          "reason" => reason
        }
      )
    end
  end

end
