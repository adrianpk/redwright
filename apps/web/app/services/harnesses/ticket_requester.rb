module Harnesses
  class TicketRequester
    POLICY_REVISION = "rails-ticket-proposal/v1".freeze
    Completion = Data.define(:content, :finish_reason)

    def initialize(legacy:, structured_call: StructuredCall.new, lifecycle: Operation.new, trace_recorder: nil)
      @legacy, @structured_call, @lifecycle, @trace_recorder = legacy, structured_call, lifecycle, trace_recorder
    end

    def for_operation(ticket:, request:, workspace:)
      Session.new(ticket: ticket, request: request, workspace: workspace, legacy: @legacy,
        structured_call: @structured_call, lifecycle: @lifecycle, trace_recorder: @trace_recorder)
    end

    class Session
      attr_reader :operation

      def initialize(ticket:, request:, workspace:, legacy:, structured_call:, lifecycle:, trace_recorder:)
        @ticket, @request, @workspace, @legacy = ticket, request, workspace, legacy
        @structured_call, @lifecycle, @trace_recorder = structured_call, lifecycle, trace_recorder
      end

      def run
        identity = @request.fetch("request_id")
        key = "ticket-#{CanonicalJson.digest([@ticket.id, identity])}"
        @operation = Selection.new(project: @ticket.project).admit!(operation_key: key,
          purpose: "ticket_proposal", role: "ticket_proposal", schema: AgentTicketExecution::LlmContract.schema,
          policy_revision: POLICY_REVISION)
        unless @operation.state == "prepared"
          raise Error.new("This ticket operation already ran; reconcile its retained outcome before retrying.", code: :uncertain)
        end
        @deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 180
        value = yield self
        finish!(successful?(value) ? "completed" : "failed") if @lease
        value
      rescue StandardError => error
        finish!("failed") if @lease
        raise
      end

      def call(execution_context:)
        @lease ||= @lifecycle.start!(operation: @operation)
        if @lease.binding.fetch("harness") == "direct_api"
          return @legacy.call(execution_context: execution_context)
        end
        binding = @lease.binding
        requester = AgentTicketExecution::LlmRequester.new(
          request_engine: Redwright::LLM::RequestEngine.new(llm_client: self),
          model: binding["requested_model"], provider: binding["requested_provider"], trace_recorder: @trace_recorder)
        @transport_error = nil
        result = requester.call(execution_context: execution_context)
        raise @transport_error if @transport_error
        result
      end

      def configured?
        true
      end

      # RequestEngine keeps the ticket context policy and redaction ahead of transport.
      def complete_json(model:, system_prompt:, user_text:)
        raise Error.new("Ticket context exceeds 128 KiB.", code: :request_too_large) if user_text.bytesize > 128 * 1024
        request = Request.new(instructions: system_prompt, context: JSON.parse(user_text),
          workspace: @workspace.workspace_path, schema: AgentTicketExecution::LlmContract.schema,
          purpose: "ticket_proposal", harness: @lease.binding.fetch("harness"),
          program: @lease.resources.fetch("executable_ref"), binding: @lease.binding,
          resources: @lease.resources, timeout: 180, deadline: @deadline)
        result = @structured_call.call(request)
        @output_digest = Digest::SHA256.hexdigest(result.bytes)
        Completion.new(content: result.bytes, finish_reason: "stop")
      rescue Harnesses::Error => error
        @transport_error = error
        raise
      end

      def correction!
        finish!("failed")
      end

      private

      def successful?(value)
        value.respond_to?(:completed?) ? value.completed? : value.is_a?(Hash) && value["state"] == "completed"
      end

      def finish!(outcome)
        @lifecycle.finish!(lease: @lease, outcome: outcome, output_digest: @output_digest)
        @lease = nil
      end
    end
  end
end
