require "json"
require "securerandom"

module Harnesses
  Request = Data.define(:request_id, :purpose, :prompt, :workspace, :schema, :timeout,
    :max_output_bytes, :harness, :program, :deadline, :cancellation, :binding, :resources) do
    def initialize(instructions:, context:, workspace:, schema:, purpose:, program: "codex",
      harness: "codex", request_id: SecureRandom.uuid, timeout: 180, max_output_bytes: 2 * 1024 * 1024,
      deadline: nil, cancellation: nil, binding: nil, resources: {})
      deadline ||= Process.clock_gettime(Process::CLOCK_MONOTONIC) + timeout if timeout.is_a?(Numeric) && timeout.finite?
      super(request_id: request_id.to_s.dup.freeze, purpose: purpose.to_s.dup.freeze,
        prompt: (instructions + "\nContext:\n" + JSON.generate(context)).freeze,
        workspace: workspace.to_s.dup.freeze, schema: JSON.parse(JSON.generate(schema), freeze: true),
        timeout: timeout, max_output_bytes: max_output_bytes,
        harness: harness.to_s.dup.freeze, program: program.to_s.dup.freeze, deadline: deadline, cancellation: cancellation,
        binding: binding && JSON.parse(JSON.generate(binding), freeze: true), resources: JSON.parse(JSON.generate(resources), freeze: true))
    end
  end
end
