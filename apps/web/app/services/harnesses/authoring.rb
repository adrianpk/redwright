module Harnesses
  class Authoring
    POLICY_REVISION = "rails-authoring/v1".freeze

    def initialize(project:, purpose:, schema:, harness:, workspace_revision: {},
      selection: nil, lifecycle: Operation.new, structured_call: StructuredCall.new)
      @project, @purpose, @schema, @harness = project, purpose, schema, harness
      @workspace_revision, @lifecycle, @structured_call = workspace_revision, lifecycle, structured_call
      @selection = selection || Selection.new(project: project)
      @output_digest = Digest::SHA256.new
    end

    def run
      harness = @harness.respond_to?(:with_operation) ? @harness.with_operation(self) : @harness
      value = yield harness
      @published = true
      @lifecycle.finish!(lease: @lease, outcome: "completed", output_digest: @output_digest.hexdigest) if @lease
      @finished = true
      value
    rescue StandardError => error
      finish_failure(error) if @lease && !@finished
      raise Specifications::Error.new(error.message, code: error.code) if error.is_a?(Harnesses::Error)
      raise
    end

    def call(instructions:, context:, workspace:, timeout:, max_output_bytes:)
      admit!(timeout)
      check_deadline!
      binding = @lease.binding
      request = Request.new(instructions: instructions, context: context, workspace: workspace,
        schema: @schema, purpose: @purpose, harness: binding.fetch("harness"),
        program: @lease.resources.fetch("executable_ref"), timeout: @timeout, deadline: @deadline,
        max_output_bytes: max_output_bytes, binding: binding, resources: @lease.resources)
      result = @structured_call.call(request)
      @output_digest.update(result.bytes)
      result
    end

    def check_deadline!
      if @deadline && Process.clock_gettime(Process::CLOCK_MONOTONIC) >= @deadline
        raise Error.new("The authoring operation timed out.", code: :timed_out)
      end
    end

    private

    def admit!(timeout)
      return if @lease
      unless timeout.is_a?(Numeric) && timeout.finite? && timeout.positive? && timeout <= 180
        raise Error.new("Invalid authoring deadline.", code: :invalid_request)
      end
      @timeout = timeout
      @deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + timeout
      operation = @selection.admit!(operation_key: SecureRandom.uuid, purpose: @purpose, role: "authoring",
        schema: @schema, policy_revision: POLICY_REVISION, workspace_revision: @workspace_revision,
        legacy_program: @harness.respond_to?(:program) ? @harness.program : nil)
      @lease = @lifecycle.start!(operation: operation)
    end

    def finish_failure(error)
      code = error.respond_to?(:code) ? error.code : nil
      outcome = if @published
        "uncertain"
      elsif code == :timed_out
        "timed_out"
      elsif code == :cancelled
        "cancelled"
      else
        "failed"
      end
      @lifecycle.finish!(lease: @lease, outcome: outcome)
    rescue ActiveRecord::ActiveRecordError, Harnesses::Error
      # Keep running/uncertain capacity reserved if the outcome cannot be durably finalized.
      raise Specifications::Error.new("The harness outcome needs reconciliation before another call.", code: :uncertain)
    end
  end
end
