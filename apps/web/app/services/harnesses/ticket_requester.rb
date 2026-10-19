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

    class DeadlineExecutor
      def initialize(executor, session)
        @executor, @session = executor, session
      end

      def execute(project_root:, action:)
        timeout = [action.fetch("timeout_ms", 30_000), @session.remaining_ms!].min
        @executor.execute(project_root: project_root, action: action.merge("timeout_ms" => timeout))
      end
    end

    class Session
      attr_reader :operation, :workspace

      def initialize(ticket:, request:, workspace:, legacy:, structured_call:, lifecycle:, trace_recorder:)
        @ticket, @request, @legacy = ticket, request, legacy
        @workspace = workspace.dup
        @workspace.primitive_executor = DeadlineExecutor.new(workspace.primitive_executor, self)
        @guard = AgentTicketExecution::ProposalWorkspace.new(workspace.workspace_path)
        @structured_call, @lifecycle, @trace_recorder = structured_call, lifecycle, trace_recorder
      end

      def run
        @deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 180
        @guard.synchronize do
          admit!
          value = yield self
          remaining_ms!
          finish!(successful?(value) ? "completed" : "failed") if @lease
          value
        rescue StandardError => error
          reconcile_failure!(error)
        end
      end

      def prepare_attempt!
        remaining_ms!
        @guard.verify!(@expected)
        @lease = @lifecycle.start!(operation: @operation)
        @output_digest = nil
        @receipt = nil
        @lifecycle.record!(lease: @lease, evidence: {"base" => @expected,
          "schema_digest" => @lease.binding.fetch("schema_digest"), "policy_revision" => POLICY_REVISION})
      end

      def call(execution_context:)
        prepare_attempt! unless @lease
        if @lease.binding.fetch("harness") == "direct_api"
          result = @legacy.call(execution_context: execution_context)
          @output_digest = CanonicalJson.digest(result.payload)
        else
          binding = @lease.binding
          requester = AgentTicketExecution::LlmRequester.new(
            request_engine: Redwright::LLM::RequestEngine.new(llm_client: self),
            model: binding["requested_model"], provider: binding["requested_provider"], trace_recorder: @trace_recorder)
          @transport_error = nil
          result = requester.call(execution_context: execution_context)
          raise @transport_error if @transport_error
        end
        @lifecycle.record!(lease: @lease, evidence: {"output_digest" => @output_digest}) if @output_digest
        result
      end

      def configured?
        true
      end

      # RequestEngine keeps the ticket context policy and redaction ahead of transport.
      def complete_json(model:, system_prompt:, user_text:)
        raise Error.new("Ticket context exceeds 128 KiB.", code: :request_too_large) if user_text.bytesize > 128 * 1024
        remaining_ms!
        request = Request.new(instructions: system_prompt, context: JSON.parse(user_text),
          workspace: workspace.workspace_path, schema: AgentTicketExecution::LlmContract.schema,
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

      def apply!(payload:)
        @guard.validate!(payload)
        effect!("application") { yield }
      end

      def validate!
        effect!("validation") { yield }
      end

      def finalize!
        effect!("finalization") { yield }
      end

      def correction!
        @guard.verify!(@expected)
        finish!("failed")
      end

      def remaining_ms!
        remaining = ((@deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)) * 1000).floor
        raise Error.new("The ticket operation timed out.", code: :timed_out) unless remaining.positive?
        remaining
      end

      private

      def admit!
        identity = @request["request_id"]
        unless identity.is_a?(String) && identity.bytesize.between?(1, 128)
          raise Error.new("A bounded ticket request identity is required.", code: :invalid_request)
        end
        key = "ticket-#{CanonicalJson.digest([@ticket.id, identity])}"
        if @ticket.project.harness_operations.where(role: "ticket_proposal", state: %w[running uncertain]).where.not(operation_key: key).exists?
          raise Error.new("An earlier ticket operation requires owned reconciliation in this workspace.", code: :uncertain)
        end
        existing = @ticket.project.harness_operations.find_by(operation_key: key)
        @expected = existing ? JSON.parse(existing.workspace_revision_json).fetch("base") : @guard.snapshot
        revision = {"base" => @expected, "request_digest" => CanonicalJson.digest(@request)}
        @operation = Selection.new(project: @ticket.project).admit!(operation_key: key,
          purpose: "ticket_proposal", role: "ticket_proposal", schema: AgentTicketExecution::LlmContract.schema,
          policy_revision: POLICY_REVISION, workspace_revision: revision)
        unless @operation.state == "prepared" && @operation.attempts.empty?
          raise Error.new("This ticket operation already ran; reconcile its retained outcome before retrying.", code: :uncertain)
        end
        @guard.verify!(@expected)
      end

      def effect!(stage)
        remaining_ms!
        @guard.verify!(@expected)
        before_ref = CanonicalJson.digest(@expected)
        @lifecycle.record!(lease: @lease, evidence: {stage => {"state" => "pending", "before_ref" => before_ref}})
        @effect_pending = true
        value = yield
        after = @guard.snapshot
        serialized = value.is_a?(Array) || value.is_a?(Hash) ? value : value.to_h
        receipt = CanonicalJson.digest({stage: stage, before: before_ref, after: after, result: serialized})
        @lifecycle.record!(lease: @lease, evidence: {stage => {"state" => "recorded", "before_ref" => before_ref,
          "after" => after, "receipt" => receipt, "result_digest" => CanonicalJson.digest(serialized)}})
        @expected, @receipt = after, receipt
        @effect_pending = false
        remaining_ms!
        value
      end

      def successful?(value)
        value.respond_to?(:completed?) ? value.completed? : value.is_a?(Hash) && value["state"] == "completed"
      end

      def finish!(outcome)
        @finishing = true
        @lifecycle.finish!(lease: @lease, outcome: outcome, output_digest: @output_digest, application_receipt: @receipt)
        @lease = nil
        @finishing = false
      end

      def reconcile_failure!(error)
        uncertain = @effect_pending || @finishing
        if @lease
          outcome = uncertain ? "uncertain" : (error.respond_to?(:code) && %i[timed_out cancelled].include?(error.code) ? error.code.to_s : "failed")
          @lifecycle.finish!(lease: @lease, outcome: outcome, output_digest: @output_digest, application_receipt: @receipt)
          @lease = nil
        end
        raise Error.new("Ticket effects require owned reconciliation; no proposal or effect was replayed.", code: :uncertain) if uncertain
        raise error
      rescue ActiveRecord::ActiveRecordError, Harnesses::Error => failure
        raise failure if failure.equal?(error) || (failure.respond_to?(:code) && failure.code == :uncertain)
        raise Error.new("Ticket outcome requires owned reconciliation before retrying.", code: :uncertain)
      end
    end
  end
end
