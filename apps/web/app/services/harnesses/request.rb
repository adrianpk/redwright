require "json"
require "securerandom"

module Harnesses
  Request = Data.define(:request_id, :purpose, :prompt, :workspace, :schema, :timeout,
    :max_output_bytes, :harness, :program) do
    def initialize(instructions:, context:, workspace:, schema:, purpose:, program: "codex",
      harness: "codex", request_id: SecureRandom.uuid, timeout: 180, max_output_bytes: 2 * 1024 * 1024)
      super(request_id: request_id.to_s.dup.freeze, purpose: purpose.to_s.dup.freeze,
        prompt: (instructions + "\nContext:\n" + JSON.generate(context)).freeze,
        workspace: workspace.to_s.dup.freeze, schema: JSON.parse(JSON.generate(schema), freeze: true),
        timeout: timeout, max_output_bytes: max_output_bytes,
        harness: harness.to_s.dup.freeze, program: program.to_s.dup.freeze)
    end
  end
end
